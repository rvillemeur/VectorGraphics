"
I am the part two gradients share: the stop list and its evaluation.

A stop is an offset in zero to one and a colour. `colorAtOffset:` interpolates between the two stops the offset falls between, unpremultiplied and in floating point, which is what live Cairo does. With no stop at all I paint nothing; with one stop I paint that colour everywhere; outside the stops I hold the first and the last, which is what Cairo does whatever the extend mode, since the extend mode acts on the gradient parameter and not on the stop list.

My subclasses say how a device point becomes that offset.
"
Class {
	#name : 'VGGradientPaint',
	#superclass : 'VGPaint',
	#instVars : [
		'stops'
	],
	#category : 'VectorGraphics-Cairo-Paint',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Paint'
}

{ #category : 'constants' }
VGGradientPaint class >> stopTableSize [
	"The size of the optional lookup table of rule 2. Phase 1 evaluates the stops instead, because
	 a table that quantises the offset drifts from live Cairo, so this number serves a shader
	 only."

	^ 256
]

{ #category : 'stops' }
VGGradientPaint >> addStopAt: anOffset channels: aCollection [
	"A stop whose colour is already four unpremultiplied channels, which is how a stop that has
	 travelled through a buffer comes back. The channels are copied, so a buffer read again does
	 not move a stop already added."

	stops add: anOffset asFloat -> aCollection copy
]

{ #category : 'accessing' }
VGGradientPaint >> addStopAt: anOffset color: aColor [
	"The stop list keeps channels and not colours, because the interpolation between two stops
	 has to stay in floating point."

	stops add: anOffset asFloat -> (self class rgbaOf: aColor)
]

{ #category : 'evaluating' }
VGGradientPaint >> extended: anOffset [
	"The offset the extend mode really reads, or nil where the mode paints nothing. Each one is
	 measured against a live Cairo context on a gradient from 16@0 to 32@0: none leaves pixel zero
	 untouched, pad holds the first stop there, repeat wraps the offset into zero to one, and
	 reflect folds it into a triangle of period two."

	self extend = #none ifTrue: [
		^ (anOffset between: 0.0 and: 1.0)
			  ifTrue: [ anOffset ]
			  ifFalse: [ nil ] ].
	self extend = #pad ifTrue: [ ^ (anOffset max: 0.0) min: 1.0 ].
	self extend = #repeat ifTrue: [ ^ anOffset \\ 1.0 ].
	^ self reflected: anOffset
]

{ #category : 'accessing' }
VGGradientPaint >> hasStops [
	^ stops notEmpty
]

{ #category : 'initialization' }
VGGradientPaint >> initialize [
	super initialize.
	stops := OrderedCollection new
]

{ #category : 'inspector' }
VGGradientPaint >> inspectorRamp: aBuilder [

	<inspectorPresentationOrder: 21 title: 'Ramp'>
	^ aBuilder newTable
		  items: ((-4 to: 12) collect: [ :eighth | eighth / 8 ]);
		  addColumn:
			  (SpStringTableColumn title: 'Offset' evaluated: [ :each | each printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Read at'
				   evaluated: [ :each |
					   (self extended: each asFloat)
						   ifNil: [ 'nothing painted' ]
						   ifNotNil: [ :extended | extended printString ] ]);
		  addColumn: (SpStringTableColumn
				   title: 'Channels'
				   evaluated: [ :each |
					   (self extended: each asFloat)
						   ifNil: [ '' ]
						   ifNotNil: [ :extended |
							   ((self rgbaAtOffset: extended) collect: [ :channel |
								    (channel * 255) rounded ]) printString ] ]);
		  yourself
]

{ #category : 'inspector' }
VGGradientPaint >> inspectorRampContext: aContext [

	aContext active: self hasStops
]

{ #category : 'evaluating' }
VGGradientPaint >> interpolate: firstChannels to: secondChannels at: aFraction [
	"Live Cairo interpolates unpremultiplied: a transparent blue stop ramping to an opaque red one
	 reads a blue of one hundred and twenty-six at the half-way point, which a premultiplied
	 interpolation cannot produce."

	^ (1 to: firstChannels size) collect: [ :index |
		  | from |
		  from := firstChannels at: index.
		  from + (((secondChannels at: index) - from) * aFraction) ]
]

{ #category : 'evaluating' }
VGGradientPaint >> offsetInPaintSpace: aPoint [
	^ self subclassResponsibility
]

{ #category : 'copying' }
VGGradientPaint >> postCopy [
	"Cairo rasterises a fill at the moment the fill is asked for, and this layer records it and
	 draws it at the drain, so the stops it will read have to be the stops of that moment."

	super postCopy.
	stops := stops copy
]

{ #category : 'evaluating' }
VGGradientPaint >> reflected: anOffset [
	"A triangle of period two: the second half of each period runs backwards."

	| folded |
	folded := anOffset \\ 2.0.
	^ folded <= 1.0
		  ifTrue: [ folded ]
		  ifFalse: [ 2.0 - folded ]
]

{ #category : 'evaluating' }
VGGradientPaint >> rgbaAtOffset: anOffset [
	"The stops are kept in the order they were added, which is the order Cairo reads them in, so
	 the stop before the offset is the last one at or below it and the stop after it is the first
	 one at or above it. An offset past either end answers the end stop itself."

	| before after |
	before := nil.
	after := nil.
	stops do: [ :each |
		each key <= anOffset ifTrue: [ before := each ].
		(after isNil and: [ each key >= anOffset ]) ifTrue: [ after := each ] ].
	before ifNil: [ ^ after value ].
	after ifNil: [ ^ before value ].
	before key = after key ifTrue: [ ^ after value ].
	^ self
		  interpolate: before value
		  to: after value
		  at: (anOffset - before key) / (after key - before key)
]

{ #category : 'evaluating' }
VGGradientPaint >> rgbaInPaintSpace: aPoint [
	| offset |
	stops ifEmpty: [ ^ nil ].
	offset := self offsetInPaintSpace: aPoint.
	offset ifNil: [ ^ nil ].
	offset := self extended: offset.
	offset ifNil: [ ^ nil ].
	^ self rgbaAtOffset: offset
]

{ #category : 'converting' }
VGGradientPaint >> stopTable [
	"The stop lookup table of rule 2: two hundred and fifty-six entries of four bytes, entry n
	 holding the channels at offset n over two hundred and fifty-five. Phase 2 hands this to a
	 shader as a one-dimensional texture. Phase 1 never reads it, because live Cairo evaluates a
	 gradient exactly and not through a table: on a ramp of nought to two thousand and forty-eight
	 pixel sixty-three reads eight, where a table of this size answers seven."

	| size table |
	size := self class stopTableSize.
	table := ByteArray new: size * 4.
	1 to: size do: [ :index |
		| channels |
		channels := self rgbaAtOffset: index - 1 / (size - 1).
		channels ifNotNil: [
			1 to: 4 do: [ :channel |
				table
					at: index - 1 * 4 + channel
					put: ((channels at: channel) * 255) rounded ] ] ].
	^ table
]

{ #category : 'accessing' }
VGGradientPaint >> stops [
	"Each stop is an offset in zero to one associated with a colour, in the order they were
	 added."

	^ stops
]
