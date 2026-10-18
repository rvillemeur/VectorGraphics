"
I am a VGCairoPattern holding another surface used as a source, which is what an image background and an image paint need.

I answer the frozen paint ABI of rule two of VECTORCANVAS-PLAN.md, and unit 1.5 implements me.
"
Class {
	#name : 'VGCairoSurfacePattern',
	#superclass : 'VGCairoPattern',
	#category : 'VectorGraphics-Cairo-Pattern',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Pattern'
}

{ #category : 'skeleton - unit 1.5' }
VGCairoSurfacePattern class >> surface: arg1 [
	^ self notYetImplementedIn: '1.5' selector: #surface:
]
