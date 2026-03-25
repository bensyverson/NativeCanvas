//
//  CanvasRendererScaleTests.swift
//  NativeCanvasTests
//

import CoreGraphics
import NativeCanvas
import Testing

struct CanvasRendererScaleTests {
    @Test("CanvasBridge at scale 2 produces a CGImage with 2x pixel dimensions")
    func bridgeScale2xDimensions() {
        let bridge = CanvasBridge(width: 100, height: 50, scale: 2)

        // Draw something so there's content
        bridge.setFillStyle("#ff0000")
        bridge.fillRect(x: 0, y: 0, width: 100, height: 50)

        guard let image = bridge.makeImage() else {
            Issue.record("Failed to create image")
            return
        }

        #expect(image.width == 200, "Image pixel width should be 2x the canvas width")
        #expect(image.height == 100, "Image pixel height should be 2x the canvas height")
    }

    @Test("CanvasBridge at scale 1 produces a CGImage with 1x pixel dimensions")
    func bridgeScale1xDimensions() {
        let bridge = CanvasBridge(width: 100, height: 50, scale: 1)

        bridge.setFillStyle("#ff0000")
        bridge.fillRect(x: 0, y: 0, width: 100, height: 50)

        guard let image = bridge.makeImage() else {
            Issue.record("Failed to create image")
            return
        }

        #expect(image.width == 100)
        #expect(image.height == 50)
    }

    @Test("CanvasRenderer.render with scale 2 produces 2x pixel dimensions")
    func rendererScale2xDimensions() throws {
        let source = """
            layers = [{
                name: "bg",
                render(ctx, params, scene) {
                    ctx.fillStyle = "red";
                    ctx.fillRect(0, 0, scene.viewport.width, scene.viewport.height);
                }
            }];
        """
        let viewport = CanvasViewport(width: 100, height: 50)
        let image = try CanvasRenderer.render(source: source, viewport: viewport, scale: 2)

        #expect(image.width == 200, "Rendered image pixel width should be 2x viewport width")
        #expect(image.height == 100, "Rendered image pixel height should be 2x viewport height")
    }

    @Test("CanvasRenderer.render with default scale produces 1x pixel dimensions")
    func rendererDefaultScaleDimensions() throws {
        let source = """
            layers = [{
                name: "bg",
                render(ctx, params, scene) {
                    ctx.fillStyle = "blue";
                    ctx.fillRect(0, 0, 100, 50);
                }
            }];
        """
        let viewport = CanvasViewport(width: 100, height: 50)
        let image = try CanvasRenderer.render(source: source, viewport: viewport)

        #expect(image.width == 100)
        #expect(image.height == 50)
    }

    @Test("Drawing coordinates at scale 2 remain in points (not pixels)")
    func scale2xDrawingCoordinatesArePoints() {
        // Fill a 50x50 rect at origin on a 100x100 canvas at scale 2.
        // The filled area should cover the top-left quadrant of the 200x200 pixel image.
        let bridge = CanvasBridge(width: 100, height: 100, scale: 2)
        bridge.setFillStyle("#ff0000")
        bridge.fillRect(x: 0, y: 0, width: 50, height: 50)

        guard let image = bridge.makeImage() else {
            Issue.record("Failed to create image")
            return
        }

        #expect(image.width == 200)
        #expect(image.height == 200)

        // Sample a pixel inside the fill area (in pixel coords, top-left quadrant)
        let inside = pixelAlpha(at: 50, y: 50, in: image)
        #expect(inside > 0.5, "Pixel at (50,50) should be inside the filled area")

        // Sample a pixel outside the fill area (bottom-right quadrant)
        let outside = pixelAlpha(at: 150, y: 150, in: image)
        #expect(outside < 0.01, "Pixel at (150,150) should be outside the filled area")
    }

    // MARK: - Helpers

    private func pixelAlpha(at x: Int, y: Int, in image: CGImage) -> Float {
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
            return 0
        }

        ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        let offset = (y * width + x) * 4
        return pixelData[offset + 3]
    }
}
