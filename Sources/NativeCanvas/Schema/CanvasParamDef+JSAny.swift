//
//  CanvasParamDef+JSAny.swift
//  NativeCanvas
//

import JavaScriptCore

public extension CanvasParamDef {
    /// Extracts a `CanvasParamDef` from a JSValue representing a single param definition.
    nonisolated static func from(_ jsValue: JSValue) -> CanvasParamDef {
        let typeStr = jsValue.forProperty("type")?.toString() ?? "string"
        let type = CanvasParamType(rawString: typeStr)

        let defaultValue: CanvasParamValue = if let defVal = jsValue.forProperty("default"), !defVal.isUndefined {
            CanvasParamValue.from(defVal)
        } else {
            .null
        }

        let min: Double? = {
            guard let v = jsValue.forProperty("min"), !v.isUndefined, v.isNumber else { return nil }
            return v.toDouble()
        }()

        let max: Double? = {
            guard let v = jsValue.forProperty("max"), !v.isUndefined, v.isNumber else { return nil }
            return v.toDouble()
        }()

        let options: [String]? = {
            guard let v = jsValue.forProperty("options"), !v.isUndefined, v.isArray else { return nil }
            let count = v.forProperty("length")?.toInt32() ?? 0
            return (0 ..< Int(count)).map { v.atIndex($0)!.toString() }
        }()

        let animatable: Bool = {
            guard let v = jsValue.forProperty("animatable"), !v.isUndefined else { return false }
            return v.toBool()
        }()

        return CanvasParamDef(
            type: type,
            defaultValue: defaultValue,
            min: min,
            max: max,
            options: options,
            animatable: animatable,
        )
    }
}
