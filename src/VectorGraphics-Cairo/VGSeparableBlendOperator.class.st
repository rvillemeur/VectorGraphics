"
A blend mode pixman composites in eight-bit integers, one channel at a time: `multiply`, `screen`,
`overlay`, `darken`, `lighten`, `hardLight`, `difference` and `exclusion`.

Each mode is a `…TermForDestination:alpha:source:alpha:` method answering the blend part of the
channel's numerator, already scaled by both alphas, and `compose:over:in:` adds the backdrop part
and the source part to it and divides once. `multiply` divides each of the three parts on its own
instead, because pixman gives it a combiner of its own; that is `VGMultiplyBlendOperator`.
"
Class {
	#name : 'VGSeparableBlendOperator',
	#superclass : 'VGBlendOperator',
	#category : 'VectorGraphics-Cairo-Compositing',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Compositing'
}

{ #category : 'compositing' }
VGSeparableBlendOperator >> blendTermsForDestination: aDestination alpha: aDestinationAlpha source: aSource alpha: aSourceAlpha [
	"A separable mode blends each channel on its own, so my term is my blend function applied
	 three times."

	^ (1 to: 3) collect: [ :index |
		  self perform: blendSelector withArguments: {
				  (aDestination at: index).
				  aDestinationAlpha.
				  (aSource at: index).
				  aSourceAlpha } ]
]

{ #category : 'compositing' }
VGSeparableBlendOperator >> channelForBackdropPart: aBackdropPart sourcePart: aSourcePart blendPart: aBlendPart in: aFormat [
	"My channel byte from the three parts of its numerator. Pixman divides the sum of the three
	 by two hundred and fifty-five once, which is one rounding for the channel."
	^ aFormat dividedByte: aBackdropPart + aSourcePart + aBlendPart
]

{ #category : 'compositing' }
VGSeparableBlendOperator >> compose: aSourcePixel over: aDestinationPixel in: aFormat [
	"The PDF blend formula, in the integer arithmetic pixman composites a blend mode on bytes
	 with. Each of the three parts of a channel runs at two hundred and fifty-five times the
	 channel: the backdrop where the source leaves it free, the source where the backdrop leaves
	 it free, and my blend term for the part the two share. Alpha composes as source-over does,
	 whatever the blend mode, so an A8 surface has no colour to blend and carries the alpha alone."
	| sourceAlpha destinationAlpha alpha source destination terms |
	sourceAlpha := aFormat alphaOfPixel: aSourcePixel.
	destinationAlpha := aFormat alphaOfPixel: aDestinationPixel.
	alpha := aFormat alphaComposing: sourceAlpha over: destinationAlpha.
	aFormat isA8 ifTrue: [ ^ alpha ].
	source := aFormat premultipliedChannelsOfPixel: aSourcePixel.
	destination := aFormat premultipliedChannelsOfPixel: aDestinationPixel.
	terms := self
		         blendTermsForDestination: destination
		         alpha: destinationAlpha
		         source: source
		         alpha: sourceAlpha.
	^ aFormat pixelForAlpha: alpha channels: ((1 to: 3) collect: [ :index |
			   | channel |
			   channel := self
				              channelForBackdropPart: (255 - sourceAlpha) * (destination at: index)
				              sourcePart: (255 - destinationAlpha) * (source at: index)
				              blendPart: (terms at: index)
				              in: aFormat.
			   (channel max: 0) min: alpha ])
]

{ #category : 'blend functions' }
VGSeparableBlendOperator >> darkenTermForDestination: aDestinationChannel alpha: aDestinationAlpha source: aSourceChannel alpha: aSourceAlpha [
	^ aSourceAlpha * aDestinationChannel min: aDestinationAlpha * aSourceChannel
]

{ #category : 'blend functions' }
VGSeparableBlendOperator >> differenceTermForDestination: aDestinationChannel alpha: aDestinationAlpha source: aSourceChannel alpha: aSourceAlpha [
	^ (aSourceAlpha * aDestinationChannel - (aDestinationAlpha * aSourceChannel)) abs
]

{ #category : 'blend functions' }
VGSeparableBlendOperator >> exclusionTermForDestination: aDestinationChannel alpha: aDestinationAlpha source: aSourceChannel alpha: aSourceAlpha [
	^ aSourceAlpha * aDestinationChannel + (aDestinationAlpha * aSourceChannel)
	  - (2 * aDestinationChannel * aSourceChannel)
]

{ #category : 'blend functions' }
VGSeparableBlendOperator >> hardLightTermForDestination: aDestinationChannel alpha: aDestinationAlpha source: aSourceChannel alpha: aSourceAlpha [
	"Hard light is a multiply under a source channel below a half and a screen above it."

	2 * aSourceChannel < aSourceAlpha ifTrue: [
		^ 2 * aDestinationChannel * aSourceChannel ].
	^ aSourceAlpha * aDestinationAlpha
	  - (2 * (aSourceAlpha - aSourceChannel) * (aDestinationAlpha - aDestinationChannel))
]

{ #category : 'blend functions' }
VGSeparableBlendOperator >> lightenTermForDestination: aDestinationChannel alpha: aDestinationAlpha source: aSourceChannel alpha: aSourceAlpha [
	^ aSourceAlpha * aDestinationChannel max: aDestinationAlpha * aSourceChannel
]

{ #category : 'blend functions' }
VGSeparableBlendOperator >> multiplyTermForDestination: aDestinationChannel alpha: aDestinationAlpha source: aSourceChannel alpha: aSourceAlpha [
	^ aDestinationChannel * aSourceChannel
]

{ #category : 'blend functions' }
VGSeparableBlendOperator >> overlayTermForDestination: aDestinationChannel alpha: aDestinationAlpha source: aSourceChannel alpha: aSourceAlpha [
	"Overlay is hard light with the two sides exchanged, so it tests the destination channel."

	2 * aDestinationChannel < aDestinationAlpha ifTrue: [
		^ 2 * aDestinationChannel * aSourceChannel ].
	^ aSourceAlpha * aDestinationAlpha
	  - (2 * (aSourceAlpha - aSourceChannel) * (aDestinationAlpha - aDestinationChannel))
]

{ #category : 'blend functions' }
VGSeparableBlendOperator >> screenTermForDestination: aDestinationChannel alpha: aDestinationAlpha source: aSourceChannel alpha: aSourceAlpha [
	^ aSourceAlpha * aDestinationChannel + (aDestinationAlpha * aSourceChannel)
	  - (aDestinationChannel * aSourceChannel)
]
