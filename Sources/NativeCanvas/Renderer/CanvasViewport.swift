//
//  CanvasViewport.swift
//  NativeCanvas
//

import Foundation

/// Edge insets for defining safe areas within a canvas viewport.
public struct CanvasEdgeInsets: Friendly {
    /// The inset from the top edge in pixels.
    public let top: Double
    /// The inset from the leading (left) edge in pixels.
    public let leading: Double
    /// The inset from the bottom edge in pixels.
    public let bottom: Double
    /// The inset from the trailing (right) edge in pixels.
    public let trailing: Double

    /// Zero insets — no safe area.
    public static let zero = CanvasEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)

    /// Creates edge insets with explicit values for each side.
    public init(top: Double, leading: Double, bottom: Double, trailing: Double) {
        self.top = top
        self.leading = leading
        self.bottom = bottom
        self.trailing = trailing
    }
}

/// Describes the pixel dimensions and safe area of the rendering canvas.
public struct CanvasViewport: Friendly {
    /// Canvas width in pixels.
    public let width: Int
    /// Canvas height in pixels.
    public let height: Int
    /// User-defined safe area insets. Defaults to `.zero`.
    public let safeArea: CanvasEdgeInsets

    /// Creates a viewport with the specified dimensions and optional safe area.
    public init(width: Int, height: Int, safeArea: CanvasEdgeInsets = .zero) {
        self.width = width
        self.height = height
        self.safeArea = safeArea
    }
}
