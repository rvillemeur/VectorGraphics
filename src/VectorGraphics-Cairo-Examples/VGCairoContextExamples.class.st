"
I hold the one-click examples for the VectorGraphics Cairo-compatible context. My examples rebuild their object on every call and assert nothing: open one from the browser, inspect the result, and read the Skeletons tab to see which selectors the context still owes and which unit of VECTORCANVAS-PLAN.md owes them.
"
Class {
	#name : 'VGCairoContextExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Cairo-Examples-Examples',
	#package : 'VectorGraphics-Cairo-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGCairoContextExamples class >> contextOnAnImageSurface [
	<sampleInstance>
	"A context over an image surface, the pair every drawing goes through."
	^ (VGCairoImageSurface extent: 64 @ 64) newContext
]

{ #category : 'examples' }
VGCairoContextExamples class >> linearGradientPatternClass [
	<sampleInstance>
	"The pattern classes are the third of the three Cairo objects AeCanvas drives. Inspecting the
	 class shows the constructors unit 1.5 owes."

	^ VGCairoLinearGradientPattern
]

{ #category : 'examples' }
VGCairoContextExamples class >> transformedContextWithASavedState [
	<sampleInstance>
	"A context whose current matrix has been moved, turned and stretched, with one state pushed
	 underneath it, so the state stack and the current transformation are both visible."
	| context |
	context := (VGCairoImageSurface extent: 64 @ 64) newContext.
	context state fillRule: #evenOdd.
	context saveState.
	context
		translateBy: 32 @ 32;
		rotateByRadians: Float pi / 6;
		scaleBy: 1.8 @ 0.6.
	context state source: Color red.
	^ context
]
