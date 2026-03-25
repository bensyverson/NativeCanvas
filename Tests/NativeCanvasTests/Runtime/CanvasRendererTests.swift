//
//  CanvasRendererTests.swift
//  NativeCanvasTests
//

import CoreGraphics
import NativeCanvas
import Testing

struct CanvasRendererTests {
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
        ) else { return (0, 0, 0, 0) }
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
        ) else { return false }
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        let minX = max(0, Int(region.minX))
        let maxX = min(width - 1, Int(region.maxX))
        let minY = max(0, Int(region.minY))
        let maxY = min(height - 1, Int(region.maxY))

        for y in stride(from: minY, through: maxY, by: 4) {
            for x in stride(from: minX, through: maxX, by: 4) {
                let offset = (y * width + x) * 4
                if pixelData[offset + 3] > 0.01 {
                    return true
                }
            }
        }
        return false
    }

    private let viewport100 = CanvasViewport(width: 100, height: 100)

    // MARK: - Basic Rendering

    @Test("Renders single-layer template that fills canvas red")
    func singleLayerRed() throws {
        let source = """
        export const schema = { name: "Red", params: {} };
        export const layers = [{
            name: "bg",
            render(ctx, params, scene) {
                ctx.fillStyle = "red";
                ctx.fillRect(0, 0, scene.viewport.width, scene.viewport.height);
            }
        }];
        """
        let image = try CanvasRenderer.render(source: source, viewport: viewport100)

        let pixel = pixelColor(at: 50, y: 50, in: image)
        #expect(pixel.r > 0.9)
        #expect(pixel.g < 0.1)
        #expect(pixel.b < 0.1)
        #expect(pixel.a > 0.9)
    }

    @Test("Two-layer template: second layer draws on top")
    func twoLayerCompositing() throws {
        let source = """
        export const schema = { name: "Two", params: {} };
        export const layers = [
            {
                name: "bg",
                render(ctx, params, scene) {
                    ctx.fillStyle = "red";
                    ctx.fillRect(0, 0, 100, 100);
                }
            },
            {
                name: "overlay",
                render(ctx, params, scene) {
                    ctx.fillStyle = "blue";
                    ctx.fillRect(25, 25, 50, 50);
                }
            }
        ];
        """
        let image = try CanvasRenderer.render(source: source, viewport: viewport100)

        let center = pixelColor(at: 50, y: 50, in: image)
        #expect(center.b > 0.9)
        #expect(center.r < 0.1)

        let corner = pixelColor(at: 5, y: 5, in: image)
        #expect(corner.r > 0.9)
        #expect(corner.b < 0.1)
    }

    @Test("Scene timing is passed correctly via t parameter")
    func sceneTimingPassedThrough() throws {
        let source = """
        export const schema = { name: "Timed", params: {} };
        export const layers = [{
            name: "bar",
            render(ctx, params, scene) {
                ctx.fillStyle = "white";
                ctx.fillRect(0, 0, scene.viewport.width * scene.t, 10);
            }
        }];
        """
        let image = try CanvasRenderer.render(source: source, at: 0.5, viewport: viewport100)

        let inside = pixelColor(at: 25, y: 5, in: image)
        #expect(inside.a > 0.5)

        let outside = pixelColor(at: 75, y: 5, in: image)
        #expect(outside.a < 0.1)
    }

    @Test("Missing render function on a layer is silently skipped")
    func missingRenderSkipped() throws {
        let source = """
        export const schema = { name: "NoRender", params: {} };
        export const layers = [
            { name: "broken" },
            {
                name: "working",
                render(ctx, params, scene) {
                    ctx.fillStyle = "green";
                    ctx.fillRect(0, 0, 100, 100);
                }
            }
        ];
        """
        let image = try CanvasRenderer.render(source: source, viewport: viewport100)

        let pixel = pixelColor(at: 50, y: 50, in: image)
        #expect(pixel.g > 0.1)
        #expect(pixel.a > 0.5)
    }

    @Test("Multiple renders are independent (no shared state)")
    func rendersAreIndependent() throws {
        let source = """
        export const schema = { name: "Reuse", params: {} };
        export const layers = [{
            name: "bg",
            render(ctx, params, scene) {
                ctx.fillStyle = scene.t > 0.5 ? "blue" : "red";
                ctx.fillRect(0, 0, 100, 100);
            }
        }];
        """

        let img1 = try CanvasRenderer.render(source: source, at: 0.3, viewport: viewport100)
        let p1 = pixelColor(at: 50, y: 50, in: img1)
        #expect(p1.r > 0.9)

        let img2 = try CanvasRenderer.render(source: source, at: 0.7, viewport: viewport100)
        let p2 = pixelColor(at: 50, y: 50, in: img2)
        #expect(p2.b > 0.9)
    }

    // MARK: - Scene Data

    @Test("User scene data is accessible in JS template")
    func userSceneData() throws {
        struct MyScene: Encodable, Sendable {
            let title: String
            let count: Int
        }

        let source = """
        export const schema = { name: "Scene", params: {} };
        export const layers = [{
            name: "check",
            render(ctx, params, scene) {
                // Fill red if title is correct, blue otherwise
                ctx.fillStyle = (scene.title === "hello" && scene.count === 42) ? "red" : "blue";
                ctx.fillRect(0, 0, 100, 100);
            }
        }];
        """
        let scene = MyScene(title: "hello", count: 42)
        let image = try CanvasRenderer.render(
            source: source,
            scene: scene,
            viewport: viewport100,
        )

        let pixel = pixelColor(at: 50, y: 50, in: image)
        #expect(pixel.r > 0.9)
        #expect(pixel.b < 0.1)
    }

    // MARK: - Proof of Life

    @Test("Proof of life: lower-third template renders at 1920x1080")
    func proofOfLife() throws {
        let vp = CanvasViewport(width: 1920, height: 1080)
        let image = try CanvasRenderer.render(source: lowerThirdSource, at: 0.5, viewport: vp)

        #expect(image.width == 1920)
        #expect(image.height == 1080)

        let hasPixels = hasAnyOpaquePixel(in: image, region: CGRect(x: 0, y: 1000, width: 1920, height: 80))
        #expect(hasPixels, "Lower region should have opaque pixels from the bar and text")

        let upperClear = !hasAnyOpaquePixel(in: image, region: CGRect(x: 0, y: 0, width: 1920, height: 500))
        #expect(upperClear, "Upper region should be transparent")
    }

    // MARK: - Lower-Third Template Source (updated to use nc namespace)

    private let lowerThirdSource = """
    export const schema = {
      name: "Lower Third",
      description: "Animated lower third with eyebrow and headline",
      version: "1.0.0",
      category: "title",
      tags: ["lower-third", "news", "minimal"],

      params: {
        eyebrowText:   { type: "string",  default: "EYEBROW" },
        headlineText:  { type: "string",  default: "Headline Text" },
        accentColor:   { type: "color",   default: "rgba(255, 59, 48, 1.0)" },
        textColor:     { type: "color",   default: "rgba(255, 255, 255, 1.0)" },
        font:          { type: "font",    default: { family: "Helvetica", weight: "bold" } },
        textSize:      { type: "float",   default: 32, min: 12, max: 96, animatable: true },
        alignment:     { type: "enum",    default: "left", options: ["left", "center", "right"] },
        showShadow:    { type: "bool",    default: true },
        opacity:       { type: "float",   default: 1.0, min: 0, max: 1.0, animatable: true },
      },
    };

    export const layers = [

      {
        name: "background",
        render(ctx, params, scene) {
          var w = scene.viewport.width;
          var h = scene.viewport.height;
          var barHeight = nc.pt(60);
          ctx.fillStyle = nc.rgba(0, 0, 0, 0.7);
          nc.roundRect(ctx, 0, h - barHeight, w, barHeight, nc.pt(4));
          ctx.fill();
        }
      },

      {
        name: "eyebrow",
        editableParam: "eyebrowText",
        render(ctx, params, scene) {
          var ease = nc.easeInOut(scene.t);
          var x = nc.lerp(-nc.pt(100), nc.pt(40), ease);
          ctx.fillStyle = params.accentColor;
          ctx.font = nc.pt(14) + "px " + params.font.family;
          ctx.fillText(params.eyebrowText, x, scene.viewport.height - nc.pt(38));
        }
      },

      {
        name: "headline",
        editableParam: "headlineText",
        render(ctx, params, scene) {
          var ease = nc.easeInOut(scene.t);
          var x = nc.lerp(-nc.pt(100), nc.pt(40), ease);
          ctx.fillStyle = params.textColor;
          ctx.font = "bold " + nc.pt(params.textSize) + "px " + params.font.family;
          ctx.fillText(params.headlineText, x, scene.viewport.height - nc.pt(12));
        }
      },

    ];
    """
}
