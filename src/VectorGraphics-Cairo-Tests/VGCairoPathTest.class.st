"
I test the path value and the builder that flattens curves into it.

A path is built in device space, because that is where Cairo puts it: a coordinate is transformed by
the matrix in force when the construction call is made, not when the path is filled.
A path is immutable once built, so that fillPreservingPath can hand the same value to two entries of
the display list.
"
Class {
	#name : 'VGCairoPathTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Cairo-Tests-Tests',
	#package : 'VectorGraphics-Cairo-Tests',
	#tag : 'Tests'
}

{ #category : 'helpers' }
VGCairoPathTest >> cubicCurveAt: aNumber through: fourPoints [
	"The analytic cubic Bezier, so that a test can say how far the flattened polyline is from the
	 curve it stands for rather than counting its points. The four points are the start, the two
	 controls and the end, in that order."

	| u |
	u := 1 - aNumber.
	^ ((fourPoints at: 1) * (u * u * u))
	  + ((fourPoints at: 2) * (3 * u * u * aNumber))
	  + ((fourPoints at: 3) * (3 * u * aNumber * aNumber))
	  + ((fourPoints at: 4) * (aNumber * aNumber * aNumber))
]

{ #category : 'support' }
VGCairoPathTest >> distanceFrom: aPoint toPolyline: aPointCollection [
	| best |
	best := Float infinity.
	1 to: aPointCollection size - 1 do: [ :index |
		best := best min: (self
				         distanceFrom: aPoint
				         toSegmentFrom: (aPointCollection at: index)
				         to: (aPointCollection at: index + 1)) ].
	^ best
]

{ #category : 'support' }
VGCairoPathTest >> distanceFrom: aPoint toSegmentFrom: aStartPoint to: anEndPoint [
	| direction lengthSquared projection closest |
	direction := anEndPoint - aStartPoint.
	lengthSquared := direction dotProduct: direction.
	lengthSquared isZero ifTrue: [ ^ (aPoint - aStartPoint) r ].
	projection := (((aPoint - aStartPoint) dotProduct: direction) / lengthSquared max: 0) min: 1.
	closest := aStartPoint + (direction * projection).
	^ (aPoint - closest) r
]

{ #category : 'tests - flattening' }
VGCairoPathTest >> testACollinearCurveFlattensToItsEndPoints [
	| path |
	path := (VGPathBuilder new
		         moveTo: 0 @ 0;
		         curveVia: 10 @ 0 via: 20 @ 0 to: 30 @ 0;
		         yourself) path.
	self assert: path subPaths first points first equals: 0 @ 0.
	self assert: path subPaths first points last equals: 30 @ 0.
	self assert: path subPaths first points size equals: 2
]

{ #category : 'tests' }
VGCairoPathTest >> testAFlattenedCurveStaysWithinToleranceOfTheCurve [
	| curve builder polyline worst |
	curve := {
		         (0 @ 0).
		         (0 @ 60).
		         (60 @ 60).
		         (60 @ 0) }.
	builder := VGPathBuilder new.
	builder flatteningTolerance: 0.1.
	builder
		moveTo: curve first;
		curveVia: (curve at: 2) via: (curve at: 3) to: curve last.
	polyline := builder path subPaths first points asArray.
	worst := (0 to: 1000) inject: 0 into: [ :best :step |
		         | point |
		         point := self cubicCurveAt: step / 1000 through: curve.
		         best max: (self distanceFrom: point toPolyline: polyline) ].
	self assert: worst <= 0.1
]

{ #category : 'tests - building' }
VGCairoPathTest >> testAFreshBuilderHoldsNoPathAndNoCurrentPoint [
	| builder |
	builder := VGPathBuilder new.
	self deny: builder hasCurrentPoint.
	self assert: builder currentPoint isNil.
	self assert: builder path isEmpty
]

{ #category : 'tests - building' }
VGCairoPathTest >> testALineToWithNoCurrentPointBehavesAsAMoveTo [
	"Cairo treats a line to with no current point as a move to, rather than failing."
	| path |
	path := (VGPathBuilder new
		         lineTo: 5 @ 5;
		         lineTo: 7 @ 5;
		         yourself) path.
	self assert: path subPaths size equals: 1.
	self assert: path subPaths first points asArray equals: { 5 @ 5. 7 @ 5 }
]

{ #category : 'tests - building' }
VGCairoPathTest >> testAPathIsImmutableOnceBuilt [
	"fillPreservingPath hands the same path to two entries of the display list, so building on
	 after a fill must not change what the first entry holds."
	| builder path |
	builder := VGPathBuilder new
		           moveTo: 0 @ 0;
		           lineTo: 4 @ 0;
		           yourself.
	path := builder path.
	builder lineTo: 4 @ 4.
	self assert: path subPaths first points size equals: 2
]

{ #category : 'tests' }
VGCairoPathTest >> testAPointIsSnappedToTheFixedPointGridCairoStoresPathsOn [
	"Cairo keeps every path coordinate as a cairo_fixed_t, which holds twenty-four bits of whole
	 number and eight of fraction, so a device coordinate lands on a two hundred and fifty-sixth
	 of a pixel. Its conversion rounds a half to the even neighbour, which is why a rectangle one
	 five hundred and twelfth of a pixel wide paints nothing at all on a live context."
	| builder points |
	builder := VGPathBuilder new.
	builder
		moveTo: 1 / 512 @ (1 / 256);
		lineTo: 2 + (1 / 400) @ (3 / 512);
		lineTo: 4.2 @ 5.7.
	points := builder path subPaths first points.
	self assert: points first equals: 0.0 @ 0.00390625.
	self assert: points second equals: 2.00390625 @ 0.0078125.
	self assert: points third equals: 4.19921875 @ 5.69921875
]

{ #category : 'tests - flattening' }
VGCairoPathTest >> testAQuadraticCurveFlattensThroughItsCubicForm [
	"Cairo has no quadratic primitive: it raises the quadratic to a cubic, and so do we."
	| quadratic cubic |
	quadratic := ((VGPathBuilder new
		              flatteningTolerance: 0.1;
		              yourself)
		             moveTo: 0 @ 0;
		             quadraticVia: 30 @ 60 to: 60 @ 0;
		             yourself) path subPaths first points asArray.
	cubic := ((VGPathBuilder new
		           flatteningTolerance: 0.1;
		           yourself)
		          moveTo: 0 @ 0;
		          curveVia: 20 @ 40 via: 40 @ 40 to: 60 @ 0;
		          yourself) path subPaths first points asArray.
	self assert: quadratic equals: cubic
]

{ #category : 'tests - building' }
VGCairoPathTest >> testASecondMoveToStartsANewSubPathAndASingleMoveToDrawsNothing [
	| path |
	path := (VGPathBuilder new
		         moveTo: 0 @ 0;
		         lineTo: 4 @ 0;
		         moveTo: 9 @ 9;
		         yourself) path.
	self assert: path subPaths size equals: 1.
	self assert: path subPaths first points size equals: 2
]

{ #category : 'tests - flattening' }
VGCairoPathTest >> testATighterToleranceFlattensIntoMorePoints [
	| coarse fine |
	coarse := ((VGPathBuilder new
		            flatteningTolerance: 1.0;
		            yourself)
		           moveTo: 0 @ 0;
		           curveVia: 0 @ 60 via: 60 @ 60 to: 60 @ 0;
		           yourself) path subPaths first points size.
	fine := ((VGPathBuilder new
		          flatteningTolerance: 0.05;
		          yourself)
		         moveTo: 0 @ 0;
		         curveVia: 0 @ 60 via: 60 @ 60 to: 60 @ 0;
		         yourself) path subPaths first points size.
	self assert: fine > coarse
]

{ #category : 'tests - building' }
VGCairoPathTest >> testClosePathClosesTheSubPathAndBringsTheCurrentPointBack [
	| builder |
	builder := VGPathBuilder new
		           moveTo: 2 @ 3;
		           lineTo: 10 @ 3;
		           lineTo: 10 @ 9;
		           closePath;
		           yourself.
	self assert: builder path subPaths first isClosed.
	self assert: builder currentPoint equals: 2 @ 3
]

{ #category : 'tests - building' }
VGCairoPathTest >> testDrawingAfterACloseStartsANewSubPath [
	| path |
	path := (VGPathBuilder new
		         moveTo: 0 @ 0;
		         lineTo: 4 @ 0;
		         closePath;
		         lineTo: 8 @ 8;
		         yourself) path.
	self assert: path subPaths size equals: 2.
	self assert: path subPaths second points first equals: 0 @ 0.
	self assert: path subPaths second points last equals: 8 @ 8
]

{ #category : 'tests - building' }
VGCairoPathTest >> testMoveToThenLineToMakesOneOpenSubPath [
	| path |
	path := (VGPathBuilder new
		         moveTo: 2 @ 3;
		         lineTo: 10 @ 3;
		         yourself) path.
	self assert: path subPaths size equals: 1.
	self assert: path subPaths first points asArray equals: { 2 @ 3. 10 @ 3 }.
	self deny: path subPaths first isClosed
]
