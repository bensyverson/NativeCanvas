//
//  CanvasParamValue.swift
//  NativeCanvas
//

import Foundation

/// A type-safe value for a template parameter.
///
/// Uses tagged enum encoding for unambiguous serialization:
/// each case encodes as `{"type": "<case>", "value": <payload>}`.
public enum CanvasParamValue: Hashable, Equatable, Sendable {
    /// A short single-line string value.
    case string(String)
    /// A numeric (floating-point) value.
    case number(Double)
    /// A boolean value.
    case bool(Bool)
    /// A font value describing family, weight, and optional style.
    case font(FontValue)
    /// A 2D point value with `x` and `y` components.
    case point2d(Point2DValue)
    /// A gradient defined by an ordered array of color stops.
    case gradient([GradientStop])
    /// An arbitrary key-value object.
    case object([String: CanvasParamValue])
    /// A null / absent value.
    case null

    /// A font descriptor used for ``CanvasParamValue/font(_:)`` values.
    public struct FontValue: Friendly {
        /// The font family name (e.g. `"Helvetica Neue"`).
        public let family: String
        /// The font weight (e.g. `"bold"`, `"400"`).
        public let weight: String
        /// The font style (e.g. `"italic"`), if any.
        public let style: String?

        /// Creates a font value with the given family, weight, and optional style.
        public init(family: String, weight: String, style: String?) {
            self.family = family
            self.weight = weight
            self.style = style
        }
    }

    /// A 2D coordinate used for ``CanvasParamValue/point2d(_:)`` values.
    public struct Point2DValue: Friendly {
        /// The horizontal component.
        public let x: Double
        /// The vertical component.
        public let y: Double

        /// Creates a point with the given x and y components.
        public init(x: Double, y: Double) {
            self.x = x
            self.y = y
        }
    }

    /// A single color stop in a gradient, used for ``CanvasParamValue/gradient(_:)`` values.
    public struct GradientStop: Friendly {
        /// The position of the stop along the gradient axis (0.0 – 1.0).
        public let stop: Double
        /// The CSS color string at this stop.
        public let color: String

        /// Creates a gradient stop at the given position with the given CSS color.
        public init(stop: Double, color: String) {
            self.stop = stop
            self.color = color
        }
    }
}

// MARK: - Codable

extension CanvasParamValue: Codable {
    private enum Tag: String, Codable {
        case string, number, bool, font, point2d, gradient, object, null
    }

    private enum CodingKeys: String, CodingKey {
        case type, value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let tag = try container.decode(Tag.self, forKey: .type)
        switch tag {
        case .string:
            self = try .string(container.decode(String.self, forKey: .value))
        case .number:
            self = try .number(container.decode(Double.self, forKey: .value))
        case .bool:
            self = try .bool(container.decode(Bool.self, forKey: .value))
        case .font:
            self = try .font(container.decode(FontValue.self, forKey: .value))
        case .point2d:
            self = try .point2d(container.decode(Point2DValue.self, forKey: .value))
        case .gradient:
            self = try .gradient(container.decode([GradientStop].self, forKey: .value))
        case .object:
            self = try .object(container.decode([String: CanvasParamValue].self, forKey: .value))
        case .null:
            self = .null
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .string(value):
            try container.encode(Tag.string, forKey: .type)
            try container.encode(value, forKey: .value)
        case let .number(value):
            try container.encode(Tag.number, forKey: .type)
            try container.encode(value, forKey: .value)
        case let .bool(value):
            try container.encode(Tag.bool, forKey: .type)
            try container.encode(value, forKey: .value)
        case let .font(value):
            try container.encode(Tag.font, forKey: .type)
            try container.encode(value, forKey: .value)
        case let .point2d(value):
            try container.encode(Tag.point2d, forKey: .type)
            try container.encode(value, forKey: .value)
        case let .gradient(value):
            try container.encode(Tag.gradient, forKey: .type)
            try container.encode(value, forKey: .value)
        case let .object(value):
            try container.encode(Tag.object, forKey: .type)
            try container.encode(value, forKey: .value)
        case .null:
            try container.encode(Tag.null, forKey: .type)
        }
    }
}
