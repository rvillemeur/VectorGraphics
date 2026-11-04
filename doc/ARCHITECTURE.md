# Inside the VectorGraphics package

This document holds what no single class comment can: the facts that span classes. Each class here
already carries its own comment, and the inspector views of the engine show the live state, so this
file states the order of things and the conventions two classes have to agree on.

Everything below is in the `VectorGraphics` package, which depends on nothing above it.

## 1. Coordinate spaces

There are two, and only one conversion between them.

- **Device space** is pixels of the target `Form`, x to the right and y down, which is what every
  buffer and every clip rectangle is indexed in.
- **Path space** is what a caller draws in. `geometryTransformation:` holds the map from it to
  device space, and a nil transformation means the two are the same: `VectorCanvas class >> onForm:`
  takes that case, so coordinates are pixel-direct unless a transformation is installed.

A drawing method is prefixed for which space its arguments are read in: `abs_` takes absolute path
coordinates, `rel_` takes an offset from the current point. Both match the SVG letters of the same
name.

## 2. The four layers of a path call

A call from a client goes down four layers, and only the last one touches a buffer. Knowing the
order is what makes the engine readable.

| Layer | Example | What it adds |
|---|---|---|
| `abs_…` / `rel_…` | `abs_EllipseCenter:radiusX:radiusY:rotationAngle:start:sweep:` | takes points, keeps the SVG state: `pathCurrentX` and `pathCurrentY`, `previousCallX` and `previousCallY`, and the reflected control point `previousCallControlX` and `previousCallControlY` |
| `basic…` | `basicCubicBezierToX:y:control1X:y:control2X:y:` | takes numbers, applies the transformation, decides how many hops the curve needs |
| `prim…` | `primLineFromX:y:toX:y:hops:incrementX:incrementY:` | walks the figure in sub-pixel hops; the only layer that writes the buffers |
| end of path | `do_ClosePath`, `finishPath:` | closes the figure if asked, grows the blend box, then blends |

The `prim` layer is `subclassResponsibility` in `VectorEngineAbstract`: the abstract class owns the
path state and the geometry, and a concrete engine owns the pixels. There are four of them —
`primLineFromX:y:toX:y:hops:incrementX:incrementY:`,
`primQuadraticBezierFromX:y:toX:y:controlX:y:hops:`,
`primCubicBezierFromX:y:toX:y:control1X:y:control2X:y:hops:` and
`primArcCenterX:centerY:radiusX:radiusY:start:rotationCos:rotationSin:hops:angleDelta:`.

## 3. The buffers

`VectorEnginePixel` allocates one slot a pixel in each of three buffers, every time a `Form` is
installed. Width and height come from the target `Form`, so a resize means a new buffer.

| Buffer | In `VectorEngineSubPixel` | In `VectorEngineWholePixel` | Holds |
|---|---|---|---|
| `alphaMask` | `WordArray`, one 32-bit word a pixel | `ByteArray`, one byte a pixel | distance from the figure, as coverage: `16r7F` is an opaque centre, `16r00` is fully transparent |
| `edgeCounts` | `WordArray` | `ByteArray` | the winding number a fill is decided by, as a signed byte |
| `morphIds` | `WordArray`, allocated in `VectorEngineAbstract` | the same | which morph painted the pixel, which is what `morph:isAtPoint:` reads |

In the sub-pixel engine the three channel bytes of a word are little-endian, so byte 1 is blue,
byte 2 green and byte 3 red. `WordArray >> bytesAt:` and `WordArray >> bytesAt:put:` are how the
engine reads and writes one pixel as four bytes, and both are extension methods of this package —
as are `Bitmap >> bytesAt:`, `ByteArray >> bitAt:bitPosition:`, `SmallInteger >> digitAt:`,
`Character class >> utf8BytesOf:` and `Character class >> evaluate:withUtf8BytesOf:`. Fifteen such
methods on base classes belong to this package; none of them may be moved upstream without a
reason, and none of them is a patch of existing behaviour.

Four more numbers are precomputed per stroke by
`VectorEnginePixel class >> computeStrokeRadii:antiAliasingWidth:`, which answers the dilated half
width `(strokeWidth + antiAliasingWidth) / 2`, its square, and the **signed** square of the eroded
half width `(strokeWidth - antiAliasingWidth) / 2`. The sign is the point: a stroke thinner than
the anti-aliasing width has a negative eroded radius, so no pixel of it is ever fully opaque.
The anti-aliasing width itself is a class decision — 1.4 in `VectorEngineSubPixel`, 1.7 in
`VectorEngineWholePixel`, 1.0 as the default of `VectorEngineAbstract`.

## 4. The anti-aliasing algorithm

Vuletich prefiltering: a figure is walked rather than scanned, and every hop writes coverage
around itself.

1. The `prim` layer walks the figure in hops smaller than a pixel, `hopsPerPixel` of them to the
   pixel.
2. Each hop calls `updateAlphasForX:y:`, which writes every pixel within the dilated half width of
   the hop, comparing the squared distance against the two squared radii of section 3 and keeping
   the larger coverage already there.
3. Each hop calls `updateEdgesAndBoundsForX:y:`, which records a crossing in `edgeCounts` whenever
   the walk changes pixel row — `VectorEngineSubPixel >> updateEdgeCountAtX:y:` is that step, and
   it keeps `prevYTruncated` to know. A crossing left of the clip rectangle is counted at its left
   edge instead, which both keeps the winding number right and avoids writing outside the buffer.
4. `finishPath:` closes the figure if asked, grows the blend box by the dilated half width and by
   `blendHorizontalExpansion`, folds that box into the morph bounds, and only then intersects it
   with the clip rectangle.
5. A blend pass walks the blend box row by row, accumulates the winding number along the row,
   decides inside or outside, and writes the colours into the target `Form`.

**The buffers are consumed by the blend.** The pass writes zero into `alphaMask` and `edgeCounts`
at every pixel it visits, because the next path has to start from a clean buffer and clearing the
whole buffer would cost more than the drawing. So a buffer inspected after a completed drawing is
all zeros; the Buffers view of `VectorEnginePixel` says so, and its example walks a path without
blending it.

## 5. The two concrete engines

| | `VectorEngineSubPixel` | `VectorEngineWholePixel` |
|---|---|---|
| Memory | four bytes a pixel in each buffer | one byte a pixel |
| Decides | per colour channel, at three x positions `subPixelDelta` apart (0.25 of a pixel) | once a pixel |
| Blend hook | `blendFillOnlyAtX:y:pixelIndex:redIsInside:greenIsInside:blueIsInside:` | `blendFillOnlyAtX:y:pixelIndex:isInside:` |
| Horizontal expansion | `subPixelDelta`, since the red and blue samples sit outside the pixel | none |
| Use it for | an ordinary display, where three times the horizontal resolution is free | a high-DPI display, where it is not worth four times the memory |

Both are subclasses of `VectorEnginePixel`, so the path state, the bounds and the stroke radii are
written once.

## 6. Stroke, fill, and the passes they need

`strokeWidth:color:fillColor:do:` is the one entry a client should use, and it decides how many
passes the figure needs before any pixel is touched:

- no stroke colour, a transparent stroke colour, or a zero width, and it is `fillColor:do:` alone;
- no fill colour or a transparent one, and it is `strokeWidth:color:do:`;
- a stroke thinner than the anti-aliasing width, in a colour different from the fill, and it draws
  twice — the fill first, then the stroke — because one pass cannot keep two colours apart inside
  a band narrower than the filter.

The blend hooks follow the same three cases: `blendFillOnly`, `blendStrokeOnly` and
`blendStrokeAndFill`.

## 7. Morphic integration

`VectorCanvas` is a subclass of Pharo's `Canvas` and holds **two** engines: `engine`, which draws,
and `boundsFinderEngine`, which measures. `updatingMorphBoundsDo:` swaps the second in for the
duration of a block and restores it in an `ensure:`, so a morph can be asked what it would paint
without painting it. **In this port the second engine is never built**: nothing assigns
`boundsFinderEngine`, so the swap hands the canvas nil and a drawing inside that block fails. Ask
the drawing engine for `morphBoundsAfterDraw` after a real drawing until a bounds finder is built.

`VectorCanvas class >> onForm:` installs a `VectorEngineWholePixel`, so a canvas is one byte a
pixel in each buffer unless the engine is replaced by hand.

Three pieces of state make a morph tree work on one `Form`:

- `currentMorph:` sets the id written into `morphIds` for every pixel painted from here on, and
  `morph:isAtPoint:` is the hit test that reads it back. A morph with an irregular outline is hit
  tested against what it really painted, not against its bounds. **Nothing in a Pharo image
  answers `morphId`**, which is what `currentMorph:` asks of the morph it is given, so the id
  stays zero, `morphIds` stays empty and the hit test finds nothing until a morph class answers
  it. The Target view of `VectorCanvas` reports that rather than describing it.
- `clippingMorph:` names the morph whose painted pixels a drawing may touch, which is how a child
  is clipped to a parent of any shape: the blend pass skips a pixel whose `morphIds` entry is
  neither the clipping morph nor the current one.
- `morphBoundsAfterDraw` answers what the last drawing actually covered, in device space and
  before any clipping, which is what a morph stores as its own bounds. It is valid only straight
  after the drawing.

`setClipRect:` is in device coordinates and its convention is worth stating once: the rectangle
includes its left and top and excludes its right and bottom, so `clipRect:` keeps
`right - 1` and `bottom - 1` as the last pixel it draws.

## 8. Text: two routes to a glyph

A glyph can be drawn as a figure or stamped as a picture, and the package does both.

**The vector route**, which is what this engine exists for:
`VectorEngineAbstract >> displayUtf8:at:trueTypeFont:color:scaleX:scaleY:` reads the contour data
of the font straight out of `TTFontDescription >> contourDataForUtf8`, indexed by
`contourDataIndexesByUtf8`, and walks it as quadratic Béziers inside one `fillColor:do:`. No
`TTGlyph` object is built at draw time. The scale is `1.0 /`
`TTFontDescription >> letterMTopSideBearing`, so a font is normalised by the height of its own
letter M, and the point size multiplies that. A byte with no entry in the map reads the unknown
glyph, and the continuation bytes of an unmapped code point are skipped, so one unmapped character
draws one unknown glyph rather than one per byte.

**The Form route**, which exists for anything blitting glyphs:
`TTFontDescription >> formGlyphForUtf8Byte1:byte2:byte3:byte4:pixelSize:` draws one glyph into a
`Form` and answers a `FormGlyph`, which carries that `Form` with its offsets and advance width.
`TrueTypeFont >> glyphAtUtf8Byte1:byte2:byte3:byte4:` is the cache in front of it.

## 9. Reading a font

```
TTFontReader class >> readTTFFrom:    raw .ttf bytes
    → TTFontDescription               one face: contour data, metrics, kern pairs
        → TTGlyph                     one glyph: bounds, contours, advance width
            → TTContourConstruction   parse time only: points and their control flags
                → Int16PointArray     the coordinates, signed 16-bit, two per element

FontFamily                            registry, class-side, by family name
    → TrueTypeFontFamily              the faces of one family, by emphasis
        → TrueTypeFont                one family at one point size
            → FormGlyph               one glyph pre-rendered into a Form
```

Three details the chain depends on:

- `TTContourConstruction >> quadraticBeziersDo:` is where the TrueType flags become geometry: two
  consecutive end points are a straight segment, an end point and a control point and an end point
  are one quadratic Bézier, and two consecutive control points have an implied end point halfway
  between them. `TTGlyph >> addContourDataTo:tx:` writes the result into the flat contour data the
  vector route reads.
- A composite glyph holds indexes rather than contours until
  `TTGlyph >> replaceIndexesByComponentGlyphsIn:` resolves them, and `TTGlyph >> isComposite`
  answers whether it had any.
- `TTFontDescription class >> read:` walks a directory of `.ttf` files and files each face under
  its family name and emphasis.

## 10. The four caches, and who clears them

| Cache | Lives in | Cleared by |
|---|---|---|
| every face read from disk, by family name and emphasis | the `Descriptions` class variable of `TTFontDescription` | nothing: it is the image's font library |
| the available families | the `AvailableFamilies` class variable of `FontFamily` | `FontFamily class >> releaseClassCachedState` |
| the faces of one family, by emphasis | the `ttFontDescriptionsByEmphasis` instance variable of `TrueTypeFontFamily` | `TrueTypeFontFamily >> clearCache` |
| one rendered `FormGlyph` per code point | the `glyphFormsByUtf8` instance variable of `TrueTypeFont`, a four-level tree 64 wide, one level a UTF-8 byte | `TrueTypeFont >> releaseCachedState`, which also walks the derivative fonts |

A reader who misses the last one renders every glyph of every frame again.

## 11. SVG path data

`SVGPathParser class >> parse:` reads a `d` attribute into a sequence of `PathCommand` instances,
with `SVGNumberStream` doing the lexing. `PathCommand class >> classFor:` maps the letter to the
class — `PathMoveToCommand` for M, `PathLineToCommand` for L, `PathLineToHCommand` for H,
`PathLineToVCommand` for V, `PathCurveToCommand` for C, `PathCurveToSmoothCommand` for S,
`PathQuadraticCurveToCommand` for Q, `PathQuadraticCurveToSmoothCommand` for T, `PathArcCommand`
for A and `PathCloseCommand` for Z — and `PathCommand class >> from:stream:` builds one. A lower
case letter means relative coordinates, which the instance keeps in
`PathCommand >> coordinatesAreRelative`.

Each instance then drives a canvas through `runOn:`, which is the only thing the commands know
about drawing. `VectorCanvas >> runPathCommands:` runs a whole sequence.

## 12. Costs and traps

- **This engine is slow.** On an 800 by 600 frame of twelve cards the whole of it takes about 2149
  ms where Cairo takes under 2 ms, and nearly all of that is the hop walk and the blend. It is
  correct and self-contained, not fast.
- **The buffers are empty after a drawing**, as section 4 says. Inspect them during a path, not
  after one.
- **The vector route re-walks the contour data on every draw.** Only the `Form` route is cached.
- **A buffer belongs to one `Form` size.** Installing a `Form` reallocates all three buffers, and
  an engine kept across a resize would index the old width.
- **The clip rectangle excludes its right and bottom edge**, while the engine's `clipRight` and
  `clipBottom` are the last pixel drawn. An off-by-one here shows as a one-pixel seam between
  sibling morphs.
- **A hit test needs the drawing it is asking about.** `morphIds` is written while painting, so
  `morph:isAtPoint:` answers about the last frame drawn on that `Form` and nothing else.

## 13. Where to look in the image

Every claim above can be opened. Each view is one click from an example, and each example
rebuilds its subject every call.

| View | Example that feeds it | Shows |
|---|---|---|
| `VectorEnginePixel >> inspectorBuffers` | `VectorCanvasExample class >> exampleEngineDuringAFillPath` | the three buffers during a path, counted rather than described |
| `VectorEngineAbstract >> inspectorPathState` | the same example | the path state, the two morph ids and the bounds of the last drawing |
| `VectorCanvas >> inspectorTarget` | `VectorCanvasExample class >> exampleCanvasAfterADrawing` | the target form, which engine draws and which measures |
| `TTGlyph >> inspectorContours` | `TrueTypeExample class >> exampleGlyphWithContours` | each contour, with its straight segments and its quadratic Béziers counted by the drawing rule itself |
| `TTGlyph >> inspectorGlyph` | the same example | the glyph as `VectorCanvas` really fills it |
| `TTFontDescription >> inspectorGlyphMap` | `TrueTypeExample class >> exampleGlyphMap` | every code point the font maps, with the record it points at |
| `TTFontDescription >> inspectorMapDensity` | the same example | what that map costs in floats and index entries |

`VectorGraphicsDocumentationTest` holds this document and those artefacts to the code: every name
written in backticks here must exist, every example must run, every view must build from its
example, and no view may change what it inspects.
