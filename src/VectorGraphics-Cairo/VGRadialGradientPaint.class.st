"
I am a radial gradient between two circles, which is what `cairo_pattern_create_radial` builds.

Fields 9 to 11 of my block are the inner circle as x, y and radius, and fields 12 to 14 the outer one. Concentric circles reduce to the distance from the centre, scaled between the two radii, which is the common case and the one the corpus draws; the general case solves the quadratic that asks for the largest parameter whose circle passes through the point.
"
Class {
	#name : 'VGRadialGradientPaint',
	#superclass : 'VGGradientPaint',
	#category : 'VectorGraphics-Cairo-Paint',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Paint'
}

{ #category : 'layout' }
VGRadialGradientPaint class >> circleFields [
	"Where my two circles sit in the block, by name: the ABI of rule 2 numbers the fields and
	 VGPaint class >> blockLayout names them, and this says which of them are mine, so a reader
	 outside this class, such as the SPIR-V kernel, asks rather than counts."

	^ Dictionary newFromPairs: {
			  #innerCenterX.
			  9.
			  #innerCenterY.
			  10.
			  #innerRadius.
			  11.
			  #outerCenterX.
			  12.
			  #outerCenterY.
			  13.
			  #outerRadius.
			  14 }
]

{ #category : 'layout' }
VGRadialGradientPaint class >> fieldNamed: aName [
	^ self circleFields at: aName
]

{ #category : 'instance creation' }
VGRadialGradientPaint class >> innerCenter: innerCenter innerRadius: innerRadius outerCenter: outerCenter outerRadius: outerRadius [
	^ (self new)
		  innerCenter: innerCenter
		  innerRadius: innerRadius
		  outerCenter: outerCenter
		  outerRadius: outerRadius;
		  yourself
]

{ #category : 'constants' }
VGRadialGradientPaint class >> paintTag [
	^ 3
]

{ #category : 'evaluating' }
VGRadialGradientPaint >> acceptableRootsAmong: aCollection [
	"The largest of those offsets whose interpolated circle has a radius of zero or more. A circle
	 of negative radius does not exist, so the offset that names it paints nothing."

	| radiusDelta acceptable |
	radiusDelta := self outerRadius - self innerRadius.
	acceptable := aCollection select: [ :each |
		              self innerRadius + (each * radiusDelta) >= 0 ].
	acceptable ifEmpty: [ ^ nil ].
	^ acceptable inject: acceptable first into: [ :best :each | best max: each ]
]

{ #category : 'accessing' }
VGRadialGradientPaint >> innerCenter [
	^ (coefficients at: (self class fieldNamed: #innerCenterX))
	  @ (coefficients at: (self class fieldNamed: #innerCenterY))
]

{ #category : 'accessing' }
VGRadialGradientPaint >> innerCenter: innerCenter innerRadius: innerRadius outerCenter: outerCenter outerRadius: outerRadius [
	coefficients
		at: (self class fieldNamed: #innerCenterX)
		put: innerCenter x asFloat.
	coefficients
		at: (self class fieldNamed: #innerCenterY)
		put: innerCenter y asFloat.
	coefficients
		at: (self class fieldNamed: #innerRadius)
		put: innerRadius asFloat.
	coefficients
		at: (self class fieldNamed: #outerCenterX)
		put: outerCenter x asFloat.
	coefficients
		at: (self class fieldNamed: #outerCenterY)
		put: outerCenter y asFloat.
	coefficients
		at: (self class fieldNamed: #outerRadius)
		put: outerRadius asFloat
]

{ #category : 'accessing' }
VGRadialGradientPaint >> innerRadius [
	^ coefficients at: (self class fieldNamed: #innerRadius)
]

{ #category : 'evaluating' }
VGRadialGradientPaint >> largestRootOf: a and: b and: c [
	"The largest root of a * s squared + b * s + c whose circle has a radius of its own, or nil when
	 there is none. A vanishing leading coefficient leaves one linear root, and a vanishing b with
	 it leaves no root at all."

	| discriminant root roots |
	a = 0 ifTrue: [
		b = 0 ifTrue: [ ^ nil ].
		^ self acceptableRootsAmong: { c / b negated } ].
	discriminant := b squared - (4 * a * c).
	discriminant < 0 ifTrue: [ ^ nil ].
	root := discriminant sqrt.
	roots := { b negated + root / (2 * a). b negated - root / (2 * a) }.
	^ self acceptableRootsAmong: roots
]

{ #category : 'evaluating' }
VGRadialGradientPaint >> offsetInPaintSpace: aPoint [
	"Cairo interpolates a whole circle between the two: at offset s the circle has centre
	 c0 + s * (c1 - c0) and radius r0 + s * (r1 - r0), and the offset at a point is the largest s
	 whose circle passes through it and whose radius is not negative. Writing |p - c(s)| = r(s) and
	 squaring gives a quadratic in s. Two concentric circles reduce it to the distance from the
	 centre less the inner radius over the difference of the radii, which is the case the corpus
	 draws and the case measured against live Cairo."

	| centreDelta radiusDelta pointDelta a b c |
	centreDelta := self outerCenter - self innerCenter.
	radiusDelta := self outerRadius - self innerRadius.
	pointDelta := aPoint - self innerCenter.
	a := (centreDelta dotProduct: centreDelta) - radiusDelta squared.
	b := -2 * ((pointDelta dotProduct: centreDelta) + (self innerRadius * radiusDelta)).
	c := (pointDelta dotProduct: pointDelta) - self innerRadius squared.
	^ self largestRootOf: a and: b and: c
]

{ #category : 'accessing' }
VGRadialGradientPaint >> outerCenter [
	^ (coefficients at: (self class fieldNamed: #outerCenterX))
	  @ (coefficients at: (self class fieldNamed: #outerCenterY))
]

{ #category : 'accessing' }
VGRadialGradientPaint >> outerRadius [
	^ coefficients at: (self class fieldNamed: #outerRadius)
]
