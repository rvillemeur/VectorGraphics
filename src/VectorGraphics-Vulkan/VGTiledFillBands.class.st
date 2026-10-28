"
The shape records of one frame cut into rows of tiles.
For every entry I hold every row of tiles it reaches, and for every shape of that entry the edges
of it that reach the rows of that row.
A tiled rasteriser walks the edges of a shape at fifteen sub-rows of every pixel of a tile, and an
edge whose own rows miss the rows of that tile cannot cross any of those sub-rows.
A tile that reads only the edges of its own row therefore reads fewer edges for exactly the same
answer: a ring of two hundred edges round a card costs a tile the twenty or so beside it rather
than all of them.

I am built from a binning, whose tiles decide which rows an entry reaches, and from the fills its
entries are drawn as.
VGTiledFillEncoding writes what I say into the shape and the edge buffer, and finds the block of
records a tile owes through blockOfEntry:inRowOfTile:.
Which shapes an entry has is mine to answer, through shapesOf:, so that the records and the bands
cannot disagree about the order of them.
"
Class {
	#name : 'VGTiledFillBands',
	#superclass : 'Object',
	#instVars : [
		'grid',
		'fills',
		'shapes',
		'indexes',
		'rows',
		'blockOffsets',
		'blockCount',
		'edgeCount',
		'shapeBase'
	],
	#category : 'VectorGraphics-Vulkan-Tiles',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Tiles'
}

{ #category : 'instance creation' }
VGTiledFillBands class >> binning: aBinning fills: anArray [
	"The bands of the frame that binning holds, whose entries are drawn as those fills. The
	 fills are given rather than asked of the entries, because rewriting a blit as a fill
	 samples its mask and the encoding has already done it once."

	^ self new setBinning: aBinning fills: anArray
]

{ #category : 'accessing' }
VGTiledFillBands class >> shapesOf: anEntry [
	"The shapes of an entry: the fill first and then every shape its clip was cut out with, all
	 of them as scanners, so that one kind of record describes a fill and a clip shape alike and
	 the kernel reads a shape without asking where it came from. This is the one place that
	 decides the order of them, so the records of an entry and the bands of its rows cannot
	 disagree."

	^ { (VGSpanScanner of: anEntry segments) } , anEntry clip shapes
]

{ #category : 'accessing' }
VGTiledFillBands >> blockCount [
	"The blocks of records the frame holds in all, which is the room they take in the shape
	 buffer beyond the whole-shape run of each entry."

	^ blockCount
]

{ #category : 'accessing' }
VGTiledFillBands >> blockOfEntry: anIndex inRow: aRow [
	"Where the records of that entry for that row of tiles start, counted in records from the
	 first record of the shape buffer. The rows of an entry lie end to end, so its own first row
	 finds the block."

	^ shapeBase + (blockOffsets at: anIndex)
	  + ((aRow - (rows at: anIndex) first) * (shapes at: anIndex) size)
]

{ #category : 'accessing' }
VGTiledFillBands >> blockOfEntry: anIndex inRowOfTile: aTileIndex [
	"Where the records that tile reads for that entry start. This is what a reference of the
	 tile carries, so that the kernel reads the edges of the row it is drawing and not every
	 edge of the shape."

	^ self blockOfEntry: anIndex inRow: (self rowOfTilesAt: aTileIndex)
]

{ #category : 'accessing' }
VGTiledFillBands >> blockRows [
	"One row a shape record of the frame, in the order the records lie in the buffer: the entry,
	 the row of tiles, the rows of pixels that row covers, the shape, the edges the record names
	 and the edges the whole shape holds, and where the record lies. Every number is asked of
	 the methods a caller asks, so a row here is what the encoding writes."

	| answer height |
	answer := OrderedCollection new.
	height := grid tileExtent y.
	self blocksDo: [ :index :row |
		(self shapesOfEntry: index) withIndexDo: [ :shape :ordinal |
			answer add: {
					index.
					row.
					(row * height -> (row + 1 * height)).
					ordinal.
					(self
						 edgeIndexesOfEntry: index
						 shape: ordinal
						 inRow: row) size.
					(shape segments size / VGTiledFillLayout edgeFloats).
					((self blockOfEntry: index inRow: row) + ordinal - 1) } ] ].
	^ answer
]

{ #category : 'enumerating' }
VGTiledFillBands >> blocksDo: aBlock [
	"That block once for every block of records of the frame, with the entry and the row of
	 tiles it belongs to, in the order the blocks lie in the buffer: every entry in turn and
	 every row of tiles that entry reaches, from the top down."

	fills withIndexDo: [ :each :index |
		(rows at: index) do: [ :row | aBlock value: index value: row ] ]
]

{ #category : 'initialization' }
VGTiledFillBands >> countBlocksAndEdges [
	"Where the block of each entry starts, how many blocks there are in all and how many edges
	 they name between them. An entry carries one block a row of tiles it reaches and one record
	 a shape in each of them, so its blocks lie end to end and the row finds its own by its
	 distance from the first."

	| offset |
	offset := 0.
	blockOffsets := Array new: fills size.
	fills withIndexDo: [ :each :index |
		blockOffsets at: index put: offset.
		offset := offset + ((rows at: index) size * (shapes at: index) size) ].
	blockCount := offset.
	edgeCount := 0.
	self blocksDo: [ :index :row |
		1 to: (shapes at: index) size do: [ :ordinal |
			edgeCount := edgeCount
			             +
				             (self
					              edgeIndexesOfEntry: index
					              shape: ordinal
					              inRow: row) size ] ]
]

{ #category : 'accessing' }
VGTiledFillBands >> edgeCount [
	"The edges the blocks name between them, which is the room they take in the edge buffer
	 beyond the whole shapes. An edge lying in two rows of tiles is named in both of them, so
	 this is larger than the edges the frame holds."

	^ edgeCount
]

{ #category : 'accessing' }
VGTiledFillBands >> edgeIndexesOfEntry: anIndex shape: anOrdinal inRow: aRow [
	"The coordinate indexes of the edges of that shape of that entry which can cross a row of
	 pixels inside that row of tiles. A shape whose box misses the row answers none, and a
	 winding of nought follows from that, which is the answer such a row owes."

	| height top |
	height := grid tileExtent y.
	top := aRow * height.
	^ ((indexes at: anIndex) at: anOrdinal)
		  edgeIndexesMeetingRowsFrom: top
		  to: top + height
]

{ #category : 'inspecting' }
VGTiledFillBands >> inspectorBlocks: aBuilder [
	<inspectorPresentationOrder: 1 title: 'Blocks'>
	"One row a shape record: the entry it belongs to, the row of tiles it is read for and the
	 pixel rows of that row, the edges it names against the edges the whole shape holds, and
	 where it lies in the shape buffer. The two edge counts side by side are the whole point of
	 the class: what a tile of that row reads, and what it would have read."

	^ aBuilder newTable
		  addColumn: (SpStringTableColumn title: 'Entry' evaluated: [ :each |
					   (each at: 1) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Row of tiles'
				   evaluated: [ :each | (each at: 2) printString ]);
		  addColumn: (SpStringTableColumn title: 'Pixel rows' evaluated: [ :each |
					   (each at: 3) key printString , ' to '
					   , (each at: 3) value printString ]);
		  addColumn: (SpStringTableColumn title: 'Shape' evaluated: [ :each |
					   (each at: 4) printString ]);
		  addColumn: (SpStringTableColumn title: 'Edges here' evaluated: [ :each |
					   (each at: 5) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Edges in the shape'
				   evaluated: [ :each | (each at: 6) printString ]);
		  addColumn: (SpStringTableColumn title: 'Record' evaluated: [ :each |
					   (each at: 7) printString ]);
		  items: self blockRows;
		  yourself
]

{ #category : 'inspecting' }
VGTiledFillBands >> inspectorBlocksContext: aContext [
	"Nothing is cut into rows until a frame is given, and a tab of no rows says less than no
	 tab at all."

	aContext active: blockOffsets isNotNil
]

{ #category : 'printing' }
VGTiledFillBands >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPut: $(;
		print: blockCount;
		nextPutAll: ' blocks, ';
		print: edgeCount;
		nextPutAll: ' edges)'
]

{ #category : 'accessing' }
VGTiledFillBands >> rowOfTilesAt: aTileIndex [
	"The row of tiles that tile is in, counted from nought, as the grid counts them. The row of
	 a tile in the table of a frame is another thing entirely, which VGTiledFillEncoding
	 answers."

	^ aTileIndex - 1 // grid columns
]

{ #category : 'accessing' }
VGTiledFillBands >> rowsOfEntry: anIndex [
	"The rows of tiles that entry reaches, counted from nought, in the order its blocks lie in."

	^ rows at: anIndex
]

{ #category : 'initialization' }
VGTiledFillBands >> setBinning: aBinning fills: anArray [
	"The rows of tiles each entry reaches and an index of every shape of it in bands of one tile
	 high. The rows are asked of the grid with the box the binning itself binned the entry by,
	 which is the box of the entry and not of the fill it is drawn as, so every tile the binning
	 holds a reference in falls in the rows I answer. The bands of an index start at multiples
	 of the tile height, so the band of a row of tiles is that row and never straddles two."

	| height |
	grid := aBinning grid.
	fills := anArray.
	height := grid tileExtent y.
	shapes := anArray collect: [ :each | self class shapesOf: each ].
	indexes := shapes collect: [ :each |
		           each collect: [ :shape |
			           VGEdgeIndex
				           coordinates: shape segments
				           bounds:
				           (shape exactBoundingBox ifNil: [ 0 @ 0 corner: 0 @ 0 ])
				           bandHeight: height ] ].
	rows := aBinning entries collect: [ :each |
		        grid rowsIntersecting: each boundingBox ].
	shapeBase := 0.
	self countBlocksAndEdges
]

{ #category : 'accessing' }
VGTiledFillBands >> shapeBase: aCount [
	"Where my blocks start in the shape buffer. The whole shapes of the entries are written
	 first, because a backend replaying a frame off the buffers alone reads those and not a band
	 of one, so a block of mine is found from that total on."

	shapeBase := aCount
]

{ #category : 'accessing' }
VGTiledFillBands >> shapesOfEntry: anIndex [
	"The shapes of that entry, the fill first and the shapes of its clip after it."

	^ shapes at: anIndex
]
