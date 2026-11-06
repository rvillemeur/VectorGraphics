"
I hold the two constructors of `PathQuadraticCurveToCommand` to the one thing they disagree about: `toPoints:controlPoints:` builds an absolute command and `toRelativePoints:controlPoints:` a relative one.

A quadratic curve carries two collections — the end points and the control points — and both constructors take them in the same order, so the flag is the only difference a test can state here.

The collections themselves are held in `PathCommandRunOnTest`, where they are asserted as the canvas receives them from `runOn:`. Nothing here reaches inside the object.
"
Class {
	#name : 'PathQuadraticCurveCommandTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Paths-Tests-Tests',
	#package : 'VectorGraphics-Paths-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
PathQuadraticCurveCommandTest >> testAbsolutePointsNotRelative [
	| cmd |
	cmd := PathQuadraticCurveToCommand new
		toPoints: { 50 @ 75 }
		controlPoints: { 25 @ 25 }.
	self deny: cmd coordinatesAreRelative
]

{ #category : 'tests' }
PathQuadraticCurveCommandTest >> testRelativePointsIsRelative [
	| cmd |
	cmd := PathQuadraticCurveToCommand new
		toRelativePoints: { 50 @ 75 }
		controlPoints: { 25 @ 25 }.
	self assert: cmd coordinatesAreRelative
]
