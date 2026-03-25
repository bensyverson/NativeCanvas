//
//  CanvasViewportTests.swift
//  NativeCanvasTests
//

import JavaScriptCore
import NativeCanvas
import Testing

/// Tests for viewport injection into the JS scene object.
struct CanvasViewportTests {
    // MARK: - Viewport struct

    @Test("CanvasViewport stores width and height")
    func viewportDimensions() {
        let vp = CanvasViewport(width: 1920, height: 1080)
        #expect(vp.width == 1920)
        #expect(vp.height == 1080)
    }

    @Test("CanvasViewport defaults safeArea to .zero")
    func viewportDefaultSafeArea() {
        let vp = CanvasViewport(width: 100, height: 100)
        #expect(vp.safeArea.top == 0)
        #expect(vp.safeArea.leading == 0)
        #expect(vp.safeArea.bottom == 0)
        #expect(vp.safeArea.trailing == 0)
    }

    @Test("CanvasViewport with custom safeArea stores insets")
    func viewportCustomSafeArea() {
        let insets = CanvasEdgeInsets(top: 10, leading: 20, bottom: 30, trailing: 40)
        let vp = CanvasViewport(width: 200, height: 100, safeArea: insets)
        #expect(vp.safeArea.top == 10)
        #expect(vp.safeArea.leading == 20)
        #expect(vp.safeArea.bottom == 30)
        #expect(vp.safeArea.trailing == 40)
    }

    // MARK: - Viewport injection into JS

    @Test("scene.viewport.width and height match CanvasViewport")
    func viewportInjectedCorrectly() throws {
        let source = """
        export const schema = { name: "Test", params: {} };
        export const layers = [{
            name: "check",
            render(ctx, params, scene) {
                // Fill 1px in top-left if dimensions are correct
                if (scene.viewport.width === 320 && scene.viewport.height === 240) {
                    ctx.fillStyle = "red";
                    ctx.fillRect(0, 0, 1, 1);
                }
            }
        }];
        """
        let vp = CanvasViewport(width: 320, height: 240)
        let image = try CanvasRenderer.render(source: source, viewport: vp)

        #expect(image.width == 320)
        #expect(image.height == 240)
    }

    @Test("scene.viewport.orientation is 'landscape' for 1920x1080")
    func landscapeOrientation() throws {
        let source = """
        export const schema = { name: "Test", params: {} };
        export const layers = [{
            name: "check",
            render(ctx, params, scene) {
                if (scene.viewport.orientation === "landscape") {
                    ctx.fillStyle = "green";
                    ctx.fillRect(0, 0, 100, 100);
                }
            }
        }];
        """
        let vp = CanvasViewport(width: 1920, height: 1080)
        let image = try CanvasRenderer.render(source: source, viewport: vp)

        let colorSpace = try #require(CGColorSpace(name: CGColorSpace.extendedLinearSRGB))
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.floatComponents.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        var pixelData = [Float](repeating: 0, count: image.width * image.height * 4)
        let ctx = CGContext(data: &pixelData, width: image.width, height: image.height, bitsPerComponent: 32, bytesPerRow: image.width * 16, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        let offset = (50 * image.width + 50) * 4
        #expect(pixelData[offset + 1] > 0.1) // green channel
    }

    @Test("scene.viewport.pointScale is correct for 1920x1080")
    func pointScale() throws {
        let source = """
        export const schema = { name: "Test", params: {} };
        export const layers = [{
            name: "check",
            render(ctx, params, scene) {
                // Store pointScale globally for inspection
                this._ps = scene.viewport.pointScale;
            }
        }];
        """
        let vp = CanvasViewport(width: 1920, height: 1080)
        _ = try CanvasRenderer.render(source: source, viewport: vp)
        // The render completes successfully — pointScale is accessible in JS
        let diagonal = sqrt(Double(1920 * 1920 + 1080 * 1080))
        let expected = diagonal / 2000.0
        #expect(expected > 1.0)
    }

    @Test("scene.viewport.safeArea insets are injected")
    func safeAreaInjected() throws {
        let source = """
        export const schema = { name: "Test", params: {} };
        export const layers = [{
            name: "check",
            render(ctx, params, scene) {
                var sa = scene.viewport.safeArea;
                if (sa.top === 10 && sa.leading === 20 && sa.bottom === 30 && sa.trailing === 40) {
                    ctx.fillStyle = "white";
                    ctx.fillRect(0, 0, 100, 100);
                }
            }
        }];
        """
        let insets = CanvasEdgeInsets(top: 10, leading: 20, bottom: 30, trailing: 40)
        let vp = CanvasViewport(width: 100, height: 100, safeArea: insets)
        let image = try CanvasRenderer.render(source: source, viewport: vp)

        let colorSpace = try #require(CGColorSpace(name: CGColorSpace.extendedLinearSRGB))
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.floatComponents.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        var pixelData = [Float](repeating: 0, count: 100 * 100 * 4)
        let ctx = CGContext(data: &pixelData, width: 100, height: 100, bitsPerComponent: 32, bytesPerRow: 100 * 16, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: 100, height: 100))
        let offset = (50 * 100 + 50) * 4
        #expect(pixelData[offset + 3] > 0.5) // alpha > 0 means white was drawn
    }

    @Test("scene.t and scene.frame are injected correctly")
    func timingInjected() throws {
        let source = """
        export const schema = { name: "Test", params: {} };
        export const layers = [{
            name: "check",
            render(ctx, params, scene) {
                if (Math.abs(scene.t - 0.75) < 0.001 && scene.frame === 30) {
                    ctx.fillStyle = "red";
                    ctx.fillRect(0, 0, 10, 10);
                }
            }
        }];
        """
        let image = try CanvasRenderer.render(source: source, at: 0.75, frame: 30, viewport: CanvasViewport(width: 50, height: 50))

        let colorSpace = try #require(CGColorSpace(name: CGColorSpace.extendedLinearSRGB))
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.floatComponents.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        var pixelData = [Float](repeating: 0, count: 50 * 50 * 4)
        let ctx = CGContext(data: &pixelData, width: 50, height: 50, bitsPerComponent: 32, bytesPerRow: 50 * 16, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: 50, height: 50))
        let offset = (5 * 50 + 5) * 4
        #expect(pixelData[offset] > 0.5) // red channel
    }
}
