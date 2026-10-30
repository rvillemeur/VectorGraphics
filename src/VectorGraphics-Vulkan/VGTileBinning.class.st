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
		'entries',
		'counts',
		'starts',
		'ordinals',
		'marks',
		'boxes'
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

{ #category : 'accessing' }
VGTileBinning >> binnedEntryCount [
	"How many references the frame binned in all, which is the length of the run."

	^ ordinals size
]

{ #category : 'private - binning' }
VGTileBinning >> countReferences [
	"How many references each tile holds, and where the run of each tile begins. The entry
	 answers its own bounding box, clip and operator included, so an operator that writes beyond
	 its shape widens the box there and not here, and the tiles of a box are walked as numbers
	 rather than collected."

	| offset |
	counts := WordArray new: grid tileCount.
	starts := WordArray new: grid tileCount.
	boxes do: [ :box |
		grid indexesIntersecting: box do: [ :index |
			counts at: index put: (counts at: index) + 1 ] ].
	offset := 0.
	1 to: counts size do: [ :index |
		starts at: index put: offset.
		offset := offset + (counts at: index) ].
	ordinals := WordArray new: offset.
	marks := ByteArray new: offset
]

{ #category : 'accessing' }
VGTileBinning >> entries [
	^ entries
]

{ #category : 'accessing' }
VGTileBinning >> entriesOfTileAt: anIndex [
	"The entries of that tile, in draw order. The run holds ordinals, so the entries are read
	 out of the frame's own list by them."

	| start |
	start := starts at: anIndex.
	^ (1 to: (counts at: anIndex)) collect: [ :each |
		  entries at: (ordinals at: start + each) ]
]

{ #category : 'private - binning' }
VGTileBinning >> entry: anEntry coversInnerBlockOfRows: aRowInterval columns: aColumnInterval [
	"Whether the entry covers every pixel of the block of tiles inside the ring of tiles its
	 bounding box reaches. An entry that reaches three rows and three columns or fewer has no
	 such block and is not asked."

	(aRowInterval size > 2 and: [ aColumnInterval size > 2 ]) ifFalse: [
		^ false ].
	^ anEntry coversEveryPixelOf: ((grid boundsOfTileAt: (grid
			    indexAtColumn: aColumnInterval first + 1
			    row: aRowInterval first + 1)) merge: (grid boundsOfTileAt: (grid
			     indexAtColumn: aColumnInterval last - 1
			     row: aRowInterval last - 1)))
]

{ #category : 'accessing' }
VGTileBinning >> grid [
	^ grid
]

{ #category : 'binning' }
VGTileBinning >> innerBlockOf: anEntry rows: aRowInterval columns: aColumnInterval [
	"The block of tiles strictly inside the ring the entry reaches, as the first and last column
	 and row of that block, or a block no tile can lie in when the entry does not cover that
	 block whole. The bounds are inclusive, so a tile belongs to the block when its column lies
	 between the left and the right and its row between the top and the bottom. The empty answer
	 is a rectangle of negative numbers rather than one with no area, because a column and a row
	 of the grid are never negative and because a rectangle whose corner precedes its origin is
	 normalised into one that does hold tiles."

	^ (self entry: anEntry coversInnerBlockOfRows: aRowInterval columns: aColumnInterval)
		  ifTrue: [
			  (aColumnInterval first + 1) @ (aRowInterval first + 1)
			  corner: (aColumnInterval last - 1) @ (aRowInterval last - 1) ]
		  ifFalse: [ -1 @ -1 corner: -1 @ -1 ]
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

{ #category : 'inspecting' }
VGTileBinning >> inspectorInnerBlocks: aBuilder [
	<inspectorPresentationOrder: 3 title: 'Inner blocks'>
	"What the mark pass asked of each entry. The ring of tiles the entry's box ends in is asked
	 tile by tile, because the entry's own edges lie on those tiles and the conservative rule
	 says no to any rectangle an edge lies on; the block inside that ring is asked once. A block
	 less than three tiles across has no inside, so such an entry is asked tile by tile
	 throughout. Every column sends the predicate the pass itself sends, so the tab cannot say an
	 entry was answered in one question where the pass asked many."

	^ aBuilder newTable
		  items: (1 to: entries size) asArray;
		  addColumn: (SpStringTableColumn title: 'Entry' evaluated: [ :each |
					   each printString , ' ' , (entries at: each) class name ]);
		  addColumn: (SpStringTableColumn title: 'Tiles' evaluated: [ :each |
					   (grid columnsIntersecting: (boxes at: each)) size printString , ' by '
					   , (grid rowsIntersecting: (boxes at: each)) size printString ]);
		  addColumn: (SpStringTableColumn title: 'Inner block' evaluated: [ :each |
					   (self
						    entry: (entries at: each)
						    coversInnerBlockOfRows: (grid rowsIntersecting: (boxes at: each))
						    columns: (grid columnsIntersecting: (boxes at: each)))
						   ifTrue: [ 'answered once' ]
						   ifFalse: [ 'asked tile by tile' ] ]);
		  addColumn: (SpStringTableColumn title: 'Interior tiles' evaluated: [ :each |
					   | tiles |
					   tiles := self tileIndexesOfEntry: (entries at: each).
					   (tiles count: [ :index |
						    self isEntry: (entries at: each) interiorToTileAt: index ])
							 printString , ' of ' , tiles size printString ]);
		  yourself
]

{ #category : 'inspecting' }
VGTileBinning >> inspectorInnerBlocksContext: aContext [
	"A binning with no display list set has no entry to ask and no box to ask about."

	aContext active: (entries isNotNil and: [ boxes isNotNil ])
]

{ #category : 'accessing' }
VGTileBinning >> interiorEntriesOfTileAt: anIndex [
	"Those of the tile's entries that cover every pixel of it, in draw order."

	| answer |
	answer := OrderedCollection new.
	self referencesOfTileAt: anIndex do: [ :ordinal :interior |
		interior ifTrue: [ answer add: (entries at: ordinal) ] ].
	^ answer
]

{ #category : 'accessing' }
VGTileBinning >> interiorReferenceCount [
	"How many of the references are marked. A mark is one byte, nought or one, so the count
	 is their sum."

	^ marks inject: 0 into: [ :sum :each | sum + each ]
]

{ #category : 'accessing' }
VGTileBinning >> isEntry: anEntry interiorToTileAt: anIndex [
	"Whether that pair was marked when it was binned. The mark sits beside the ordinal, so this
	 reads it rather than ask the entry a second time."

	self referencesOfTileAt: anIndex do: [ :ordinal :interior |
		(entries at: ordinal) == anEntry ifTrue: [ ^ interior ] ].
	^ false
]

{ #category : 'private - binning' }
VGTileBinning >> markReferenceAt: anIndex ordinal: anOrdinal mark: aMark cursors: aCursorArray [
	"One reference into the run of its tile, at the place the counting pass reserved for it. The
	 cursor of the tile moves on, so the next entry that reaches this tile lands after this one
	 and the references of a tile stay in draw order."

	| at |
	at := (aCursorArray at: anIndex) + 1.
	aCursorArray at: anIndex put: at.
	ordinals at: at put: anOrdinal.
	marks at: at put: aMark
]

{ #category : 'private - binning' }
VGTileBinning >> markReferences [
	"The ordinal of the entry and the mark of the pair, written into the run at the place the
	 counting pass left for them. The entries are walked in draw order, so the references of a
	 tile come out in draw order too; a tile the entry covers in full is marked as it is binned,
	 because the tile and the entry are both in hand here and nothing later holds the pair.
	 An ordinal and a mark beside it are what a reference of the device carries, which is what
	 spares the writer a search for an ordinal and a second question for the mark."

	| cursors |
	cursors := starts copy.
	entries withIndexDo: [ :entry :ordinal |
		self
			markReferencesOf: entry
			box: (boxes at: ordinal)
			ordinal: ordinal
			cursors: cursors ]
]

{ #category : 'binning' }
VGTileBinning >> markReferencesOf: anEntry box: aBox ordinal: anOrdinal cursors: aCursorArray [
	"Every tile of the entry, with its mark. Asking an entry whether it covers a tile whole is
	 the costliest thing a binning does, and the question is monotone: a fill that covers every
	 pixel of a rectangle covers every pixel of anything inside that rectangle. So the block of
	 tiles inside the ring the entry reaches is asked once, and a yes there is the mark of every
	 tile of the block; only the ring is asked tile by tile. The ring is left out of the block
	 because the rule is conservative — it says no to a rectangle an edge of the shape lies on,
	 and the edges of an entry lie on the tiles its bounding box ends in.
	 On the reference frame that is 1620 questions where there were 3803, and the 2208 marks the
	 shortcut writes are every interior mark the frame has.
	 The loop is written out here rather than sent to a helper a tile at a time: this is the one
	 loop of the binning that turns thirty-eight hundred times a frame, and a send a tile
	 measured two milliseconds on the reference frame."

	| rows columns inner |
	rows := grid rowsIntersecting: aBox.
	columns := grid columnsIntersecting: aBox.
	rows isEmpty | columns isEmpty ifTrue: [ ^ self ].
	inner := self innerBlockOf: anEntry rows: rows columns: columns.
	rows do: [ :row |
		| rowIsInner |
		rowIsInner := row between: inner top and: inner bottom.
		columns do: [ :column |
			| index |
			index := grid indexAtColumn: column row: row.
			self
				markReferenceAt: index
				ordinal: anOrdinal
				mark:
				((rowIsInner and: [ column between: inner left and: inner right ]) or: [
					 anEntry coversEveryPixelOf: (grid boundsOfTileAt: index) ]) asBit
				cursors: aCursorArray ] ]
]

{ #category : 'accessing' }
VGTileBinning >> maxEntriesInATile [

	^ counts inject: 0 into: [ :most :each | most max: each ]
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

{ #category : 'accessing' }
VGTileBinning >> referenceCountOfTileAt: anIndex [
	"How many references that tile holds, which is the count the tile record carries."

	^ counts at: anIndex
]

{ #category : 'accessing' }
VGTileBinning >> referencesOfTileAt: anIndex do: aBlock [
	"Every reference of that tile, in the order the frame drew the entries: the ordinal of the
	 entry and whether the entry covers every pixel of the tile. That is the pair the device
	 writes as one reference, so the writer asks one question here and neither searches for an
	 ordinal nor scans a second collection for the mark."

	| start |
	start := starts at: anIndex.
	1 to: (counts at: anIndex) do: [ :each |
		aBlock
			value: (ordinals at: start + each)
			value: (marks at: start + each) = 1 ]
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
		  ('pairs interior'
		   -> (self interiorReferenceCount printString , ' of '
			   , self binnedEntryCount printString)).
		  ('busiest tile' -> self maxEntriesInATile printString) }
]

{ #category : 'initialization' }
VGTileBinning >> setDisplayList: aDisplayList grid: aGrid [
	"The entries are copied out, in order, because draining the frame resets the display list and
	 a census reads its counts after the frame is drawn. Their bounding boxes are taken once
	 here: both passes read the box of every entry, a blit builds its box out of its clip and
	 its operator rather than keeping one, and a box that moved between the two passes would
	 leave a tile a reference it reserved no room for.
	 The references of every tile live in one flat run, found by the tile's own start and count,
	 so a tile is reached by arithmetic, the tiles come back in tile order with nothing sorted,
	 and the frame pays no hashing and allocates no collection a tile: on the reference frame the
	 dictionary was two of the ten milliseconds the binning cost, and a bin an entry was
	 nineteen hundred collections a frame after that. The counting pass is what the flat run
	 needs, and it is arithmetic over the boxes the entries answer."

	grid := aGrid.
	entries := aDisplayList entries asArray.
	boxes := entries collect: [ :each | each boundingBox ].
	self countReferences.
	self markReferences
]

{ #category : 'accessing' }
VGTileBinning >> tileIndexesOfEntry: anEntry [
	"The tiles that hold a reference to that entry. The entry is turned into its ordinal once,
	 because a reference names an entry by its place in the frame."

	| ordinal answer |
	ordinal := entries identityIndexOf: anEntry.
	answer := Set new.
	ordinal = 0 ifTrue: [ ^ answer ].
	1 to: counts size do: [ :index |
		self referencesOfTileAt: index do: [ :each :interior |
			each = ordinal ifTrue: [ answer add: index ] ] ].
	^ answer
]

{ #category : 'accessing' }
VGTileBinning >> touchedTileCount [

	^ counts count: [ :each | each > 0 ]
]

{ #category : 'accessing' }
VGTileBinning >> touchedTileIndexes [
	"The tiles that hold at least one reference, in tile order. A tile's references live in
	 the slot of its own count, so the order comes out of the walk and nothing is sorted: the
	 encoding used to sort nineteen hundred keys a frame to get here."

	| answer |
	answer := OrderedCollection new: counts size.
	counts withIndexDo: [ :count :index |
		count > 0 ifTrue: [ answer add: index ] ].
	^ answer asArray
]
