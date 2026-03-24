//
//  CanvasBridgeTests.swift
//  NativeCanvasTests
//

import CoreGraphics
import NativeCanvas
import Testing

/// Tests for the Canvas 2D to Core Graphics bridge
struct CanvasBridgeTests {
    // MARK: - Pixel Verification Helper

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

    private func isClose(_ a: Float, _ b: Float, tolerance: Float = 0.01) -> Bool {
        abs(a - b) < tolerance
    }

    // MARK: - Context Creation

    @Test("Creates a valid context and produces an image")
    func contextCreation() {
        let bridge = CanvasBridge(width: 10, height: 10)
        let image = bridge.makeImage()
        #expect(image != nil)
        #expect(image?.width == 10)
        #expect(image?.height == 10)
    }

    // MARK: - fillRect

    @Test("fillRect draws correct color at correct position")
    func fillRectDrawsColor() {
        let bridge = CanvasBridge(width: 10, height: 10)
        bridge.setFillStyle("#ff0000")
        bridge.fillRect(x: 0, y: 0, width: 5, height: 5)

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

    // MARK: - strokeRect

    @Test("strokeRect draws border but not interior")
    func strokeRectDrawsBorder() {
        let bridge = CanvasBridge(width: 20, height: 20)
        bridge.setStrokeStyle("#00ff00")
        bridge.lineWidth = 1.0
        bridge.strokeRect(x: 5, y: 5, width: 10, height: 10)

        guard let image = bridge.makeImage() else {
            Issue.record("Failed to create image")
            return
        }

        let border = pixelColor(at: 5, y: 5, in: image)
        #expect(border.g > 0.5)

        let interior = pixelColor(at: 10, y: 10, in: image)
        #expect(isClose(interior.a, 0.0))
    }

    // MARK: - clearRect

    @Test("clearRect makes pixels transparent")
    func clearRectMakesTransparent() {
        let bridge = CanvasBridge(width: 10, height: 10)
        bridge.setFillStyle("#ff0000")
        bridge.fillRect(x: 0, y: 0, width: 10, height: 10)
        bridge.clearRect(x: 2, y: 2, width: 4, height: 4)

        guard let image = bridge.makeImage() else {
            Issue.record("Failed to create image")
            return
        }

        let cleared = pixelColor(at: 3, y: 3, in: image)
        #expect(isClose(cleared.a, 0.0))

        let uncleared = pixelColor(at: 0, y: 0, in: image)
        #expect(isClose(uncleared.r, 1.0))
        #expect(isClose(uncleared.a, 1.0))
    }

    // MARK: - State Management

    @Test("save/restore preserves and restores fillStyle")
    func saveRestoreFillStyle() {
        let bridge = CanvasBridge(width: 10, height: 10)

        bridge.setFillStyle("#ff0000")
        bridge.save()
        bridge.setFillStyle("#0000ff")

        bridge.fillRect(x: 0, y: 0, width: 5, height: 5)
        bridge.restore()

        bridge.fillRect(x: 5, y: 0, width: 5, height: 5)

        guard let image = bridge.makeImage() else {
            Issue.record("Failed to create image")
            return
        }

        let left = pixelColor(at: 2, y: 2, in: image)
        #expect(isClose(left.b, 1.0))

        let right = pixelColor(at: 7, y: 2, in: image)
        #expect(isClose(right.r, 1.0))
    }

    @Test("save/restore preserves lineWidth")
    func saveRestoreLineWidth() {
        let bridge = CanvasBridge(width: 10, height: 10)
        bridge.lineWidth = 3.0
        bridge.save()
        bridge.lineWidth = 1.0
        bridge.restore()
        #expect(bridge.currentState.lineWidth == 3.0)
    }

    // MARK: - Path Drawing

    @Test("Path-based triangle fill produces filled pixels")
    func pathTriangleFill() {
        let bridge = CanvasBridge(width: 10, height: 10)
        bridge.setFillStyle("#00ff00")

        bridge.beginPath()
        bridge.moveTo(x: 0, y: 0)
        bridge.lineTo(x: 10, y: 0)
        bridge.lineTo(x: 5, y: 10)
        bridge.closePath()
        bridge.fill()

        guard let image = bridge.makeImage() else {
            Issue.record("Failed to create image")
            return
        }

        let inside = pixelColor(at: 5, y: 2, in: image)
        #expect(isClose(inside.g, 1.0))
        #expect(isClose(inside.a, 1.0))
    }

    @Test("arc draws circular pixels")
    func arcDrawsCircle() {
        let bridge = CanvasBridge(width: 20, height: 20)
        bridge.setFillStyle("#0000ff")

        bridge.beginPath()
        bridge.arc(x: 10, y: 10, radius: 5, startAngle: 0, endAngle: .pi * 2)
        bridge.fill()

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

    @Test("beginPath clears previous path")
    func beginPathClears() {
        let bridge = CanvasBridge(width: 10, height: 10)
        bridge.setFillStyle("#ff0000")

        bridge.beginPath()
        bridge.moveTo(x: 0, y: 0)
        bridge.lineTo(x: 10, y: 0)
        bridge.lineTo(x: 10, y: 10)
        bridge.closePath()

        bridge.beginPath()
        bridge.fill()

        guard let image = bridge.makeImage() else {
            Issue.record("Failed to create image")
            return
        }

        let pixel = pixelColor(at: 5, y: 2, in: image)
        #expect(isClose(pixel.a, 0.0))
    }

    // MARK: - Transforms

    @Test("translate shifts drawing position")
    func translateShiftsDrawing() {
        let bridge = CanvasBridge(width: 20, height: 20)
        bridge.setFillStyle("#ff0000")
        bridge.translate(x: 10, y: 10)
        bridge.fillRect(x: 0, y: 0, width: 5, height: 5)

        guard let image = bridge.makeImage() else {
            Issue.record("Failed to create image")
            return
        }

        let origin = pixelColor(at: 0, y: 0, in: image)
        #expect(isClose(origin.a, 0.0))

        let shifted = pixelColor(at: 12, y: 12, in: image)
        #expect(isClose(shifted.r, 1.0))
        #expect(isClose(shifted.a, 1.0))
    }

    @Test("scale changes drawing size")
    func scaleChangesSize() {
        let bridge = CanvasBridge(width: 20, height: 20)
        bridge.setFillStyle("#ff0000")
        bridge.scale(x: 2, y: 2)
        bridge.fillRect(x: 0, y: 0, width: 5, height: 5)

        guard let image = bridge.makeImage() else {
            Issue.record("Failed to create image")
            return
        }

        let inside = pixelColor(at: 8, y: 8, in: image)
        #expect(isClose(inside.r, 1.0))

        let outside = pixelColor(at: 12, y: 12, in: image)
        #expect(isClose(outside.a, 0.0))
    }

    @Test("resetTransform restores to base flipped transform")
    func resetTransformRestoresBase() {
        let bridge = CanvasBridge(width: 10, height: 10)
        bridge.setFillStyle("#ff0000")
        bridge.translate(x: 100, y: 100)
        bridge.resetTransform()
        bridge.fillRect(x: 0, y: 0, width: 5, height: 5)

        guard let image = bridge.makeImage() else {
            Issue.record("Failed to create image")
            return
        }

        let pixel = pixelColor(at: 2, y: 2, in: image)
        #expect(isClose(pixel.r, 1.0))
        #expect(isClose(pixel.a, 1.0))
    }

    @Test("setTransform overrides current transform")
    func setTransformOverrides() {
        let bridge = CanvasBridge(width: 20, height: 20)
        bridge.setFillStyle("#ff0000")
        bridge.translate(x: 100, y: 100)
        bridge.setTransform(a: 1, b: 0, c: 0, d: 1, e: 5, f: 5)
        bridge.fillRect(x: 0, y: 0, width: 5, height: 5)

        guard let image = bridge.makeImage() else {
            Issue.record("Failed to create image")
            return
        }

        let pixel = pixelColor(at: 7, y: 7, in: image)
        #expect(isClose(pixel.r, 1.0))
        #expect(isClose(pixel.a, 1.0))

        let origin = pixelColor(at: 0, y: 0, in: image)
        #expect(isClose(origin.a, 0.0))
    }

    // MARK: - Clipping

    @Test("clip restricts drawing to clipped region")
    func clipRestrictsDrawing() {
        let bridge = CanvasBridge(width: 20, height: 20)

        bridge.beginPath()
        bridge.rect(x: 5, y: 5, width: 10, height: 10)
        bridge.clip()

        bridge.setFillStyle("#ff0000")
        bridge.fillRect(x: 0, y: 0, width: 20, height: 20)

        guard let image = bridge.makeImage() else {
            Issue.record("Failed to create image")
            return
        }

        let inside = pixelColor(at: 10, y: 10, in: image)
        #expect(isClose(inside.r, 1.0))
        #expect(isClose(inside.a, 1.0))

        let outside = pixelColor(at: 0, y: 0, in: image)
        #expect(isClose(outside.a, 0.0))
    }

    // MARK: - globalAlpha

    @Test("globalAlpha affects opacity of drawn content")
    func globalAlphaAffectsOpacity() {
        let bridge = CanvasBridge(width: 10, height: 10)
        bridge.setFillStyle("#ff0000")
        bridge.globalAlpha = 0.5
        bridge.fillRect(x: 0, y: 0, width: 10, height: 10)

        guard let image = bridge.makeImage() else {
            Issue.record("Failed to create image")
            return
        }

        let pixel = pixelColor(at: 5, y: 5, in: image)
        #expect(isClose(pixel.r, 0.5, tolerance: 0.05))
        #expect(isClose(pixel.a, 0.5, tolerance: 0.05))
    }

    // MARK: - Style Properties

    @Test("lineCapString round-trips correctly")
    func lineCapRoundTrip() {
        let bridge = CanvasBridge(width: 10, height: 10)
        #expect(bridge.lineCapString == "butt")

        bridge.lineCapString = "round"
        #expect(bridge.lineCapString == "round")

        bridge.lineCapString = "square"
        #expect(bridge.lineCapString == "square")
    }

    @Test("lineJoinString round-trips correctly")
    func lineJoinRoundTrip() {
        let bridge = CanvasBridge(width: 10, height: 10)
        #expect(bridge.lineJoinString == "miter")

        bridge.lineJoinString = "round"
        #expect(bridge.lineJoinString == "round")

        bridge.lineJoinString = "bevel"
        #expect(bridge.lineJoinString == "bevel")
    }

    @Test("globalCompositeOperation round-trips correctly")
    func compositeOperationRoundTrip() {
        let bridge = CanvasBridge(width: 10, height: 10)
        #expect(bridge.globalCompositeOperationString == "source-over")

        bridge.globalCompositeOperationString = "multiply"
        #expect(bridge.globalCompositeOperationString == "multiply")
    }

    // MARK: - Coordinate System

    @Test("Coordinate system has top-left origin (Y increases downward)")
    func topLeftOrigin() {
        let bridge = CanvasBridge(width: 10, height: 10)
        bridge.setFillStyle("#ff0000")
        bridge.fillRect(x: 0, y: 0, width: 5, height: 5)

        guard let image = bridge.makeImage() else {
            Issue.record("Failed to create image")
            return
        }

        let topLeft = pixelColor(at: 2, y: 2, in: image)
        #expect(isClose(topLeft.r, 1.0))

        let bottomRight = pixelColor(at: 7, y: 7, in: image)
        #expect(isClose(bottomRight.a, 0.0))
    }
}
