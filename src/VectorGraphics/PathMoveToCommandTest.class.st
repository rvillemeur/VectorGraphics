Class {
	#name : 'PathMoveToCommandTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Tests',
	#package : 'VectorGraphics',
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

{ #category : 'tests' }
PathMoveToCommandTest >> testToPointStoresCoordinates [
	| cmd canvas log |
	cmd := PathMoveToCommand new toPoint: 30 @ 40.
	log := OrderedCollection new.
	canvas := Object new.
	"Verify the command stores one point at the given coords by driving a mock canvas."
	cmd privatePointsDo: [ :pt | log add: pt ].
	self assert: log size equals: 1.
	self assert: log first equals: 30 @ 40
]

{ #category : 'tests' }
PathMoveToCommandTest >> testToRelativePointStoresCoordinates [
	| cmd log |
	cmd := PathMoveToCommand new toRelativePoint: 5 @ 7.
	log := OrderedCollection new.
	cmd privatePointsDo: [ :pt | log add: pt ].
	self assert: log size equals: 1.
	self assert: log first equals: 5 @ 7
]
