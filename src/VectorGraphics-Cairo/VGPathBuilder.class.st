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
		'flatteningTolerance'
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
	"A closed run bounds its own area and the current point goes back to where the run started, so
	 that drawing on begins a new run from there, which is what Cairo does."
	points size < 2 ifTrue: [ ^ self ].
	subPaths add: (VGSubPath points: points asArray closed: true).
	points := OrderedCollection with: startPoint.
	currentPoint := startPoint
]

{ #category : 'accessing' }
VGPathBuilder >> currentPoint [
	^ currentPoint
]

{ #category : 'building' }
VGPathBuilder >> curveVia: aControlPoint via: anotherControlPoint to: aPoint [
	self hasCurrentPoint ifFalse: [ self moveTo: aControlPoint ].
	self
		flattenCubicFrom: currentPoint
		via: aControlPoint
		via: anotherControlPoint
		to: aPoint
		depth: 0.
	points add: aPoint.
	currentPoint := aPoint
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
VGPathBuilder >> flattenCubicFrom: aPoint via: aControlPoint via: anotherControlPoint to: anEndPoint depth: anInteger [
	"Recursive subdivision: a curve flat enough to be its own chord is emitted as that chord, and
	 any other is halved. The end point is added by the caller, so each call adds only what lies
	 strictly inside its own span."
	| middle leftControl leftAnother rightControl rightAnother leftEnd |
	(anInteger >= self class maximumSubdivisionDepth or: [
		 self isFlatFrom: aPoint via: aControlPoint via: anotherControlPoint to: anEndPoint ])
		ifTrue: [ ^ self ].
	leftControl := (aPoint + aControlPoint) / 2.
	middle := (aControlPoint + anotherControlPoint) / 2.
	rightAnother := (anotherControlPoint + anEndPoint) / 2.
	leftAnother := (leftControl + middle) / 2.
	rightControl := (middle + rightAnother) / 2.
	leftEnd := (leftAnother + rightControl) / 2.
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

{ #category : 'private' }
VGPathBuilder >> flushRun [
	"Move the run being built into the finished runs. A run of one point draws nothing: a move to
	 that nothing follows leaves no mark in Cairo either."
	points size >= 2 ifTrue: [
		subPaths add: (VGSubPath points: points asArray closed: false) ].
	points := OrderedCollection new
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
	self hasCurrentPoint ifFalse: [ ^ self moveTo: aPoint ].
	points add: aPoint.
	currentPoint := aPoint
]

{ #category : 'building' }
VGPathBuilder >> moveTo: aPoint [
	self flushRun.
	points := OrderedCollection with: aPoint.
	startPoint := aPoint.
	currentPoint := aPoint
]

{ #category : 'converting' }
VGPathBuilder >> path [
	"The path built so far, as a value: the run still open is included, and building on afterwards
	 cannot change what this answers."
	| all |
	all := subPaths asArray.
	points size >= 2 ifTrue: [
		all := all , { (VGSubPath points: points asArray closed: false) } ].
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
