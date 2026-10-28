"
I index the edges of one shape by the band of rows each of them lives in, so that a question about one pixel row or one tile reads only the edges near it.

A shape reaching a tiled rasteriser can carry hundreds of edges, and the two questions asked of it once a tile — whether an edge of it touches the tile, and what the winding is at the middle of the tile — are both scans over every edge. Over the tiles of a frame those scans are the cost of the questions rather than of the answers. I cut the bounding box of the shape into bands of rows and hold each edge in every band its own box reaches. A band is read once, and an edge is held once in each band, so a winding counted over a band counts each edge once, which a grid of cells in two directions could not promise without remembering which edges it had seen.

I am built once a shape, by VGSpanScanner, and my coordinates never change afterwards. 'coordinates:bounds:' chooses the band count from the number of edges; 'coordinates:bounds:bands:' states it, and an index of one band is the scan over every edge that I replace, which is what a test compares me against.
"
Class {
	#name : 'VGEdgeIndex',
	#superclass : 'Object',
	#instVars : [
		'coordinates',
		'bounds',
		'bandTop',
		'bandCount',
		'bandHeight',
		'bands'
	],
	#category : 'VectorGraphics-Cairo-Rasterising',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Rasterising'
}

{ #category : 'instance creation' }
VGEdgeIndex class >> coordinates: anArray bounds: aRectangle [
	"The index of those edges, with the band count chosen from how many there are: a band holds
	 edgesPerBand of them where they are spread evenly, which is the point at which reading a
	 band costs about as much as the scan it saves."

	| count |
	count := (anArray size / 4 / self edgesPerBand) ceiling.
	^ self
		  coordinates: anArray
		  bounds: aRectangle
		  bands: ((count max: 1) min: self maximumBandCount)
]

{ #category : 'instance creation' }
VGEdgeIndex class >> coordinates: anArray bounds: aRectangle bandHeight: aHeight [
	"The index of those edges in bands of that height, each band starting at a multiple of it.
	 The tiled encoding asks for these, because the band of a tile has to be the rows of that
	 tile and no band may straddle two rows of tiles."

	^ self new
		  setCoordinates: anArray
		  bounds: aRectangle
		  bandHeight: aHeight
]

{ #category : 'instance creation' }
VGEdgeIndex class >> coordinates: anArray bounds: aRectangle bands: aBandCount [
	^ self new setCoordinates: anArray bounds: aRectangle bands: aBandCount
]

{ #category : 'constants' }
VGEdgeIndex class >> edgesPerBand [
	"How many edges a band is meant to hold. Eight is small enough that a tile reads a handful of
	 edges, and large enough that the bands of a shape of a few edges cost nothing to build."

	^ 8
]

{ #category : 'constants' }
VGEdgeIndex class >> maximumBandCount [
	"The most bands an index may have. A shape of ten thousand edges would otherwise be cut into
	 more bands than the frame has pixel rows, and the bands themselves would cost more than the
	 scan they save."

	^ 64
]

{ #category : 'testing' }
VGEdgeIndex >> anEdgeMeets: aRectangle [
	"Whether any edge of the shape touches that closed rectangle. Only the bands the rectangle
	 spans are read, and an edge in two of them is asked twice rather than remembered, because
	 remembering it would allocate and this is asked of one shape once a tile."

	(self bandOf: aRectangle top) to: (self bandOf: aRectangle bottom) do: [
		:band |
		(bands at: band) do: [ :index |
			(self edgeAt: index meets: aRectangle) ifTrue: [ ^ true ] ] ].
	^ false
]

{ #category : 'accessing' }
VGEdgeIndex >> bandCount [
	^ bandCount
]

{ #category : 'private' }
VGEdgeIndex >> bandOf: aNumber [
	"An index of one band never divides, because the box of a shape whose edges all lie on one
	 row has no height. A row outside the bands answers the nearest one, whose edges then fail
	 every test a caller makes of them, which is the answer such a row owes."

	bandCount = 1 ifTrue: [ ^ 1 ].
	^ ((aNumber - bandTop / bandHeight) floor + 1 max: 1) min: bandCount
]

{ #category : 'accessing' }
VGEdgeIndex >> boundsOfBandAt: aBandIndex [
	| top |
	top := bandTop + (aBandIndex - 1 * bandHeight).
	^ bounds left @ top corner: bounds right @ (top + bandHeight)
]

{ #category : 'accessing' }
VGEdgeIndex >> boxOfEdgeAt: anIndex [
	"The rectangle the edge at that coordinate lives in. The index is the one the coordinates
	 array uses, counting four numbers to an edge."

	| x0 y0 x1 y1 |
	x0 := coordinates at: anIndex.
	y0 := coordinates at: anIndex + 1.
	x1 := coordinates at: anIndex + 2.
	y1 := coordinates at: anIndex + 3.
	^ (x0 min: x1) @ (y0 min: y1) corner: (x0 max: x1) @ (y0 max: y1)
]

{ #category : 'private' }
VGEdgeIndex >> edgeAt: anIndex hasEveryCornerOnOneSideOf: aRectangle [
	"Whether every corner of the rectangle lies strictly on one side of the line the edge at that
	 coordinate runs along. The edge then cannot touch the rectangle, whatever the two axes of
	 the rectangle say, and those three tests together are exact for a segment against a
	 rectangle. An edge of no length puts every corner at distance nought on its own line and so
	 answers false, which is the conservative way round."

	| x0 y0 normalX normalY at topLeft topRight bottomRight bottomLeft |
	x0 := coordinates at: anIndex.
	y0 := coordinates at: anIndex + 1.
	normalX := (coordinates at: anIndex + 3) - y0.
	normalY := x0 - (coordinates at: anIndex + 2).
	at := normalX * x0 + (normalY * y0).
	topLeft := normalX * aRectangle left + (normalY * aRectangle top) - at.
	topRight := normalX * aRectangle right + (normalY * aRectangle top) - at.
	bottomRight := normalX * aRectangle right
	               + (normalY * aRectangle bottom) - at.
	bottomLeft := normalX * aRectangle left
	              + (normalY * aRectangle bottom) - at.
	(topLeft > 0 and: [
		 topRight > 0 and: [ bottomRight > 0 and: [ bottomLeft > 0 ] ] ])
		ifTrue: [ ^ true ].
	^ topLeft < 0 and: [
		  topRight < 0 and: [ bottomRight < 0 and: [ bottomLeft < 0 ] ] ]
]

{ #category : 'private' }
VGEdgeIndex >> edgeAt: anIndex meets: aRectangle [
	"Whether the edge at that coordinate touches the closed rectangle. The two axes of the
	 rectangle answer most edges on their own, so they are asked first, and the line of the edge
	 only for what is left. Nothing is allocated here."

	| x0 x1 y0 y1 |
	x0 := coordinates at: anIndex.
	x1 := coordinates at: anIndex + 2.
	((x0 max: x1) < aRectangle left or: [
		 (x0 min: x1) > aRectangle right ]) ifTrue: [ ^ false ].
	y0 := coordinates at: anIndex + 1.
	y1 := coordinates at: anIndex + 3.
	((y0 max: y1) < aRectangle top or: [
		 (y0 min: y1) > aRectangle bottom ]) ifTrue: [ ^ false ].
	^ (self edgeAt: anIndex hasEveryCornerOnOneSideOf: aRectangle) not
]

{ #category : 'accessing' }
VGEdgeIndex >> edgeCount [
	^ coordinates size // 4
]

{ #category : 'accessing' }
VGEdgeIndex >> edgeIndexesInBandAt: aBandIndex [
	"The coordinate indexes of the edges held in that band, in the order they were given."

	^ bands at: aBandIndex
]

{ #category : 'accessing' }
VGEdgeIndex >> edgeIndexesMeetingRowsFrom: aTop to: aBottom [
	"The coordinate indexes of the edges that may cross the rows between those two numbers,
	 which are the rows of one band of mine. Rows the box of the shape does not reach hold no
	 edge at all: bandOf: answers the nearest band for a row outside the box, and the edges of
	 that band cannot cross such a row, so answering them would cost a caller the reading and
	 tell it nothing. The ends are read open, because a box that only touches a row along its
	 own edge encloses no part of it."

	(bounds top < aBottom and: [ bounds bottom > aTop ]) ifFalse: [ ^ #(  ) ].
	^ self edgeIndexesInBandAt: (self bandOf: aTop)
]

{ #category : 'initialization' }
VGEdgeIndex >> fillBands [
	"Every edge into every band its own rows reach. An edge is held as its index into the
	 coordinates, so that no edge is copied and an answer is read from the array the shape
	 already carries. A band holds its edges in the order they were given, which is the order a
	 scan over every edge would read them in."

	| streams |
	streams := (1 to: bandCount) collect: [ :each |
		           WriteStream on: (Array new: 8) ].
	1 to: coordinates size by: 4 do: [ :index |
		| top bottom |
		top := (coordinates at: index + 1) min: (coordinates at: index + 3).
		bottom := (coordinates at: index + 1) max: (coordinates at: index + 3).
		(self bandOf: top) to: (self bandOf: bottom) do: [ :band |
			(streams at: band) nextPut: index ] ].
	bands := streams collect: [ :each | each contents ]
]

{ #category : 'inspector' }
VGEdgeIndex >> inspectorBands: aBuilder [
	<inspectorPresentationOrder: 1 title: 'Bands'>
	"Each band with the rows it covers, the edges it holds and the two questions the index is
	 asked. The columns send those questions to me rather than restating them, so a band that
	 holds an edge it does not reach shows as an edge box outside the band's own rows."

	^ aBuilder newTable
		  addColumn: (SpStringTableColumn title: 'Band' evaluated: [ :each |
					   each printString ]);
		  addColumn: (SpStringTableColumn title: 'Rows' evaluated: [ :each |
					   | box |
					   box := self boundsOfBandAt: each.
					   box top printString , ' to ' , box bottom printString ]);
		  addColumn: (SpStringTableColumn title: 'Edges' evaluated: [ :each |
					   (self edgeIndexesInBandAt: each) size printString ]);
		  addColumn: (SpStringTableColumn title: 'An edge meets its rows' evaluated: [ :each |
					   (self anEdgeMeets: (self boundsOfBandAt: each)) printString ]);
		  addColumn: (SpStringTableColumn title: 'Winding at its centre' evaluated: [ :each |
					   (self windingAt: (self boundsOfBandAt: each) center) printString ]);
		  addColumn: (SpStringTableColumn title: 'Boxes of its edges' evaluated: [ :each |
					   ((self edgeIndexesInBandAt: each) collect: [ :index |
						    self boxOfEdgeAt: index ]) asArray printString ]);
		  items: (1 to: self bandCount);
		  yourself
]

{ #category : 'inspector' }
VGEdgeIndex >> inspectorBandsContext: aContext [
	aContext active: bands isNotNil
]

{ #category : 'printing' }
VGEdgeIndex >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPutAll: ' of ';
		print: self edgeCount;
		nextPutAll: (self edgeCount = 1
				 ifTrue: [ ' edge over ' ]
				 ifFalse: [ ' edges over ' ]);
		print: bandCount;
		nextPutAll: (bandCount = 1
				 ifTrue: [ ' band' ]
				 ifFalse: [ ' bands' ])
]

{ #category : 'initialization' }
VGEdgeIndex >> setCoordinates: anArray bounds: aRectangle bandHeight: aHeight [
	"Bands of a fixed height, each starting at a multiple of it, so that a band is the rows of a
	 row of tiles and the caller may find the band of a tile from the tile alone. The box of a
	 shape whose edges all lie on one row still falls in one band, which the ceiling gives."

	coordinates := anArray.
	bounds := aRectangle.
	bandHeight := aHeight.
	bandTop := (aRectangle top / aHeight) floor * aHeight.
	bandCount := ((aRectangle bottom - bandTop / aHeight) ceiling max: 1).
	self fillBands
]

{ #category : 'initialization' }
VGEdgeIndex >> setCoordinates: anArray bounds: aRectangle bands: aBandCount [
	"A box of no height would divide by nought, so such a box is one band however many were
	 asked for. The bands cover the box exactly, so the first of them starts at its top."

	coordinates := anArray.
	bounds := aRectangle.
	bandTop := aRectangle top.
	bandCount := aRectangle height isZero
		             ifTrue: [ 1 ]
		             ifFalse: [ aBandCount ].
	bandHeight := aRectangle height / bandCount.
	self fillBands
]

{ #category : 'accessing' }
VGEdgeIndex >> windingAt: aPoint [
	"The winding number of the shape at that point: the edges that cross its row at or to the
	 left of it, counted up where they run downwards and down where they run upwards. Only the
	 band of its row is read, and an edge is held once in a band, so each crossing is counted
	 once. Nothing is allocated here, because a binning asks this of one shape once a tile."

	| x y winding |
	x := aPoint x.
	y := aPoint y.
	winding := 0.
	(bands at: (self bandOf: y)) do: [ :index |
		| y0 y1 |
		y0 := coordinates at: index + 1.
		y1 := coordinates at: index + 3.
		(y0 ~= y1 and: [
			 y >= (y0 min: y1) and: [ y < (y0 max: y1) ] ]) ifTrue: [
			| x0 x1 |
			x0 := coordinates at: index.
			x1 := coordinates at: index + 2.
			x0 + ((x1 - x0) * (y - y0) / (y1 - y0)) <= x ifTrue: [
				winding := winding + (y1 > y0
					            ifTrue: [ 1 ]
					            ifFalse: [ -1 ]) ] ] ].
	^ winding
]
