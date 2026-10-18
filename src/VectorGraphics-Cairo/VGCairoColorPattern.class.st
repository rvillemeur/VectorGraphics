"
I am a VGCairoPattern holding a single colour, which Cairo models as a pattern so that every source is one kind of thing.

I answer the frozen paint ABI of rule two of VECTORCANVAS-PLAN.md, and unit 1.5 implements me.
"
Class {
	#name : 'VGCairoColorPattern',
	#superclass : 'VGCairoPattern',
	#category : 'VectorGraphics-Cairo-Pattern',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Pattern'
}

{ #category : 'instance creation' }
VGCairoColorPattern class >> newFrom: arg1 [
	^ self notYetImplementedIn: '1.5' selector: #newFrom:
]

{ #category : 'skeleton - unit 1.5' }
VGCairoColorPattern class >> r: arg1 g: arg2 b: arg3 [
	^ self notYetImplementedIn: '1.5' selector: #r:g:b:
]

{ #category : 'skeleton - unit 1.5' }
VGCairoColorPattern class >> r: arg1 g: arg2 b: arg3 alpha: arg4 [
	^ self notYetImplementedIn: '1.5' selector: #r:g:b:alpha:
]
