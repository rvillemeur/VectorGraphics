"
I am one run of a path: a sequence of points in device space, and whether it is closed.

My points are already flattened, so a curve has become the polyline that stands for it within the
tolerance in force when it was built.
I am immutable: a path that outlives a fill, which is what fillPreservingPath asks for, can be
handed to two entries of the display list without either seeing the other's changes.
Filling closes me whatever my isClosed answers, because an area has to have a boundary; stroking is
the operation that cares.
"
Class {
	#name : 'VGSubPath',
	#superclass : 'Object',
	#instVars : [
		'points',
		'isClosed',
		'startTangent',
		'endTangent'
	],
	#category : 'VectorGraphics-Cairo-Path',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Path'
}

{ #category : 'constants' }
VGSubPath class >> directionTolerance [
	"How far two directions may turn from one another and still count as the same, as a tangent of
	 that angle. A path point sits on Cairo's grid of two hundred and fifty-sixths, so a control
	 point ten pixels out carries a rounding of some four ten-thousandths of a radian; this is
	 loose enough to swallow that and far too tight to swallow a corner."
	^ 0.001
]

{ #category : 'instance creation' }
VGSubPath class >> points: aPointCollection closed: aBoolean [
	^ self new setPoints: aPointCollection asArray closed: aBoolean
]

{ #category : 'instance creation' }
VGSubPath class >> points: aPointCollection closed: aBoolean startTangent: aTangent endTangent: anotherTangent [
	"A run that also remembers the direction the path leaves its first point in and the direction
	 it arrives at its last point in. Those two are the chords themselves for a run of straight
	 lines, and the tangents of the spline for a run that was flattened from one, which is the
	 whole reason to carry them: the chords of a flattened curve do not answer the direction the
	 curve itself had at its ends."
	^ self new
		  setPoints: aPointCollection asArray
		  closed: aBoolean
		  startTangent: aTangent
		  endTangent: anotherTangent
]

{ #category : 'enumerating' }
VGSubPath >> closedEdgesDo: aBlock [
	"Every edge of the area I bound, which closes me whether I was closed or not: an unclosed run
	 still encloses an area, and Cairo fills it as if the closing edge were there."
	self edgesDo: aBlock.
	points first = points last ifFalse: [ aBlock value: points last value: points first ]
]

{ #category : 'testing' }
VGSubPath >> comesBackToItsStartSmoothly [
	"Whether I end where I began and arrive there in the direction I left in. The full circle
	 cairo_arc draws is such a run: Cairo strokes the spline and its stroke is the whole annulus,
	 with nothing missing where the two ends meet, so a stroke of my chords has to fill the wedge
	 between the last chord and the first. Two ends that meet at an angle are a corner Cairo caps
	 instead, and a run of fewer than three points has no wedge at all."
	| incoming outgoing |
	points size > 2 ifFalse: [ ^ false ].
	points first = points last ifFalse: [ ^ false ].
	incoming := endTangent ifNil: [ points last - (points at: points size - 1) ].
	outgoing := startTangent ifNil: [ (points at: 2) - points first ].
	^ self isDirection: incoming theSameAs: outgoing
]

{ #category : 'enumerating' }
VGSubPath >> edgesDo: aBlock [
	"Every edge of mine as a pair of points, in order, without closing me."
	1 to: points size - 1 do: [ :index |
		aBlock value: (points at: index) value: (points at: index + 1) ]
]

{ #category : 'accessing' }
VGSubPath >> endTangent [
	"The direction the path arrives at my last point in, as the path itself had it, or nil when my
	 last chord answers for it."
	^ endTangent
]

{ #category : 'accessing' }
VGSubPath >> first [
	^ points first
]

{ #category : 'inspector' }
VGSubPath >> inspectorPoints: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Points'>
	"My points in order, in device space, with the edge each one starts. The closing edge of a
	 closed run is shown against the last point, because that is the edge the run adds."

	^ aBuilder newTable
		  items: (1 to: points size) asArray;
		  addColumn: (SpStringTableColumn
				   title: 'Index'
				   evaluated: [ :index | index printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'X'
				   evaluated: [ :index | (points at: index) x printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Y'
				   evaluated: [ :index | (points at: index) y printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Edge to'
				   evaluated: [ :index |
					   index < points size
						   ifTrue: [ (points at: index + 1) printString ]
						   ifFalse: [
							   isClosed
								   ifTrue: [ points first printString ]
								   ifFalse: [ '' ] ] ]);
		  yourself
]

{ #category : 'inspector' }
VGSubPath >> inspectorPointsContext: aContext [
	aContext active: points notNil
]

{ #category : 'inspector' }
VGSubPath >> inspectorSeam: aBuilder [
	<inspectorPresentationOrder: 20 title: 'Seam'>
	"What happens where my two ends meet: the directions the path really left and arrived in, the
	 chords that stand for them, and the answer of the predicate a stroke asks, so that the view
	 cannot drift from the rule. A smooth seam is stroked with a join in the wedge between the two
	 end chords; a seam that turns is capped, as Cairo caps it."
	^ aBuilder newTable
		  items: {
				  { 'Ends meet'. (points first = points last) printString }.
				  { 'Leaves in'. (startTangent ifNil: [ (points at: 2) - points first ]) printString }.
				  { 'Arrives in'.
				  (endTangent ifNil: [ points last - (points at: points size - 1) ]) printString }.
				  { 'Tangent of its own'. (startTangent notNil and: [ endTangent notNil ]) printString }.
				  { 'Comes back smoothly'. self comesBackToItsStartSmoothly printString }.
				  { 'Stroked seam'.
				  (self comesBackToItsStartSmoothly
					   ifTrue: [ 'joined' ]
					   ifFalse: [ 'capped' ]) } };
		  addColumn: (SpStringTableColumn
				   title: 'Question'
				   evaluated: [ :each | each first ]);
		  addColumn: (SpStringTableColumn
				   title: 'Answer'
				   evaluated: [ :each | each second ]);
		  yourself
]

{ #category : 'inspector' }
VGSubPath >> inspectorSeamContext: aContext [
	"A run of fewer than three points has no seam to show: there is no chord on either side of
	 its first point."
	aContext active: (points notNil and: [ points size > 2 ])
]

{ #category : 'accessing' }
VGSubPath >> isClosed [
	^ isClosed
]

{ #category : 'private' }
VGSubPath >> isDirection: aPoint theSameAs: anotherPoint [
	"Whether two directions point the same way, to within the tolerance of the grid the path sits
	 on. The cross product over the dot product is the tangent of the angle between them, which
	 saves a square root, and a dot product of nothing or less means they point apart."
	| cross dot |
	(aPoint isZero or: [ anotherPoint isZero ]) ifTrue: [ ^ false ].
	dot := (aPoint x * anotherPoint x) + (aPoint y * anotherPoint y).
	dot > 0 ifFalse: [ ^ false ].
	cross := (aPoint x * anotherPoint y) - (aPoint y * anotherPoint x).
	^ cross abs <= (dot * self class directionTolerance)
]

{ #category : 'accessing' }
VGSubPath >> last [
	^ points last
]

{ #category : 'accessing' }
VGSubPath >> points [
	^ points
]

{ #category : 'printing' }
VGSubPath >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPutAll: '(';
		print: points size;
		nextPutAll: ' points';
		nextPutAll: (isClosed ifTrue: [ ', closed' ] ifFalse: [ '' ]);
		nextPut: $)
]

{ #category : 'initialization' }
VGSubPath >> setPoints: aPointArray closed: aBoolean [
	"A run with no tangent of its own: its chords answer for its directions, which is right for a
	 run of straight lines."
	self
		setPoints: aPointArray
		closed: aBoolean
		startTangent: nil
		endTangent: nil
]

{ #category : 'initialization' }
VGSubPath >> setPoints: aPointArray closed: aBoolean startTangent: aTangent endTangent: anotherTangent [
	points := aPointArray.
	isClosed := aBoolean.
	startTangent := aTangent.
	endTangent := anotherTangent
]

{ #category : 'accessing' }
VGSubPath >> size [
	^ points size
]

{ #category : 'accessing' }
VGSubPath >> startTangent [
	"The direction the path leaves my first point in, as the path itself had it, or nil when my
	 first chord answers for it."
	^ startTangent
]
