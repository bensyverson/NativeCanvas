//
//  CanvasBridge+Text.swift
//  NativeCanvas
//

import CoreGraphics
import CoreText
import Foundation

public extension CanvasBridge {
    /// Fills text at the given position using the current fill style and font.
    func fillText(text: String, x: Double, y: Double) {
        let ctFont = CanvasFontParser.parse(currentState.fontString)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: ctFont,
            .foregroundColor: currentState.fillColor,
        ]
        let attrString = NSAttributedString(string: text, attributes: attrs)
        let line = CTLineCreateWithAttributedString(attrString)

        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        let width = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, nil))

        let alignedX = applyTextAlign(x: CGFloat(x), width: width)
        let baselineY = applyTextBaseline(y: CGFloat(y), ascent: ascent, descent: descent)

        cgContext.saveGState()
        applyShadow()
        cgContext.setAlpha(currentState.globalAlpha)
        cgContext.textMatrix = .identity
        cgContext.translateBy(x: alignedX, y: baselineY)
        cgContext.scaleBy(x: 1, y: -1)
        CTLineDraw(line, cgContext)
        cgContext.restoreGState()
    }

    /// Strokes text outlines at the given position using the current stroke style and font.
    func strokeText(text: String, x: Double, y: Double) {
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
        let width = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, nil))

        let alignedX = applyTextAlign(x: CGFloat(x), width: width)
        let baselineY = applyTextBaseline(y: CGFloat(y), ascent: ascent, descent: descent)

        cgContext.saveGState()
        applyShadow()
        cgContext.setAlpha(currentState.globalAlpha)
        cgContext.textMatrix = .identity
        cgContext.translateBy(x: alignedX, y: baselineY)
        cgContext.scaleBy(x: 1, y: -1)
        CTLineDraw(line, cgContext)
        cgContext.restoreGState()
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
