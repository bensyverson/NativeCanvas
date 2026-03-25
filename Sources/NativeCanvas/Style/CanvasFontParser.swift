//
//  CanvasFontParser.swift
//  NativeCanvas
//

import CoreText
import Foundation

/// Parses Canvas 2D font strings (e.g. `"bold 32px SF Pro"`) into `CTFont` instances.
///
/// Supports the standard Canvas font shorthand format:
/// `[style] [variant] [weight] size family`
///
/// Falls back to the system font at 10px if parsing fails, matching Canvas 2D spec behavior.
public nonisolated enum CanvasFontParser {
    /// Parses a Canvas 2D font string into a `CTFont`.
    ///
    /// - Parameter string: A Canvas font string like `"bold 32px Arial"` or `"italic 14px Helvetica Neue"`
    /// - Returns: A `CTFont` matching the parsed attributes, or a default system font if parsing fails
    public static func parse(_ string: String) -> CTFont {
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return defaultFont() }

        let tokens = tokenize(trimmed)
        guard let parsed = parseTokens(tokens) else { return defaultFont() }

        return createFont(family: parsed.family, size: parsed.size, weight: parsed.weight, isItalic: parsed.isItalic)
    }

    // MARK: - Token Parsing

    private struct ParsedFont {
        let family: String
        let size: CGFloat
        let weight: CGFloat
        let isItalic: Bool
    }

    private static let styleKeywords: Set<String> = ["normal", "italic", "oblique"]
    private static let variantKeywords: Set<String> = ["normal", "small-caps"]
    private static let weightKeywords: Set<String> = ["normal", "bold"]

    private static func tokenize(_ string: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        for char in string {
            if char == " " || char == "\t" {
                if !current.isEmpty {
                    tokens.append(current)
                    current = ""
                }
            } else {
                current.append(char)
            }
        }
        if !current.isEmpty {
            tokens.append(current)
        }
        return tokens
    }

    private static func parseTokens(_ tokens: [String]) -> ParsedFont? {
        guard !tokens.isEmpty else { return nil }

        var index = 0
        var isItalic = false
        var weight: CGFloat = 0

        // Consume style, variant, and weight tokens in any order.
        // The CSS spec prescribes style → variant → weight, but LLMs
        // commonly produce "bold italic" (weight before style).  We
        // keep consuming until we hit a size token or an unrecognised word.
        while index < tokens.count {
            let token = tokens[index]

            // Stop as soon as we find something that looks like a size.
            if parseSize(token) != nil { break }

            if token == "italic" || token == "oblique" {
                isItalic = true
            } else if token == "bold" {
                weight = 0.4
            } else if token == "small-caps" || token == "normal" {
                // "normal" can be style, variant, or weight — just skip it.
            } else if let numWeight = numericWeight(token) {
                weight = numWeight
            } else {
                // Unrecognised token before the size — bail out so the
                // caller can fall back to the default font.
                break
            }
            index += 1
        }

        guard index < tokens.count else { return nil }
        let sizeToken = tokens[index]
        guard let size = parseSize(sizeToken) else { return nil }
        index += 1

        guard index < tokens.count else { return nil }
        let family = tokens[index...].joined(separator: " ")

        return ParsedFont(family: family, size: size, weight: weight, isItalic: isItalic)
    }

    private static func parseSize(_ token: String) -> CGFloat? {
        let lower = token.lowercased()
        guard lower.hasSuffix("px") else { return nil }
        let numPart = String(lower.dropLast(2))
        guard let value = Double(numPart), value > 0 else { return nil }
        return CGFloat(value)
    }

    private static func numericWeight(_ token: String) -> CGFloat? {
        guard let value = Int(token), value >= 100, value <= 900 else { return nil }
        return cssWeightToCT(value)
    }

    private static func cssWeightToCT(_ cssWeight: Int) -> CGFloat {
        switch cssWeight {
        case 100: return -0.8
        case 200: return -0.6
        case 300: return -0.4
        case 400: return 0.0
        case 500: return 0.23
        case 600: return 0.3
        case 700: return 0.4
        case 800: return 0.56
        case 900: return 0.8
        default:
            let fraction = CGFloat(cssWeight - 400) / 300.0
            return fraction * 0.4
        }
    }

    // MARK: - Font Creation

    private static func createFont(family: String, size: CGFloat, weight: CGFloat, isItalic: Bool) -> CTFont {
        let normalizedFamily = normalizeFamily(family)

        var attributes: [CFString: Any] = [
            kCTFontFamilyNameAttribute: normalizedFamily,
            kCTFontSizeAttribute: size,
        ]

        var traits: [CFString: Any] = [
            kCTFontWeightTrait: weight,
        ]

        if isItalic {
            let symbolicTraits = CTFontSymbolicTraits.traitItalic
            traits[kCTFontSymbolicTrait] = symbolicTraits.rawValue
        }

        attributes[kCTFontTraitsAttribute] = traits

        let descriptor = CTFontDescriptorCreateWithAttributes(attributes as CFDictionary)
        let font = CTFontCreateWithFontDescriptor(descriptor, size, nil)

        let resolvedFamily = CTFontCopyFamilyName(font) as String
        if resolvedFamily != normalizedFamily, !genericFamilies.contains(normalizedFamily.lowercased()) {
            let simpleDescriptor = CTFontDescriptorCreateWithAttributes(
                [kCTFontFamilyNameAttribute: normalizedFamily, kCTFontSizeAttribute: size] as CFDictionary,
            )
            return CTFontCreateWithFontDescriptor(simpleDescriptor, size, nil)
        }

        return font
    }

    private static let genericFamilies: Set<String> = [
        "sans-serif", "serif", "monospace", "cursive", "fantasy", "system-ui",
    ]

    private static func normalizeFamily(_ family: String) -> String {
        // CSS font-family allows comma-separated fallbacks (e.g. "Georgia, serif").
        // CoreText expects a single family name, so take only the first entry.
        // Quotes around family names (e.g. "Georgia" or 'Helvetica Neue') are
        // valid in CSS but must be stripped before passing to CoreText.
        let primary = family
            .split(separator: ",", maxSplits: 1)
            .first
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "\"'")) }
            ?? family

        switch primary.lowercased() {
        case "sans-serif", "system-ui":
            return systemFontFamily()
        case "serif":
            return "Times New Roman"
        case "monospace":
            return "Menlo"
        case "cursive":
            return "Snell Roundhand"
        case "fantasy":
            return "Papyrus"
        default:
            return primary
        }
    }

    private static func systemFontFamily() -> String {
        let systemFont = CTFontCreateUIFontForLanguage(.system, 12, nil)!
        return CTFontCopyFamilyName(systemFont) as String
    }

    private static func defaultFont() -> CTFont {
        let systemFamily = systemFontFamily()
        let descriptor = CTFontDescriptorCreateWithAttributes(
            [kCTFontFamilyNameAttribute: systemFamily, kCTFontSizeAttribute: 10.0] as CFDictionary,
        )
        return CTFontCreateWithFontDescriptor(descriptor, 10, nil)
    }
}
