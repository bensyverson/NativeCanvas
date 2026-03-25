//
//  CanvasBridge+Image.swift
//  NativeCanvas
//

import CoreGraphics

public extension CanvasBridge {
    /// Draws an image at the specified position at its natural size.
    func drawImage(image: CGImage, dx: Double, dy: Double) {
        drawImage(image: image, dx: dx, dy: dy, dw: Double(image.width), dh: Double(image.height))
    }

    /// Draws an image scaled to the specified destination rectangle.
    func drawImage(image: CGImage, dx: Double, dy: Double, dw: Double, dh: Double) {
        cgContext.saveGState()
        applyShadow()
        cgContext.setAlpha(currentState.globalAlpha)
        cgContext.translateBy(x: CGFloat(dx), y: CGFloat(dy) + CGFloat(dh))
        cgContext.scaleBy(x: 1, y: -1)
        cgContext.draw(image, in: CGRect(x: 0, y: 0, width: dw, height: dh))
        cgContext.restoreGState()
    }

    /// Draws a cropped region of an image into a destination rectangle.
    func drawImage(image: CGImage, sx: Double, sy: Double, sw: Double, sh: Double, dx: Double, dy: Double, dw: Double, dh: Double) {
        let sourceRect = CGRect(x: sx, y: sy, width: sw, height: sh)
        guard let croppedImage = image.cropping(to: sourceRect) else { return }
        drawImage(image: croppedImage, dx: dx, dy: dy, dw: dw, dh: dh)
    }

    /// Draws a registered image by key. Dispatches to the correct overload based on argument count.
    func drawImageByKey(_ key: String, args: [Double]) {
        guard let image = registeredImage(forKey: key) else { return }

        switch args.count {
        case 2:
            drawImage(image: image, dx: args[0], dy: args[1])
        case 4:
            drawImage(image: image, dx: args[0], dy: args[1], dw: args[2], dh: args[3])
        case 8:
            drawImage(image: image, sx: args[0], sy: args[1], sw: args[2], sh: args[3],
                      dx: args[4], dy: args[5], dw: args[6], dh: args[7])
        default:
            break
        }
    }
}
