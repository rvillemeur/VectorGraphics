"
The four blend modes that read a colour whole rather than channel by channel: `hslHue`,
`hslSaturation`, `hslColor` and `hslLuminosity`.

The PDF specification writes them in terms of a colour's luminance and saturation, which no single
channel carries, so my blend selector takes the two whole colours and answers a whole colour. The
helpers below are that specification's `Lum`, `ClipColor`, `SetLum`, `Sat` and `SetSat`. Like the
dividing modes I composite in floating point, which is where pixman composites these.
"
Class {
	#name : 'VGNonSeparableBlendOperator',
	#superclass : 'VGFloatBlendOperator',
	#category : 'VectorGraphics-Cairo-Compositing',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Compositing'
}

{ #category : 'compositing' }
VGNonSeparableBlendOperator >> blendForBackdrop: aBackdrop source: aSource [
	"A hue-saturation-luminosity mode reads all three channels of a colour at once, so my blend
	 function takes the two colours whole and answers the three channels together."
	^ self perform: blendSelector with: aBackdrop with: aSource
]

{ #category : 'colour arithmetic' }
VGNonSeparableBlendOperator >> clippedColour: aColour [
	"Setting a luminance can carry a channel out of zero to one. The specification pulls the whole
	 colour back towards its luminance, by the amount the worst channel overshoots, so the hue is
	 kept. Both pulls read the luminance and the extremes the colour arrived with."

	| luminance darkest lightest clipped |
	luminance := self luminanceOf: aColour.
	darkest := aColour min.
	lightest := aColour max.
	clipped := aColour.
	(darkest < 0 and: [ luminance > darkest ]) ifTrue: [
		clipped := clipped collect: [ :each |
			           luminance + ((each - luminance) * luminance / (luminance - darkest)) ] ].
	(lightest > 1 and: [ lightest > luminance ]) ifTrue: [
		clipped := clipped collect: [ :each |
			           luminance
			           + ((each - luminance) * (1 - luminance) / (lightest - luminance)) ] ].
	^ clipped
]

{ #category : 'blend functions' }
VGNonSeparableBlendOperator >> colorOf: aBackdrop with: aSource [
	"Named as cairo_operator_t names it, so the operator table reads as the enumeration does."

	^ self colour: aSource withLuminance: (self luminanceOf: aBackdrop)
]

{ #category : 'colour arithmetic' }
VGNonSeparableBlendOperator >> colour: aColour withLuminance: aLuminance [
	| lift |
	lift := aLuminance - (self luminanceOf: aColour).
	^ self clippedColour: (aColour collect: [ :each | each + lift ])
]

{ #category : 'colour arithmetic' }
VGNonSeparableBlendOperator >> colour: aColour withSaturationRange: aRange [
	"The darkest channel goes to zero, the lightest to the range, and the middle one keeps its
	 place between them. A colour with no range of its own has no middle to keep, so it is black."

	| darkest lightest |
	darkest := aColour min.
	lightest := aColour max.
	lightest = darkest ifTrue: [ ^ #( 0 0 0 ) ].
	^ aColour collect: [ :each |
		  (each - darkest) * aRange / (lightest - darkest) ]
]

{ #category : 'blend functions' }
VGNonSeparableBlendOperator >> hueOf: aBackdrop with: aSource [
	^ self
		  colour: (self colour: aSource withSaturationRange: (self saturationRangeOf: aBackdrop))
		  withLuminance: (self luminanceOf: aBackdrop)
]

{ #category : 'colour arithmetic' }
VGNonSeparableBlendOperator >> luminanceOf: aColour [
	"The weights of the PDF specification, as exact fractions: a colour that comes out of the clip
	 at a whole channel has to stay there, and a float weight would leave it just below."

	^ (3 / 10 * (aColour at: 1)) + (59 / 100 * (aColour at: 2))
	  + (11 / 100 * (aColour at: 3))
]

{ #category : 'blend functions' }
VGNonSeparableBlendOperator >> luminosityOf: aBackdrop with: aSource [
	^ self colour: aBackdrop withLuminance: (self luminanceOf: aSource)
]

{ #category : 'blend functions' }
VGNonSeparableBlendOperator >> saturationOf: aBackdrop with: aSource [
	^ self
		  colour: (self colour: aBackdrop withSaturationRange: (self saturationRangeOf: aSource))
		  withLuminance: (self luminanceOf: aBackdrop)
]

{ #category : 'colour arithmetic' }
VGNonSeparableBlendOperator >> saturationRangeOf: aColour [
	^ aColour max - aColour min
]
