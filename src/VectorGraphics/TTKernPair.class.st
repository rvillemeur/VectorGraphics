"
One kerning pair from a TrueType font's kern table.

Kerning adjusts the horizontal spacing between specific adjacent glyph pairs (e.g. 'AV').
Created by TTFontParser >> parseKernPairsType0: and stored in TTFontDescription >> kernPairs.
TrueTypeFont uses the sorted collection for fast lookup during string measurement.

## Key instVars
- `left`   glyph index of the left character
- `right`  glyph index of the right character
- `value`  kerning adjustment in font design units (negative = tighter, positive = looser)
- `mask`   packed integer `(left bitShift: 12) + right`, used as the sort/search key

## Key methods
- `TTKernPair class >> maskFor:with:` — computes the mask for binary-search lookup
- `mask` — lazy, caches the computed mask on first access
"
Class {
	#name : 'TTKernPair',
	#superclass : 'Object',
	#instVars : [
		'left',
		'right',
		'value',
		'mask'
	],
	#category : 'VectorGraphics-TrueType',
	#package : 'VectorGraphics',
	#tag : 'TrueType'
}

{ #category : 'accessing' }
TTKernPair class >> maskFor: left with: right [

	^ (left bitShift: 12) + right
]

{ #category : 'accessing' }
TTKernPair >> left [

	^ left
]

{ #category : 'accessing' }
TTKernPair >> left: aNumber [

	left := aNumber
]

{ #category : 'accessing' }
TTKernPair >> mask [

	^ mask ifNil: [ mask := self class maskFor: left with: right ]
]

{ #category : 'accessing' }
TTKernPair >> right [

	^ right
]

{ #category : 'accessing' }
TTKernPair >> right: aNumber [

	right := aNumber
]

{ #category : 'accessing' }
TTKernPair >> value [

	^ value
]

{ #category : 'accessing' }
TTKernPair >> value: aNumber [

	value := aNumber
]
