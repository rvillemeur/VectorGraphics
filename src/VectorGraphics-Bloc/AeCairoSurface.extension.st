Extension { #name : 'AeCairoSurface' }

{ #category : '*VectorGraphics-Bloc' }
AeCairoSurface >> newContext [
	"An extension redefining Alexandrie's own method, because Alexandrie's classes are never
	 edited in this project: VGAeTextContext answers the text selectors for a VGScaledFont, which
	 has no cairo_scaled_font_t to marshal, and delegates every other font to the stock code."

	^ VGAeTextContext newFor: self
]
