"
An operator that weighs the source and the destination by a factor each, which is what the twelve
Porter-Duff operators and `add` are: `over` weighs the source by one and the destination by one
minus the source's alpha, `in` weighs the source by the destination's alpha and the destination by
nothing, and so on.

I hold the two factors as selectors (`#one`, `#oneMinusSourceAlpha`, `#destinationAlpha`, …) and
`factor:sourceAlpha:destinationAlpha:` turns one into a number for the pixel in hand. `clear` and
`source` need the destination even where no source covers, so they are my subclasses
`VGClearOperator` and `VGSourceOperator` and override the composition itself.
"
Class {
	#name : 'VGPorterDuffOperator',
	#superclass : 'VGCairoOperator',
	#instVars : [
		'sourceFactor',
		'destinationFactor'
	],
	#category : 'VectorGraphics-Cairo-Compositing',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Compositing'
}

{ #category : 'instance creation' }
VGPorterDuffOperator class >> code: anInteger name: aSymbol source: aFactorName destination: anotherFactorName [
	^ self new setCode: anInteger name: aSymbol source: aFactorName destination: anotherFactorName
]

{ #category : 'compositing' }
VGPorterDuffOperator >> compose: aSourcePixel over: aDestinationPixel in: aFormat [
	"Source times my source factor plus destination times my destination factor, channel by
	 channel on premultiplied bytes, summed with the rounding division by 255 Cairo's own integer
	 blend uses and capped, because add is the one pair of factors whose sum can overflow."

	| sourceAlpha destinationAlpha source destination |
	sourceAlpha := aFormat alphaOfPixel: aSourcePixel.
	destinationAlpha := aFormat alphaOfPixel: aDestinationPixel.
	source := self
		          factor: sourceFactor
		          sourceAlpha: sourceAlpha
		          destinationAlpha: destinationAlpha.
	destination := self
		               factor: destinationFactor
		               sourceAlpha: sourceAlpha
		               destinationAlpha: destinationAlpha.
	^ aFormat
		  mixPixel: aSourcePixel
		  weightedBy: source
		  withPixel: aDestinationPixel
		  weightedBy: destination
]

{ #category : 'private' }
VGPorterDuffOperator >> factor: aFactorName sourceAlpha: aSourceAlphaByte destinationAlpha: aDestinationAlphaByte [
	"The weight one of my two factor names stands for, as a byte. Saturate's factor is the one
	 that is not a plain alpha: it is how much of the source still fits in what the destination
	 leaves free, which is Cairo's own rounding division of the free alpha by the source alpha,
	 and the whole source when it already fits."

	aFactorName == #one ifTrue: [ ^ 255 ].
	aFactorName == #zero ifTrue: [ ^ 0 ].
	aFactorName == #sourceAlpha ifTrue: [ ^ aSourceAlphaByte ].
	aFactorName == #destinationAlpha ifTrue: [ ^ aDestinationAlphaByte ].
	aFactorName == #oneMinusSourceAlpha ifTrue: [ ^ 255 - aSourceAlphaByte ].
	aFactorName == #oneMinusDestinationAlpha ifTrue: [
		^ 255 - aDestinationAlphaByte ].
	aFactorName == #saturating ifTrue: [
		| free |
		free := 255 - aDestinationAlphaByte.
		^ aSourceAlphaByte > free
			  ifTrue: [ (free * 255 + (aSourceAlphaByte // 2)) // aSourceAlphaByte ]
			  ifFalse: [ 255 ] ].
	^ self error: aFactorName printString , ' is no compositing factor'
]

{ #category : 'initialisation' }
VGPorterDuffOperator >> setCode: anInteger name: aSymbol source: aFactorName destination: anotherFactorName [
	self setCode: anInteger name: aSymbol.
	sourceFactor := aFactorName.
	destinationFactor := anotherFactorName
]
