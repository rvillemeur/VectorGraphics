Class {
	#name : 'PathCommandRunOnTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Tests',
	#package : 'VectorGraphics',
	#tag : 'Tests'
}

{ #category : 'helpers' }
PathCommandRunOnTest >> canvas [

	^ RecordingCanvas new
]

{ #category : 'helpers' }
PathCommandRunOnTest >> makeAbsolute: aCommandClass points: anArray [

	| cmd |
	cmd := aCommandClass new.
	cmd instVarNamed: 'coordinatesAreRelative' put: false.
	^ cmd
]

{ #category : 'tests' }
PathCommandRunOnTest >> testArcRunOn [

	| cmd canvas rs xr pts arcs inc |
	rs := OrderedCollection with: 10 @ 5.
	xr := OrderedCollection with: 0.
	pts := OrderedCollection with: 100 @ 200.
	arcs := OrderedCollection with: false.
	inc := OrderedCollection with: true.
	cmd := PathArcCommand new.
	cmd instVarNamed: 'coordinatesAreRelative' put: false.
	cmd instVarNamed: 'rs' put: rs.
	cmd instVarNamed: 'xAxisRotations' put: xr.
	cmd instVarNamed: 'toPoints' put: pts.
	cmd instVarNamed: 'doLargerArcs' put: arcs.
	cmd instVarNamed: 'useIncreasingAngless' put: inc.
	canvas := self canvas.
	cmd runOn: canvas.
	self assert: canvas lastSelector equals: #multiArc:rs:xAxisRotations:toPoints:doLargerArcs:useIncreasingAngless:.
	self assert: (canvas lastArguments at: 1) equals: false.
	self assert: (canvas lastArguments at: 2) equals: rs.
	self assert: (canvas lastArguments at: 4) equals: pts
]

{ #category : 'tests' }
PathCommandRunOnTest >> testClosePathRunOn [

	| cmd canvas |
	cmd := PathCloseCommand new.
	cmd instVarNamed: 'coordinatesAreRelative' put: false.
	canvas := self canvas.
	cmd runOn: canvas.
	self assert: canvas lastSelector equals: #closePath.
	self assert: canvas lastArguments isEmpty
]

{ #category : 'tests' }
PathCommandRunOnTest >> testCubicCurveToRunOn [

	| cmd canvas to c1 c2 |
	to := OrderedCollection with: 50 @ 60.
	c1 := OrderedCollection with: 10 @ 20.
	c2 := OrderedCollection with: 30 @ 40.
	cmd := PathCurveToCommand new.
	cmd instVarNamed: 'coordinatesAreRelative' put: true.
	cmd instVarNamed: 'toPoints' put: to.
	cmd instVarNamed: 'control1Points' put: c1.
	cmd instVarNamed: 'control2Points' put: c2.
	canvas := self canvas.
	cmd runOn: canvas.
	self assert: canvas lastSelector equals: #multiCurveTo:toPoints:control1Points:control2Points:.
	self assert: (canvas lastArguments at: 1) equals: true.
	self assert: (canvas lastArguments at: 2) equals: to.
	self assert: (canvas lastArguments at: 3) equals: c1.
	self assert: (canvas lastArguments at: 4) equals: c2
]

{ #category : 'tests' }
PathCommandRunOnTest >> testHorizontalLineRunOn [

	| cmd canvas xs |
	xs := #( 10 20 30 ).
	cmd := PathLineToHCommand new.
	cmd instVarNamed: 'coordinatesAreRelative' put: false.
	cmd instVarNamed: 'xs' put: xs.
	canvas := self canvas.
	cmd runOn: canvas.
	self assert: canvas lastSelector equals: #multiLineTo:xs:.
	self assert: (canvas lastArguments at: 1) equals: false.
	self assert: (canvas lastArguments at: 2) equals: xs
]

{ #category : 'tests' }
PathCommandRunOnTest >> testLineToRelativeRunOn [

	| cmd canvas |
	cmd := PathLineToCommand new.
	cmd instVarNamed: 'coordinatesAreRelative' put: true.
	cmd instVarNamed: 'points' put: (Array with: 5 @ 5).
	canvas := self canvas.
	cmd runOn: canvas.
	self assert: (canvas lastArguments at: 1) equals: true
]

{ #category : 'tests' }
PathCommandRunOnTest >> testLineToRunOn [

	| cmd canvas pts |
	pts := Array with: 10 @ 20 with: 30 @ 40.
	cmd := PathLineToCommand new.
	cmd instVarNamed: 'coordinatesAreRelative' put: false.
	cmd instVarNamed: 'points' put: pts.
	canvas := self canvas.
	cmd runOn: canvas.
	self assert: canvas lastSelector equals: #multiLineTo:points:.
	self assert: (canvas lastArguments at: 1) equals: false.
	self assert: (canvas lastArguments at: 2) equals: pts
]

{ #category : 'tests' }
PathCommandRunOnTest >> testQuadraticCurveSmoothRunOn [

	| cmd canvas pts |
	pts := OrderedCollection with: 40 @ 50.
	cmd := PathQuadraticCurveToSmoothCommand new.
	cmd instVarNamed: 'coordinatesAreRelative' put: false.
	cmd instVarNamed: 'toPoints' put: pts.
	canvas := self canvas.
	cmd runOn: canvas.
	self assert: canvas lastSelector equals: #multiQuadraticCurveToSmooth:toPoints:.
	self assert: (canvas lastArguments at: 1) equals: false.
	self assert: (canvas lastArguments at: 2) equals: pts
]

{ #category : 'tests' }
PathCommandRunOnTest >> testSmoothCubicCurveRunOn [

	| cmd canvas to c2 |
	to := OrderedCollection with: 70 @ 80.
	c2 := OrderedCollection with: 50 @ 60.
	cmd := PathCurveToSmoothCommand new.
	cmd instVarNamed: 'coordinatesAreRelative' put: true.
	cmd instVarNamed: 'toPoints' put: to.
	cmd instVarNamed: 'control2Points' put: c2.
	canvas := self canvas.
	cmd runOn: canvas.
	self assert: canvas lastSelector equals: #multiCurveToSmooth:toPoints:control2Points:.
	self assert: (canvas lastArguments at: 1) equals: true.
	self assert: (canvas lastArguments at: 2) equals: to.
	self assert: (canvas lastArguments at: 3) equals: c2
]

{ #category : 'tests' }
PathCommandRunOnTest >> testVerticalLineRunOn [

	| cmd canvas ys |
	ys := #( 100 200 ).
	cmd := PathLineToVCommand new.
	cmd instVarNamed: 'coordinatesAreRelative' put: true.
	cmd instVarNamed: 'ys' put: ys.
	canvas := self canvas.
	cmd runOn: canvas.
	self assert: canvas lastSelector equals: #multiLineTo:ys:.
	self assert: (canvas lastArguments at: 1) equals: true.
	self assert: (canvas lastArguments at: 2) equals: ys
]
