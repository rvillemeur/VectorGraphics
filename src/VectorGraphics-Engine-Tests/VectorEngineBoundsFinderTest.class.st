"
I hold the contract of VectorEngineBoundsFinder: that it measures the same area the painting engine covers, for straight and curved paths and under either anti-aliasing engine, that it writes neither pixels nor buffers, and that it mirrors the engine it stands in for rather than its own class defaults.

My fixtures draw the same commands twice, once through a painting engine and once through a finder built on a form of the same size, and compare `morphBoundsAfterDraw`.
"
Class {
	#name : 'VectorEngineBoundsFinderTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Engine-Tests-Tests',
	#package : 'VectorGraphics-Engine-Tests',
	#tag : 'Tests'
}

{ #category : 'running' }
VectorEngineBoundsFinderTest >> boundsOf: aSelector measuredBy: anEngineClass [

	| painting finder |
	painting := anEngineClass onForm: self newWhiteForm.
	finder := VectorEngineBoundsFinder
		          onForm: self newWhiteForm
		          mirroring: painting.
	self perform: aSelector with: painting.
	self perform: aSelector with: finder.
	^ painting morphBoundsAfterDraw -> finder morphBoundsAfterDraw
]

{ #category : 'running' }
VectorEngineBoundsFinderTest >> drawCircleOn: anEngine [

	anEngine
		strokeWidth: 2.0
		color: Color black
		fillColor: Color red
		do: [ :each | each abs_CircleCenter: 30 @ 30 radius: 20 ]
]

{ #category : 'running' }
VectorEngineBoundsFinderTest >> drawCubicBezierOn: anEngine [

	anEngine
		strokeWidth: 3.0
		color: Color black
		do: [ :each |
			each abs_MoveTo: 5 @ 50.
			each
				abs_CubicBezierTo: 55 @ 50
				control1: 15 @ 5
				control2: 45 @ 95 ]
]

{ #category : 'running' }
VectorEngineBoundsFinderTest >> drawMarginSensitiveTriangleOn: anEngine [

	"Fractional corners and a stroke width of 2.8 are a case where the whole-pixel and
	the sub-pixel margins truncate to different integers, so a finder that mirrors the
	wrong engine measures the wrong box. Most widths hide that."

	anEngine
		strokeWidth: 2.8
		color: Color black
		fillColor: Color blue
		do: [ :each |
			each abs_MoveTo: 5.3 @ 5.3.
			each abs_LineTo: 55.4 @ 5.3.
			each abs_LineTo: 30.2 @ 55.7.
			each do_ClosePath ]
]

{ #category : 'running' }
VectorEngineBoundsFinderTest >> drawTriangleOn: anEngine [

	anEngine
		strokeWidth: 1.0
		color: Color black
		fillColor: Color blue
		do: [ :each |
			each abs_MoveTo: 5 @ 5.
			each abs_LineTo: 55 @ 5.
			each abs_LineTo: 30 @ 55.
			each do_ClosePath ]
]

{ #category : 'running' }
VectorEngineBoundsFinderTest >> newWhiteForm [

	| form |
	form := Form extent: 60 @ 60 depth: 32.
	form fillColor: Color white.
	^ form
]

{ #category : 'tests' }
VectorEngineBoundsFinderTest >> testAllocatesNoBuffer [

	| finder allocated |
	finder := VectorEngineBoundsFinder
		          onForm: self newWhiteForm
		          mirroring: (VectorEngineWholePixel onForm: self newWhiteForm).
	self drawTriangleOn: finder.
	allocated := #( #alphaMask #edgeCounts #morphIds ) select: [ :each |
		             (finder instVarNamed: each) notNil ].
	self assert: allocated isEmpty description: allocated printString
]

{ #category : 'tests' }
VectorEngineBoundsFinderTest >> testAnswersNoHitTest [

	| finder |
	finder := VectorEngineBoundsFinder
		          onForm: self newWhiteForm
		          mirroring: (VectorEngineWholePixel onForm: self newWhiteForm).
	self drawTriangleOn: finder.
	self deny: (finder morph: nil isAtPoint: 30 @ 20)
]

{ #category : 'tests' }
VectorEngineBoundsFinderTest >> testMeasuresWhatTheSubPixelEngineCovers [

	| wrong |
	wrong := #( #drawTriangleOn: #drawMarginSensitiveTriangleOn: #drawCubicBezierOn: #drawCircleOn: )
		         reject: [ :each |
			         | both |
			         both := self
				                 boundsOf: each
				                 measuredBy: VectorEngineSubPixel.
			         both key = both value ].
	self assert: wrong isEmpty description: wrong printString
]

{ #category : 'tests' }
VectorEngineBoundsFinderTest >> testMeasuresWhatTheWholePixelEngineCoversForEveryKindOfPath [

	| wrong |
	wrong := #( #drawTriangleOn: #drawCubicBezierOn: #drawCircleOn: ) reject: [
		         :each |
		         | both |
		         both := self boundsOf: each measuredBy: VectorEngineWholePixel.
		         both key = both value ].
	self assert: wrong isEmpty description: wrong printString
]

{ #category : 'tests' }
VectorEngineBoundsFinderTest >> testTheTwoEnginesAreMeasuredDifferently [

	"The margin #finishPath: adds comes from the anti-aliasing width and the sub-pixel
	delta, so mirroring the wrong engine would be a silent error. This test says the
	two cases really differ, which is what makes the test above worth running."

	| whole sub |
	whole := self
		         boundsOf: #drawMarginSensitiveTriangleOn:
		         measuredBy: VectorEngineWholePixel.
	sub := self
		       boundsOf: #drawMarginSensitiveTriangleOn:
		       measuredBy: VectorEngineSubPixel.
	self deny: whole value = sub value
]

{ #category : 'tests' }
VectorEngineBoundsFinderTest >> testWritesNoPixel [

	| form finder before |
	form := self newWhiteForm.
	finder := VectorEngineBoundsFinder
		          onForm: form
		          mirroring: (VectorEngineWholePixel onForm: self newWhiteForm).
	before := form bits copy.
	self drawTriangleOn: finder.
	self assert: form bits equals: before
]
