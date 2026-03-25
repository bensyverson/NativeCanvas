//
//  CanvasBridgeGradientTextTests.swift
//  NativeCanvasTests
//
// NOTE: These tests use CoreText and may hang in `swift test` (SPM headless runner).
// Run from Xcode using the NativeCanvasTests target instead.

import CoreGraphics
import JavaScriptCore
import NativeCanvas
import Testing

#if !SKIP_CORETEXT_TESTS
    struct CanvasBridgeGradientTextTests {
        // MARK: - Pixel Helpers

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

        /// Scans a region for the maximum red and blue values across all opaque pixels.
        private func maxChannels(in image: CGImage, region: CGRect) -> (maxR: Float, maxB: Float) {
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
                return (0, 0)
            }

            ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

            let minX = max(0, Int(region.minX))
            let maxX = min(width - 1, Int(region.maxX))
            let minY = max(0, Int(region.minY))
            let maxY = min(height - 1, Int(region.maxY))

            var maxR: Float = 0
            var maxB: Float = 0

            for y in minY ... maxY {
                for x in minX ... maxX {
                    let offset = (y * width + x) * 4
                    let a = pixelData[offset + 3]
                    guard a > 0.01 else { continue }
                    // Unpremultiply
                    let r = pixelData[offset] / a
                    let b = pixelData[offset + 2] / a
                    maxR = max(maxR, r)
                    maxB = max(maxB, b)
                }
            }
            return (maxR, maxB)
        }

        // MARK: - Gradient fillText

        @Test("fillText with gradient produces gradient-colored pixels, not solid fallback")
        func fillTextWithGradient() throws {
            // Use a canvas sized so text glyphs span from the red to blue region.
            let bridge = CanvasBridge(width: 200, height: 60)

            // Red→Blue horizontal gradient spanning the full width.
            let gradient = bridge.createLinearGradient(x0: 0, y0: 0, x1: 200, y1: 0)
            let cs = bridge.colorSpace
            try gradient.addColorStop(offset: 0, color: #require(CGColor(colorSpace: cs, components: [1, 0, 0, 1])))
            try gradient.addColorStop(offset: 1, color: #require(CGColor(colorSpace: cs, components: [0, 0, 1, 1])))
            bridge.fillGradient = gradient

            bridge.currentState.fontString = "bold 40px Helvetica"
            bridge.fillText(text: "ABCDEFGHIJKLM", x: 0, y: 45)

            guard let image = bridge.makeImage() else {
                Issue.record("Failed to create image")
                return
            }

            // The text region should have opaque pixels.
            let hasPixels = hasAnyOpaquePixel(in: image, region: CGRect(x: 0, y: 0, width: 200, height: 60))
            #expect(hasPixels, "fillText with gradient should produce visible pixels")

            // Left portion of text should be predominantly red.
            let leftChannels = maxChannels(in: image, region: CGRect(x: 0, y: 0, width: 40, height: 60))
            #expect(leftChannels.maxR > 0.5, "Left side of gradient text should have red, got \(leftChannels.maxR)")

            // Right portion of text should have significant blue.
            // Check a region that is well past the midpoint of the gradient.
            let rightChannels = maxChannels(in: image, region: CGRect(x: 120, y: 0, width: 80, height: 60))
            #expect(rightChannels.maxB > 0.3, "Right side of gradient text should have blue, got \(rightChannels.maxB)")
        }

        @Test("JS fillText with gradient style produces gradient-colored text")
        func jsFillTextWithGradient() throws {
            let bridge = CanvasBridge(width: 200, height: 60)
            let jsContext = try #require(JSContext())

            let ctxValue = try #require(JSValue(newObjectIn: jsContext))
            bridge.installInto(ctxValue)
            jsContext.setObject(ctxValue, forKeyedSubscript: "ctx" as NSString)

            jsContext.evaluateScript("""
                var grad = ctx.createLinearGradient(0, 0, 200, 0);
                grad.addColorStop(0, "red");
                grad.addColorStop(1, "blue");
                ctx.fillStyle = grad;
                ctx.font = "bold 40px Helvetica";
                ctx.fillText("ABCDEFGHIJKLM", 0, 45);
            """)

            guard let image = bridge.makeImage() else {
                Issue.record("Failed to create image")
                return
            }

            let hasPixels = hasAnyOpaquePixel(in: image, region: CGRect(x: 0, y: 0, width: 200, height: 60))
            #expect(hasPixels, "JS fillText with gradient should produce visible pixels")

            let leftChannels = maxChannels(in: image, region: CGRect(x: 0, y: 0, width: 40, height: 60))
            #expect(leftChannels.maxR > 0.5, "Left side should be red")

            let rightChannels = maxChannels(in: image, region: CGRect(x: 120, y: 0, width: 80, height: 60))
            #expect(rightChannels.maxB > 0.3, "Right side should be blue")
        }
    }
#endif
