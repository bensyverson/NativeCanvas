//
//  CanvasParamDef.swift
//  NativeCanvas
//

import Foundation

/// A single parameter definition extracted from a template's schema.
public struct CanvasParamDef: Friendly {
    /// The parameter type.
    public let type: CanvasParamType
    /// The default value for this parameter.
    public let defaultValue: CanvasParamValue
    /// Minimum value (for float/int params).
    public let min: Double?
    /// Maximum value (for float/int params).
    public let max: Double?
    /// Allowed values (for enum params).
    public let options: [String]?
    /// Whether this parameter can be animated over time.
    public let animatable: Bool

    public init(
        type: CanvasParamType,
        defaultValue: CanvasParamValue,
        min: Double?,
        max: Double?,
        options: [String]?,
        animatable: Bool
    ) {
        self.type = type
        self.defaultValue = defaultValue
        self.min = min
        self.max = max
        self.options = options
        self.animatable = animatable
    }
}
