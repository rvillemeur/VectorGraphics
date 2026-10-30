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
		'columnCount',
		'rowCount'
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

	^ columnCount
]

{ #category : 'accessing' }
VGTileGrid >> columnsIntersecting: aRectangle [
	"The columns of tiles a rectangle can touch, counted from nought, as the interval between
	 the first and the last of them. What touches no tile touches no column, which is an empty
	 interval."

	| box |
	aRectangle ifNil: [ ^ 1 to: 0 ].
	box := self wholePixelsOf: (aRectangle intersect: (0 @ 0 corner: extent)).
	(box width > 0 and: [ box height > 0 ]) ifFalse: [ ^ 1 to: 0 ].
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

	| indexes |
	indexes := OrderedCollection new:
		           (self rowsIntersecting: aRectangle) size
		           * (self columnsIntersecting: aRectangle) size.
	self indexesIntersecting: aRectangle do: [ :each | indexes add: each ].
	^ indexes
]

{ #category : 'accessing' }
VGTileGrid >> indexesIntersecting: aRectangle do: aBlock [
	"That block once for every tile the rectangle can touch, in dispatch order, allocating
	 nothing. A binning walks every entry and tile pair of a frame — nearly four thousand of
	 them on the reference frame — and the collection indexesIntersecting: builds is read once
	 and thrown away."

	| columns |
	columns := self columnsIntersecting: aRectangle.
	(self rowsIntersecting: aRectangle) do: [ :row |
		columns do: [ :column |
			aBlock value: (self indexAtColumn: column row: row) ] ]
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
VGTileGrid >> newBoundsOfTileAt: anIndex [
	"The pixels of that tile, worked out from the index. The column and the row come out of the
	 index because a tile is numbered row-major, which is the order a dispatch walks."

	| column row left top |
	column := (anIndex - 1) \\ columnCount.
	row := (anIndex - 1) // columnCount.
	left := column * tileExtent x.
	top := row * tileExtent y.
	^ left @ top
	  corner: ((left + tileExtent x) min: extent x) @ ((top + tileExtent y) min: extent y)
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
	^ rowCount
]

{ #category : 'accessing' }
VGTileGrid >> rowsIntersecting: aRectangle [
	"The rows of tiles a rectangle can touch, counted from nought, as the interval between the
	 first and the last of them. What touches no tile touches no row, which is an empty
	 interval; the box is read exactly as indexesIntersecting: reads it, so a caller that holds
	 rows and a caller that holds tiles cannot disagree about which rows an entry reaches."

	| box |
	aRectangle ifNil: [ ^ 1 to: 0 ].
	box := self wholePixelsOf: (aRectangle intersect: (0 @ 0 corner: extent)).
	(box width > 0 and: [ box height > 0 ]) ifFalse: [ ^ 1 to: 0 ].
	^ box origin y // tileExtent y to: box corner y - 1 // tileExtent y
]

{ #category : 'accessing' }
VGTileGrid >> setExtent: anExtent tileExtent: aTileExtent [
	"The count of columns and of rows is worked out here rather than asked for: the bounds of
	 every tile are worked out from the column count, the division it takes builds a fraction,
	 and a frame of 1900 tiles asked for it nineteen hundred times."

	extent := anExtent.
	tileExtent := aTileExtent.
	columnCount := (extent x / tileExtent x) ceiling.
	rowCount := (extent y / tileExtent y) ceiling
]

{ #category : 'accessing' }
VGTileGrid >> tileCount [
	^ self columns * self rows
]

{ #category : 'accessing' }
VGTileGrid >> tileExtent [
	^ tileExtent
]

{ #category : 'binning' }
VGTileGrid >> wholePixelsOf: aRectangle [
	"Outward on every side: a box in device space may carry fractions from a transform, and the
	 pixel a shape covers in part is a pixel it writes."

	^ (aRectangle origin x floor @ aRectangle origin y floor)
	  corner: aRectangle corner x ceiling @ aRectangle corner y ceiling
]
