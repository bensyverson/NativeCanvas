//
//  CanvasRuntime.swift
//  NativeCanvas
//

import Foundation
import JavaScriptCore

/// Errors that can occur during canvas engine operations.
public nonisolated enum CanvasError: Error, CustomStringConvertible {
    /// A JavaScript evaluation failed with the given message.
    case evaluationFailed(String)
    /// A required export (e.g. "schema" or "layers") was not found in the template.
    case missingExport(String)
    /// The `layers` export is not an array or is empty.
    case invalidLayers

    public var description: String {
        switch self {
        case let .evaluationFailed(message): "Evaluation failed: \(message)"
        case let .missingExport(name): "Missing required export: \(name)"
        case .invalidLayers: "layers must be a non-empty array"
        }
    }
}

/// Metadata about a loaded template.
public struct CanvasTemplate {
    /// Template name from the schema.
    public let name: String
    /// Layer metadata.
    public let layers: [LayerInfo]
    /// Default parameter values extracted from schema, as a JS object.
    public let defaultParams: JSValue
    /// Reference to the layers JSValue array (for calling render functions).
    public let layersValue: JSValue

    /// Metadata about a single layer.
    public struct LayerInfo {
        /// Layer name (stable identifier).
        public let name: String
        /// The param key this layer's text is bound to, if any.
        public let editableParam: String?

        public init(name: String, editableParam: String?) {
            self.name = name
            self.editableParam = editableParam
        }
    }

    public init(name: String, layers: [LayerInfo], defaultParams: JSValue, layersValue: JSValue) {
        self.name = name
        self.layers = layers
        self.defaultParams = defaultParams
        self.layersValue = layersValue
    }
}

/// Manages a sandboxed JSContext, optionally injects the nc standard library, and loads templates.
///
/// Each `CanvasRuntime` loads exactly **one** template. Create a new runtime for
/// a different template to avoid cross-template state pollution in the JSContext.
public final nonisolated class CanvasRuntime {
    /// The sandboxed JSContext.
    public let jsContext: JSContext
    /// Canvas width in pixels.
    public let viewportWidth: Int
    /// Canvas height in pixels.
    public let viewportHeight: Int

    /// The last JS exception message, captured by the exception handler.
    private var lastException: String?

    /// Creates a new runtime with a sandboxed JSContext.
    ///
    /// - Parameters:
    ///   - width: Canvas width in pixels
    ///   - height: Canvas height in pixels
    ///   - standardLibrary: Whether to inject the nc standard library (default: true)
    public init(width: Int, height: Int, standardLibrary: Bool = true) {
        viewportWidth = width
        viewportHeight = height
        jsContext = JSContext()!

        // Capture exceptions
        jsContext.exceptionHandler = { [weak self] _, exception in
            self?.lastException = exception?.toString()
        }

        // Sandbox: remove dangerous globals
        jsContext.evaluateScript("""
            delete this.eval;
            (function() {
                var _Function = Function;
                Object.defineProperty(this, 'Function', {
                    get: function() { return function() { throw new Error('Function constructor is disabled'); }; },
                    configurable: false
                });
            })();
        """)

        // Wire console.log to Swift for debugging
        let logBlock: @convention(block) (String) -> Void = { message in
            _ = message
        }
        let console = JSValue(newObjectIn: jsContext)!
        console.setObject(logBlock, forKeyedSubscript: "log" as NSString)
        console.setObject(logBlock, forKeyedSubscript: "warn" as NSString)
        console.setObject(logBlock, forKeyedSubscript: "error" as NSString)
        jsContext.setObject(console, forKeyedSubscript: "console" as NSString)

        // Install nc standard library if requested
        if standardLibrary {
            CanvasStandardLibrary.install(into: jsContext, viewportWidth: width, viewportHeight: height)
        }
    }

    /// Extracts a ``CanvasSchema`` from the currently loaded template's schema global.
    ///
    /// Call this after ``loadTemplate(source:)`` to get the persistent schema representation.
    ///
    /// - Returns: The parsed schema, or `nil` if the schema global is missing or invalid
    public func extractSchema() -> CanvasSchema? {
        guard let schemaValue = jsContext.objectForKeyedSubscript("schema"),
              !schemaValue.isUndefined, !schemaValue.isNull
        else {
            return nil
        }
        return CanvasSchema.from(schemaValue)
    }

    /// Loads a template from source, returning layer info.
    ///
    /// - Parameter source: The raw template JavaScript source
    /// - Returns: A ``CanvasTemplate`` with extracted metadata
    /// - Throws: ``CanvasError`` if evaluation fails or required exports are missing
    public func loadTemplate(source: String) throws -> CanvasTemplate {
        lastException = nil

        // Preprocess and evaluate
        let preprocessed = CanvasSourcePreprocessor.preprocess(source)
        jsContext.evaluateScript(preprocessed)

        if let exception = lastException {
            throw CanvasError.evaluationFailed(exception)
        }

        // Extract schema
        guard let schema = jsContext.objectForKeyedSubscript("schema"),
              !schema.isUndefined, !schema.isNull
        else {
            throw CanvasError.missingExport("schema")
        }

        // Extract layers
        guard let layersValue = jsContext.objectForKeyedSubscript("layers"),
              !layersValue.isUndefined, !layersValue.isNull,
              layersValue.isArray
        else {
            if let layers = jsContext.objectForKeyedSubscript("layers"),
               !layers.isUndefined, !layers.isNull
            {
                throw CanvasError.invalidLayers
            }
            throw CanvasError.missingExport("layers")
        }

        let layerCount = layersValue.forProperty("length")?.toInt32() ?? 0
        guard layerCount > 0 else {
            throw CanvasError.invalidLayers
        }

        // Extract layer metadata
        var layerInfos: [CanvasTemplate.LayerInfo] = []
        for i in 0 ..< Int(layerCount) {
            let layer = layersValue.atIndex(i)!
            let name = layer.forProperty("name")?.toString() ?? "layer_\(i)"
            let editableParam: String? = {
                guard let val = layer.forProperty("editableParam"),
                      !val.isUndefined, !val.isNull
                else { return nil }
                return val.toString()
            }()
            layerInfos.append(CanvasTemplate.LayerInfo(name: name, editableParam: editableParam))
        }

        // Extract default param values from schema.params
        let defaultParams = JSValue(newObjectIn: jsContext)!
        if let schemaParams = schema.forProperty("params"),
           !schemaParams.isUndefined, !schemaParams.isNull
        {
            if let keys = jsContext.evaluateScript("Object.keys(schema.params)"),
               keys.isArray
            {
                let keyCount = keys.forProperty("length")?.toInt32() ?? 0
                for i in 0 ..< Int(keyCount) {
                    let key = keys.atIndex(i)!.toString()!
                    let paramDef = schemaParams.forProperty(key)!
                    let defaultVal = paramDef.forProperty("default")
                    if let defaultVal, !defaultVal.isUndefined {
                        defaultParams.setValue(defaultVal, forProperty: key)
                    }
                }
            }
        }

        let name = schema.forProperty("name")?.toString() ?? "Untitled"

        return CanvasTemplate(
            name: name,
            layers: layerInfos,
            defaultParams: defaultParams,
            layersValue: layersValue
        )
    }
}
