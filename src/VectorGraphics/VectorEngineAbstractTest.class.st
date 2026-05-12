Class {
	#name : 'VectorEngineAbstractTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Tests',
	#package : 'VectorGraphics',
	#tag : 'Tests'
}

{ #category : 'helpers' }
VectorEngineAbstractTest >> engineOnSmallForm [

	^ VectorEngineWholePixel onForm: (Form extent: 50 @ 50 depth: 32)
]

{ #category : 'tests' }
VectorEngineAbstractTest >> testClosePathRestoresFirstPoint [

	| engine capturedX capturedY |
	engine := self engineOnSmallForm.
	engine strokeWidth: 2.0 color: Color black do: [
		engine abs_MoveTo: 10 @ 20.
		engine abs_LineTo: 40 @ 45.
		engine do_ClosePath.
		capturedX := engine instVarNamed: 'previousCallX'.
		capturedY := engine instVarNamed: 'previousCallY' ].
	self assert: capturedX equals: 10.
	self assert: capturedY equals: 20
]

{ #category : 'tests' }
VectorEngineAbstractTest >> testInitializePathResetsState [

	| engine pathFirstX pathFirstY pathCurrentX pathCurrentY prevX prevY |
	engine := self engineOnSmallForm.
	engine strokeWidth: 2.0 color: Color black do: [
		engine abs_MoveTo: 33 @ 44.
		engine initializePath.
		pathFirstX := engine instVarNamed: 'pathFirstX'.
		pathFirstY := engine instVarNamed: 'pathFirstY'.
		pathCurrentX := engine instVarNamed: 'pathCurrentX'.
		pathCurrentY := engine instVarNamed: 'pathCurrentY'.
		prevX := engine instVarNamed: 'previousCallX'.
		prevY := engine instVarNamed: 'previousCallY' ].
	self assert: pathFirstX equals: 0.
	self assert: pathFirstY equals: 0.
	self assert: pathCurrentX equals: 0.0.
	self assert: pathCurrentY equals: 0.0.
	self assert: prevX equals: 0.0.
	self assert: prevY equals: 0.0
]

{ #category : 'tests' }
VectorEngineAbstractTest >> testLineToUpdatesCurrentPoint [

	| engine capturedX capturedY |
	engine := self engineOnSmallForm.
	engine strokeWidth: 2.0 color: Color black do: [
		engine abs_MoveTo: 5 @ 5.
		engine abs_LineTo: 40 @ 30.
		capturedX := engine instVarNamed: 'pathCurrentX'.
		capturedY := engine instVarNamed: 'pathCurrentY' ].
	self assert: capturedX equals: 40.
	self assert: capturedY equals: 30
]

{ #category : 'tests' }
VectorEngineAbstractTest >> testMoveToSetsAllPathState [

	| engine pathFirstX pathFirstY pathCurrentX pathCurrentY prevX prevY |
	engine := self engineOnSmallForm.
	engine strokeWidth: 2.0 color: Color black do: [
		engine abs_MoveTo: 10 @ 20.
		pathFirstX := engine instVarNamed: 'pathFirstX'.
		pathFirstY := engine instVarNamed: 'pathFirstY'.
		pathCurrentX := engine instVarNamed: 'pathCurrentX'.
		pathCurrentY := engine instVarNamed: 'pathCurrentY'.
		prevX := engine instVarNamed: 'previousCallX'.
		prevY := engine instVarNamed: 'previousCallY' ].
	self assert: pathFirstX equals: 10.
	self assert: pathFirstY equals: 20.
	self assert: pathCurrentX equals: 10.
	self assert: pathCurrentY equals: 20.
	self assert: prevX equals: 10.
	self assert: prevY equals: 20
]

{ #category : 'tests' }
VectorEngineAbstractTest >> testMultipleMoveToUpdatesFirstPoint [

	| engine capturedFirstX capturedFirstY |
	engine := self engineOnSmallForm.
	engine strokeWidth: 2.0 color: Color black do: [
		engine abs_MoveTo: 10 @ 20.
		engine abs_LineTo: 30 @ 30.
		engine abs_MoveTo: 45 @ 48.
		capturedFirstX := engine instVarNamed: 'pathFirstX'.
		capturedFirstY := engine instVarNamed: 'pathFirstY' ].
	self assert: capturedFirstX equals: 45.
	self assert: capturedFirstY equals: 48
]

{ #category : 'tests' }
VectorEngineAbstractTest >> testRelativeLineAddsToCurrentPoint [

	| engine capturedX capturedY |
	engine := self engineOnSmallForm.
	engine strokeWidth: 2.0 color: Color black do: [
		engine abs_MoveTo: 10 @ 10.
		engine rel_LineTo: 20 @ 15.
		capturedX := engine instVarNamed: 'pathCurrentX'.
		capturedY := engine instVarNamed: 'pathCurrentY' ].
	self assert: capturedX equals: 30.
	self assert: capturedY equals: 25
]
