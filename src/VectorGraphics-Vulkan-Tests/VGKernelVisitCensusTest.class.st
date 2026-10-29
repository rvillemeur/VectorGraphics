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
VGKernelVisitCensusTest >> testAReferenceWithMoreEdgesThanASubRowHoldsSpansIsCountedAsOneThatMayOverflow [
	"The spans of a sub-row are written into a block of workgroup storage of a fixed size, so a
	 sub-row that finds more spans than the block holds falls back to the sweep the kernel ran
	 before this unit, which keeps the answer right and makes the overflow a cost rather than a
	 defect. Whether a reference can overflow is bounded by its edges: a straight edge crosses
	 a horizontal sub-row at most once, two crossings bound a span, and the runs of an
	 intersection of shapes are at most the runs of all of them, so a reference of no more than
	 twice the capacity in edges cannot overflow a sub-row at all. The census reports that
	 bound and not a count: a circle of many edges crosses a sub-row twice."

	| plain many |
	plain := VGKernelVisitCensus of: (self
			         encodingOfExtent: 64 @ 64
			         drawnWith: [ :context |
				         context
					         sourceColor: Color blue;
					         rectangleX: 8 y: 8 width: 40 height: 40;
					         fill ]).
	many := VGKernelVisitCensus of: (self
			        encodingOfExtent: 64 @ 64
			        drawnWith: [ :context |
				        context
					        sourceColor: Color blue;
					        circleCenterX: 32 y: 32 radius: 24;
					        fill ]).
	self assert: plain sweptReferences > 0.
	self assert: plain referencesThatMayOverflowASubRow equals: 0.
	self assert: many referencesThatMayOverflowASubRow > 0.
	self
		assert: many referencesThatMayOverflowASubRow
		    <= many sweptReferences
]

{ #category : 'tests' }
VGKernelVisitCensusTest >> testAShapeRecordPastTheStagedBlockIsReadByEveryInvocationForItself [
	"The staged block holds a fixed number of shape records, because workgroup storage is
	 declared when the module is built and an entry may carry any number of clip shapes. A shape
	 record past that capacity is read out of global memory by every invocation that walks it,
	 as every record was before this unit, so a frame of twenty stacked clips still reads most
	 of its shape records once an invocation."

	| encoding census staged spilled |
	encoding := self
		            encodingOfExtent: 64 @ 64
		            drawnWith: [ :context |
			            context sourceColor: Color green.
			            1 to: 20 do: [ :each |
				            context
					            circleCenterX: 32 y: 32 radius: 30 - each;
					            clip ].
			            context
				            rectangleX: 0 y: 0 width: 64 height: 64;
				            fill ].
	census := VGKernelVisitCensus of: encoding.
	self
		assert: (census shapeCountOfEntry: 1) > VGTiledFillStagedBlock shapeCapacity.
	staged := census references * (1 + VGTiledFillStagedBlock shapeCapacity).
	spilled := census neededRecordReads - staged.
	self assert: spilled > 0.
	self
		assert: census recordReads
		equals: staged + (spilled * census invocationsPerTile)
]

{ #category : 'tests' }
VGKernelVisitCensusTest >> testASubRowOfATileIsSweptOnceForTheWholeWorkgroup [
	"The gate of unit 3.3, and the finding phase 3 was built on answered. A sub-row of a tile
	 was swept by every invocation of its row, which is one invocation a column, and every one
	 of those sweeps walked the same edges over the same sub-row to answer the coverage of one
	 pixel out of it. The invocations of a workgroup now divide the sub-rows of their tile
	 between them, each sweeps its own once and writes the spans it finds where the pixels of
	 that sub-row read them, so the sweeps the kernel runs are the sweeps the picture needs and
	 the edges it reads are the edges the picture needs."

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
	self assert: census subRowSweeps equals: census neededSubRowSweeps.
	self assert: census edgeReads equals: census neededEdgeReads
]

{ #category : 'tests' }
VGKernelVisitCensusTest >> testAnInteriorReferenceIsVisitedAndSweptNotAtAll [
	"A fill that covers the whole of a tile is marked interior when it is binned, and the kernel
	 takes the coverage of such a pixel as one without reading an edge. So a frame of one fill
	 over the whole surface is all visits and no sweeps: the records of its one entry are read
	 once a workgroup, which is what unit 3.2 did, and no edge is read at all, which is what
	 unit 3.3 is about.
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

{ #category : 'tests' }
VGKernelVisitCensusTest >> testTheRecordsOfATileAreReadOnceAWorkgroup [
	"The gate of unit 3.2. A record of an entry — its header, its clip, its mask rectangle and
	 the shape records of its block — says the same thing to every pixel of the tile, so the
	 workgroup stages the records in shared memory once and every invocation reads them from
	 there. The record reads of a frame whose entries fit the staged block are therefore the
	 reads the frame needs, one a workgroup, where they were that many times the invocations of
	 a tile before."

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
	self assert: census recordReads equals: census neededRecordReads.
	self
		assert: census invocationsPerTile
		equals: encoding grid tileExtent x * encoding grid tileExtent y
]
