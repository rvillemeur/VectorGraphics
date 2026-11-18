"
I test the contour a Type 2 charstring draws, and the TrueType contour it is turned into.

A CFF contour holds lines and cubic curves and closes itself. A TrueType contour holds one array of points, each of them on or off the curve, and closes itself too: an off-curve point is the control point of a quadratic. I test that the turn from the one to the other keeps the shape, states the right points as control points, and writes the closing point only once.
"
Class {
	#name : 'TTCffContourTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-TrueType-Tests-Tests',
	#package : 'VectorGraphics-TrueType-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
TTCffContourTest >> testALineKeepsItsPointAndACurveAddsOneOffTheCurve [
	"Every point a line ends at is on the curve. A cubic shallow enough to be held by one
	 quadratic adds that quadratic's control point, which is off the curve, and its end
	 point, which is on it."

	| contour construction |
	contour := TTCffContour startingAt: 0 @ 0.
	contour addSegment: { (100 @ 0) }.
	contour addSegment: {
			(100 + (200 / 3) @ (400 / 3)).
			(100 + (400 / 3) @ (400 / 3)).
			(300 @ 0) }.
	construction := contour contourConstructionWithinTolerance: 0.1.
	self
		assert: construction points asArray
		equals: {
				(0 @ 0).
				(100 @ 0).
				(200 @ 200).
				(300 @ 0) }.
	self
		assert: ((1 to: 4) collect: [ :each |
				 construction controlPointFlags bitBooleanAt: each ])
		equals: #( false false true false )
]

{ #category : 'tests' }
TTCffContourTest >> testTheClosingPointIsWrittenOnlyOnce [
	"A CFF contour closes itself, and so does a TrueType one. A charstring that draws its
	 way back to the point it started at must not leave that point in the array twice,
	 since the closing segment would then be drawn on top of a segment of no length."

	| contour construction |
	contour := TTCffContour startingAt: 10 @ 10.
	contour addSegment: { (110 @ 10) }.
	contour addSegment: { (110 @ 110) }.
	contour addSegment: { (10 @ 10) }.
	construction := contour contourConstructionWithinTolerance: 0.1.
	self
		assert: construction points asArray
		equals: {
				(10 @ 10).
				(110 @ 10).
				(110 @ 110) }
]
