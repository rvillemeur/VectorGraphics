"
I am a Cairo context that knows this project's scaled fonts.

Cairo's own text calls take a `cairo_scaled_font_t`. A `VGScaledFont` has no such handle, so a text selector that reaches the FFI call with one of ours dies marshalling it. I take the decision out of the context: the font posed on me is asked for its text adapter, and that adapter answers every text selector afterwards. One of our fonts answers a `VGAeTextFont`, which draws through its own masks and outlines; a real `AeCairoScaledFont` answers itself and sends the call straight back to me, to the `…ThroughCairo:` method that holds what my superclass does, so an image with no font manager of ours draws exactly as before.

`ownTextFont` holds the adapter of the last font of this project posed on me, which is what my glyph and extent selectors then work from. It is nil while a real Alexandrie font is posed: that route never reads it.

`VGCanvas` builds me for the surface it draws on. My superclass is left alone: substituting me for it at `AeCairoSurface >> newContext` was withdrawn in unit 4.6 of the font plan, because an extension that redefines an upstream method cannot leave that checkout clean.
"
Class {
	#name : 'VGAeTextContext',
	#superclass : 'AeCairoContext',
	#instVars : [
		'ownTextFont'
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

	^ self textFontToWorkFrom
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

	^ self textFontToWorkFrom fontExtentsInto: aFontExtents onAeContext: self
]

{ #category : 'API - text' }
VGAeTextContext >> getGlyphExtentsOf: aGlyphArray size: aNumberOfGlyphs into: aTextExtents [
	"The measuring site, which unit 4.3 of the font plan answers from our own metrics. Until
	 then a VGScaledFont has no method for it and the send fails naming our class and this
	 selector, which says what is missing; nothing reaches the FFI call with a font it cannot
	 marshal."

	^ self textFontToWorkFrom
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
VGAeTextContext >> ownTextFont [
	"The adapter of one of our scaled fonts, posed on me, nil while a real Alexandrie font is
	 posed."

	^ ownTextFont
]

{ #category : 'accessing' }
VGAeTextContext >> ownTextFont: aTextFont [
	"Sent by a VGAeTextFont posing itself on me. Cairo is told nothing: it has no handle for the
	 font behind that adapter, and marshalling one into cairo_set_scaled_font is the very break
	 this class removes."

	ownTextFont := aTextFont
]

{ #category : 'text - through cairo' }
VGAeTextContext >> poseScaledFontThroughCairo: aScaledFont [
	"What my superclass does, cairo_set_scaled_font. A scaled font sends itself back here rather
	 than letting me ask what it is, and an extension method cannot send super for me, so every
	 inherited text call has a method of its own on this side."

	ownTextFont := nil.
	^ super scaledFont: aScaledFont
]

{ #category : 'API - text' }
VGAeTextContext >> scaledFont: aScaledFont [
	"The verb AeCanvas sends before it draws, measures or paths any text. Which font arrives
	 decides the whole route, so the font answers for itself through its adapter: one of ours
	 answers a VGAeTextFont, which remembers itself on me, a real AeCairoScaledFont answers
	 itself and goes to Cairo."

	^ aScaledFont aeTextFont poseOnAeContext: self
]

{ #category : 'API - text' }
VGAeTextContext >> showGlyphs: aGlyphsArray size: aNumberOfGlyphs [
	"The drawing site: cairo_show_glyphs upstream, one A8 mask a glyph here."

	^ self textFontToWorkFrom
		  showGlyphs: aGlyphsArray
		  size: aNumberOfGlyphs
		  onAeContext: self
]

{ #category : 'text - through cairo' }
VGAeTextContext >> showGlyphsThroughCairo: aGlyphsArray size: aNumberOfGlyphs [
	"What my superclass does, cairo_show_glyphs."

	^ super showGlyphs: aGlyphsArray size: aNumberOfGlyphs
]

{ #category : 'text' }
VGAeTextContext >> textFontToWorkFrom [
	"The font my text selectors ask: the adapter of one of ours when one was posed, otherwise
	 the font Cairo itself holds, which is what keeps an image with no font manager of ours on
	 the stock route."

	^ ownTextFont ifNil: [ self scaledFont ]
]
