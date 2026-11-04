# Plan: document the architecture of the base VectorGraphics package

The engine and the TrueType code are the oldest part of this project and the least documented at
the level that matters. Every class here already carries a comment of 800 to 2400 characters, so
what is missing is not per-class prose: it is the facts that span classes, and a way for a reader
to see the live buffers rather than read a paragraph about them.

Three artefacts, in this order. Each is one unit of work, finished only when its tests pass and
the critics are clean on what it changed.

## Unit 1 — the package comment, and the stale selectors around it

`ManifestVectorGraphics comment`, which is what `(PackageOrganizer default packageNamed:
'VectorGraphics') packageComment` answers, is 794 characters and wrong in two ways: it lists the
tags as `kernel` and `tests` where the package really holds `Kernel` and `Tests`, and it does not
mention the `SVG` tag at all.

The comment is the map, not the manual. It says what the package is, names the seven tags as they
really are — `Kernel`, `PathCommands`, `TrueType`, `SVG`, `Examples`, `Tests`, `Manifest` — gives
the three entry points, and points at the longer documents:

| Entry point | For |
|---|---|
| `VectorCanvas class >> onForm:` | drawing through Pharo's `Canvas` protocol |
| `VectorEngineSubPixel class >> onForm:` | drawing straight on a `Form`, no Morphic |
| `FontFamily class >> familyName:pointSize:` | text, which answers a `TrueTypeFont` |

Two tests in a new `VectorGraphicsDocumentationTest`, in the `Tests` tag of this package:

- the package comment names every tag the package has;
- and names no tag the package does not have, so a renamed tag fails here rather than misleading a
  reader.

The same unit fixes two selector names that this project's own documents get wrong, because the
first port renamed them: `CLAUDE.md` says `primLineFrom:to:hops:increment:` and
`updateAlphasFor:`, where the code has `primLineFromX:y:toX:y:hops:incrementX:incrementY:` and
`updateAlphasForX:y:`.

## Unit 2 — `doc/ARCHITECTURE.md`

The long form, and only what no single class comment can own. Ten sections:

1. **Coordinate spaces.** What `geometryTransformation:` maps, what `abs_` and `rel_` mean, where a
   figure is in path space and where it is in device pixels.
2. **The four layers of a path call.** `abs_…`/`rel_…` take points and keep the SVG state
   (`previousCallX/Y`, `previousCallControlX/Y`); `basic…X:y:` take numbers; `prim…hops:` walk the
   curve in sub-pixel hops; `do_ClosePath` and `finishPath:` end it. A reader needs the order,
   because only the `prim` layer touches the buffers.
3. **The buffers.** `alphaMask` and `edgeCounts`, the blend bounds
   (`blendLeft`/`Top`/`Right`/`Bottom`), the clip bounds, and the four `aux…` stroke radii that
   `VectorEnginePixel class >> computeStrokeRadii:antiAliasingWidth:` precomputes. One table: what
   each holds, how wide a pixel is in it, and who writes it.
4. **The anti-aliasing algorithm** (Vuletich prefiltering), as the hop loop really is:
   `primLineFromX:y:toX:y:hops:incrementX:incrementY:` per segment, then `updateAlphasForX:y:` and
   `updateEdgesAndBoundsForX:y:` per hop, then a blend pass. `16r7F` is an opaque centre and
   `16r00` is fully transparent.
5. **The two concrete engines.** `VectorEngineSubPixel` keeps three bytes a pixel and a
   `subPixelDelta`, and decides per channel (`…redIsInside:greenIsInside:blueIsInside:`);
   `VectorEngineWholePixel` keeps one byte and decides per pixel (`…isInside:`). When each wins.
6. **The blend stage.** `blendStrokeOnly`, `blendFillOnly`, `blendStrokeAndFill`, and why the
   horizontal expansion exists.
7. **Morphic integration.** `VectorCanvas` holds two engines — `engine` and `boundsFinderEngine` —
   and the engine tracks `morphIds`, `currentMorphId` and `clippingMorphId`. `updatingMorphBoundsDo:`
   and `morphBoundsAfterDraw` are how a morph learns the bounds it really painted, and
   `morph:isAtPoint:` is the hit test that reads the same buffers.
8. **The TrueType chain, with the handoff at each arrow.** `TTFontReader readTTFFrom:` → a
   `TTFontDescription` holding `contourDataForUtf8` and `contourDataIndexesByUtf8` → `TTGlyph` with
   contours in an `Int16PointArray` → `TTContourConstruction`, which exists only while parsing →
   `FormGlyph`, one glyph rendered into a `Form`. Composite glyphs
   (`replaceIndexesByComponentGlyphsIn:`, `isComposite`) and kern pairs belong here.
9. **The four caches, and who clears them.** `TTFontDescription class >> Descriptions`,
   `FontFamily class >> AvailableFamilies`, `TrueTypeFont >> glyphFormsByUtf8` and
   `TrueTypeFontFamily >> ttFontDescriptionsByEmphasis`, against `releaseCachedState`,
   `clearCache` and `releaseClassCachedState`. A reader who misses this renders every glyph twice.
10. **SVG, and the traps.** `SVGPathParser class >> parse:` and `SVGNumberStream` feed
    `PathCommand class >> from:stream:`, whose instances `runOn:` a canvas. Then the costs worth
    knowing before touching any of it: this engine is about a thousand times slower than Cairo on
    a real frame, a glyph `Form` is cached but a contour is re-walked, and a font handle outliving
    its library has killed the image before.

The gate is a test, not a promise, in the same `VectorGraphicsDocumentationTest`: every class name
the document writes in backticks exists, and every keyword selector it writes in backticks is
implemented somewhere in the image. A rename then fails the suite instead of rotting the document.
The test reads the file through the Iceberg checkout, because a repository under `pharo-local` is
invisible to anything else, and skips if the checkout is not there.

## Unit 3 — the views, and the examples that feed them

The engine side has no inspector view at all: `VectorCanvas`, `VectorEngineAbstract`,
`VectorEnginePixel`, `VectorEngineSubPixel` and `VectorEngineWholePixel` define no `inspector…`
method, and in the whole package only `TTFontDescription` does, with `Glyph map` and `Map density`.
A view shows what a paragraph can only assert, and it cannot drift, so this unit is the half of the
documentation that stays true on its own.

| Class | View | Shows |
|---|---|---|
| `VectorEnginePixel` | `Buffers` | the alpha mask as a `Form`, the edge counts, the blend and clip bounds, the precomputed stroke radii |
| `VectorEngineAbstract` | `Path state` | the first, current and previous points, the control point, `hopsPerPixel`, the stroke and anti-aliasing widths, the morph bounds |
| `VectorCanvas` | `Target` | the target `Form`, the clip rectangle, the current and clipping morph, and which engine class is drawing |
| `TTGlyph` | `Contours` | one row a contour: point count, on-curve against control points, and the bounds |
| `TTGlyph` | `Glyph` | the glyph drawn at a readable size |

Every view answers a presenter built from the live object and never writes to it: a view that has to
move or insert something inserts into a `copy`. A view that only makes sense in part of the
hierarchy carries its `…Context:` gate; `VectorEnginePixel >> inspectorBuffersContext:` is the one
that needs it, since the buffers exist only once a path has been walked.

Each view needs a one-click object to show it on, so this unit adds class-side `<sampleInstance>`
examples to the two holders the package already has — `VectorCanvasExample` (24 examples) and
`TrueTypeExample` (7) — rather than a new package: the dependency table gives this package no
outgoing edge, and its examples have always lived in its own `Examples` tag.

The gate is a third set of tests in the same new test class, and it is deliberately a small copy of
what `VGCairoExamplesTest` does for the layers above. It cannot be a subclass of it:
`VGArchitectureTest class >> allowedDependencies` gives `'VectorGraphics' -> #( )`, so no class of
this package may name a class of `VectorGraphics-Cairo-Tests`. The tests: every example rebuilds its
object on each call, every holder has a class comment, every view builds and fills its cells, and
every view that has a gate answers it both ways.

## Order, and what done means

Unit 1, then 2, then 3, each committed on its own. A unit is done when:

- its tests pass, and the suites of the package still pass;
- `run_critics` is clean on the classes it touched;
- the documents and the code agree, which after unit 2 is a test rather than a reading.

## What was done

All three units are done, each on its own commit.

| Unit | Commit | Result |
|---|---|---|
| 1 | `8372aec` | The package comment rewritten, three tests holding it to the real tags of the package, and the two stale selector names in `CLAUDE.md` corrected |
| 2 | `80225fc` | `doc/ARCHITECTURE.md`, thirteen sections, and four tests holding every name it writes in backticks to the image |
| 3 | `0e14cca` | Five inspector views, three examples feeding them, and four gates over the examples and the views |

Three things differ from the plan above, each for a reason found while doing the work:

- **The views need no `…Context:` gate.** The plan asked for one on
  `VectorEnginePixel >> inspectorBuffers`, since the buffers hold something only during a path.
  The view says that instead: it is always shown, and it reports how many pixels of each buffer
  hold anything, which is zero after a finished drawing. A gate would have hidden the fact the
  reader most needs.
- **The example for the buffers walks a path through the public entry and stops before the
  blend.** An empty `fillColor:do:` first gives the engine its stroke radii and its hops per
  pixel, then `initializePath` and the path commands leave both buffers full and unblended. No
  new method was needed on the engine to reach that state.
- **Two gaps of the port came out of writing the views**, and are now in `doc/ARCHITECTURE.md`
  rather than only in a reader's head: nothing assigns `boundsFinderEngine`, so
  `updatingMorphBoundsDo:` hands the canvas nil, and nothing in a Pharo image answers `morphId`,
  which `currentMorph:` asks of the morph it is given, so `morphIds` stays empty and
  `morph:isAtPoint:` finds nothing. Both are defects of the port, not of the design, and neither
  is fixed here: a fix belongs in its own unit, with the failing test first.

The suite of the base package is 226 tests over 23 concrete test classes and passes. `run_critics`
reports nothing new on any class touched; what it does report on `VectorEnginePixel`,
`VectorEngineAbstract` and `VectorCanvas` was there before this work and is unchanged by it.
