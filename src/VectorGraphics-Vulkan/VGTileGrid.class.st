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
		'tileExtent'
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
	 pixels they really hold and the tiles together cover the frame exactly once."

	| column row origin |
	column := (anIndex - 1) \\ self columns.
	row := (anIndex - 1) // self columns.
	origin := column * tileExtent x @ (row * tileExtent y).
	^ origin corner: ((origin + tileExtent) min: extent)
]

{ #category : 'accessing' }
VGTileGrid >> columns [
	"Rounded up, because the last column is short wherever the extent does not divide by the tile
	 and the pixels in it still have to be drawn."

	^ (extent x / tileExtent x) ceiling
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

{ #category : 'binning' }
VGTileGrid >> indexesIntersecting: aRectangle [
	"The tiles a rectangle can touch, in dispatch order. Nothing, nothing outside the frame and
	 nothing of no width or height touch no tile at all: a tile touched for one of those would be
	 a dispatch over pixels no entry writes. A fractional box is widened to whole pixels first,
	 because a shape that covers a pixel in part still writes it."

	| box firstColumn lastColumn firstRow lastRow indexes |
	aRectangle ifNil: [ ^ #(  ) ].
	box := self wholePixelsOf: (aRectangle intersect: (0 @ 0 corner: extent)).
	(box width > 0 and: [ box height > 0 ]) ifFalse: [ ^ #(  ) ].
	firstColumn := box origin x // tileExtent x.
	lastColumn := (box corner x - 1) // tileExtent x.
	firstRow := box origin y // tileExtent y.
	lastRow := (box corner y - 1) // tileExtent y.
	indexes := OrderedCollection new: (lastColumn - firstColumn + 1)
		           * (lastRow - firstRow + 1).
	firstRow to: lastRow do: [ :row |
		firstColumn to: lastColumn do: [ :column |
			indexes add: (self indexAtColumn: column row: row) ] ].
	^ indexes
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

{ #category : 'initialization' }
VGTileGrid >> setExtent: anExtent tileExtent: aTileExtent [
	extent := anExtent.
	tileExtent := aTileExtent
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
