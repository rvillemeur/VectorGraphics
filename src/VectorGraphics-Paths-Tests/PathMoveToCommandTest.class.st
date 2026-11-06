Class {
	#name : 'PathMoveToCommandTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Paths-Tests-Tests',
	#package : 'VectorGraphics-Paths-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
PathMoveToCommandTest >> testAbsoluteToPointIsNotRelative [
	| cmd |
	cmd := PathMoveToCommand new toPoint: 10 @ 20.
	self deny: cmd coordinatesAreRelative
]

{ #category : 'tests' }
PathMoveToCommandTest >> testRelativeToPointIsRelative [
	| cmd |
	cmd := PathMoveToCommand new toRelativePoint: 10 @ 20.
	self assert: cmd coordinatesAreRelative
]
