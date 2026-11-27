Port of Cuis vector canvas to Pharo smalltalk

```smalltalk
Metacello new
	baseline: 'VectorGraphics';
	repository: 'github://rvillemeur/VectorGraphics:main/src';
	onConflictUseIncoming;
	load
```

That loads the `default` group: the software rasteriser and the canvas that replaces Cairo, and nothing
else. Neither names a class of Bloc or of Alexandrie, so the project loads in an image where
neither is present. Every layer above them is a group of its own.

## Packages

| Package | What it holds |
|---|---|
| `VectorGraphics` | The front page of the project in the browser: a package comment and the Renraku rule configuration, no code |
| `VectorGraphics-Engine` | The software rasteriser: paths, spans, paint, clips |
| `VectorGraphics-Paths` | The SVG path commands, and the parser that reads a `d` attribute into them |
| `VectorGraphics-TrueType` | Reading a `.ttf`, and the glyphs, metrics and font classes it yields |
| `VectorGraphics-Text` | The glue that draws a string: extension methods over the engine and the font reader |
| `VectorGraphics-Canvas` | The canvas that replaces the Cairo layer, same calling API as `Alexandrie-Cairo`: the surface, the context and the display list every call is recorded in |
| `VectorGraphics-Canvas-Raster` | The software renderer of that canvas: the backend, the rasteriser, the spans, the clip, the stroker and the blur |
| `VectorGraphics-Canvas-Fonts` | The scaled fonts of that canvas: a face at a size, its glyph atlas and the extents text is measured by |
| `VectorGraphics-Canvas-Geometry` | The geometry both routes measure and map with: a path, its subpaths, the builder that records one, and the matrix a point is mapped by. It names nothing else of this project |
| `VectorGraphics-Reflection` | `VGCairoReferenceScanner`: which classes of another project a package of this one names, read from the compiled methods |
| `VectorGraphics-Bloc` | `VGCanvas` and `VGRenderer`, the Bloc backend, plus the pixel buffer host |
| `VectorGraphics-Bloc-Text` | The cairo text route, which both canvases of this project share: `VGFontCanvas`, the `AeCanvas` and renderer of our own that draw through Cairo, our font manager, and the extension methods on Alexandrie's classes they need |
| `VectorGraphics-Bloc-FontEngine` | `VGFontEngine` alone: one send that makes Bloc draw text with the fonts of this project, and one that gives the image back. The route itself is the package above, so loading that route poses nothing |
| `VectorGraphics-Vulkan` | The GPU backend: device session, tiled fill, the present host and its SDL2 host |
| `VectorGraphics-Conformance` | The corpus every backend is compared against: the cases, the ported Alexandrie corpus, the `Form` comparison |
| `VectorGraphics-Benchmarks` | The frame harness: the drawing kit, the stage benchmark and the device benchmark |
| `VectorGraphics-Documentation` | The architecture of this project drawn from the code: the inspector tabs installed on Pharo's `Package`, the object graph of a live font or font manager, and `VGFontRouteMap`, the six parts of the font route |
| `VectorGraphics-Engine-Examples`, `VectorGraphics-Paths-Examples`, `VectorGraphics-TrueType-Examples`, `VectorGraphics-Text-Examples` | One `<sampleInstance>` example per subject of the rasteriser |
| `VectorGraphics-Canvas-Examples`, `VectorGraphics-Canvas-Raster-Examples`, `VectorGraphics-Canvas-Fonts-Examples`, `VectorGraphics-Canvas-Geometry-Examples`, `VectorGraphics-Reflection-Examples`, `VectorGraphics-Bloc-Examples`, `VectorGraphics-Bloc-Text-Examples`, `VectorGraphics-Bloc-FontEngine-Examples`, `VectorGraphics-Vulkan-Examples` | One `<sampleInstance>` example per subject of the layers above it |
| `VectorGraphics-Tests` | `VectorGraphicsDocumentationTest`, the abstract documentation gate the four suites below subclass |
| `VectorGraphics-Engine-Tests`, `VectorGraphics-Paths-Tests`, `VectorGraphics-TrueType-Tests`, `VectorGraphics-Text-Tests` | The suites of the rasteriser, each with the documentation gate of its own package |
| `VectorGraphics-Canvas-Tests`, `VectorGraphics-Canvas-Raster-Tests`, `VectorGraphics-Canvas-Fonts-Tests`, `VectorGraphics-Canvas-Geometry-Tests`, `VectorGraphics-Bloc-Tests`, `VectorGraphics-Bloc-Text-Tests`, `VectorGraphics-Bloc-FontEngine-Tests`, `VectorGraphics-Vulkan-Tests` | The suites of the layers above, including the conformance gate against Alexandrie |

## Groups

| Group | Loads |
|---|---|
| `default` | `core`, `canvas`, `canvas-raster`, `canvas-fonts` and `canvas-geometry` — the whole rasteriser and the whole canvas, no Bloc |
| `core` | the front page and the four packages of the rasteriser: `paths`, `engine`, `truetype`, `text` |
| `paths` | the SVG path commands and their parser, alone |
| `engine` | the scan-line rasteriser, with no font code |
| `truetype` | the `.ttf` reader, with no rasteriser: it brings `paths` and nothing else |
| `text` | the glue that draws a string, so it brings `engine` and `truetype` |
| `paths-examples`, `engine-examples`, `truetype-examples`, `text-examples` | the examples of one package of the rasteriser |
| `paths-tests`, `engine-tests`, `truetype-tests`, `text-tests` | the suite of one package of the rasteriser, each bringing `VectorGraphics-Tests` for the documentation gate |
| `canvas` | the canvas API and the display list. It names the renderer and the font layer, so this brings all three, and the font layer brings `truetype` and `paths` below it, not the whole of `core` |
| `canvas-raster` | the software renderer alone: no font code, and nothing of the canvas API below it |
| `canvas-fonts` | the scaled fonts alone, with no renderer. It names the `.ttf` reader, so it brings `truetype` and `paths` |
| `canvas-geometry` | a path, its subpaths, the builder that records one and the matrix a point is mapped by, alone. It names nothing of this project, so nothing else comes with it |
| `canvas-examples`, `canvas-raster-examples`, `canvas-fonts-examples`, `canvas-geometry-examples` | the examples of one package of the canvas |
| `canvas-tests`, `canvas-raster-tests`, `canvas-fonts-tests`, `canvas-geometry-tests` | the suite of one package of the canvas, still without Bloc |
| `bloc` | `core`, `VectorGraphics-Bloc`, and Bloc itself from `github://pharo-graphics/Bloc:master` |
| `bloc-examples`, `bloc-tests` | the examples and the suites of the Bloc backend |
| `bloc-text` | the cairo text route alone, six packages: `VectorGraphics-Bloc-Text`, the font layer, the geometry, the reference scan and the `.ttf` reader and the path commands below them, with Bloc itself. `VectorGraphics-Canvas` and its rasteriser stay out |
| `bloc-text-examples`, `bloc-text-tests` | the examples and the suite of that route |
| `fonts` | `bloc-text` and the engine that poses it, seven packages: the six of that route and `VectorGraphics-Bloc-FontEngine`, which carries a `postLoadDoIt:`, so the load poses the route itself and leaves nothing to evaluate. `VectorGraphics-Canvas` and its rasteriser stay out of this group too |
| `fonts-examples`, `fonts-tests` | the example and the suite of the font engine |
| `documentation` | the package that draws this project's architecture from the declarations its classes carry, with ArchDoc and Roassal. It installs the inspector tabs on every package of the project, and it names `VGFontManager`, so it brings `bloc-text` and Bloc with it |
| `documentation-examples`, `documentation-tests` | the examples that open each picture with one click, and the gate that holds them to the code |
| `vulkan` | `core`, `VectorGraphics-Vulkan` and PharoVulkan from `github://rvillemeur/PharoVulkan:main/src`, whose `default` group the three Vulkan packages require. The machine needs `libvulkan.so.1` and a driver; nothing else of this project does |
| `vulkan-examples`, `vulkan-tests` | the examples and the suites of the GPU backend |
| `conformance` | the corpus alone. It names the canvas and no test package, so a comparison can be drawn with no suite loaded |
| `benchmarks` | the frame harness, which names the corpus it draws and the three backends it measures |
| `reflection` | the reference scan alone. It is in no group above it: every package that reads it requires it, so it arrives with whichever of them is asked for |
| `reflection-examples` | the examples of that scan |
| `examples`, `tests` | the union of the layer groups: thirteen for the examples, the twelve layers and the reference scan, twelve for the suites. Both reach Bloc and PharoVulkan |
| `dev` | the group to work on this project from: `default`, the suites of its eight layers, and MuTalk from `github://pharo-contributions/mutalk:v3.0.8/src`. It names the eight test groups one by one, so it still loads in a plain Pharo image |

The canvas examples and suites load without Bloc:

```smalltalk
Metacello new
	baseline: 'VectorGraphics';
	repository: 'github://rvillemeur/VectorGraphics:main/src';
	load: 'canvas-tests'.
```

`canvas-tests` brings fifteen packages in: the four of the canvas, the four of their examples, the
suite of the renderer beside the suite asked for, `VectorGraphics-Conformance`, the corpus the gate
reads, the reference scan and its examples, and the `.ttf` reader and the path commands below the
font layer. Neither the scan-line
engine nor the text glue arrives, because no package of the canvas names either. The suites do name
Alexandrie's Cairo bindings, on purpose: the conformance gate proves this rasteriser matches live
Cairo byte for byte, and a comparison needs that positive control.

`VGArchitectureTest` holds every sentence above — which package may name which, what each group
loads, and that no package the canvas groups load names or inherits from a Bloc class. Its
class-side `Groups` tab shows the three columns live.

## Working on this project

```smalltalk
Metacello new
	baseline: 'VectorGraphics';
	repository: 'github://rvillemeur/VectorGraphics:main/src';
	load: 'dev'.
```

That brings the default stack, the suite of each of its layers, and MuTalk, the mutation tester.
MuTalk rewrites a production method and asks whether a test notices, so it needs the tests of the
code under test in the image — which is why `dev` is not simply `default` plus MuTalk. It is pinned
to a tag rather than to `master`: the version doing the rewriting is part of this project's setup.

Mutate the classes of the task in hand, not a whole package: a package-wide run takes orders of
magnitude longer and says nothing about the work. Commit first, because a run that is interrupted
leaves its rewrites in the image, and only a clean checkout tells them from your own edits.

## Drawing Bloc through this project

```smalltalk
Metacello new
	baseline: 'VectorGraphics';
	repository: 'github://rvillemeur/VectorGraphics:main/src';
	load: 'bloc'.

BlHostRenderer preferableClass: VGRenderer.
```

Every space opened afterwards draws through the software rasteriser instead of Cairo.
`VGRenderer` is a drop-in for `BARenderer`, so the elements, the effects and the text of an existing
Bloc application need no change.

## Replacing Bloc's font engine

```smalltalk
Metacello new
	baseline: 'VectorGraphics';
	repository: 'github://rvillemeur/VectorGraphics:main/src';
	load: 'fonts'.
```

That is the whole of it. When the load returns, every space of the image draws its text with the
fonts this project reads, and no FreeType face is built anywhere in the route. There is no step
left to the reader: `VectorGraphics-Bloc-FontEngine` carries a `postLoadDoIt:` that sends
`VGFontEngine install` once the package is in.

The group loads that route and nothing else, seven packages: the `.ttf` reader and the path
commands below it, the font layer of the canvas, the geometry both routes map with, the reference
scan, `VectorGraphics-Bloc-Text` — the cairo text route itself — and the engine package.
`VectorGraphics-Canvas` stays out, and so do its renderer and its display list: Cairo rasterises
every figure on this route, so none of them is on it. Bloc arrives too, because the route extends
Alexandrie's classes.

Two slots of the image decide where a glyph comes from, and `install` writes both:

- `AeFontManager globalInstance` becomes a `VGFontManager`, which reads a `.ttf` of this machine
  in Pharo and holds no FreeType library. It also registers the families it found with
  `FontFamily`, and poses one of them as the image default.
- `BlHostRenderer preferableClass` becomes `VGAeRenderer`. The renderer has to change with the
  manager: Cairo still rasterises every figure of a frame on this route, and only that renderer's
  canvas answers a scaled font of ours. Under Alexandrie's own renderer a font of ours would die
  marshalling a `cairo_scaled_font_t`.

To go back, in the same image:

```smalltalk
VGFontEngine uninstall.
```

That writes back the renderer and the manager that were in place when the route was posed, rather
than a route named in the code, so an image that was already drawing through something else finds
it again. `VGFontEngine isInstalled` answers from those two slots, never from a flag of its own,
and the class-side `Route` tab of its inspector shows both halves with what each was before.

In an image that already holds this project, the three lines the group runs for you are:

```smalltalk
VGFontManager installGlobally.
BlHostRenderer preferableClass: VGAeRenderer.
VGAeOffscreen resetInstance.
```

The faces come from this machine, not from the image: a machine holding none of the families
`VGFontManager class >> preferredTextFamilyNames` lists raises `VGFontManagerHasNoUsableFamily`,
and the load of `fonts` fails. That is deliberate. An image that cannot draw with these fonts must
say so, rather than keep FreeType and look as though it had switched.

To draw with the software rasteriser instead of Cairo, and keep FreeType for the glyphs, load
`bloc` and pose `VGRenderer` as the section above shows. The two are separate choices: `fonts`
changes where a glyph comes from, `bloc` changes what rasterises it.

## Reading the font route

The route is documented from the code itself, not from a file that drifts from it. Each class of it
declares what it holds as a pragma on its accessor, each manifest declares where a reader starts,
and the pictures a reader opens are drawn from those declarations:

```smalltalk
Metacello new
	baseline: 'VectorGraphics';
	repository: 'github://rvillemeur/VectorGraphics:main/src';
	load: 'documentation'.
```

That group brings `VectorGraphics-Documentation`, ArchDoc and Roassal, and adds four tabs to the
inspector of every package of this project:

- *Neighbours* — the whole project with this package filled apart from the rest, a forbidden arrow
  drawn in red.
- *Components* — the six parts of the font route rather than its classes, `The face`,
  `The scaled font`, `The glyph cache`, `The measurements`, `The Bloc seat` and `The Cairo route`,
  each opening on its own diagram. `VGFontRouteMap` declares them.
- *Architecture* — the classes of the package and what each holds, read from the pragmas.
- *Where to start* — the classes in reading order, with the ones the package's manifest declares as
  entry points at the head of the list and marked as declared.

`ManifestVectorGraphicsCanvasFonts class >> archDocEntryPoints` is one such declaration: a manifest
of the route answers the three or four classes to read first, in the order to read them, and
`VGFontArchitectureTest` holds every manifest of the route to it — no package of the route may be
silent, and no name declared may be absent from the package declaring it.

A fifth tab, *Object graph*, is installed on `VGScaledFont` and on `VGFontManager`. It walks a live
font or a live manager and shows what it holds at this moment, which is not what the declarations
say it may hold: a manager nobody has drawn with keeps no face at all.

Sections 8 to 10 of `doc/ARCHITECTURE.md` describe the chain from a character to a glyph in prose,
and `VGDocumentationExamples` opens each of these pictures with one click from the browser.

## Using the layer directly

`doc/USAGE.md` shows the three levels of the replacement, a surface and a context, an `AeCanvas` of
our own, and the whole of Bloc, and how to run the 82 Alexandrie experiments through it.