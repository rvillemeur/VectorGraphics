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
| `VectorGraphics-Vulkan` | The GPU backend: device session, tiled fill, the present host and its SDL2 host |
| `VectorGraphics-Engine-Examples`, `VectorGraphics-Paths-Examples`, `VectorGraphics-TrueType-Examples`, `VectorGraphics-Text-Examples` | One `<sampleInstance>` example per subject of the rasteriser |
| `VectorGraphics-Cairo-Examples`, `VectorGraphics-Bloc-Examples`, `VectorGraphics-Vulkan-Examples` | One `<sampleInstance>` example per subject of the layers above it |
| `VectorGraphics-Tests` | `VectorGraphicsDocumentationTest`, the abstract documentation gate the four suites below subclass |
| `VectorGraphics-Engine-Tests`, `VectorGraphics-Paths-Tests`, `VectorGraphics-TrueType-Tests`, `VectorGraphics-Text-Tests` | The suites of the rasteriser, each with the documentation gate of its own package |
| `VectorGraphics-Cairo-Tests`, `VectorGraphics-Bloc-Tests`, `VectorGraphics-Vulkan-Tests` | The suites of the layers above, including the conformance gate against Alexandrie |

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
| `vulkan` | `core` and `VectorGraphics-Vulkan`. PharoVulkan is not published, so load it before asking for this group |
| `vulkan-examples`, `vulkan-tests` | the examples and the suites of the GPU backend |
| `examples`, `tests` | the union of the seven layer groups, so they reach Bloc and PharoVulkan |
| `dev` | the group to work on this project from: `default`, the suites of its five layers, and MuTalk from `github://pharo-contributions/mutalk:v3.0.8/src`. It names the five test groups one by one, so it still loads in a plain Pharo image |

The Cairo examples and suites load without Bloc:

```smalltalk
Metacello new
	baseline: 'VectorGraphics';
	repository: 'github://rvillemeur/VectorGraphics:main/src';
	load: 'cairo-tests'.
```

`cairo-tests` requires `cairo-examples`, which requires `cairo`, which requires the font reader and
the path commands, so that one name brings five packages in — and neither the scan-line engine nor
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

## Using the layer directly

`doc/USAGE.md` shows the three levels of the replacement, a surface and a context, an `AeCanvas` of
our own, and the whole of Bloc, and how to run the 82 Alexandrie experiments through it.