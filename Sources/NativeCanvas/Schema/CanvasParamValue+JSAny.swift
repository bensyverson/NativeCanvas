//
//  CanvasParamValue+JSAny.swift
//  NativeCanvas
//

import JavaScriptCore

extension CanvasParamValue {
    /// Extracts a `CanvasParamValue` from a JSValue by inspecting its JS type.
    public nonisolated static func from(_ jsValue: JSValue) -> CanvasParamValue {
        if jsValue.isNull || jsValue.isUndefined {
            return .null
        }
        if jsValue.isBoolean {
            return .bool(jsValue.toBool())
        }
        if jsValue.isNumber {
            return .number(jsValue.toDouble())
        }
        if jsValue.isString {
            return .string(jsValue.toString())
        }
        if jsValue.isArray {
            // Check if this looks like a gradient array
            let length = jsValue.forProperty("length")?.toInt32() ?? 0
            if length > 0,
               let first = jsValue.atIndex(0),
               !first.forProperty("stop")!.isUndefined
            {
                var stops: [GradientStop] = []
                for i in 0 ..< Int(length) {
                    let item = jsValue.atIndex(i)!
                    let stop = item.forProperty("stop")?.toDouble() ?? 0
                    let color = item.forProperty("color")?.toString() ?? "#000000"
                    stops.append(GradientStop(stop: stop, color: color))
                }
                return .gradient(stops)
            }
            // Generic array → fall through to object
        }
        if jsValue.isObject {
            // Check for known object shapes
            if let family = jsValue.forProperty("family"),
               !family.isUndefined, family.isString
            {
                let weight = jsValue.forProperty("weight")?.toString() ?? "normal"
                let style: String? = {
                    guard let s = jsValue.forProperty("style"),
                          !s.isUndefined, !s.isNull
                    else { return nil }
                    return s.toString()
                }()
                return .font(FontValue(family: family.toString(), weight: weight, style: style))
            }
            if let x = jsValue.forProperty("x"),
               let y = jsValue.forProperty("y"),
               !x.isUndefined, !y.isUndefined,
               x.isNumber, y.isNumber
            {
                return .point2d(Point2DValue(x: x.toDouble(), y: y.toDouble()))
            }
            // Generic object
            guard let context = jsValue.context else { return .null }
            var dict: [String: CanvasParamValue] = [:]
            if let keys = context.evaluateScript("(function(obj) { return Object.keys(obj); })")?.call(withArguments: [jsValue]),
               keys.isArray
            {
                let keyCount = keys.forProperty("length")?.toInt32() ?? 0
                for i in 0 ..< Int(keyCount) {
                    let key = keys.atIndex(i)!.toString()!
                    let val = jsValue.forProperty(key)!
                    dict[key] = CanvasParamValue.from(val)
                }
            }
            return .object(dict)
        }
        return .null
    }
}
