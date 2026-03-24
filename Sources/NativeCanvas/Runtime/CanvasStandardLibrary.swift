//
//  CanvasStandardLibrary.swift
//  NativeCanvas
//

#if canImport(AppKit)
    import AppKit
#elseif canImport(UIKit)
    import UIKit
#endif
import CoreText
import Foundation
import JavaScriptCore

/// Injects the nc standard library into a JSContext.
///
/// The `nc` object provides resolution-independent utilities, easing functions,
/// color helpers, math utilities, and drawing helpers that templates use to
/// render graphics at any resolution.
///
/// Most functions are pure JavaScript evaluated once at install time.
/// Typography functions (`measureText`, `wrapText`, `fitText`) bridge to
/// Core Text via `@convention(block)` closures.
public nonisolated enum CanvasStandardLibrary {
    /// Installs the nc standard library into a JSContext.
    ///
    /// - Parameters:
    ///   - jsContext: The context to install into
    ///   - viewportWidth: Canvas width in pixels
    ///   - viewportHeight: Canvas height in pixels
    public static func install(into jsContext: JSContext, viewportWidth: Int, viewportHeight: Int) {
        let diagonal = sqrt(Double(viewportWidth * viewportWidth + viewportHeight * viewportHeight))
        let pointScale = diagonal / 2000.0

        jsContext.evaluateScript(pureJSLibrary(pointScale: pointScale))
        installTypographyBridges(into: jsContext)
    }

    // MARK: - Pure JS Library

    private static func pureJSLibrary(pointScale: Double) -> String {
        """
        var nc = (function() {
            var _pointScale = \(pointScale);

            // Resolution
            function pt(value) { return value * _pointScale; }

            // Easing
            function easeIn(t) { return t * t * t; }
            function easeOut(t) { return 1 - Math.pow(1 - t, 3); }
            function easeInOut(t) {
                return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;
            }
            function spring(t, tension, friction) {
                tension = tension || 300;
                friction = friction || 20;
                var decay = Math.exp(-friction * t / 2);
                var omega = Math.sqrt(Math.max(tension - (friction * friction / 4), 0));
                return 1 - decay * Math.cos(omega * t);
            }
            function steps(t, n) {
                n = n || 4;
                return Math.floor(t * n) / n;
            }
            function bounce(t) {
                var n1 = 7.5625;
                var d1 = 2.75;
                if (t < 1 / d1) {
                    return n1 * t * t;
                } else if (t < 2 / d1) {
                    t -= 1.5 / d1;
                    return n1 * t * t + 0.75;
                } else if (t < 2.5 / d1) {
                    t -= 2.25 / d1;
                    return n1 * t * t + 0.9375;
                } else {
                    t -= 2.625 / d1;
                    return n1 * t * t + 0.984375;
                }
            }

            // Interpolation
            function lerp(a, b, t) { return a + (b - a) * t; }
            function clamp(v, min, max) { return Math.max(min, Math.min(max, v)); }
            function map(v, inMin, inMax, outMin, outMax) {
                return outMin + (outMax - outMin) * ((v - inMin) / (inMax - inMin));
            }
            function smoothstep(edge0, edge1, t) {
                var x = clamp((t - edge0) / (edge1 - edge0), 0, 1);
                return x * x * (3 - 2 * x);
            }

            // Color
            function parseColor(c) {
                if (typeof c === 'object' && c.r !== undefined) return c;
                var m;
                // rgba(r, g, b, a)
                m = c.match(/^rgba\\((\\d+),\\s*(\\d+),\\s*(\\d+),\\s*([\\d.]+)\\)$/);
                if (m) return { r: parseInt(m[1]), g: parseInt(m[2]), b: parseInt(m[3]), a: parseFloat(m[4]) };
                // rgb(r, g, b)
                m = c.match(/^rgb\\((\\d+),\\s*(\\d+),\\s*(\\d+)\\)$/);
                if (m) return { r: parseInt(m[1]), g: parseInt(m[2]), b: parseInt(m[3]), a: 1 };
                // Named colors
                var named = {
                    'red': '#ff0000', 'green': '#008000', 'blue': '#0000ff',
                    'white': '#ffffff', 'black': '#000000', 'yellow': '#ffff00',
                    'cyan': '#00ffff', 'magenta': '#ff00ff', 'orange': '#ffa500',
                    'purple': '#800080', 'transparent': '#00000000'
                };
                if (named[c]) c = named[c];
                // Hex
                if (c.charAt(0) === '#') {
                    var hex = c.substring(1);
                    if (hex.length === 3) hex = hex[0]+hex[0]+hex[1]+hex[1]+hex[2]+hex[2];
                    if (hex.length === 6) hex += 'ff';
                    return {
                        r: parseInt(hex.substring(0, 2), 16),
                        g: parseInt(hex.substring(2, 4), 16),
                        b: parseInt(hex.substring(4, 6), 16),
                        a: parseInt(hex.substring(6, 8), 16) / 255
                    };
                }
                return { r: 0, g: 0, b: 0, a: 1 };
            }

            function hexToRgb(hex) {
                return parseColor(hex);
            }

            function rgba(r, g, b, a) {
                if (a === undefined) a = 1;
                return 'rgba(' + Math.round(r) + ', ' + Math.round(g) + ', ' + Math.round(b) + ', ' + a + ')';
            }

            function lerpColor(a, b, t) {
                var ca = parseColor(a);
                var cb = parseColor(b);
                return rgba(
                    lerp(ca.r, cb.r, t),
                    lerp(ca.g, cb.g, t),
                    lerp(ca.b, cb.b, t),
                    lerp(ca.a, cb.a, t)
                );
            }

            // Math
            function random(seed) {
                return (Math.sin(seed * 78233) * 43758.5453) % 1;
            }
            // Ensure positive result
            function _random(seed) {
                var v = random(seed);
                return v < 0 ? v + 1 : v;
            }
            function noise(x, y, seed) {
                seed = seed || 0;
                var ix = Math.floor(x);
                var iy = Math.floor(y);
                var fx = x - ix;
                var fy = y - iy;
                var v00 = _random(ix + iy * 57 + seed);
                var v10 = _random((ix + 1) + iy * 57 + seed);
                var v01 = _random(ix + (iy + 1) * 57 + seed);
                var v11 = _random((ix + 1) + (iy + 1) * 57 + seed);
                var i1 = lerp(v00, v10, fx);
                var i2 = lerp(v01, v11, fx);
                return lerp(i1, i2, fy);
            }
            function degToRad(d) { return d * Math.PI / 180; }
            function radToDeg(r) { return r * 180 / Math.PI; }

            // Drawing
            function roundRect(ctx, x, y, w, h, r) {
                if (r > Math.min(w, h) / 2) r = Math.min(w, h) / 2;
                ctx.beginPath();
                ctx.moveTo(x + r, y);
                ctx.arcTo(x + w, y, x + w, y + h, r);
                ctx.arcTo(x + w, y + h, x, y + h, r);
                ctx.arcTo(x, y + h, x, y, r);
                ctx.arcTo(x, y, x + w, y, r);
                ctx.closePath();
            }

            function drawTextWithShadow(ctx, text, x, y, opts) {
                opts = opts || {};
                ctx.save();
                if (opts.shadowColor) ctx.shadowColor = opts.shadowColor;
                if (opts.shadowBlur !== undefined) ctx.shadowBlur = opts.shadowBlur;
                if (opts.shadowOffsetX !== undefined) ctx.shadowOffsetX = opts.shadowOffsetX;
                if (opts.shadowOffsetY !== undefined) ctx.shadowOffsetY = opts.shadowOffsetY;
                ctx.fillText(text, x, y);
                ctx.restore();
            }

            function highlightWord(ctx, word, rect, color) {
                ctx.save();
                ctx.fillStyle = color || 'rgba(255, 255, 0, 0.3)';
                ctx.fillRect(rect.x, rect.y, rect.width, rect.height);
                ctx.restore();
            }

            // Layout
            function safeArea(viewport) {
                var insetX = viewport.width * 0.05;
                var insetY = viewport.height * 0.05;
                return {
                    top: insetY,
                    bottom: viewport.height - insetY,
                    left: insetX,
                    right: viewport.width - insetX
                };
            }

            function grid(viewport, cols, rows) {
                var cells = [];
                var cellW = viewport.width / cols;
                var cellH = viewport.height / rows;
                for (var r = 0; r < rows; r++) {
                    for (var c = 0; c < cols; c++) {
                        cells.push({ x: c * cellW, y: r * cellH, width: cellW, height: cellH });
                    }
                }
                return cells;
            }

            return {
                pt: pt,
                easeIn: easeIn, easeOut: easeOut, easeInOut: easeInOut,
                spring: spring, steps: steps, bounce: bounce,
                lerp: lerp, clamp: clamp, map: map, smoothstep: smoothstep,
                hexToRgb: hexToRgb, rgba: rgba, lerpColor: lerpColor,
                random: random, noise: noise, degToRad: degToRad, radToDeg: radToDeg,
                roundRect: roundRect, drawTextWithShadow: drawTextWithShadow, highlightWord: highlightWord,
                safeArea: safeArea, grid: grid
            };
        })();
        """
    }

    // MARK: - Typography Bridges

    private static func installTypographyBridges(into jsContext: JSContext) {
        guard let nc = jsContext.objectForKeyedSubscript("nc") else { return }

        // measureText(text, fontFamily, size) → {width, height}
        let measureBlock: @convention(block) (String, String, Double) -> [String: Double] = { text, fontFamily, size in
            let fontString = "\(Int(size))px \(fontFamily)"
            let ctFont = CanvasFontParser.parse(fontString)
            let attrs: [NSAttributedString.Key: Any] = [.font: ctFont]
            let attrString = NSAttributedString(string: text, attributes: attrs)
            let line = CTLineCreateWithAttributedString(attrString)

            var ascent: CGFloat = 0
            var descent: CGFloat = 0
            let width = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, nil))

            return ["width": Double(width), "height": Double(ascent + descent)]
        }
        nc.setObject(measureBlock, forKeyedSubscript: "measureText" as NSString)

        // wrapText(text, maxWidth, fontFamily, size) → string[]
        let wrapBlock: @convention(block) (String, Double, String, Double) -> [String] = { text, maxWidth, fontFamily, size in
            let fontString = "\(Int(size))px \(fontFamily)"
            let ctFont = CanvasFontParser.parse(fontString)
            let words = text.split(separator: " ").map(String.init)
            var lines: [String] = []
            var currentLine = ""

            for word in words {
                let testLine = currentLine.isEmpty ? word : "\(currentLine) \(word)"
                let attrs: [NSAttributedString.Key: Any] = [.font: ctFont]
                let attrString = NSAttributedString(string: testLine, attributes: attrs)
                let line = CTLineCreateWithAttributedString(attrString)
                let width = CTLineGetTypographicBounds(line, nil, nil, nil)

                if width > maxWidth, !currentLine.isEmpty {
                    lines.append(currentLine)
                    currentLine = word
                } else {
                    currentLine = testLine
                }
            }
            if !currentLine.isEmpty {
                lines.append(currentLine)
            }
            return lines
        }
        nc.setObject(wrapBlock, forKeyedSubscript: "wrapText" as NSString)

        // fitText(text, maxWidth, fontFamily) → number (largest font size that fits)
        let fitBlock: @convention(block) (String, Double, String) -> Double = { text, maxWidth, fontFamily in
            var low = 1.0
            var high = 500.0
            var result = low

            while high - low > 0.5 {
                let mid = (low + high) / 2
                let fontString = "\(Int(mid))px \(fontFamily)"
                let ctFont = CanvasFontParser.parse(fontString)
                let attrs: [NSAttributedString.Key: Any] = [.font: ctFont]
                let attrString = NSAttributedString(string: text, attributes: attrs)
                let line = CTLineCreateWithAttributedString(attrString)
                let width = CTLineGetTypographicBounds(line, nil, nil, nil)

                if width <= maxWidth {
                    result = mid
                    low = mid
                } else {
                    high = mid
                }
            }
            return result
        }
        nc.setObject(fitBlock, forKeyedSubscript: "fitText" as NSString)
    }
}
