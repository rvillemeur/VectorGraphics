Class {
	#name : 'PathCommandParseTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Tests',
	#package : 'VectorGraphics',
	#tag : 'Tests'
}

{ #category : 'tests' }
PathCommandParseTest >> testArcAbsoluteParse [

	| cmd stream |
	stream := MockNumberStream on: #( 10 5 0 1 0 100 200 ).
	cmd := PathCommand from: $A stream: stream.
	self assert: cmd coordinatesAreRelative equals: false.
	self assert: (cmd instVarNamed: 'rs') asArray equals: { 10 @ 5 }.
	self assert: (cmd instVarNamed: 'toPoints') asArray equals: { 100 @ 200 }.
	self assert: (cmd instVarNamed: 'doLargerArcs') asArray equals: { true }.
	self assert: (cmd instVarNamed: 'useIncreasingAngless') asArray equals: { false }
]

{ #category : 'tests' }
PathCommandParseTest >> testArcRelativeParse [

	| cmd stream |
	stream := MockNumberStream on: #( 10 5 0 0 1 100 200 ).
	cmd := PathCommand from: $a stream: stream.
	self assert: cmd coordinatesAreRelative equals: true.
	self assert: (cmd instVarNamed: 'doLargerArcs') asArray equals: { false }.
	self assert: (cmd instVarNamed: 'useIncreasingAngless') asArray equals: { true }
]

{ #category : 'tests' }
PathCommandParseTest >> testClosePathParse [

	| cmd stream |
	stream := MockNumberStream on: #(  ).
	cmd := PathCommand from: $Z stream: stream.
	self assert: (cmd isKindOf: PathCloseCommand).
	self assert: cmd coordinatesAreRelative equals: false
]

{ #category : 'tests' }
PathCommandParseTest >> testCubicCurveToAbsoluteParse [

	| cmd stream |
	stream := MockNumberStream on: #( 1 2 3 4 5 6 ).
	cmd := PathCommand from: $C stream: stream.
	self assert: cmd coordinatesAreRelative equals: false.
	self assert: (cmd instVarNamed: 'toPoints') asArray equals: { 5 @ 6 }.
	self assert: (cmd instVarNamed: 'control1Points') asArray equals: { 1 @ 2 }.
	self assert: (cmd instVarNamed: 'control2Points') asArray equals: { 3 @ 4 }
]

{ #category : 'tests' }
PathCommandParseTest >> testCubicCurveToRelativeParse [

	| cmd stream |
	stream := MockNumberStream on: #( 1 2 3 4 5 6 ).
	cmd := PathCommand from: $c stream: stream.
	self assert: cmd coordinatesAreRelative equals: true.
	self assert: (cmd instVarNamed: 'toPoints') asArray equals: { 5 @ 6 }
]

{ #category : 'tests' }
PathCommandParseTest >> testHorizontalLineAbsoluteParse [

	| cmd stream |
	stream := MockNumberStream on: #( 42 ).
	cmd := PathCommand from: $H stream: stream.
	self assert: cmd coordinatesAreRelative equals: false.
	self assert: (cmd instVarNamed: 'xs') asArray equals: #( 42 )
]

{ #category : 'tests' }
PathCommandParseTest >> testHorizontalLineMultipleValuesParse [

	| cmd stream |
	stream := MockNumberStream on: #( 10 20 30 ).
	cmd := PathCommand from: $H stream: stream.
	self assert: (cmd instVarNamed: 'xs') asArray equals: #( 10 20 30 )
]

{ #category : 'tests' }
PathCommandParseTest >> testLineToAbsoluteParse [

	| cmd stream |
	stream := MockNumberStream on: #( 5 15 ).
	cmd := PathCommand from: $L stream: stream.
	self assert: cmd coordinatesAreRelative equals: false.
	self assert: (cmd instVarNamed: 'points') asArray equals: { 5 @ 15 }
]

{ #category : 'tests' }
PathCommandParseTest >> testLineToMultiplePointsParse [

	| cmd stream |
	stream := MockNumberStream on: #( 1 2 3 4 ).
	cmd := PathCommand from: $L stream: stream.
	self assert: (cmd instVarNamed: 'points') asArray equals: { 1 @ 2. 3 @ 4 }
]

{ #category : 'tests' }
PathCommandParseTest >> testLineToRelativeParse [

	| cmd stream |
	stream := MockNumberStream on: #( 5 15 ).
	cmd := PathCommand from: $l stream: stream.
	self assert: cmd coordinatesAreRelative equals: true.
	self assert: (cmd instVarNamed: 'points') asArray equals: { 5 @ 15 }
]

{ #category : 'tests' }
PathCommandParseTest >> testMoveToAbsoluteParse [

	| cmd stream |
	stream := MockNumberStream on: #( 10 20 ).
	cmd := PathCommand from: $M stream: stream.
	self assert: cmd coordinatesAreRelative equals: false.
	self assert: (cmd instVarNamed: 'points') asArray equals: { 10 @ 20 }
]

{ #category : 'tests' }
PathCommandParseTest >> testMoveToRelativeParse [

	| cmd stream |
	stream := MockNumberStream on: #( 10 20 ).
	cmd := PathCommand from: $m stream: stream.
	self assert: cmd coordinatesAreRelative equals: true.
	self assert: (cmd instVarNamed: 'points') asArray equals: { 10 @ 20 }
]

{ #category : 'tests' }
PathCommandParseTest >> testQuadraticCurveToAbsoluteParse [

	| cmd stream |
	stream := MockNumberStream on: #( 1 2 3 4 ).
	cmd := PathCommand from: $Q stream: stream.
	self assert: cmd coordinatesAreRelative equals: false.
	self assert: (cmd instVarNamed: 'toPoints') asArray equals: { 3 @ 4 }.
	self assert: (cmd instVarNamed: 'controlPoints') asArray equals: { 1 @ 2 }
]

{ #category : 'tests' }
PathCommandParseTest >> testQuadraticCurveToSmoothAbsoluteParse [

	| cmd stream |
	stream := MockNumberStream on: #( 7 8 ).
	cmd := PathCommand from: $T stream: stream.
	self assert: cmd coordinatesAreRelative equals: false.
	self assert: (cmd instVarNamed: 'toPoints') asArray equals: { 7 @ 8 }
]

{ #category : 'tests' }
PathCommandParseTest >> testSmoothCubicCurveToAbsoluteParse [

	| cmd stream |
	stream := MockNumberStream on: #( 1 2 3 4 ).
	cmd := PathCommand from: $S stream: stream.
	self assert: cmd coordinatesAreRelative equals: false.
	self assert: (cmd instVarNamed: 'toPoints') asArray equals: { 3 @ 4 }.
	self assert: (cmd instVarNamed: 'control2Points') asArray equals: { 1 @ 2 }
]

{ #category : 'tests' }
PathCommandParseTest >> testVerticalLineAbsoluteParse [

	| cmd stream |
	stream := MockNumberStream on: #( 77 ).
	cmd := PathCommand from: $V stream: stream.
	self assert: cmd coordinatesAreRelative equals: false.
	self assert: (cmd instVarNamed: 'ys') asArray equals: #( 77 )
]

{ #category : 'tests' }
PathCommandParseTest >> testVerticalLineRelativeParse [

	| cmd stream |
	stream := MockNumberStream on: #( 77 ).
	cmd := PathCommand from: $v stream: stream.
	self assert: cmd coordinatesAreRelative equals: true.
	self assert: (cmd instVarNamed: 'ys') asArray equals: #( 77 )
]
