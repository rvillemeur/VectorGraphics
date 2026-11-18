"
I am one contour of a glyph drawn by a Type 2 charstring: a point it starts at, and the segments that leave it.

A segment is the points a charstring gives for it: one point is a straight line to that point, three are the two control points and the end point of a cubic curve. The points are absolute and in font units, since a charstring states every one of them as a step from the point before.

I am closed, always: a contour of a charstring closes from its last point back to its start, and no byte says so. My closing line is not one of my segments, because a reader that draws me closes me itself.
"
Class {
	#name : 'TTCffContour',
	#superclass : 'Object',
	#instVars : [
		'start',
		'segments'
	],
	#category : 'VectorGraphics-TrueType-CFF',
	#package : 'VectorGraphics-TrueType',
	#tag : 'CFF'
}

{ #category : 'instance creation' }
TTCffContour class >> startingAt: aPoint [
	^ self new
		  startAt: aPoint;
		  yourself
]

{ #category : 'converting' }
TTCffContour >> addQuadraticsFrom: aPoint to: aSegment on: aPointCollection controls: aBooleanCollection withinTolerance: aNumber [
	"One cubic of mine, written as the quadratics that hold it: a control point off the
	 curve and an end point on it, for each of them."

	| cubic |
	cubic := TTCffCubic
		         from: aPoint
		         via: aSegment first
		         and: aSegment second
		         to: aSegment third.
	(cubic quadraticsWithinTolerance: aNumber) do: [ :each |
		aPointCollection
			add: each first;
			add: each second.
		aBooleanCollection
			add: true;
			add: false ]
]

{ #category : 'building' }
TTCffContour >> addSegment: aCollectionOfPoints [
	"One segment of me: a point is a straight line to it, three points a cubic curve."

	segments add: aCollectionOfPoints
]

{ #category : 'converting' }
TTCffContour >> contourConstructionWithinTolerance: aNumber [
	"The same contour as a TrueType one: one array of points, each of them on the curve or
	 off it, holding me to within that many font units. Every cubic becomes a chain of
	 quadratics, and each quadratic writes its control point off the curve and its end
	 point on it. The point I close at is written once, since both kinds of contour close
	 themselves."

	| points controls construction |
	points := OrderedCollection with: start.
	controls := OrderedCollection with: false.
	segments do: [ :each |
		each size = 1
			ifTrue: [
				points add: each first.
				controls add: false ]
			ifFalse: [
				self
					addQuadraticsFrom: points last
					to: each
					on: points
					controls: controls
					withinTolerance: aNumber ] ].
	(points size > 1 and: [ points last = points first ]) ifTrue: [
		points removeLast.
		controls removeLast ].
	construction := TTContourConstruction on: (Int16PointArray new: points size).
	points doWithIndex: [ :each :index |
		construction points at: index put: each rounded.
		construction controlPointFlags
			bitAt: index
			put: ((controls at: index)
					 ifTrue: [ 1 ]
					 ifFalse: [ 0 ]) ].
	^ construction
]

{ #category : 'inspector' }
TTCffContour >> inspectorSegments: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Segments'>
	"One row per segment, in the order they were drawn: a segment of one point is a line and
	 a segment of three is a cubic curve, which is what the row says by counting its own
	 points rather than by being told."

	^ aBuilder newTable
		  addColumn: ((SpStringTableColumn title: 'Step' evaluated: [ :each |
				    (segments indexOf: each) printString ]) width: 60);
		  addColumn: ((SpStringTableColumn title: 'Kind' evaluated: [ :each |
				    each size = 1
					    ifTrue: [ 'line' ]
					    ifFalse: [ 'curve' ] ]) width: 80);
		  addColumn: ((SpStringTableColumn title: 'Ends at' evaluated: [ :each |
				    each last printString ]) width: 120);
		  addColumn: (SpStringTableColumn title: 'Control points' evaluated: [ :each |
			   each allButLast printString ]);
		  items: segments;
		  yourself
]

{ #category : 'inspector' }
TTCffContour >> inspectorTrueTypePoints: aBuilder [
	<inspectorPresentationOrder: 20 title: 'TrueType points'>
	"The same contour as a TrueType one holds it, at the tolerance a glyph is built with:
	 one row a point, saying whether it lies on the curve or is the control point of a
	 quadratic, and what it rounds to in whole font units."

	| construction rows |
	construction := self contourConstructionWithinTolerance:
		                TTCffTableParser quadraticTolerance.
	rows := (1 to: construction points size) asArray.
	^ aBuilder newTable
		  addColumn: ((SpStringTableColumn title: 'Point' evaluated: [ :each |
				    each printString ]) width: 60);
		  addColumn: ((SpStringTableColumn title: 'At' evaluated: [ :each |
				    (construction points at: each) printString ]) width: 140);
		  addColumn: (SpStringTableColumn title: 'On the curve' evaluated: [ :each |
			   (construction controlPointFlags bitBooleanAt: each)
				   ifTrue: [ 'no, a control point' ]
				   ifFalse: [ 'yes' ] ]);
		  items: rows;
		  yourself
]

{ #category : 'testing' }
TTCffContour >> isClosed [
	"Always. A contour of a charstring closes from its last point back to its start."

	^ true
]

{ #category : 'testing' }
TTCffContour >> isEmpty [
	"A contour a charstring opened and left without a single segment, which a font writes when
	 one move follows another."

	^ segments isEmpty
]

{ #category : 'accessing' }
TTCffContour >> lastPoint [
	"The point I end at before closing, which is my start when nothing was drawn from it."

	^ segments ifEmpty: [ start ] ifNotEmpty: [ segments last last ]
]

{ #category : 'accessing' }
TTCffContour >> points [
	"Every point I hold, my start first, control points among them."

	^ Array streamContents: [ :stream |
		  stream nextPut: start.
		  segments do: [ :each | stream nextPutAll: each ] ]
]

{ #category : 'printing' }
TTCffContour >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPut: $(;
		print: start;
		nextPutAll: ' and ';
		print: segments size;
		nextPutAll: ' segments)'
]

{ #category : 'accessing' }
TTCffContour >> segments [
	^ segments
]

{ #category : 'accessing' }
TTCffContour >> start [
	^ start
]

{ #category : 'building' }
TTCffContour >> startAt: aPoint [
	start := aPoint.
	segments := OrderedCollection new
]

{ #category : 'building' }
TTCffContour >> translatedBy: aPoint [
	"A contour of the same shape, every point of it moved by that step."

	| copy |
	copy := self class startingAt: start + aPoint.
	segments do: [ :each |
		copy addSegment: (each collect: [ :point | point + aPoint ]) ].
	^ copy
]
