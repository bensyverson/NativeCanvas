//
//  CanvasParamType.swift
//  NativeCanvas
//

import Foundation

/// The type of a template parameter, as declared in a template's schema.
///
/// Supports 11 known types plus an ``unknown(_:)`` case for forward compatibility.
/// Unknown types are preserved through serialization so templates authored with
/// newer param types can still be loaded and re-saved without data loss.
public enum CanvasParamType: Hashable, Equatable, Sendable {
    case string
    case text
    case float
    case int
    case bool
    case color
    case enumType
    case font
    case point2d
    case gradient
    case image
    case unknown(String)

    /// The raw string representation used in JS schemas and serialization.
    public var rawString: String {
        switch self {
        case .string: "string"
        case .text: "text"
        case .float: "float"
        case .int: "int"
        case .bool: "bool"
        case .color: "color"
        case .enumType: "enum"
        case .font: "font"
        case .point2d: "point2d"
        case .gradient: "gradient"
        case .image: "image"
        case let .unknown(value): value
        }
    }

    /// Parses a param type from its JS schema string representation.
    public init(rawString: String) {
        switch rawString {
        case "string": self = .string
        case "text": self = .text
        case "float": self = .float
        case "int": self = .int
        case "bool": self = .bool
        case "color": self = .color
        case "enum": self = .enumType
        case "font": self = .font
        case "point2d": self = .point2d
        case "gradient": self = .gradient
        case "image": self = .image
        default: self = .unknown(rawString)
        }
    }
}

// MARK: - Codable

extension CanvasParamType: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self.init(rawString: raw)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawString)
    }
}
