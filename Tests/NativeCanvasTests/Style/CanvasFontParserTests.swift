//
//  CanvasFontParserTests.swift
//  NativeCanvasTests
//
// NOTE: These tests use CoreText and may hang in `swift test` (SPM headless runner).
// Run from Xcode using the NativeCanvasTests target instead.

import CoreText
import NativeCanvas
import Testing

// Tests for Canvas 2D font string parsing
#if !SKIP_CORETEXT_TESTS
    struct CanvasFontParserTests {
        @Test("Parses simple font string with size and family")
        func simpleFont() {
            let font = CanvasFontParser.parse("32px Arial")
            let size = CTFontGetSize(font)
            #expect(size == 32.0)
        }

        @Test("Parses bold weight")
        func boldWeight() {
            let font = CanvasFontParser.parse("bold 24px Helvetica")
            let size = CTFontGetSize(font)
            #expect(size == 24.0)

            let traits = CTFontGetSymbolicTraits(font)
            #expect(traits.contains(.boldTrait))
        }

        @Test("Parses italic style")
        func italicStyle() {
            let font = CanvasFontParser.parse("italic 16px Helvetica")
            let size = CTFontGetSize(font)
            #expect(size == 16.0)

            let traits = CTFontGetSymbolicTraits(font)
            #expect(traits.contains(.italicTrait))
        }

        @Test("Parses italic bold combined (spec order)")
        func italicBold() {
            let font = CanvasFontParser.parse("italic bold 16px Helvetica")
            let size = CTFontGetSize(font)
            #expect(size == 16.0)
            let traits = CTFontGetSymbolicTraits(font)
            #expect(traits.contains(.boldTrait))
            #expect(traits.contains(.italicTrait))
        }

        @Test("Parses bold italic combined (reversed order)")
        func boldItalic() {
            let font = CanvasFontParser.parse("bold italic 60px Georgia")
            let size = CTFontGetSize(font)
            #expect(size == 60.0)
            let traits = CTFontGetSymbolicTraits(font)
            #expect(traits.contains(.boldTrait))
            #expect(traits.contains(.italicTrait))
            let family = CTFontCopyFamilyName(font) as String
            #expect(family == "Georgia")
        }

        @Test("Parses numeric weight")
        func numericWeight() {
            let font = CanvasFontParser.parse("700 20px Helvetica")
            let size = CTFontGetSize(font)
            #expect(size == 20.0)

            let traits = CTFontGetSymbolicTraits(font)
            #expect(traits.contains(.boldTrait))
        }

        @Test("Parses multi-word font family")
        func multiWordFamily() {
            let font = CanvasFontParser.parse("14px Times New Roman")
            let size = CTFontGetSize(font)
            #expect(size == 14.0)

            let family = CTFontCopyFamilyName(font) as String
            #expect(family == "Times New Roman")
        }

        @Test("Parses sans-serif generic family")
        func sansSerifGeneric() {
            let font = CanvasFontParser.parse("12px sans-serif")
            let size = CTFontGetSize(font)
            #expect(size == 12.0)
        }

        @Test("Returns default font for empty string")
        func emptyString() {
            let font = CanvasFontParser.parse("")
            let size = CTFontGetSize(font)
            #expect(size == 10.0)
        }

        @Test("Returns default font for invalid string")
        func invalidString() {
            let font = CanvasFontParser.parse("not a font string")
            let size = CTFontGetSize(font)
            #expect(size == 10.0)
        }

        @Test("Parses fractional pixel size")
        func fractionalSize() {
            let font = CanvasFontParser.parse("14.5px Arial")
            let size = CTFontGetSize(font)
            #expect(size == 14.5)
        }

        @Test("Parses monospace generic family")
        func monospaceGeneric() {
            let font = CanvasFontParser.parse("16px monospace")
            let size = CTFontGetSize(font)
            #expect(size == 16.0)

            let family = CTFontCopyFamilyName(font) as String
            #expect(family == "Menlo")
        }

        @Test("Strips CSS fallback list, using only the first family")
        func commaFallbackFamilyUsesFirstEntry() {
            let font = CanvasFontParser.parse("18px Georgia, serif")
            let family = CTFontCopyFamilyName(font) as String
            #expect(family == "Georgia")
        }

        @Test("Italic with comma fallback family applies italic trait")
        func italicWithCommaFallback() {
            let font = CanvasFontParser.parse("italic 18px Georgia, serif")
            let family = CTFontCopyFamilyName(font) as String
            #expect(family == "Georgia")
            let traits = CTFontGetSymbolicTraits(font)
            #expect(traits.contains(.italicTrait))
        }

        @Test("Strips double quotes from font family name")
        func doubleQuotedFamily() {
            let font = CanvasFontParser.parse("bold 32px \"Georgia\"")
            let family = CTFontCopyFamilyName(font) as String
            #expect(family == "Georgia")
        }

        @Test("Strips single quotes from font family name")
        func singleQuotedFamily() {
            let font = CanvasFontParser.parse("16px 'Helvetica Neue'")
            let family = CTFontCopyFamilyName(font) as String
            #expect(family == "Helvetica Neue")
        }

        @Test("Strips quotes from font family in comma fallback list")
        func quotedFamilyWithFallback() {
            let font = CanvasFontParser.parse("14px \"Times New Roman\", serif")
            let family = CTFontCopyFamilyName(font) as String
            #expect(family == "Times New Roman")
        }
    }
#endif
