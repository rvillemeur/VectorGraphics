"
The package the four code packages were split out of. Nothing is left in it but this comment and
the Renraku rule configuration: it is the front page of the project in the browser, and the name
the baseline and the repository are called by.

The four code packages, and what each holds:

- `VectorGraphics-Engine` — the canvas and the engines, the rasteriser itself.
- `VectorGraphics-Paths` — the SVG path commands and the parser that reads them.
- `VectorGraphics-TrueType` — reading a `.ttf`, and the glyphs and fonts it yields.
- `VectorGraphics-Text` — the glue that draws a string with the engine.

Each has a sibling `-Examples` package of one-click examples and a sibling `-Tests` package of
suites. `VectorGraphics-Tests` holds the abstract documentation gate those four suites subclass.

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
