"
I put the entries of one recorded frame into the tiles of a grid.

I exist because a dispatch has to know which entries touch the pixels it covers. I ask each entry
for its own bounding box — clip and operator included, so an unbounded operator widens its box
itself — and add the entry to every tile that box reaches. An entry that spans a boundary is in
every tile it spans, which is why `binnedEntryCount` is larger than the number of entries drawn; that
growth is the price of tiling and `VGTileBinningCensus` measures it.

The entries of a tile stay in the order they were drawn, because compositing is not commutative.
I copy the entries out of the display list when I am built, because draining a frame resets its list
and a caller reads my counts after the frame is drawn.

`of:extent:` takes the default tile size; `of:grid:` is for a caller with a grid of its own.
`touchedTileCount` is the number of dispatches a frame would cost and `maxEntriesInATile` the depth
of its busiest tile. See `VGTileGrid` for the tiles and `VGTileBinningCensus` for the measurement
over the corpus and the reference frame.
"
Class {
	#name : 'VGTileBinning',
	#superclass : 'Object',
	#instVars : [
		'grid',
		'bins',
		'entries'
	],
	#category : 'VectorGraphics-Vulkan-Tiles',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Tiles'
}

{ #category : 'instance creation' }
VGTileBinning class >> of: aDisplayList extent: anExtent [
	^ self of: aDisplayList grid: (VGTileGrid extent: anExtent)
]

{ #category : 'instance creation' }
VGTileBinning class >> of: aDisplayList grid: aGrid [
	^ self new setDisplayList: aDisplayList grid: aGrid
]

{ #category : 'binning' }
VGTileBinning >> bin: anEntry [
	"Where the entry says it can touch, and nowhere else. The entry answers its own bounding box,
	 clip and operator included, so an operator that writes beyond its shape widens the box there
	 and not here."

	(grid indexesIntersecting: anEntry boundingBox) do: [ :index |
		(bins at: index ifAbsentPut: [ OrderedCollection new ]) add: anEntry ]
]

{ #category : 'accessing' }
VGTileBinning >> binnedEntryCount [
	"Entries counted once per tile they reach, which is the total work the tiles hold. It is
	 larger than the display list wherever an entry spans tiles, and that growth is the price of
	 tiling."

	^ bins inject: 0 into: [ :sum :each | sum + each size ]
]

{ #category : 'accessing' }
VGTileBinning >> entries [
	^ entries
]

{ #category : 'accessing' }
VGTileBinning >> entriesOfTileAt: anIndex [
	"In the order they were drawn, because compositing is not commutative."

	^ bins at: anIndex ifAbsent: [ #(  ) ]
]

{ #category : 'accessing' }
VGTileBinning >> grid [
	^ grid
]

{ #category : 'inspector' }
VGTileBinning >> inspectorBinning: aBuilder [
	<inspectorPresentationOrder: 1 title: 'Binning'>
	^ aBuilder newTable
		  addColumn: (SpStringTableColumn title: 'What' evaluated: [ :each | each key ]);
		  addColumn:
			  (SpStringTableColumn title: 'Value' evaluated: [ :each | each value ]);
		  items: self reportRows;
		  yourself
]

{ #category : 'inspector' }
VGTileBinning >> inspectorBinningContext: aContext [
	aContext active: grid isNotNil
]

{ #category : 'inspector' }
VGTileBinning >> inspectorBusiestTiles: aBuilder [
	"The tiles with the most entries in them, which is where a dispatch would do the most work.
	 The order is read from the bins, not kept anywhere, so it follows the binning."

	<inspectorPresentationOrder: 2 title: 'Busiest tiles'>
	^ aBuilder newTable
		  addColumn: (SpStringTableColumn
				   title: 'Tile'
				   evaluated: [ :each | each printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Bounds'
				   evaluated: [ :each | (grid boundsOfTileAt: each) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Entries'
				   evaluated: [ :each | (self entriesOfTileAt: each) size printString ]);
		  items: (self touchedTileIndexes asSortedCollection: [ :one :other |
					   (self entriesOfTileAt: one) size
					   >= (self entriesOfTileAt: other) size ]) asArray;
		  yourself
]

{ #category : 'inspector' }
VGTileBinning >> inspectorBusiestTilesContext: aContext [
	aContext active: self touchedTileCount > 0
]

{ #category : 'accessing' }
VGTileBinning >> maxEntriesInATile [
	"The depth of the busiest tile, which decides whether one dispatch can carry a tile's work."

	^ bins inject: 0 into: [ :most :each | most max: each size ]
]

{ #category : 'printing' }
VGTileBinning >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPutAll: ' of ';
		print: entries size;
		nextPutAll: ' entries over ';
		print: self touchedTileCount;
		nextPutAll: ' of ';
		print: grid tileCount;
		nextPutAll: ' tiles'
]

{ #category : 'reporting' }
VGTileBinning >> reportRows [
	"Label and value, read from the bins themselves, so the tab cannot drift from the binning."

	^ {
		  ('frame' -> grid extent printString).
		  ('tile' -> grid tileExtent printString).
		  ('tiles' -> (grid columns printString , ' by ' , grid rows printString)).
		  ('entries drawn' -> entries size printString).
		  ('tiles touched'
		   -> (self touchedTileCount printString , ' of ' , grid tileCount printString)).
		  ('entries binned' -> self binnedEntryCount printString).
		  ('busiest tile' -> self maxEntriesInATile printString) }
]

{ #category : 'initialization' }
VGTileBinning >> setDisplayList: aDisplayList grid: aGrid [
	"The entries are copied out, in order, because draining the frame resets the display list and
	 a census reads its counts after the frame is drawn."

	grid := aGrid.
	entries := aDisplayList entries asArray.
	bins := Dictionary new.
	entries do: [ :each | self bin: each ]
]

{ #category : 'accessing' }
VGTileBinning >> tileIndexesOfEntry: anEntry [
	"Read back out of the bins rather than measured again, so this answers where the entry really
	 landed."

	^ (bins associations
		   select: [ :each | each value identityIncludes: anEntry ]
		   thenCollect: [ :each | each key ]) asSet
]

{ #category : 'accessing' }
VGTileBinning >> touchedTileCount [
	"The number of dispatches the GPU path would make for this frame, which is what the gate of
	 unit 2.2 counts."

	^ bins size
]

{ #category : 'accessing' }
VGTileBinning >> touchedTileIndexes [
	^ bins keys
]
