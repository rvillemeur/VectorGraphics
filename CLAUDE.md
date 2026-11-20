# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Goal

Two goals, one built on the other.

1. Port the Cuis Smalltalk VectorEngine (originally `VectorEnginePlugin.pck.st`) to Pharo: vector
   rasterising in pure Pharo, TrueType glyph rendering included, backed by unit tests.
2. Stand in for the Cairo layer of Alexandrie, so that Bloc — and anything else drawing through
   `AeCanvas` — draws through this rasteriser instead of libcairo, and so that a Vulkan device can
   draw the same frame.

What the measurements say, so that no unit is planned on a wrong premise. On an 800 by 600 frame of
twelve cards this project takes about 2149 ms where Cairo takes 1.8 to 2.1 ms, which is around a
thousand times slower, and all of it is in the drain: recording the frame costs 4 to 9 ms. The
Vulkan device path draws the same frame 50 to 68 times faster than the software rasteriser and is
still about 130 times slower than Cairo, which draws it in 289 to 324 microseconds warm. Bloc's
default renderer therefore stays Alexandrie's; this project is the replacement a user asks for.

## Loading into Pharo

The default load is the rasteriser and the three canvas packages alone. None of them names a class of Bloc
or of Alexandrie, so both load in an image that holds neither.

```smalltalk
Metacello new
    baseline: 'VectorGraphics';
    repository: 'github://rvillemeur/VectorGraphics:main/src';
    onConflictUseIncoming;
    load
```

Every layer above that is a group: `bloc` brings the renderer and Bloc itself, `canvas-tests` brings
the conformance corpus without Bloc, `vulkan` brings the device path and needs PharoVulkan loaded
by hand, because it is not published. `fonts` brings the renderer and poses it, together with
this project's font manager, as the load runs: its package carries a `postLoadDoIt:` sending
`VGFontEngine install`, so an image that drew text through FreeType draws it through this project
when the load returns, with nothing left to evaluate. `README.md` lists every group and `doc/USAGE.md` says
which group each level of use needs. Change a group or an edge in `BaselineOfVectorGraphics` only
together with the test that states it.

## Running Tests

There is no single suite class. Each code package is covered by the test package named after it,
except the rasteriser, whose tests live in the `Tests` tag of `VectorGraphics` itself.

| Where | Test classes |
|---|---|
| `VectorGraphics-Engine-Tests` | 8: `VectorEngineAbstractTest`, `VectorEnginePixelTest`, `VectorEngineWholePixelTest`, `VectorEngineBoundsFinderTest`, `VectorCanvasTest`, `PathCommandRunOnTest`, and the gates `VGEngineDocumentationTest` and `VGEngineExamplesTest` |
| `VectorGraphics-Paths-Tests` | 6: the four `Path…Test`, and the gates of the package |
| `VectorGraphics-TrueType-Tests` | 31: the `TT…`/`TrueType…Test` family, the twelve `TTCff…Test` of the Type 2 reader, `Int16PointArrayTest`, `FontFamilyTest`, `FormGlyphTest`, and the gates |
| `VectorGraphics-Text-Tests` | 3: `VGTextDrawingTest` and the gates |
| `VectorGraphics-Tests` | 1: `VectorGraphicsDocumentationTest`, the abstract gate the four above subclass |
| `VectorGraphics-Canvas-Tests` | 15: the `VGCairo…Test` family, `VGPaintTest`, `VGMeshTest`, and the gates `VGConformanceTest`, `VGAlexandrieCorpusTest`, `VGArchitectureTest`, `VGCairoExamplesTest` |
| `VectorGraphics-Canvas-Raster-Tests` | 5: `VGRasteriserTest`, `VGCairoClipTest`, `VGCairoStrokeTest`, `VGBlurTest`, `VGBackendSelectionTest` |
| `VectorGraphics-Canvas-Fonts-Tests` | 1: `VGCairoTextTest` |
| `VectorGraphics-Bloc-Tests` | 12: the canvas, renderer, offscreen, text and font manager suites, `VGFrameProfileTest`, `VGBlocExamplesTest` |
| `VectorGraphics-Bloc-FontEngine-Tests` | 2: `VGFontEngineTest`, `VGFontEngineExamplesTest` |
| `VectorGraphics-Vulkan-Tests` | 17: the `VGTiled…Test` family, `VGVulkan…Test`, the two benchmark tests, `VGKernelVisitCensusTest`, `VGBlurRoundingTest`, `VGVulkanExamplesTest` |

```smalltalk
VGCairoDrawingTest suite run.
VGCairoDrawingTest run: #testAFillOutsideTheSurfaceTouchesNothing.
```

Three things about the counts and the runs are worth knowing before trusting either.

- A package-level count double-counts an abstract `TestCase` with concrete subclasses
  (`VGTiledFrameTestCase`), so ask a concrete class when the number matters.
- `VGBlocExamplesTest` and `VGVulkanExamplesTest` define no test of their own: they subclass
  `VGCairoExamplesTest` and override `exampleHolders`, so their tests are inherited and
  `testSelectors` answers zero for them.
- A suite that opens a window or drives the device through uFFI has taken the image down. Commit
  the finished work first, then run that suite with nothing else touching the image.

## Package Structure

Thirty-five packages, source layout `src/<PackageName>/` in Tonel format. Iceberg manages commits
of `src/` — do not use git directly for it, and never hand-edit a `.class.st` file. Each code
package has a sibling `-Examples` and a sibling `-Tests` package; the table names the code ones and
the counts are of classes in the image.

| Package | Classes | Holds |
|---|---|---|
| `VectorGraphics` | 1 | The front page: the package comment and the Renraku rule configuration, no code |
| `VectorGraphics-Engine` | 7 | The scan-line rasteriser, tag `Kernel`: the canvas and the three engines |
| `VectorGraphics-Paths` | 15 | The SVG path commands, tag `Commands`, and the parser, tag `SVG` |
| `VectorGraphics-TrueType` | 44 | Reading a `.ttf`: tags `Reading`, `Glyphs`, `Fonts` and `CFF`, the Type 2 charstring reader |
| `VectorGraphics-Text` | 1 | The glue that draws a string with the engine: extension methods only |
| `VectorGraphics-Canvas` | 47 | The canvas that replaces Cairo: `Surface`, `Context`, `Display list`, `Path`, `Paint`, `Pattern`, `Compositing`, `Matrix`, `Export`, `Inventory`, `Reflection`, `Skeleton` |
| `VectorGraphics-Canvas-Raster` | 14 | Its software renderer: `Backend`, `Rasterising`, `Path` (the stroker), `Paint` (the mesh), `Blur` |
| `VectorGraphics-Canvas-Fonts` | 13 | Its scaled fonts, tag `Text`: the face, the scaled font, the glyph atlas and the extents |
| `VectorGraphics-Bloc` | 16 | `Backend` (`VGCanvas`, `VGRenderer`, `VGOffscreen`), `Hosts`, `Exporters`, `Profiling`, `Fonts`, `Text` |
| `VectorGraphics-Bloc-FontEngine` | 1 | `VGFontEngine`: one send that poses this project's fonts in Bloc, and one that gives the image back |
| `VectorGraphics-Vulkan` | 37 | The device path: `Backend`, `Tiles`, `Kernels`, `Blur`, `Budget`, `Present` |
| `VectorGraphics-Conformance` | 8 | The corpus every backend is compared against: the cases, the ported Alexandrie corpus, the `Form` comparison. No `TestCase` |
| `VectorGraphics-Benchmarks` | 4 | The frame harness: the drawing kit, the stage benchmark and the device benchmark. No `TestCase` |

## Which package may name which

This file does not say. `VGArchitectureTest class >> allowedDependencies` does, with one entry per
package, and its 60 tests hold the code, the baseline and the table to each other: a package absent
from the table fails a test, and so does a reference no entry allows. Adding a dependency means
stating it in the table and in `BaselineOfVectorGraphics`, in the commit that needs it.

Four facts of that table are easy to get wrong.

- The engine depends on nothing. The default group — the engine and the canvas — names
  no class of Bloc or of Alexandrie, and two tests hold that in both directions, by literal and by
  superclass.
- `VectorGraphics-Canvas-Examples` and `VectorGraphics-Canvas-Tests` name each other, because
  `VGArchitectureExamples` has the architecture gate itself for a subject. The baseline states
  one direction only, since a cycle has no load order. It is the one pair left: the conformance
  corpus and the benchmark harness moved into packages of their own in the review of 2026-11,
  which ended the second cycle.
- The canvas tests do name Alexandrie, on purpose: proving this rasteriser matches live Cairo byte
  for byte needs that positive control. No other package may.
- Only the Vulkan family may name a PharoVulkan class. That rule lives in
  `VGBackendSelectionTest`, through `VGCairoReferenceScanner`, not in `allowedDependencies`.

## Architecture

### The rasteriser (`VectorGraphics-Engine`)

```
VectorCanvas (subclass of Canvas)
    └── VectorEngineAbstract  (abstract, owns path state & coordinate transform)
            └── VectorEnginePixel  (pixel-level alpha mask + edge count buffers)
                    ├── VectorEngineSubPixel   (sub-pixel AA; 3 bytes/pixel for R/G/B channels)
                    └── VectorEngineWholePixel (whole-pixel AA; 1 byte/pixel; for hi-DPI)
```

**Anti-aliasing algorithm** (Vuletich prefiltering):

1. Path traversal in sub-pixel hops (`primLineFromX:y:toX:y:hops:incrementX:incrementY:`).
2. Per hop, update `alphaMask` (distance buffer) via `updateAlphasForX:y:`.
3. Per hop, update `edgeCounts` (winding number for fills) via `updateEdgesAndBoundsForX:y:`.
4. After path done, blend stroke/fill colors into `targetForm` using the buffers.

Key numeric conventions: `alphaMask` value `16r7F` = opaque center; `16r00` = fully transparent.
Alpha decreases from center outward through the translucent band.

`VectorEngineAbstract` stores path state (`pathCurrentX/Y`, `previousCallX/Y`, etc.) and a
`geometryTransformation` for coordinate mapping. All drawing methods are prefixed `abs_` (absolute
coords) or `rel_` (relative coords), matching SVG conventions.

```smalltalk
(VectorEngineSubPixel onForm: Display)
    strokeWidth: 1.0 color: Color black fillColor: Color red do: [ :engine |
        engine abs_MoveToX: 20 y: 10;
               abs_LineToX: 210 y: 15;
               abs_LineToX: 20 y: 20;
               do_ClosePath ].
Display forceToScreen.
```

### SVG path commands (`PathCommands`, `SVG`)

`PathCommand` (abstract) — subclasses map to SVG path letters: `PathMoveToCommand` M,
`PathLineToCommand` L, `PathLineToHCommand` H, `PathLineToVCommand` V, `PathCurveToCommand` C,
`PathCurveToSmoothCommand` S, `PathQuadraticCurveToCommand` Q,
`PathQuadraticCurveToSmoothCommand` T, `PathArcCommand` A, `PathCloseCommand` Z.

Parse entry point: `PathCommand class >> from: commandChar stream: aStream`. Each subclass
implements `runOn: aCanvas` to drive a `VectorCanvas`. `SVGPathParser` and `SVGNumberStream`, in the
`SVG` tag, read a whole `d` attribute.

### TrueType font rendering (`TrueType`)

```
TTFontReader                  reads raw .ttf bytes
    └── builds TTFontDescription   (in-memory font: glyphs, metrics, kern pairs)
            └── TTGlyph            (one glyph: bounds, contours, advance width)
                    └── TTContourConstruction  (temporary, used during parsing)

TrueTypeFontFamily            groups TTFontDescriptions by emphasis (bold/italic/…)
    └── TrueTypeFont          (subclass of AbstractFont; specific point size)
            └── FormGlyph     (one glyph pre-rendered into a Form)

FontFamily                    registry of available families; class-side AvailableFamilies dict
```

`Int16PointArray` (subclass of `DoubleByteArray`) stores signed 16-bit x/y glyph coordinates
efficiently.

### The canvas (`VectorGraphics-Canvas`, `-Canvas-Raster`, `-Canvas-Fonts`)

`VGCairoImageSurface` and `VGCairoContext` answer the selectors of `AeCairoImageSurface` and
`AeCairoContext`. A surface owns a `VGDisplayList` and every context drawing on it records
there, so that two contexts on one surface draw in the order their calls were made. No class of
`VectorGraphics-Canvas` calls a renderer: a backend drains the list through `drainInto:`, and
`VGSoftwareBackend`, in `VectorGraphics-Canvas-Raster`, rasterises it with the engine above, while
`VGVulkanBackend` fills it on the device. `VectorGraphics-Canvas-Fonts` holds a face at a size,
its glyph atlas and the extents text is measured by; it is a leaf, so a font can be scaled with no
renderer loaded. `VGCairoReferenceScanner`, in the `Reflection` tag, is how the architecture tests
read what a package really names. The class names keep the `VGCairo` prefix: they are the Cairo
selectors this layer stands in for, and renaming them would break every caller.
`CANVAS-SPLIT-PLAN.md` holds the split of November 2026, and each package comment holds its own
tags and entry points.

### The Bloc backend (`VectorGraphics-Bloc`)

`VGCanvas` is an `AeCanvas` overriding the six methods that build a backend object; `VGRenderer` is
a `BARenderer`, named through `BlHostRenderer preferableClass: VGRenderer`.
Bloc measures a paragraph during layout, before any frame exists, and the canvas that answers
those measurements is `VGOffscreen instance textMeasurer`.
`doc/USAGE.md` shows all three levels of use.

### The Vulkan backend (`VectorGraphics-Vulkan`)

The display list is binned into tiles and filled by a SPIR-V kernel compiled through PharoVulkan,
with its own present host and an SDL2 host beside it. `VectorGraphics-Benchmarks` holds the benchmarks that
compare device, software and Cairo on one frame.

## The development cycle

Every new class or method is finished only when five artefacts exist: a failing test first, the
smallest code that passes it, a refactor with the suite green, a class-side `<sampleInstance>`
example in the matching `-Examples` package, and an `<inspectorPresentationOrder:title:>` view with
its `…Context:` gate. Then run the critics on what changed.

- An example is class-side, takes no argument, rebuilds its object on every call, asserts nothing,
  and is named `open…` when it opens a window.
- A view never mutates the inspected object and asks the real predicate rather than restating it,
  so that it cannot drift from the code.
- `VGCairoExamplesTest` holds the five gates over every holder, every example and every view, and
  the Bloc and Vulkan example tests inherit them.
- Fix a bug by writing the failing test first. Never fix first.

## Porting Notes (Cuis → Pharo)

- Cuis uses `ShortPointArray`; Pharo equivalent is `DoubleByteArray` — `Int16PointArray` wraps this.
- The standalone `VectorEngine` of the first port, and the `PreferenceSet` and `DirectoryEntry`
  stubs, are gone: the hierarchy above is the whole engine. `AffineTransformation` is gone too, and
  the transform is this project's own.
- The `exper*` convention of the first port is gone as well. Runnable code is a `<sampleInstance>`
  example in an `-Examples` package, which is what the example gates read.
- `VectorCanvas` inherits from Pharo's `Canvas`, so the Morphic path depends on Pharo's Morphic API.
  The Bloc path does not go through it at all.
- `TrueTypeFont` inherits from Pharo's `AbstractFont`; font-metrics methods must match Pharo's font
  protocol.
- Correctness of the port is now measured against Alexandrie: `VGAlexandrieCorpus` ports the 82
  experiments of the BookletGraphics package and `VGAlexandrieCase` draws each one both ways.
  BookletGraphics is not loaded by this baseline.

## Where the rest is written down

`README.md` holds every package and every group. `doc/USAGE.md` holds the three levels of
use and the corpus. The unit specs and every measurement live in `VECTORCANVAS-PLAN.md` and
`VECTORCANVAS-PRESENT-PLAN.md`, kept in the PharoVulkan working directory beside this checkout.
out.
