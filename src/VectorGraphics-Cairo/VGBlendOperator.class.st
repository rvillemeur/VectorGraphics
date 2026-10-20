"
One of the fifteen PDF blend modes, which composite like `over` but mix the two colours by a blend
function first.

I hold the blend function as a selector and `isBlendMode` answers true, which is how the tests
pick the fifteen out of the twenty-nine. Where the arithmetic runs is my subclasses' business:
`VGSeparableBlendOperator` composites in eight-bit integers, because pixman kept an integer
combiner for those modes, and `VGFloatBlendOperator` composites in floating point, because pixman
did not.
"
Class {
	#name : 'VGBlendOperator',
	#superclass : 'VGCairoOperator',
	#instVars : [
		'blendSelector'
	],
	#category : 'VectorGraphics-Cairo-Compositing',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Compositing'
}

{ #category : 'instance creation' }
VGBlendOperator class >> code: anInteger name: aSymbol blend: aSelector [
	^ self new setCode: anInteger name: aSymbol blend: aSelector
]

{ #category : 'testing' }
VGBlendOperator >> isBlendMode [
	^ true
]

{ #category : 'initialisation' }
VGBlendOperator >> setCode: anInteger name: aSymbol blend: aSelector [
	self setCode: anInteger name: aSymbol.
	blendSelector := aSelector
]
