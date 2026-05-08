# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Goal

Port of the Cuis Smalltalk VectorEngine (originally from `VectorEnginePlugin.pck.st`) to Pharo Smalltalk. Target: fully working vector graphics rendering including TrueType font display, backed by unit tests, following Pharo coding conventions.

## Loading into Pharo

```smalltalk
Metacello new
    baseline: 'VectorGraphics';
    repository: 'github://rvillemeur/VectorGraphics:main/src';
    onConflictUseIncoming;
    load
```

## Running Tests

In Pharo, open the Test Runner and run `VectorEngineTest`, or evaluate:

```smalltalk
VectorEngineTest suite run
```

Run a single test:

```smalltalk
VectorEngineTest run: #testAlphaValue
```

## Quick Rendering Examples

```smalltalk
"Stroke only"
(VectorEngineSubPixel onForm: Display)
    strokeWidth: 1.0 color: Color black do: [ :engine |
        engine abs_EllipseCenterX: 100 y: 100 radiusX: 80 radiusY: 40
               rotationAngle: -0.2 start: 0 sweep: Float pi * 2 ].
Display forceToScreen.

"Stroke + fill"
(VectorEngineSubPixel onForm: Display)
    strokeWidth: 1.0 color: Color black fillColor: Color red do: [ :engine |
        engine abs_MoveToX: 20 y: 10;
               abs_LineToX: 210 y: 15;
               abs_LineToX: 20 y: 20;
               do_ClosePath ].
Display forceToScreen.
```

Class-side `exper*` methods on `VectorEngineAbstract` and its subclasses contain runnable examples.

## Package Structure

All code lives in `src/VectorGraphics/` under four tags:

| Tag | Purpose |
|-----|---------|
| `kernel` | Core rendering engine and canvas |
| `PathCommands` | SVG path command objects |
| `TrueType` | Font file parsing and glyph rendering |
| `tests` | SUnit test cases |

## Architecture

### Rendering Pipeline (`kernel`)

```
VectorCanvas (subclass of Canvas)
    └── VectorEngineAbstract  (abstract, owns path state & coordinate transform)
            └── VectorEnginePixel  (pixel-level alpha mask + edge count buffers)
                    ├── VectorEngineSubPixel   (sub-pixel AA; 3 bytes/pixel for R/G/B channels)
                    └── VectorEngineWholePixel (whole-pixel AA; 1 byte/pixel; for hi-DPI)
```

`VectorEngine` (not `Abstract`) is a standalone, simpler implementation that keeps `alphaMask` and `edgeCounts` as plain `ByteArray`s — used as the reference implementation for unit tests and for understanding the core algorithm.

**Anti-aliasing algorithm** (Vuletich prefiltering):
1. Path traversal in sub-pixel hops (`primLineFrom:to:hops:increment:`).
2. Per hop, update `alphaMask` (distance buffer) via `updateAlphasFor:`.
3. Per hop, update `edgeCounts` (winding number for fills) via `updateEdgesAndBoundsForX:y:`.
4. After path done, blend stroke/fill colors into `targetForm` using the buffers.

Key numeric conventions: `alphaMask` value `16r7F` = opaque center; `16r00` = fully transparent. Alpha decreases from center outward through the translucent band.

`VectorEngineAbstract` stores path state (`pathCurrentX/Y`, `previousCallX/Y`, etc.) and a `geometryTransformation` for coordinate mapping. All drawing methods are prefixed `abs_` (absolute coords) or `rel_` (relative coords), matching SVG conventions.

### SVG Path Commands (`PathCommands`)

`PathCommand` (abstract) — subclasses map to SVG path letters:

| Class | SVG letter |
|-------|-----------|
| `PathMoveToCommand` | M |
| `PathLineToCommand` | L |
| `PathLineToHCommand` | H |
| `PathLineToVCommand` | V |
| `PathCurveToCommand` | C (cubic Bézier) |
| `PathCurveToSmoothCommand` | S |
| `PathQuadraticCurveToCommand` | Q |
| `PathQuadraticCurveToSmoothCommand` | T |
| `PathArcCommand` | A |
| `PathCloseCommand` | Z |

Parse entry point: `PathCommand class >> from: commandChar stream: aStream`. Each subclass implements `runOn: aCanvas` to drive a `VectorCanvas`.

### TrueType Font Rendering (`TrueType`)

```
TTFontReader                  reads raw .ttf bytes
    └── builds TTFontDescription   (in-memory font: glyphs, metrics, kern pairs)
            └── TTGlyph            (one glyph: bounds, contours, advance width)
                    └── TTContourConstruction  (temporary, used during parsing)

TrueTypeFontFamily            groups TTFontDescriptions by emphasis (bold/italic/…)
    └── TrueTypeFont          (subclass of AbstractFont; specific point size)
            └── FormGlyph     (pre-rendered Form, used with BitBltCanvasEngine)

FontFamily                    registry of available families; class-side AvailableFamilies dict
```

`Int16PointArray` (subclass of `DoubleByteArray`) stores signed 16-bit x/y glyph coordinates efficiently.

`DirectoryEntry` and `PreferenceSet` are Pharo stubs standing in for Cuis classes of the same name.

## Porting Notes (Cuis → Pharo)

- Cuis uses `ShortPointArray`; Pharo equivalent is `DoubleByteArray` — `Int16PointArray` wraps this.
- `PreferenceSet` and `DirectoryEntry` exist only as compatibility stubs; real Pharo alternatives should replace them as the port matures.
- `VectorCanvas` inherits from Pharo's `Canvas`; Morphic integration depends on Pharo's Morphic API.
- `TrueTypeFont` inherits from Pharo's `AbstractFont`; font-metrics methods must match Pharo's font protocol.
- `VectorEngineAbstract` references `AffineTransformation` — verify this resolves to a Pharo class (likely from the Athens or Morphic package).
