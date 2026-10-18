"
I hold the one-click examples for the VectorGraphics Cairo-compatible context. My examples rebuild their object on every call and assert nothing: open one from the browser, inspect the result, and read the Skeletons tab to see which selectors the context still owes and which unit of VECTORCANVAS-PLAN.md owes them.
"
Class {
	#name : 'VGCairoContextExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Cairo-Examples',
	#package : 'VectorGraphics-Cairo-Examples'
}

{ #category : 'examples' }
VGCairoContextExamples class >> contextOnAnImageSurface [
	<sampleInstance>
	"A context over an image surface, the pair every drawing goes through. Unit 1.1 owns
	 VGCairoImageSurface class >> #extent:, so the surface is built reflectively until then."

	| surface |
	surface := VGCairoImageSurface basicNew.
	^ VGCairoContext newFor: surface
]

{ #category : 'examples' }
VGCairoContextExamples class >> linearGradientPatternClass [
	<sampleInstance>
	"The pattern classes are the third of the three Cairo objects AeCanvas drives. Inspecting the
	 class shows the constructors unit 1.5 owes."

	^ VGCairoLinearGradientPattern
]
