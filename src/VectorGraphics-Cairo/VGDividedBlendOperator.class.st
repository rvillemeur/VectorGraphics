"
The three blend modes whose arithmetic divides: `colorDodge`, `colorBurn` and `softLight`.

Pixman has no eight-bit combiner for them — the division costs too much precision — so it
composites them in floating point, and so do I through `VGFloatBlendOperator`. I blend channel by
channel, performing my blend selector on each unpremultiplied pair.
"
Class {
	#name : 'VGDividedBlendOperator',
	#superclass : 'VGFloatBlendOperator',
	#category : 'VectorGraphics-Cairo-Compositing',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Compositing'
}

{ #category : 'compositing' }
VGDividedBlendOperator >> blendForBackdrop: aBackdrop source: aSource [
	"I blend each channel on its own, so my blend function runs three times."
	^ (1 to: 3) collect: [ :index |
		  self
			  perform: blendSelector
			  with: (aBackdrop at: index)
			  with: (aSource at: index) ]
]

{ #category : 'blend functions' }
VGDividedBlendOperator >> colorBurnOf: aBackdrop with: aSource [
	aBackdrop >= 1 ifTrue: [ ^ 1 ].
	aSource = 0 ifTrue: [ ^ 0 ].
	^ 1 - ((1 - aBackdrop) / aSource min: 1)
]

{ #category : 'blend functions' }
VGDividedBlendOperator >> colorDodgeOf: aBackdrop with: aSource [
	"Named as cairo_operator_t names it, so the operator table reads as the enumeration does."

	aBackdrop = 0 ifTrue: [ ^ 0 ].
	aSource >= 1 ifTrue: [ ^ 1 ].
	^ aBackdrop / (1 - aSource) min: 1
]

{ #category : 'blend functions' }
VGDividedBlendOperator >> softLightOf: aBackdrop with: aSource [
	"The darkening half is exact; the lightening half needs a root below a quarter backdrop, which
	 the specification replaces with a cubic so the curve stays continuous."

	| lift |
	aSource <= (1 / 2) ifTrue: [
		^ aBackdrop - ((1 - (2 * aSource)) * aBackdrop * (1 - aBackdrop)) ].
	lift := aBackdrop <= (1 / 4)
		        ifTrue: [ ((16 * aBackdrop - 12) * aBackdrop + 4) * aBackdrop ]
		        ifFalse: [ aBackdrop sqrt ].
	^ aBackdrop + (((2 * aSource) - 1) * (lift - aBackdrop))
]
