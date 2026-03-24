//
//  CanvasViewport.swift
//  NativeCanvas
//

import Foundation

/// Edge insets for defining safe areas within a canvas viewport.
public struct CanvasEdgeInsets: Friendly {
    public let top: Double
    public let leading: Double
    public let bottom: Double
    public let trailing: Double

    public static let zero = CanvasEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)

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

    public init(width: Int, height: Int, safeArea: CanvasEdgeInsets = .zero) {
        self.width = width
        self.height = height
        self.safeArea = safeArea
    }
}
