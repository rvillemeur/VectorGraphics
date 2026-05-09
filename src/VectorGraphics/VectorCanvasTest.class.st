Class {
	#name : 'VectorCanvasTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Tests',
	#package : 'VectorGraphics',
	#tag : 'Tests'
}

{ #category : 'helpers' }
VectorCanvasTest >> makeCanvas [

	| form |
	form := Form extent: 60 @ 60 depth: 32.
	form fillColor: Color white.
	^ VectorCanvas onForm: form
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
