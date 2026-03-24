//
//  CanvasState.swift
//  NativeCanvas
//

import CoreGraphics

/// A snapshot of the Canvas 2D graphics state, used for `save()`/`restore()`.
///
/// Matches the Canvas 2D specification defaults:
/// - Black fill and stroke
/// - 1.0 line width, butt cap, miter join
/// - 1.0 global alpha, source-over compositing
/// - Identity transform
public struct CanvasState: Equatable, Hashable, Sendable {
    /// The current fill color.
    public var fillColor: CGColor

    /// The current stroke color.
    public var strokeColor: CGColor

    /// The current line width in pixels.
    public var lineWidth: CGFloat

    /// The line cap style.
    public var lineCap: CGLineCap

    /// The line join style.
    public var lineJoin: CGLineJoin

    /// The global alpha (opacity) applied to all drawing operations.
    public var globalAlpha: CGFloat

    /// The blend mode for compositing.
    public var globalCompositeOperation: CGBlendMode

    /// The current transformation matrix (relative to the base transform).
    public var currentTransform: CGAffineTransform

    // MARK: - Text Properties

    /// The current font as a Canvas font string (e.g. `"10px sans-serif"`).
    public var fontString: String

    /// The current text alignment (`"start"`, `"end"`, `"left"`, `"right"`, `"center"`).
    public var textAlign: String

    /// The current text baseline (`"alphabetic"`, `"top"`, `"hanging"`, `"middle"`, `"bottom"`, `"ideographic"`).
    public var textBaseline: String

    // MARK: - Shadow Properties

    /// The shadow color.
    public var shadowColor: CGColor

    /// The shadow blur radius.
    public var shadowBlur: CGFloat

    /// The shadow horizontal offset.
    public var shadowOffsetX: CGFloat

    /// The shadow vertical offset.
    public var shadowOffsetY: CGFloat

    /// Creates a `CanvasState` with Canvas 2D specification defaults.
    ///
    /// - Parameter colorSpace: The color space used to create default fill/stroke colors
    public init(colorSpace: CGColorSpace) {
        let black = CGColor(colorSpace: colorSpace, components: [0, 0, 0, 1])!
        let transparent = CGColor(colorSpace: colorSpace, components: [0, 0, 0, 0])!
        fillColor = black
        strokeColor = black
        lineWidth = 1.0
        lineCap = .butt
        lineJoin = .miter
        globalAlpha = 1.0
        globalCompositeOperation = .normal
        currentTransform = .identity
        fontString = "10px sans-serif"
        textAlign = "start"
        textBaseline = "alphabetic"
        shadowColor = transparent
        shadowBlur = 0
        shadowOffsetX = 0
        shadowOffsetY = 0
    }
}
