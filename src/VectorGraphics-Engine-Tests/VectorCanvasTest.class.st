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
