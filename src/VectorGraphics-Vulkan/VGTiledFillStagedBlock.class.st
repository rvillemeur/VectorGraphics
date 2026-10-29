"
The block of workgroup storage one workgroup of the tiled fill kernel stages the records of its tile in: the frame record, the tile record, the reference word and the shape block offset of the entry standing, and that entry's header, clip, mask rectangle, paint block and as many of its shape records as I have room for.
Every invocation of a workgroup reads the same records — a header says the same thing to the pixel at one corner of a tile as to the pixel at the other — so the workgroup reads each word once into me and every invocation reads it back out of shared memory. I am the layout of that: one slot a word, numbered from zero, with the words and the floats in blocks of their own because a slot holds one type.
I hold the records as runs, and a run is what the staging loads: the words of one record lie next to each other both in the buffer they come from and in me, so the invocations of the workgroup take one word each of a run by their own number and a run of sixty-four words is staged in one step, as a run of four is. The writer of a slot is therefore its position in its own run, so no two words of one run share a writer, and what this asks of a run is only that it be no longer than the workgroup.
My capacity in shape records is fixed, because workgroup storage is declared when the module is built while an entry carries as many shapes as its clip was cut out with. A shape record past that capacity is read out of global memory by every invocation that walks it, which is what the kernel did with every record before unit 3.2. Key methods: wordCount, floatCount, the slot family, the run family, writerOfWordSlot:, rows.
"
Class {
	#name : 'VGTiledFillStagedBlock',
	#superclass : 'Object',
	#instVars : [
		'tileExtent'
	],
	#category : 'VectorGraphics-Vulkan-Tiles',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Tiles'
}

{ #category : 'instance creation' }
VGTiledFillStagedBlock class >> default [
	"The block of the tile size every frame of this engine is binned over."

	^ self onTileExtent: VGTileGrid defaultTileExtent
]

{ #category : 'instance creation' }
VGTiledFillStagedBlock class >> onTileExtent: anExtent [
	"The block a workgroup of that tile size stages into: the slots are the same whatever the
	 tile, and which invocation writes which slot is not, because a workgroup of a smaller tile
	 has fewer invocations than I have slots."

	^ self new setTileExtent: anExtent
]

{ #category : 'constants' }
VGTiledFillStagedBlock class >> shapeCapacity [
	"How many shape records of the entry standing I hold. The deepest entry of the profiled
	 frame carries two shapes — its fill and one clip shape — so sixteen is eight times what a
	 real frame has asked of it, and the whole block is still well under a kilobyte of the
	 sixteen a workgroup may have on the smallest device this engine runs on. A shape past it is
	 read from global memory by every invocation, so the capacity costs correctness nothing."

	^ 16
]

{ #category : 'slots' }
VGTiledFillStagedBlock >> bytes [
	"What one workgroup asks of the device's shared memory. The width of a slot comes from the
	 compiler's own stride table, so it follows the element type rather than being restated
	 here, and a word and a float are the same four bytes wide."

	^ (self wordCount + self floatCount)
	  * (PVSPIRVEmitter storageBufferArrayStrideFor: #bufferOf_i32)
]

{ #category : 'runs' }
VGTiledFillStagedBlock >> clipRun [
	"The run of the clip of the entry standing, in the float block: four sides, each a float."

	^ {
		  #float.
		  (self clipSlotOfField: 1).
		  'clip'.
		  (self fieldNamesOfStride: #clipFloats) }
]

{ #category : 'slots' }
VGTiledFillStagedBlock >> clipSlotOfField: anInteger [
	"The slot of one side of the clip of the entry standing, in the float block: a clip is four
	 floats and a slot of that block holds a float."

	^ anInteger - 1
]

{ #category : 'runs' }
VGTiledFillStagedBlock >> entryReferenceRun [
	"The run of the reference word of the entry standing: one word, the identifier of that entry
	 and in its top bit the mark that says it covers the whole of this tile."

	^ {
		  #word.
		  self referenceSlot.
		  'reference'.
		  { 'entry of the reference' } }
]

{ #category : 'describing' }
VGTiledFillStagedBlock >> fieldNamesOfStride: aSelector [
	"The name of every word of the record of that stride, in order, read out of the layout's own
	 table so that a row of mine cannot name a field the record has not and a spare word shows
	 as spare."

	^ (VGTiledFillLayout recordRows select: [ :each | each first = aSelector ])
		  collect: [ :each | each fourth ]
]

{ #category : 'slots' }
VGTiledFillStagedBlock >> floatCount [
	"The slots of the float block: the clip of the entry standing, the rectangle of its mask and
	 its paint block. The stops of a gradient are not here — there is any number of them and
	 the search reads two — and neither are the edges of a shape, which are unit 3.3's own."

	^ 2 * VGTiledFillLayout clipFloats
	  + VGTiledFillLayout paintBlockFloats
]

{ #category : 'describing' }
VGTiledFillStagedBlock >> floatRows [
	"Every float slot, in slot order. The clip and the mask rectangle are both four floats of the
	 same shape, so they read the one stride the layout names and are told apart by the record
	 column."

	^ self rowsOfRuns: self floatRuns
]

{ #category : 'runs' }
VGTiledFillStagedBlock >> floatRuns [
	"Every run of the float block, in slot order."

	^ {
		  self clipRun.
		  self maskRectRun.
		  self paintRun }
]

{ #category : 'describing' }
VGTiledFillStagedBlock >> frameFieldNames [
	"The layout's table names the words of the records the layout writes, and the frame record is
	 the kernel's own, so its names are read off the kernel instead: every class-side selector of
	 it that names a field, in the order of the word each names."

	^ ((VGTiledFillKernel class selectors select: [ :each | each endsWith: 'Field' ])
		   asSortedCollection: [ :a :b |
			   (VGTiledFillKernel perform: a) <= (VGTiledFillKernel perform: b) ]) asArray
		  collect: [ :each | each asString ]
]

{ #category : 'runs' }
VGTiledFillStagedBlock >> frameRun [
	"The run of the frame record: the storage it is staged in, the slot its first word sits in,
	 the record it is, and the name of every word of it. A run is what the staging loads — the
	 invocations of the workgroup take one word each of it, by their own number — so its length
	 is the number of words it names and cannot be told apart from them."

	^ {
		  #word.
		  (self frameSlotOfField: 1).
		  'frame record'.
		  self frameFieldNames }
]

{ #category : 'slots' }
VGTiledFillStagedBlock >> frameSlotOfField: anInteger [
	"The slot of one field of the frame record, which is the first record of the word block. A
	 field counts from one and a slot from zero, so the two differ by one here and everywhere
	 below."

	^ anInteger - 1
]

{ #category : 'runs' }
VGTiledFillStagedBlock >> headerRun [
	"The run of the header of the entry standing. The whole header is a run and not the fields
	 the walk reads, because a run is loaded in one step whatever its length and a field the
	 kernel starts reading would otherwise cost a change here as well."

	^ {
		  #word.
		  (self headerSlotOfField: 1).
		  'entry header'.
		  (self fieldNamesOfStride: #entryHeaderWords) }
]

{ #category : 'slots' }
VGTiledFillStagedBlock >> headerSlotOfField: anInteger [
	"The slot of one field of the header of the entry standing. The whole header is staged and
	 not the fields the walk reads, because a spare word costs a slot and a field the kernel
	 starts reading would otherwise cost a change here as well."

	^ self shapeOffsetSlot + anInteger
]

{ #category : 'inspecting' }
VGTiledFillStagedBlock >> inspectorSlots: aBuilder [
	<inspectorPresentationOrder: 1 title: 'Slots'>
	"Every slot of the block, with the record it stages and the invocation that writes it. The
	 rows are built from the runs the staging really loads and from the layout's own table of
	 field names, so the tab cannot say a word sits where the kernel does not read it, nor name
	 an invocation other than the one that stages it."

	^ aBuilder newTable
		  items: self rows;
		  addColumn: (SpStringTableColumn title: 'Storage' evaluated: [ :each |
					   each first asString ]);
		  addColumn: ((SpStringTableColumn title: 'Slot' evaluated: [ :each |
						each second printString ]) beSortable);
		  addColumn: (SpStringTableColumn title: 'Record' evaluated: [ :each | each third ]);
		  addColumn: (SpStringTableColumn title: 'Word' evaluated: [ :each | each fourth ]);
		  addColumn: (SpStringTableColumn title: 'Written by' evaluated: [ :each |
					   'invocation ' , each fifth printString ]);
		  yourself
]

{ #category : 'inspecting' }
VGTiledFillStagedBlock >> inspectorSlotsContext: aContext [
	"A block with no tile extent knows no workgroup, so it cannot say which invocation writes a
	 slot and the tab has nothing to show."

	aContext active: tileExtent isNotNil
]

{ #category : 'accessing' }
VGTiledFillStagedBlock >> invocationCount [
	"The invocations of one workgroup, which is one a pixel of a tile."

	^ tileExtent x * tileExtent y
]

{ #category : 'runs' }
VGTiledFillStagedBlock >> maskRectRun [
	"The run of the rectangle of the mask of the entry standing. A mask rectangle is laid out as
	 a clip rectangle, so the fields of a clip name its fields and one base in the buffers serves
	 the two runs."

	^ {
		  #float.
		  (self maskRectSlotOfField: 1).
		  'mask rectangle'.
		  (self fieldNamesOfStride: #clipFloats) }
]

{ #category : 'slots' }
VGTiledFillStagedBlock >> maskRectSlotOfField: anInteger [
	"The slot of one side of the rectangle of the mask of the entry standing. A mask rectangle
	 is laid out as a clip rectangle, so the fields of a clip name its fields and the slots
	 follow the clip's own four."

	^ VGTiledFillLayout clipFloats + anInteger - 1
]

{ #category : 'describing' }
VGTiledFillStagedBlock >> paintFieldNames [
	"The sixteen floats of a paint block mean different things under different paint tags — a
	 matrix under a gradient, a colour under none — so the layout names none of them and they are
	 named here by the coefficient the pixel emitter asks for."

	^ (1 to: VGTiledFillLayout paintBlockFloats) collect: [ :each |
		  'coefficient ' , each printString ]
]

{ #category : 'runs' }
VGTiledFillStagedBlock >> paintRun [
	"The run of the paint block of the entry standing. The whole block is a run because every
	 paint of the subset reads its matrix and most of the rest: the tag selects an arm of the
	 emission and not a run of coefficients."

	^ {
		  #float.
		  (self paintSlotOfField: 1).
		  'paint block'.
		  self paintFieldNames }
]

{ #category : 'slots' }
VGTiledFillStagedBlock >> paintSlotOfField: anInteger [
	"The slot of one coefficient of the paint block of the entry standing, numbered as the paint
	 ABI numbers it. The whole block is staged because every paint of the subset reads its
	 matrix and most of the rest: the tag selects an arm of the emission and not a run of
	 coefficients."

	^ 2 * VGTiledFillLayout clipFloats + anInteger - 1
]

{ #category : 'printing' }
VGTiledFillStagedBlock >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPut: $(;
		print: self wordCount;
		nextPutAll: ' words, ';
		print: self floatCount;
		nextPutAll: ' floats)'
]

{ #category : 'slots' }
VGTiledFillStagedBlock >> referenceSlot [
	"The slot of the reference word of the entry standing: the identifier of that entry and, in
	 its top bit, the mark that says it covers the whole of this tile."

	^ VGTiledFillKernel frameRecordWords + VGTiledFillLayout tileRecordWords
]

{ #category : 'describing' }
VGTiledFillStagedBlock >> rows [
	"One row a slot I hold: the storage it is in, its slot, the record it belongs to, the name of
	 the word and the invocation of the workgroup that writes it."

	^ self wordRows , self floatRows
]

{ #category : 'describing' }
VGTiledFillStagedBlock >> rowsOfRuns: aCollection [
	"One row a word of every run of that collection: the storage it is in, its slot, the record
	 it belongs to, the name of the word and the invocation of the workgroup that writes it. The
	 writer is the position of the word in its own run, because a run is loaded cooperatively and
	 the invocations take one word each by their own number."

	| rows |
	rows := OrderedCollection new.
	aCollection do: [ :run |
		run fourth withIndexDo: [ :name :position |
			rows add: {
					run first.
					(run second + position - 1).
					run third.
					name.
					(position - 1) } ] ].
	^ rows asArray
]

{ #category : 'runs' }
VGTiledFillStagedBlock >> runInFloats: aSlot [
	"The run of the float block that slot belongs to."

	^ self floatRuns detect: [ :each |
		  aSlot >= each second and: [ aSlot < (each second + each fourth size) ] ]
]

{ #category : 'runs' }
VGTiledFillStagedBlock >> runInWords: aSlot [
	"The run of the word block that slot belongs to."

	^ self wordRuns detect: [ :each |
		  aSlot >= each second and: [ aSlot < (each second + each fourth size) ] ]
]

{ #category : 'runs' }
VGTiledFillStagedBlock >> runs [
	"Every run I hold, the words before the floats."

	^ self wordRuns , self floatRuns
]

{ #category : 'initialization' }
VGTiledFillStagedBlock >> setTileExtent: anExtent [
	tileExtent := anExtent
]

{ #category : 'runs' }
VGTiledFillStagedBlock >> shapeBlockRun [
	"The run of the offset of the block of shape records this tile reads for the entry standing:
	 one word, out of a buffer of its own, which is why it is a run beside the reference and not
	 a second word of it."

	^ {
		  #word.
		  self shapeOffsetSlot.
		  'reference'.
		  { 'shape block of the reference' } }
]

{ #category : 'describing' }
VGTiledFillStagedBlock >> shapeFieldNames [
	"The name of every word of the run of shape records: the words of one record, as the layout
	 names them, once for every record of my capacity, each carrying the shape it belongs to.
	 One run covers them all, so the shape is in the name of the word and not in the name of the
	 record."

	| names stride |
	names := OrderedCollection new.
	stride := self fieldNamesOfStride: #shapeRecordWords.
	1 to: self class shapeCapacity do: [ :shape |
		stride do: [ :each |
			names add: 'shape ' , shape printString , ', ' , each ] ].
	^ names asArray
]

{ #category : 'slots' }
VGTiledFillStagedBlock >> shapeOffsetSlot [
	"The slot of the block of shape records this tile reads for the entry standing, which the
	 encoding writes beside the reference word under the same index."

	^ self referenceSlot + 1
]

{ #category : 'runs' }
VGTiledFillStagedBlock >> shapeRun [
	"The run of the shape records of the entry standing, every record of my capacity in one run,
	 because the records of a block lie next to each other in the shape buffer and a run of
	 sixty-four words is loaded as cheaply as a run of four. The run is short where the entry
	 carries fewer shapes than my capacity: the kernel passes the length it works out from the
	 header and the words past it are left as they were."

	^ {
		  #word.
		  self shapeSlotBase.
		  'shape records'.
		  self shapeFieldNames }
]

{ #category : 'slots' }
VGTiledFillStagedBlock >> shapeSlotBase [
	"The first slot of the run of shape records, which follows the header of the entry."

	^ (self headerSlotOfField: VGTiledFillLayout entryHeaderWords) + 1
]

{ #category : 'slots' }
VGTiledFillStagedBlock >> shapeSlotOfOrdinal: anOrdinal field: anInteger [
	"The slot of one field of one shape record of the entry standing, the shapes counted from
	 nought as the kernel's shape loop counts them. Only the first shapeCapacity of them are
	 here; the kernel reads the rest from global memory and computes this slot from the loop
	 counter rather than asking me, because an ordinal of the walk is an id and not an integer."

	^ self shapeSlotBase + (anOrdinal * VGTiledFillLayout shapeRecordWords)
	  + anInteger - 1
]

{ #category : 'accessing' }
VGTiledFillStagedBlock >> tileExtent [
	^ tileExtent
]

{ #category : 'runs' }
VGTiledFillStagedBlock >> tileRun [
	"The run of the record of this workgroup's own tile, staged once before the first entry and
	 read until the workgroup ends."

	^ {
		  #word.
		  (self tileSlotOfField: 1).
		  'tile record'.
		  (self fieldNamesOfStride: #tileRecordWords) }
]

{ #category : 'slots' }
VGTiledFillStagedBlock >> tileSlotOfField: anInteger [
	"The slot of one field of the record of this workgroup's own tile, which no entry of the
	 walk overwrites: it is staged once, before the first entry, and read until the workgroup
	 ends."

	^ VGTiledFillKernel frameRecordWords + anInteger - 1
]

{ #category : 'slots' }
VGTiledFillStagedBlock >> wordCount [
	"The slots of the word block: the frame record, the tile record, the reference word, the
	 shape block offset, the header of the entry standing and its shape records up to my
	 capacity."

	^ self shapeSlotBase
	  + (self class shapeCapacity * VGTiledFillLayout shapeRecordWords)
]

{ #category : 'describing' }
VGTiledFillStagedBlock >> wordRows [
	"Every word slot, in slot order, named by the record it belongs to. The slots come from the
	 runs and the names from the layout, so a word the runs do not cover shows as a slot with no
	 row rather than be named wrongly."

	^ self rowsOfRuns: self wordRuns
]

{ #category : 'runs' }
VGTiledFillStagedBlock >> wordRuns [
	"Every run of the word block, in slot order. Together they name every slot of it exactly
	 once, which a test of mine asserts against the slot family."

	^ {
		  self frameRun.
		  self tileRun.
		  self entryReferenceRun.
		  self shapeBlockRun.
		  self headerRun.
		  self shapeRun }
]

{ #category : 'slots' }
VGTiledFillStagedBlock >> writerOfFloatSlot: aSlot [
	"The invocation of the workgroup that stages that slot of the float block, counted from the
	 first word of the run it belongs to."

	^ aSlot - (self runInFloats: aSlot) second
]

{ #category : 'slots' }
VGTiledFillStagedBlock >> writerOfWordSlot: aSlot [
	"The invocation of the workgroup that stages that slot of the word block: the position of
	 the word in the run of its own record. A run is loaded cooperatively — the invocations of
	 the workgroup take one word each of it, by their own number — so the first word of every run
	 is staged by invocation nought and no two words of one run share a writer.
	 Two slots of different runs do share a writer, and that writes no word twice: a run is a
	 place of its own, so an invocation writing one word of each writes two slots and not one
	 twice. What this asks of a run is only that it be no longer than the workgroup, which a
	 test of mine asserts, because an invocation stages one word of a run and not two."

	^ aSlot - (self runInWords: aSlot) second
]
