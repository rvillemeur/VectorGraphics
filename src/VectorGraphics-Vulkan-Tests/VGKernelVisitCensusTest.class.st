"
I hold the facts of unit 3.0's visit census: that it counts one visit for every reference the encoding wrote, that the edges it counts are the edges of the blocks those references name, that a sub-row is swept once a column of a tile where once a tile would do, that every invocation of a tile reads the same records again, and that a reference the binning marked interior is visited and swept not at all.
The census counts what the kernel does; it dispatches nothing, so every test here passes on a machine with no device.
"
Class {
	#name : 'VGKernelVisitCensusTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Vulkan-Tests-Tests',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Tests'
}

{ #category : 'fixtures' }
VGKernelVisitCensusTest >> binningOfExtent: aPoint drawnWith: aBlock [
	"The frame of that block binned over a grid of the default tile size, which is what an
	 encoding is written from. A test that needs the band layout as well as the buffers builds
	 both from one binning, so the two cannot be of different frames."

	| surface |
	surface := VGCairoImageSurface extent: aPoint.
	aBlock value: surface newContext.
	^ VGTileBinning of: surface displayList extent: aPoint
]

{ #category : 'fixtures' }
VGKernelVisitCensusTest >> encodingOfExtent: aPoint drawnWith: aBlock [
	"The buffers of a frame drawn by that block on a surface of that extent, which is what a
	 census reads. Nothing is dispatched: a census counts what a dispatch would do."

	^ VGTiledFillEncoding on: (self binningOfExtent: aPoint drawnWith: aBlock)
]

{ #category : 'tests' }
VGKernelVisitCensusTest >> testAFrameThatTouchesNoTileIsVisitedNotAtAll [
	"The degenerate frame. A fill wholly beyond the surface is binned into no tile, so there is
	 no workgroup, no visit and nothing to read, and every count of the census is nought rather
	 than nil: a census of such a frame is a report and not a failure."

	| encoding census |
	encoding := self
		            encodingOfExtent: 64 @ 64
		            drawnWith: [ :context |
			            context
				            sourceColor: Color red;
				            rectangleX: 74 y: 74 width: 10 height: 10;
				            fill ].
	census := VGKernelVisitCensus of: encoding.
	self assert: encoding touchedTileCount equals: 0.
	self assert: census tiles equals: 0.
	self assert: census references equals: 0.
	self assert: census subRowSweeps equals: 0.
	self assert: census recordReads equals: 0.
	self deny: census reportRows isEmpty
]

{ #category : 'tests' }
VGKernelVisitCensusTest >> testASubRowIsSweptOnceAColumnOfATileWhereOnceWouldDo [
	"The finding phase 3 is built on. A sub-row of a tile is swept by every invocation of its
	 row, which is one invocation a column, and every one of those sweeps walks the same edges
	 over the same sub-row and answers the coverage of its own pixel out of it. So the sweeps
	 the kernel runs are the sweeps it needs times the width of a tile, and that width is asked
	 of the grid rather than written here."

	| encoding census |
	encoding := self
		            encodingOfExtent: 64 @ 64
		            drawnWith: [ :context |
			            context
				            sourceColor: Color blue;
				            circleCenterX: 32 y: 32 radius: 10;
				            fill ].
	census := VGKernelVisitCensus of: encoding.
	self assert: census neededSubRowSweeps > 0.
	self
		assert: census subRowSweeps
		equals: census neededSubRowSweeps * encoding grid tileExtent x.
	self
		assert: census edgeReads
		equals: census neededEdgeReads * encoding grid tileExtent x
]

{ #category : 'tests' }
VGKernelVisitCensusTest >> testAnInteriorReferenceIsVisitedAndSweptNotAtAll [
	"A fill that covers the whole of a tile is marked interior when it is binned, and the kernel
	 takes the coverage of such a pixel as one without reading an edge. So a frame of one fill
	 over the whole surface is all visits and no sweeps: the records are still read by every
	 invocation, which is what unit 3.2 is about, and no edge is read at all, which is what unit
	 3.3 is about.
	 The fill reaches past every side of the frame, because a tile the border of a fill runs
	 through is not interior to it and the tiles of the outer ring would otherwise be swept."

	| encoding census |
	encoding := self
		            encodingOfExtent: 64 @ 64
		            drawnWith: [ :context |
			            context
				            sourceColor: Color red;
				            rectangleX: -10 y: -10 width: 84 height: 84;
				            fill ].
	census := VGKernelVisitCensus of: encoding.
	self assert: census references equals: census interiorReferences.
	self assert: census subRowSweeps equals: 0.
	self assert: census edgeReads equals: 0.
	self assert: census edgeVisits equals: 0.
	self assert: census recordReads > 0
]

{ #category : 'tests' }
VGKernelVisitCensusTest >> testEveryInvocationOfATileReadsTheRecordsOfItsTileAgain [
	"The second finding. A record of an entry — its header, its clip, its mask rectangle and the
	 shape records of its block — says the same thing to every pixel of the tile, and every
	 invocation reads it for itself. So the record reads of a frame are the reads it needs times
	 the invocations of a tile, which is asked of the kernel's own local size."

	| encoding census |
	encoding := self
		            encodingOfExtent: 64 @ 64
		            drawnWith: [ :context |
			            context
				            sourceColor: Color blue;
				            circleCenterX: 32 y: 32 radius: 10;
				            fill ].
	census := VGKernelVisitCensus of: encoding.
	self assert: census neededRecordReads > 0.
	self
		assert: census recordReads
		equals: census neededRecordReads * census invocationsPerTile.
	self
		assert: census invocationsPerTile
		equals: encoding grid tileExtent x * encoding grid tileExtent y
]

{ #category : 'tests' }
VGKernelVisitCensusTest >> testTheCensusVisitsEveryReferenceTheEncodingWrote [
	"A workgroup walks the references of its own tile and nothing else, so the visits of a frame
	 are its references: the ones the binning counted and the ones the tile table names have to
	 be the same number, or the census is reading a frame the device would not draw."

	| encoding census |
	encoding := self
		            encodingOfExtent: 64 @ 64
		            drawnWith: [ :context |
			            context
				            sourceColor: Color red;
				            rectangleX: 4 y: 4 width: 40 height: 40;
				            fill ].
	census := VGKernelVisitCensus of: encoding.
	self assert: census tiles equals: encoding touchedTileCount.
	self assert: census references equals: encoding binnedEntryCount.
	self assert: census references > 0
]

{ #category : 'tests' }
VGKernelVisitCensusTest >> testTheEdgesTheCensusCountsAreTheEdgesOfTheBlocksTheReferencesName [
	"The census reads the records out of the buffers, as a workgroup does. The bands know the
	 same number from the other side — they are what wrote those blocks — so the two are
	 compared here over a circle, whose flattened edges a band really narrows. Both are built
	 from one binning, so neither can be of a different frame. The circle is small enough that
	 no tile falls wholly inside it, because an interior reference is swept not at all and would
	 be counted on one side only."

	| binning encoding bands census expected |
	binning := self
		           binningOfExtent: 64 @ 64
		           drawnWith: [ :context |
			           context
				           sourceColor: Color blue;
				           circleCenterX: 32 y: 32 radius: 10;
				           fill ].
	encoding := VGTiledFillEncoding on: binning.
	bands := VGTiledFillBands
		         binning: binning
		         fills: (binning entries collect: [ :each | each asTiledFill ]).
	census := VGKernelVisitCensus of: encoding.
	self assert: census interiorReferences equals: 0.
	expected := encoding tileTableRows inject: 0 into: [ :sum :row |
		            | rowOfTiles |
		            rowOfTiles := (encoding grid rowsIntersecting:
			                           (encoding grid boundsOfTileAt: row first))
			                          first.
		            sum + (((bands shapesOfEntry: 1) withIndexCollect: [
				                :shape
				                :ordinal |
				                (bands
					                 edgeIndexesOfEntry: 1
					                 shape: ordinal
					                 inRow: rowOfTiles) size ]) inject: 0 into: [
			                   :total
			                   :each | total + each ]) ].
	self assert: expected > 0.
	self assert: census edgeVisits equals: expected
]
