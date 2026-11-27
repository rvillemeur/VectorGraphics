"
The scaled-font layer: one face at one size under one transformation, the glyphs it yields and the
extents the canvas measures with. It is the leaf of the three canvas packages — it names
`VectorGraphics-TrueType` and nothing else of this project, which is why a font engine that
depends on it depends on glyphs and not on a renderer.

`VGFontFace` is a `.ttf` read into the image, `VGScaledFont` that face at a size, and
`VGGlyphAtlas` the masks already rendered for it, kept per glyph, phase and matrix so that a
second draw of the same character rasterises nothing. `VGFontOptions` carries the four
enumerations beside it: antialias, hint style, hint metrics and subpixel order.

Two ways in:

- `VGFontFace class >> newForFile:` answers a face, and `default` the one of this machine.
- `VGScaledFont class >> fontFace:fontMatrix:userToDeviceMatrix:options:` answers the scaled font
  a context measures and draws with.

Tags:

- `Text` — every class of the layer: the face, the scaled font, the glyph, the atlas, the mask,
  the font and text extents, the options, and the four enumerations the options carry.
- `Manifest` — this comment and the Renraku rule configuration.

The canvas names this package from `VGCairoContext` alone, through `defaultScaledFont`,
`fontSize:`, `glyphsOf:size:` and `renderedGlyphMaskFor:atPhase:`. `CANVAS-SPLIT-PLAN.md` holds
the split that made the three, and `VectorGraphics-Canvas-Fonts-Examples` holds a runnable example
per subject.
"
Class {
	#name : 'ManifestVectorGraphicsCanvasFonts',
	#superclass : 'PackageManifest',
	#category : 'VectorGraphics-Canvas-Fonts-Manifest',
	#package : 'VectorGraphics-Canvas-Fonts',
	#tag : 'Manifest'
}

{ #category : 'architecture' }
ManifestVectorGraphicsCanvasFonts class >> archDocEntryPoints [
	"Where a reader of this package starts, in the order to read them, which is the prose of my
	 comment said in a form a tool can read. The face is a font file in the image, the scaled
	 font is that face at a size under a matrix, and the atlas is what keeps a glyph from being
	 rasterised twice."

	^ #( #VGFontFace #VGScaledFont #VGGlyphAtlas )
]
