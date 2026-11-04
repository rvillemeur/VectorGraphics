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
| `VectorGraphics` | The software rasteriser: paths, spans, paint, clips, text |
| `VectorGraphics-Cairo` | The replacement for the Cairo layer, same calling API as `Alexandrie-Cairo` |
| `VectorGraphics-Bloc` | `VGCanvas` and `VGRenderer`, the Bloc backend, plus the pixel buffer host |
| `VectorGraphics-Vulkan` | The GPU backend: device session, tiled fill, the present host and its SDL2 host |
| `VectorGraphics-Cairo-Examples`, `VectorGraphics-Bloc-Examples`, `VectorGraphics-Vulkan-Examples` | One `<sampleInstance>` example per subject |
| `VectorGraphics-Cairo-Tests`, `VectorGraphics-Bloc-Tests`, `VectorGraphics-Vulkan-Tests` | The suites, including the conformance gate against Alexandrie |

## Groups

| Group | Loads |
|---|---|
| `default` | `core` and `cairo` — the rasteriser and the Cairo replacement, no Bloc |
| `core` | `VectorGraphics` alone |
| `cairo` | the Cairo replacement |
| `cairo-examples`, `cairo-tests` | the examples and the suites of that layer, still without Bloc |
| `bloc` | `VectorGraphics-Bloc`, and Bloc itself from `github://pharo-graphics/Bloc:master` |
| `bloc-examples`, `bloc-tests` | the examples and the suites of the Bloc backend |
| `vulkan` | `VectorGraphics-Vulkan`. PharoVulkan is not published, so load it before asking for this group |
| `vulkan-examples`, `vulkan-tests` | the examples and the suites of the GPU backend |
| `examples`, `tests` | the union of the three layer groups, so they reach Bloc and PharoVulkan |

The Cairo examples and suites load without Bloc:

```smalltalk
Metacello new
	baseline: 'VectorGraphics';
	repository: 'github://rvillemeur/VectorGraphics:main/src';
	load: 'cairo-tests'.
```

`cairo-tests` requires `cairo-examples`, which requires `cairo`, which requires the rasteriser, so
that one name brings all four packages in. They do name Alexandrie's Cairo bindings, on purpose:
the conformance gate proves this rasteriser matches live Cairo byte for byte, and a comparison
needs that positive control.

`VGArchitectureTest` holds every sentence above — which package may name which, what each group
loads, and that no package the Cairo groups load names or inherits from a Bloc class. Its
class-side `Groups` tab shows the three columns live.

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
