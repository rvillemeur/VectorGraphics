Class {
	#name : 'Int16PointArrayTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-tests',
	#package : 'VectorGraphics',
	#tag : 'tests'
}

{ #category : 'tests' }
Int16PointArrayTest >> testAtPutBothNegative [
	| arr |
	arr := Int16PointArray new: 1.
	arr at: 1 put: -100 @ -200.
	self assert: (arr at: 1) equals: -100 @ -200
]

{ #category : 'tests' }
Int16PointArrayTest >> testAtPutNegativeX [
	| arr |
	arr := Int16PointArray new: 1.
	arr at: 1 put: -100 @ 50.
	self assert: (arr at: 1) equals: -100 @ 50
]

{ #category : 'tests' }
Int16PointArrayTest >> testAtPutNegativeY [
	| arr |
	arr := Int16PointArray new: 1.
	arr at: 1 put: 50 @ -200.
	self assert: (arr at: 1) equals: 50 @ -200
]

{ #category : 'tests' }
Int16PointArrayTest >> testAtPutPositive [
	| arr |
	arr := Int16PointArray new: 3.
	arr at: 2 put: 100 @ 200.
	self assert: (arr at: 2) equals: 100 @ 200
]

{ #category : 'tests' }
Int16PointArrayTest >> testBoundaryMaxValues [
	| arr |
	arr := Int16PointArray new: 1.
	arr at: 1 put: 32767 @ 32767.
	self assert: (arr at: 1) equals: 32767 @ 32767
]

{ #category : 'tests' }
Int16PointArrayTest >> testBoundaryMinValues [
	| arr |
	arr := Int16PointArray new: 1.
	arr at: 1 put: -32768 @ -32768.
	self assert: (arr at: 1) equals: -32768 @ -32768
]

{ #category : 'tests' }
Int16PointArrayTest >> testDefaultElement [
	| arr |
	arr := Int16PointArray new: 1.
	self assert: arr defaultElement equals: 0 @ 0
]

{ #category : 'tests' }
Int16PointArrayTest >> testMultipleElements [
	| arr |
	arr := Int16PointArray new: 3.
	arr at: 1 put: 10 @ 20.
	arr at: 2 put: -30 @ 40.
	arr at: 3 put: 50 @ -60.
	self assert: (arr at: 1) equals: 10 @ 20.
	self assert: (arr at: 2) equals: -30 @ 40.
	self assert: (arr at: 3) equals: 50 @ -60
]

{ #category : 'tests' }
Int16PointArrayTest >> testPutX [
	| arr |
	arr := Int16PointArray new: 1.
	arr at: 1 put: 0 @ 99.
	arr at: 1 putX: -500.
	self assert: (arr at: 1) x equals: -500.
	self assert: (arr at: 1) y equals: 99
]

{ #category : 'tests' }
Int16PointArrayTest >> testPutY [
	| arr |
	arr := Int16PointArray new: 1.
	arr at: 1 put: 77 @ 0.
	arr at: 1 putY: -500.
	self assert: (arr at: 1) x equals: 77.
	self assert: (arr at: 1) y equals: -500
]

{ #category : 'tests' }
Int16PointArrayTest >> testSize [
	| arr |
	arr := Int16PointArray new: 4.
	self assert: arr size equals: 4
]

{ #category : 'tests' }
Int16PointArrayTest >> testZeroPoint [
	| arr |
	arr := Int16PointArray new: 1.
	arr at: 1 put: 0 @ 0.
	self assert: (arr first) equals: 0 @ 0
]
