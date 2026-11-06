"
I hold the path state of `VectorEngineAbstract` — the part of an engine that has nothing to do with pixels.

An engine remembers four coordinates while a path is built: the first point of the subpath, the current point, and the previous call's point and control point. The tests here state who writes them: `moveTo` sets all of the path state, a second `moveTo` moves the first point with it, `lineTo` moves only the current point, a relative line adds to the current point rather than replacing it, `closePath` brings the current point back to the first one, and initialising a path clears the lot.

One test is a gate rather than a fact about a drawing: `testTheEngineKeepsNoMorphIdentityState` fails if the morph-id buffer and its accessors come back into the hierarchy. They were a feature of the Cuis original that no Pharo image could fill, and `doc/DEFECTS.md` records why they went.
"
Class {
	#name : 'VectorEngineAbstractTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Engine-Tests-Tests',
	#package : 'VectorGraphics-Engine-Tests',
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

{ #category : 'tests - state' }
VectorEngineAbstractTest >> testTheEngineKeepsNoMorphIdentityState [
	"The hit test read a buffer of morph ids that no Pharo image could ever fill, because nothing
	answers morphId. Every painted pixel paid for the buffer, so the state must not come back."

	self assertEmpty: (VectorEngineAbstract allInstVarNames select: [ :each |
			 each asLowercase includesSubstring: 'morphid' ]).
	self assertEmpty: (VectorEngineAbstract withAllSubclasses flatCollect: [ :each |
			 (each selectors select: [ :selector |
				  #( currentMorph: clippingMorph: morph:isAtPoint: pvtAllocateMorphIds )
					  includes: selector ]) collect: [ :selector |
				 each name , '>>' , selector ] ])
]
