"
The package the code packages were split out of. Nothing is left in it but this comment and the
Renraku rule configuration: it is the front page of the project in the browser, and the name the
baseline and the repository are called by.

The rasteriser, four packages:

- `VectorGraphics-Engine` — the scan-line canvas and the engines, the rasteriser itself.
- `VectorGraphics-Paths` — the SVG path commands and the parser that reads them.
- `VectorGraphics-TrueType` — reading a `.ttf`, and the glyphs and fonts it yields.
- `VectorGraphics-Text` — the glue that draws a string with the engine.

The canvas that replaces the Cairo layer, three packages since the split of November 2026:

- `VectorGraphics-Canvas` — the canvas API and the display list every call is recorded in.
- `VectorGraphics-Canvas-Raster` — the software renderer that turns that list into pixels.
- `VectorGraphics-Canvas-Fonts` — the scaled fonts and glyph atlases the canvas measures with.

And the layers above:

- `VectorGraphics-Bloc` — the Bloc backend, `VGCanvas` and `VGRenderer`.
- `VectorGraphics-Bloc-FontEngine` — the one send that makes Bloc draw text with these fonts.
- `VectorGraphics-Vulkan` — the device path: tiles, kernels and the present host.
- `VectorGraphics-Conformance` — the corpus every backend is compared against.
- `VectorGraphics-Benchmarks` — the frame harness that measures the three of them.

Each code package has a sibling `-Examples` package of one-click examples and a sibling `-Tests`
package of suites. `VectorGraphics-Tests` holds the abstract documentation gate the rasteriser
suites subclass.

Tags:

- `Manifest` — this comment and the Renraku rule configuration.

`README.md` lists every package and group of the project, `doc/ARCHITECTURE.md` describes what
spans them, and `doc/USAGE.md` shows the layers above.
"
Class {
	#name : 'ManifestVectorGraphics',
	#superclass : 'PackageManifest',
	#category : 'VectorGraphics-Manifest',
	#package : 'VectorGraphics',
	#tag : 'Manifest'
}
