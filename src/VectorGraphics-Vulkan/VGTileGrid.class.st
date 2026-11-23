"
I cut a frame into tiles of a fixed size and answer which tiles a rectangle touches.

I exist because the Vulkan path has to decide how much of a frame a dispatch covers. A dispatch over
a whole frame does work for pixels nothing draws, and a dispatch per entry pays the submission cost
many times over; a tile is the middle, and `indexesIntersecting:` is the question every binning
asks. My tiles are row-major and one based, the last column and the last row are short wherever the
extent does not divide by the tile, and together my tiles cover every pixel of the extent exactly
once — `VGTileBinningTest` holds that fact rather than this comment.

`extent:` takes `defaultTileExtent`, which is sixteen pixels square and comes from the census in
`VGTileBinningCensus class >> occupancyByTileExtent`. `extent:tileExtent:` is for a caller that has
measured something else. `VGTileBinning` puts the entries of a display list into my tiles.
"
Class {
	#name : 'VGTileGrid',
	#superclass : 'Object',
	#instVars : [
		'extent',
		'tileExtent',
		'bounds',
		'superBounds',
		'superTileIndexes'
	],
	#category : 'VectorGraphics-Vulkan-Tiles',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Tiles'
}

{ #category : 'constants' }
VGTileGrid class >> defaultTileExtent [
	"Sixteen pixels square, measured and not guessed.
	 VGTileBinningCensus class >> referenceOccupancyByTileExtent bins the reference frame of unit
	 1.11 at eight, sixteen and thirty-two: eight gives 7500 tiles and 14436 binned entries,
	 sixteen gives 1900 and 3803, thirty-two gives 475 and 1167. The redundant pixel work barely
	 moves between eight and sixteen — 924k entry-pixels against 973k — while the number of
	 dispatches falls fourfold, and thirty-two costs a fifth more of that work again. Sixteen
	 square is also 256 work items, a whole multiple of the 64 a workgroup of the coverage kernel
	 holds, which VGTileBinningTest requires."

	^ 16 @ 16
]

{ #category : 'instance creation' }
VGTileGrid class >> extent: anExtent [
	^ self extent: anExtent tileExtent: self defaultTileExtent
]

{ #category : 'instance creation' }
VGTileGrid class >> extent: anExtent tileExtent: aTileExtent [
	^ self new setExtent: anExtent tileExtent: aTileExtent
]

{ #category : 'constants' }
VGTileGrid class >> interiorProbeFactor [
	"How many tiles a super tile holds along each axis. A binning asks whether a whole super
	 tile is interior to an entry before it asks about the sixteen tiles inside it, so one walk
	 over the edges of a shape answers for sixteen tiles where it answers yes. Four was measured
	 on the reference frame against two and eight: 3.815 ms of interior testing against 4.307 and
	 4.304, where asking every tile on its own costs 5.036."
	^ 4
]

{ #category : 'accessing' }
VGTileGrid >> boundsOfSuperTileAt: anIndex [
	"The pixels of that super tile. The rectangle is remembered, and the same object comes back
	 every time: a scanner remembers its answer under the rectangle it was asked about, and an
	 answer is reused only where the rectangle is the same object."
	superBounds ifNil: [ superBounds := Array new: self superTileCount ].
	^ (superBounds at: anIndex) ifNil: [
		  superBounds at: anIndex put: (self newBoundsOfSuperTileAt: anIndex) ]
]

{ #category : 'accessing' }
VGTileGrid >> boundsOfTileAt: anIndex [
	"Clipped to the extent, so the short tiles of the last column and the last row answer the
	 pixels they really hold and the tiles together cover the frame exactly once.
	 The rectangle is remembered: a binning asks for the bounds of a tile once for every entry
	 and tile pair it marks, and nothing of mine changes after I am built."

	bounds ifNil: [ bounds := Array new: self tileCount ].
	^ (bounds at: anIndex) ifNil: [
		  bounds at: anIndex put: (self newBoundsOfTileAt: anIndex) ]
]

{ #category : 'accessing' }
VGTileGrid >> columns [
	"Rounded up, because the last column is short wherever the extent does not divide by the tile
	 and the pixels in it still have to be drawn."

	^ (extent x / tileExtent x) ceiling
]

{ #category : 'accessing' }
VGTileGrid >> columnsIntersecting: aRectangle [
	"The columns of tiles a rectangle can touch, counted from nought, as the interval between
	 the first and the last of them. What touches no tile touches no column, which is an empty
	 interval."
	| box |
	box := self pixelBoxOf: aRectangle.
	box ifNil: [ ^ 1 to: 0 ].
	^ box origin x // tileExtent x to: box corner x - 1 // tileExtent x
]

{ #category : 'accessing' }
VGTileGrid >> extent [
	^ extent
]

{ #category : 'accessing' }
VGTileGrid >> indexAtColumn: aColumn row: aRow [
	"Row-major, one based, which is the order a dispatch walks and the order a report reads."

	^ aRow * self columns + aColumn + 1
]

{ #category : 'accessing' }
VGTileGrid >> indexesIntersecting: aRectangle [
	"The tiles a rectangle can touch, in dispatch order. Nothing, nothing outside the frame and
	 nothing of no width or height touch no tile at all: a tile touched for one of those would be
	 a dispatch over pixels no entry writes. Which rows and which columns a box reaches is asked
	 of the two methods that answer those, so a caller holding rows alone reads the same box."

	| rows columns indexes |
	rows := self rowsIntersecting: aRectangle.
	columns := self columnsIntersecting: aRectangle.
	indexes := OrderedCollection new: rows size * columns size.
	rows do: [ :row |
		columns do: [ :column |
			indexes add: (self indexAtColumn: column row: row) ] ].
	^ indexes
]

{ #category : 'inspector' }
VGTileGrid >> inspectorSuperTiles: aBuilder [
	"Every super tile with the tiles it holds, which is what a binning asks about before it asks
	 about those tiles one by one. The counts are read from the grid itself, so a change of the
	 factor shows here and nothing is restated."
	<inspectorPresentationOrder: 2 title: 'Super tiles'>
	^ aBuilder newTable
		  addColumn: (SpStringTableColumn
				   title: 'Super tile'
				   evaluated: [ :each | each printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Column'
				   evaluated: [ :each |
					   ((each - 1) \\ self superTileColumns) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Row'
				   evaluated: [ :each |
					   ((each - 1) // self superTileColumns) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Bounds'
				   evaluated: [ :each | (self boundsOfSuperTileAt: each) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Tiles'
				   evaluated: [ :each |
					   (self tileIndexesOfSuperTileAt: each) size printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'First tile'
				   evaluated: [ :each |
					   (self tileIndexesOfSuperTileAt: each) first printString ]);
		  items: (1 to: self superTileCount) asArray;
		  yourself
]

{ #category : 'inspector' }
VGTileGrid >> inspectorSuperTilesContext: aContext [
	aContext active: extent isNotNil
]

{ #category : 'inspector' }
VGTileGrid >> inspectorTiles: aBuilder [
	"Every tile with the bounds it really answers, so the short tiles of the last column and the
	 last row are visible as such."

	<inspectorPresentationOrder: 1 title: 'Tiles'>
	^ aBuilder newTable
		  addColumn: (SpStringTableColumn
				   title: 'Tile'
				   evaluated: [ :each | each printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Column'
				   evaluated: [ :each | ((each - 1) \\ self columns) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Row'
				   evaluated: [ :each | ((each - 1) // self columns) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Bounds'
				   evaluated: [ :each | (self boundsOfTileAt: each) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Pixels'
				   evaluated: [ :each |
					   | bounds |
					   bounds := self boundsOfTileAt: each.
					   (bounds width * bounds height) printString ]);
		  items: (1 to: self tileCount) asArray;
		  yourself
]

{ #category : 'inspector' }
VGTileGrid >> inspectorTilesContext: aContext [
	aContext active: extent isNotNil
]

{ #category : 'accessing' }
VGTileGrid >> newBoundsOfSuperTileAt: anIndex [
	"The pixels of that super tile, clipped to the extent, worked out from the index the same way
	 a tile's bounds are."
	| factor column row origin span |
	factor := self class interiorProbeFactor.
	column := (anIndex - 1) \\ self superTileColumns.
	row := (anIndex - 1) // self superTileColumns.
	span := factor * tileExtent x @ (factor * tileExtent y).
	origin := column * span x @ (row * span y).
	^ origin corner: ((origin + span) min: extent)
]

{ #category : 'private' }
VGTileGrid >> newBoundsOfTileAt: anIndex [
	"The pixels of that tile, worked out from the index. The column and the row come out of the
	 index because a tile is numbered row-major, which is the order a dispatch walks."

	| column row origin |
	column := (anIndex - 1) \\ self columns.
	row := (anIndex - 1) // self columns.
	origin := column * tileExtent x @ (row * tileExtent y).
	^ origin corner: ((origin + tileExtent) min: extent)
]

{ #category : 'private' }
VGTileGrid >> pixelBoxOf: aRectangle [
	"The whole pixels of that rectangle inside my extent, or nil where it touches no pixel of
	 mine at all. Three readers ask for tiles, for rows and columns, and for super tiles, and
	 they must not disagree about what a box reaches, so the box is read in one place."
	| box |
	aRectangle ifNil: [ ^ nil ].
	box := self wholePixelsOf: (aRectangle intersect: (0 @ 0 corner: extent)).
	^ (box width > 0 and: [ box height > 0 ])
		  ifTrue: [ box ]
		  ifFalse: [ nil ]
]

{ #category : 'printing' }
VGTileGrid >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPutAll: ' of ';
		print: self columns;
		nextPutAll: ' by ';
		print: self rows;
		nextPutAll: ' tiles of ';
		print: tileExtent
]

{ #category : 'accessing' }
VGTileGrid >> rows [
	^ (extent y / tileExtent y) ceiling
]

{ #category : 'accessing' }
VGTileGrid >> rowsIntersecting: aRectangle [
	"The rows of tiles a rectangle can touch, counted from nought, as the interval between the
	 first and the last of them. What touches no tile touches no row, which is an empty
	 interval; the box is read exactly as indexesIntersecting: reads it, so a caller that holds
	 rows and a caller that holds tiles cannot disagree about which rows an entry reaches."
	| box |
	box := self pixelBoxOf: aRectangle.
	box ifNil: [ ^ 1 to: 0 ].
	^ box origin y // tileExtent y to: box corner y - 1 // tileExtent y
]

{ #category : 'initialization' }
VGTileGrid >> setExtent: anExtent tileExtent: aTileExtent [
	extent := anExtent.
	tileExtent := aTileExtent
]

{ #category : 'accessing' }
VGTileGrid >> superTileColumns [
	"How many super tiles a row of the grid holds. The last one is short where the columns do not
	 divide by the factor, as the last tile of a row is short where the pixels do not."
	^ (self columns / self class interiorProbeFactor) ceiling
]

{ #category : 'accessing' }
VGTileGrid >> superTileCount [
	"How many super tiles cover me. Row-major like the tiles, so a super tile is found by
	 arithmetic and nothing is searched."
	^ self superTileColumns * self superTileRows
]

{ #category : 'accessing' }
VGTileGrid >> superTileIndexesIntersecting: aRectangle [
	"The super tiles a rectangle can touch, in dispatch order. The box is read exactly as
	 indexesIntersecting: reads it, so a super tile is reached where one of its own tiles is and
	 nowhere else."
	| box span answer |
	box := self pixelBoxOf: aRectangle.
	box ifNil: [ ^ #(  ) ].
	span := self class interiorProbeFactor * tileExtent x
	        @ (self class interiorProbeFactor * tileExtent y).
	answer := OrderedCollection new.
	box origin y // span y to: box corner y - 1 // span y do: [ :row |
		box origin x // span x to: box corner x - 1 // span x do: [ :column |
			answer add: row * self superTileColumns + column + 1 ] ].
	^ answer
]

{ #category : 'accessing' }
VGTileGrid >> superTileRows [
	"How many super tiles a column of the grid holds."
	^ (self rows / self class interiorProbeFactor) ceiling
]

{ #category : 'accessing' }
VGTileGrid >> tileCount [
	^ self columns * self rows
]

{ #category : 'accessing' }
VGTileGrid >> tileExtent [
	^ tileExtent
]

{ #category : 'accessing' }
VGTileGrid >> tileIndexesOfSuperTileAt: anIndex [
	"The tiles that super tile holds, in dispatch order. Remembered, because a binning reads them
	 once for every entry whose box reaches that super tile."
	superTileIndexes ifNil: [ superTileIndexes := Array new: self superTileCount ].
	^ (superTileIndexes at: anIndex) ifNil: [
		  superTileIndexes
			  at: anIndex
			  put: (self indexesIntersecting: (self boundsOfSuperTileAt: anIndex)) asArray ]
]

{ #category : 'binning' }
VGTileGrid >> wholePixelsOf: aRectangle [
	"Outward on every side: a box in device space may carry fractions from a transform, and the
	 pixel a shape covers in part is a pixel it writes."

	^ (aRectangle origin x floor @ aRectangle origin y floor)
	  corner: aRectangle corner x ceiling @ aRectangle corner y ceiling
]
