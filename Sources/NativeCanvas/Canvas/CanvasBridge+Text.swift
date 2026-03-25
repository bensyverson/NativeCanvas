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
    /// - Parameters:
    ///   - text: The string to draw.
    ///   - x: The x coordinate of the text anchor point.
    ///   - y: The y coordinate of the text anchor point.
    ///   - maxWidth: If provided and the text is wider than this value, a horizontal
    ///     scale transform is applied to squish it to fit — matching Canvas 2D spec behaviour.
    func fillText(text: String, x: Double, y: Double, maxWidth: Double? = nil) {
        let ctFont = CanvasFontParser.parse(currentState.fontString)
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
}
