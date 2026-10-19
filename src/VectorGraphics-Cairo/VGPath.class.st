"
I am a path: an ordered collection of VGSubPath runs in device space.

Cairo transforms a coordinate when the construction call is made, not when the path is painted, so
my points are already in device space and my filling needs no matrix.
I am immutable, and VGPathBuilder is what builds me.
"
Class {
	#name : 'VGPath',
	#superclass : 'Object',
	#instVars : [
		'subPaths'
	],
	#category : 'VectorGraphics-Cairo-Path',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Path'
}

{ #category : 'instance creation' }
VGPath class >> empty [
	^ self subPaths: #()
]

{ #category : 'instance creation' }
VGPath class >> subPaths: aCollection [
	^ self new setSubPaths: aCollection asArray
]

{ #category : 'geometry' }
VGPath >> boundingBox [
	"The device-space rectangle my points live in, or nil when I have none. A rasteriser reads it
	 to know which rows it has to visit at all."
	| left top right bottom |
	self isEmpty ifTrue: [ ^ nil ].
	left := Float infinity.
	top := Float infinity.
	right := Float infinity negated.
	bottom := Float infinity negated.
	subPaths do: [ :subPath |
		subPath points do: [ :point |
			left := left min: point x.
			right := right max: point x.
			top := top min: point y.
			bottom := bottom max: point y ] ].
	^ left @ top corner: right @ bottom
]

{ #category : 'enumerating' }
VGPath >> closedEdgesDo: aBlock [
	"Every edge of the area this path bounds, over all of its runs."
	subPaths do: [ :each | each closedEdgesDo: aBlock ]
]

{ #category : 'geometry' }
VGPath >> edgeCoordinates [
	"My edges as a flat array of x0, y0, x1, y1 quadruples, which is what a VGSegments carries over
	 the backend boundary: nothing below the boundary may hear about a path or a curve."
	| stream |
	stream := WriteStream on: (Array new: self pointCount * 4).
	self closedEdgesDo: [ :from :to |
		stream
			nextPut: from x asFloat;
			nextPut: from y asFloat;
			nextPut: to x asFloat;
			nextPut: to y asFloat ].
	^ stream contents
]

{ #category : 'initialization' }
VGPath >> initialize [
	super initialize.
	subPaths := #()
]

{ #category : 'inspector' }
VGPath >> inspectorSubPaths: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Sub-paths'>
	"The runs as the path holds them, each with the number of edges it really contributes: a
	 closed run contributes one more edge than an open run of the same points, which is why the
	 column counts them rather than restating the point count."

	^ aBuilder newTable
		  items: (1 to: subPaths size) asArray;
		  addColumn: (SpStringTableColumn
				   title: 'Run'
				   evaluated: [ :index | index printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Points'
				   evaluated: [ :index | (subPaths at: index) size printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Closed'
				   evaluated: [ :index | (subPaths at: index) isClosed printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Edges'
				   evaluated: [ :index |
					   | count |
					   count := 0.
					   (subPaths at: index) closedEdgesDo: [ :from :to | count := count + 1 ].
					   count printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'From'
				   evaluated: [ :index | (subPaths at: index) first printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'To'
				   evaluated: [ :index | (subPaths at: index) last printString ]);
		  yourself
]

{ #category : 'inspector' }
VGPath >> inspectorSubPathsContext: aContext [
	aContext active: self notEmpty
]

{ #category : 'accessing' }
VGPath >> isEmpty [
	^ subPaths isEmpty
]

{ #category : 'accessing' }
VGPath >> notEmpty [
	^ subPaths notEmpty
]

{ #category : 'accessing' }
VGPath >> pointCount [
	^ subPaths inject: 0 into: [ :sum :each | sum + each size ]
]

{ #category : 'printing' }
VGPath >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPutAll: '(';
		print: subPaths size;
		nextPutAll: ' runs, ';
		print: self pointCount;
		nextPutAll: ' points)' 
]

{ #category : 'geometry' }
VGPath >> segmentsWithFillRule: aSymbol [
	^ VGSegments coordinates: self edgeCoordinates fillRule: aSymbol
]

{ #category : 'initialization' }
VGPath >> setSubPaths: anArray [
	subPaths := anArray
]

{ #category : 'accessing' }
VGPath >> subPaths [
	^ subPaths
]
