"
I hold the runnable examples of shaping a run of text with HarfBuzz from a catalogue entry of this project, with no FreeType anywhere in the route.

Each one rebuilds its catalogue and its buffer, so clicking an example twice shows the same thing twice. None of them touches the font manager Bloc asks for its faces: shaping needs the bytes of one font, not an index of the whole machine.

The route is `TTFontCatalogueEntry >> newHbFontScaledTo:`, then upstream's own `AeHbBuffer >> shapeWithFont:` and `cairoGlyphArray`. Upstream's shortcut `cairoGlyphArrayForFace:size:` is the other route, and it needs an `AeFTFace`.
"
Class {
	#name : 'VGHarfbuzzShapingExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Bloc-Examples',
	#package : 'VectorGraphics-Bloc-Examples'
}

{ #category : 'examples' }
VGHarfbuzzShapingExamples class >> glyphArrayShapedWithoutFreeType [

	<sampleInstance>
	"The word 'Pharo' shaped at 22 pixels through a font this project carries in memory.
	 Inspect the answer: an AeCairoGlyphArray, one element a glyph, each holding the identifier
	 its face knows the glyph by and the place HarfBuzz put it. No AeFTFace is built on the way —
	 the FreeType route is AeHbBuffer >> cairoGlyphArrayForFace:size:, which sets a size on such
	 a face and calls hb_ft_font_create_referenced."

	| entry buffer |
	entry := TTFontCatalogue new addBytes:
		         AeSourceSansPro_Regular fontContentsData.
	buffer := AeHbBuffer new
		          direction: AeHbDirection leftToRight;
		          script: AeHbScript latin;
		          language: AeHbLanguage en;
		          addString: 'Pharo';
		          yourself.
	buffer shapeWithFont: (entry newHbFontScaledTo: 22).
	^ buffer cairoGlyphArray
]
