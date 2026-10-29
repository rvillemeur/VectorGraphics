"
I hold the facts about the SPIR-V module of the tiled fill rasteriser: what the kernel of
VGTiledFillKernel emits, what VGTiledFillPixelEmitter emits into that same module, and what
neither of them may name.

My tests read the module and the two classes, and draw nothing at all, so they run on a machine
with no driver. The tests that draw pixels, through the device or through the software backend,
live in VGTiledFillTest, which is why the two classes are separate: a fact about the emitted words
is checked by reading the words, and a fact about a frame is checked by comparing pixels.
"
Class {
	#name : 'VGTiledFillKernelTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Vulkan-Tests-Tests',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Tests'
}

{ #category : 'asserting' }
VGTiledFillKernelTest >> assertSlotsAndWritersOf: aStagedBlock [
	"The rows of that block name every slot of it exactly once, name every word, and give the
	 words of each run the writers nought upwards, which is the cooperative load the kernel
	 emits. No run is longer than the workgroup, because an invocation stages one word of a run
	 and not two."

	| rows |
	rows := aStagedBlock rows.
	self
		assert: (rows
				 select: [ :each | each first = #word ]
				 thenCollect: [ :each | each second ]) asSortedCollection asArray
		equals: (0 to: aStagedBlock wordCount - 1) asArray.
	self
		assert: (rows
				 select: [ :each | each first = #float ]
				 thenCollect: [ :each | each second ]) asSortedCollection asArray
		equals: (0 to: aStagedBlock floatCount - 1) asArray.
	self deny: (rows anySatisfy: [ :each | each fourth isEmpty ]).
	aStagedBlock runs do: [ :run |
		self assert: run fourth size <= aStagedBlock invocationCount.
		self
			assert: (self writersOfRun: run in: rows)
			equals: (0 to: run fourth size - 1) asArray ]
]

{ #category : 'private' }
VGTiledFillKernelTest >> classesNamedBy: aMethod [
	"Every class that method names, read from its literals, so a rule about what a method may
	 name is checked against the compiled method and not against its text."

	^ (aMethod literals
		   select: [ :each |
		   each isVariableBinding and: [ each value isBehavior ] ])
		  collect: [ :each | each value ]
]

{ #category : 'private' }
VGTiledFillKernelTest >> kernelDecorationLiterals: aDecoration [
	"Every literal that decoration carries in the kernel's module, read from the module's own
	 decoration instructions and not from the bytes."

	^ ((VGTiledFillKernel default module decorations select: [ :each |
		    (each first = #decorate and: [ each third = aDecoration ]) ]) collect: [
		   :each | each fourth ]) flattened
]

{ #category : 'private' }
VGTiledFillKernelTest >> kernelValidator [
	"The kernel of the default grid, read by the one tool that knows what a module may be."

	^ PVSpirvValidator on: VGTiledFillKernel default spirv
]

{ #category : 'tests' }
VGTiledFillKernelTest >> testADispatchAsksTheCacheForItsModuleAndBuildsNoneOfItsOwn [
	"Measured in unit 2.4a: building the module was one to four milliseconds of every frame, and
	 the frame carries nothing the module depends on. So the dispatch asks the cache, and a
	 module built there would be that cost back.
	 The whole class is read and not `draw:into:` alone, because unit 3.0 moved each step of a
	 frame into a method of its own and the fact is about the dispatch, not about one method."

	self assert: (VGTiledFillDispatch methods anySatisfy: [ :each |
			 each sendsSelector: #spirvOnTileExtent: ]).
	self deny: (VGTiledFillDispatch methods anySatisfy: [ :each |
			 each sendsSelector: #onTileExtent: ])
]

{ #category : 'tests' }
VGTiledFillKernelTest >> testAPixelEmitterSharesTheModuleOfTheKernelThatBuildsIt [
	"The emitter is a second vocabulary of one module: the builder it emits into and the value
	 table it reads are the kernel's own objects and not copies of them, because an identifier
	 the kernel remembers is an identifier the emitter uses and the two of them are emitting one
	 function."
	| kernel emitter |
	kernel := VGTiledFillKernel default.
	kernel spirv.
	emitter := VGTiledFillPixelEmitter on: kernel.
	self assert: emitter kernel identicalTo: kernel.
	self assert: emitter builder identicalTo: kernel builder.
	self assert: emitter values identicalTo: kernel values.
	self
		assert: (emitter valueNamed: #alphaByte)
		equals: (kernel valueNamed: #alphaByte)
]

{ #category : 'tests' }
VGTiledFillKernelTest >> testClearingTheSpirvCacheBuildsTheSameBytesAgain [
	"The cache is a saving and never a decision: the module built after it is cleared is the
	 module it held, byte for byte, so a test or a caller may clear it at any point."

	| first second |
	VGTiledFillKernel clearSpirvCache.
	first := VGTiledFillKernel spirvOnTileExtent: VGTileGrid defaultTileExtent.
	VGTiledFillKernel clearSpirvCache.
	self assert: VGTiledFillKernel cachedTileExtents isEmpty.
	second := VGTiledFillKernel spirvOnTileExtent: VGTileGrid defaultTileExtent.
	self deny: second identicalTo: first.
	self assert: second equals: first.
	self assert: VGTiledFillKernel cachedTileExtents size equals: 1
]

{ #category : 'tests' }
VGTiledFillKernelTest >> testEveryCompositionSelectorOfThePixelEmitterIsAMethodOfItsOwn [
	"The table names arithmetic by selector, so a selector in it that the emitter does not
	 implement is a frame that fails while its module is built. The table is held to the class
	 rather than to a list written twice."
	VGTiledFillPixelEmitter compositionSelectors keysAndValuesDo: [
		:name
		:selector |
		self
			assert: (VGTiledFillPixelEmitter includesSelector: selector)
			description: name ]
]

{ #category : 'tests' }
VGTiledFillKernelTest >> testEverySubRowOfATileIsSweptByOneInvocationOfItsWorkgroup [
	"The point of the unit: a sub-row of the tile is swept once and not once a column. The
	 invocations of the workgroup divide the sub-rows of the tile between them, so every
	 sub-row is swept by exactly one invocation of exactly one round, and the rounds a tile
	 needs follow from its own shape — a workgroup of a 16 by 16 tile has 256 invocations and
	 240 sub-rows and sweeps them in one round, where a workgroup of an 8 by 8 tile has 64
	 invocations and 120 sub-rows and needs two. The sweeps of the last round that fall past
	 the end are the ones the kernel's own guard drops."

	#( 16 8 ) do: [ :side |
		| block swept |
		block := VGTiledFillSpanBlock onTileExtent: side @ side.
		swept := OrderedCollection new.
		0 to: block invocationCount - 1 do: [ :invocation |
			0 to: block sweepsPerInvocation - 1 do: [ :round |
				swept add: (block subRowSweptBy: invocation inRound: round) ] ].
		self
			assert:
			(swept select: [ :each | each < block subRowCount ]) asSortedCollection
				asArray
			equals: (0 to: block subRowCount - 1) asArray.
		self
			assert: (swept reject: [ :each | each < block subRowCount ]) size
			equals:
			block invocationCount * block sweepsPerInvocation - block subRowCount ]
]

{ #category : 'tests' }
VGTiledFillKernelTest >> testTheBlocksOfAWorkgroupFitTheSharedMemoryEveryDeviceGuarantees [
	"Workgroup storage is declared when the module is built, so a block larger than the device
	 allows is a pipeline a driver refuses and not a frame drawn slowly. Vulkan guarantees
	 16 KB of it to every conformant device, which is the budget this engine builds for: the
	 staged records and the spans of every sub-row of a tile have to fit inside it together,
	 and the span capacity is what gives way if they do not."

	self
		assert:
		VGTiledFillStagedBlock default bytes + VGTiledFillSpanBlock default bytes
		<= VGTiledFillKernel sharedMemoryBudget
]

{ #category : 'tests' }
VGTiledFillKernelTest >> testTheKernelBindsOneBufferForEveryBufferItReads [
	"The seven buffers of the binding contract: the five VGTiledFillEncoding writes, the target
	 pixels and the size of the frame. They stand at one descriptor set, numbered from zero in
	 the order bindingNames holds them."

	self
		assert: (self kernelValidator variableIdsInStorageClass:
				 SpvStorageClass storageBuffer) size
		equals: VGTiledFillKernel bindingNames size.
	self
		assert:
		(self kernelDecorationLiterals: SpvDecoration bindingDecoration)
			asSortedCollection asArray
		equals: (0 to: VGTiledFillKernel bindingNames size - 1) asArray.
	self
		assert: (self kernelDecorationLiterals: SpvDecoration descriptorSet) asSet
		equals: { VGTiledFillKernel descriptorSetIndex } asSet
]

{ #category : 'tests' }
VGTiledFillKernelTest >> testTheKernelModuleIsValidSpirv [
	"The whole walk, assembled by hand: the block order, the merge instruction of every loop
	 and the function variables that stand where VGTileCoverage answers early. spirv-val reads
	 all of it, and a driver refuses what it refuses."

	| validator |
	PVSpirvValidator isAvailable ifFalse: [ ^ self skip ].
	validator := self kernelValidator.
	self
		assert: validator isValid
		description: 'the tiled fill kernel produced invalid SPIR-V: '
			, validator validationOutput
]

{ #category : 'tests' }
VGTiledFillKernelTest >> testTheKernelNamesEveryBufferAndBuiltInInItsInterface [
	"Under SPIR-V 1.5 an entry point names every module-scope variable it touches, so a buffer,
	 a built-in or a block of workgroup storage left out of the interface is a module a driver
	 may refuse. The count of the workgroup blocks is read off the module rather than written
	 here, so the interface is checked against what the kernel really declares."

	| validator |
	validator := self kernelValidator.
	self
		assert: validator entryPointInterfaceIds size
		equals: VGTiledFillKernel bindingNames size
			+ VGTiledFillKernel builtInNumbers size
			+ (validator variableCountInStorageClass: SpvStorageClass workgroup)
]

{ #category : 'tests' }
VGTiledFillKernelTest >> testTheKernelNamesNoOpcodeWhereItEmits [
	"Every instruction of the kernel comes out of the vocabulary it is written in, so nothing
	 that emits names an opcode at all: one written in the walk would be an instruction whose
	 type and arithmetic no other reader of that vocabulary could hold to. The inspecting
	 methods are left out, because they count opcodes in a module already built instead of
	 adding any."

	self assert: (VGTiledFillKernel inheritsFrom: VGSpirvVocabulary).
	VGTiledFillKernel methods , VGTiledFillKernel class methods do: [ :each |
		each protocolName = #inspecting ifFalse: [
			self
				deny: ((self classesNamedBy: each) includes: SpvOpcode)
				description: each printString , ' names an opcode' ] ]
]

{ #category : 'tests' }
VGTiledFillKernelTest >> testTheKernelReadsTheTileFromTheWorkgroupAndThePixelFromTheInvocation [
	"Two built-ins and no more: which tile this workgroup owns and which pixel of that tile
	 this invocation owns. Nothing reads the global invocation id, because a tile is addressed
	 by its record in the table and not by its place in the dispatch."

	self
		assert: self kernelValidator builtInsFromWords asSet
		equals: (VGTiledFillKernel builtInNumbers collect: [ :each |
				 PVSpirvValidator builtInNameFor: each ]) asSet
]

{ #category : 'tests' }
VGTiledFillKernelTest >> testTheKernelRefusesAnOperatorWithNoArithmeticOfItsOwn [
	"Every operator of the rasteriser's subset has its own mix of source, mask and destination
	 in the pixel emitter. One added to the subset without arithmetic there is refused while the
	 module is built, so no frame is drawn by a branch that composites nothing."
	VGTiledFillRasteriser supportedOperators do: [ :each |
		self assert:
			(VGTiledFillPixelEmitter compositionSelectorFor: each) isSymbol ].
	self
		should: [
		VGTiledFillPixelEmitter compositionSelectorFor: VGCairoOperator add ]
		raise: Error
]

{ #category : 'tests' }
VGTiledFillKernelTest >> testTheKernelStagesTheRecordsOfATileAndOfOneEntryInWorkgroupStorage [
	"Four blocks of workgroup storage. Two for the records the tile and the entry standing
	 need, one of words and one of floats, because a block holds one type; and two for the spans
	 the workgroup sweeps, the count of each sub-row in words and the bounds of its spans in
	 floats.

	 Six barriers. One once the frame record and the tile record are staged, before any
	 invocation reads a value out of them. Five about the entry standing, inside the loop over
	 the references: one at the top of the loop, so that no invocation overwrites a record or a
	 span a neighbour still reads; two between the three rounds of the staging, because a writer
	 of a later round needs a word an earlier round staged; one once the last round is written,
	 so that no invocation sweeps against a record not yet there; and one once the sweep of the
	 sub-rows is written, so that no invocation reads a span not yet swept.

	 Every one of them stands in control flow the whole workgroup runs — outside the test of
	 whether an invocation has a pixel of the frame at all, and inside a loop whose count comes
	 out of the tile record every invocation shares — because a barrier one invocation of a
	 workgroup reaches and another does not is undefined behaviour."

	| validator |
	validator := self kernelValidator.
	self
		assert: (validator variableCountInStorageClass: SpvStorageClass workgroup)
		equals: 4.
	self
		assert: (validator countOfOpcode: SpvOpcode opControlBarrier)
		equals: 6
]

{ #category : 'tests' }
VGTiledFillKernelTest >> testTheModuleCacheTabListsOneRowForEveryTileExtentItHolds [
	"The tab reads the cache itself, so it names what a session really holds and cannot drift
	 from it. A column block only runs when a row is drawn, so every cell is asked for here."

	| builder presenter titles |
	VGTiledFillKernel clearSpirvCache.
	VGTiledFillKernel spirvOnTileExtent: 8 @ 8.
	VGTiledFillKernel spirvOnTileExtent: 16 @ 16.
	builder := SpPresenterBuilder newApplication: SpApplication new.
	presenter := VGTiledFillKernel inspectorModuleCache: builder.
	self assert: presenter items size equals: VGTiledFillKernel cachedTileExtents size.
	titles := presenter columns collect: [ :each | each title ].
	self assert: (titles includes: 'Tile').
	presenter items do: [ :item |
		presenter columns do: [ :column | column evaluation value: item ] ].
	self assert: ((presenter items collect: [ :each | each ]) includes: 8 @ 8)
]

{ #category : 'tests' }
VGTiledFillKernelTest >> testTheSpanBlockGivesEverySubRowOfATileItsOwnCountAndItsOwnSpanSlots [
	"The spans a sub-row of the tile was found to cover are written into workgroup storage by
	 the one invocation that swept it and read by the sixteen invocations of its pixel row, so
	 every sub-row needs a count slot of its own and a run of bound slots of its own: two slots
	 a span, its left and its right. Two sub-rows sharing a slot would be one row of pixels
	 reading another row's coverage, which no byte of a frame could be traced back to."

	| block counts bounds |
	block := VGTiledFillSpanBlock default.
	counts := (0 to: block subRowCount - 1) collect: [ :each |
		          block countSlotOfSubRow: each ].
	bounds := OrderedCollection new.
	0 to: block subRowCount - 1 do: [ :subRow |
		0 to: VGTiledFillSpanBlock spanCapacity - 1 do: [ :span |
			bounds add: (block startSlotOfSubRow: subRow span: span).
			bounds add: (block endSlotOfSubRow: subRow span: span) ] ].
	self
		assert: counts asSortedCollection asArray
		equals: (0 to: block wordCount - 1) asArray.
	self
		assert: bounds asSortedCollection asArray
		equals: (0 to: block floatCount - 1) asArray
]

{ #category : 'tests' }
VGTiledFillKernelTest >> testTheSpirvCacheHoldsOneModuleForEveryTileExtentAskedFor [
	"A kernel built for one tile size cannot dispatch a grid of another, because the tile extent
	 is the shape of the workgroup, so the cache is keyed by the extent and the bytes of two
	 extents differ."

	| small large |
	VGTiledFillKernel clearSpirvCache.
	small := VGTiledFillKernel spirvOnTileExtent: 4 @ 4.
	large := VGTiledFillKernel spirvOnTileExtent: 16 @ 16.
	self
		assert: VGTiledFillKernel cachedTileExtents asSet
		equals: {
				(4 @ 4).
				(16 @ 16) } asSet.
	self deny: small equals: large.
	self assert: large equals: (VGTiledFillKernel onTileExtent: 16 @ 16) spirv
]

{ #category : 'tests' }
VGTiledFillKernelTest >> testTheSpirvOfATileExtentIsAnsweredFromTheCacheTheSecondTime [
	"Building the module costs one to four milliseconds of every frame and depends on the tile
	 extent alone, so the bytes are built once a session and answered again. The same bytes here
	 means the same object: a second serialisation would be the cost the cache is for."

	| first second |
	VGTiledFillKernel clearSpirvCache.
	first := VGTiledFillKernel spirvOnTileExtent: 8 @ 8.
	second := VGTiledFillKernel spirvOnTileExtent: 8 @ 8.
	self assert: second identicalTo: first.
	self assert: first equals: (VGTiledFillKernel onTileExtent: 8 @ 8) spirv
]

{ #category : 'tests' }
VGTiledFillKernelTest >> testTheStagedBlockGivesEverySlotOneWriterAndNamesThemAll [
	"A run of the block is loaded cooperatively: the invocations of the workgroup take one word
	 each of it, by their own number, so the writer of a slot is its position in its own run. No
	 two words of one run share a writer, which is what keeps a word from being written twice,
	 and a run is no longer than the workgroup, which is what lets one step stage it with no
	 loop. The narrowest tile the kernel builds for is the measure of that, because the longest
	 run is the sixty-four words of the shape records.
	 Two slots of different runs do share a writer, and that writes no word twice: a run is a
	 place of its own, so an invocation writing one word of each writes two slots.
	 The rows are what the inspector reads, so they must name every slot and nothing else."

	| wide |
	wide := VGTiledFillStagedBlock onTileExtent: 16 @ 16.
	self assertSlotsAndWritersOf: wide.
	self
		assertSlotsAndWritersOf: (VGTiledFillStagedBlock onTileExtent: 8 @ 8).
	self assert: (wide writerOfWordSlot: wide shapeSlotBase) equals: 0.
	self assert: (wide writerOfFloatSlot: 0) equals: 0
]

{ #category : 'tests' }
VGTiledFillKernelTest >> testTheStagedBlockGivesEveryWordOfTheRecordsItHoldsOneSlotOfItsOwn [
	"The block is addressed by slot and a slot holds one word, so the slots of the records it
	 stages have to fill it exactly and may not overlap: the frame record, the tile record, the
	 reference word, the offset of the shape block, the header of the entry and as many shape
	 records as its capacity on the word side, and the clip, the mask rectangle and the paint
	 block on the float side. Two words of one record in one slot would be a record read wrong
	 by every invocation of the workgroup, which no byte of a frame could be traced back to."

	| block words floats |
	block := VGTiledFillStagedBlock default.
	words := ((1 to: VGTiledFillKernel frameRecordWords) collect: [ :each |
		          block frameSlotOfField: each ])
	         , ((1 to: VGTiledFillLayout tileRecordWords) collect: [ :each |
			          block tileSlotOfField: each ])
	         , {
			         block referenceSlot.
			         block shapeOffsetSlot }
	         , ((1 to: VGTiledFillLayout entryHeaderWords) collect: [ :each |
			          block headerSlotOfField: each ]).
	0 to: VGTiledFillStagedBlock shapeCapacity - 1 do: [ :ordinal |
		words := words
		         , ((1 to: VGTiledFillLayout shapeRecordWords) collect: [ :each |
				          block shapeSlotOfOrdinal: ordinal field: each ]) ].
	floats := ((1 to: VGTiledFillLayout clipFloats) collect: [ :each |
		           block clipSlotOfField: each ])
	          , ((1 to: VGTiledFillLayout clipFloats) collect: [ :each |
			           block maskRectSlotOfField: each ])
	          , ((1 to: VGTiledFillLayout paintBlockFloats) collect: [ :each |
			           block paintSlotOfField: each ]).
	self
		assert: words asSortedCollection asArray
		equals: (0 to: block wordCount - 1) asArray.
	self
		assert: floats asSortedCollection asArray
		equals: (0 to: block floatCount - 1) asArray
]

{ #category : 'tests' }
VGTiledFillKernelTest >> testTheVocabularyNamesNothingOfThisRasteriser [
	"The vocabulary is the SPIR-V a hand-built module is written in and nothing of this
	 rasteriser: a layout, a constant or a format named there would be a fact kept in two
	 places, and the kernel is where the facts of the tiled fill belong."

	VGSpirvVocabulary methods , VGSpirvVocabulary class methods do: [ :each |
		(self classesNamedBy: each) do: [ :class |
			self
				deny: (class name beginsWith: 'VG')
				description: each printString , ' names ' , class name ] ]
]

{ #category : 'asserting' }
VGTiledFillKernelTest >> writersOfRun: aRun in: aCollection [
	"The invocation that writes each word of that run, in slot order, read off the rows of the
	 block. A row carries the storage it is in as well as its slot, because a word slot and a
	 float slot of one number are two places."

	^ (aCollection
		   select: [ :each |
			   each first = aRun first and: [
				   each second >= aRun second and: [
					   each second < (aRun second + aRun fourth size) ] ] ]
		   thenCollect: [ :each | each fifth ]) asSortedCollection asArray
]
