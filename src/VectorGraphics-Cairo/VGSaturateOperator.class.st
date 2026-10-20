"
I am Cairo's saturate operator: the source weighted by as much of it as the destination still leaves free, added to the whole destination.

My factors are my superclass's, source saturating and destination one, and what I do not share with it is where the arithmetic runs. Pixman composites me in floating point, as it does the seven dividing blend modes, so I read the source as a wide pixel of four sixteen-bit shorts and store through VGCairoOperator >> composeWideSource:mask:over:in:. On bytes my superclass's arithmetic is a step out of live Cairo on three of nine measured colour pairs, and in floating point it matches all nine.
"
Class {
	#name : 'VGSaturateOperator',
	#superclass : 'VGPorterDuffOperator',
	#category : 'VectorGraphics-Cairo-Compositing',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Compositing'
}

{ #category : 'testing' }
VGSaturateOperator >> composesInFloatingPoint [
	^ true
]

{ #category : 'compositing' }
VGSaturateOperator >> floatAlphaForSource: aSourceAlpha over: aDestinationAlpha [
	^ (self floatFactorForSource: aSourceAlpha over: aDestinationAlpha) * aSourceAlpha
	  + aDestinationAlpha
]

{ #category : 'compositing' }
VGSaturateOperator >> floatChannelsForSource: aSource alpha: aSourceAlpha over: aDestination alpha: aDestinationAlpha [
	"My factor weighs the source, the destination stands whole, and the store caps what overflows."
	| factor |
	factor := self floatFactorForSource: aSourceAlpha over: aDestinationAlpha.
	^ (1 to: 3) collect: [ :index |
		  factor * (aSource at: index) + (aDestination at: index) ]
]

{ #category : 'compositing' }
VGSaturateOperator >> floatFactorForSource: aSourceAlpha over: aDestinationAlpha [
	"How much of the source still fits in what the destination leaves free, capped at the whole
	 source. A source of no alpha has nothing to fit and pixman weighs it fully rather than
	 dividing by nothing."
	aSourceAlpha = 0 ifTrue: [ ^ 1.0 ].
	^ ((1.0 - aDestinationAlpha) / aSourceAlpha max: 0.0) min: 1.0
]
