"
I hold `Int16PointArray`, which stores a point as two signed 16-bit halves of one 32-bit word.

The packing is the whole of the class and all of the risk, so the tests walk the four sign combinations — both coordinates positive, each one negative in turn, and both negative — then the two boundaries, the most positive and the most negative value a signed 16-bit field holds. A sign bit leaking from one half into the other shows up in exactly those cases and nowhere else.

The rest states the collection protocol a glyph contour relies on: the size asked for is the size answered, an untouched slot reads back as the zero point, `putX` and `putY` reach one half without disturbing the other, and several elements keep their own values.
"
Class {
	#name : 'Int16PointArrayTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-TrueType-Tests-Tests',
	#package : 'VectorGraphics-TrueType-Tests',
	#tag : 'Tests'
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
