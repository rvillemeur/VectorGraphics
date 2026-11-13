Extension { #name : 'AeCairoScaledFont' }

{ #category : '*VectorGraphics-Bloc' }
AeCairoScaledFont >> appendPathOfGlyphs: aGlyphsArray length: aNumberOfGlyphs onAeContext: aContext [
	"Straight back to cairo_glyph_path."

	^ aContext
		  appendGlyphsPathThroughCairo: aGlyphsArray
		  length: aNumberOfGlyphs
]

{ #category : '*VectorGraphics-Bloc' }
AeCairoScaledFont >> fontExtentsInto: aFontExtents onAeContext: aContext [
	"Straight back to cairo_font_extents."

	^ aContext fontExtentsThroughCairoInto: aFontExtents
]

{ #category : '*VectorGraphics-Bloc' }
AeCairoScaledFont >> glyphExtentsOf: aGlyphArray size: aNumberOfGlyphs into: aTextExtents onAeContext: aContext [
	"Straight back to cairo_glyph_extents."

	^ aContext
		  glyphExtentsThroughCairoOf: aGlyphArray
		  size: aNumberOfGlyphs
		  into: aTextExtents
]

{ #category : '*VectorGraphics-Bloc' }
AeCairoScaledFont >> poseOnAeContext: aContext [
	"Extensions in this project's own package, because Alexandrie's classes are never edited
	 here: VGAeTextContext asks the scaled font it was given which route to take, and a real
	 Cairo font sends every text call straight back to the inherited implementation."

	^ aContext poseScaledFontThroughCairo: self
]

{ #category : '*VectorGraphics-Bloc' }
AeCairoScaledFont >> showGlyphs: aGlyphsArray size: aNumberOfGlyphs onAeContext: aContext [
	"Straight back to cairo_show_glyphs: I am a font Cairo can draw by itself."

	^ aContext showGlyphsThroughCairo: aGlyphsArray size: aNumberOfGlyphs
]
