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
