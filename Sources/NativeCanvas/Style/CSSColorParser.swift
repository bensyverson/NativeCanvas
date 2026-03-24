//
//  CSSColorParser.swift
//  NativeCanvas
//

import CoreGraphics
import Foundation

/// Parses CSS color strings into `CGColor` values.
///
/// Supports the following formats:
/// - Hex: `#RGB`, `#RRGGBB`, `#RRGGBBAA`
/// - Functional: `rgb(r, g, b)`, `rgba(r, g, b, a)` with number or percent values
/// - Named colors: common CSS color keywords
public enum CSSColorParser {
    // MARK: - Public API

    /// Parses a CSS color string into a `CGColor` in the given color space.
    ///
    /// - Parameters:
    ///   - string: A CSS color string (e.g. `"#ff0000"`, `"rgba(255, 0, 0, 0.5)"`, `"red"`)
    ///   - colorSpace: The color space for the resulting `CGColor`
    /// - Returns: A `CGColor` if parsing succeeds, or `nil` for invalid input
    public nonisolated static func parse(_ string: String, in colorSpace: CGColorSpace) -> CGColor? {
        let trimmed = string.trimmingCharacters(in: .whitespaces).lowercased()

        if trimmed.hasPrefix("#") {
            return parseHex(trimmed, in: colorSpace)
        }

        if trimmed.hasPrefix("rgba(") {
            return parseRGBA(trimmed, in: colorSpace)
        }

        if trimmed.hasPrefix("rgb(") {
            return parseRGB(trimmed, in: colorSpace)
        }

        return namedColors[trimmed].flatMap { parseHex($0, in: colorSpace) }
    }

    // MARK: - Hex Parsing

    private nonisolated static func parseHex(_ hex: String, in colorSpace: CGColorSpace) -> CGColor? {
        let digits = String(hex.dropFirst()) // remove '#'

        let r, g, b, a: CGFloat

        switch digits.count {
        case 3:
            guard let rv = hexVal(digits, at: 0, count: 1),
                  let gv = hexVal(digits, at: 1, count: 1),
                  let bv = hexVal(digits, at: 2, count: 1) else { return nil }
            r = rv / 15.0
            g = gv / 15.0
            b = bv / 15.0
            a = 1.0

        case 6:
            guard let rv = hexVal(digits, at: 0, count: 2),
                  let gv = hexVal(digits, at: 2, count: 2),
                  let bv = hexVal(digits, at: 4, count: 2) else { return nil }
            r = rv / 255.0
            g = gv / 255.0
            b = bv / 255.0
            a = 1.0

        case 8:
            guard let rv = hexVal(digits, at: 0, count: 2),
                  let gv = hexVal(digits, at: 2, count: 2),
                  let bv = hexVal(digits, at: 4, count: 2),
                  let av = hexVal(digits, at: 6, count: 2) else { return nil }
            r = rv / 255.0
            g = gv / 255.0
            b = bv / 255.0
            a = av / 255.0

        default:
            return nil
        }

        return CGColor(colorSpace: colorSpace, components: [r, g, b, a])
    }

    private nonisolated static func hexVal(_ string: String, at offset: Int, count: Int) -> CGFloat? {
        let start = string.index(string.startIndex, offsetBy: offset)
        let end = string.index(start, offsetBy: count)
        let sub = String(string[start ..< end])
        guard let val = UInt8(sub, radix: 16) else { return nil }
        return CGFloat(val)
    }

    // MARK: - Functional Notation Parsing

    private nonisolated static func extractArgs(from string: String, prefix: String) -> [String]? {
        guard string.hasPrefix(prefix),
              string.hasSuffix(")") else { return nil }
        let inner = string.dropFirst(prefix.count).dropLast()
        let parts = inner.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        return parts.isEmpty ? nil : parts
    }

    private nonisolated static func parseRGB(_ string: String, in colorSpace: CGColorSpace) -> CGColor? {
        guard let args = extractArgs(from: string, prefix: "rgb("),
              args.count == 3 else { return nil }

        guard let r = parseComponent(args[0]),
              let g = parseComponent(args[1]),
              let b = parseComponent(args[2]) else { return nil }

        return CGColor(colorSpace: colorSpace, components: [r, g, b, 1.0])
    }

    private nonisolated static func parseRGBA(_ string: String, in colorSpace: CGColorSpace) -> CGColor? {
        guard let args = extractArgs(from: string, prefix: "rgba("),
              args.count == 4 else { return nil }

        guard let r = parseComponent(args[0]),
              let g = parseComponent(args[1]),
              let b = parseComponent(args[2]),
              let a = parseAlpha(args[3]) else { return nil }

        return CGColor(colorSpace: colorSpace, components: [r, g, b, a])
    }

    private nonisolated static func parseComponent(_ value: String) -> CGFloat? {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        if trimmed.hasSuffix("%") {
            guard let pct = Double(trimmed.dropLast()) else { return nil }
            return CGFloat(pct / 100.0)
        }
        guard let num = Double(trimmed) else { return nil }
        return CGFloat(num / 255.0)
    }

    private nonisolated static func parseAlpha(_ value: String) -> CGFloat? {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        if trimmed.hasSuffix("%") {
            guard let pct = Double(trimmed.dropLast()) else { return nil }
            return CGFloat(pct / 100.0)
        }
        guard let num = Double(trimmed) else { return nil }
        return CGFloat(num)
    }

    // MARK: - Named Colors

    private static let namedColors: [String: String] = [
        "black": "#000000",
        "white": "#ffffff",
        "red": "#ff0000",
        "green": "#008000",
        "blue": "#0000ff",
        "transparent": "#00000000",
        "yellow": "#ffff00",
        "cyan": "#00ffff",
        "magenta": "#ff00ff",
        "orange": "#ffa500",
        "purple": "#800080",
        "gray": "#808080",
        "grey": "#808080",
    ]
}
