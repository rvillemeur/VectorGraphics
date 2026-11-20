Port of Cuis vector canvas to Pharo smalltalk

```smalltalk
Metacello new
	baseline: 'VectorGraphics';
	repository: 'github://rvillemeur/VectorGraphics:main/src';
	onConflictUseIncoming;
	load
```

That loads the `default` group: the software rasteriser and the Cairo replacement, and nothing
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
| `VectorGraphics-Cairo` | The replacement for the Cairo layer, same calling API as `Alexandrie-Cairo` |
| `VectorGraphics-Bloc` | `VGCanvas` and `VGRenderer`, the Bloc backend, plus the pixel buffer host |
| `VectorGraphics-Bloc-FontEngine` | `VGFontEngine`: one send that makes Bloc draw text with the fonts of this project, and one that gives the image back |
| `VectorGraphics-Vulkan` | The GPU backend: device session, tiled fill, the present host and its SDL2 host |
| `VectorGraphics-Conformance` | The corpus every backend is compared against: the cases, the ported Alexandrie corpus, the `Form` comparison |
| `VectorGraphics-Benchmarks` | The frame harness: the drawing kit, the stage benchmark and the device benchmark |
| `VectorGraphics-Engine-Examples`, `VectorGraphics-Paths-Examples`, `VectorGraphics-TrueType-Examples`, `VectorGraphics-Text-Examples` | One `<sampleInstance>` example per subject of the rasteriser |
| `VectorGraphics-Cairo-Examples`, `VectorGraphics-Bloc-Examples`, `VectorGraphics-Bloc-FontEngine-Examples`, `VectorGraphics-Vulkan-Examples` | One `<sampleInstance>` example per subject of the layers above it |
| `VectorGraphics-Tests` | `VectorGraphicsDocumentationTest`, the abstract documentation gate the four suites below subclass |
| `VectorGraphics-Engine-Tests`, `VectorGraphics-Paths-Tests`, `VectorGraphics-TrueType-Tests`, `VectorGraphics-Text-Tests` | The suites of the rasteriser, each with the documentation gate of its own package |
| `VectorGraphics-Cairo-Tests`, `VectorGraphics-Bloc-Tests`, `VectorGraphics-Bloc-FontEngine-Tests`, `VectorGraphics-Vulkan-Tests` | The suites of the layers above, including the conformance gate against Alexandrie |

## Groups

| Group | Loads |
|---|---|
| `default` | `core` and `cairo` — the whole rasteriser and the Cairo replacement, no Bloc |
| `core` | the front page and the four packages of the rasteriser: `paths`, `engine`, `truetype`, `text` |
| `paths` | the SVG path commands and their parser, alone |
| `engine` | the scan-line rasteriser, with no font code |
| `truetype` | the `.ttf` reader, with no rasteriser: it brings `paths` and nothing else |
| `text` | the glue that draws a string, so it brings `engine` and `truetype` |
| `paths-examples`, `engine-examples`, `truetype-examples`, `text-examples` | the examples of one package of the rasteriser |
| `paths-tests`, `engine-tests`, `truetype-tests`, `text-tests` | the suite of one package of the rasteriser, each bringing `VectorGraphics-Tests` for the documentation gate |
| `cairo` | the Cairo replacement. It names the font reader alone, so this brings `paths` and `truetype`, not the whole of `core` |
| `cairo-examples`, `cairo-tests` | the examples and the suites of that layer, still without Bloc |
| `bloc` | `core`, `VectorGraphics-Bloc`, and Bloc itself from `github://pharo-graphics/Bloc:master` |
| `bloc-examples`, `bloc-tests` | the examples and the suites of the Bloc backend |
| `fonts` | the font engine, and the route it poses: the `.ttf` reader, the Cairo replacement, the Bloc backend and `VGFontEngine`. The package carries a `postLoadDoIt:`, so the load poses the route itself and leaves nothing to evaluate |
| `fonts-examples`, `fonts-tests` | the example and the suite of the font engine |
| `vulkan` | `core` and `VectorGraphics-Vulkan`. PharoVulkan is not published, so load it before asking for this group |
| `vulkan-examples`, `vulkan-tests` | the examples and the suites of the GPU backend |
| `conformance` | the corpus alone. It names `cairo` and no test package, so a comparison can be drawn with no suite loaded |
| `benchmarks` | the frame harness, which names the corpus it draws and the three backends it measures |
| `examples`, `tests` | the union of the eight layer groups, so they reach Bloc and PharoVulkan |
| `dev` | the group to work on this project from: `default`, the suites of its five layers, and MuTalk from `github://pharo-contributions/mutalk:v3.0.8/src`. It names the five test groups one by one, so it still loads in a plain Pharo image |

The Cairo examples and suites load without Bloc:

```smalltalk
Metacello new
	baseline: 'VectorGraphics';
	repository: 'github://rvillemeur/VectorGraphics:main/src';
	load: 'cairo-tests'.
```

`cairo-tests` requires `cairo-examples`, which requires `cairo`, which requires the font reader and
the path commands, so that one name brings six packages in — the sixth is
`VectorGraphics-Conformance`, the corpus the gate reads — and neither the scan-line engine nor
the text glue, which the Cairo layer does not name. They do name Alexandrie's Cairo bindings, on
purpose:
the conformance gate proves this rasteriser matches live Cairo byte for byte, and a comparison
needs that positive control.

`VGArchitectureTest` holds every sentence above — which package may name which, what each group
loads, and that no package the Cairo groups load names or inherits from a Bloc class. Its
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

## Using the layer directly

`doc/USAGE.md` shows the three levels of the replacement, a surface and a context, an `AeCanvas` of
our own, and the whole of Bloc, and how to run the 82 Alexandrie experiments through it.