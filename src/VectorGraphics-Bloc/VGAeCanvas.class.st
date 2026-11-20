"
I am the canvas of the route this font plan builds: Cairo draws every pixel, and the fonts behind the text are this project's.

My surface and my context are Alexandrie's own, because Cairo is what composites here. One thing is mine: the context is a `VGAeTextContext`, which asks the font posed on it for its text adapter instead of marshalling it into `cairo_set_scaled_font`. A `VGScaledFont` has no such handle, so a stock context dies on the first run of text; mine draws it from our own masks and outlines.

Everything about the fonts themselves — our options record, one `VGScaledFont` per face and size, the font matrix in `VGCairoMatrix` — belongs to `VGFontCanvas`, which I share with `VGCanvas`. We part on who draws: that one replaces Cairo, I keep it.

`VGAeRenderer` builds me for a window's frame and `VGAeOffscreen` for the measurement of text that happens before any window exists.
"
Class {
	#name : 'VGAeCanvas',
	#superclass : 'VGFontCanvas',
	#category : 'VectorGraphics-Bloc-Text',
	#package : 'VectorGraphics-Bloc',
	#tag : 'Text'
}

{ #category : 'initialization' }
VGAeCanvas >> prepareForSurface: aeCairoSurface [
	"Alexandrie''s own method with two sends changed. The context is built by `VGAeTextContext`
	 rather than asked of the surface, which would answer an `AeCairoContext` and die marshalling
	 one of our scaled fonts. Substituting the context at `AeCairoSurface >> newContext` was
	 withdrawn in unit 4.6 of the font plan, because an extension that redefines an upstream
	 method cannot leave that checkout clean, so the decision is taken here instead.
	 The manager is checked for the same reason it is checked when measuring: the faces this
	 canvas draws come from the slot upstream nils at every image start, and a face of
	 upstream''s own kind breaks in our scaled font.	 Nothing holds the rest of the method against the upstream source: a change of Alexandrie's
	 own prepareForSurface: has to be read by hand when the dependency is raised."

	VGFontManager ensureUpstreamHoldsMine.
	cairoSurface := aeCairoSurface.
	cairoContext := VGAeTextContext unownedNewFor: aeCairoSurface.
	deviceScaleMatrix := cairoSurface deviceScaleMatrix.
	self setHighQualityOptions
]
