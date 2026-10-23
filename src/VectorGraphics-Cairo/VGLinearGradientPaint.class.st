"
I am a linear gradient: the offset of a point is how far along the line from my first point to my second it projects, as a fraction of the length of that line.

Fields 9 to 12 of my block are that line, as x0, y0, x1, y1, in my own space. A line of no length paints nothing.
"
Class {
	#name : 'VGLinearGradientPaint',
	#superclass : 'VGGradientPaint',
	#category : 'VectorGraphics-Cairo-Paint',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Paint'
}

{ #category : 'instance creation' }
VGLinearGradientPaint class >> from: aPoint to: anotherPoint [
	^ (self new) from: aPoint to: anotherPoint; yourself
]

{ #category : 'layout' }
VGLinearGradientPaint class >> lineEndFields [
	"Where the end of my line sits in the block, as x then y."

	^ #( 11 12 )
]

{ #category : 'layout' }
VGLinearGradientPaint class >> lineStartFields [
	"Where the start of my line sits in the block, as x then y. The ABI of rule 2 numbers the
	 fields and VGPaint class >> blockLayout names them; this says which of them are mine, so a
	 reader outside this class, such as the SPIR-V kernel, asks rather than counts."

	^ #( 9 10 )
]

{ #category : 'constants' }
VGLinearGradientPaint class >> paintTag [
	^ 2
]

{ #category : 'accessing' }
VGLinearGradientPaint >> from [
	^ (coefficients at: self class lineStartFields first)
	  @ (coefficients at: self class lineStartFields second)
]

{ #category : 'accessing' }
VGLinearGradientPaint >> from: aPoint to: anotherPoint [
	coefficients
		at: self class lineStartFields first
		put: aPoint x asFloat.
	coefficients
		at: self class lineStartFields second
		put: aPoint y asFloat.
	coefficients
		at: self class lineEndFields first
		put: anotherPoint x asFloat.
	coefficients
		at: self class lineEndFields second
		put: anotherPoint y asFloat
]

{ #category : 'evaluating' }
VGLinearGradientPaint >> offsetInPaintSpace: aPoint [
	"How far along the line from its start to its end the point projects, as a fraction. A line of
	 no length has no direction to project on, so it paints nothing at all."

	| line |
	line := self to - self from.
	line isZero ifTrue: [ ^ nil ].
	^ ((aPoint - self from) dotProduct: line) / (line dotProduct: line)
]

{ #category : 'accessing' }
VGLinearGradientPaint >> to [
	^ (coefficients at: self class lineEndFields first)
	  @ (coefficients at: self class lineEndFields second)
]
