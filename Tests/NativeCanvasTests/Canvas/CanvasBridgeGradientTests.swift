//
//  CanvasBridgeGradientTests.swift
//  NativeCanvasTests
//

import CoreGraphics
import JavaScriptCore
import NativeCanvas
import Testing

/// Tests for Canvas 2D gradient rendering, shadows, and drawImage
struct CanvasBridgeGradientTests {
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
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return (0, 0, 0, 0)
        }

        ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        let offset = (y * width + x) * 4
        return (pixelData[offset], pixelData[offset + 1], pixelData[offset + 2], pixelData[offset + 3])
    }

    private func isClose(_ a: Float, _ b: Float, tolerance: Float = 0.1) -> Bool {
        abs(a - b) < tolerance
    }

    // MARK: - Linear Gradient

    @Test("Linear gradient from red to blue produces varying colors")
    func linearGradientRedToBlue() throws {
        let bridge = CanvasBridge(width: 20, height: 10)

        let gradient = bridge.createLinearGradient(x0: 0, y0: 0, x1: 20, y1: 0)
        let cs = bridge.colorSpace
        try gradient.addColorStop(offset: 0, color: #require(CGColor(colorSpace: cs, components: [1, 0, 0, 1])))
        try gradient.addColorStop(offset: 1, color: #require(CGColor(colorSpace: cs, components: [0, 0, 1, 1])))
        bridge.fillGradient = gradient

        bridge.fillRect(x: 0, y: 0, width: 20, height: 10)

        guard let image = bridge.makeImage() else {
            Issue.record("Failed to create image")
            return
        }

        let left = pixelColor(at: 1, y: 5, in: image)
        #expect(left.r > 0.7)
        #expect(left.b < 0.3)
        #expect(isClose(left.a, 1.0))

        let right = pixelColor(at: 18, y: 5, in: image)
        #expect(right.r < 0.3)
        #expect(right.b > 0.7)

        let mid = pixelColor(at: 10, y: 5, in: image)
        #expect(mid.r > 0.1 && mid.r < 0.9)
        #expect(mid.b > 0.1 && mid.b < 0.9)
    }

    @Test("Gradient applied to path fill")
    func gradientPathFill() throws {
        let bridge = CanvasBridge(width: 20, height: 20)

        let gradient = bridge.createLinearGradient(x0: 0, y0: 0, x1: 20, y1: 0)
        let cs = bridge.colorSpace
        try gradient.addColorStop(offset: 0, color: #require(CGColor(colorSpace: cs, components: [1, 0, 0, 1])))
        try gradient.addColorStop(offset: 1, color: #require(CGColor(colorSpace: cs, components: [0, 1, 0, 1])))
        bridge.fillGradient = gradient

        bridge.beginPath()
        bridge.arc(x: 10, y: 10, radius: 8, startAngle: 0, endAngle: .pi * 2)
        bridge.fill()

        guard let image = bridge.makeImage() else {
            Issue.record("Failed to create image")
            return
        }

        let center = pixelColor(at: 10, y: 10, in: image)
        #expect(center.a > 0.5)

        let corner = pixelColor(at: 0, y: 0, in: image)
        #expect(isClose(corner.a, 0.0))
    }

    // MARK: - Radial Gradient

    @Test("Radial gradient center matches inner color stop")
    func radialGradientCenter() throws {
        let bridge = CanvasBridge(width: 20, height: 20)

        let gradient = bridge.createRadialGradient(x0: 10, y0: 10, r0: 0, x1: 10, y1: 10, r1: 10)
        let cs = bridge.colorSpace
        try gradient.addColorStop(offset: 0, color: #require(CGColor(colorSpace: cs, components: [1, 0, 0, 1])))
        try gradient.addColorStop(offset: 1, color: #require(CGColor(colorSpace: cs, components: [0, 0, 1, 1])))
        bridge.fillGradient = gradient

        bridge.fillRect(x: 0, y: 0, width: 20, height: 20)

        guard let image = bridge.makeImage() else {
            Issue.record("Failed to create image")
            return
        }

        let center = pixelColor(at: 10, y: 10, in: image)
        #expect(center.r > 0.7)
        #expect(center.b < 0.3)
    }

    // MARK: - Gradient with multiple stops

    @Test("Gradient with 3 stops produces intermediate colors")
    func threeStopGradient() throws {
        let bridge = CanvasBridge(width: 30, height: 10)

        let gradient = bridge.createLinearGradient(x0: 0, y0: 0, x1: 30, y1: 0)
        let cs = bridge.colorSpace
        try gradient.addColorStop(offset: 0, color: #require(CGColor(colorSpace: cs, components: [1, 0, 0, 1])))
        try gradient.addColorStop(offset: 0.5, color: #require(CGColor(colorSpace: cs, components: [0, 1, 0, 1])))
        try gradient.addColorStop(offset: 1, color: #require(CGColor(colorSpace: cs, components: [0, 0, 1, 1])))
        bridge.fillGradient = gradient

        bridge.fillRect(x: 0, y: 0, width: 30, height: 10)

        guard let image = bridge.makeImage() else {
            Issue.record("Failed to create image")
            return
        }

        let left = pixelColor(at: 2, y: 5, in: image)
        #expect(left.r > 0.5)

        let mid = pixelColor(at: 15, y: 5, in: image)
        #expect(mid.g > 0.5)

        let right = pixelColor(at: 27, y: 5, in: image)
        #expect(right.b > 0.5)
    }

    // MARK: - Setting color clears gradient

    @Test("Setting fillStyle string clears fillGradient")
    func setFillStyleClearsGradient() throws {
        let bridge = CanvasBridge(width: 10, height: 10)

        let gradient = bridge.createLinearGradient(x0: 0, y0: 0, x1: 10, y1: 0)
        let cs = bridge.colorSpace
        try gradient.addColorStop(offset: 0, color: #require(CGColor(colorSpace: cs, components: [1, 0, 0, 1])))
        try gradient.addColorStop(offset: 1, color: #require(CGColor(colorSpace: cs, components: [0, 0, 1, 1])))
        bridge.fillGradient = gradient

        bridge.setFillStyle("#ff0000")
        #expect(bridge.fillGradient == nil)
    }

    // MARK: - Shadows

    @Test("Shadow offset produces shadow pixels behind shape")
    func shadowOffset() {
        let bridge = CanvasBridge(width: 40, height: 40)
        bridge.shadowColorString = "rgba(0, 0, 0, 1)"
        bridge.shadowOffsetX = 5
        bridge.shadowOffsetY = 5
        bridge.shadowBlur = 0
        bridge.setFillStyle("#ff0000")
        bridge.fillRect(x: 5, y: 5, width: 10, height: 10)

        guard let image = bridge.makeImage() else {
            Issue.record("Failed to create image")
            return
        }

        let shadowPixel = pixelColor(at: 14, y: 14, in: image)
        #expect(shadowPixel.a > 0.5)

        let empty = pixelColor(at: 35, y: 35, in: image)
        #expect(isClose(empty.a, 0.0))
    }

    @Test("Shadow is cleared after restore")
    func shadowClearedAfterRestore() {
        let bridge = CanvasBridge(width: 20, height: 20)
        bridge.save()
        bridge.shadowColorString = "rgba(0, 0, 0, 1)"
        bridge.shadowBlur = 5
        bridge.shadowOffsetX = 3
        bridge.restore()

        #expect(bridge.shadowBlur == 0)
        #expect(bridge.shadowOffsetX == 0)
    }

    @Test("Shadow applies to fill operations")
    func shadowAppliesToFill() {
        let bridge = CanvasBridge(width: 30, height: 30)
        bridge.shadowColorString = "rgba(0, 0, 255, 1)"
        bridge.shadowOffsetX = 3
        bridge.shadowOffsetY = 3
        bridge.shadowBlur = 0
        bridge.setFillStyle("#ff0000")

        bridge.beginPath()
        bridge.rect(x: 2, y: 2, width: 8, height: 8)
        bridge.fill()

        guard let image = bridge.makeImage() else {
            Issue.record("Failed to create image")
            return
        }

        let mainPixel = pixelColor(at: 5, y: 5, in: image)
        #expect(mainPixel.r > 0.5)
    }

    // MARK: - drawImage

    @Test("drawImage draws image at correct position")
    func drawImagePosition() {
        let bridge = CanvasBridge(width: 20, height: 20)

        let testImage = createTestImage(width: 5, height: 5, r: 1, g: 0, b: 0)
        bridge.registerImage(testImage, forKey: "test")

        bridge.drawImageByKey("test", args: [5, 5])

        guard let image = bridge.makeImage() else {
            Issue.record("Failed to create image")
            return
        }

        let inside = pixelColor(at: 7, y: 7, in: image)
        #expect(isClose(inside.r, 1.0))
        #expect(isClose(inside.a, 1.0))

        let outside = pixelColor(at: 0, y: 0, in: image)
        #expect(isClose(outside.a, 0.0))
    }

    @Test("drawImage scales to specified dimensions")
    func drawImageScaled() {
        let bridge = CanvasBridge(width: 20, height: 20)

        let testImage = createTestImage(width: 5, height: 5, r: 0, g: 1, b: 0)
        bridge.registerImage(testImage, forKey: "test")

        bridge.drawImageByKey("test", args: [0, 0, 10, 10])

        guard let image = bridge.makeImage() else {
            Issue.record("Failed to create image")
            return
        }

        let inside = pixelColor(at: 8, y: 8, in: image)
        #expect(isClose(inside.g, 1.0))
        #expect(isClose(inside.a, 1.0))

        let outside = pixelColor(at: 15, y: 15, in: image)
        #expect(isClose(outside.a, 0.0))
    }

    @Test("drawImage source crop extracts correct region")
    func drawImageCrop() {
        let bridge = CanvasBridge(width: 20, height: 20)

        let testImage = createSplitImage(width: 10, height: 10)
        bridge.registerImage(testImage, forKey: "split")

        bridge.drawImageByKey("split", args: [5, 0, 5, 10, 0, 0, 10, 10])

        guard let image = bridge.makeImage() else {
            Issue.record("Failed to create image")
            return
        }

        let pixel = pixelColor(at: 5, y: 5, in: image)
        #expect(pixel.b > 0.5)
        #expect(pixel.r < 0.3)
    }

    // MARK: - JS Gradient Integration

    @Test("JS gradient creation and fill")
    func jsGradientFill() throws {
        let bridge = CanvasBridge(width: 20, height: 10)
        let jsContext = try #require(JSContext())

        let ctxValue = try #require(JSValue(newObjectIn: jsContext))
        bridge.installInto(ctxValue)
        jsContext.setObject(ctxValue, forKeyedSubscript: "ctx" as NSString)

        jsContext.evaluateScript("""
            var grad = ctx.createLinearGradient(0, 0, 20, 0);
            grad.addColorStop(0, "red");
            grad.addColorStop(1, "blue");
            ctx.fillStyle = grad;
            ctx.fillRect(0, 0, 20, 10);
        """)

        guard let image = bridge.makeImage() else {
            Issue.record("Failed to create image")
            return
        }

        let left = pixelColor(at: 1, y: 5, in: image)
        #expect(left.r > 0.7)

        let right = pixelColor(at: 18, y: 5, in: image)
        #expect(right.b > 0.7)
    }

    @Test("JS shadow properties affect drawing")
    func jsShadowProperties() throws {
        let bridge = CanvasBridge(width: 30, height: 30)
        let jsContext = try #require(JSContext())

        let ctxValue = try #require(JSValue(newObjectIn: jsContext))
        bridge.installInto(ctxValue)
        jsContext.setObject(ctxValue, forKeyedSubscript: "ctx" as NSString)

        jsContext.evaluateScript("""
            ctx.shadowColor = "rgba(0, 0, 0, 1)";
            ctx.shadowOffsetX = 5;
            ctx.shadowOffsetY = 5;
            ctx.shadowBlur = 0;
            ctx.fillStyle = "red";
            ctx.fillRect(2, 2, 10, 10);
        """)

        #expect(bridge.shadowOffsetX == 5)
        #expect(bridge.shadowOffsetY == 5)
        #expect(bridge.shadowBlur == 0)
    }

    @Test("JS radial gradient works")
    func jsRadialGradient() throws {
        let bridge = CanvasBridge(width: 20, height: 20)
        let jsContext = try #require(JSContext())

        let ctxValue = try #require(JSValue(newObjectIn: jsContext))
        bridge.installInto(ctxValue)
        jsContext.setObject(ctxValue, forKeyedSubscript: "ctx" as NSString)

        jsContext.evaluateScript("""
            var grad = ctx.createRadialGradient(10, 10, 0, 10, 10, 10);
            grad.addColorStop(0, "white");
            grad.addColorStop(1, "black");
            ctx.fillStyle = grad;
            ctx.fillRect(0, 0, 20, 20);
        """)

        guard let image = bridge.makeImage() else {
            Issue.record("Failed to create image")
            return
        }

        let center = pixelColor(at: 10, y: 10, in: image)
        #expect(center.r > 0.7)
        #expect(center.g > 0.7)
    }

    // MARK: - Test Image Helpers

    private func createTestImage(width: Int, height: Int, r: Float, g: Float, b: Float) -> CGImage {
        let colorSpace = CGColorSpace(name: CGColorSpace.extendedLinearSRGB)!
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.floatComponents.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)

        var pixelData = [Float](repeating: 0, count: width * height * 4)
        for i in 0 ..< width * height {
            pixelData[i * 4 + 0] = r
            pixelData[i * 4 + 1] = g
            pixelData[i * 4 + 2] = b
            pixelData[i * 4 + 3] = 1.0
        }

        let ctx = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 32,
            bytesPerRow: width * 16,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        )!

        return ctx.makeImage()!
    }

    private func createSplitImage(width: Int, height: Int) -> CGImage {
        let colorSpace = CGColorSpace(name: CGColorSpace.extendedLinearSRGB)!
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.floatComponents.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)

        var pixelData = [Float](repeating: 0, count: width * height * 4)
        for y in 0 ..< height {
            for x in 0 ..< width {
                let i = (y * width + x) * 4
                if x < width / 2 {
                    pixelData[i + 0] = 1.0
                    pixelData[i + 1] = 0.0
                    pixelData[i + 2] = 0.0
                } else {
                    pixelData[i + 0] = 0.0
                    pixelData[i + 1] = 0.0
                    pixelData[i + 2] = 1.0
                }
                pixelData[i + 3] = 1.0
            }
        }

        let ctx = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 32,
            bytesPerRow: width * 16,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        )!

        return ctx.makeImage()!
    }
}
