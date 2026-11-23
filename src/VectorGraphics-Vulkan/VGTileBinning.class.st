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
		'entries',
		'interiors',
		'stages'
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
VGTileBinning class >> stageNames [
	"The phases binning a frame is paid in, in the order an entry pays them: the bounding box
	 the entry answers, the tiles and super tiles that box reaches, the questions about what the
	 entry covers whole, and the writing of the references into the bins. This table is the only
	 place that names a phase of mine, as VGTiledFillEncoding class >> stageNames is for the
	 host half of a frame; the whole of what I am paid shows there as the one phase bin."
	^ #( #boundingBox #indexes #interior #bins )
]

{ #category : 'building' }
VGTileBinning >> bin: anEntry at: anOrdinal [
	"Where the entry says it can touch, and nowhere else. The entry answers its own bounding box,
	 clip and operator included, so an operator that writes beyond its shape widens the box there
	 and not here. A tile the entry covers in full is marked as it is binned, because the tile
	 and the entry are both in hand here and nothing later holds the pair.
	 What a bin holds is the ordinal of the entry in the frame, and beside it the mark of the
	 pair: that is what a reference of the device carries, and it is what spares the writer a
	 search for an ordinal and a second question for the mark.
	 The super tile is asked before the tiles inside it: an entry that covers a whole super tile
	 covers every tile of it, so one walk over the edges of a shape marks sixteen tiles and the
	 tiles themselves are never asked. On the reference frame that is 4.587 ms of binning against
	 5.722 ms, with the same tiles marked."
	| box |
	box := self timeStage: #boundingBox during: [ anEntry boundingBox ].
	(self timeStage: #indexes during: [ grid superTileIndexesIntersecting: box ])
		do: [ :superIndex |
			| superBounds interior tileIndexes |
			superBounds := grid boundsOfSuperTileAt: superIndex.
			interior := self
				            timeStage: #interior
				            during: [ anEntry coversEveryPixelOf: superBounds ].
			tileIndexes := self
				               timeStage: #indexes
				               during: [ grid indexesIntersecting: (box intersect: superBounds) ].
			tileIndexes do: [ :index |
				| mark |
				mark := interior or: [
					        self
						        timeStage: #interior
						        during: [
						        anEntry coversEveryPixelOf: (grid boundsOfTileAt: index) ] ].
				self timeStage: #bins during: [
					(bins at: index) ifNil: [
						bins at: index put: (OrderedCollection new: 4).
						interiors at: index put: (OrderedCollection new: 4) ].
					(bins at: index) add: anOrdinal.
					(interiors at: index) add: mark ] ] ]
]

{ #category : 'accessing' }
VGTileBinning >> binnedEntryCount [
	^ bins inject: 0 into: [ :sum :each |
		  sum + (each ifNil: [ 0 ] ifNotNil: [ :ordinals | ordinals size ]) ]
]

{ #category : 'accessing' }
VGTileBinning >> entries [
	^ entries
]

{ #category : 'accessing' }
VGTileBinning >> entriesOfTileAt: anIndex [
	"The entries of that tile, in draw order. A bin holds ordinals, so the entries are read out
	 of the frame's own list by them."

	^ (bins at: anIndex)
		  ifNil: [ #(  ) ]
		  ifNotNil: [ :ordinals |
			  ordinals collect: [ :each | entries at: each ] ]
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

{ #category : 'inspecting' }
VGTileBinning >> inspectorPhases: aBuilder [
	<inspectorPresentationOrder: 3 title: 'Phases'>
	"Where the milliseconds of this binning went: every phase of
	 VGTileBinning class >> stageNames the build reached, its microseconds, and its share of the
	 ones measured. The order is the table's own, so a phase cannot be shown under a name no
	 report has, and the share is computed from the rows beside it, which is why it reads as a
	 share of what was timed and not of the frame.
	 The tab is inactive on a binning built without recordStages, which is every binning a
	 running tool makes."
	| measured total |
	measured := self stageMicroseconds.
	total := measured values inject: 0 into: [ :sum :each | sum + each ].
	^ aBuilder newTable
		  addColumn: (SpStringTableColumn
				   title: 'Phase'
				   evaluated: [ :each | each key asString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Microseconds'
				   evaluated: [ :each | each value printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Share'
				   evaluated: [ :each |
					   (each value * 100 / total) asFloat printShowingDecimalPlaces: 1 ]);
		  items: ((self class stageNames select: [ :each |
					    measured includesKey: each ]) collect: [ :each |
				   each -> (measured at: each) ]);
		  yourself
]

{ #category : 'inspecting' }
VGTileBinning >> inspectorPhasesContext: aContext [
	aContext active: stages isNotNil
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
	^ interiors inject: 0 into: [ :sum :each |
		  sum + (each ifNil: [ 0 ] ifNotNil: [ :marks |
			    marks count: [ :mark | mark ] ]) ]
]

{ #category : 'accessing' }
VGTileBinning >> isEntry: anEntry interiorToTileAt: anIndex [
	"Whether that pair was marked when it was binned. The mark sits beside the ordinal, so this
	 reads it rather than ask the entry a second time."

	self referencesOfTileAt: anIndex do: [ :ordinal :interior |
		(entries at: ordinal) == anEntry ifTrue: [ ^ interior ] ].
	^ false
]

{ #category : 'accessing' }
VGTileBinning >> maxEntriesInATile [
	^ bins inject: 0 into: [ :most :each |
		  most max: (each ifNil: [ 0 ] ifNotNil: [ :ordinals | ordinals size ]) ]
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

{ #category : 'measuring' }
VGTileBinning >> recordStages [
	"Time every phase of the binning I build from here on. A frame of a running tool does not,
	 because the clock is read twice a phase and four times an entry, which on the reference
	 frame is 15312 readings; the census asks, and nothing else does.
	 Sent before the bins are built, since the phases run inside that build: the recipe is
	 VGTileBinning new recordStages, then setDisplayList:grid:."
	stages := VGStageTimings new.
	^ self
]

{ #category : 'accessing' }
VGTileBinning >> referenceCountOfTileAt: anIndex [
	"How many references that tile holds, which is the count the tile record carries."

	^ (bins at: anIndex) ifNil: [ 0 ] ifNotNil: [ :ordinals | ordinals size ]
]

{ #category : 'accessing' }
VGTileBinning >> referencesOfTileAt: anIndex do: aBlock [
	"Every reference of that tile, in the order the frame drew the entries: the ordinal of the
	 entry and whether the entry covers every pixel of the tile. That is the pair the device
	 writes as one reference, so the writer asks one question here and neither searches for an
	 ordinal nor scans a second collection for the mark."

	| ordinals marks |
	ordinals := bins at: anIndex.
	ordinals ifNil: [ ^ self ].
	marks := interiors at: anIndex.
	ordinals withIndexDo: [ :ordinal :each |
		aBlock value: ordinal value: (marks at: each) ]
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
	 a census reads its counts after the frame is drawn.
	 A bin is held in a slot of its own tile rather than under a key, so a tile is found by
	 arithmetic, the tiles come back in tile order with nothing sorted, and the frame pays no
	 hashing: on the reference frame the dictionary was two of the ten milliseconds the binning
	 cost."

	grid := aGrid.
	entries := aDisplayList entries asArray.
	bins := Array new: grid tileCount.
	interiors := Array new: grid tileCount.
	entries withIndexDo: [ :each :ordinal | self bin: each at: ordinal ]
]

{ #category : 'measuring' }
VGTileBinning >> stageMicroseconds [
	"What each phase of my own build cost, keyed by phase name. A phase that was never reached
	 is absent rather than nought, so a binning of an empty frame can be told from one whose
	 phase was too fast to measure."
	^ stages ifNil: [ Dictionary new ] ifNotNil: [ stages microseconds ]
]

{ #category : 'accessing' }
VGTileBinning >> tileIndexesOfEntry: anEntry [
	"The tiles that hold a reference to that entry. The entry is turned into its ordinal once,
	 because a bin names an entry by its place in the frame."

	| ordinal answer |
	ordinal := entries identityIndexOf: anEntry.
	answer := Set new.
	ordinal = 0 ifTrue: [ ^ answer ].
	bins withIndexDo: [ :each :index |
		(each notNil and: [ each includes: ordinal ]) ifTrue: [ answer add: index ] ].
	^ answer
]

{ #category : 'measuring' }
VGTileBinning >> timeStage: aSymbol during: aBlock [
	"The block, answering what it answers, with the microseconds it took added to that phase
	 where a caller asked for the phases. A binning that was not asked evaluates the block and
	 reads no clock at all, so the phases cost a running tool nothing."
	stages ifNil: [ ^ aBlock value ].
	^ stages time: aSymbol during: aBlock
]

{ #category : 'accessing' }
VGTileBinning >> touchedTileCount [
	^ bins count: [ :each | each isNotNil ]
]

{ #category : 'accessing' }
VGTileBinning >> touchedTileIndexes [
	"The tiles that hold at least one reference, in tile order. A bin lives in the slot of its own
	 tile, so the order comes out of the walk and nothing is sorted: the encoding used to sort
	 nineteen hundred keys a frame to get here."

	| answer |
	answer := OrderedCollection new: bins size.
	bins withIndexDo: [ :each :index |
		each ifNotNil: [ answer add: index ] ].
	^ answer asArray
]
