"
I am the pattern a gradient is named with, and I hold what the two kinds of gradient have in common: the colour stops.

Alexandrie has the same class in the same place, and the stop selectors live here because a caller may name a gradient one stop at a time or hand over a whole collection of offset to colour associations at once. The geometry belongs to my subclasses: a line for a linear gradient, two circles for a radial one.
"
Class {
	#name : 'VGCairoGradientPattern',
	#superclass : 'VGCairoPattern',
	#category : 'VectorGraphics-Cairo-Pattern',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Pattern'
}

{ #category : 'accessing' }
VGCairoGradientPattern >> addStopAt: anOffset color: aColor [
	"Cairo sorts stops of the same offset by the order they were added, so that a caller can ask
	 for a sharp step rather than a blend; the paint keeps them in that order for the same reason."

	paint addStopAt: anOffset color: aColor
]

{ #category : 'accessing' }
VGCairoGradientPattern >> addStopAt: anOffset colorRGB: aColor [
	"Cairo's rgb stop drops the colour's own alpha and takes the stop as opaque."

	self addStopAt: anOffset color: (aColor alpha: 1.0)
]

{ #category : 'accessing' }
VGCairoGradientPattern >> addStopAt: anOffset colorRGBA: aColor [
	self addStopAt: anOffset color: aColor
]

{ #category : 'accessing' }
VGCairoGradientPattern >> addStopsFrom: offsetColorAssociations [
	offsetColorAssociations do: [ :each |
		self addStopAt: each key color: each value ]
]
