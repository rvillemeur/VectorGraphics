"
I hold the facts of unit 2.2: what a tile grid is, where an entry lands, and that no frame of the
corpus or of the reference draws a pixel outside the tiles its binning touched.

The grid tests are arithmetic and cheap. The two corpus tests draw real frames on the software path,
which is why they are the slow ones here. `frameOfExtent:drawnWith:` answers a display list caught
before the surface drains it, because draining resets it.

See `VGTileGrid`, `VGTileBinning` and `VGTileBinningCensus`.
"
Class {
	#name : 'VGTileBinningTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Vulkan-Tests-Tests',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Tests'
}

{ #category : 'fixtures' }
VGTileBinningTest >> censusOverTheCorpus [
	"The corpus lives in this package and the census does not, so the cases are handed to it
	 here."

	^ VGTileBinningCensus overCases: VGConformanceCorpus cases
]

{ #category : 'fixtures' }
VGTileBinningTest >> frameOfExtent: anExtent drawnWith: aBlock [
	"The display list a frame records, caught before the surface drains it, which is the only way
	 to see the entries binning reads."

	| surface |
	surface := VGCairoImageSurface extent: anExtent.
	aBlock value: surface newContext.
	^ surface displayList
]

{ #category : 'tests - grid' }
VGTileBinningTest >> testADegenerateRectangleTouchesNoTileAtAll [
	"The degenerate states: nothing to draw, nothing off the grid, and nothing from a rectangle of
	 no width. A tile touched for one of these would be a dispatch over pixels no entry writes."

	| grid |
	grid := VGTileGrid extent: 64 @ 64 tileExtent: 16 @ 16.
	self assert: (grid indexesIntersecting: nil) isEmpty.
	self assert: (grid indexesIntersecting: (10 @ 10 corner: 10 @ 20)) isEmpty.
	self assert: (grid indexesIntersecting: (70 @ 70 corner: 80 @ 80)) isEmpty.
	self
		assert: (grid indexesIntersecting: (-20 @ -20 corner: 4 @ 4)) asArray
		equals: #( 1 )
]

{ #category : 'tests' }
VGTileBinningTest >> testAFillUnderAClipCutByAShapeMarksTheTilesThatShapeEnclosesInterior [
	"A clip cut out by a shape allows a pixel as far as that shape covers it, so a tile the shape
	 encloses wholly is covered in full and a tile the shape runs through is not. The clip here is
	 a circle of radius thirty about the middle of a sixty-four pixel frame: it encloses the four
	 middle tiles of the grid, whose farthest corner is twenty-three pixels out, and it runs
	 through the twelve around them. The binning asks the entry, which is where that rule is kept."

	| binning grid centre marked |
	grid := VGTileGrid extent: 64 @ 64 tileExtent: 16 @ 16.
	centre := 32 @ 32.
	binning := VGTileBinning
		           of: (self
				            frameOfExtent: 64 @ 64
				            drawnWith: [ :context |
					            context
						            circleCenterX: 32 y: 32 radius: 30;
						            clip;
						            rectangleX: 0 y: 0 width: 64 height: 64;
						            fill ])
		           grid: grid.
	self assert: binning touchedTileCount equals: grid tileCount.
	self assert: binning interiorReferenceCount equals: 4.
	marked := (1 to: grid tileCount) select: [ :index |
		          binning
			          isEntry: binning entries first
			          interiorToTileAt: index ].
	marked do: [ :index |
		(grid boundsOfTileAt: index) corners do: [ :corner |
			self assert: (corner distanceTo: centre) < 30 ] ].
	((1 to: grid tileCount) reject: [ :index | marked includes: index ])
		do: [ :index |
			self assert: ((grid boundsOfTileAt: index) corners anySatisfy: [
					 :corner | (corner distanceTo: centre) > 30 ]) ]
]

{ #category : 'tests - binning' }
VGTileBinningTest >> testAFillUnderAnUnboundedOperatorLandsInEveryTileOfTheClip [
	"An unbounded operator writes where the shape covers nothing, so its entry owes every tile of
	 its clip. A binning that read the edges alone would leave those tiles unwritten."

	| list binning |
	list := self frameOfExtent: 64 @ 64 drawnWith: [ :context |
		        context sourceColorR: 1 g: 1 b: 1 a: 1.
		        context operator: VGCairoOperator in.
		        context rectangleX: 2 y: 2 width: 8 height: 8.
		        context fill ].
	binning := VGTileBinning of: list extent: 64 @ 64.
	self assert: binning touchedTileCount equals: binning grid tileCount
]

{ #category : 'tests - grid' }
VGTileBinningTest >> testAGridCoversItsExtentWithWholeTiles [
	"The last column and the last row are short where the extent does not divide by the tile, and
	 they still have to be there, or the right and bottom edges of a frame would never be drawn."

	| grid |
	grid := VGTileGrid extent: 800 @ 600 tileExtent: 16 @ 16.
	self assert: grid columns equals: 50.
	self assert: grid rows equals: 38.
	self assert: grid tileCount equals: 50 * 38.
	self assert: (grid boundsOfTileAt: 1) equals: (0 @ 0 corner: 16 @ 16).
	self
		assert: (grid boundsOfTileAt: grid tileCount)
		equals: (784 @ 592 corner: 800 @ 600)
]

{ #category : 'tests - grid' }
VGTileBinningTest >> testARectangleTouchesTheTilesItOverlapsAndNoOthers [
	| grid |
	grid := VGTileGrid extent: 64 @ 64 tileExtent: 16 @ 16.
	self
		assert: (grid indexesIntersecting: (2 @ 2 corner: 14 @ 14)) asArray
		equals: #( 1 ).
	self
		assert: (grid indexesIntersecting: (14 @ 2 corner: 18 @ 14)) size
		equals: 2.
	self
		assert: (grid indexesIntersecting: (14 @ 14 corner: 18 @ 18)) size
		equals: 4.
	self
		assert: (grid indexesIntersecting: (0 @ 0 corner: 64 @ 64)) size
		equals: grid tileCount
]

{ #category : 'tests' }
VGTileBinningTest >> testATileWhollyInsideAFillIsMarkedInteriorAndATileOnItsEdgeIsNot [
	"A tile the fill covers in full needs no walk over the edges: every pixel of it has coverage
	 one. The binning marks those pairs as it bins them, because it has the tile and the entry in
	 hand there and nothing later holds the pair. The fill runs from 8 to 56 of a 64 pixel frame,
	 so the four middle tiles of the sixteen are inside it and the twelve around them are cut."

	| binning grid inside onTheEdge |
	grid := VGTileGrid extent: 64 @ 64 tileExtent: 16 @ 16.
	binning := VGTileBinning
		           of: (self
				            frameOfExtent: 64 @ 64
				            drawnWith: [ :context |
					            context
						            rectangleX: 8 y: 8 width: 48 height: 48;
						            fill ])
		           grid: grid.
	inside := (grid indexesIntersecting: (33 @ 33 corner: 34 @ 34)) anyOne.
	onTheEdge := (grid indexesIntersecting: (0 @ 0 corner: 1 @ 1)) anyOne.
	self assert: (binning interiorEntriesOfTileAt: inside) size equals: 1.
	self assert: (binning interiorEntriesOfTileAt: onTheEdge) isEmpty.
	self assert: binning interiorReferenceCount equals: 4
]

{ #category : 'tests - binning' }
VGTileBinningTest >> testAnEmptyDisplayListTouchesNoTile [
	| binning |
	binning := VGTileBinning of: VGDisplayList new extent: 64 @ 64.
	self assert: binning touchedTileCount equals: 0.
	self assert: binning binnedEntryCount equals: 0.
	self assert: binning maxEntriesInATile equals: 0.
	self assert: (binning entriesOfTileAt: 1) isEmpty
]

{ #category : 'tests - binning' }
VGTileBinningTest >> testAnEntryLandsInTheTilesItsOwnBoundingBoxTouches [
	"The binning asks the entry where it can touch rather than measuring the geometry again, so a
	 change to a bounding box moves the entry's tiles with it."

	| list binning entry |
	list := self frameOfExtent: 64 @ 64 drawnWith: [ :context |
		        context sourceColorR: 1 g: 0 b: 0 a: 1.
		        context rectangleX: 2 y: 2 width: 10 height: 10.
		        context fill ].
	binning := VGTileBinning of: list extent: 64 @ 64.
	entry := list entries first.
	self
		assert: binning touchedTileIndexes asSortedCollection asArray
		equals: (binning grid indexesIntersecting: entry boundingBox)
				asSortedCollection asArray.
	self assert: binning binnedEntryCount equals: binning touchedTileCount.
	self assert: (binning entriesOfTileAt: binning touchedTileIndexes anyOne) asArray
		equals: { entry }
]

{ #category : 'tests' }
VGTileBinningTest >> testEveryPairMarkedInteriorHasCoverageOneAtEveryPixelOfItsTile [
	"The gate of the mark, and it reads the software coverage rather than the rule that made the
	 mark: for every tile and entry the binning marked, VGTileCoverage answers one at every pixel
	 of that tile. A mark that is wrong by a single pixel makes the device paint whole what the
	 walk would have painted in part."

	| binning grid marked |
	grid := VGTileGrid extent: 64 @ 64 tileExtent: 16 @ 16.
	binning := VGTileBinning
		           of: (self
				            frameOfExtent: 64 @ 64
				            drawnWith: [ :context |
					            context
						            circleCenterX: 30 y: 30 radius: 24;
						            fill;
						            rectangleX: 20 y: 20 width: 40 height: 40;
						            fill ])
		           grid: grid.
	marked := 0.
	1 to: grid tileCount do: [ :index |
		| bounds |
		bounds := grid boundsOfTileAt: index.
		(binning interiorEntriesOfTileAt: index) do: [ :entry |
			| coverage |
			marked := marked + 1.
			coverage := VGTileCoverage of: entry.
			bounds top to: bounds bottom - 1 do: [ :row |
				bounds left to: bounds right - 1 do: [ :column |
					self
						assert: (coverage atX: column row: row) = 1.0
						description: 'tile ' , index printString , ' pixel '
							, (column @ row) printString ] ] ] ].
	self assert: marked > 0
]

{ #category : 'tests - corpus' }
VGTileBinningTest >> testEveryPixelEveryCorpusFrameDrawsLiesInATouchedTile [
	"The gate of this unit, and the only check here that does not read a bounding box: every corpus
	 frame is drawn on the software path and every pixel it really wrote is required to lie in a
	 tile the binning touched. A pixel outside those tiles is a pixel the tiled path would leave
	 behind, which is how the unbounded operators were caught."

	| census |
	census := self censusOverTheCorpus.
	self deny: census rows isEmpty.
	census rows do: [ :row |
		self assert: row strayPixelCount isZero description: row name ].
	self assert: census strayPixelCount equals: 0
]

{ #category : 'tests' }
VGTileBinningTest >> testTheBinningReportNamesHowManyPairsAreInteriorOfHowManyBinned [
	"The interior marks are what the kernel reads instead of walking sub rows, so the report has
	 to show them: a frame whose marks vanished would otherwise look exactly like one whose marks
	 are all there."

	| binning row |
	binning := VGTileBinningExamples binningWithInteriorTilesMarked.
	row := binning reportRows detect: [ :each | each key = 'pairs interior' ].
	self
		assert: row value
		equals: binning interiorReferenceCount printString , ' of '
			, binning binnedEntryCount printString.
	self assert: binning interiorReferenceCount > 0
]

{ #category : 'tests - corpus' }
VGTileBinningTest >> testTheCensusCountsTheTilesTouchedByEveryCaseOfTheCorpus [
	"The second half of the gate: a count of tiles touched per case, with no case missing and none
	 claiming more tiles than its grid holds."

	| census |
	census := self censusOverTheCorpus.
	self assert: census rows size equals: VGConformanceCorpus cases size.
	census rows do: [ :row |
		self assert: row tilesTouched <= row tilesTotal description: row name.
		self assert: row tilesTotal > 0 description: row name.
		self assert: row maxEntriesInATile <= row entries description: row name ]
]

{ #category : 'tests - grid' }
VGTileBinningTest >> testTheDefaultTileHoldsAWholeNumberOfWorkgroups [
	"The tile is the unit of dispatch, so its pixels have to divide by the work items a workgroup
	 holds; a tile that leaves a part of a workgroup idle wastes that part on every tile of every
	 frame."

	| tile |
	tile := VGTileGrid defaultTileExtent.
	self
		assert: (tile x * tile y) \\ VGVulkanRoundTrip workItemsPerGroup
		equals: 0
]

{ #category : 'tests - corpus' }
VGTileBinningTest >> testTheReferenceFrameDrawsNoPixelOutsideATouchedTile [
	"The conformance corpus draws through the context verbs; the reference frame draws through the
	 Bloc renderer, with gradients, strokes, glyphs and blits in it, and it is eight hundred by six
	 hundred rather than sixty-four square. The pixels have to lie in the tiles there too."

	| row |
	row := VGTileBinningCensus overTheReferenceFrame rows first.
	self assert: row strayPixelCount equals: 0.
	self assert: row entries > 0.
	self assert: row tilesTouched > 0
]

{ #category : 'tests - grid' }
VGTileBinningTest >> testTheTilesOfAGridAreDisjointAndCoverEveryPixelOfIt [
	"Asked of the grid itself rather than written down: every pixel of the extent belongs to one
	 tile and to no other, because a pixel in two tiles would be composited twice and a pixel in
	 none would never be written."

	| grid extent seen |
	extent := 37 @ 23.
	grid := VGTileGrid extent: extent tileExtent: 8 @ 8.
	seen := Set new.
	1 to: grid tileCount do: [ :index |
		| bounds |
		bounds := grid boundsOfTileAt: index.
		bounds origin x to: bounds corner x - 1 do: [ :x |
			bounds origin y to: bounds corner y - 1 do: [ :y |
				self deny: (seen includes: x @ y).
				seen add: x @ y ] ] ].
	self assert: seen size equals: extent x * extent y
]

{ #category : 'tests - binning' }
VGTileBinningTest >> testTwoDistantEntriesShareNoTile [
	"What binning is for: two shapes far apart give two small dispatches and not one over the whole
	 frame."

	| list binning first second |
	list := self frameOfExtent: 128 @ 128 drawnWith: [ :context |
		        context sourceColorR: 1 g: 0 b: 0 a: 1.
		        context rectangleX: 2 y: 2 width: 8 height: 8.
		        context fill.
		        context rectangleX: 100 y: 100 width: 8 height: 8.
		        context fill ].
	binning := VGTileBinning of: list extent: 128 @ 128.
	self assert: list entries size equals: 2.
	first := binning tileIndexesOfEntry: list entries first.
	second := binning tileIndexesOfEntry: list entries second.
	self assert: (first intersection: second) isEmpty.
	self assert: binning touchedTileCount equals: first size + second size
]
