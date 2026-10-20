"
I am a blend mode that pixman composites in floating point rather than on bytes, and I hold that arithmetic for the modes that divide, which are my two subclasses: the three that divide one channel by another and the four that take a colour apart into hue, saturation and luminosity.

What I do differently from VGSeparableBlendOperator is not the blend function but the precision around it. I read the source as a wide pixel of four sixteen-bit shorts, because Cairo keeps a solid colour at that precision and pixman hands it to its floating point combiner unchanged; I unpremultiply both colours into floats, blend, and store each result the way pixman's own store does, by multiplying by two hundred and fifty-six and truncating. Composing me from an eight-bit pixel instead lands a step out of live Cairo on about one channel in three.

The split is measured, not inferred: over nine colour pairs, the twenty-one other operators match pixman's integer combiners and the seven modes under me, together with saturate, match the floating point one. VGCairoOperator >> composesInFloatingPoint answers which, and VGCairoOperator >> composeWideSource:mask:over:in: is the arithmetic I share with VGSaturateOperator.
"
Class {
	#name : 'VGFloatBlendOperator',
	#superclass : 'VGBlendOperator',
	#category : 'VectorGraphics-Cairo-Compositing',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Compositing'
}

{ #category : 'compositing' }
VGFloatBlendOperator >> blendForBackdrop: aBackdrop source: aSource [
	"The three blended channels of two unpremultiplied colours. A mode that blends each channel
	 on its own and a mode that reads a colour whole answer this differently, which is the only
	 difference between my two subclasses."
	^ self subclassResponsibility
]

{ #category : 'testing' }
VGFloatBlendOperator >> composesInFloatingPoint [
	^ true
]

{ #category : 'compositing' }
VGFloatBlendOperator >> floatAlphaForSource: aSourceAlpha over: aDestinationAlpha [
	"Every blend mode composites source over destination and only the colour differs."
	^ aSourceAlpha + aDestinationAlpha - (aSourceAlpha * aDestinationAlpha)
]

{ #category : 'compositing' }
VGFloatBlendOperator >> floatChannelsForSource: aSource alpha: aSourceAlpha over: aDestination alpha: aDestinationAlpha [
	"What the blend formula of the specification says: the source where the destination is
	 transparent, the destination where the source is transparent, and the blend of the two
	 colours where both are present. My blend function reads the colours with the alpha divided
	 back out, so either side fully transparent leaves nothing to blend and the other side
	 stands alone."
	| backdrop source blended |
	aSourceAlpha = 0 ifTrue: [ ^ aDestination ].
	aDestinationAlpha = 0 ifTrue: [ ^ aSource ].
	backdrop := aDestination collect: [ :each | each / aDestinationAlpha ].
	source := aSource collect: [ :each | each / aSourceAlpha ].
	blended := self blendForBackdrop: backdrop source: source.
	^ (1 to: 3) collect: [ :index |
		  (1 - aDestinationAlpha) * (aSource at: index)
		  + ((1 - aSourceAlpha) * (aDestination at: index))
		  + (aSourceAlpha * aDestinationAlpha * (blended at: index)) ]
]
