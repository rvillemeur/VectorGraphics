"
I am the Cairo context Alexandrie builds for every surface, and I know this project's scaled fonts.

Cairo's own text calls take a `cairo_scaled_font_t`. A `VGScaledFont` has no such handle, so a text selector that reaches the FFI call with one of ours dies marshalling it. I take the decision out of the context: every text selector asks the scaled font it was given, and the font answers for itself. A `VGScaledFont` draws through its own glyph atlas; a real `AeCairoScaledFont` sends the call straight back to me, to the `…ThroughCairo:` method that holds what my superclass does, so an image with no font manager of ours draws exactly as before.

`ownScaledFont` holds the last scaled font of this project posed on me, which is what my glyph and extent selectors then work from. It is nil while a real Alexandrie font is posed: that route never reads it.

I am substituted for my superclass at one site, the extension `AeCairoSurface >> newContext`, which covers windows, composition layers, shadows, exporters and offscreen surfaces at once.
"
Class {
	#name : 'VGAeTextContext',
	#superclass : 'AeCairoContext',
	#instVars : [
		'ownScaledFont'
	],
	#category : 'VectorGraphics-Bloc-Text',
	#package : 'VectorGraphics-Bloc',
	#tag : 'Text'
}

{ #category : 'instance creation' }
VGAeTextContext class >> unownedNewFor: targetSurface [
	"The same cairo_create as my superclass, with my class as the return type: an FFI call names
	 the class it marshals the answer into, so the inherited method would answer an AeCairoContext
	 and lose the text routing."

	^ self ffiCall: #(
		  VGAeTextContext
		  cairo_create (
			  AeCairoSurface targetSurface ) )
]

{ #category : 'API - text' }
VGAeTextContext >> appendGlyphsPath: aGlyphsArray length: aNumberOfGlyphs [
	"The path site, which unit 4.4 of the font plan answers from our own outlines."

	^ self scaledFontToWorkFrom
		  appendPathOfGlyphs: aGlyphsArray
		  length: aNumberOfGlyphs
		  onAeContext: self
]

{ #category : 'text - through cairo' }
VGAeTextContext >> appendGlyphsPathThroughCairo: aGlyphsArray length: aNumberOfGlyphs [
	"What my superclass does, cairo_glyph_path."

	^ super appendGlyphsPath: aGlyphsArray length: aNumberOfGlyphs
]

{ #category : 'text - through cairo' }
VGAeTextContext >> fontExtentsThroughCairoInto: aFontExtents [
	"What my superclass does, cairo_font_extents."

	^ super getFontExtentsInto: aFontExtents
]

{ #category : 'API - text' }
VGAeTextContext >> getFontExtentsInto: aFontExtents [
	"The font extents site, which unit 4.5 of the font plan answers from hhea."

	^ self scaledFontToWorkFrom fontExtentsInto: aFontExtents onAeContext: self
]

{ #category : 'API - text' }
VGAeTextContext >> getGlyphExtentsOf: aGlyphArray size: aNumberOfGlyphs into: aTextExtents [
	"The measuring site, which unit 4.3 of the font plan answers from our own metrics. Until
	 then a VGScaledFont has no method for it and the send fails naming our class and this
	 selector, which says what is missing; nothing reaches the FFI call with a font it cannot
	 marshal."

	^ self scaledFontToWorkFrom
		  glyphExtentsOf: aGlyphArray
		  size: aNumberOfGlyphs
		  into: aTextExtents
		  onAeContext: self
]

{ #category : 'text - through cairo' }
VGAeTextContext >> glyphExtentsThroughCairoOf: aGlyphArray size: aNumberOfGlyphs into: aTextExtents [
	"What my superclass does, cairo_glyph_extents."

	^ super
		  getGlyphExtentsOf: aGlyphArray
		  size: aNumberOfGlyphs
		  into: aTextExtents
]

{ #category : 'accessing' }
VGAeTextContext >> ownScaledFont [
	"The scaled font of this project posed on me, nil while a real Alexandrie font is posed."

	^ ownScaledFont
]

{ #category : 'accessing' }
VGAeTextContext >> ownScaledFont: aScaledFont [
	"Sent by a VGScaledFont posing itself on me. Cairo is told nothing: it has no handle for this
	 font, and marshalling one into cairo_set_scaled_font is the very break this class removes."

	ownScaledFont := aScaledFont
]

{ #category : 'text - through cairo' }
VGAeTextContext >> poseScaledFontThroughCairo: aScaledFont [
	"What my superclass does, cairo_set_scaled_font. A scaled font sends itself back here rather
	 than letting me ask what it is, and an extension method cannot send super for me, so every
	 inherited text call has a method of its own on this side."

	ownScaledFont := nil.
	^ super scaledFont: aScaledFont
]

{ #category : 'API - text' }
VGAeTextContext >> scaledFont: aScaledFont [
	"The verb AeCanvas sends before it draws, measures or paths any text. Which font arrives
	 decides the whole route, so the font answers for itself: one of ours remembers itself on me,
	 a real AeCairoScaledFont goes to Cairo."

	^ aScaledFont poseOnAeContext: self
]

{ #category : 'text' }
VGAeTextContext >> scaledFontToWorkFrom [
	"The font my text selectors ask: ours when one was posed, otherwise the one Cairo itself
	 holds, which is what keeps an image with no font manager of ours on the stock route."

	^ ownScaledFont ifNil: [ self scaledFont ]
]

{ #category : 'API - text' }
VGAeTextContext >> showGlyphs: aGlyphsArray size: aNumberOfGlyphs [
	"The drawing site: cairo_show_glyphs upstream, one A8 mask a glyph here."

	^ self scaledFontToWorkFrom
		  showGlyphs: aGlyphsArray
		  size: aNumberOfGlyphs
		  onAeContext: self
]

{ #category : 'text - through cairo' }
VGAeTextContext >> showGlyphsThroughCairo: aGlyphsArray size: aNumberOfGlyphs [
	"What my superclass does, cairo_show_glyphs."

	^ super showGlyphs: aGlyphsArray size: aNumberOfGlyphs
]
