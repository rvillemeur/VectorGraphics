Class {
	#name : 'Int16PointArray',
	#superclass : 'DoubleByteArray',
	#type : 'DoubleByteLayout',
	#category : 'VectorGraphics-TrueType',
	#package : 'VectorGraphics',
	#tag : 'TrueType'
}

{ #category : 'accessing' }
Int16PointArray >> at: index [
	"Return the element (e.g., point) at the given index"
	^(self signedAt: index * 2 - 1) @ (self signedAt: index * 2).
]

{ #category : 'accessing' }
Int16PointArray >> at: index put: aPoint [
	"Store the argument aPoint at the given index"
	self signedAt: index * 2 - 1 put: aPoint x asInteger.
	self signedAt: index * 2 put: aPoint y asInteger.
	^aPoint.
]

{ #category : 'accessing' }
Int16PointArray >> at: index putX: aNumber [
	"Store the argument aPoint at the given index"
	self signedAt: index * 2 - 1 put: aNumber asInteger.
]

{ #category : 'accessing' }
Int16PointArray >> at: index putY: aNumber [
	"Store the argument aPoint at the given index"
	self signedAt: index * 2 put: aNumber asInteger.
]

{ #category : 'accessing' }
Int16PointArray >> defaultElement [
	"Return the default element of the receiver"
	^0@0.
]

{ #category : 'accessing' }
Int16PointArray >> signedAt: index [
	"Return the 16-bit signed integer value at the given index of the receiver."

	<primitive: 143>
	index isInteger ifTrue: [self errorSubscriptBounds: index].
	index isNumber ifTrue: [^ self at: index truncated].
	self errorNonIntegerIndex.
]

{ #category : 'accessing' }
Int16PointArray >> signedAt: index put: value [
	"Store the given 16-bit signed integer at the given index in the receiver."

	<primitive: 144>
	index isInteger
		ifTrue: [
			(index >= 1 and: [index <= self size])
				ifTrue: [self errorImproperStore]
				ifFalse: [self errorSubscriptBounds: index]].
	index isNumber ifTrue: [^ self at: index truncated put: value].
	self errorNonIntegerIndex.
]

{ #category : 'accessing' }
Int16PointArray >> size [
	"Return the number of elements in the receiver"
	^ super size // 2.
]
