"
I am the multiply blend mode, which pixman gives a combiner of its own rather than running it through the macro the other separable modes share.

The formula is the same as my superclass's, and the rounding is not: pixman rounds each of my three parts on its own, the backdrop weighted by what the source leaves free, the source weighted by what the backdrop leaves free, and the product of the two premultiplied channels, where every other separable mode rounds the three only once after summing them. The difference is one step of a channel and it showed on four of nine measured colour pairs, which is why I am a class and not a flag.
"
Class {
	#name : 'VGMultiplyBlendOperator',
	#superclass : 'VGSeparableBlendOperator',
	#category : 'VectorGraphics-Cairo-Compositing',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Compositing'
}

{ #category : 'compositing' }
VGMultiplyBlendOperator >> channelForBackdropPart: aBackdropPart sourcePart: aSourcePart blendPart: aBlendPart in: aFormat [
	"Pixman's combiner for multiply rounds each of the three parts on its own, where the macro
	 the other separable modes share rounds their sum once. Measured: the two differ by a step of
	 a channel on four of nine colour pairs."
	^ (aFormat dividedByte: aBackdropPart) + (aFormat dividedByte: aSourcePart)
	  + (aFormat dividedByte: aBlendPart)
]
