# Getting Started

Render your first JavaScript Canvas template to a `CGImage` in minutes.

## Requirements

- Swift 6 or later
- macOS 15+ or iOS 18+
- Xcode 16+

## Installation

Add NativeCanvas to your package using Swift Package Manager:

```swift
// In Package.swift
dependencies: [
    .package(url: "https://github.com/your-org/NativeCanvas", from: "1.0.0")
],
targets: [
    .target(
        name: "MyTarget",
        dependencies: ["NativeCanvas"]
    )
]
```

## Rendering a Template

The simplest render call takes a JavaScript source string and a ``CanvasViewport``,
and returns a `CGImage`:

```swift
import NativeCanvas

let js = """
nc.schema({
    name: "Hello World",
    description: "A simple greeting graphic",
    version: "1.0.0",
    category: "Example",
    tags: [],
    params: {}
});

var layers = [{
    name: "background",
    render: function(ctx, params, scene) {
        ctx.fillStyle = "navy";
        ctx.fillRect(0, 0, scene.viewport.width, scene.viewport.height);
        ctx.fillStyle = "white";
        ctx.font = nc.pt(48) + "px sans-serif";
        ctx.textAlign = "center";
        ctx.textBaseline = "middle";
        ctx.fillText("Hello, World!", scene.viewport.width / 2, scene.viewport.height / 2);
    }
}];
"""

let viewport = CanvasViewport(width: 1920, height: 1080)
let image: CGImage = try CanvasRenderer.render(source: js, viewport: viewport)
```

## Displaying the Result in SwiftUI

Wrap the `CGImage` in a `SwiftUI.Image`:

```swift
import SwiftUI

struct CanvasPreview: View {
    let image: CGImage

    var body: some View {
        Image(image, scale: 1, label: Text("Canvas"))
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}
```

## Passing Parameters via a Scene Struct

Define a `Codable` struct and pass it as the `scene` argument. NativeCanvas encodes it to
JSON and makes the properties available as `scene.*` inside your JavaScript:

```swift
struct TitleScene: Encodable, Sendable {
    var title: String
    var subtitle: String
    var accentColor: String
}

let scene = TitleScene(title: "Breaking News", subtitle: "Live Coverage", accentColor: "#e53e3e")
let image: CGImage = try CanvasRenderer.render(
    source: templateJS,
    scene: scene,
    viewport: CanvasViewport(width: 1920, height: 1080)
)
```

Inside JavaScript, access your fields as `scene.title`, `scene.subtitle`, and `scene.accentColor`.
NativeCanvas also injects `scene.t` (normalised time 0–1), `scene.frame` (integer frame number),
and `scene.viewport` (width, height, orientation, aspectRatio, pointScale, safeArea).

## Animating Over Time

Pass a `time` value between 0 and 1 to animate your template:

```swift
for frame in 0..<60 {
    let t = Double(frame) / 59.0
    let image = try CanvasRenderer.render(
        source: templateJS,
        at: t,
        frame: frame,
        viewport: viewport
    )
    // encode image as a video frame…
}
```

## HDR Rendering

Use ``CanvasBridge/RenderingProfile/hdr`` to render into an extended-range float32 context:

```swift
let image = try CanvasRenderer.render(
    source: js,
    viewport: viewport,
    profile: .hdr
)
```
