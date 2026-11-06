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

The default load is the rasteriser and the Cairo replacement alone. Neither names a class of Bloc
or of Alexandrie, so both load in an image that holds neither.

```smalltalk
Metacello new
    baseline: 'VectorGraphics';
    repository: 'github://rvillemeur/VectorGraphics:main/src';
    onConflictUseIncoming;
    load
```

Every layer above that is a group: `bloc` brings the renderer and Bloc itself, `cairo-tests` brings
the conformance corpus without Bloc, `vulkan` brings the device path and needs PharoVulkan loaded
by hand, because it is not published. `README.md` lists every group and `doc/USAGE.md` says
which group each level of use needs. Change a group or an edge in `BaselineOfVectorGraphics` only
together with the test that states it.

## Running Tests

There is no single suite class. Each code package is covered by the test package named after it,
except the rasteriser, whose tests live in the `Tests` tag of `VectorGraphics` itself.

| Where | Test classes |
|---|---|
| `VectorGraphics`, tag `Tests` | 22 classes: `VectorEngineAbstractTest`, `VectorEnginePixelTest`, `VectorEngineWholePixelTest`, `VectorCanvasTest`, the eight `Path…Test`, the nine `TT…`/`TrueType…Test`, `Int16PointArrayTest`, `FontFamilyTest`, `FormGlyphTest` |
| `VectorGraphics-Cairo-Tests` | 21 classes: the `VGCairo…Test` family, `VGPaintTest`, `VGMeshTest`, `VGBlurTest`, `VGRasteriserTest`, and the gates `VGConformanceTest`, `VGAlexandrieCorpusTest`, `VGArchitectureTest`, `VGBackendSelectionTest`, `VGCairoExamplesTest` |
| `VectorGraphics-Bloc-Tests` | `VGCanvasTest`, `VGRendererTest`, `VGFrameProfileTest`, `VGBlocExamplesTest` |
| `VectorGraphics-Vulkan-Tests` | 18 classes: the `VGTiled…Test` family, `VGVulkan…Test`, the two benchmark tests, `VGKernelVisitCensusTest`, `VGBlurRoundingTest`, `VGVulkanExamplesTest` |

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

Ten packages, source layout `src/<PackageName>/` in Tonel format. Iceberg manages commits of
`src/` — do not use git directly for it, and never hand-edit a `.class.st` file.

| Package | Classes | Holds |
|---|---|---|
| `VectorGraphics` | 68 | The rasteriser, under tags `Kernel`, `PathCommands`, `TrueType`, `SVG`, plus its own `Examples` and `Tests` tags |
| `VectorGraphics-Cairo` | 73 | The Cairo replacement: `Surface`, `Context`, `Path`, `Paint`, `Pattern`, `Text`, `Matrix`, `Blur`, `Compositing`, `Display list`, `Rasterising`, `Export`, `Backend`, `Skeleton`, `Inventory`, `Reflection` |
| `VectorGraphics-Bloc` | 8 | `Backend` (`VGCanvas`, `VGRenderer`, `VGOffscreen`), `Hosts`, `Exporters`, `Profiling` |
| `VectorGraphics-Vulkan` | 36 | The device path: `Backend`, `Tiles`, `Kernels`, `Blur`, `Budget`, `Present` |
| `VectorGraphics-Cairo-Examples` | 25 | One `<Subject>Examples` class per subject of the Cairo layer |
| `VectorGraphics-Bloc-Examples` | 3 | The canvas, the renderer and the host examples |
| `VectorGraphics-Vulkan-Examples` | 13 | The device, tile, kernel and benchmark examples |
| `VectorGraphics-Cairo-Tests` | 26 | Tags `Tests`, `Fixtures` and `Conformance`, which holds `VGConformanceTest`, the gate that reads the corpus |
| `VectorGraphics-Bloc-Tests` | 6 | The renderer, canvas and frame profile suites |
| `VectorGraphics-Vulkan-Tests` | 22 | Tags `Tests` and `Fixtures` |
| `VectorGraphics-Conformance` | 7 | The corpus every backend is compared against: the cases, the ported Alexandrie corpus, the `Form` comparison. No `TestCase` |
| `VectorGraphics-Benchmarks` | 3 | The frame harness: the drawing kit, the stage benchmark and the device benchmark. No `TestCase` |

## Which package may name which

This file does not say. `VGArchitectureTest class >> allowedDependencies` does, with one entry per
package, and its 45 tests hold the code, the baseline and the table to each other: a package absent
from the table fails a test, and so does a reference no entry allows. Adding a dependency means
stating it in the table and in `BaselineOfVectorGraphics`, in the commit that needs it.

Four facts of that table are easy to get wrong.

- The engine depends on nothing. The default group — the engine and the Cairo replacement — names
  no class of Bloc or of Alexandrie, and two tests hold that in both directions, by literal and by
  superclass.
- `VectorGraphics-Cairo-Examples` and `VectorGraphics-Cairo-Tests` name each other, because
  `VGArchitectureExamples` has the architecture gate itself for a subject. The baseline states
  one direction only, since a cycle has no load order. It is the one pair left: the conformance
  corpus and the benchmark harness moved into packages of their own in the review of 2026-11,
  which ended the second cycle.
- The Cairo tests do name Alexandrie, on purpose: proving this rasteriser matches live Cairo byte
  for byte needs that positive control. No other package may.
- Only the Vulkan family may name a PharoVulkan class. That rule lives in
  `VGBackendSelectionTest`, through `VGCairoReferenceScanner`, not in `allowedDependencies`.

## Architecture

### The rasteriser (`VectorGraphics`)

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

### The Cairo replacement (`VectorGraphics-Cairo`)

`VGCairoImageSurface` and `VGCairoContext` answer the selectors of `AeCairoImageSurface` and
`AeCairoContext`. A surface owns a `VGDisplayList` and every context drawing on it records
there, so that two contexts on one surface draw in the order their calls were made. A backend
drains the list through `drainInto:`: `VGSoftwareBackend` rasterises it with the engine above,
`VGVulkanBackend` fills it on the device. `VGCairoReferenceScanner`, in the `Reflection` tag,
is how the architecture tests read what a package really names.

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

`README.md` holds the packages and the thirteen groups. `doc/USAGE.md` holds the three levels of
use and the corpus. The unit specs and every measurement live in `VECTORCANVAS-PLAN.md` and
`VECTORCANVAS-PRESENT-PLAN.md`, kept in the PharoVulkan working directory beside this checkout.
