# Architecture

How NativeCanvas maps JavaScript Canvas 2D calls to CoreGraphics.

## Overview

NativeCanvas is structured as three cooperating layers. Each layer has a single
well-defined responsibility, and ``CanvasRenderer`` acts as the thin orchestrator
that wires them together for a single render call.

```
┌──────────────────────────────────────────────────────┐
│                    CanvasRenderer                    │  ← Top-level API
│   render(source:at:frame:scene:viewport:profile:)    │
└─────────────────────┬──────────────┬─────────────────┘
                      │              │
          ┌───────────▼────┐  ┌──────▼──────────────┐
          │  CanvasRuntime │  │    CanvasBridge     │
          │  (JSContext)   │  │    (CGContext)      │
          └───────────┬────┘  └─────────────────────┘
                      │
              ┌───────▼────────┐
              │CanvasStandard  │
              │Library (nc)    │
              └────────────────┘
```

## Bridge Layer — `CanvasBridge`

``CanvasBridge`` wraps a `CGContext` and implements the Canvas 2D drawing API:
paths, rectangles, transforms, gradients, shadows, text, and image drawing.
It stores transient drawing state in a ``CanvasState`` struct that mirrors the
Canvas 2D specification's state stack, and uses ``CanvasGradient`` to represent
gradient definitions before they are rasterised.

The context uses a **top-left origin** coordinate system (Y increases downward)
matching the Canvas 2D convention. A permanent Y-flip transform is applied at
initialisation time so that all subsequent drawing is in this expected space.

The ``CanvasBridge/RenderingProfile`` enum selects the pixel format:

| Profile | Bit depth | Color space | Use case |
|---------|-----------|-------------|----------|
| `.display` | 8-bit integer | Device RGB | Preview, SDR export |
| `.hdr` | 32-bit float | Extended linear sRGB | HDR export |

JavaScript templates access the bridge through the JSCore integration layer in
`CanvasBridge+JSCore`, which wires every Canvas 2D property and method to a
corresponding Swift closure.

## Runtime Layer — `CanvasRuntime`

``CanvasRuntime`` manages a sandboxed `JSContext`:

- Removes dangerous globals (`eval`, `Function` constructor).
- Wires `console.log/warn/error` to a no-op Swift closure (avoiding crashes on
  `JSContext` threads).
- Optionally installs the `nc` standard library via ``CanvasStandardLibrary``.
- Evaluates template source (after source preprocessing) and extracts the `schema`
  and `layers` globals as a ``CanvasTemplate``.

Each ``CanvasRuntime`` is intended to load **exactly one template**. Create a new
runtime for a different template to avoid cross-template state pollution.

The `nc` standard library (`CanvasStandardLibrary`) injects resolution-independent
utilities, easing functions, interpolation helpers, color utilities, and
Core Text–backed typography functions (`measureText`, `wrapText`, `fitText`) into
the `nc` global object.

## Renderer Layer — `CanvasRenderer`

``CanvasRenderer`` is a `nonisolated enum` that provides purely static render
methods. Each call:

1. Creates a fresh ``CanvasRuntime`` and loads the template.
2. Encodes the Swift scene struct to JSON and parses it back into a `JSValue`,
   then injects `t`, `frame`, and `viewport` fields.
3. Creates a ``CanvasBridge`` (either owned or caller-provided).
4. Iterates over the template's `layers` array, calling each layer's `render`
   function with `(ctx, params, scene)`.
5. Returns the resulting `CGImage` or renders into the provided `CGContext`.

Because each call creates its own runtime and bridge, concurrent renders are safe
with no locking.

## Viewport & Safe Area

``CanvasViewport`` carries the pixel dimensions and optional ``CanvasEdgeInsets``
safe area. The safe area is exposed to JavaScript as `scene.viewport.safeArea`
with `top`, `leading`, `bottom`, and `trailing` values, letting templates inset
their content for device bezels or broadcast title-safe zones.

## Schema & Parameters

Templates optionally declare their user-editable parameters through a `var schema = {...}`
global. NativeCanvas parses this into a ``CanvasSchema`` which contains an ordered list of
``CanvasParamDef`` entries, each with a ``CanvasParamType`` and default
``CanvasParamValue``. Host applications can read the schema to render editor UIs
and pass overridden values back to the renderer.

## Swift 6 Concurrency

All public types are either value types (`struct`/`enum`) or `nonisolated final class`.
No global mutable state is shared between render calls. `CanvasRuntime` and
`CanvasBridge` are `nonisolated` because `JSContext` and `CGContext` are not
`Sendable`; callers are responsible for using each instance from a single isolation
domain. ``CanvasRenderer``'s static methods each create fresh instances, so they
are safe to call concurrently from any isolation context.
