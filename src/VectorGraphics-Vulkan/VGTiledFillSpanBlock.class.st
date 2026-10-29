"
The block of workgroup storage the invocations of one workgroup write the spans of their tile's sub-rows into, and the layout of it: one count a sub-row of the tile in the word block, and `spanCapacity` pairs of floats a sub-row in the float block, the left and the right of each span.

A sub-row of a tile is swept once and the sixteen pixels of its row read what that sweep found. That is what unit 3.3 is: before it every pixel of a row swept the same sub-row for itself over a window one pixel wide, and the edges of every shape of the entry were scanned once a pixel and not once a sub-row. So the sweeping invocation writes maximal runs of the points every antialiased shape of the entry calls inside, trimmed to the clip and to the tile, left to right; a pixel then adds, for each span of each of the fifteen sub-rows of its own row, the part of that span inside its own column. The float that arrives at the pixel is the same subtraction of the same two floats the pixel-wide sweep made of it, which is why the frame stays byte identical.

A sub-row may cover more spans than I hold — a shape has any number of edges and so a sub-row has any number of runs — and the capacity is declared when the module is built. A sweep that finds more writes `overflowMark` as that sub-row's count, and the pixels of that row sweep that sub-row for themselves as they did before this unit. So the capacity costs correctness nothing and `VGKernelVisitCensus` counts the overflows of a frame, which makes a capacity too small a measurement and not a defect.

I am asked which invocation sweeps which sub-row, and the answer depends on the tile: a workgroup of a 16 by 16 tile has 256 invocations and 240 sub-rows and sweeps them in one round, where a workgroup of an 8 by 8 tile has 64 invocations and 120 sub-rows and needs two. The sweeps of the last round that fall past the last sub-row are dropped by the kernel's own guard.
"
Class {
	#name : 'VGTiledFillSpanBlock',
	#superclass : 'Object',
	#instVars : [
		'tileExtent'
	],
	#category : 'VectorGraphics-Vulkan-Tiles',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Tiles'
}

{ #category : 'instance creation' }
VGTiledFillSpanBlock class >> default [
	"The block of the tile size every frame of this engine is binned over."

	^ self onTileExtent: VGTileGrid defaultTileExtent
]

{ #category : 'instance creation' }
VGTiledFillSpanBlock class >> onTileExtent: anExtent [
	"The span block of a workgroup of that tile size. The slots a sub-row holds are the same
	 whatever the tile; how many sub-rows there are, and in how many rounds the invocations
	 sweep them, are not."

	^ self new setTileExtent: anExtent
]

{ #category : 'constants' }
VGTiledFillSpanBlock class >> overflowMark [
	"The count a sweep writes for a sub-row that covers more spans than I hold. It is the
	 largest word there is, so it cannot be mistaken for a count, and the pixels of that
	 sub-row's row read it as the instruction to sweep that sub-row for themselves."

	^ 16rFFFFFFFF
]

{ #category : 'constants' }
VGTiledFillSpanBlock class >> spanCapacity [
	"How many spans of one sub-row of a tile the block holds. A sub-row that finds more than
	 this falls back to the sweep the kernel ran before unit 3.3, once a pixel of it, so the
	 capacity is a cost and never an answer: four is twice what the profiled frames ask of it,
	 and four is what keeps the whole of a workgroup's storage — the records of its tile and the
	 spans of its sub-rows together — inside the 16 KB Vulkan guarantees on every device.

	 Seven is the most that budget allows and it measured a millisecond slower on the reference
	 frame than four, because the storage a workgroup asks for is what a device divides its
	 occupancy by; two measured as fast as four and leaves less room before the fallback. So
	 four is the figure, and the one to revisit is the fallback and not this number."

	^ 4
]

{ #category : 'slots' }
VGTiledFillSpanBlock >> bytes [
	"What one workgroup asks of the device's shared memory for its spans. The width of a slot
	 comes from the compiler's own stride table, as it does for the staged block, and a word
	 and a float are the same four bytes wide."

	^ (self wordCount + self floatCount)
	  * (PVSPIRVEmitter storageBufferArrayStrideFor: #bufferOf_i32)
]

{ #category : 'slots' }
VGTiledFillSpanBlock >> countSlotOfSubRow: aSubRow [
	"The slot of the count of spans of that sub-row, in the word block. A sub-row counts from
	 nought and a slot from nought, so the two are the same number here."

	^ aSubRow
]

{ #category : 'slots' }
VGTiledFillSpanBlock >> endSlotOfSubRow: aSubRow span: aSpan [
	"The slot of the right bound of that span of that sub-row, which follows its left bound."

	^ (self startSlotOfSubRow: aSubRow span: aSpan) + 1
]

{ #category : 'slots' }
VGTiledFillSpanBlock >> floatCount [
	"The slots of the float block: two bounds a span, as many spans as my capacity, for every
	 sub-row of the tile."

	^ 2 * self class spanCapacity * self subRowCount
]

{ #category : 'inspecting' }
VGTiledFillSpanBlock >> inspectorSubRows: aBuilder [
	<inspectorPresentationOrder: 1 title: 'Sub-rows'>
	"Every sub-row of the tile, with the row of pixels it lies in, the slots its count and its
	 spans are written into and the invocation that sweeps it. The rows are read off the slot
	 family and the sweeping arithmetic the kernel itself emits, so the tab cannot name an
	 invocation other than the one that really sweeps, nor a slot the kernel does not write."

	^ aBuilder newTable
		  items: self rows;
		  addColumn: ((SpStringTableColumn title: 'Sub-row' evaluated: [ :each |
					    each first printString ]) beSortable);
		  addColumn: (SpStringTableColumn title: 'Pixel row' evaluated: [ :each |
					   each second printString ]);
		  addColumn: (SpStringTableColumn title: 'Sample' evaluated: [ :each |
					   each third printString ]);
		  addColumn: (SpStringTableColumn title: 'Count slot' evaluated: [ :each |
					   each fourth printString ]);
		  addColumn: (SpStringTableColumn title: 'First bound slot' evaluated: [ :each |
					   each fifth printString ]);
		  addColumn: (SpStringTableColumn title: 'Swept by' evaluated: [ :each |
					   'invocation ' , each sixth printString ]);
		  yourself
]

{ #category : 'inspecting' }
VGTiledFillSpanBlock >> inspectorSubRowsContext: aContext [
	"A block with no tile extent knows neither how many sub-rows it holds nor which invocation
	 sweeps one, so the tab has nothing to show."

	aContext active: tileExtent isNotNil
]

{ #category : 'accessing' }
VGTiledFillSpanBlock >> invocationCount [
	"The invocations of one workgroup, which is one a pixel of a tile."

	^ tileExtent x * tileExtent y
]

{ #category : 'printing' }
VGTiledFillSpanBlock >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPut: $(;
		print: self subRowCount;
		nextPutAll: ' sub-rows, ';
		print: self class spanCapacity;
		nextPutAll: ' spans each, ';
		print: self bytes;
		nextPutAll: ' bytes)'
]

{ #category : 'describing' }
VGTiledFillSpanBlock >> rowOfSubRow: aSubRow [
	"Which row of pixels of the tile that sub-row lies in, counted from nought at the top."

	^ aSubRow // VGTiledFillKernel subRowCount
]

{ #category : 'describing' }
VGTiledFillSpanBlock >> rows [
	"One row a sub-row of the tile: the sub-row, the row of pixels it lies in, which sample of
	 that row it is, the slot its count of spans is written into, the first of its bound slots
	 and the invocation that sweeps it. The slots come from the slot family, so the tab cannot
	 say a count sits where the kernel does not write it."

	^ (0 to: self subRowCount - 1) collect: [ :subRow |
		  {
			  subRow.
			  (self rowOfSubRow: subRow).
			  (self sampleOfSubRow: subRow).
			  (self countSlotOfSubRow: subRow).
			  (self startSlotOfSubRow: subRow span: 0).
			  (self sweeperOfSubRow: subRow) } ]
]

{ #category : 'describing' }
VGTiledFillSpanBlock >> sampleOfSubRow: aSubRow [
	"Which sample of its pixel row that sub-row is, counted from nought as the kernel's own
	 sub-row loop counts them."

	^ aSubRow \\ VGTiledFillKernel subRowCount
]

{ #category : 'initialization' }
VGTiledFillSpanBlock >> setTileExtent: anExtent [
	tileExtent := anExtent
]

{ #category : 'slots' }
VGTiledFillSpanBlock >> startSlotOfSubRow: aSubRow span: aSpan [
	"The slot of the left bound of that span of that sub-row, in the float block. The spans of
	 a sub-row lie together, two slots a span, so the pixels of a row read one run of slots."

	^ 2 * (aSubRow * self class spanCapacity + aSpan)
]

{ #category : 'accessing' }
VGTiledFillSpanBlock >> subRowCount [
	"The sub-rows of one tile: the sub-rows of a pixel row, which the kernel samples a pixel
	 over, times the rows of the tile. The count comes from the kernel so that a sub-row I hold
	 a count for is a sub-row the walk really samples."

	^ tileExtent y * VGTiledFillKernel subRowCount
]

{ #category : 'sweeping' }
VGTiledFillSpanBlock >> subRowSweptBy: anInvocation inRound: aRound [
	"The sub-row that invocation sweeps in that round, counted from nought. The invocations
	 take the sub-rows in their own order, a whole workgroup at a time, so neighbouring
	 invocations sweep neighbouring sub-rows and the sweeps of the last round that fall past
	 the last sub-row are the ones the kernel's guard drops."

	^ aRound * self invocationCount + anInvocation
]

{ #category : 'describing' }
VGTiledFillSpanBlock >> sweeperOfSubRow: aSubRow [
	"The invocation of the workgroup that sweeps that sub-row, which is the invocation whose
	 own number it is taken around the workgroup. Asked of me rather than written into a row,
	 so that a row cannot disagree with the invocation the kernel really guards the sweep with."

	^ aSubRow \\ self invocationCount
]

{ #category : 'accessing' }
VGTiledFillSpanBlock >> sweepsPerInvocation [
	"How many sub-rows one invocation sweeps: one where the workgroup has at least as many
	 invocations as the tile has sub-rows, and as many rounds as it takes where it has fewer.
	 A 16 by 16 tile is 240 sub-rows over 256 invocations and sweeps in one round; an 8 by 8
	 tile is 120 sub-rows over 64 invocations and needs two."

	^ (self subRowCount / self invocationCount) ceiling
]

{ #category : 'accessing' }
VGTiledFillSpanBlock >> tileExtent [
	^ tileExtent
]

{ #category : 'slots' }
VGTiledFillSpanBlock >> wordCount [
	"The slots of the word block: one count a sub-row of the tile."

	^ self subRowCount
]
