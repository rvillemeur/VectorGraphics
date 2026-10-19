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

{ #category : 'constants' }
VGLinearGradientPaint class >> paintTag [
	^ 2
]

{ #category : 'accessing' }
VGLinearGradientPaint >> from [
	^ (coefficients at: 9) @ (coefficients at: 10)
]

{ #category : 'accessing' }
VGLinearGradientPaint >> from: aPoint to: anotherPoint [
	coefficients at: 9 put: aPoint x asFloat.
	coefficients at: 10 put: aPoint y asFloat.
	coefficients at: 11 put: anotherPoint x asFloat.
	coefficients at: 12 put: anotherPoint y asFloat
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
	^ (coefficients at: 11) @ (coefficients at: 12)
]
