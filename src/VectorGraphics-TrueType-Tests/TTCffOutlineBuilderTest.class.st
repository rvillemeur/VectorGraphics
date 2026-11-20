"
I state what TTCffOutlineBuilder makes of the steps a Type 2 charstring gives it.

Every point a charstring states is a step from the point before, and nothing in the bytes says where a contour ends: a move ends it. So the facts here are about the point reached, where a contour opens, and which contours the builder hands back — the one being drawn is not among them, and one opened without a segment is dropped.

I build the builder by hand rather than through TTCffCharstringInterpreter: the interpreter has its own tests, and a fact about the builder must fail when the builder breaks, not when an operator is decoded differently.
"
Class {
	#name : 'TTCffOutlineBuilderTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-TrueType-Tests-Tests',
	#package : 'VectorGraphics-TrueType-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
TTCffOutlineBuilderTest >> testAContourOpenedAndNeverDrawnInIsDropped [
	"A font writes one move straight after another, and the contour the first opened holds
	 no segment. Answering it would give the glyph a contour of one point, which fills
	 nothing and which a rasteriser still has to walk."

	| builder |
	builder := TTCffOutlineBuilder new.
	builder
		moveBy: 10 @ 10;
		moveBy: 50 @ 50;
		lineBy: 10 @ 0;
		closeContour.
	self assert: builder contours size equals: 1.
	self assert: builder contours first start equals: 60 @ 60
]

{ #category : 'tests' }
TTCffOutlineBuilderTest >> testACurveStatesItsTwoControlPointsAndItsEndPointEachAsAStepFromTheOneBefore [
	"A cubic is three steps, not three points: the first control point is a step from the
	 point reached, the second a step from the first, and the end point a step from the
	 second. Reading them as three steps from the same point would bend the curve."

	| builder |
	builder := TTCffOutlineBuilder new.
	builder
		moveBy: 0 @ 0;
		curveBy: 10 @ 0 by: 10 @ 10 by: 0 @ 10;
		closeContour.
	self assert: builder point equals: 20 @ 20.
	self
		assert: builder contours first segments asArray
		equals: { { (10 @ 0). (20 @ 10). (20 @ 20) } }
]

{ #category : 'tests' }
TTCffOutlineBuilderTest >> testAFreshBuilderStartsAtTheOriginWithNoContour [
	"The first step of a charstring is counted from the origin, and a glyph that draws
	 nothing — the space of every font — answers no contour at all."

	| builder |
	builder := TTCffOutlineBuilder new.
	self assert: builder point equals: 0 @ 0.
	self assert: builder contours equals: #(  )
]

{ #category : 'tests' }
TTCffOutlineBuilderTest >> testALineAddsOneAbsolutePointCountedFromThePointBefore [
	"A line is one step long. The contour keeps where it lands, not the step itself, so two
	 lines in a row leave two points that each add their step to the one before."

	| builder |
	builder := TTCffOutlineBuilder new.
	builder
		moveBy: 10 @ 10;
		lineBy: 20 @ 0;
		lineBy: 0 @ 30;
		closeContour.
	self assert: builder point equals: 30 @ 40.
	self
		assert: builder contours first segments asArray
		equals: {
				{ (30 @ 10) }.
				{ (30 @ 40) } }
]

{ #category : 'tests' }
TTCffOutlineBuilderTest >> testAMoveOpensAContourAtThePointItReaches [
	"A move counts its step from the point reached so far and opens a contour there. The
	 contour is not among the ones the builder hands back until it is closed, because a
	 contour holding no segment is dropped rather than answered."

	| builder |
	builder := TTCffOutlineBuilder new.
	builder moveBy: 50 @ 100.
	self assert: builder point equals: 50 @ 100.
	self assert: builder contours equals: #(  ).
	builder
		lineBy: 10 @ 0;
		closeContour.
	self assert: builder contours size equals: 1.
	self assert: builder contours first start equals: 50 @ 100
]

{ #category : 'tests' }
TTCffOutlineBuilderTest >> testClosingWithNothingOpenLeavesTheBuilderAsItWas [
	"A charstring may end on a close, and a reader may close twice. Neither adds a contour
	 nor loses one."

	| builder |
	builder := TTCffOutlineBuilder new.
	builder closeContour.
	self assert: builder contours equals: #(  ).
	builder
		moveBy: 10 @ 10;
		lineBy: 10 @ 0;
		closeContour;
		closeContour.
	self assert: builder contours size equals: 1
]

{ #category : 'tests' }
TTCffOutlineBuilderTest >> testContoursDrawnElsewhereAreTakenAsTheyAre [
	"An accented glyph is drawn from two other glyphs, whose contours are already absolute
	 and in font units. They are added as they stand, after the ones drawn here, and the
	 point reached is not moved by them."

	| builder taken |
	builder := TTCffOutlineBuilder new.
	builder
		moveBy: 10 @ 10;
		lineBy: 10 @ 0;
		closeContour.
	taken := TTCffContour startingAt: 500 @ 500.
	taken addSegment: { (600 @ 500) }.
	builder addContours: { taken }.
	self assert: builder contours size equals: 2.
	self assert: builder contours second equals: taken.
	self assert: builder point equals: 20 @ 10
]

{ #category : 'tests' }
TTCffOutlineBuilderTest >> testTheContoursViewListsEveryClosedContourWithItsStartAndSegmentCount [
	"The view a reader opens on the builder names its columns and lists one row per closed
	 contour: its place in the order they were closed, where it starts, and how many segments
	 it holds. The contour still being drawn is not among them, since it may yet be dropped.
	 The second contour starts at 130@110 and not at 100@100, because a move is a step too."

	| builder presenter rows |
	builder := TTCffOutlineBuilder new.
	builder
		moveBy: 10 @ 10;
		lineBy: 20 @ 0;
		moveBy: 100 @ 100;
		curveBy: 10 @ 0 by: 10 @ 10 by: 0 @ 10;
		closeContour;
		moveBy: 500 @ 500.
	presenter := (StInspectionContext new
		              inspectedObject: builder;
		              methodSelector: #inspectorContours:;
		              yourself) basicNewInspectionPresenter:
		             (SpPresenterBuilder newApplication: SpApplication new).
	self
		assert: (presenter columns collect: [ :each | each title ]) asArray
		equals: #( 'Contour' 'Starts at' 'Segments' ).
	rows := presenter items collect: [ :item |
		        presenter columns collect: [ :column |
			        column evaluation value: item ] ].
	self
		assert: (rows collect: [ :each | each asArray ]) asArray
		equals: {
				#( '1' '(10@10)' '1' ).
				#( '2' '(130@110)' '1' ) }
]
