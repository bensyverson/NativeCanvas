//
//  CanvasStandardLibraryTests.swift
//  NativeCanvasTests
//

import JavaScriptCore
import NativeCanvas
import Testing

struct CanvasStandardLibraryTests {
    /// Creates a JSContext with the nc library installed at 1920x1080.
    private func makeContext(width: Int = 1920, height: Int = 1080) -> JSContext {
        let ctx = JSContext()!
        CanvasStandardLibrary.install(into: ctx, viewportWidth: width, viewportHeight: height)
        return ctx
    }

    // MARK: - Resolution

    @Test("pt() returns correct pixel value for 1920x1080")
    func ptFunction() throws {
        let ctx = makeContext()
        let diagonal = sqrt(Double(1920 * 1920 + 1080 * 1080))
        let expectedScale = diagonal / 2000.0
        let result = try #require(ctx.evaluateScript("nc.pt(10)")?.toDouble())
        #expect(abs(result - 10 * expectedScale) < 0.001)
    }

    // MARK: - Easing

    @Test("easeIn(0) = 0 and easeIn(1) = 1")
    func easeInBoundaries() {
        let ctx = makeContext()
        #expect(ctx.evaluateScript("nc.easeIn(0)")?.toDouble() == 0)
        #expect(ctx.evaluateScript("nc.easeIn(1)")?.toDouble() == 1)
    }

    @Test("easeOut(0) = 0 and easeOut(1) = 1")
    func easeOutBoundaries() {
        let ctx = makeContext()
        #expect(ctx.evaluateScript("nc.easeOut(0)")?.toDouble() == 0)
        #expect(ctx.evaluateScript("nc.easeOut(1)")?.toDouble() == 1)
    }

    @Test("easeInOut(0) = 0 and easeInOut(1) = 1")
    func easeInOutBoundaries() {
        let ctx = makeContext()
        #expect(ctx.evaluateScript("nc.easeInOut(0)")?.toDouble() == 0)
        #expect(ctx.evaluateScript("nc.easeInOut(1)")?.toDouble() == 1)
    }

    @Test("easeIn is monotonically increasing")
    func easeInMonotonic() throws {
        let ctx = makeContext()
        var prev = 0.0
        for i in 1 ... 10 {
            let t = Double(i) / 10.0
            let val = try #require(ctx.evaluateScript("nc.easeIn(\(t))")?.toDouble())
            #expect(val >= prev, "easeIn(\(t)) = \(val) should be >= \(prev)")
            prev = val
        }
    }

    @Test("bounce(0) = 0 and bounce(1) = 1")
    func bounceBoundaries() throws {
        let ctx = makeContext()
        #expect(ctx.evaluateScript("nc.bounce(0)")?.toDouble() == 0)
        #expect(try abs(#require(ctx.evaluateScript("nc.bounce(1)")?.toDouble()) - 1.0) < 0.001)
    }

    @Test("steps returns stepped values")
    func stepsFunction() throws {
        let ctx = makeContext()
        let val = try #require(ctx.evaluateScript("nc.steps(0.3, 4)")?.toDouble())
        #expect(val == 0.25)
    }

    // MARK: - Interpolation

    @Test("lerp(0, 10, 0.5) == 5")
    func lerpMidpoint() {
        let ctx = makeContext()
        #expect(ctx.evaluateScript("nc.lerp(0, 10, 0.5)")?.toDouble() == 5)
    }

    @Test("clamp(15, 0, 10) == 10")
    func clampAbove() {
        let ctx = makeContext()
        #expect(ctx.evaluateScript("nc.clamp(15, 0, 10)")?.toDouble() == 10)
    }

    @Test("clamp(-5, 0, 10) == 0")
    func clampBelow() {
        let ctx = makeContext()
        #expect(ctx.evaluateScript("nc.clamp(-5, 0, 10)")?.toDouble() == 0)
    }

    @Test("smoothstep(0, 1, 0.5) is approximately 0.5")
    func smoothstepMidpoint() throws {
        let ctx = makeContext()
        let val = try #require(ctx.evaluateScript("nc.smoothstep(0, 1, 0.5)")?.toDouble())
        #expect(abs(val - 0.5) < 0.01)
    }

    @Test("map(5, 0, 10, 0, 100) == 50")
    func mapFunction() {
        let ctx = makeContext()
        #expect(ctx.evaluateScript("nc.map(5, 0, 10, 0, 100)")?.toDouble() == 50)
    }

    // MARK: - Color

    @Test("hexToRgb('#ff0000') returns correct components")
    func hexToRgb() throws {
        let ctx = makeContext()
        let result = try #require(ctx.evaluateScript("nc.hexToRgb('#ff0000')"))
        #expect(result.forProperty("r")?.toInt32() == 255)
        #expect(result.forProperty("g")?.toInt32() == 0)
        #expect(result.forProperty("b")?.toInt32() == 0)
        #expect(result.forProperty("a")?.toInt32() == 1)
    }

    @Test("rgba(255, 0, 0, 0.5) returns correct CSS string")
    func rgbaFunction() throws {
        let ctx = makeContext()
        let result = try #require(ctx.evaluateScript("nc.rgba(255, 0, 0, 0.5)")?.toString())
        #expect(result == "rgba(255, 0, 0, 0.5)")
    }

    @Test("lerpColor interpolates between colors")
    func lerpColorFunction() throws {
        let ctx = makeContext()
        let result = try #require(ctx.evaluateScript("nc.lerpColor('#ff0000', '#0000ff', 0.5)")?.toString())
        #expect(result.hasPrefix("rgba("))
        #expect(result.contains("128"))
    }

    // MARK: - Math

    @Test("random(42) is deterministic")
    func randomDeterministic() throws {
        let ctx = makeContext()
        let r1 = try #require(ctx.evaluateScript("nc.random(42)")?.toDouble())
        let r2 = try #require(ctx.evaluateScript("nc.random(42)")?.toDouble())
        #expect(r1 == r2)
    }

    @Test("random(42) != random(43)")
    func randomDifferentSeeds() throws {
        let ctx = makeContext()
        let r1 = try #require(ctx.evaluateScript("nc.random(42)")?.toDouble())
        let r2 = try #require(ctx.evaluateScript("nc.random(43)")?.toDouble())
        #expect(r1 != r2)
    }

    @Test("noise returns value in [0,1]")
    func noiseRange() throws {
        let ctx = makeContext()
        let val = try #require(ctx.evaluateScript("nc.noise(0.5, 0.5, 0)")?.toDouble())
        #expect(val >= 0 && val <= 1)
    }

    @Test("degToRad and radToDeg are inverses")
    func degRadConversion() throws {
        let ctx = makeContext()
        let rad = try #require(ctx.evaluateScript("nc.degToRad(180)")?.toDouble())
        #expect(abs(rad - Double.pi) < 0.001)
        let deg = try #require(ctx.evaluateScript("nc.radToDeg(Math.PI)")?.toDouble())
        #expect(abs(deg - 180) < 0.001)
    }

    // MARK: - Layout

    @Test("safeArea returns 5% insets")
    func safeAreaInsets() throws {
        let ctx = makeContext()
        let result = try #require(ctx.evaluateScript("nc.safeArea({width: 1920, height: 1080})"))
        #expect(result.forProperty("left")?.toDouble() == 96)
        #expect(result.forProperty("top")?.toDouble() == 54)
        #expect(result.forProperty("right")?.toDouble() == 1824)
        #expect(result.forProperty("bottom")?.toDouble() == 1026)
    }

    @Test("grid returns correct number of cells")
    func gridCells() throws {
        let ctx = makeContext()
        let result = try #require(ctx.evaluateScript("nc.grid({width: 1920, height: 1080}, 3, 2)"))
        #expect(result.forProperty("length")?.toInt32() == 6)
        let first = try #require(result.atIndex(0))
        #expect(first.forProperty("x")?.toDouble() == 0)
        #expect(first.forProperty("y")?.toDouble() == 0)
        #expect(first.forProperty("width")?.toDouble() == 640)
        #expect(first.forProperty("height")?.toDouble() == 540)
    }

    // MARK: - Drawing Helpers

    @Test("roundRect builds a path that can be filled")
    func roundRectPath() throws {
        let ctx = makeContext()
        let bridge = CanvasBridge(width: 100, height: 100)
        let ctxValue = try #require(JSValue(newObjectIn: ctx))
        bridge.installInto(ctxValue)
        ctx.setObject(ctxValue, forKeyedSubscript: "__testCtx" as NSString)

        ctx.evaluateScript("nc.roundRect(__testCtx, 10, 10, 80, 80, 5); __testCtx.fillStyle = 'red'; __testCtx.fill();")

        let image = try #require(bridge.makeImage())
        let pixel = pixelColor(at: 50, y: 50, in: image)
        #expect(pixel.a > 0.5)
    }

    // MARK: - Pixel Helper

    private func pixelColor(at x: Int, y: Int, in image: CGImage) -> (r: Float, g: Float, b: Float, a: Float) {
        let colorSpace = CGColorSpace(name: CGColorSpace.extendedLinearSRGB)!
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.floatComponents.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)

        let width = image.width
        let height = image.height
        let bytesPerRow = width * 16

        var pixelData = [Float](repeating: 0, count: width * height * 4)
        guard let ctx = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 32,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return (0, 0, 0, 0)
        }

        ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        let offset = (y * width + x) * 4
        return (pixelData[offset], pixelData[offset + 1], pixelData[offset + 2], pixelData[offset + 3])
    }
}
