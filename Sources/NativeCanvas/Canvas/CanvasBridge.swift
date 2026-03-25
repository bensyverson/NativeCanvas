//
//  CanvasBridge.swift
//  NativeCanvas
//

import CoreGraphics
import JavaScriptCore

/// Bridges the Canvas 2D drawing API to a Core Graphics context.
///
/// `CanvasBridge` wraps a `CGContext` and exposes Canvas 2D methods
/// (rects, paths, transforms, state management) that JavaScript templates call
/// through the JSCore integration layer in ``CanvasBridge+JSCore``.
///
/// The context uses a top-left origin coordinate system (Y increases downward),
/// matching the Canvas 2D convention. The ``RenderingProfile`` controls the
/// pixel format: `.display` uses device RGB 8-bit for zero-cost compositing,
/// `.hdr` uses extendedLinearSRGB float32 for HDR export.
///
/// ## Usage
///
/// ```swift
/// let bridge = CanvasBridge(width: 1920, height: 1080)
/// bridge.setFillStyle("red")
/// bridge.fillRect(x: 0, y: 0, width: 100, height: 50)
/// let image = bridge.makeImage()
/// ```
public final nonisolated class CanvasBridge {
    /// Selects the pixel format and color space for the backing `CGContext`.
    public enum RenderingProfile: Friendly {
        /// Device RGB, 8-bit integer. For preview and SDR export.
        case display
        /// Extended linear sRGB, 32-bit float. For HDR export to >8-bit codecs.
        case hdr
    }

    // MARK: - Properties

    /// The underlying Core Graphics context.
    public let cgContext: CGContext

    /// The rendering profile used to create this bridge.
    public let profile: RenderingProfile

    /// The color space used for color parsing and context creation.
    public let colorSpace: CGColorSpace

    /// The canvas width in pixels.
    public let width: Int

    /// The canvas height in pixels.
    public let height: Int

    private let baseTransform: CGAffineTransform
    private var stateStack: [CanvasState] = []

    /// The current graphics state.
    public var currentState: CanvasState

    private var currentPath = CGMutablePath()

    /// The current fill style as a CSS string.
    public private(set) var fillStyleString: String = "#000000"

    /// The current stroke style as a CSS string.
    public private(set) var strokeStyleString: String = "#000000"

    /// The active fill gradient, if any.
    public var fillGradient: CanvasGradient?

    /// The active stroke gradient, if any.
    public var strokeGradient: CanvasGradient?

    private var images: [String: CGImage] = [:]

    /// Registry of gradients created via `createLinearGradient`/`createRadialGradient`.
    public var gradients: [String: CanvasGradient] = [:]

    /// Weak reference to the JSContext, stored during `installInto`.
    public weak var jsContext: JSContext?

    // MARK: - Initialization

    /// Creates a new canvas bridge with a CGContext configured for the given profile.
    public init(width: Int, height: Int, profile: RenderingProfile = .display) {
        self.width = width
        self.height = height
        self.profile = profile

        let resolvedColorSpace: CGColorSpace
        let bitsPerComponent: Int
        let bytesPerRow: Int
        let bitmapInfo: CGBitmapInfo

        switch profile {
        case .display:
            resolvedColorSpace = CGColorSpaceCreateDeviceRGB()
            bitsPerComponent = 8
            bytesPerRow = width * 4
            bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        case .hdr:
            resolvedColorSpace = CGColorSpace(name: CGColorSpace.extendedLinearSRGB)!
            bitsPerComponent = 32
            bytesPerRow = width * 16
            bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.floatComponents.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        }

        colorSpace = resolvedColorSpace

        guard let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: resolvedColorSpace,
            bitmapInfo: bitmapInfo.rawValue,
        ) else {
            fatalError("Failed to create CGContext (\(width)×\(height), profile: \(profile))")
        }

        cgContext = ctx
        currentState = CanvasState(colorSpace: resolvedColorSpace)

        cgContext.translateBy(x: 0, y: CGFloat(height))
        cgContext.scaleBy(x: 1, y: -1)
        baseTransform = cgContext.ctm

        applyState()
    }

    /// Creates a canvas bridge wrapping an existing CGContext.
    ///
    /// The context will have a Y-flip transform applied so that drawing
    /// uses a top-left origin. The caller owns the context's lifecycle.
    ///
    /// - Parameters:
    ///   - context: An existing CGContext to draw into
    ///   - width: Canvas width in pixels
    ///   - height: Canvas height in pixels
    ///   - profile: Rendering profile (used to select color space for state parsing)
    public init(context: CGContext, width: Int, height: Int, profile: RenderingProfile = .display) {
        self.width = width
        self.height = height
        self.profile = profile
        cgContext = context

        let resolvedColorSpace: CGColorSpace = switch profile {
        case .display:
            CGColorSpaceCreateDeviceRGB()
        case .hdr:
            CGColorSpace(name: CGColorSpace.extendedLinearSRGB)!
        }
        colorSpace = resolvedColorSpace
        currentState = CanvasState(colorSpace: resolvedColorSpace)

        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        baseTransform = context.ctm

        applyState()
    }

    // MARK: - Image Output

    /// Extracts the current canvas content as a `CGImage`.
    public func makeImage() -> CGImage? {
        cgContext.makeImage()
    }

    // MARK: - State Management

    /// Saves the current graphics state onto the stack.
    public func save() {
        currentState.currentTransform = cgContext.ctm.concatenating(baseTransform.inverted())
        stateStack.append(currentState)
        cgContext.saveGState()
    }

    /// Restores the most recently saved graphics state from the stack.
    public func restore() {
        guard let saved = stateStack.popLast() else { return }
        currentState = saved
        cgContext.restoreGState()
    }

    // MARK: - Style Properties

    /// Sets the fill style from a CSS color string, clearing any active gradient.
    public func setFillStyle(_ value: String) {
        fillStyleString = value
        fillGradient = nil
        if let color = CSSColorParser.parse(value, in: colorSpace) {
            currentState.fillColor = color
        }
    }

    /// Sets the stroke style from a CSS color string, clearing any active gradient.
    public func setStrokeStyle(_ value: String) {
        strokeStyleString = value
        strokeGradient = nil
        if let color = CSSColorParser.parse(value, in: colorSpace) {
            currentState.strokeColor = color
        }
    }

    /// The line width for stroke operations.
    public var lineWidth: CGFloat {
        get { currentState.lineWidth }
        set {
            currentState.lineWidth = newValue
            cgContext.setLineWidth(newValue)
        }
    }

    /// The line cap style as a CSS string.
    public var lineCapString: String {
        get {
            switch currentState.lineCap {
            case .butt: "butt"
            case .round: "round"
            case .square: "square"
            @unknown default: "butt"
            }
        }
        set {
            let cap: CGLineCap = switch newValue {
            case "round": .round
            case "square": .square
            default: .butt
            }
            currentState.lineCap = cap
            cgContext.setLineCap(cap)
        }
    }

    /// The line join style as a CSS string.
    public var lineJoinString: String {
        get {
            switch currentState.lineJoin {
            case .miter: "miter"
            case .round: "round"
            case .bevel: "bevel"
            @unknown default: "miter"
            }
        }
        set {
            let join: CGLineJoin = switch newValue {
            case "round": .round
            case "bevel": .bevel
            default: .miter
            }
            currentState.lineJoin = join
            cgContext.setLineJoin(join)
        }
    }

    /// The global alpha (0.0–1.0) applied to all drawing operations.
    public var globalAlpha: CGFloat {
        get { currentState.globalAlpha }
        set {
            currentState.globalAlpha = max(0, min(1, newValue))
            cgContext.setAlpha(currentState.globalAlpha)
        }
    }

    /// The global composite operation as a CSS string.
    public var globalCompositeOperationString: String {
        get { Self.blendModeToString[currentState.globalCompositeOperation] ?? "source-over" }
        set {
            if let mode = Self.stringToBlendMode[newValue] {
                currentState.globalCompositeOperation = mode
                cgContext.setBlendMode(mode)
            }
        }
    }

    // MARK: - Image Registry

    /// Registers an image for use with `drawImage`.
    public func registerImage(_ image: CGImage, forKey key: String) {
        images[key] = image
    }

    /// Retrieves a registered image by key.
    public func registeredImage(forKey key: String) -> CGImage? {
        images[key]
    }

    // MARK: - Rectangle Operations

    /// Fills a rectangle with the current fill style.
    public func fillRect(x: Double, y: Double, width w: Double, height h: Double) {
        let rect = CGRect(x: x, y: y, width: w, height: h)
        if let gradient = fillGradient {
            cgContext.saveGState()
            applyShadow()
            cgContext.setAlpha(currentState.globalAlpha)
            cgContext.addRect(rect)
            cgContext.clip()
            drawGradient(gradient)
            cgContext.restoreGState()
        } else {
            cgContext.saveGState()
            applyShadow()
            cgContext.setFillColor(currentState.fillColor)
            cgContext.setAlpha(currentState.globalAlpha)
            cgContext.fill(rect)
            cgContext.restoreGState()
        }
    }

    /// Strokes the outline of a rectangle with the current stroke style.
    public func strokeRect(x: Double, y: Double, width w: Double, height h: Double) {
        let rect = CGRect(x: x, y: y, width: w, height: h)
        cgContext.saveGState()
        applyShadow()
        cgContext.setStrokeColor(currentState.strokeColor)
        cgContext.setLineWidth(currentState.lineWidth)
        cgContext.setAlpha(currentState.globalAlpha)
        cgContext.stroke(rect)
        cgContext.restoreGState()
    }

    /// Clears the specified rectangle, making it fully transparent.
    public func clearRect(x: Double, y: Double, width w: Double, height h: Double) {
        cgContext.clear(CGRect(x: x, y: y, width: w, height: h))
    }

    // MARK: - Path Operations

    /// Begins a new path, discarding any existing path.
    public func beginPath() {
        currentPath = CGMutablePath()
    }

    /// Moves the current point to the specified coordinates.
    public func moveTo(x: Double, y: Double) {
        currentPath.move(to: CGPoint(x: x, y: y))
    }

    /// Draws a line from the current point to the specified coordinates.
    public func lineTo(x: Double, y: Double) {
        currentPath.addLine(to: CGPoint(x: x, y: y))
    }

    /// Closes the current subpath by drawing a line to the starting point.
    public func closePath() {
        currentPath.closeSubpath()
    }

    /// Adds a cubic Bezier curve from the current point.
    public func bezierCurveTo(cp1x: Double, cp1y: Double, cp2x: Double, cp2y: Double, x: Double, y: Double) {
        currentPath.addCurve(to: CGPoint(x: x, y: y), control1: CGPoint(x: cp1x, y: cp1y), control2: CGPoint(x: cp2x, y: cp2y))
    }

    /// Adds a quadratic Bezier curve from the current point.
    public func quadraticCurveTo(cpx: Double, cpy: Double, x: Double, y: Double) {
        currentPath.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: cpx, y: cpy))
    }

    /// Adds an arc to the current path.
    public func arc(x: Double, y: Double, radius: Double, startAngle: Double, endAngle: Double, counterclockwise: Bool = false) {
        currentPath.addArc(center: CGPoint(x: x, y: y), radius: CGFloat(radius), startAngle: CGFloat(startAngle), endAngle: CGFloat(endAngle), clockwise: counterclockwise)
    }

    /// Adds an arc defined by tangent lines to the current path.
    public func arcTo(x1: Double, y1: Double, x2: Double, y2: Double, radius: Double) {
        currentPath.addArc(tangent1End: CGPoint(x: x1, y: y1), tangent2End: CGPoint(x: x2, y: y2), radius: CGFloat(radius))
    }

    /// Adds a rectangle to the current path.
    public func rect(x: Double, y: Double, width w: Double, height h: Double) {
        currentPath.addRect(CGRect(x: x, y: y, width: w, height: h))
    }

    /// Fills the current path with the current fill style.
    public func fill() {
        if let gradient = fillGradient {
            cgContext.saveGState()
            applyShadow()
            cgContext.setAlpha(currentState.globalAlpha)
            cgContext.addPath(currentPath)
            cgContext.clip()
            drawGradient(gradient)
            cgContext.restoreGState()
        } else {
            cgContext.saveGState()
            applyShadow()
            cgContext.setFillColor(currentState.fillColor)
            cgContext.setAlpha(currentState.globalAlpha)
            cgContext.addPath(currentPath)
            cgContext.fillPath()
            cgContext.restoreGState()
        }
    }

    /// Strokes the current path with the current stroke style.
    public func stroke() {
        cgContext.saveGState()
        applyShadow()
        cgContext.setStrokeColor(currentState.strokeColor)
        cgContext.setLineWidth(currentState.lineWidth)
        cgContext.setLineCap(currentState.lineCap)
        cgContext.setLineJoin(currentState.lineJoin)
        cgContext.setAlpha(currentState.globalAlpha)
        cgContext.addPath(currentPath)
        cgContext.strokePath()
        cgContext.restoreGState()
    }

    /// Uses the current path as a clipping region for subsequent drawing.
    public func clip() {
        cgContext.addPath(currentPath)
        cgContext.clip()
    }

    // MARK: - Transform Operations

    /// Translates the coordinate system.
    public func translate(x: Double, y: Double) {
        cgContext.translateBy(x: CGFloat(x), y: CGFloat(y))
    }

    /// Rotates the coordinate system by the given angle in radians.
    public func rotate(angle: Double) {
        cgContext.rotate(by: CGFloat(angle))
    }

    /// Scales the coordinate system.
    public func scale(x: Double, y: Double) {
        cgContext.scaleBy(x: CGFloat(x), y: CGFloat(y))
    }

    /// Sets the transform matrix (relative to the base flipped coordinate system).
    public func setTransform(a: Double, b: Double, c: Double, d: Double, e: Double, f: Double) {
        resetToBaseTransform()
        cgContext.concatenate(CGAffineTransform(a: a, b: b, c: c, d: d, tx: e, ty: f))
    }

    /// Resets the transform to the identity (relative to the base flipped coordinate system).
    public func resetTransform() {
        resetToBaseTransform()
    }

    private func resetToBaseTransform() {
        let currentCTM = cgContext.ctm
        cgContext.concatenate(currentCTM.inverted())
        cgContext.concatenate(baseTransform)
    }

    // MARK: - Gradient Creation

    /// Creates a linear gradient definition.
    public func createLinearGradient(x0: Double, y0: Double, x1: Double, y1: Double) -> CanvasGradient {
        CanvasGradient.linear(from: CGPoint(x: x0, y: y0), to: CGPoint(x: x1, y: y1))
    }

    /// Creates a radial gradient definition.
    public func createRadialGradient(x0: Double, y0: Double, r0: Double, x1: Double, y1: Double, r1: Double) -> CanvasGradient {
        CanvasGradient.radial(startCenter: CGPoint(x: x0, y: y0), startRadius: CGFloat(r0), endCenter: CGPoint(x: x1, y: y1), endRadius: CGFloat(r1))
    }

    // MARK: - Shadow Properties

    /// The shadow color as a CSS string.
    public var shadowColorString: String = "rgba(0, 0, 0, 0)" {
        didSet {
            if let color = CSSColorParser.parse(shadowColorString, in: colorSpace) {
                currentState.shadowColor = color
            }
        }
    }

    /// The shadow blur radius.
    public var shadowBlur: CGFloat {
        get { currentState.shadowBlur }
        set { currentState.shadowBlur = max(0, newValue) }
    }

    /// The shadow horizontal offset.
    public var shadowOffsetX: CGFloat {
        get { currentState.shadowOffsetX }
        set { currentState.shadowOffsetX = newValue }
    }

    /// The shadow vertical offset.
    public var shadowOffsetY: CGFloat {
        get { currentState.shadowOffsetY }
        set { currentState.shadowOffsetY = newValue }
    }

    // MARK: - Private Helpers

    /// Applies the current shadow to the context if shadow is configured.
    public func applyShadow() {
        let state = currentState
        guard state.shadowBlur > 0 || state.shadowOffsetX != 0 || state.shadowOffsetY != 0 else { return }

        let components = state.shadowColor.components ?? []
        let alpha = components.count >= 4 ? components[3] : 0
        guard alpha > 0 else { return }

        let offset = CGSize(width: state.shadowOffsetX, height: -state.shadowOffsetY)
        cgContext.setShadow(offset: offset, blur: state.shadowBlur, color: state.shadowColor)
    }

    private func drawGradient(_ gradient: CanvasGradient) {
        guard let cgGradient = gradient.makeCGGradient(in: colorSpace) else { return }
        let options: CGGradientDrawingOptions = [.drawsBeforeStartLocation, .drawsAfterEndLocation]

        // PDF gradient shadings (Type 2/3) encode only device color values — the
        // alpha channel in color stops is silently dropped. When any stop has alpha < 1
        // and we're not in a bitmap context, render the gradient into an offscreen
        // bitmap and draw the result as an image so transparency composites correctly.
        let hasTransparentStop = gradient.stops.contains {
            ($0.color.components?.last ?? 1.0) < 1.0
        }
        if hasTransparentStop, cgContext.makeImage() == nil {
            drawGradientOffscreen(gradient, cgGradient: cgGradient, options: options)
            return
        }

        switch gradient.type {
        case .linear:
            cgContext.drawLinearGradient(cgGradient, start: gradient.startPoint, end: gradient.endPoint, options: options)
        case .radial:
            cgContext.drawRadialGradient(cgGradient, startCenter: gradient.startPoint, startRadius: gradient.startRadius, endCenter: gradient.endPoint, endRadius: gradient.endRadius, options: options)
        }
    }

    /// Renders a gradient with transparent stops into an offscreen DeviceRGB bitmap,
    /// then composites the result into the current context as an image.
    /// This preserves the current clip (which is in device space) while correctly
    /// rendering alpha values that PDF shading functions cannot express.
    private func drawGradientOffscreen(_ gradient: CanvasGradient, cgGradient: CGGradient, options: CGGradientDrawingOptions) {
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let offCtx = CGContext(
            data: nil, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: bitmapInfo.rawValue,
        ) else { return }

        // Apply the real context's full CTM so gradient coordinates map correctly.
        offCtx.concatenate(cgContext.ctm)

        switch gradient.type {
        case .linear:
            offCtx.drawLinearGradient(cgGradient, start: gradient.startPoint, end: gradient.endPoint, options: options)
        case .radial:
            offCtx.drawRadialGradient(cgGradient, startCenter: gradient.startPoint, startRadius: gradient.startRadius, endCenter: gradient.endPoint, endRadius: gradient.endRadius, options: options)
        }

        guard let image = offCtx.makeImage() else { return }

        // Draw the image in device space. The clip set by fillRect/fill is stored
        // in device space, so it still masks correctly after resetting the CTM.
        cgContext.saveGState()
        cgContext.concatenate(cgContext.ctm.inverted())
        cgContext.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        cgContext.restoreGState()
    }

    private func applyState() {
        cgContext.setFillColor(currentState.fillColor)
        cgContext.setStrokeColor(currentState.strokeColor)
        cgContext.setLineWidth(currentState.lineWidth)
        cgContext.setLineCap(currentState.lineCap)
        cgContext.setLineJoin(currentState.lineJoin)
        cgContext.setAlpha(currentState.globalAlpha)
        cgContext.setBlendMode(currentState.globalCompositeOperation)
    }

    // MARK: - Blend Mode Mappings

    static let stringToBlendMode: [String: CGBlendMode] = [
        "source-over": .normal,
        "source-in": .sourceIn,
        "source-out": .sourceOut,
        "source-atop": .sourceAtop,
        "destination-over": .destinationOver,
        "destination-in": .destinationIn,
        "destination-out": .destinationOut,
        "destination-atop": .destinationAtop,
        "lighter": .plusLighter,
        "copy": .copy,
        "xor": .xor,
        "multiply": .multiply,
        "screen": .screen,
        "overlay": .overlay,
        "darken": .darken,
        "lighten": .lighten,
        "color-dodge": .colorDodge,
        "color-burn": .colorBurn,
        "hard-light": .hardLight,
        "soft-light": .softLight,
        "difference": .difference,
        "exclusion": .exclusion,
        "hue": .hue,
        "saturation": .saturation,
        "color": .color,
        "luminosity": .luminosity,
    ]

    static let blendModeToString: [CGBlendMode: String] = {
        var result: [CGBlendMode: String] = [:]
        for (key, value) in stringToBlendMode {
            result[value] = key
        }
        return result
    }()
}
