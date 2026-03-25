//
//  CGColor+CSSString.swift
//  NativeCanvas
//

import CoreGraphics
import Foundation

public extension CGColor {
    /// Converts this color to a CSS `rgba()` string in sRGB space.
    ///
    /// Extracts RGBA components (converting to sRGB if needed) and formats as
    /// `rgba(r, g, b, a)` with r/g/b as 0-255 floats and alpha as 0-1 float.
    /// Using `rgba()` preserves float precision without clamping to 8-bit hex.
    nonisolated var cssRGBAString: String {
        let srgb = CGColorSpace(name: CGColorSpace.sRGB)!
        let converted = converted(to: srgb, intent: .defaultIntent, options: nil) ?? self
        guard let components = converted.components, components.count >= 3 else {
            return "rgba(0, 0, 0, 1.0)"
        }
        let r = components[0] * 255.0
        let g = components[1] * 255.0
        let b = components[2] * 255.0
        let a = components.count >= 4 ? components[3] : 1.0
        return String(format: "rgba(%.1f, %.1f, %.1f, %.2f)", r, g, b, a)
    }
}
