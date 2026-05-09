Class {
	#name : 'PathQuadraticCurveCommandTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Tests',
	#package : 'VectorGraphics',
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

{ #category : 'tests' }
PathQuadraticCurveCommandTest >> testToPointsStoresEndPoints [
	| cmd log |
	cmd := PathQuadraticCurveToCommand new
		toPoints: { 10 @ 20. 30 @ 40 }
		controlPoints: { 5 @ 5. 15 @ 15 }.
	log := OrderedCollection new.
	cmd privatePointsDo: [ :pt | log add: pt ].
	self assert: log size equals: 2.
	self assert: log first equals: 10 @ 20.
	self assert: log last equals: 30 @ 40
]

{ #category : 'tests' }
PathQuadraticCurveCommandTest >> testToRelativePointsStoresEndPoints [
	| cmd log |
	cmd := PathQuadraticCurveToCommand new
		toRelativePoints: { 3 @ 4 }
		controlPoints: { 1 @ 2 }.
	log := OrderedCollection new.
	cmd privatePointsDo: [ :pt | log add: pt ].
	self assert: log size equals: 1.
	self assert: log first equals: 3 @ 4
]
