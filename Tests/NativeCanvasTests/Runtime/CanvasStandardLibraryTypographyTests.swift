//
//  CanvasStandardLibraryTypographyTests.swift
//  NativeCanvasTests
//

import JavaScriptCore
import NativeCanvas
import Testing

struct CanvasStandardLibraryTypographyTests {
    private func makeContext() -> JSContext {
        let ctx = JSContext()!
        CanvasStandardLibrary.install(into: ctx, viewportWidth: 1920, viewportHeight: 1080)
        return ctx
    }

    // MARK: - measureText

    @Test("measureText accepts a CSS font string and returns width > 0")
    func measureTextCSSFont() throws {
        let ctx = makeContext()
        let result = try #require(ctx.evaluateScript(#"nc.measureText("Hello", "16px Georgia")"#))
        let width = try #require(result.forProperty("width")?.toDouble())
        #expect(width > 0)
    }

    @Test("measureText bold font returns wider measurement than regular")
    func measureTextBoldWiderThanRegular() throws {
        let ctx = makeContext()
        let regular = try #require(
            ctx.evaluateScript(#"nc.measureText("W", "32px Georgia")"#)?
                .forProperty("width")?.toDouble(),
        )
        let bold = try #require(
            ctx.evaluateScript(#"nc.measureText("W", "bold 32px Georgia")"#)?
                .forProperty("width")?.toDouble(),
        )
        #expect(bold > regular, "Bold 'W' should be wider than regular 'W'")
    }

    @Test("measureText returns height > 0")
    func measureTextReturnsHeight() throws {
        let ctx = makeContext()
        let result = try #require(ctx.evaluateScript(#"nc.measureText("Hello", "16px Georgia")"#))
        let height = try #require(result.forProperty("height")?.toDouble())
        #expect(height > 0)
    }

    @Test("measureText italic font returns a valid measurement")
    func measureTextItalic() throws {
        let ctx = makeContext()
        let result = try #require(ctx.evaluateScript(#"nc.measureText("Hello", "italic 16px Georgia")"#))
        let width = try #require(result.forProperty("width")?.toDouble())
        #expect(width > 0)
    }

    // MARK: - wrapText

    @Test("wrapText accepts a CSS font string")
    func wrapTextCSSFont() throws {
        let ctx = makeContext()
        let result = try #require(ctx.evaluateScript(#"nc.wrapText("one two three four five", 100, "14px Georgia")"#))
        let length = try #require(result.forProperty("length")?.toInt32())
        #expect(length > 1, "Long text at narrow width should wrap into multiple lines")
    }

    @Test("wrapText bold font wraps earlier than regular (bold chars are wider)")
    func wrapTextBoldWrapsEarlier() throws {
        let ctx = makeContext()
        let regularCount = try #require(
            ctx.evaluateScript(#"nc.wrapText("The quick brown fox jumped over the lazy dog", 200, "14px Georgia")"#)?
                .forProperty("length")?.toInt32(),
        )
        let boldCount = try #require(
            ctx.evaluateScript(#"nc.wrapText("The quick brown fox jumped over the lazy dog", 200, "bold 14px Georgia")"#)?
                .forProperty("length")?.toInt32(),
        )
        #expect(boldCount >= regularCount, "Bold text should wrap into at least as many lines as regular")
    }

    @Test("wrapText short text at wide width returns single line")
    func wrapTextNoWrap() throws {
        let ctx = makeContext()
        let result = try #require(ctx.evaluateScript(#"nc.wrapText("Hi", 1000, "14px Georgia")"#))
        let length = try #require(result.forProperty("length")?.toInt32())
        #expect(length == 1)
    }

    // MARK: - fitText

    @Test("fitText returns positive size for regular weight")
    func fitTextRegular() throws {
        let ctx = makeContext()
        let size = try #require(ctx.evaluateScript(#"nc.fitText("Hello", 200, "Georgia")"#)?.toDouble())
        #expect(size > 0)
    }

    @Test("fitText with bold style returns smaller size than regular (bold chars are wider)")
    func fitTextBoldSmallerThanRegular() throws {
        let ctx = makeContext()
        let regular = try #require(ctx.evaluateScript(#"nc.fitText("Hello", 200, "Georgia")"#)?.toDouble())
        let bold = try #require(ctx.evaluateScript(#"nc.fitText("Hello", 200, "Georgia", "bold")"#)?.toDouble())
        #expect(bold <= regular, "Bold text must be smaller to fit the same width")
    }

    @Test("fitText with italic bold style returns a valid size")
    func fitTextItalicBold() throws {
        let ctx = makeContext()
        let size = try #require(ctx.evaluateScript(#"nc.fitText("Hello", 200, "Georgia", "italic bold")"#)?.toDouble())
        #expect(size > 0)
    }
}
