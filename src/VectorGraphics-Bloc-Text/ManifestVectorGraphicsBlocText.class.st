"
The fonts of this project posed under Cairo: Cairo rasterises every pixel and the text is read,
measured and drawn from our own font files. It is the half-way route of the font plan — the one
a user wants when the drawing is to stay as it is and only FreeType is to go.

`VGFontManager` is the registry Bloc asks for a face, and it holds no FreeType library: it
answers from `TTFontCatalogue`, which judges a font file by its content and reads a few hundred
bytes of it. `VGFontCanvas` is the abstract canvas whose scaled fonts are ours, with `VGAeCanvas`
under it for this route and `VGCanvas` for the all-ours one. `VGAeTextContext` is an
`AeCairoContext` that asks the posed font for a text adapter instead of marshalling a
`cairo_scaled_font_t` it has not got, and `VGAeTextFont` is that adapter: it answers Alexandrie's
five text verbs from our masks and outlines, and keeps the A8 masks Cairo rasterised for the
glyphs drawn through it.

Three ways in:

- `VGFontManager class >> installGlobally` poses our registry where `AeFontManager globalInstance`
  reads it, and puts it back at every image start.
- `BlHostRenderer preferableClass: VGAeRenderer` is the whole installation of the route: the
  renderer builds a `VGAeCanvas` for a frame and measures text through `VGAeOffscreen`.
- `VGAeTextFont` is where a reader sees what replaces FreeType, verb by verb.

Tags:

- `Manifest` — this comment, the entry points the architecture tools read, and the Renraku rule
  configuration.

`VectorGraphics-Bloc-FontEngine` is the one send that installs all of this at once;
`FONT-PLAN.md`, kept in the PharoVulkan working directory beside this checkout, holds the
measurements that chose this route over the FreeType one, and
`doc/ARCHITECTURE.md` sections 8 to 10 hold the chain from a character to a glyph.


"
Class {
	#name : 'ManifestVectorGraphicsBlocText',
	#superclass : 'PackageManifest',
	#category : 'VectorGraphics-Bloc-Text-Manifest',
	#package : 'VectorGraphics-Bloc-Text',
	#tag : 'Manifest'
}

{ #category : 'architecture' }
ManifestVectorGraphicsBlocText class >> archDocEntryPoints [
	"Where a reader of this package starts, in the order to read them, which is the prose of my
	 comment said in a form a tool can read. The manager is what Bloc asks for a face, the text
	 font is what replaces FreeType verb by verb, the context is what sends it those verbs, and
	 the canvas is where a face becomes a scaled font of ours."

	^ #( #VGFontManager #VGAeTextFont #VGAeTextContext #VGFontCanvas )
]
