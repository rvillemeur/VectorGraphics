"
I hold `VectorCanvas` to the three promises it makes to the code that draws through it.

The first is the destination: a canvas is built on a 32-bit `Form`, answers that same form back, and refuses a form of any other depth — the engines write a word per pixel, so a shallower form would be corrupted rather than drawn on. The second is that the canvas is an `Object` and inherits nothing of Morphic; it stood in for `Canvas` in the Cuis original and does not here, and the test says so rather than leaving a reader to infer it from the class definition.

The third is measuring. Asking the canvas for the bounds of a drawing swaps the painting engine for `VectorEngineBoundsFinder`, so the tests here state that the bounds answered are the bounds the same drawing really covers, that nothing is painted while measuring, that a second measurement forgets the first, that the measurement follows the canvas into sub-pixel anti-aliasing, and that the painting engine is the one in place afterwards.

The remaining tests only drive the path and paint protocol and assert that it does not raise — thin, and deliberately so: what the pixels look like is held by the engine tests and the conformance corpus, not here.
"
Class {
	#name : 'VectorCanvasTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Engine-Tests-Tests',
	#package : 'VectorGraphics-Engine-Tests',
	#tag : 'Tests'
}

{ #category : 'running' }
VectorCanvasTest >> drawTriangleOn: aCanvas [

	aCanvas
		strokeWidth: 1.0
		color: Color black
		fillColor: Color blue
		do: [
			aCanvas moveToX: 5 y: 5.
			aCanvas lineToX: 55 y: 5.
			aCanvas lineToX: 30 y: 55.
			aCanvas closePath ]
]

{ #category : 'helpers' }
VectorCanvasTest >> makeCanvas [

	| form |
	form := Form extent: 60 @ 60 depth: 32.
	form fillColor: Color white.
	^ VectorCanvas onForm: form
]

{ #category : 'running' }
VectorCanvasTest >> newWhiteForm [

	| form |
	form := Form extent: 60 @ 60 depth: 32.
	form fillColor: Color white.
	^ form
]

{ #category : 'tests' }
VectorCanvasTest >> testClosePathDoesNotError [

	| canvas |
	canvas := self makeCanvas.
	canvas strokeWidth: 1.0 color: Color black do: [
		canvas moveToX: 10 y: 10.
		canvas lineToX: 50 y: 10.
		canvas lineToX: 50 y: 50.
		canvas closePath ].
	self assert: true
]

{ #category : 'tests' }
VectorCanvasTest >> testEngineIsCreatedOnForm [

	| canvas |
	canvas := self makeCanvas.
	self assert: canvas engine notNil
]

{ #category : 'tests' }
VectorCanvasTest >> testFillColorDoesNotError [

	| canvas |
	canvas := self makeCanvas.
	canvas fillColor: Color red do: [
		canvas moveToX: 5 y: 5.
		canvas lineToX: 55 y: 5.
		canvas lineToX: 55 y: 55.
		canvas lineToX: 5 y: 55.
		canvas closePath ].
	self assert: true
]

{ #category : 'tests' }
VectorCanvasTest >> testMeasuredMorphBoundsEqualTheBoundsTheDrawingCovers [

	| measuring painting |
	measuring := VectorCanvas onForm: self newWhiteForm.
	painting := VectorCanvas onForm: self newWhiteForm.
	measuring updatingMorphBoundsDo: [ self drawTriangleOn: measuring ].
	self drawTriangleOn: painting.
	self
		assert: measuring measuredMorphBounds
		equals: painting engine morphBoundsAfterDraw
]

{ #category : 'tests' }
VectorCanvasTest >> testMeasuringFollowsTheCanvasToSubPixelAntiAliasing [

	| measuring painting |
	measuring := VectorCanvas onForm: self newWhiteForm.
	painting := VectorCanvas onForm: self newWhiteForm.
	measuring doSubPixelAntiAliasing.
	painting doSubPixelAntiAliasing.
	measuring updatingMorphBoundsDo: [ self drawTriangleOn: measuring ].
	self drawTriangleOn: painting.
	self
		assert: measuring measuredMorphBounds
		equals: painting engine morphBoundsAfterDraw
]

{ #category : 'tests' }
VectorCanvasTest >> testMeasuringMorphBoundsPaintsNothing [

	| form canvas before |
	form := self newWhiteForm.
	canvas := VectorCanvas onForm: form.
	before := form bits copy.
	canvas updatingMorphBoundsDo: [ self drawTriangleOn: canvas ].
	self assert: form bits equals: before
]

{ #category : 'tests' }
VectorCanvasTest >> testMeasuringTwiceForgetsTheFirstDrawing [

	| canvas first second |
	canvas := VectorCanvas onForm: self newWhiteForm.
	canvas updatingMorphBoundsDo: [
		canvas line: 2 @ 2 to: 10 @ 10 width: 1.0 color: Color black ].
	first := canvas measuredMorphBounds.
	canvas updatingMorphBoundsDo: [
		canvas line: 40 @ 40 to: 50 @ 50 width: 1.0 color: Color black ].
	second := canvas measuredMorphBounds.
	self deny: (second containsRect: first)
]

{ #category : 'tests' }
VectorCanvasTest >> testMoveToLineToDoesNotError [

	| canvas |
	canvas := self makeCanvas.
	canvas strokeWidth: 2.0 color: Color black do: [
		canvas moveToX: 10 y: 20.
		canvas lineToX: 40 y: 20 ].
	self assert: true
]

{ #category : 'tests' }
VectorCanvasTest >> testRequires32BitForm [

	| form |
	form := Form extent: 10 @ 10 depth: 8.
	self
		should: [ VectorCanvas onForm: form ]
		raise: Error
]

{ #category : 'tests' }
VectorCanvasTest >> testStrokeAndFillDoesNotError [

	| canvas |
	canvas := self makeCanvas.
	canvas
		strokeWidth: 1.0
		color: Color black
		fillColor: Color blue
		do: [
			canvas moveToX: 5 y: 5.
			canvas lineToX: 55 y: 5.
			canvas lineToX: 30 y: 55.
			canvas closePath ].
	self assert: true
]

{ #category : 'tests' }
VectorCanvasTest >> testTheCanvasAnswersTheFormItDrawsOn [
	"Reading the pixels back is the normal end of a drawing, so the canvas hands out the form
	it was given rather than leaving the caller to keep its own reference."

	| target canvas |
	target := Form extent: 8 @ 8 depth: 32.
	canvas := VectorCanvas onForm: target.
	self assert: canvas form identicalTo: target
]

{ #category : 'tests' }
VectorCanvasTest >> testTheCanvasIsIndependentOfMorphic [
	"In Cuis this class stood in for Canvas and was handed to Morphic. Morphic is not a target
	of this project: the canvas is independent, and inheriting from Canvas only promised a
	protocol it does not implement."

	self assert: VectorCanvas superclass identicalTo: Object.
	self
		deny: (VectorCanvas allSuperclasses anySatisfy: [ :each | each name = #Canvas ])
		description: 'the canvas must not inherit a Morphic protocol it cannot honour'
]

{ #category : 'tests' }
VectorCanvasTest >> testThePaintingEngineComesBackAfterMeasuring [

	| form canvas painting |
	form := self newWhiteForm.
	canvas := VectorCanvas onForm: form.
	painting := canvas engine.
	canvas updatingMorphBoundsDo: [ self drawTriangleOn: canvas ].
	self assert: canvas engine identicalTo: painting.
	self drawTriangleOn: canvas.
	self deny: (form pixelValueAt: 30 @ 30) = (Color white pixelValueForDepth: 32)
]
