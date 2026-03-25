//
//  CanvasBridgeTextTests.swift
//  NativeCanvasTests
//
// NOTE: These tests use CoreText and may hang in `swift test` (SPM headless runner).
// Run from Xcode using the NativeCanvasTests target instead.

import CoreGraphics
import JavaScriptCore
import NativeCanvas
import Testing

// Tests for Canvas 2D text rendering and measurement
#if !SKIP_CORETEXT_TESTS
    struct CanvasBridgeTextTests {
        // MARK: - Pixel Verification Helper

        private func pixelColor(at x: Int, y: Int, in image: CGImage) -> (r: Float, g: Float, b: Float, a: Float) {
            let colorSpace = CGColorSpace(name: CGColorSpace.extendedLinearSRGB)!
            let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.floatComponents.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)

            let width = image.width
            let height = image.height
            var pixelData = [Float](repeating: 0, count: width * height * 4)

            guard let ctx = CGContext(
                data: &pixelData,
                width: width,
                height: height,
                bitsPerComponent: 32,
                bytesPerRow: width * 16,
                space: colorSpace,
                bitmapInfo: bitmapInfo.rawValue,
            ) else {
                return (0, 0, 0, 0)
            }

            ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

            let offset = (y * width + x) * 4
            return (pixelData[offset], pixelData[offset + 1], pixelData[offset + 2], pixelData[offset + 3])
        }

        private func hasAnyOpaquePixel(in image: CGImage, region: CGRect) -> Bool {
            let colorSpace = CGColorSpace(name: CGColorSpace.extendedLinearSRGB)!
            let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.floatComponents.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)

            let width = image.width
            let height = image.height
            var pixelData = [Float](repeating: 0, count: width * height * 4)

            guard let ctx = CGContext(
                data: &pixelData,
                width: width,
                height: height,
                bitsPerComponent: 32,
                bytesPerRow: width * 16,
                space: colorSpace,
                bitmapInfo: bitmapInfo.rawValue,
            ) else {
                return false
            }

            ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

            let minX = max(0, Int(region.minX))
            let maxX = min(width - 1, Int(region.maxX))
            let minY = max(0, Int(region.minY))
            let maxY = min(height - 1, Int(region.maxY))

            for y in minY ... maxY {
                for x in minX ... maxX {
                    let offset = (y * width + x) * 4
                    if pixelData[offset + 3] > 0.01 {
                        return true
                    }
                }
            }
            return false
        }

        // MARK: - fillText

        @Test("fillText produces non-transparent pixels")
        func fillTextProducesPixels() {
            let bridge = CanvasBridge(width: 100, height: 40)
            bridge.setFillStyle("#ff0000")
            bridge.currentState.fontString = "20px Helvetica"
            bridge.fillText(text: "Hi", x: 5, y: 25)

            guard let image = bridge.makeImage() else {
                Issue.record("Failed to create image")
                return
            }

            let hasPixels = hasAnyOpaquePixel(in: image, region: CGRect(x: 0, y: 5, width: 50, height: 35))
            #expect(hasPixels)
        }

        // MARK: - strokeText

        @Test("strokeText produces non-transparent pixels")
        func strokeTextProducesPixels() {
            let bridge = CanvasBridge(width: 100, height: 40)
            bridge.setStrokeStyle("#00ff00")
            bridge.currentState.fontString = "20px Helvetica"
            bridge.strokeText(text: "Hi", x: 5, y: 25)

            guard let image = bridge.makeImage() else {
                Issue.record("Failed to create image")
                return
            }

            let hasPixels = hasAnyOpaquePixel(in: image, region: CGRect(x: 0, y: 5, width: 50, height: 35))
            #expect(hasPixels)
        }

        // MARK: - measureText

        @Test("measureText returns positive width for non-empty text")
        func measureTextWidth() {
            let bridge = CanvasBridge(width: 100, height: 40)
            bridge.currentState.fontString = "20px Helvetica"

            let result = bridge.measureText("Hello")
            let width = result["width"] ?? 0
            #expect(width > 0)
        }

        @Test("measureText returns zero width for empty text")
        func measureTextEmptyString() {
            let bridge = CanvasBridge(width: 100, height: 40)
            let result = bridge.measureText("")
            let width = result["width"] ?? -1
            #expect(width == 0)
        }

        @Test("measureText returns wider result for longer text")
        func measureTextLongerIsWider() {
            let bridge = CanvasBridge(width: 200, height: 40)
            bridge.currentState.fontString = "16px Helvetica"

            let shortWidth = bridge.measureText("Hi")["width"] ?? 0
            let longWidth = bridge.measureText("Hello World")["width"] ?? 0
            #expect(longWidth > shortWidth)
        }

        // MARK: - textAlign

        @Test("textAlign center shifts text so it is centered on x")
        func textAlignCenter() {
            let bridge = CanvasBridge(width: 100, height: 40)
            bridge.setFillStyle("#ff0000")
            bridge.currentState.fontString = "20px Helvetica"
            bridge.currentState.textAlign = "center"
            bridge.fillText(text: "X", x: 50, y: 25)

            guard let image = bridge.makeImage() else {
                Issue.record("Failed to create image")
                return
            }

            let nearCenter = hasAnyOpaquePixel(in: image, region: CGRect(x: 40, y: 5, width: 20, height: 30))
            #expect(nearCenter)

            let farLeft = hasAnyOpaquePixel(in: image, region: CGRect(x: 0, y: 0, width: 10, height: 40))
            #expect(!farLeft)
        }

        // MARK: - textBaseline

        @Test("textBaseline top draws text below the specified y")
        func textBaselineTop() {
            let bridge = CanvasBridge(width: 100, height: 60)
            bridge.setFillStyle("#ff0000")
            bridge.currentState.fontString = "20px Helvetica"
            bridge.currentState.textBaseline = "top"
            bridge.fillText(text: "X", x: 5, y: 5)

            guard let image = bridge.makeImage() else {
                Issue.record("Failed to create image")
                return
            }

            let aboveY = hasAnyOpaquePixel(in: image, region: CGRect(x: 0, y: 0, width: 100, height: 4))
            #expect(!aboveY)

            let belowY = hasAnyOpaquePixel(in: image, region: CGRect(x: 0, y: 5, width: 50, height: 30))
            #expect(belowY)
        }

        // MARK: - JS Integration

        @Test("JS fillText draws text")
        func jsFillText() throws {
            let bridge = CanvasBridge(width: 100, height: 40)
            let jsContext = try #require(JSContext())

            let ctxValue = try #require(JSValue(newObjectIn: jsContext))
            bridge.installInto(ctxValue)
            jsContext.setObject(ctxValue, forKeyedSubscript: "ctx" as NSString)

            jsContext.evaluateScript("""
                ctx.fillStyle = "red";
                ctx.font = "20px Helvetica";
                ctx.fillText("Hi", 5, 25);
            """)

            guard let image = bridge.makeImage() else {
                Issue.record("Failed to create image")
                return
            }

            let hasPixels = hasAnyOpaquePixel(in: image, region: CGRect(x: 0, y: 5, width: 50, height: 35))
            #expect(hasPixels)
        }

        @Test("JS measureText returns width")
        func jsMeasureText() throws {
            let bridge = CanvasBridge(width: 100, height: 40)
            let jsContext = try #require(JSContext())

            let ctxValue = try #require(JSValue(newObjectIn: jsContext))
            bridge.installInto(ctxValue)
            jsContext.setObject(ctxValue, forKeyedSubscript: "ctx" as NSString)

            let result = jsContext.evaluateScript("""
                ctx.font = "20px Helvetica";
                ctx.measureText("Hello").width;
            """)

            let width = result?.toDouble() ?? 0
            #expect(width > 0)
        }

        @Test("JS font property round-trips")
        func jsFontRoundTrip() throws {
            let bridge = CanvasBridge(width: 10, height: 10)
            let jsContext = try #require(JSContext())

            let ctxValue = try #require(JSValue(newObjectIn: jsContext))
            bridge.installInto(ctxValue)
            jsContext.setObject(ctxValue, forKeyedSubscript: "ctx" as NSString)

            jsContext.evaluateScript("ctx.font = 'bold 24px Arial';")
            let font = jsContext.evaluateScript("ctx.font")?.toString()
            #expect(font == "bold 24px Arial")
        }

        // MARK: - State save/restore for text properties

        @Test("save/restore preserves font and textAlign")
        func saveRestoreTextProperties() {
            let bridge = CanvasBridge(width: 10, height: 10)

            bridge.currentState.fontString = "20px Arial"
            bridge.currentState.textAlign = "center"
            bridge.save()

            bridge.currentState.fontString = "30px Helvetica"
            bridge.currentState.textAlign = "right"

            bridge.restore()

            #expect(bridge.currentState.fontString == "20px Arial")
            #expect(bridge.currentState.textAlign == "center")
        }
    }
#endif
