"
I am the component map of the font route: the altitude above the classes of
`VectorGraphics-Canvas-Fonts` and `VectorGraphics-Bloc-Text`.

The complaint I answer is that the *Architecture* tab of those packages drew seventeen boxes of
class names, which is legible and says nothing about what the font engine is. I say it in six parts,
in the order a reader meets them: a font file is read (`The face`), a size and a set of options make
a scaled font of it (`The scaled font`), that font rasterises glyphs into a cache (`The glyph cache`)
and answers the geometry a caller asks for before it draws (`The measurements`), and two seats in
Bloc hand the result to a canvas (`The Bloc seat`, `The Cairo route`).

My parts are declared in reading order, which is the order the diagram draws them in. Clicking a box
opens the part, with its own classes and its own diagram. `VGFontArchitectureTest` holds me to the
packages: every class of them is in exactly one part, so a class added to the route cannot be left
out of the picture silently.

`VectorGraphics-TrueType` is not mine yet. Its forty-four classes are the next slice, and the reason
this altitude was built before the rest of the font documentation.

```
VGFontRouteMap new
```
"
Class {
	#name : 'VGFontRouteMap',
	#superclass : 'ArchDocComponentMap',
	#category : 'VectorGraphics-Documentation',
	#package : 'VectorGraphics-Documentation'
}

{ #category : 'declaring' }
VGFontRouteMap class >> components [
	"The font route in six parts, in the order a reader meets them: a font file is read, a size
	 and a set of options make a scaled font of it, that font rasterises glyphs into a cache and
	 answers measurements from them, and two seats in Bloc hand the result to a canvas."

	^ {
		#( 'The face'
			#( #VGFontFace )
			'one font file, read by the TrueType parsers and asked what the font itself says' ) .
		#( 'The scaled font'
			#( #VGScaledFont #VGFontOptions #VGCairoAntialias #VGCairoHintStyle
				#VGCairoHintMetrics #VGCairoSubpixelOrder )
			'one face at one size under one transformation, with the rendering choices Cairo
			 names in cairo_font_options_t' ) .
		#( 'The glyph cache'
			#( #VGGlyphAtlas #VGGlyphMask #VGGlyph )
			'the glyphs of one scaled font, rasterised once and kept' ) .
		#( 'The measurements'
			#( #VGFontExtents #VGTextExtents )
			'what a caller asks before it draws: the vertical geometry of a font and the box of
			 a run of glyphs' ) .
		#( 'The Bloc seat'
			#( #VGFontCanvas #VGFontManager #VGFontManagerHasNoUsableFamily )
			'what Bloc asks for its faces, and the canvas whose fonts are ours' ) .
		#( 'The Cairo route'
			#( #VGAeCanvas #VGAeOffscreen #VGAeRenderer #VGAeTextContext #VGAeTextFont )
			'the route where Cairo still draws every pixel and only the fonts are ours' ) }
]

{ #category : 'declaring' }
VGFontRouteMap class >> packageNames [
	"The two packages of slice one of the font route. VectorGraphics-TrueType joins them when its
	 own parts are written: forty-four classes read as a heap of text at class altitude, which is
	 the complaint this altitude answers."

	^ #( 'VectorGraphics-Canvas-Fonts' 'VectorGraphics-Bloc-Text' )
]
