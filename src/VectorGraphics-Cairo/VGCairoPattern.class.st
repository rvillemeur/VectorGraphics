"
I am the abstract replacement for AeCairoPattern: a source of colour other than a single flat colour.

My subclasses are VGCairoColorPattern, VGCairoLinearGradientPattern, VGCairoRadialGradientPattern and VGCairoSurfacePattern. Whatever the subclass, what reaches a backend is the frozen paint ABI of rule two: a tag, a block of thirty-two-bit floats, and for a gradient a two-hundred-and-fifty-six-entry stop lookup table. Nothing below the backend boundary knows I exist.

Unit 1.5 implements me.
"
Class {
	#name : 'VGCairoPattern',
	#superclass : 'VGCairoObject',
	#instVars : [
		'matrix'
	],
	#category : 'VectorGraphics-Cairo-Pattern',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Pattern'
}

{ #category : 'skeleton' }
VGCairoPattern >> addStopAt: anArgument1 color: anArgument2 [
	^ self notYetImplementedIn: '1.5' selector: #addStopAt:color:
]

{ #category : 'skeleton - unit 1.5' }
VGCairoPattern >> filter: arg1 [
	^ self notYetImplementedIn: '1.5' selector: #filter:
]

{ #category : 'initialization' }
VGCairoPattern >> initialize [
	super initialize.
	matrix := VGCairoMatrix newIdentity
]

{ #category : 'accessing' }
VGCairoPattern >> matrix [
	"A copy, because Cairo answers the numbers rather than the pattern's own matrix."
	^ matrix copy
]

{ #category : 'accessing' }
VGCairoPattern >> matrix: aMatrix [
	matrix := aMatrix copy
]

{ #category : 'skeleton - unit 1.5' }
VGCairoPattern >> type [
	^ self notYetImplementedIn: '1.5' selector: #type
]
