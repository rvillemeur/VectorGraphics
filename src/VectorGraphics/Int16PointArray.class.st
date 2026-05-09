"
A compact array of signed 16-bit integer points, used to store TrueType glyph coordinates.

Subclasses DoubleByteArray (each slot is a uint16) and interprets pairs of slots as signed
(x, y) points. This matches the int16 coordinate format used in TrueType 'glyf' table data.

Pharo has no built-in ShortPointArray (Cuis has one); this class fills that gap. It stores
n points as 2n uint16 slots in the underlying DoubleByteArray, using `signedAt:` to reinterpret
unsigned storage as signed values.

## Used by
TTContourConstruction stores glyph outline points in an Int16PointArray.

## Key methods
- `at: index`         — returns a Point (signedX @ signedY) for the given 1-based point index
- `at: index put: pt` — stores a Point at the given index
- `signedAt: i`       — reads a uint16 slot as a signed int16 (handles values > 32767)
"
Class {
	#name : 'Int16PointArray',
	#superclass : 'DoubleByteArray',
	#type : 'DoubleByteLayout',
	#category : 'VectorGraphics-TrueType',
	#package : 'VectorGraphics',
	#tag : 'TrueType'
}

{ #category : 'instance creation' }
Int16PointArray class >> new: n [
	"Allocate n points — each point needs 2 uint16 slots in the underlying DoubleByteArray."
	^ super new: n * 2
]

{ #category : 'accessing' }
Int16PointArray >> at: index [
	"Return the point at the given index."
	^ (self signedAt: index * 2 - 1) @ (self signedAt: index * 2)
]

{ #category : 'accessing' }
Int16PointArray >> at: index put: aPoint [
	"Store aPoint at the given index."
	self signedAt: index * 2 - 1 put: aPoint x asInteger.
	self signedAt: index * 2 put: aPoint y asInteger.
	^ aPoint
]

{ #category : 'accessing' }
Int16PointArray >> at: index putX: aNumber [
	"Store only the x coordinate at the given index."
	self signedAt: index * 2 - 1 put: aNumber asInteger
]

{ #category : 'accessing' }
Int16PointArray >> at: index putY: aNumber [
	"Store only the y coordinate at the given index."
	self signedAt: index * 2 put: aNumber asInteger
]

{ #category : 'accessing' }
Int16PointArray >> defaultElement [
	^ 0 @ 0
]

{ #category : 'accessing' }
Int16PointArray >> signedAt: index [
	"Return the 16-bit signed integer at the given slot index.
	Converts from unsigned uint16 (stored by DoubleByteArray) to signed."
	| val |
	val := super at: index.
	val > 32767 ifTrue: [ val := val - 65536 ].
	^ val
]

{ #category : 'accessing' }
Int16PointArray >> signedAt: index put: value [
	"Store a 16-bit signed integer at the given slot index.
	Converts from signed to unsigned uint16 before storing."
	| unsigned |
	unsigned := value < 0 ifTrue: [ value + 65536 ] ifFalse: [ value ].
	super at: index put: unsigned.
	^ value
]

{ #category : 'accessing' }
Int16PointArray >> size [
	"Number of points (each point occupies 2 uint16 slots)."
	^ super size // 2
]
