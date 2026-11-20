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

{ #category : 'support' }
TTCffContourTest >> presenterOn: aContour through: aSelector [
	"The presenter an inspector builds for one view of a contour. A view takes the builder
	 as its argument, which is how the inspector decides it may open it."

	^ (StInspectionContext new
		   inspectedObject: aContour;
		   methodSelector: aSelector;
		   yourself) basicNewInspectionPresenter:
		  (SpPresenterBuilder newApplication: SpApplication new)
]

{ #category : 'support' }
TTCffContourTest >> rowsOf: aPresenter [
	"What a reader sees in the table: one array a row, a column block evaluated per item,
	 since a column block runs only when a row is drawn."

	^ (aPresenter items collect: [ :item |
		   (aPresenter columns collect: [ :column |
			    column evaluation value: item ]) asArray ]) asArray
]

{ #category : 'tests' }
TTCffContourTest >> testAContourWithNoSegmentTurnsIntoItsStartAlone [
	"The degenerate contour a font writes when one move follows another. It holds its start
	 and nothing else, and the closing point is not dropped here: a single point is not a
	 point written twice."

	| construction |
	construction := (TTCffContour startingAt: 50 @ 100)
		                contourConstructionWithinTolerance: 0.1.
	self assert: construction points asArray equals: { (50 @ 100) }.
	self deny: (construction controlPointFlags bitBooleanAt: 1)
]

{ #category : 'tests' }
TTCffContourTest >> testAFreshContourIsEmptyAndClosedAndEndsWhereItStarts [
	"A move opens a contour and draws nothing. It is closed all the same — every contour of
	 a charstring is — and it ends where it starts, so the next step is counted from there."

	| contour |
	contour := TTCffContour startingAt: 50 @ 100.
	self assert: contour isEmpty.
	self assert: contour isClosed.
	self assert: contour start equals: 50 @ 100.
	self assert: contour lastPoint equals: 50 @ 100.
	self assert: contour segments asArray equals: #(  ).
	self assert: contour points equals: { (50 @ 100) }
]

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
TTCffContourTest >> testATighterToleranceHoldsACurveWithMoreQuadratics [
	"A cubic is held by quadratics to within a number of font units. The tighter the number,
	 the more quadratics it takes, and whatever their count the points alternate: a control
	 point off the curve, then a point on it."

	| contour loose tight |
	contour := TTCffContour startingAt: 0 @ 0.
	contour addSegment: { (0 @ 400). (600 @ 400). (600 @ 0) }.
	loose := contour contourConstructionWithinTolerance: 20.
	tight := contour contourConstructionWithinTolerance: 0.05.
	self assert: tight points size > loose points size.
	self
		assert: ((2 to: tight points size) collect: [ :each |
				 tight controlPointFlags bitBooleanAt: each ])
		equals: ((2 to: tight points size) collect: [ :each | each even ])
]

{ #category : 'tests' }
TTCffContourTest >> testEveryPointIsAnsweredWithTheStartFirstAndTheControlPointsAmongThem [
	"The points of a contour, for a reader that wants its extent: the start first, then
	 every point of every segment in the order they were drawn. A control point is among
	 them, since a curve never leaves its control points."

	| contour |
	contour := TTCffContour startingAt: 0 @ 0.
	contour addSegment: { (100 @ 0) }.
	contour addSegment: { (150 @ 50). (150 @ 150). (100 @ 200) }.
	self
		assert: contour points
		equals: {
				(0 @ 0).
				(100 @ 0).
				(150 @ 50).
				(150 @ 150).
				(100 @ 200) }
]

{ #category : 'tests' }
TTCffContourTest >> testPrintingStatesWhereTheContourStartsAndHowManySegmentsItHolds [
	"What a reader sees of a contour in a list: where it starts, and how much was drawn
	 from there."

	| contour |
	contour := TTCffContour startingAt: 50 @ 100.
	self assert: contour printString equals: 'a TTCffContour((50@100) and 0 segments)'.
	contour addSegment: { (150 @ 100) }.
	self assert: contour printString equals: 'a TTCffContour((50@100) and 1 segments)'
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

{ #category : 'tests' }
TTCffContourTest >> testTheLastPointIsWhereTheLastSegmentEnds [
	"The point a reader counts the next step from is the last point of the last segment,
	 which for a cubic is its end point and not one of its control points."

	| contour |
	contour := TTCffContour startingAt: 0 @ 0.
	contour addSegment: { (100 @ 0) }.
	contour addSegment: { (150 @ 50). (150 @ 150). (100 @ 200) }.
	self deny: contour isEmpty.
	self assert: contour lastPoint equals: 100 @ 200
]

{ #category : 'tests' }
TTCffContourTest >> testTheSegmentsViewSaysOfEachSegmentWhetherItIsALineOrACurveAndWhereItEnds [
	"One row a segment, in the order they were drawn. The row counts the points of the
	 segment to say which kind it is, so a curve written with three points reads as a
	 curve without being told."

	| contour presenter |
	contour := TTCffContour startingAt: 0 @ 0.
	contour addSegment: { (100 @ 0) }.
	contour addSegment: { (150 @ 50). (150 @ 150). (100 @ 200) }.
	presenter := self presenterOn: contour through: #inspectorSegments:.
	self
		assert: (presenter columns collect: [ :each | each title ]) asArray
		equals: #( 'Step' 'Kind' 'Ends at' 'Control points' ).
	self
		assert: (self rowsOf: presenter)
		equals: {
				#( '1' 'line' '(100@0)' '#()' ).
				#( '2' 'curve' '(100@200)' '{(150@50). (150@150)}' ) }
]

{ #category : 'tests' }
TTCffContourTest >> testTheTrueTypePointsViewSaysOfEachPointWhetherItLiesOnTheCurve [
	"The same contour as a TrueType one holds it, one row a point: what the point rounds to
	 in whole font units, and whether it lies on the curve or is the control point of a
	 quadratic. The start is on the curve, and a quadratic writes its control point before
	 the point it ends at."

	| contour presenter |
	contour := TTCffContour startingAt: 0 @ 0.
	contour addSegment: { (100 @ 0) }.
	contour addSegment: {
			(100 + (200 / 3) @ (400 / 3)).
			(100 + (400 / 3) @ (400 / 3)).
			(300 @ 0) }.
	presenter := self presenterOn: contour through: #inspectorTrueTypePoints:.
	self
		assert: (presenter columns collect: [ :each | each title ]) asArray
		equals: #( 'Point' 'At' 'On the curve' ).
	self
		assert: (self rowsOf: presenter)
		equals: {
				#( '1' '(0@0)' 'yes' ).
				#( '2' '(100@0)' 'yes' ).
				#( '3' '(200@200)' 'no, a control point' ).
				#( '4' '(300@0)' 'yes' ) }
]

{ #category : 'tests' }
TTCffContourTest >> testTranslatingMovesEveryPointAndLeavesTheContourItCameFrom [
	"A glyph drawn from another glyph moves its contours. Each point of each segment moves
	 by the same step as the start, and the contour translated from is not touched, since
	 the glyph it belongs to is still drawn where it was."

	| contour moved |
	contour := TTCffContour startingAt: 0 @ 0.
	contour addSegment: { (100 @ 0) }.
	contour addSegment: { (150 @ 50). (150 @ 150). (100 @ 200) }.
	moved := contour translatedBy: 10 @ 20.
	self
		assert: moved points
		equals: {
				(10 @ 20).
				(110 @ 20).
				(160 @ 70).
				(160 @ 170).
				(110 @ 220) }.
	self assert: contour start equals: 0 @ 0.
	self assert: contour lastPoint equals: 100 @ 200
]
