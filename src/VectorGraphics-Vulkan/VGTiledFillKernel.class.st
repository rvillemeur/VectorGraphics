"
I am the tiled fill rasteriser of VGTiledFillRasteriser, hand built as one SPIR-V compute module: one workgroup owns one tile of the frame and one invocation owns one pixel of that tile.
I read the seven buffers of my own binding contract — the five VGTiledFillEncoding writes, the pixels of the target and the size of the frame — and I write one word of the target per invocation.
Nothing is shared and nothing is synchronised: a pixel belongs to one invocation alone, so the tiles may be dispatched in any order and no atomic or barrier appears in the module.
My walk is VGTileCoverage translated instruction by instruction, with a flag variable where that class answers early, and my composition is the arithmetic of VGCairoSurfaceFormat and of the three operators of VGTiledFillRasteriser class >> supportedOperators.
Send module for what I build and spirv for its bytes; a parity gate against the software backend is what holds me to the Pharo I translate, because the device computes in single floats where VGTileCoverage computes in double ones.
"
Class {
	#name : 'VGTiledFillKernel',
	#superclass : 'VGSpirvKernel',
	#instVars : [
		'tileExtent',
		'stagedBlock',
		'stagedWords',
		'stagedFloats',
		'spanBlock',
		'spanCounts',
		'spanBounds'
	],
	#classInstVars : [
		'spirvByTileExtent'
	],
	#category : 'VectorGraphics-Vulkan-Tiles',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Tiles'
}

{ #category : 'constants' }
VGTiledFillKernel class >> bindingNames [
	"The fourteen buffers I read, in the order they are bound: the twelve an encoding writes,
	 the pixels of the target and the size of the frame. A binding number is the position of the
	 name here, counted from zero, so this one list states the whole contract."

	^ #( #tileTable #entryRefs #refShapes #headers #clips #edges #shapes #paints
	     #stops #maskRects #maskBytes #sourcePixels #target #frame )
]

{ #category : 'constants' }
VGTiledFillKernel class >> builtInNumbers [
	"The two built-ins I read: which tile this workgroup owns and which pixel of that tile this
	 invocation owns. Nothing reads the global invocation id, because a tile is addressed by its
	 record in the table and not by its place in the dispatch."

	^ {
		  SpvBuiltIn workgroupId.
		  SpvBuiltIn localInvocationId }
]

{ #category : 'module cache' }
VGTiledFillKernel class >> cachedTileExtents [
	"The tile sizes a module has been built for in this session."

	^ self spirvCache keys
]

{ #category : 'module cache' }
VGTiledFillKernel class >> clearSpirvCache [
	"Forget every module built so far. The cache is a saving and never a decision, so what is
	 built next is byte for byte what was forgotten."

	spirvByTileExtent := nil
]

{ #category : 'instance creation' }
VGTiledFillKernel class >> default [
	"The kernel of the tile size VGTileGrid measured, which is the one every frame of this
	 engine is binned over."

	^ self onTileExtent: VGTileGrid defaultTileExtent
]

{ #category : 'constants' }
VGTiledFillKernel class >> floatBindingNames [
	"The five buffers of single floats. A clip side, a mask side, an edge end, a coefficient of a
	 paint and the offset and channels of a stop are all floating point; everything else a frame
	 carries is a word, the alpha bytes of a mask among them, because a storage buffer holds
	 words and four of those bytes ride in each."

	^ #( #clips #maskRects #edges #paints #stops )
]

{ #category : 'constants' }
VGTiledFillKernel class >> floatVariableNames [
	^ #( #coverage #nearest #nearestAll #cursor #start )
]

{ #category : 'constants' }
VGTiledFillKernel class >> frameHeightField [
	^ 2
]

{ #category : 'constants' }
VGTiledFillKernel class >> frameRecordWords [
	"The words the frame buffer takes: the width and the height of the target in pixels."

	^ 2
]

{ #category : 'constants' }
VGTiledFillKernel class >> frameWidthField [
	"The width of the target, which is also the stride of its pixels, because they are packed
	 row by row with nothing between the rows."

	^ 1
]

{ #category : 'constants' }
VGTiledFillKernel class >> halfUnit [
	"Half of one, which the walk needs twice over: the centre of a sub-row inside its row, and
	 the half Pharo's rounded adds before it takes the floor of what it is given."

	^ 1 / 2
]

{ #category : 'inspector' }
VGTiledFillKernel class >> inspectorModuleCache: aBuilder [
	<inspectorPresentationOrder: 2 title: 'Module cache'>
	^ aBuilder newTable
		  addColumn: (SpStringTableColumn title: 'Tile' evaluated: [ :each |
					   each printString ]);
		  addColumn: (SpStringTableColumn title: 'Bytes' evaluated: [ :each |
					   (self spirvCache at: each) size printString ]);
		  addColumn: (SpStringTableColumn title: 'Words' evaluated: [ :each |
					   ((self spirvCache at: each) size // 4) printString ]);
		  items: (self cachedTileExtents asSortedCollection: [ :a :b | a x <= b x ])
				  asArray;
		  yourself
]

{ #category : 'inspector' }
VGTiledFillKernel class >> inspectorModuleCacheContext: aContext [
	"Nothing to show on a session that has dispatched no frame, and the tab asks the cache
	 rather than building a module, so inspecting the class opens no device and costs nothing."

	aContext active: self spirvCache isNotEmpty
]

{ #category : 'constants' }
VGTiledFillKernel class >> maskScale [
	"The coverage is scaled by this before it is rounded to a mask byte, which is what
	 VGCairoSurfaceFormat >> maskByteForCoverage: measured against a live Cairo context."

	^ VGTiledFillEncoding fullAlphaByte + 1
]

{ #category : 'instance creation' }
VGTiledFillKernel class >> onTileExtent: anExtent [
	"The kernel of a grid of that tile size: the tile extent is the shape of the workgroup, so a
	 kernel built for one tile size cannot dispatch a grid of another."

	^ self new setTileExtent: anExtent
]

{ #category : 'contract' }
VGTiledFillKernel class >> rgbaChannelShifts [
	"Where each channel of an unpremultiplied quadruple sits in a pixel word of the one format a
	 frame is encoded for. The format lists its shifts lowest first, which is blue, green, red
	 and then alpha, and a quadruple runs red, green, blue, alpha, so the three colours are the
	 format''s own list read backwards and the alpha is the last of it."

	| shifts |
	shifts := VGTiledFillEncoding targetFormat channelShifts.
	^ shifts allButLast reversed , { shifts last }
]

{ #category : 'constants' }
VGTiledFillKernel class >> roundingAddend [
	"Half of the full byte, added before the division by that byte: the rounding division of
	 VGCairoSurfaceFormat >> scaleByte:by:, which is Cairo's own integer blend."

	^ VGTiledFillEncoding fullAlphaByte // 2
]

{ #category : 'constants' }
VGTiledFillKernel class >> sharedMemoryBudget [
	"The workgroup storage a module of this kernel may declare, in bytes. Vulkan guarantees
	 16 KB of it to every conformant device — maxComputeSharedMemorySize is at least that —
	 and a block larger than the device allows is a pipeline a driver refuses rather than a
	 frame drawn slowly, so this engine builds for the guarantee and not for the device in
	 the machine. The staged records and the spans of every sub-row of a tile fit inside it
	 together."

	^ 16 * 1024
]

{ #category : 'constants' }
VGTiledFillKernel class >> signedVariableNames [
	"The winding number of one scan of the edges of one shape, which runs negative under the
	 winding rule."

	^ #( #scanWinding )
]

{ #category : 'module cache' }
VGTiledFillKernel class >> spirvCache [
	"Tile extent to bytes, built on first use. The key is the extent because the extent is the
	 shape of the workgroup, so one entry cannot serve another tile size."

	^ spirvByTileExtent ifNil: [ spirvByTileExtent := Dictionary new ]
]

{ #category : 'module cache' }
VGTiledFillKernel class >> spirvOnTileExtent: anExtent [
	"The bytes of the kernel of that tile size, built once a session. Unit 2.4a measured the
	 build at one to four milliseconds of every frame, and the module depends on the tile extent
	 and on nothing a frame carries, so a frame that built one would pay that twice."

	^ self spirvCache
		  at: anExtent
		  ifAbsentPut: [ (self onTileExtent: anExtent) spirv ]
]

{ #category : 'constants' }
VGTiledFillKernel class >> subRowCount [
	"The sub-rows one pixel row is sampled on, which is VGRasteriser's own grid: the kernel
	 sums the same number of terms in the same order as the software rasteriser, so only the
	 width of the float differs between them."

	^ VGRasteriser samplesPerPixelRow
]

{ #category : 'constants' }
VGTiledFillKernel class >> tileComponent [
	"The component of the workgroup id that carries the row of the tile table this workgroup
	 owns. The dispatch is one dimensional, so the other two are zero."

	^ 0
]

{ #category : 'constants' }
VGTiledFillKernel class >> wordVariableNames [
	"The function variables that hold a word: the destination pixel, the source pixel of the
	 fill and whether the fill lays one down at all, the pixel a surface paint samples, the byte
	 the mask of the fill carries here, the three loop counters, the record of the shape the walk
	 stands in and the verdicts of a sweep over the shapes, the stop loop with the two stops it
	 looks for and the flags that stand where VGTileCoverage answers early, and the five the
	 cooperative sweep of the sub-rows needs: the round of the sweep, the spans the sub-row it
	 sweeps has found, whether it found more than the block holds, the count a pixel reads back
	 and the span of that count it stands on."

	^ #( #dest #source #hasSource #sampledPixel #maskByte #reference #sample #edge
	     #shape #shapeEdgeOffset #shapeEdgeCount #shapeFillRule #shapeAliased
	     #hasAntialiased #allows #insideAll #inside #nextInside #nearestFound
	     #stop #beforeStop #afterStop #beforeFound #afterFound #sweepRound
	     #spanIndex #spanOverflow #spanCount #span )
]

{ #category : 'building' }
VGTiledFillKernel >> declareSharedStorage [
	"Four blocks of workgroup storage, two laid out by VGTiledFillStagedBlock and two by
	 VGTiledFillSpanBlock: the words of the records this workgroup's tile and the entry standing
	 need and their floats, then the count of the spans of every sub-row of the tile and the
	 bounds of those spans. One block a type, because an array holds one type."

	stagedBlock := VGTiledFillStagedBlock onTileExtent: tileExtent.
	stagedWords := self
		               newSharedArrayOfType: self wordType
		               length: stagedBlock wordCount.
	stagedFloats := self
		                newSharedArrayOfType: self floatType
		                length: stagedBlock floatCount.
	spanBlock := VGTiledFillSpanBlock onTileExtent: tileExtent.
	spanCounts := self
		              newSharedArrayOfType: self wordType
		              length: spanBlock wordCount.
	spanBounds := self
		              newSharedArrayOfType: self floatType
		              length: spanBlock floatCount
]

{ #category : 'emitting' }
VGTiledFillKernel >> emitAddPieceFrom: aLeftId to: aRightId [
	"That piece of the window added to the coverage, where the sweep stands inside the shapes.
	 The verdict is read here and not at the call site, because SPIR-V has no answer out of a
	 branch and both ends of the piece are in hand only here."

	builder
		emitIf: (self word: (self load: #inside) equals: (self constantWord: 1))
		then: [
			self
				store: (self
						 sumOfFloat: (self load: #coverage)
						 and: (self differenceOfFloat: aRightId and: aLeftId))
				into: #coverage ]
]

{ #category : 'emitting' }
VGTiledFillKernel >> emitAliasedShapesAllowPixelOnSubRow: aSubRowId [
	"Whether every aliased shape of the entry calls the centre of this pixel inside, sampled at
	 the centre of its own pixel row: VGShapeWalk >> isPixelCentreInsideAtX:onSubRow: asked of
	 each of them, which is how an aliased shape answers whole pixels and answers the same ones
	 on every sub-row of a row. The verdict rides in a variable while the loop runs and is
	 answered as a condition, because that is what a branch of SPIR-V takes."

	| centre row |
	centre := self
		          sumOfFloat: (self valueNamed: #pixelLeft)
		          and: (self constantFloat: self class halfUnit).
	row := self
		       sumOfFloat: (self floorOfFloat: aSubRowId)
		       and: (self constantFloat: self class halfUnit).
	self store: (self constantWord: 1) into: #allows.
	self emitShapesDo: [
		builder emitIf: (self negation: self emitIsAntialiasedShape) then: [
			builder
				emitIf: (self negation:
							 (self emitIsInside: (self emitWindingUpTo: centre onSubRow: row)))
				then: [ self store: (self constantWord: 0) into: #allows ] ] ].
	^ self word: (self load: #allows) equals: (self constantWord: 1)
]

{ #category : 'emitting' }
VGTiledFillKernel >> emitAllowsRowAt: aRowId [
	"The rows the walk visits at all: whole pixel rows, from the floor of the clip's top to the
	 ceiling of its bottom, which is VGTileCoverage >> allowsRowAt:. A pixel asks it of its own
	 row and the sweep of a sub-row asks it of the row that sub-row samples, which is the same
	 test of the same clip."

	^ self
		  both: (self
				   float: aRowId
				   atLeast: (self floorOfFloat: (self valueNamed: #clipTop)))
		  and: (self
				   float: aRowId
				   below: (self ceilingOfFloat: (self valueNamed: #clipBottom)))
]

{ #category : 'emitting - staging' }
VGTiledFillKernel >> emitBarrier [
	"Every invocation of the workgroup waits here and every write to workgroup storage before it
	 is visible to every invocation after it. A barrier one invocation reaches and another does
	 not is undefined behaviour, so every barrier I emit stands in control flow the whole
	 workgroup runs: outside the test of whether this invocation has a pixel of the frame at all,
	 and inside a loop whose count comes from the tile record every invocation shares."

	builder currentBlock addInstruction: builder workgroupBarrier
]

{ #category : 'emitting - staging' }
VGTiledFillKernel >> emitBody [
	"Which tile this workgroup owns and which pixel of it this invocation owns. The records of
	 the tile are staged in workgroup storage before anything else, because every value below is
	 read out of them: the invocations of the workgroup divide the words of the frame record and
	 the tile record between them, the barrier makes those writes visible to all of them, and
	 each invocation then reads what it needs out of shared memory. A header, a corner and a
	 count say the same thing to the pixel at one corner of a tile as to the pixel at the other,
	 which is why one read a workgroup serves them all.

	 The corner of the tile and the row of this invocation inside it are remembered beside the
	 pixel they make, because the cooperative sweep of a sub-row needs the corner to know where
	 the sub-row starts and a pixel needs its row to know which sub-rows of the tile are its
	 own."

	self
		remember:
		(self componentOfBuiltIn: SpvBuiltIn localInvocationId at: self class rowComponent)
		as: #localRow.
	self remember: self emitLocalIndex as: #localIndex.
	self emitStageOfTile.
	self emitBarrier.
	self
		remember:
		(self stagedWordAt:
			 (stagedBlock frameSlotOfField: self class frameWidthField))
		as: #frameWidth.
	self
		remember:
		(self stagedWordAt:
			 (stagedBlock frameSlotOfField: self class frameHeightField))
		as: #frameHeight.
	self
		remember: (self stagedWordAt:
				 (stagedBlock tileSlotOfField: VGTiledFillLayout tileLeftField))
		as: #tileLeft.
	self
		remember: (self stagedWordAt:
				 (stagedBlock tileSlotOfField: VGTiledFillLayout tileTopField))
		as: #tileTop.
	self
		remember: (self
				 sumOfWord: (self valueNamed: #tileLeft)
				 and: (self
						  componentOfBuiltIn: SpvBuiltIn localInvocationId
						  at: self class columnComponent))
		as: #pixelX.
	self
		remember: (self
				 sumOfWord: (self valueNamed: #tileTop)
				 and: (self valueNamed: #localRow))
		as: #pixelY.
	self
		remember: (self stagedWordAt: (stagedBlock tileSlotOfField:
					 VGTiledFillLayout referenceOffsetField))
		as: #referenceOffset.
	self
		remember: (self stagedWordAt: (stagedBlock tileSlotOfField:
					 VGTiledFillLayout referenceCountField))
		as: #referenceCount.
	self emitPixel
]

{ #category : 'emitting' }
VGTiledFillKernel >> emitCoverageGivenInterior: aBooleanId [
	"The coverage of this pixel for this entry: one where the reference says the entry covers the
	 whole of the tile, and the spans of the sub-rows of its row where it does not. Which shapes
	 are antialiased was read before the sweep, because the whole workgroup turns on it."

	self store: (self constantFloat: 0) into: #coverage.
	builder emitIf: aBooleanId then: [
		self store: (self constantFloat: 1) into: #coverage ].
	builder emitIf: (self negation: aBooleanId) then: [
		builder
			emitIf: (self emitAllowsRowAt: (self valueNamed: #pixelRow))
			then: [ self emitCoverageOfSubRows ] ]
]

{ #category : 'emitting' }
VGTiledFillKernel >> emitCoverageOfSubRowOfTile: aSubRowId onSubRow: aYId allowed: aConditionId [
	"The parts of this pixel the entry covers inside its clip on that sub-row, trimmed to the
	 clip and to the pixel, which is VGTileCoverage >> spansAtX:onSubRow:do: and the two edges
	 it trims to. The aliased shapes gate the pixel and then leave the window alone; where no
	 shape is antialiased the whole window is covered.

	 Where a shape is antialiased the spans of that sub-row of the tile are read back out of
	 workgroup storage and each is clipped to this pixel's window: a maximal run of the points
	 every antialiased shape calls inside is a function of x alone, so the runs inside a window
	 are the runs of the tile cut to that window, and a bound inside it is the same float the
	 sweep computed while a bound outside it is the edge of the window itself. A sub-row that
	 found more spans than its block holds carries the mark of an overflow instead of a count,
	 and is swept here from this pixel's own window as the kernel swept every sub-row before
	 this unit."

	| left right swept overflowed |
	left := self
		        largerFloatOf: (self valueNamed: #pixelLeft)
		        and: (self valueNamed: #clipLeft).
	right := self
		         smallerFloatOf: (self
				          sumOfFloat: (self valueNamed: #pixelLeft)
				          and: (self constantFloat: 1))
		         and: (self valueNamed: #clipRight).
	builder emitIf: (self float: right above: left) then: [
		builder emitIf: aConditionId then: [
			swept := self
				         word: (self load: #hasAntialiased)
				         equals: (self constantWord: 1).
			builder emitIf: (self negation: swept) then: [
				self
					store: (self
							 sumOfFloat: (self load: #coverage)
							 and: (self differenceOfFloat: right and: left))
					into: #coverage ].
			builder emitIf: swept then: [
				self
					store: (self spanCountOfSubRowOfTile: aSubRowId)
					into: #spanCount.
				overflowed := self
					              word: (self load: #spanCount)
					              equals:
					              (self constantWord: VGTiledFillSpanBlock overflowMark).
				builder
					emitIf: overflowed
					then: [ self emitSweepFrom: left to: right onSubRow: aYId ].
				builder emitIf: (self negation: overflowed) then: [
					self
						emitSumOfSpansOfSubRowOfTile: aSubRowId
						from: left
						to: right ] ] ] ]
]

{ #category : 'emitting' }
VGTiledFillKernel >> emitCoverageOfSubRows [
	"The part of this pixel the fill covers, summed over the sub-rows of its row and capped at
	 one, which is VGTileCoverage >> atX:row:. The terms arrive in the order they arrive there,
	 so the sum is the same arithmetic in a narrower float.

	 Whether the aliased shapes of the entry let this pixel through is asked once for the whole
	 row and not once a sub-row: an aliased shape is sampled at the centre of its own pixel row,
	 so it answers the same for the fifteen sub-rows of a row.

	 The sub-rows of the tile were swept by the invocations of the workgroup between them, so
	 each of the fifteen is a short list of spans here; a sub-row that found more spans than its
	 block holds is swept again, by this invocation for its own column."

	| allows |
	allows := self emitAliasedShapesAllowPixelOnSubRow:
		          (self valueNamed: #pixelRow).
	self store: (self constantWord: 0) into: #sample.
	builder
		emitWhile: [
			self
				word: (self load: #sample)
				below: (self constantWord: self class subRowCount) ]
		do: [
			self
				emitCoverageOfSubRowOfTile: (self
						 sumOfWord: (self
								  productOfWord: (self valueNamed: #localRow)
								  and: (self constantWord: self class subRowCount))
						 and: (self load: #sample))
				onSubRow: (self
						 sumOfFloat: (self valueNamed: #pixelRow)
						 and: (self
								  quotientOfFloat: (self
										   sumOfFloat: (self floatOfWord: (self load: #sample))
										   and: (self constantFloat: self class halfUnit))
								  by: (self constantFloat: self class subRowCount)))
				allowed: allows.
			self
				store: (self sumOfWord: (self load: #sample) and: (self constantWord: 1))
				into: #sample ].
	self
		store: (self
				 smallerFloatOf: (self
						  quotientOfFloat: (self load: #coverage)
						  by: (self constantFloat: self class subRowCount))
				 and: (self constantFloat: 1))
		into: #coverage
]

{ #category : 'emitting' }
VGTiledFillKernel >> emitCrossingAfter: aCursorId onSubRow: aSubRowId [
	"The nearest crossing of the shape in hand strictly right of that cursor, and whether its
	 edges have one at all, left in nearestFound. One scan of the edges, which is what a run
	 costs here instead of a sorted array of every crossing:
	 VGShapeWalk >> crossingAfter:onSubRow:."

	self store: (self constantFloat: 0) into: #nearest.
	self store: (self constantWord: 0) into: #nearestFound.
	self store: (self constantWord: 0) into: #edge.
	builder
		emitWhile: [
		self word: (self load: #edge) below: (self load: #shapeEdgeCount) ]
		do: [
			| crossing better |
			crossing := self
				            emitCrossingOfEdgeAt: (self load: #edge)
				            onSubRow: aSubRowId.
			better := self
				          both: (self
						           both: crossing second
						           and: (self float: crossing first above: aCursorId))
				          and: (self
						           either: (self
								            word: (self load: #nearestFound)
								            equals: (self constantWord: 0))
						           or: (self float: crossing first below: (self load: #nearest))).
			builder emitIf: better then: [
				self store: crossing first into: #nearest.
				self store: (self constantWord: 1) into: #nearestFound ].
			self
				store: (self sumOfWord: (self load: #edge) and: (self constantWord: 1))
				into: #edge ].
	^ self load: #nearest
]

{ #category : 'emitting' }
VGTiledFillKernel >> emitCrossingOfEdgeAt: anEdgeId onSubRow: aSubRowId [
	"Where the edge at that position of the shape in hand crosses that sub-row, and whether it
	 reaches it at all: VGShapeWalk >> crossingOfEdgeAt:onSubRow: term for term, with the two
	 answers of nil carried as a flag beside the value. The edge is taken half open from its
	 upper end. A horizontal edge divides by the difference of its own two ends, so the divisor
	 is one where the edge does not reach the sub-row at all, which keeps an infinity out of a
	 value the walk then discards."

	| base x0 y0 x1 y1 reaches divisor |
	base := self
		        productOfWord: (self
				         sumOfWord: (self load: #shapeEdgeOffset)
				         and: anEdgeId)
		        and: (self constantWord: VGTiledFillLayout edgeFloats).
	x0 := self
		      elementOf: #edges
		      atBase: base
		      field: VGTiledFillLayout edgeStartXField.
	y0 := self
		      elementOf: #edges
		      atBase: base
		      field: VGTiledFillLayout edgeStartYField.
	x1 := self
		      elementOf: #edges
		      atBase: base
		      field: VGTiledFillLayout edgeEndXField.
	y1 := self
		      elementOf: #edges
		      atBase: base
		      field: VGTiledFillLayout edgeEndYField.
	reaches := self
		           both: (self negation: (self float: y0 equals: y1))
		           and: (self
				            both:
				            (self float: aSubRowId atLeast: (self smallerFloatOf: y0 and: y1))
				            and:
				            (self float: aSubRowId below: (self largerFloatOf: y0 and: y1))).
	divisor := self
		           select: reaches
		           ifTrue: (self differenceOfFloat: y1 and: y0)
		           ifFalse: (self constantFloat: 1)
		           type: self floatType.
	^ {
		  (self
			   sumOfFloat: x0
			   and: (self
					    quotientOfFloat: (self
							     productOfFloat: (self differenceOfFloat: x1 and: x0)
							     and: (self differenceOfFloat: aSubRowId and: y0))
					    by: divisor)).
		  reaches }
]

{ #category : 'emitting' }
VGTiledFillKernel >> emitDirectionOfEdgeAt: anEdgeId [
	"Down the page is one and up the page is minus one, as VGSpanScanner counts it."

	| base y0 y1 |
	base := self
		        productOfWord: (self
				         sumOfWord: (self load: #shapeEdgeOffset)
				         and: anEdgeId)
		        and: (self constantWord: VGTiledFillLayout edgeFloats).
	y0 := self
		      elementOf: #edges
		      atBase: base
		      field: VGTiledFillLayout edgeStartYField.
	y1 := self
		      elementOf: #edges
		      atBase: base
		      field: VGTiledFillLayout edgeEndYField.
	^ self
		  select: (self float: y1 above: y0)
		  ifTrue: (self constantSigned: 1)
		  ifFalse: (self constantSigned: -1)
		  type: self signedType
]

{ #category : 'emitting - entry' }
VGTiledFillKernel >> emitEntryGivenInterior: aBooleanId [
	"One fill of this tile at this pixel: the pixel its paint lays down here, the coverage of
	 the walk over it and the composition of the two into the destination. Whether the entry
	 covers the whole of this tile is answered before this, because the sweep of the sub-rows
	 the whole workgroup runs turns on the same answer.

	 Every record of the entry has already been staged in workgroup storage by the invocations
	 of this workgroup between them and read back out of it by every one of them, so the header,
	 the clip, the mask rectangle, the paint block and the shape records of the block this tile
	 is to read are all in hand here: the records of the row of tiles this tile lies in, each
	 naming only the edges of its shape that reach the rows of that row. An edge whose own rows
	 miss this tile cannot cross a sub-row of it, so the short run and the whole shape give the
	 same coverage.

	 A pixel the paint lays nothing down at is left alone, which the subset may do because every
	 operator in it is bounded, and which is what the software rasteriser does with the nil a
	 paint answers.

	 The mask scales the coverage after the alpha of the fill does, which is the order
	 VGTiledFillRasteriser scales them in and the order the software backend scales a blit in;
	 an entry that carries no mask answers full alpha and scaling by that leaves a byte as it
	 was, so one path serves a fill and a blit alike.

	 The paint and the composition are emitted by VGTiledFillPixelEmitter, which shares this
	 module while I emit this entry; the walk over the edges between them is my own."

	| mask pixels |
	pixels := VGTiledFillPixelEmitter on: self.
	pixels emitSource.
	self emitCoverageGivenInterior: aBooleanId.
	mask := pixels emitMaskForCoverage: (self load: #coverage).
	mask := pixels emitScaleOfByte: mask by: self emitMaskByte.
	builder
		emitIf: (self
				 both: (self word: (self constantWord: 0) below: mask)
				 and: (self word: (self constantWord: 0) below: (self load: #hasSource)))
		then: [ pixels emitCompositeWithMask: mask ]
]

{ #category : 'emitting - staging' }
VGTiledFillKernel >> emitFloatRun: aRun from: aBindingName base: aBaseId [
	"One cooperative load of a run of floats, as emitWordRun:from:base: loads a run of words.
	 Every float run of the block is as long as the names it carries, because a clip, a mask
	 rectangle and a paint block are of one size whatever the entry is."

	| index |
	index := self valueNamed: #localIndex.
	builder
		emitIf:
		(self word: index below: (self constantWord: aRun fourth size))
		then: [
			builder
				emitStore:
				(self elementOf: aBindingName at: (self sumOfWord: aBaseId and: index))
				at: (self
						 sharedPointerTo: stagedFloats
						 ofType: self floatType
						 atId: (self
								  sumOfWord: (self constantWord: aRun second)
								  and: index)) ]
]

{ #category : 'emitting' }
VGTiledFillKernel >> emitHasAntialiasedShape [
	"Whether any shape of the entry is antialiased, read once for the whole pixel. Where none
	 is, every shape answers whole pixels and the window of a sub-row is covered in full or not
	 at all, which is the empty swept set of VGTileCoverage >> spansAtX:onSubRow:do:."

	self store: (self constantWord: 0) into: #hasAntialiased.
	self emitShapesDo: [
		builder
			emitIf: self emitIsAntialiasedShape
			then: [ self store: (self constantWord: 1) into: #hasAntialiased ] ]
]

{ #category : 'emitting' }
VGTiledFillKernel >> emitIsAntialiasedShape [
	"Whether the shape in hand is antialiased, which is the one a sweep runs over. An aliased
	 shape answers whole pixels instead, so it gates the pixel and leaves the window alone."

	^ self
		  word: (self load: #shapeAliased)
		  equals:
		  (self constantWord: (VGTiledFillEncoding flagForAliased: false))
]

{ #category : 'emitting' }
VGTiledFillKernel >> emitIsInside: aWindingId [
	"Whether that winding number stands inside the shape in hand, under the fill rule its own
	 record names: VGSpanScanner >> isInside:. An odd number is the lowest bit set, which holds
	 for a negative winding as well, because a signed word is stored in two''s complement."

	| evenOdd odd nonZero |
	evenOdd := self
		           word: (self load: #shapeFillRule)
		           equals:
		           (self constantWord:
			            (VGTiledFillEncoding codeForFillRule: #evenOdd)).
	odd := self
		       integer:
		       (self bitsOfSigned: aWindingId and: (self constantSigned: 1))
		       equals: (self constantSigned: 1).
	nonZero := self
		           integer: aWindingId
		           differsFrom: (self constantSigned: 0).
	^ self
		  select: evenOdd
		  ifTrue: odd
		  ifFalse: nonZero
		  type: self boolType
]

{ #category : 'emitting' }
VGTiledFillKernel >> emitIsInsideAllAt: anXId onSubRow: aSubRowId [
	"Whether every antialiased shape of the entry calls that point inside, which is
	 VGTileCoverage >> isInsideAt:onSubRow:. That is the geometric intersection Cairo performs:
	 spans meet spans and no coverage is multiplied by another."

	self store: (self constantWord: 1) into: #insideAll.
	self emitShapesDo: [
		builder emitIf: self emitIsAntialiasedShape then: [
			builder
				emitIf: (self negation:
							 (self emitIsInside:
									  (self emitWindingUpTo: anXId onSubRow: aSubRowId)))
				then: [ self store: (self constantWord: 0) into: #insideAll ] ] ].
	^ self load: #insideAll
]

{ #category : 'emission - entry' }
VGTiledFillKernel >> emitIsInteriorReference: aReferenceId [
	"Whether that reference carries the mark of a tile the entry covers in full, which is
	 VGTiledFillEncoding class >> isInteriorReference: read in the kernel."

	^ self
		  word:
		  (self
			   bitsOfWord: aReferenceId
			   and:
			   (self constantWord: VGTiledFillLayout interiorReferenceFlag))
		  equals:
		  (self constantWord: VGTiledFillLayout interiorReferenceFlag)
]

{ #category : 'emitting - staging' }
VGTiledFillKernel >> emitLocalIndex [
	"Which invocation of its workgroup this is, as one number: the row of the tile times the
	 width of the tile plus the column. A slot of workgroup storage is written by the invocation
	 whose number is that slot's own, so an invocation needs one number to compare."

	^ self
		  sumOfWord:
		  (self
			   productOfWord: (self valueNamed: #localRow)
			   and: (self constantWord: tileExtent x))
		  and: (self
				   componentOfBuiltIn: SpvBuiltIn localInvocationId
				   at: self class columnComponent)
]

{ #category : 'emitting' }
VGTiledFillKernel >> emitMaskByte [
	"The alpha the mask of this entry carries at this pixel, which the coverage is scaled by. It
	 is full alpha where the entry carries no mask at all: the rectangle written for such an
	 entry is empty, so every pixel falls outside it, and VGMaskedFillEntry answers full alpha
	 outside its own rectangle for the same reason. The bytes lie four to a word, row by row from
	 the top left of the rectangle, so the one wanted is found by a division and a shift the
	 invocation computes rather than the module. The load sits inside the test and not in a
	 select, because a select evaluates both of its arms and outside the rectangle the index is
	 not one the buffer holds."

	| inside column row width position index shift |
	self
		store: (self constantWord: VGTiledFillEncoding fullAlphaByte)
		into: #maskByte.
	inside := self
		          both: (self
				           both: (self
						            float: (self valueNamed: #pixelLeft)
						            atLeast: (self valueNamed: #maskLeft))
				           and: (self
						            float: (self valueNamed: #pixelLeft)
						            below: (self valueNamed: #maskRight)))
		          and: (self
				           both: (self
						            float: (self valueNamed: #pixelRow)
						            atLeast: (self valueNamed: #maskTop))
				           and: (self
						            float: (self valueNamed: #pixelRow)
						            below: (self valueNamed: #maskBottom))).
	builder emitIf: inside then: [
		column := self wordOfFloat: (self
				          differenceOfFloat: (self valueNamed: #pixelLeft)
				          and: (self valueNamed: #maskLeft)).
		row := self wordOfFloat: (self
				       differenceOfFloat: (self valueNamed: #pixelRow)
				       and: (self valueNamed: #maskTop)).
		width := self wordOfFloat: (self
				         differenceOfFloat: (self valueNamed: #maskRight)
				         and: (self valueNamed: #maskLeft)).
		position := self
			            sumOfWord: (self valueNamed: #maskOffset)
			            and: (self
					             sumOfWord: (self productOfWord: row and: width)
					             and: column).
		index := self
			         word: position
			         dividedBy:
			         (self constantWord: VGTiledFillLayout maskBytesPerWord).
		shift := self
			         productOfWord: (self
					          differenceOfWord: position
					          and: (self
							           productOfWord: index
							           and: (self constantWord:
									            VGTiledFillLayout maskBytesPerWord)))
			         and: (self constantWord: VGTiledFillLayout maskByteBits).
		self
			store: (self
					 bitsOfWord: (self
							  word: (self elementOf: #maskBytes at: index)
							  shiftedRightByWord: shift)
					 and: (self constantWord: VGTiledFillEncoding fullAlphaByte))
			into: #maskByte ].
	^ self load: #maskByte
]

{ #category : 'emitting' }
VGTiledFillKernel >> emitNearestCrossingAfter: aCursorId to: aRightId onSubRow: aSubRowId [
	"The nearest crossing of any antialiased shape strictly right of that cursor, or the right
	 bound where none of them crosses inside the window, which is
	 VGTileCoverage >> nextCrossingAfter:to:onSubRow:."

	self store: aRightId into: #nearestAll.
	self emitShapesDo: [
		builder emitIf: self emitIsAntialiasedShape then: [
			| crossing |
			crossing := self emitCrossingAfter: aCursorId onSubRow: aSubRowId.
			builder
				emitIf: (self
						 both: (self
								  word: (self load: #nearestFound)
								  equals: (self constantWord: 1))
						 and: (self float: crossing below: (self load: #nearestAll)))
				then: [ self store: crossing into: #nearestAll ] ] ].
	^ self load: #nearestAll
]

{ #category : 'emitting - entry' }
VGTiledFillKernel >> emitPixel [
	"The pixel of this invocation: the destination word read once, every entry of the tile
	 composited into it in the order the references hold them, and the word written back. One
	 invocation owns this pixel alone, so nothing else can have written it in between, which is
	 what lets the read stand outside the loop.

	 The loop over the references is run by every invocation of the workgroup and not only by
	 those with a pixel of the frame to draw, because the records of each entry are staged in
	 workgroup storage inside it and the sub-rows of the tile are swept there between the
	 invocations of the workgroup, and a barrier one invocation reaches and another does not is
	 undefined behaviour. A tile of the last column or the last row is short, so the invocations
	 past its edge have no pixel of their own: what that test guards is the reading of the
	 destination, the drawing of the entry and the writing back, and not the loop, not the
	 staging and not the sweep. The count the loop turns on comes out of the tile record, which
	 the whole workgroup shares, so every invocation turns it the same number of times.

	 Three of the five barriers an entry stands between are mine — one at the top of the loop, so
	 that no invocation overwrites a record or a span a neighbour still reads, one once the
	 staging is written, so that the sweep reads the records of the entry standing, and one once
	 the sweep is written, so that each pixel reads the spans of its own sub-rows and not the
	 spans of the entry before — and the two others are the staging's own, between its rounds."

	| inside index |
	inside := self
		          both: (self
				           word: (self valueNamed: #pixelX)
				           below: (self valueNamed: #frameWidth))
		          and: (self
				           word: (self valueNamed: #pixelY)
				           below: (self valueNamed: #frameHeight)).
	index := self
		         sumOfWord: (self
				          productOfWord: (self valueNamed: #pixelY)
				          and: (self valueNamed: #frameWidth))
		         and: (self valueNamed: #pixelX).
	self
		remember: (self floatOfWord: (self valueNamed: #pixelX))
		as: #pixelLeft.
	self
		remember: (self floatOfWord: (self valueNamed: #pixelY))
		as: #pixelRow.
	builder emitIf: inside then: [
		self store: (self elementOf: #target at: index) into: #dest ].
	self store: (self constantWord: 0) into: #reference.
	builder
		emitWhile: [
		self word: (self load: #reference) below: (self valueNamed: #referenceCount) ]
		do: [
			| interior |
			self emitBarrier.
			self emitStageOfEntryAt: (self
					 sumOfWord: (self valueNamed: #referenceOffset)
					 and: (self load: #reference)).
			self emitBarrier.
			interior := self emitRecordsAndSweepOfEntry.
			self emitBarrier.
			builder emitIf: inside then: [
				self emitEntryGivenInterior: interior ].
			self
				store:
					(self sumOfWord: (self load: #reference) and: (self constantWord: 1))
				into: #reference ].
	builder emitIf: inside then: [
		self storeWord: (self load: #dest) into: #target at: index ]
]

{ #category : 'emitting - sweep' }
VGTiledFillKernel >> emitRecordSpanFrom: aLeftId to: aRightId forSubRowOfTile: aSubRowId [
	"One run of the sweep written into the block of spans of its sub-row, where the sweep stands
	 inside the shapes. The verdict is read here and not at the call site, as
	 emitAddPieceFrom:to: reads it, because SPIR-V has no answer out of a branch.

	 A sub-row of more runs than the block holds is marked as overflowed and the runs past the
	 capacity are dropped: no pixel reads a span of such a sub-row, because the mark sends every
	 one of them back to sweeping its own window."

	builder
		emitIf: (self word: (self load: #inside) equals: (self constantWord: 1))
		then: [
			| room slot |
			room := self
				        word: (self load: #spanIndex)
				        below:
				        (self constantWord: VGTiledFillSpanBlock spanCapacity).
			builder emitIf: room then: [
				slot := self
					        spanBoundSlotOfSubRowOfTile: aSubRowId
					        span: (self load: #spanIndex).
				self storeSpanBound: aLeftId atSlot: slot.
				self
					storeSpanBound: aRightId
					atSlot: (self sumOfWord: slot and: (self constantWord: 1)).
				self
					store:
						(self sumOfWord: (self load: #spanIndex) and: (self constantWord: 1))
					into: #spanIndex ].
			builder emitIf: (self negation: room) then: [
				self store: (self constantWord: 1) into: #spanOverflow ] ]
]

{ #category : 'emitting - entry' }
VGTiledFillKernel >> emitRecordsAndSweepOfEntry [
	"The records of the entry standing read back out of workgroup storage by every invocation
	 of the workgroup, and the sub-rows of the tile swept between them. Answers whether the
	 reference says the entry covers the whole of this tile, which both the sweep and the
	 coverage of a pixel turn on.

	 Every invocation reads the records and not only a drawing one, because an invocation with
	 no pixel of the frame may still own a sub-row of the tile to sweep, and the sweep reads the
	 clip and the shape records as a pixel does.

	 Whether the entry covers the whole tile and whether any shape of it is antialiased are the
	 same answer for the whole workgroup, so the sweep stands in control flow every invocation
	 runs alike: an interior entry has no sweep to do, an entry of aliased shapes alone covers
	 whole pixels and needs none, and anything else has its sub-rows divided between the
	 invocations and swept once each."

	| interior |
	self rememberStagedHeader.
	self rememberStagedClip.
	self rememberStagedMaskRect.
	interior := self emitIsInteriorReference:
		            (self stagedWordAt: stagedBlock referenceSlot).
	self emitHasAntialiasedShape.
	builder
		emitIf: (self
				 both: (self negation: interior)
				 and: (self
						  word: (self load: #hasAntialiased)
						  equals: (self constantWord: 1)))
		then: [ self emitSweepOfTileSubRows ].
	^ interior
]

{ #category : 'emitting - entry' }
VGTiledFillKernel >> emitShapesDo: aBlock [
	"That block once for every shape of the entry, the fill first and the shapes of its clip
	 after it, with the record of the shape in hand. No shape loop of mine runs inside another,
	 so one counter serves them all. The counter is the position of the shape in the block of
	 this tile and not an index into the shape buffer, because that is what says whether the
	 record was staged in workgroup storage."

	self store: (self constantWord: 0) into: #shape.
	builder
		emitWhile: [
		self word: (self load: #shape) below: (self valueNamed: #shapeCount) ]
		do: [
			self rememberShapeAtOrdinal: (self load: #shape).
			aBlock value.
			self
				store: (self sumOfWord: (self load: #shape) and: (self constantWord: 1))
				into: #shape ]
]

{ #category : 'emitting - staging' }
VGTiledFillKernel >> emitStageOfEntryAt: anIndexId [
	"The records of one entry of this tile into workgroup storage, in three rounds with a barrier
	 between neighbours, because a writer of a later round needs a word an earlier round staged:
	 the words of the reference, then the header and the two rectangles the identifier it carries
	 locates, then the paint block and the shape records the header locates.
	 Every word of those records is read out of global memory once a workgroup, by the one
	 invocation that writes its slot, where before this unit every invocation read every one of
	 them for itself."

	self emitStageOfReferenceAt: anIndexId.
	self emitBarrier.
	self emitStageOfHeaderClipAndMask.
	self emitBarrier.
	self emitStageOfPaintAndShapes
]

{ #category : 'emitting - staging' }
VGTiledFillKernel >> emitStageOfHeaderClipAndMask [
	"The whole header of the entry the staged reference names, its clip and the rectangle of its
	 mask, one run each. All three are found from the identifier the reference carries, which is
	 why they are staged in the round after it.
	 A mask rectangle is laid out as a clip rectangle, so one base serves the two buffers."

	| previous clipBase |
	previous := self
		            differenceOfWord: (self
				             bitsOfWord: (self stagedWordAt: stagedBlock referenceSlot)
				             and: (self constantWord:
							              VGTiledFillLayout referenceIdentifierMask))
		            and: (self constantWord: 1).
	clipBase := self
		            productOfWord: previous
		            and: (self constantWord: VGTiledFillLayout clipFloats).
	self
		emitWordRun: stagedBlock headerRun
		from: #headers
		base: (self
				 productOfWord: previous
				 and: (self constantWord: VGTiledFillLayout entryHeaderWords)).
	self emitFloatRun: stagedBlock clipRun from: #clips base: clipBase.
	self
		emitFloatRun: stagedBlock maskRectRun
		from: #maskRects
		base: clipBase
]

{ #category : 'emitting - staging' }
VGTiledFillKernel >> emitStageOfPaintAndShapes [
	"The paint block of the entry standing and as many of the shape records of its block as the
	 staged block has room for, one run each. Both are found from words of the header, so they
	 are staged in the round after it: the paint block from the offset the header carries, and
	 the shape records from the block the reference names and the count of shapes the header
	 carries.
	 The records of a block lie next to each other in the shape buffer, so every shape record of
	 the entry is one run; the run is as long as the entry has shapes, up to the capacity of the
	 block. A shape record past that capacity is left unstaged and read out of global memory by
	 every invocation that walks it, which is what the kernel did with every record before this
	 unit."

	| shapeWords |
	self
		emitFloatRun: stagedBlock paintRun
		from: #paints
		base: (self
				 productOfWord: (self stagedWordAt:
						  (stagedBlock headerSlotOfField:
							   VGTiledFillLayout paintBlockOffsetField))
				 and: (self constantWord: VGTiledFillLayout paintBlockFloats)).
	shapeWords := self
		               productOfWord: (self
				                smallerWordOf: (self stagedWordAt:
						                 (stagedBlock headerSlotOfField:
							                  VGTiledFillLayout shapeCountField))
				                and: (self constantWord:
						                 VGTiledFillStagedBlock shapeCapacity))
		               and:
		               (self constantWord: VGTiledFillLayout shapeRecordWords).
	self
		emitWordRun: stagedBlock shapeRun
		from: #shapes
		base: (self
				 productOfWord: (self stagedWordAt: stagedBlock shapeOffsetSlot)
				 and: (self constantWord: VGTiledFillLayout shapeRecordWords))
		lengthId: shapeWords
]

{ #category : 'emitting - staging' }
VGTiledFillKernel >> emitStageOfReferenceAt: anIndexId [
	"The two words the reference at that index carries: the entry it names, with the mark of an
	 interior reference in its top bit, and the block of shape records this tile is to read for
	 that entry. They come out of two buffers, so they are two runs of one word and not one run
	 of two."

	self
		emitWordRun: stagedBlock entryReferenceRun
		from: #entryRefs
		base: anIndexId.
	self
		emitWordRun: stagedBlock shapeBlockRun
		from: #refShapes
		base: anIndexId
]

{ #category : 'emitting - staging' }
VGTiledFillKernel >> emitStageOfTile [
	"The frame record and the tile record into workgroup storage, one run each. Both say the same
	 thing to every pixel of the tile and neither changes while the workgroup runs, so they are
	 staged once before the loop over the references and never written again."

	self
		emitWordRun: stagedBlock frameRun
		from: #frame
		base: (self constantWord: 0).
	self
		emitWordRun: stagedBlock tileRun
		from: #tileTable
		base: (self
				 productOfWord: (self
						  componentOfBuiltIn: SpvBuiltIn workgroupId
						  at: self class tileComponent)
				 and: (self constantWord: VGTiledFillLayout tileRecordWords))
]

{ #category : 'emitting - sweep' }
VGTiledFillKernel >> emitSumOfSpansOfSubRowOfTile: aSubRowId from: aLeftId to: aRightId [
	"The spans that sub-row of the tile found, each cut to this pixel's window and added to the
	 coverage left to right. The spans were written left to right by the sweep, so the terms
	 arrive in the order VGTileCoverage adds them, and a span that misses the window adds
	 nothing rather than a zero."

	self store: (self constantWord: 0) into: #span.
	builder
		emitWhile: [
		self word: (self load: #span) below: (self load: #spanCount) ]
		do: [
			| slot low high |
			slot := self
				        spanBoundSlotOfSubRowOfTile: aSubRowId
				        span: (self load: #span).
			low := self
				       largerFloatOf: (self spanBoundAtSlot: slot)
				       and: aLeftId.
			high := self
				        smallerFloatOf: (self spanBoundAtSlot:
						         (self sumOfWord: slot and: (self constantWord: 1)))
				        and: aRightId.
			builder emitIf: (self float: high above: low) then: [
				self
					store: (self
							 sumOfFloat: (self load: #coverage)
							 and: (self differenceOfFloat: high and: low))
					into: #coverage ].
			self
				store: (self sumOfWord: (self load: #span) and: (self constantWord: 1))
				into: #span ]
]

{ #category : 'emitting' }
VGTiledFillKernel >> emitSweepFrom: aLeftId to: aRightId onSubRow: aSubRowId [
	"The sweep of that window added to the coverage of this pixel, which is what a sub-row whose
	 spans overflowed its block falls back to."

	self
		emitSweepFrom: aLeftId
		to: aRightId
		onSubRow: aSubRowId
		piece: [ :start :end | self emitAddPieceFrom: start to: end ]
]

{ #category : 'emitting' }
VGTiledFillKernel >> emitSweepFrom: aLeftId to: aRightId onSubRow: aSubRowId piece: aBlock [
	"The parts of that window every antialiased shape calls inside, found left to right and
	 handed to that block one by one: VGTileCoverage >> sweepFrom:to:onSubRow:do:. A piece runs
	 from where the last shape lets it in to where the first one shuts it out, so a crossing
	 that leaves the verdict alone does not cut a piece in two and the sums are the same floats
	 the software rasteriser adds. Nothing is sorted and no crossing is kept: the verdict at a
	 point is one scan of the edges of each shape and the next crossing right of it is one more.

	 The block is sent the two ends of the piece and reads the verdict for itself: a pixel adds
	 the piece to its coverage and the cooperative sweep writes it into the spans of its
	 sub-row, and both of them are the same walk over the same crossings."

	self store: aLeftId into: #cursor.
	self store: aLeftId into: #start.
	self
		store: (self emitIsInsideAllAt: aLeftId onSubRow: aSubRowId)
		into: #inside.
	builder
		emitWhile: [ self float: (self load: #cursor) below: aRightId ]
		do: [
			| next ends |
			next := self
				        emitNearestCrossingAfter: (self load: #cursor)
				        to: aRightId
				        onSubRow: aSubRowId.
			ends := self float: next atLeast: aRightId.
			builder emitIf: ends then: [
				aBlock value: (self load: #start) value: aRightId.
				self store: aRightId into: #cursor ].
			builder emitIf: (self negation: ends) then: [
				self
					store: (self emitIsInsideAllAt: next onSubRow: aSubRowId)
					into: #nextInside.
				builder emitIf: (self negation: (self
							  word: (self load: #nextInside)
							  equals: (self load: #inside))) then: [
					aBlock value: (self load: #start) value: next.
					builder
						emitIf: (self word: (self load: #inside) equals: (self constantWord: 0))
						then: [ self store: next into: #start ].
					self store: (self load: #nextInside) into: #inside ].
				self store: next into: #cursor ] ]
]

{ #category : 'emitting - sweep' }
VGTiledFillKernel >> emitSweepOfSubRowOfTile: aSubRowId [
	"One sub-row of the tile swept once, left to right, over the whole width of the tile cut to
	 the clip of the entry: the crossings of every edge of every antialiased shape of it, with
	 the verdict read at the start and at each crossing, and the maximal runs it finds written
	 into workgroup storage where the pixels of that sub-row read them.

	 The sub-row names its own row of the tile and its own sample of that row, so the sampling
	 line is the float the pixel of that row computes for the same sample, and the window is the
	 window of that row of pixels taken whole. A row outside the rows the clip allows and a
	 window the clip leaves empty find no span at all, which is what the pixels of such a row
	 add.

	 The count is written last and says how many spans the pixels are to read, or carries the
	 mark of an overflow where the sub-row found more than the block holds."

	| rowOfTile row sample left right |
	rowOfTile := self
		             word: aSubRowId
		             dividedBy: (self constantWord: self class subRowCount).
	sample := self
		          differenceOfWord: aSubRowId
		          and: (self
				           productOfWord: rowOfTile
				           and: (self constantWord: self class subRowCount)).
	row := self floatOfWord:
		       (self sumOfWord: (self valueNamed: #tileTop) and: rowOfTile).
	left := self
		        largerFloatOf: (self floatOfWord: (self valueNamed: #tileLeft))
		        and: (self valueNamed: #clipLeft).
	right := self
		         smallerFloatOf: (self floatOfWord: (self
					           sumOfWord: (self valueNamed: #tileLeft)
					           and: (self constantWord: tileExtent x)))
		         and: (self valueNamed: #clipRight).
	self store: (self constantWord: 0) into: #spanIndex.
	self store: (self constantWord: 0) into: #spanOverflow.
	builder
		emitIf: (self
				 both: (self emitAllowsRowAt: row)
				 and: (self float: right above: left))
		then: [
			self
				emitSweepFrom: left
				to: right
				onSubRow: (self
						 sumOfFloat: row
						 and: (self
								  quotientOfFloat: (self
										   sumOfFloat: (self floatOfWord: sample)
										   and: (self constantFloat: self class halfUnit))
								  by: (self constantFloat: self class subRowCount)))
				piece: [ :start :end |
					self
						emitRecordSpanFrom: start
						to: end
						forSubRowOfTile: aSubRowId ] ].
	self
		storeSpanCount: (self
				 select: (self
						  word: (self load: #spanOverflow)
						  equals: (self constantWord: 1))
				 ifTrue:
				 (self constantWord: VGTiledFillSpanBlock overflowMark)
				 ifFalse: (self load: #spanIndex)
				 type: self wordType)
		ofSubRowOfTile: aSubRowId
]

{ #category : 'emitting - sweep' }
VGTiledFillKernel >> emitSweepOfTileSubRows [
	"The sub-rows of this tile swept between the invocations of the workgroup, one sweep a
	 sub-row, for the entry standing. A tile of sixteen rows sampled fifteen times a row is two
	 hundred and forty sub-rows and a workgroup of a tile is two hundred and fifty-six
	 invocations, so one round gives every sub-row a sweeper of its own and the invocations past
	 the last sub-row sweep nothing; a smaller tile turns the round more than once, as
	 VGTiledFillSpanBlock >> sweepsPerInvocation says.

	 This runs in control flow the whole workgroup shares — the entry is interior or it is not,
	 and a shape of it is antialiased or none is, for every invocation alike — and it holds no
	 barrier of its own, so an invocation with no sub-row to sweep may leave it at once."

	self store: (self constantWord: 0) into: #sweepRound.
	builder
		emitWhile: [
			self
				word: (self load: #sweepRound)
				below: (self constantWord: spanBlock sweepsPerInvocation) ]
		do: [
			| subRow |
			subRow := self
				          sumOfWord: (self
						           productOfWord: (self load: #sweepRound)
						           and: (self constantWord: spanBlock invocationCount))
				          and: (self valueNamed: #localIndex).
			builder
				emitIf: (self
						 word: subRow
						 below: (self constantWord: spanBlock subRowCount))
				then: [ self emitSweepOfSubRowOfTile: subRow ].
			self
				store:
					(self sumOfWord: (self load: #sweepRound) and: (self constantWord: 1))
				into: #sweepRound ]
]

{ #category : 'emitting' }
VGTiledFillKernel >> emitWindingOnSubRow: aSubRowId accepting: aBlock [
	"What the crossings that block accepts contribute to the winding of the shape in hand, which
	 is VGShapeWalk >> windingOnSubRow:crossing: inlined at each of its call sites: the even-odd
	 rule counts a crossing and the winding rule counts the direction the edge runs in."

	| evenOdd |
	evenOdd := self
		           word: (self load: #shapeFillRule)
		           equals:
		           (self constantWord:
			            (VGTiledFillEncoding codeForFillRule: #evenOdd)).
	self store: (self constantSigned: 0) into: #scanWinding.
	self store: (self constantWord: 0) into: #edge.
	builder
		emitWhile: [
		self word: (self load: #edge) below: (self load: #shapeEdgeCount) ]
		do: [
			| crossing step |
			crossing := self
				            emitCrossingOfEdgeAt: (self load: #edge)
				            onSubRow: aSubRowId.
			step := self
				        select: evenOdd
				        ifTrue: (self constantSigned: 1)
				        ifFalse: (self emitDirectionOfEdgeAt: (self load: #edge))
				        type: self signedType.
			builder
				emitIf:
					(self both: crossing second and: (aBlock value: crossing first))
				then: [
					self
						store: (self sumOfSigned: (self load: #scanWinding) and: step)
						into: #scanWinding ].
			self
				store: (self sumOfWord: (self load: #edge) and: (self constantWord: 1))
				into: #edge ].
	^ self load: #scanWinding
]

{ #category : 'emitting' }
VGTiledFillKernel >> emitWindingUpTo: anX onSubRow: aSubRowId [
	"The winding number just right of that coordinate, in one scan of the edges. A crossing
	 exactly there counts: a run that starts there is inside from there, and a run that ends
	 there has ended."

	^ self
		  emitWindingOnSubRow: aSubRowId
		  accepting: [ :crossing | self float: crossing notAbove: anX ]
]

{ #category : 'emitting - staging' }
VGTiledFillKernel >> emitWordRun: aRun from: aBindingName base: aBaseId [
	"As emitWordRun:from:base:lengthId:, for a run every word of which the entry standing has:
	 the run names its words, so it is as long as the names it carries."

	self
		emitWordRun: aRun
		from: aBindingName
		base: aBaseId
		lengthId: (self constantWord: aRun fourth size)
]

{ #category : 'emitting - staging' }
VGTiledFillKernel >> emitWordRun: aRun from: aBindingName base: aBaseId lengthId: aLengthId [
	"One cooperative load of a run of words: the invocations of the workgroup take one word each
	 of the run, by their own number, so the first n invocations stage a run of n words in one
	 step. A run is never longer than the workgroup — a test of the staged block asserts it — so
	 no invocation takes a second word of one and the step needs no loop.
	 The words of a record lie next to each other both in the buffer and in the block, so one
	 index serves the read and the write and the run says where it starts in the block. The
	 length is a value and not a constant where the run may be short: a run of shape records is
	 as long as the entry has shapes, and a word past that is left as it was because no
	 invocation reads it."

	| index |
	index := self valueNamed: #localIndex.
	builder emitIf: (self word: index below: aLengthId) then: [
		builder
			emitStore:
			(self elementOf: aBindingName at: (self sumOfWord: aBaseId and: index))
			at: (self
					 sharedPointerTo: stagedWords
					 ofType: self wordType
					 atId: (self
							  sumOfWord: (self constantWord: aRun second)
							  and: index)) ]
]

{ #category : 'building' }
VGTiledFillKernel >> freshKernel [
	^ self class onTileExtent: tileExtent
]

{ #category : 'testing' }
VGTiledFillKernel >> isReadyToBuild [
	"My shape is given after I am created, so a view of my module waits for it."

	^ tileExtent isNotNil
]

{ #category : 'accessing' }
VGTiledFillKernel >> localSize [
	"One invocation per pixel of a tile, which is what lets an invocation find its pixel by
	 adding its own local id to the corner its tile record carries."

	^ {
		  tileExtent x.
		  tileExtent y.
		  self class layerCount }
]

{ #category : 'building' }
VGTiledFillKernel >> newSharedArrayOfType: aType length: anInteger [
	"One fixed-size array in the Workgroup storage class, which is the memory the invocations of
	 a workgroup share. The length operand is the id of a constant, which the array type declares
	 as it is created."

	^ builder
		  addGlobalVariable: (builder types
				   pointerType: SpvStorageClass workgroup
				   type: (builder types arrayType: aType length: anInteger))
		  storageClass: SpvStorageClass workgroup
]

{ #category : 'printing' }
VGTiledFillKernel >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPut: $(;
		print: tileExtent x;
		nextPut: $x;
		print: tileExtent y;
		nextPutAll: ' tile)'
]

{ #category : 'emitting - entry' }
VGTiledFillKernel >> rememberShapeAtOrdinal: anOrdinalId [
	"The record of one shape of the entry standing, named by its position in the block the
	 reference of this tile points at, and kept in variables and not as values because the walk
	 reads another shape at every turn of its shape loop. The fill is the first shape of an entry
	 and a shape of its clip is read in exactly the same way.
	 A shape within the capacity of the staged block is read out of workgroup storage, where one
	 invocation of the workgroup put it; a shape past that capacity is read out of global memory
	 by this invocation for itself, because workgroup storage is declared when the module is
	 built while an entry carries as many shapes as its clip was cut out with. Both arms store
	 into the same variables, so the walk cannot tell which of the two it was given."

	| staged slotBase recordBase |
	staged := self
		          word: anOrdinalId
		          below:
		          (self constantWord: VGTiledFillStagedBlock shapeCapacity).
	slotBase := self
		            sumOfWord: (self
				             productOfWord: anOrdinalId
				             and: (self constantWord:
							              VGTiledFillLayout shapeRecordWords))
		            and: (self constantWord: stagedBlock shapeSlotBase).
	recordBase := self
		              productOfWord: (self
				               sumOfWord:
				               (self stagedWordAt: stagedBlock shapeOffsetSlot)
				               and: anOrdinalId)
		              and:
		              (self constantWord: VGTiledFillLayout shapeRecordWords).
	builder emitIf: staged then: [
		self shapeFieldsDo: [ :field :name |
			self
				store: (self stagedWordAtId: (self
							  sumOfWord: slotBase
							  and: (self constantWord: field - 1)))
				into: name ] ].
	builder emitIf: (self negation: staged) then: [
		self shapeFieldsDo: [ :field :name |
			self
				store: (self elementOf: #shapes atBase: recordBase field: field)
				into: name ] ]
]

{ #category : 'emitting - entry' }
VGTiledFillKernel >> rememberStagedClip [
	"The four sides of the clip of the entry standing, out of workgroup storage."

	#( #clipLeftField #clipTopField #clipRightField #clipBottomField ) do: [
		:each |
		self
			remember: (self stagedFloatAt:
					 (stagedBlock clipSlotOfField: (VGTiledFillLayout perform: each)))
			as: (each copyUpToLast: $F) asSymbol ]
]

{ #category : 'emitting - entry' }
VGTiledFillKernel >> rememberStagedHeader [
	"The words of the header of the entry standing that I read, read once out of workgroup
	 storage for the whole walk over it. What a shape of the entry is read under is not among
	 them: a fill and a shape of its clip each carry their own record. Nor is the start of the
	 whole-shape run of the entry, which the header does carry and which a backend replaying a
	 frame off the buffers alone reads: a reference of this tile names the block of records of
	 its own row of tiles instead. Nor is the offset of the paint block, which one invocation
	 read to stage the block itself and which no invocation needs once the block is staged: the
	 pixel emitter asks for a coefficient by its field and reads the slot it was staged in."

	#( #sourcePixelField #operatorField #alphaByteField #shapeCountField
	   #paintTagField #stopOffsetField #stopCountField #maskOffsetField
	   #pixelOffsetField ) do: [ :each |
		self
			remember: (self stagedWordAt:
					 (stagedBlock headerSlotOfField: (VGTiledFillLayout perform: each)))
			as: (each copyUpToLast: $F) asSymbol ]
]

{ #category : 'emitting - entry' }
VGTiledFillKernel >> rememberStagedMaskRect [
	"The four sides of the rectangle of the mask of the entry standing, out of workgroup storage.
	 A mask rectangle is laid out as a clip rectangle, so the field constants of a clip name its
	 fields, and the names these are remembered under are their own because a pixel is tested
	 against both rectangles."

	#( #clipLeftField #clipTopField #clipRightField #clipBottomField )
		with: #( #maskLeft #maskTop #maskRight #maskBottom )
		do: [ :field :name |
			self
				remember: (self stagedFloatAt: (stagedBlock maskRectSlotOfField:
							  (VGTiledFillLayout perform: field)))
				as: name ]
]

{ #category : 'initialization' }
VGTiledFillKernel >> setTileExtent: anExtent [
	tileExtent := anExtent
]

{ #category : 'emitting - entry' }
VGTiledFillKernel >> shapeFieldsDo: aBlock [
	"That block once for every word of a shape record, with the number of the field and the name
	 of the variable the walk reads it under. Two arms read a record — one out of workgroup
	 storage and one out of global memory — and this is what keeps them reading the same words
	 into the same variables."

	#( #shapeEdgeOffsetField #shapeEdgeCountField #shapeFillRuleField
	   #shapeAliasedField ) do: [ :each |
		aBlock
			value: (VGTiledFillLayout perform: each)
			value: (each copyUpToLast: $F) asSymbol ]
]

{ #category : 'emitting - staging' }
VGTiledFillKernel >> sharedPointerTo: aVariable ofType: aType at: aSlot [
	^ self
		  sharedPointerTo: aVariable
		  ofType: aType
		  atId: (self constantWord: aSlot)
]

{ #category : 'emitting - staging' }
VGTiledFillKernel >> sharedPointerTo: aVariable ofType: aType atId: aSlotId [
	"A pointer to one slot of a block of workgroup storage. A block is a bare array and not a
	 structure, so the chain has one index where a buffer's has two. The index may be a value and
	 not a constant, which is what lets the shape loop read the record of the shape it stands on."

	^ builder
		  emitAccessChain: aVariable id
		  type: (builder types pointerType: SpvStorageClass workgroup type: aType)
		  indices: { aSlotId }
]

{ #category : 'building' }
VGTiledFillKernel >> sharedVariables [
	^ {
		  stagedWords.
		  stagedFloats.
		  spanCounts.
		  spanBounds }
]

{ #category : 'emitting - sweep' }
VGTiledFillKernel >> spanBoundAtSlot: aSlotId [
	"One bound of one span out of workgroup storage, where the invocation that swept its
	 sub-row left it."

	^ builder
		  emitLoad:
			  (self sharedPointerTo: spanBounds ofType: self floatType atId: aSlotId)
		  type: self floatType
]

{ #category : 'emitting - sweep' }
VGTiledFillKernel >> spanBoundSlotOfSubRowOfTile: aSubRowId span: aSpanId [
	"The slot of the first bound of one span of one sub-row of the tile, the end of that span
	 standing in the slot after it. This is VGTiledFillSpanBlock >> startSlotOfSubRow:span:
	 computed here and not asked of the block, because a sub-row of the sweep and a span of it
	 are both ids of the walk and not integers; the block's own method is what the test of the
	 layout reads."

	^ self
		  productOfWord: (self constantWord: 2)
		  and: (self
				   sumOfWord: (self
						    productOfWord: aSubRowId
						    and:
						    (self constantWord: VGTiledFillSpanBlock spanCapacity))
				   and: aSpanId)
]

{ #category : 'emitting - sweep' }
VGTiledFillKernel >> spanCountOfSubRowOfTile: aSubRowId [
	"How many spans the sweep of that sub-row of the tile found, or the mark of an overflow
	 where it found more than the block holds. The slot is the sub-row's own, as
	 VGTiledFillSpanBlock >> countSlotOfSubRow: numbers it."

	^ builder
		  emitLoad:
			  (self sharedPointerTo: spanCounts ofType: self wordType atId: aSubRowId)
		  type: self wordType
]

{ #category : 'emitting - staging' }
VGTiledFillKernel >> stagedFloatAt: aSlot [
	^ builder
		  emitLoad:
		  (self sharedPointerTo: stagedFloats ofType: self floatType at: aSlot)
		  type: self floatType
]

{ #category : 'emitting - staging' }
VGTiledFillKernel >> stagedPaintCoefficient: aField [
	"One float of the paint block of the entry standing, out of workgroup storage. The pixel
	 emitter asks for a field of the block and does not need to know where the block itself sits,
	 which is why the slot and not the offset is what it reads."

	^ self stagedFloatAt: (stagedBlock paintSlotOfField: aField)
]

{ #category : 'emitting - staging' }
VGTiledFillKernel >> stagedWordAt: aSlot [
	^ builder
		  emitLoad:
		  (self sharedPointerTo: stagedWords ofType: self wordType at: aSlot)
		  type: self wordType
]

{ #category : 'emitting - staging' }
VGTiledFillKernel >> stagedWordAtId: aSlotId [
	^ builder
		  emitLoad: (self
				   sharedPointerTo: stagedWords
				   ofType: self wordType
				   atId: aSlotId)
		  type: self wordType
]

{ #category : 'emitting - sweep' }
VGTiledFillKernel >> storeSpanBound: aValueId atSlot: aSlotId [
	"One bound of one span into workgroup storage, written by the one invocation that swept its
	 sub-row."

	builder
		emitStore: aValueId
		at:
		(self sharedPointerTo: spanBounds ofType: self floatType atId: aSlotId)
]

{ #category : 'emitting - sweep' }
VGTiledFillKernel >> storeSpanCount: aValueId ofSubRowOfTile: aSubRowId [
	"The count of one sub-row, written by the one invocation that swept it."

	builder
		emitStore: aValueId
		at:
		(self sharedPointerTo: spanCounts ofType: self wordType atId: aSubRowId)
]

{ #category : 'accessing' }
VGTiledFillKernel >> tileExtent [
	^ tileExtent
]
