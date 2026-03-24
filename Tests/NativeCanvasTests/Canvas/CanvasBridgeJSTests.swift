//
//  CanvasBridgeJSTests.swift
//  NativeCanvasTests
//

import CoreGraphics
import JavaScriptCore
import NativeCanvas
import Testing

/// Tests for the Canvas 2D bridge driven from JavaScript via JSCore
struct CanvasBridgeJSTests {
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

    private func isClose(_ a: Float, _ b: Float, tolerance: Float = 0.01) -> Bool {
        abs(a - b) < tolerance
    }

    // MARK: - JS-Driven Drawing

    @Test("JS fillRect draws red pixels")
    func jsFillRect() throws {
        let bridge = CanvasBridge(width: 10, height: 10)
        let jsContext = try #require(JSContext())

        let ctxValue = try #require(JSValue(newObjectIn: jsContext))
        bridge.installInto(ctxValue)
        jsContext.setObject(ctxValue, forKeyedSubscript: "ctx" as NSString)

        jsContext.evaluateScript("""
            ctx.fillStyle = "red";
            ctx.fillRect(0, 0, 5, 5);
        """)

        guard let image = bridge.makeImage() else {
            Issue.record("Failed to create image")
            return
        }

        let inside = pixelColor(at: 2, y: 2, in: image)
        #expect(isClose(inside.r, 1.0))
        #expect(isClose(inside.g, 0.0))
        #expect(isClose(inside.b, 0.0))
        #expect(isClose(inside.a, 1.0))

        let outside = pixelColor(at: 7, y: 7, in: image)
        #expect(isClose(outside.a, 0.0))
    }

    @Test("JS path drawing creates filled shape")
    func jsPathDrawing() throws {
        let bridge = CanvasBridge(width: 20, height: 20)
        let jsContext = try #require(JSContext())

        let ctxValue = try #require(JSValue(newObjectIn: jsContext))
        bridge.installInto(ctxValue)
        jsContext.setObject(ctxValue, forKeyedSubscript: "ctx" as NSString)

        jsContext.evaluateScript("""
            ctx.fillStyle = "#0000ff";
            ctx.beginPath();
            ctx.arc(10, 10, 5, 0, Math.PI * 2);
            ctx.fill();
        """)

        guard let image = bridge.makeImage() else {
            Issue.record("Failed to create image")
            return
        }

        let center = pixelColor(at: 10, y: 10, in: image)
        #expect(isClose(center.b, 1.0))
        #expect(isClose(center.a, 1.0))

        let corner = pixelColor(at: 0, y: 0, in: image)
        #expect(isClose(corner.a, 0.0))
    }

    @Test("JS save/restore works correctly")
    func jsSaveRestore() throws {
        let bridge = CanvasBridge(width: 10, height: 10)
        let jsContext = try #require(JSContext())

        let ctxValue = try #require(JSValue(newObjectIn: jsContext))
        bridge.installInto(ctxValue)
        jsContext.setObject(ctxValue, forKeyedSubscript: "ctx" as NSString)

        jsContext.evaluateScript("""
            ctx.fillStyle = "red";
            ctx.save();
            ctx.fillStyle = "blue";
            ctx.fillRect(0, 0, 5, 5);
            ctx.restore();
            ctx.fillRect(5, 0, 5, 5);
        """)

        guard let image = bridge.makeImage() else {
            Issue.record("Failed to create image")
            return
        }

        let left = pixelColor(at: 2, y: 2, in: image)
        #expect(isClose(left.b, 1.0))

        let right = pixelColor(at: 7, y: 2, in: image)
        #expect(isClose(right.r, 1.0))
    }

    @Test("JS property getters return correct values")
    func jsPropertyGetters() throws {
        let bridge = CanvasBridge(width: 10, height: 10)
        let jsContext = try #require(JSContext())

        let ctxValue = try #require(JSValue(newObjectIn: jsContext))
        bridge.installInto(ctxValue)
        jsContext.setObject(ctxValue, forKeyedSubscript: "ctx" as NSString)

        jsContext.evaluateScript("""
            ctx.lineWidth = 3.0;
            ctx.lineCap = "round";
            ctx.lineJoin = "bevel";
            ctx.globalAlpha = 0.5;
        """)

        let lineWidth = jsContext.evaluateScript("ctx.lineWidth")?.toDouble()
        #expect(lineWidth == 3.0)

        let lineCap = jsContext.evaluateScript("ctx.lineCap")?.toString()
        #expect(lineCap == "round")

        let lineJoin = jsContext.evaluateScript("ctx.lineJoin")?.toString()
        #expect(lineJoin == "bevel")

        let alpha = jsContext.evaluateScript("ctx.globalAlpha")?.toDouble()
        #expect(alpha == 0.5)
    }

    @Test("JS transform operations work")
    func jsTransforms() throws {
        let bridge = CanvasBridge(width: 20, height: 20)
        let jsContext = try #require(JSContext())

        let ctxValue = try #require(JSValue(newObjectIn: jsContext))
        bridge.installInto(ctxValue)
        jsContext.setObject(ctxValue, forKeyedSubscript: "ctx" as NSString)

        jsContext.evaluateScript("""
            ctx.fillStyle = "#ff0000";
            ctx.translate(10, 10);
            ctx.fillRect(0, 0, 5, 5);
        """)

        guard let image = bridge.makeImage() else {
            Issue.record("Failed to create image")
            return
        }

        let origin = pixelColor(at: 0, y: 0, in: image)
        #expect(isClose(origin.a, 0.0))

        let shifted = pixelColor(at: 12, y: 12, in: image)
        #expect(isClose(shifted.r, 1.0))
    }

    @Test("JS clearRect works")
    func jsClearRect() throws {
        let bridge = CanvasBridge(width: 10, height: 10)
        let jsContext = try #require(JSContext())

        let ctxValue = try #require(JSValue(newObjectIn: jsContext))
        bridge.installInto(ctxValue)
        jsContext.setObject(ctxValue, forKeyedSubscript: "ctx" as NSString)

        jsContext.evaluateScript("""
            ctx.fillStyle = "blue";
            ctx.fillRect(0, 0, 10, 10);
            ctx.clearRect(2, 2, 4, 4);
        """)

        guard let image = bridge.makeImage() else {
            Issue.record("Failed to create image")
            return
        }

        let cleared = pixelColor(at: 3, y: 3, in: image)
        #expect(isClose(cleared.a, 0.0))

        let filled = pixelColor(at: 0, y: 0, in: image)
        #expect(isClose(filled.b, 1.0))
    }
}
