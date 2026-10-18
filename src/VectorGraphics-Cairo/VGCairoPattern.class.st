"
I am the abstract replacement for AeCairoPattern: a source of colour other than a single flat colour.

My subclasses are VGCairoColorPattern, VGCairoLinearGradientPattern, VGCairoRadialGradientPattern and VGCairoSurfacePattern. Whatever the subclass, what reaches a backend is the frozen paint ABI of rule two: a tag, a block of thirty-two-bit floats, and for a gradient a two-hundred-and-fifty-six-entry stop lookup table. Nothing below the backend boundary knows I exist.

Unit 1.5 implements me.
"
Class {
	#name : 'VGCairoPattern',
	#superclass : 'VGCairoObject',
	#category : 'VectorGraphics-Cairo-Pattern',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Pattern'
}

{ #category : 'skeleton - unit 1.5' }
VGCairoPattern >> filter: arg1 [
	^ self notYetImplementedIn: '1.5' selector: #filter:
]

{ #category : 'skeleton - unit 1.2' }
VGCairoPattern >> matrix [
	^ self notYetImplementedIn: '1.2' selector: #matrix
]

{ #category : 'skeleton - unit 1.2' }
VGCairoPattern >> matrix: arg1 [
	^ self notYetImplementedIn: '1.2' selector: #matrix:
]

{ #category : 'skeleton - unit 1.5' }
VGCairoPattern >> type [
	^ self notYetImplementedIn: '1.5' selector: #type
]
