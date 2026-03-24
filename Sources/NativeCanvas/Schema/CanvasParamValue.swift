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
    case string(String)
    case number(Double)
    case bool(Bool)
    case font(FontValue)
    case point2d(Point2DValue)
    case gradient([GradientStop])
    case object([String: CanvasParamValue])
    case null

    public struct FontValue: Friendly {
        public let family: String
        public let weight: String
        public let style: String?

        public init(family: String, weight: String, style: String?) {
            self.family = family
            self.weight = weight
            self.style = style
        }
    }

    public struct Point2DValue: Friendly {
        public let x: Double
        public let y: Double

        public init(x: Double, y: Double) {
            self.x = x
            self.y = y
        }
    }

    public struct GradientStop: Friendly {
        public let stop: Double
        public let color: String

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
