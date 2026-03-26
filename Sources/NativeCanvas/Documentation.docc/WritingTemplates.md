# Writing Templates

Author JavaScript templates that NativeCanvas can render.

## Template Contract

A NativeCanvas template is a plain JavaScript file (or string) that exports
globals after evaluation:

| Global | Type | Description |
|--------|------|-------------|
| `schema` | Object | Template metadata and parameter definitions (optional) |
| `layers` | Array | One or more layer objects, each with a `render` function |

A minimal template skeleton looks like this:

```javascript
var schema = {
    name: "My Template",
    description: "What this template does",
    version: "1.0.0",
    category: "Lower Thirds",
    tags: ["news", "broadcast"],
    params: {
        title: { type: "string", default: "Hello" },
        fontSize: { type: "float", default: 48, min: 12, max: 200, animatable: true }
    }
};

var layers = [
    {
        name: "background",
        render: function(ctx, params, scene) {
            // draw the background
        }
    },
    {
        name: "title_text",
        editableParam: "title",      // optional: binds this layer to a text param
        render: function(ctx, params, scene) {
            ctx.fillStyle = "white";
            ctx.font = nc.pt(params.fontSize) + "px sans-serif";
            ctx.fillText(params.title, nc.pt(40), nc.pt(40));
        }
    }
];
```

## Schema Declaration

Declare a `schema` variable at the top of your template. The schema is **optional**—if
omitted, the template name defaults to `"Untitled"` and parameters will be empty.

```javascript
var schema = {
    name: "My Template",
    params: {
        title: { type: "string", default: "Hello" }
    }
};
```

### Required fields

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Display name shown in the host UI |
| `params` | object | Parameter definitions (see below) |

### Optional fields

| Field | Type | Description |
|-------|------|-------------|
| `description` | string | Short description of the template |
| `version` | string | Semantic version, e.g. `"1.0.0"` (default: `"1.0.0"`) |
| `category` | string | Grouping category, e.g. `"Lower Thirds"` (default: `"Uncategorized"`) |
| `tags` | string[] | Searchable tags (default: `[]`) |
| `author` | `{ name, url? }` | Author credit |
| `paramGroups` | `{ [groupName]: string[] }` | Groups param keys into named sections for UI |
| `defaultDuration` | number | Suggested duration in seconds |

## Parameter Types

Each key in `params` is a parameter definition object. The `type` field maps
directly to a ``CanvasParamType`` case:

| JS type string | Swift enum case | Value shape |
|---------------|-----------------|-------------|
| `"string"` | `.string` | A single-line string |
| `"text"` | `.text` | A multiline text block |
| `"float"` | `.float` | A `Double` number |
| `"int"` | `.int` | An integer number |
| `"bool"` | `.bool` | `true` / `false` |
| `"color"` | `.color` | A CSS color string |
| `"enum"` | `.enumType` | One of the strings listed in `options` |
| `"font"` | `.font` | `{ family, weight, style? }` |
| `"point2d"` | `.point2d` | `{ x, y }` |
| `"gradient"` | `.gradient` | Array of `{ stop, color }` objects |
| `"image"` | `.image` | A registered image key string |

### Parameter definition fields

```javascript
params: {
    myParam: {
        type: "float",          // required
        default: 1.0,           // required
        min: 0,                 // optional, for float/int
        max: 10,                // optional, for float/int
        options: [],            // required for "enum" type
        animatable: true        // optional (default: false)
    }
}
```

## The `nc` Standard Library

The `nc` global is injected by ``CanvasStandardLibrary`` and provides:

### Resolution Independence

```javascript
nc.pt(value)
// Converts a resolution-independent point to pixels.
// The scale is derived from the viewport diagonal: diagonal / 2000.
// Use this for all font sizes and layout measurements.
ctx.font = nc.pt(48) + "px sans-serif";
```

### Easing Functions

All easing functions accept a normalised time `t` (0–1) and return a value (usually 0–1):

```javascript
nc.easeIn(t)          // Cubic ease-in
nc.easeOut(t)         // Cubic ease-out
nc.easeInOut(t)       // Cubic ease-in-out
nc.spring(t, tension, friction)  // Spring physics (tension=300, friction=20)
nc.steps(t, n)        // Stepped interpolation (n=4 steps)
nc.bounce(t)          // Bounce easing
```

### Interpolation & Math

```javascript
nc.lerp(a, b, t)                        // Linear interpolation
nc.clamp(v, min, max)                   // Clamp to range
nc.map(v, inMin, inMax, outMin, outMax) // Remap a value between ranges
nc.smoothstep(edge0, edge1, t)          // Smooth Hermite interpolation
nc.degToRad(degrees)                    // Degrees to radians
nc.radToDeg(radians)                    // Radians to degrees
nc.random(seed)                         // Seeded pseudo-random number
nc.noise(x, y, seed)                    // 2D value noise
```

### Color Utilities

```javascript
nc.rgba(r, g, b, a)           // Build an rgba() CSS string
nc.hexToRgb(hex)              // Parse hex → { r, g, b, a }
nc.lerpColor(colorA, colorB, t) // Interpolate between two CSS colors
```

### Typography (Core Text–backed)

These functions call into CoreText and are available on Apple platforms only:

```javascript
// Returns { width, height } in pixels
// font is a full CSS font string, e.g. 'bold 32px "Georgia"'
nc.measureText(text, font)

// Returns an array of lines that fit within maxWidth
// font is a full CSS font string, e.g. '14px "Georgia"'
nc.wrapText(text, maxWidth, font)

// Returns the largest font size (in points) that fits text within maxWidth
// style is an optional CSS weight/style prefix, e.g. "bold" or "italic bold"
nc.fitText(text, maxWidth, fontFamily, style?)
```

### Drawing Helpers

```javascript
// Draws a rounded rectangle path (does not fill or stroke)
nc.roundRect(ctx, x, y, width, height, radius)

// Fills text with optional shadow properties
nc.drawTextWithShadow(ctx, text, x, y, {
    shadowColor, shadowBlur, shadowOffsetX, shadowOffsetY
})

// Fills a highlight rectangle
nc.highlightWord(ctx, word, { x, y, width, height }, color)
```

### Layout Helpers

```javascript
// Returns { top, bottom, left, right } with 5% insets
nc.safeArea(scene.viewport)

// Returns an array of { x, y, width, height } cell objects
nc.grid(scene.viewport, cols, rows)
```

## The Render Function Signature

Each layer's `render` function receives three arguments:

```javascript
render: function(ctx, params, scene) { ... }
```

| Parameter | Description |
|-----------|-------------|
| `ctx` | The Canvas 2D context object (backed by ``CanvasBridge``) |
| `params` | Parameter values, merged from schema defaults and any runtime overrides |
| `scene` | Runtime scene data (see below) |

### The `scene` object

```javascript
scene.t            // Normalised time: 0.0 → 1.0
scene.frame        // Integer frame number
scene.viewport     // { width, height, orientation, aspectRatio, pointScale, safeArea }

// Any fields from your Swift Encodable scene struct are also present:
scene.title        // ← your field
scene.accentColor  // ← your field
```

## Layers

The `layers` global must be a non-empty JavaScript array. Each element is an object
with at minimum a `render` function:

```javascript
{
    name: "layer_name",          // string identifier (required)
    editableParam: "paramKey",   // optional: links this layer to a text param for inline editing
    render: function(ctx, params, scene) { ... }
}
```

NativeCanvas calls each layer's `render` function in array order, wrapping each
call in a `ctx.save()` / `ctx.restore()` pair so transforms and state changes
in one layer do not affect subsequent layers.
