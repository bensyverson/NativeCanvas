# NativeCanvas

Render JavaScript Canvas 2D templates into native CoreGraphics images on Apple platforms.

NativeCanvas evaluates JavaScript templates written against the familiar Canvas 2D API and
produces `CGImage` output backed by CoreGraphics — no web view required. Templates declare
a typed parameter schema so host applications can drive dynamic graphics (titles, lower-thirds,
data visualisations) with strongly-typed Swift values, while keeping the drawing logic in
portable, hot-reloadable JavaScript.

## Requirements

- Swift 6+
- macOS 15+ / iOS 18+

## Installation

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/your-org/NativeCanvas", from: "1.0.0")
],
targets: [
    .target(name: "MyTarget", dependencies: ["NativeCanvas"])
]
```

## Quick Start

```swift
import NativeCanvas

let templateJS = """
nc.schema({
    name: "Hello World", description: "", version: "1.0.0",
    category: "Example", tags: [], params: {}
});
var layers = [{
    name: "bg",
    render: function(ctx, params, scene) {
        ctx.fillStyle = "navy";
        ctx.fillRect(0, 0, scene.viewport.width, scene.viewport.height);
        ctx.fillStyle = "white";
        ctx.font = nc.pt(64) + "px sans-serif";
        ctx.textAlign = "center";
        ctx.textBaseline = "middle";
        ctx.fillText("Hello!", scene.viewport.width / 2, scene.viewport.height / 2);
    }
}];
"""

// Render to a CGImage
let image: CGImage = try CanvasRenderer.render(
    source: templateJS,
    viewport: CanvasViewport(width: 1920, height: 1080)
)

// Display in SwiftUI
Image(image, scale: 1, label: Text("Canvas"))
    .resizable()
    .aspectRatio(contentMode: .fit)
```

## Documentation

Full documentation is available as a DocC catalog in `Sources/NativeCanvas/Documentation.docc/`.
Generate and browse it with:

```bash
swift package generate-documentation --target NativeCanvas
```

Key articles:

- **Getting Started** — installation, first render, SwiftUI display, scene parameters, animation
- **Architecture** — three-layer design (Bridge → Runtime → Renderer), concurrency model
- **Writing Templates** — template contract, schema declaration, parameter types, `nc` standard library
