//
//  CanvasRenderer.swift
//  NativeCanvas
//

import CoreGraphics
import Foundation
import JavaScriptCore

/// An empty scene for use when no user data is needed.
public struct NoScene: Encodable, Sendable {
    public init() {}
}

/// Renders templates into `CGImage` or into an existing `CGContext`.
///
/// All methods are static and `nonisolated`. Each render call creates a fresh
/// `CanvasRuntime` and `CanvasBridge` so concurrent calls are safe.
public nonisolated enum CanvasRenderer {

    // MARK: - CGImage Render (with scene)

    /// Renders a template to a `CGImage` with user-supplied scene data.
    ///
    /// - Parameters:
    ///   - source: The raw template JavaScript source
    ///   - time: Normalized time within the graphic's duration (0..1). Default 0.
    ///   - frame: Integer frame number. Default 0.
    ///   - scene: An `Encodable & Sendable` value merged into the JS scene object.
    ///   - viewport: Canvas dimensions and safe area.
    ///   - profile: Rendering profile controlling pixel format. Default `.display`.
    ///   - standardLibrary: Whether to inject the `nc` standard library. Default `true`.
    /// - Returns: The rendered `CGImage`.
    /// - Throws: ``CanvasError`` on JS evaluation or missing exports; `EncodingError` if scene encoding fails.
    public static func render<Scene: Encodable & Sendable>(
        source: String,
        at time: Double = 0,
        frame: Int = 0,
        scene: Scene,
        viewport: CanvasViewport,
        profile: CanvasBridge.RenderingProfile = .display,
        standardLibrary: Bool = true
    ) throws -> CGImage {
        let runtime = CanvasRuntime(width: viewport.width, height: viewport.height, standardLibrary: standardLibrary)
        let template = try runtime.loadTemplate(source: source)
        let sceneValue = try buildSceneValue(
            scene: scene, time: time, frame: frame,
            viewport: viewport, in: runtime.jsContext
        )
        return try renderLayers(
            template: template, runtime: runtime,
            sceneValue: sceneValue, params: nil, profile: profile,
            width: viewport.width, height: viewport.height
        )
    }

    // MARK: - CGImage Render (no scene)

    /// Renders a template to a `CGImage` without user scene data.
    public static func render(
        source: String,
        at time: Double = 0,
        frame: Int = 0,
        viewport: CanvasViewport,
        profile: CanvasBridge.RenderingProfile = .display,
        standardLibrary: Bool = true
    ) throws -> CGImage {
        try render(
            source: source, at: time, frame: frame,
            scene: NoScene(), viewport: viewport,
            profile: profile, standardLibrary: standardLibrary
        )
    }

    // MARK: - Into Context (with scene)

    /// Renders a template into an existing `CGContext`.
    ///
    /// The caller owns the context and is responsible for its lifecycle.
    public static func render<Scene: Encodable & Sendable>(
        source: String,
        at time: Double = 0,
        frame: Int = 0,
        scene: Scene,
        into context: CGContext,
        viewport: CanvasViewport,
        profile: CanvasBridge.RenderingProfile = .display,
        standardLibrary: Bool = true
    ) throws {
        let runtime = CanvasRuntime(width: viewport.width, height: viewport.height, standardLibrary: standardLibrary)
        let template = try runtime.loadTemplate(source: source)
        let sceneValue = try buildSceneValue(
            scene: scene, time: time, frame: frame,
            viewport: viewport, in: runtime.jsContext
        )
        let canvas = CanvasBridge(context: context, width: viewport.width, height: viewport.height, profile: profile)
        try renderLayersInto(canvas: canvas, template: template, runtime: runtime, sceneValue: sceneValue, params: nil)
    }

    // MARK: - Private Helpers

    private static func buildSceneValue<Scene: Encodable>(
        scene: Scene,
        time: Double,
        frame: Int,
        viewport: CanvasViewport,
        in jsContext: JSContext
    ) throws -> JSValue {
        // Encode user scene to JSON, then parse in JSContext
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(scene)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"

        // Parse user JSON in JS context
        let sceneValue: JSValue
        if let parsed = jsContext.evaluateScript("JSON.parse(\(jsonStringLiteral(jsonString)))"),
           !parsed.isUndefined, !parsed.isNull, parsed.isObject
        {
            sceneValue = parsed
        } else {
            sceneValue = JSValue(newObjectIn: jsContext)!
        }

        // Merge base fields: t, frame, viewport
        sceneValue.setValue(time, forProperty: "t")
        sceneValue.setValue(frame, forProperty: "frame")

        let vp = JSValue(newObjectIn: jsContext)!
        vp.setValue(viewport.width, forProperty: "width")
        vp.setValue(viewport.height, forProperty: "height")
        let orientation = viewport.width >= viewport.height ? "landscape" : "portrait"
        vp.setValue(orientation, forProperty: "orientation")
        let aspectRatio = Double(viewport.width) / Double(viewport.height)
        vp.setValue(aspectRatio, forProperty: "aspectRatio")
        let diagonal = sqrt(Double(viewport.width * viewport.width + viewport.height * viewport.height))
        vp.setValue(diagonal / 2000.0, forProperty: "pointScale")

        // Safe area
        let sa = JSValue(newObjectIn: jsContext)!
        sa.setValue(viewport.safeArea.top, forProperty: "top")
        sa.setValue(viewport.safeArea.leading, forProperty: "leading")
        sa.setValue(viewport.safeArea.bottom, forProperty: "bottom")
        sa.setValue(viewport.safeArea.trailing, forProperty: "trailing")
        vp.setValue(sa, forProperty: "safeArea")

        sceneValue.setValue(vp, forProperty: "viewport")

        return sceneValue
    }

    private static func renderLayers(
        template: CanvasTemplate,
        runtime: CanvasRuntime,
        sceneValue: JSValue,
        params: [String: Any]?,
        profile: CanvasBridge.RenderingProfile,
        width: Int,
        height: Int
    ) throws -> CGImage {
        let canvas = CanvasBridge(width: width, height: height, profile: profile)
        try renderLayersInto(canvas: canvas, template: template, runtime: runtime, sceneValue: sceneValue, params: params)
        guard let image = canvas.makeImage() else {
            throw CanvasError.evaluationFailed("Failed to produce CGImage from canvas")
        }
        return image
    }

    private static func renderLayersInto(
        canvas: CanvasBridge,
        template: CanvasTemplate,
        runtime: CanvasRuntime,
        sceneValue: JSValue,
        params: [String: Any]?
    ) throws {
        // Build params: start from defaults, overlay overrides
        let paramsValue = JSValue(newObjectIn: runtime.jsContext)!
        if let keys = runtime.jsContext.evaluateScript("(function(obj) { return Object.keys(obj); })")?.call(withArguments: [template.defaultParams]),
           keys.isArray
        {
            let keyCount = keys.forProperty("length")?.toInt32() ?? 0
            for i in 0 ..< Int(keyCount) {
                let key = keys.atIndex(i)!.toString()!
                let val = template.defaultParams.forProperty(key)!
                paramsValue.setValue(val, forProperty: key)
            }
        }
        if let overrides = params {
            for (key, value) in overrides {
                paramsValue.setValue(value, forProperty: key)
            }
        }

        // Create ctx JS object and install bridge
        let ctxValue = JSValue(newObjectIn: runtime.jsContext)!
        canvas.installInto(ctxValue)

        // Render each layer
        let layerCount = template.layersValue.forProperty("length")?.toInt32() ?? 0
        for i in 0 ..< Int(layerCount) {
            guard let layer = template.layersValue.atIndex(i) else { continue }
            guard let renderFn = layer.forProperty("render"),
                  !renderFn.isUndefined, !renderFn.isNull
            else { continue }

            canvas.save()
            renderFn.call(withArguments: [ctxValue, paramsValue, sceneValue])
            canvas.restore()
        }
    }

    /// Escapes a Swift string for safe embedding inside a JS string literal.
    private static func jsonStringLiteral(_ s: String) -> String {
        // The JSON string is already valid JSON; wrap it in single quotes after
        // escaping backslashes and single quotes so it's safe inside JS parens.
        let escaped = s
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
        return "'\(escaped)'"
    }
}
