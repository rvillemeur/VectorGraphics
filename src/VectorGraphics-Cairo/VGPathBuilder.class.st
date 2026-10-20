"
I build a VGPath from the construction calls a context makes, in device space.

I hold the run being built, the runs already finished, the current point and the point a close will
return to. I flatten every curve into a polyline by recursive subdivision, stopping when the control
points lie within flatteningTolerance of the chord, which is how Cairo reads its own tolerance.
A line to with no current point acts as a move to, as Cairo does, and drawing after a close starts a
new run at the closed run's first point.
"
Class {
	#name : 'VGPathBuilder',
	#superclass : 'Object',
	#instVars : [
		'subPaths',
		'points',
		'startPoint',
		'currentPoint',
		'flatteningTolerance',
		'startTangent',
		'endTangent'
	],
	#category : 'VectorGraphics-Cairo-Path',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Path'
}

{ #category : 'constants' }
VGPathBuilder class >> defaultFlatteningTolerance [
	"Cairo's own default tolerance, in device units: a flattened curve stays within a tenth of a
	 pixel of the curve, which is below what one antialiased pixel can show."
	^ 0.1
]

{ #category : 'constants' }
VGPathBuilder class >> maximumSubdivisionDepth [
	"A degenerate curve, one whose control points send the flatness test to infinity, must still
	 end: sixteen halvings is well past the point where a pixel can tell."
	^ 16
]

{ #category : 'building' }
VGPathBuilder >> beginSubPath [
	"End the run I am building and leave me with no current point, which is what Cairo's
	 cairo_new_sub_path does: the next lineTo acts as a moveTo."

	self flushRun.
	startPoint := nil.
	currentPoint := nil
]

{ #category : 'building' }
VGPathBuilder >> closePath [
	"A closed run bounds its own area and the current point goes back to where the run started,
	 so that drawing on begins a new run from there, which is what Cairo does. A run of one
	 point closes too: Cairo paints the round cap of a closed degenerate run, and nothing at all
	 for a move that closes nothing."
	points ifEmpty: [ ^ self ].
	subPaths add: (self runOfPoints: points asArray closed: true).
	points := OrderedCollection with: startPoint.
	currentPoint := startPoint.
	startTangent := nil.
	endTangent := nil
]

{ #category : 'accessing' }
VGPathBuilder >> currentPoint [
	^ currentPoint
]

{ #category : 'building' }
VGPathBuilder >> curveVia: aControlPoint via: anotherControlPoint to: aPoint [
	"The control points reach the grid before the curve is flattened, because Cairo subdivides a
	 spline that is already on the grid. The spline's own two tangents are remembered before it
	 becomes chords, because the chords of a flattened curve do not answer the direction the curve
	 had where it began and where it ended."
	| firstControl secondControl end from isFirstSegment |
	self hasCurrentPoint ifFalse: [ self moveTo: aControlPoint ].
	firstControl := self snapped: aControlPoint.
	secondControl := self snapped: anotherControlPoint.
	end := self snapped: aPoint.
	from := currentPoint.
	isFirstSegment := points size = 1.
	self
		flattenCubicFrom: from
		via: firstControl
		via: secondControl
		to: end
		depth: 0.
	points add: end.
	currentPoint := end.
	self
		noteTangentsFrom: (self firstOf: {
					 (firstControl - from).
					 (secondControl - from).
					 (end - from) })
		to: (self firstOf: {
					 (end - secondControl).
					 (end - firstControl).
					 (end - from) })
		firstSegment: isFirstSegment
]

{ #category : 'private' }
VGPathBuilder >> distanceFrom: aPoint toLineFrom: aStartPoint to: anEndPoint [
	| direction length |
	direction := anEndPoint - aStartPoint.
	length := direction r.
	length isZero ifTrue: [ ^ (aPoint - aStartPoint) r ].
	^ ((direction x * (aPoint y - aStartPoint y)) - (direction y * (aPoint x - aStartPoint x))) abs
	  / length
]

{ #category : 'private' }
VGPathBuilder >> firstOf: aCollectionOfPoints [
	"The first of these differences that has a direction, which is how Cairo reads the tangent of
	 a spline whose first or last control point sits on its end point."
	^ aCollectionOfPoints detect: [ :each | each isZero not ] ifNone: [ 0 @ 0 ]
]

{ #category : 'private' }
VGPathBuilder >> fixedOf: aNumber [
	"A coordinate on the grid Cairo stores a path on. A cairo_fixed_t is twenty-four bits of
	 whole number and eight of fraction, so a device coordinate lands on a two hundred and fifty
	 sixth of a pixel, and the conversion rounds a half to the even neighbour. Both halves of the
	 rule are measured: a rectangle one five hundred and twelfth of a pixel wide paints nothing
	 on a live context, where a half rounded away from zero would make it paint an alpha of one."
	| scaled floor |
	scaled := aNumber * 256.
	floor := scaled floor.
	^ (scaled - floor = (1 / 2)
		   ifTrue: [ floor even ifTrue: [ floor ] ifFalse: [ floor + 1 ] ]
		   ifFalse: [ scaled rounded ]) / 256.0
]

{ #category : 'private' }
VGPathBuilder >> flattenCubicFrom: aPoint via: aControlPoint via: anotherControlPoint to: anEndPoint depth: anInteger [
	"Recursive subdivision: a curve flat enough to be its own chord is emitted as that chord, and
	 any other is halved. The end point is added by the caller, so each call adds only what lies
	 strictly inside its own span. Each emitted point is snapped, because a flattened point is a
	 path point like any other and Cairo holds it on the same grid."
	| middle leftControl leftAnother rightControl rightAnother leftEnd |
	(anInteger >= self class maximumSubdivisionDepth or: [
		 self isFlatFrom: aPoint via: aControlPoint via: anotherControlPoint to: anEndPoint ])
		ifTrue: [ ^ self ].
	leftControl := (aPoint + aControlPoint) / 2.
	middle := (aControlPoint + anotherControlPoint) / 2.
	rightAnother := (anotherControlPoint + anEndPoint) / 2.
	leftAnother := (leftControl + middle) / 2.
	rightControl := (middle + rightAnother) / 2.
	leftEnd := self snapped: (leftAnother + rightControl) / 2.
	self
		flattenCubicFrom: aPoint
		via: leftControl
		via: leftAnother
		to: leftEnd
		depth: anInteger + 1.
	points add: leftEnd.
	self
		flattenCubicFrom: leftEnd
		via: rightControl
		via: rightAnother
		to: anEndPoint
		depth: anInteger + 1
]

{ #category : 'accessing' }
VGPathBuilder >> flatteningTolerance [
	^ flatteningTolerance
]

{ #category : 'accessing' }
VGPathBuilder >> flatteningTolerance: aNumber [
	flatteningTolerance := aNumber
]

{ #category : 'building' }
VGPathBuilder >> flushRun [
	"Move the run being built into the finished runs. A run of one point draws nothing: a move to
	 that nothing follows leaves no mark in Cairo either."
	points size >= 2 ifTrue: [
		subPaths add: (self runOfPoints: points asArray closed: false) ].
	points := OrderedCollection new.
	startTangent := nil.
	endTangent := nil
]

{ #category : 'accessing' }
VGPathBuilder >> hasCurrentPoint [
	^ currentPoint notNil
]

{ #category : 'initialization' }
VGPathBuilder >> initialize [
	super initialize.
	subPaths := OrderedCollection new.
	points := OrderedCollection new.
	flatteningTolerance := self class defaultFlatteningTolerance
]

{ #category : 'inspector' }
VGPathBuilder >> inspectorBuilding: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Building'>
	"What a fill would consume right now. The values come from the real readers, and `path` is a
	 value that includes the run still open, so looking does not end the run."

	^ aBuilder newTable
		  items: {
				  ('Finished runs' -> subPaths size).
				  ('Points in the open run' -> points size).
				  ('Current point' -> self currentPoint).
				  ('Has a current point' -> self hasCurrentPoint).
				  ('Start of the run' -> startPoint).
				  ('Flattening tolerance' -> self flatteningTolerance).
				  ('Runs the path answers' -> self path subPaths size).
				  ('Points the path answers' -> self path pointCount).
				  ('Bounding box' -> self path boundingBox) };
		  addColumn: (SpStringTableColumn
				   title: 'Property'
				   evaluated: [ :each | each key ]);
		  addColumn: (SpStringTableColumn
				   title: 'Value'
				   evaluated: [ :each | each value printString ]);
		  yourself
]

{ #category : 'inspector' }
VGPathBuilder >> inspectorBuildingContext: aContext [
	aContext active: subPaths notNil
]

{ #category : 'testing' }
VGPathBuilder >> isAtRunStart [
	"Whether the next segment appended will be the first of the run being built. A caller that
	 appends a curve as chords of its own asks this before it starts, so that it can hand back the
	 curve's tangents afterwards and say whether they are the tangents of the run as well."
	^ points size <= 1
]

{ #category : 'accessing' }
VGPathBuilder >> isEmpty [
	^ self path isEmpty
]

{ #category : 'private' }
VGPathBuilder >> isFlatFrom: aPoint via: aControlPoint via: anotherControlPoint to: anEndPoint [
	"Flat when both control points lie within the tolerance of the chord. Cairo measures the error
	 the same way, by the distance from the control points to the line the chord lies on."
	^ (self distanceFrom: aControlPoint toLineFrom: aPoint to: anEndPoint)
	  <= flatteningTolerance and: [
		  (self distanceFrom: anotherControlPoint toLineFrom: aPoint to: anEndPoint)
		  <= flatteningTolerance ]
]

{ #category : 'building' }
VGPathBuilder >> lineTo: aPoint [
	"Cairo treats a line to with no current point as a move to rather than as an error."
	| point direction |
	self hasCurrentPoint ifFalse: [ ^ self moveTo: aPoint ].
	point := self snapped: aPoint.
	direction := point - currentPoint.
	self
		noteTangentsFrom: direction
		to: direction
		firstSegment: points size = 1.
	points add: point.
	currentPoint := point
]

{ #category : 'building' }
VGPathBuilder >> moveTo: aPoint [
	| point |
	point := self snapped: aPoint.
	self flushRun.
	points := OrderedCollection with: point.
	startPoint := point.
	currentPoint := point
]

{ #category : 'building' }
VGPathBuilder >> noteTangentsFrom: aPoint to: anotherPoint firstSegment: aBoolean [
	"Remember the directions of the segment just added: a curve leaves its first point and arrives
	 at its last one in two different directions, a line in one and the same. The first segment of
	 a run gives the run its start tangent and every segment gives the run its end tangent. A
	 direction of nothing is no direction at all and is not remembered.

	 A caller that flattens a curve itself, as an arc does, sends this with the curve's own two
	 tangents once its chords are in, so that the run remembers the direction the curve had and
	 not the direction of the first and last chord. A stroke reads those to tell a seam that
	 passes smoothly through its own first point from a corner Cairo caps."
	(aBoolean and: [ aPoint isZero not ]) ifTrue: [ startTangent := aPoint ].
	anotherPoint isZero ifFalse: [ endTangent := anotherPoint ]
]

{ #category : 'accessing' }
VGPathBuilder >> path [
	"The path built so far, as a value: the run still open is included, and building on afterwards
	 cannot change what this answers."
	| all |
	all := subPaths asArray.
	points size >= 2 ifTrue: [
		all := all , { (self runOfPoints: points asArray closed: false) } ].
	^ VGPath subPaths: all
]

{ #category : 'printing' }
VGPathBuilder >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPutAll: '(';
		print: self path;
		nextPut: $)
]

{ #category : 'building' }
VGPathBuilder >> quadraticVia: aControlPoint to: aPoint [
	"Cairo has no quadratic primitive, so the quadratic is raised to the cubic with the same shape:
	 each cubic control point is a third of the way from an end point to the quadratic control."
	| from |
	self hasCurrentPoint ifFalse: [ self moveTo: aControlPoint ].
	from := currentPoint.
	self
		curveVia: from + ((aControlPoint - from) * (2 / 3))
		via: aPoint + ((aControlPoint - aPoint) * (2 / 3))
		to: aPoint
]

{ #category : 'private' }
VGPathBuilder >> runOfPoints: aPointCollection closed: aBoolean [
	"The run those points make, carrying the tangents of the run being built."
	^ VGSubPath
		  points: aPointCollection
		  closed: aBoolean
		  startTangent: startTangent
		  endTangent: endTangent
]

{ #category : 'private' }
VGPathBuilder >> snapped: aPoint [
	"The point Cairo would store for this one. Snapping here, where device coordinates arrive,
	 is what keeps our coverage and Cairo's from drifting apart on a shape thinner than a step
	 of the grid."
	^ (self fixedOf: aPoint x) @ (self fixedOf: aPoint y)
]
