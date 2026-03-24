//
//  CSSColorParserTests.swift
//  NativeCanvasTests
//

import CoreGraphics
import NativeCanvas
import Testing

/// Tests for CSS color string parsing
struct CSSColorParserTests {
    private let colorSpace = CGColorSpace(name: CGColorSpace.extendedLinearSRGB)!

    // MARK: - Hex Colors

    @Test("Parses 6-digit hex color")
    func hexSixDigit() {
        let color = CSSColorParser.parse("#ff0000", in: colorSpace)
        let c = components(of: color)
        #expect(c.r == 1.0)
        #expect(c.g == 0.0)
        #expect(c.b == 0.0)
        #expect(c.a == 1.0)
    }

    @Test("Parses 3-digit hex color")
    func hexThreeDigit() {
        let color = CSSColorParser.parse("#f00", in: colorSpace)
        let c = components(of: color)
        #expect(c.r == 1.0)
        #expect(c.g == 0.0)
        #expect(c.b == 0.0)
        #expect(c.a == 1.0)
    }

    @Test("Parses 8-digit hex color with alpha")
    func hexEightDigit() {
        let color = CSSColorParser.parse("#ff000080", in: colorSpace)
        let c = components(of: color)
        #expect(c.r == 1.0)
        #expect(c.g == 0.0)
        #expect(c.b == 0.0)
        #expect(isClose(c.a, 128.0 / 255.0))
    }

    @Test("Parses uppercase hex")
    func hexUppercase() {
        let color = CSSColorParser.parse("#FF0000", in: colorSpace)
        #expect(color != nil)
        let c = components(of: color)
        #expect(c.r == 1.0)
    }

    @Test("Parses hex with mixed case")
    func hexMixedCase() {
        let color = CSSColorParser.parse("#Ff8800", in: colorSpace)
        #expect(color != nil)
    }

    // MARK: - RGB Functional Notation

    @Test("Parses rgb() with integer values")
    func rgbIntegers() {
        let color = CSSColorParser.parse("rgb(255, 128, 0)", in: colorSpace)
        let c = components(of: color)
        #expect(c.r == 1.0)
        #expect(isClose(c.g, 128.0 / 255.0))
        #expect(c.b == 0.0)
        #expect(c.a == 1.0)
    }

    @Test("Parses rgb() with percentage values")
    func rgbPercentages() {
        let color = CSSColorParser.parse("rgb(100%, 50%, 0%)", in: colorSpace)
        let c = components(of: color)
        #expect(c.r == 1.0)
        #expect(c.g == 0.5)
        #expect(c.b == 0.0)
    }

    // MARK: - RGBA Functional Notation

    @Test("Parses rgba() with integer values and alpha")
    func rgbaIntegers() {
        let color = CSSColorParser.parse("rgba(255, 0, 0, 0.5)", in: colorSpace)
        let c = components(of: color)
        #expect(c.r == 1.0)
        #expect(c.g == 0.0)
        #expect(c.b == 0.0)
        #expect(c.a == 0.5)
    }

    @Test("Parses rgba() with percentage alpha")
    func rgbaPercentAlpha() {
        let color = CSSColorParser.parse("rgba(255, 0, 0, 50%)", in: colorSpace)
        let c = components(of: color)
        #expect(c.a == 0.5)
    }

    // MARK: - Named Colors

    @Test("Parses named color 'red'")
    func namedRed() {
        let color = CSSColorParser.parse("red", in: colorSpace)
        let c = components(of: color)
        #expect(c.r == 1.0)
        #expect(c.g == 0.0)
        #expect(c.b == 0.0)
    }

    @Test("Parses named color 'transparent'")
    func namedTransparent() {
        let color = CSSColorParser.parse("transparent", in: colorSpace)
        let c = components(of: color)
        #expect(c.r == 0.0)
        #expect(c.g == 0.0)
        #expect(c.b == 0.0)
        #expect(c.a == 0.0)
    }

    @Test("Parses 'gray' and 'grey' identically")
    func grayGrey() {
        let gray = CSSColorParser.parse("gray", in: colorSpace)
        let grey = CSSColorParser.parse("grey", in: colorSpace)
        #expect(gray != nil)
        #expect(grey != nil)
        let gc = components(of: gray)
        let grc = components(of: grey)
        #expect(gc.r == grc.r)
        #expect(gc.g == grc.g)
        #expect(gc.b == grc.b)
    }

    @Test("Parses named colors case-insensitively")
    func namedCaseInsensitive() {
        let color = CSSColorParser.parse("RED", in: colorSpace)
        #expect(color != nil)
    }

    // MARK: - Invalid Input

    @Test("Returns nil for empty string")
    func emptyString() {
        #expect(CSSColorParser.parse("", in: colorSpace) == nil)
    }

    @Test("Returns nil for invalid hex")
    func invalidHex() {
        #expect(CSSColorParser.parse("#xyz", in: colorSpace) == nil)
    }

    @Test("Returns nil for unknown named color")
    func unknownName() {
        #expect(CSSColorParser.parse("chartreuse", in: colorSpace) == nil)
    }

    @Test("Returns nil for malformed rgb()")
    func malformedRGB() {
        #expect(CSSColorParser.parse("rgb()", in: colorSpace) == nil)
        #expect(CSSColorParser.parse("rgb(255)", in: colorSpace) == nil)
        #expect(CSSColorParser.parse("rgb(a, b, c)", in: colorSpace) == nil)
    }

    @Test("Handles whitespace around input")
    func whitespace() {
        let color = CSSColorParser.parse("  #ff0000  ", in: colorSpace)
        #expect(color != nil)
    }

    // MARK: - Helpers

    private struct RGBA {
        let r: CGFloat
        let g: CGFloat
        let b: CGFloat
        let a: CGFloat
    }

    private func components(of color: CGColor?) -> RGBA {
        guard let color, let c = color.components, c.count >= 4 else {
            return RGBA(r: -1, g: -1, b: -1, a: -1)
        }
        return RGBA(r: c[0], g: c[1], b: c[2], a: c[3])
    }

    private func isClose(_ a: CGFloat, _ b: CGFloat, tolerance: CGFloat = 0.01) -> Bool {
        abs(a - b) < tolerance
    }
}
