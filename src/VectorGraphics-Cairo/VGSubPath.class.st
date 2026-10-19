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
		'isClosed'
	],
	#category : 'VectorGraphics-Cairo-Path',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Path'
}

{ #category : 'instance creation' }
VGSubPath class >> points: aPointCollection closed: aBoolean [
	^ self new setPoints: aPointCollection asArray closed: aBoolean
]

{ #category : 'enumerating' }
VGSubPath >> closedEdgesDo: aBlock [
	"Every edge of the area I bound, which closes me whether I was closed or not: an unclosed run
	 still encloses an area, and Cairo fills it as if the closing edge were there."
	self edgesDo: aBlock.
	points first = points last ifFalse: [ aBlock value: points last value: points first ]
]

{ #category : 'enumerating' }
VGSubPath >> edgesDo: aBlock [
	"Every edge of mine as a pair of points, in order, without closing me."
	1 to: points size - 1 do: [ :index |
		aBlock value: (points at: index) value: (points at: index + 1) ]
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

{ #category : 'accessing' }
VGSubPath >> isClosed [
	^ isClosed
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
	points := aPointArray.
	isClosed := aBoolean
]

{ #category : 'accessing' }
VGSubPath >> size [
	^ points size
]
