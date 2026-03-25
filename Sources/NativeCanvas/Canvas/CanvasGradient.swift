//
//  CanvasGradient.swift
//  NativeCanvas
//

import CoreGraphics

/// A Canvas 2D gradient definition, holding gradient type, geometry, and color stops.
///
/// Instances are created via ``CanvasBridge/createLinearGradient(x0:y0:x1:y1:)`` or
/// ``CanvasBridge/createRadialGradient(x0:y0:r0:x1:y1:r1:)`` and accumulate color stops
/// via ``addColorStop(offset:color:)``. When assigned to `fillStyle` or `strokeStyle`,
/// the bridge clips to the current path and draws the gradient.
public final nonisolated class CanvasGradient {
    /// The type of gradient.
    public enum GradientType {
        /// A gradient that transitions linearly between two points.
        case linear
        /// A gradient that transitions radially between two circles.
        case radial
    }

    /// The gradient type.
    public let type: GradientType

    /// The start point (linear) or start center (radial).
    public let startPoint: CGPoint

    /// The end point (linear) or end center (radial).
    public let endPoint: CGPoint

    /// The start radius (radial only).
    public let startRadius: CGFloat

    /// The end radius (radial only).
    public let endRadius: CGFloat

    /// The accumulated color stops, sorted by offset.
    public private(set) var stops: [(offset: CGFloat, color: CGColor)] = []

    // MARK: - Factory Methods

    /// Creates a linear gradient.
    public static func linear(from start: CGPoint, to end: CGPoint) -> CanvasGradient {
        CanvasGradient(type: .linear, startPoint: start, endPoint: end, startRadius: 0, endRadius: 0)
    }

    /// Creates a radial gradient.
    public static func radial(startCenter: CGPoint, startRadius: CGFloat, endCenter: CGPoint, endRadius: CGFloat) -> CanvasGradient {
        CanvasGradient(type: .radial, startPoint: startCenter, endPoint: endCenter, startRadius: startRadius, endRadius: endRadius)
    }

    private init(type: GradientType, startPoint: CGPoint, endPoint: CGPoint, startRadius: CGFloat, endRadius: CGFloat) {
        self.type = type
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.startRadius = startRadius
        self.endRadius = endRadius
    }

    // MARK: - Color Stops

    /// Adds a color stop to the gradient.
    ///
    /// - Parameters:
    ///   - offset: Position along the gradient (0.0 to 1.0)
    ///   - color: The color at this stop
    public func addColorStop(offset: CGFloat, color: CGColor) {
        let clampedOffset = max(0, min(1, offset))
        stops.append((offset: clampedOffset, color: color))
        stops.sort { $0.offset < $1.offset }
    }

    // MARK: - CG Gradient

    /// Builds a `CGGradient` from the accumulated color stops.
    ///
    /// - Parameter colorSpace: The color space for the gradient
    /// - Returns: A `CGGradient`, or `nil` if there are fewer than 2 stops
    public func makeCGGradient(in colorSpace: CGColorSpace) -> CGGradient? {
        guard stops.count >= 2 else { return nil }

        let colors = stops.map(\.color) as CFArray
        var locations = stops.map(\.offset)

        return CGGradient(
            colorsSpace: colorSpace,
            colors: colors,
            locations: &locations,
        )
    }
}
