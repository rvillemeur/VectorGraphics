Port of Cuis vector canvas to Pharo smalltalk

```smalltalk
Metacello new
	baseline: 'VectorGraphics';
	repository: 'github://rvillemeur/VectorGraphics:main/src';
	onConflictUseIncoming;
	load
```

## Packages and groups

| Package | What it holds |
|---|---|
| `VectorGraphics` | The software rasteriser: paths, spans, paint, clips, text |
| `VectorGraphics-Cairo` | The replacement for the Cairo layer, same calling API as `Alexandrie-Cairo` |
| `VectorGraphics-Bloc` | `VGCanvas` and `VGRenderer`, the Bloc backend, plus the pixel buffer host |
| `VectorGraphics-Cairo-Examples`, `VectorGraphics-Bloc-Examples` | One `<sampleInstance>` example per subject |
| `VectorGraphics-Cairo-Tests`, `VectorGraphics-Bloc-Tests` | The suites, including the conformance gate against Alexandrie |

The groups are `core`, `cairo`, `bloc`, `examples`, `tests`, and `default`, which loads the three
code layers.

## Drawing Bloc through this project

```smalltalk
BlHostRenderer preferableClass: VGRenderer.
```

Every space opened afterwards draws through the software rasteriser instead of Cairo.
`VGRenderer` is a drop-in for `BARenderer`, so the elements, the effects and the text of an existing
Bloc application need no change.

## Using the layer directly

`doc/USAGE.md` shows the three levels of the replacement, a surface and a context, an `AeCanvas` of
our own, and the whole of Bloc, and how to run the 82 Alexandrie experiments through it.
