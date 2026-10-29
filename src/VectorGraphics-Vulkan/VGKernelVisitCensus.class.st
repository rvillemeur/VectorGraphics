"
I count what the tiled fill kernel does to a frame, without dispatching it: the tiles it runs a workgroup for, the references those workgroups walk, the records every invocation reads, the sub-rows it sweeps and the edges those sweeps read.
Beside each count I answer the count the same picture needs — one sweep a sub-row rather than one a pixel of its row, one read of a record a workgroup rather than one an invocation — so the redundancy phase 3 removes is a measured ratio and not an estimate. The ratios come out as the width of a tile and as the invocations of a tile, both asked of the grid and of the kernel's own local size.
Everything is read out of the buffers an encoding wrote, as a workgroup reads them, so a count here is of the frame the device would really draw. An interior reference — one the binning marked as covering the whole of its tile — is visited and read but never swept, which is what the kernel does with it.
"
Class {
	#name : 'VGKernelVisitCensus',
	#superclass : 'Object',
	#instVars : [
		'encoding',
		'counts'
	],
	#category : 'VectorGraphics-Vulkan-Budget',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Budget'
}

{ #category : 'instance creation' }
VGKernelVisitCensus class >> of: anEncoding [
	"The census of the frame those buffers hold. Counting it costs one walk of the tile table
	 and nothing else, so it can be asked of any frame a dispatch could draw."

	^ self new setEncoding: anEncoding
]

{ #category : 'accessing' }
VGKernelVisitCensus >> edgeReads [
	"How many times an edge is read: every sweep walks the whole run of its block, and every
	 invocation of the tile runs that sweep again."

	^ self edgeVisits * self invocationsPerTile
	  * VGTiledFillKernel subRowCount
]

{ #category : 'accessing' }
VGKernelVisitCensus >> edgeVisits [
	"Pairs of an edge and a tile: every edge the blocks of the swept references name, counted
	 once a reference. This is the walk unit 2.7 shortened, and it is what a sweep of a tile
	 reads once over."

	^ counts at: #edgeVisits
]

{ #category : 'reading' }
VGKernelVisitCensus >> edgesOfBlock: aBlock shapes: aCount [
	"The edges the records of that block name, summed over its shapes. A record of a band names
	 only the edges of its shape that reach the rows of its row of tiles, which is what unit 2.7
	 narrowed, so this is the run a sweep of that tile really walks."

	^ (aBlock to: aBlock + aCount - 1) inject: 0 into: [ :sum :record |
		  sum + (encoding shapes at:
				   record * VGTiledFillLayout shapeRecordWords
				   + VGTiledFillLayout shapeEdgeCountField) ]
]

{ #category : 'inspector' }
VGKernelVisitCensus >> inspectorCounts: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Counts'>
	"What the kernel reads of this encoding beside what the work needs, every row read from the
	 report so the tab cannot show a count the census did not take. Nothing is dispatched and no
	 device is opened: a census counts what a dispatch would do."

	^ aBuilder newTable
		  items: self reportRows;
		  addColumn: (SpStringTableColumn title: 'Count' evaluated: [ :each |
					   each key ]);
		  addColumn:
			  (SpStringTableColumn title: 'Value' evaluated: [ :each |
					   each value ]);
		  yourself
]

{ #category : 'inspector' }
VGKernelVisitCensus >> inspectorCountsContext: aContext [
	"A census built on no encoding has counted nothing."

	aContext active: encoding isNotNil
]

{ #category : 'accessing' }
VGKernelVisitCensus >> interiorReferences [
	"The references the binning marked as covering the whole of their tile, which the kernel
	 draws at full coverage without a sweep."

	^ counts at: #interiorReferences
]

{ #category : 'accessing' }
VGKernelVisitCensus >> invocationsPerTile [
	"How many invocations a workgroup runs over one tile, asked of the kernel's own local size
	 rather than written here, so that a kernel which stops running one invocation a pixel
	 changes this count with it."

	^ (VGTiledFillKernel onTileExtent: encoding grid tileExtent) localSize
		  inject: 1
		  into: [ :product :each | product * each ]
]

{ #category : 'accessing' }
VGKernelVisitCensus >> neededEdgeReads [
	"How many times the same picture needs an edge read: once a sub-row of the tile its block
	 belongs to."

	^ self edgeVisits * self subRowsPerTile
]

{ #category : 'accessing' }
VGKernelVisitCensus >> neededRecordReads [
	"The records the frame holds for its tiles: a header for every reference of a tile and the
	 shape records of the block that reference names. One workgroup needs each of them once."

	^ counts at: #neededRecordReads
]

{ #category : 'accessing' }
VGKernelVisitCensus >> neededSubRowSweeps [
	"The sweeps the same picture needs: one a sub-row of a tile for every reference swept there.
	 A sweep of a sub-row crosses the edges once and the coverage of every pixel of that sub-row
	 falls out of the crossings, so nothing of the picture is lost by sweeping it once."

	^ self sweptReferences * self subRowsPerTile
]

{ #category : 'printing' }
VGKernelVisitCensus >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPut: $(;
		print: self tiles;
		nextPutAll: ' tiles, ';
		print: self references;
		nextPutAll: ' references';
		nextPut: $)
]

{ #category : 'reporting' }
VGKernelVisitCensus >> ratioRowsInto: aCollection [
	"The three counts phase 3 is about, each with what the kernel does, what the picture needs
	 and the factor between them. A frame that needs nothing of a kind answers no factor rather
	 than a division by nought."

	{
		{ 'sub-row sweeps'. self subRowSweeps. self neededSubRowSweeps }.
		{ 'edge reads'. self edgeReads. self neededEdgeReads }.
		{ 'record reads'. self recordReads. self neededRecordReads } } do: [
		:each |
		aCollection add: each first -> each second printString.
		aCollection add: (each first , ' needed') -> each third printString.
		each third = 0 ifFalse: [
			aCollection add: (each first , ' over')
				-> (((each second / each third) asFloat printShowingDecimalPlaces: 1)
						 , ' times') ] ]
]

{ #category : 'counting' }
VGKernelVisitCensus >> recordReads [
	"How many records the kernel reads. A record staged in workgroup storage is read once a
	 workgroup, by the one invocation that writes its slot; a shape record past the capacity of
	 the staged block is read by every invocation of the tile for itself, which is what the
	 kernel did with every record before unit 3.2."

	^ (counts at: #stagedRecordReads)
	  + ((counts at: #unstagedRecordReads) * self invocationsPerTile)
]

{ #category : 'accessing' }
VGKernelVisitCensus >> references [
	^ counts at: #references
]

{ #category : 'reporting' }
VGKernelVisitCensus >> reportRows [
	"The census as rows: what the frame is, what the kernel does to it, what the same picture
	 needs, and the ratio between the two where there is one. The ratios are divided here and
	 not written down, so a kernel that stops repeating itself reports a one."

	| rows |
	rows := OrderedCollection new.
	rows add: 'tiles' -> self tiles printString.
	rows add: 'references' -> self references printString.
	rows add: 'interior references' -> self interiorReferences printString.
	rows add: 'invocations a tile' -> self invocationsPerTile printString.
	rows add: 'sub-rows a tile' -> self subRowsPerTile printString.
	rows add: 'edge and tile pairs' -> self edgeVisits printString.
	self ratioRowsInto: rows.
	^ rows asArray
]

{ #category : 'building' }
VGKernelVisitCensus >> setEncoding: anEncoding [
	"Walk the tile table as a workgroup walks it: every touched tile, every reference of that
	 tile, and for each the entry it names, whether the binning marked it interior to the tile,
	 and the block of shape records that tile is to read for it. What is counted is the reading,
	 so an interior reference is counted as a visit and as records read and as no sweep at all,
	 which is what the kernel does with one."

	encoding := anEncoding.
	counts := self tallyOfWalk
]

{ #category : 'reading' }
VGKernelVisitCensus >> shapeCountOfEntry: anIdentifier [
	"How many shape records a block of that entry holds: its fill and the shapes of its clip.
	 Read out of the header the encoding wrote, so this is the count a workgroup reads."

	^ encoding headers at:
		  (anIdentifier - 1) * VGTiledFillLayout entryHeaderWords
		  + VGTiledFillLayout shapeCountField
]

{ #category : 'counting' }
VGKernelVisitCensus >> stagedRecordReads [
	"The records the workgroup stages in shared memory, each read out of global memory once."

	^ counts at: #stagedRecordReads
]

{ #category : 'accessing' }
VGKernelVisitCensus >> subRowSweeps [
	"The sweeps the kernel runs: every invocation of a tile sweeps the sub-rows of its own pixel
	 row for every reference it is not given as interior, so a sub-row is swept once for each
	 pixel of it."

	^ self sweptReferences * self invocationsPerTile
	  * VGTiledFillKernel subRowCount
]

{ #category : 'accessing' }
VGKernelVisitCensus >> subRowsPerTile [
	"The sub-rows of one tile: every pixel row of it sampled on the rasteriser's own sub-row
	 grid. This is how many sweeps a tile needs for one reference, one sweep to a sub-row."

	^ encoding grid tileExtent y * VGTiledFillKernel subRowCount
]

{ #category : 'accessing' }
VGKernelVisitCensus >> sweptReferences [
	"The references whose coverage is walked: every reference of the frame but the interior
	 ones, whose coverage the kernel takes as one without reading an edge."

	^ counts at: #sweptReferences
]

{ #category : 'building' }
VGKernelVisitCensus >> tally: aTally add: anInteger to: aKey [
	"Every counter of the walk starts at nought and is only ever added to, so one place reads one
	 back and no counter of mine can be left unset."

	aTally at: aKey put: (aTally at: aKey) + anInteger
]

{ #category : 'building' }
VGKernelVisitCensus >> tallyOfWalk [
	"One pass over the tile table, every reference of every touched tile tallied as the kernel
	 reads it. The counters that are sums of others are worked out once the pass is over, so no
	 reference has to know about them."

	| tally |
	tally := Dictionary new.
	#( #references #interiorReferences #edgeVisits #stagedRecordReads
	   #unstagedRecordReads ) do: [ :each | tally at: each put: 0 ].
	encoding tileTableRows do: [ :row |
		| offset |
		offset := row third.
		1 to: row fourth do: [ :position |
			self tallyReferenceAt: offset + position into: tally ] ].
	tally
		at: #tiles put: encoding touchedTileCount;
		at: #neededRecordReads
		put: (tally at: #stagedRecordReads) + (tally at: #unstagedRecordReads);
		at: #sweptReferences
		put: (tally at: #references) - (tally at: #interiorReferences).
	^ tally
]

{ #category : 'building' }
VGKernelVisitCensus >> tallyReferenceAt: anIndex into: aTally [
	"One reference of one tile: the entry it names, whether the binning marked it interior to the
	 tile, and the records this tile reads for it.
	 A record is counted once a workgroup when it is staged in workgroup storage and once an
	 invocation when it is not: a shape record past the capacity of VGTiledFillStagedBlock is read
	 out of global memory by every invocation that walks it."

	| reference identifier shapes capacity |
	reference := encoding entryRefs at: anIndex.
	identifier := VGTiledFillLayout identifierOfReference: reference.
	shapes := self shapeCountOfEntry: identifier.
	capacity := VGTiledFillStagedBlock shapeCapacity.
	self tally: aTally add: 1 to: #references.
	self tally: aTally add: 1 + (shapes min: capacity) to: #stagedRecordReads.
	self
		tally: aTally
		add: (shapes - capacity max: 0)
		to: #unstagedRecordReads.
	(VGTiledFillLayout isInteriorReference: reference)
		ifTrue: [ self tally: aTally add: 1 to: #interiorReferences ]
		ifFalse: [
			self
				tally: aTally
				add: (self
						 edgesOfBlock: (encoding refShapes at: anIndex)
						 shapes: shapes)
				to: #edgeVisits ]
]

{ #category : 'accessing' }
VGKernelVisitCensus >> tiles [
	^ counts at: #tiles
]

{ #category : 'counting' }
VGKernelVisitCensus >> unstagedRecordReads [
	"The records the staged block has no room for, each read by every invocation of the tile."

	^ counts at: #unstagedRecordReads
]
