# ``NativeCanvas``

Render JavaScript Canvas 2D scripts into native CoreGraphics contexts on Apple platforms.

@Metadata {
    @DisplayName("NativeCanvas")
}

## Overview

NativeCanvas is a Swift library that evaluates JavaScript templates written against the familiar
[Canvas 2D API](https://developer.mozilla.org/en-US/docs/Web/API/Canvas_API) and produces
`CGImage` output backed by CoreGraphics. Templates can declare a typed parameter schema so that
host applications can drive dynamic graphics—PDFs, animations and more—with
strongly-typed Swift values while keeping the drawing logic in portable, hot-reloadable JavaScript.

The library is thread-safe: each render call creates an isolated ``CanvasRuntime`` and
``CanvasBridge``, so multiple templates can be rendered concurrently without synchronisation.

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:Architecture>
- <doc:WritingTemplates>

### Core Drawing

- ``CanvasBridge``
- ``CanvasGradient``
- ``CanvasState``
- ``CanvasBridge/RenderingProfile``

### Rendering

- ``CanvasRenderer``
- ``CanvasViewport``
- ``CanvasEdgeInsets``
- ``NoScene``

### Templates & Schema

- ``CanvasRuntime``
- ``CanvasTemplate``
- ``CanvasSchema``
- ``CanvasParamDef``
- ``CanvasParamValue``
- ``CanvasParamType``
- ``CanvasStandardLibrary``

### Errors

- ``CanvasError``
