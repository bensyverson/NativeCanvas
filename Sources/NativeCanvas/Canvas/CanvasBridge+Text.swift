//
//  CanvasBridge+Text.swift
//  NativeCanvas
//

import CoreGraphics
import CoreText
import Foundation

public extension CanvasBridge {
    /// Fills text at the given position using the current fill style and font.
    ///
    /// When the active fill style is a gradient, the text is converted to a `CGPath`
    /// and used as a clipping mask so the gradient draws through the glyph outlines —
    /// matching the clip-then-draw pattern used by ``fill()`` and ``fillRect(x:y:width:height:)``.
    ///
    /// - Parameters:
    ///   - text: The string to draw.
    ///   - x: The x coordinate of the text anchor point.
    ///   - y: The y coordinate of the text anchor point.
    ///   - maxWidth: If provided and the text is wider than this value, a horizontal
    ///     scale transform is applied to squish it to fit — matching Canvas 2D spec behaviour.
    func fillText(text: String, x: Double, y: Double, maxWidth: Double? = nil) {
        let ctFont = CanvasFontParser.parse(currentState.fontString)

        if let gradient = fillGradient {
            // Gradient branch: build a CGPath from the glyphs, clip, then draw the gradient.
            let attrs: [NSAttributedString.Key: Any] = [.font: ctFont]
            let attrString = NSAttributedString(string: text, attributes: attrs)
            let line = CTLineCreateWithAttributedString(attrString)

            var ascent: CGFloat = 0
            var descent: CGFloat = 0
            let textWidth = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, nil))

            let alignedX = applyTextAlign(x: CGFloat(x), width: textWidth)
            let baselineY = applyTextBaseline(y: CGFloat(y), ascent: ascent, descent: descent)
            let scaleX = maxWidthScale(textWidth: textWidth, maxWidth: maxWidth)

            guard let glyphPath = glyphPath(from: line) else { return }

            // Position the path in canvas coordinates.
            // CoreText glyphs are drawn in a Y-up coordinate system; we apply a Y-flip
            // so the path integrates into the top-left-origin canvas space.
            var transform = CGAffineTransform.identity
                .translatedBy(x: alignedX, y: baselineY)
                .scaledBy(x: scaleX < 1.0 ? scaleX : 1.0, y: -1)
            let positionedPath = glyphPath.copy(using: &transform) ?? glyphPath

            // A transparency layer is needed so the shadow is cast by the
            // composite text shape rather than by the gradient draw alone.
            // Without it, shadow pixels fall outside the clip and are invisible.
            cgContext.saveGState()
            applyShadow()
            cgContext.setAlpha(currentState.globalAlpha)
            cgContext.beginTransparencyLayer(auxiliaryInfo: nil)
            cgContext.addPath(positionedPath)
            cgContext.clip()
            drawGradient(gradient)
            cgContext.endTransparencyLayer()
            cgContext.restoreGState()
        } else {
            // Solid color branch (unchanged).
            let attrs: [NSAttributedString.Key: Any] = [
                .font: ctFont,
                .foregroundColor: currentState.fillColor,
            ]
            let attrString = NSAttributedString(string: text, attributes: attrs)
            let line = CTLineCreateWithAttributedString(attrString)

            var ascent: CGFloat = 0
            var descent: CGFloat = 0
            let textWidth = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, nil))

            let alignedX = applyTextAlign(x: CGFloat(x), width: textWidth)
            let baselineY = applyTextBaseline(y: CGFloat(y), ascent: ascent, descent: descent)
            let scaleX = maxWidthScale(textWidth: textWidth, maxWidth: maxWidth)

            cgContext.saveGState()
            applyShadow()
            cgContext.setAlpha(currentState.globalAlpha)
            cgContext.textMatrix = .identity
            cgContext.translateBy(x: alignedX, y: baselineY)
            if scaleX < 1.0 { cgContext.scaleBy(x: scaleX, y: 1.0) }
            cgContext.scaleBy(x: 1, y: -1)
            CTLineDraw(line, cgContext)
            cgContext.restoreGState()
        }
    }

    /// Strokes text outlines at the given position using the current stroke style and font.
    ///
    /// - Parameters:
    ///   - text: The string to draw.
    ///   - x: The x coordinate of the text anchor point.
    ///   - y: The y coordinate of the text anchor point.
    ///   - maxWidth: If provided and the text is wider than this value, a horizontal
    ///     scale transform is applied to squish it to fit — matching Canvas 2D spec behaviour.
    func strokeText(text: String, x: Double, y: Double, maxWidth: Double? = nil) {
        let ctFont = CanvasFontParser.parse(currentState.fontString)
        let strokeWidth = max(currentState.lineWidth, 1.0)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: ctFont,
            .strokeColor: currentState.strokeColor,
            .strokeWidth: strokeWidth,
        ]
        let attrString = NSAttributedString(string: text, attributes: attrs)
        let line = CTLineCreateWithAttributedString(attrString)

        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        let textWidth = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, nil))

        let alignedX = applyTextAlign(x: CGFloat(x), width: textWidth)
        let baselineY = applyTextBaseline(y: CGFloat(y), ascent: ascent, descent: descent)
        let scaleX = maxWidthScale(textWidth: textWidth, maxWidth: maxWidth)

        cgContext.saveGState()
        applyShadow()
        cgContext.setAlpha(currentState.globalAlpha)
        cgContext.textMatrix = .identity
        cgContext.translateBy(x: alignedX, y: baselineY)
        if scaleX < 1.0 { cgContext.scaleBy(x: scaleX, y: 1.0) }
        cgContext.scaleBy(x: 1, y: -1)
        CTLineDraw(line, cgContext)
        cgContext.restoreGState()
    }

    private func maxWidthScale(textWidth: CGFloat, maxWidth: Double?) -> CGFloat {
        guard let maxWidth, maxWidth > 0, textWidth > CGFloat(maxWidth) else { return 1.0 }
        return CGFloat(maxWidth) / textWidth
    }

    /// Measures text width using the current font.
    func measureText(_ text: String) -> [String: Double] {
        let ctFont = CanvasFontParser.parse(currentState.fontString)
        let attrs: [NSAttributedString.Key: Any] = [.font: ctFont]
        let attrString = NSAttributedString(string: text, attributes: attrs)
        let line = CTLineCreateWithAttributedString(attrString)

        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        let width = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, nil))

        return ["width": Double(width)]
    }

    // MARK: - Text Positioning Helpers

    internal func applyTextAlign(x: CGFloat, width: CGFloat) -> CGFloat {
        switch currentState.textAlign {
        case "center": x - width / 2
        case "right", "end": x - width
        default: x
        }
    }

    internal func applyTextBaseline(y: CGFloat, ascent: CGFloat, descent: CGFloat) -> CGFloat {
        switch currentState.textBaseline {
        case "top", "hanging": y + ascent
        case "middle": y + (ascent - descent) / 2
        case "bottom", "ideographic": y - descent
        default: y
        }
    }

    // MARK: - Glyph Path Helper

    /// Builds a `CGPath` from all glyphs in a `CTLine`, with each glyph positioned
    /// at its typographic origin.
    private func glyphPath(from line: CTLine) -> CGPath? {
        let path = CGMutablePath()
        let runs = CTLineGetGlyphRuns(line) as! [CTRun]

        for run in runs {
            let count = CTRunGetGlyphCount(run)
            let font = (CTRunGetAttributes(run) as NSDictionary)[kCTFontAttributeName] as! CTFont

            var glyphs = [CGGlyph](repeating: 0, count: count)
            var positions = [CGPoint](repeating: .zero, count: count)
            CTRunGetGlyphs(run, CFRange(location: 0, length: count), &glyphs)
            CTRunGetPositions(run, CFRange(location: 0, length: count), &positions)

            for i in 0 ..< count {
                guard let glyphPath = CTFontCreatePathForGlyph(font, glyphs[i], nil) else { continue }
                let translation = CGAffineTransform(translationX: positions[i].x, y: positions[i].y)
                path.addPath(glyphPath, transform: translation)
            }
        }

        return path.isEmpty ? nil : path
    }
}
