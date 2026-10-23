"
I am the tiled fill rasteriser of VGTiledFillRasteriser, hand built as one SPIR-V compute module: one workgroup owns one tile of the frame and one invocation owns one pixel of that tile.
I read the seven buffers of my own binding contract — the five VGTiledFillEncoding writes, the pixels of the target and the size of the frame — and I write one word of the target per invocation.
Nothing is shared and nothing is synchronised: a pixel belongs to one invocation alone, so the tiles may be dispatched in any order and no atomic or barrier appears in the module.
My walk is VGTileCoverage translated instruction by instruction, with a flag variable where that class answers early, and my composition is the arithmetic of VGCairoSurfaceFormat and of the three operators of VGTiledFillRasteriser class >> supportedOperators.
Send module for what I build and spirv for its bytes; a parity gate against the software backend is what holds me to the Pharo I translate, because the device computes in single floats where VGTileCoverage computes in double ones.
"
Class {
	#name : 'VGTiledFillKernel',
	#superclass : 'VGSpirvVocabulary',
	#instVars : [
		'tileExtent',
		'bindings',
		'builtIns',
		'variables',
		'spirvModule',
		'spirv'
	],
	#classInstVars : [
		'spirvByTileExtent'
	],
	#category : 'VectorGraphics-Vulkan-Tiles',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Tiles'
}

{ #category : 'contract' }
VGTiledFillKernel class >> bindingNames [
	"The nine buffers I read, in the order they are bound: the seven an encoding writes, the
	 pixels of the target and the size of the frame. A binding number is the position of the
	 name here, counted from zero, so this one list states the whole contract."

	^ #( #tileTable #entryRefs #headers #clips #edges #paints #stops #target
	     #frame )
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

{ #category : 'constants' }
VGTiledFillKernel class >> columnComponent [
	"The component of the local invocation id that carries the column of the pixel inside the
	 tile."

	^ 0
]

{ #category : 'instance creation' }
VGTiledFillKernel class >> default [
	"The kernel of the tile size VGTileGrid measured, which is the one every frame of this
	 engine is binned over."

	^ self onTileExtent: VGTileGrid defaultTileExtent
]

{ #category : 'constants' }
VGTiledFillKernel class >> descriptorSetIndex [
	"All seven buffers stand at one descriptor set, so one set is bound once a frame."

	^ 0
]

{ #category : 'constants' }
VGTiledFillKernel class >> elementStride [
	"The bytes one element of a buffer takes, which is what the array stride decoration wants."

	^ self scalarBitWidth // 8
]

{ #category : 'constants' }
VGTiledFillKernel class >> entryPointName [
	"The name every compute entry point of this engine carries, and the one the shader module
	 is asked for."

	^ 'main'
]

{ #category : 'contract' }
VGTiledFillKernel class >> floatBindingNames [
	"The four buffers of single floats. A clip side, an edge end, a coefficient of a paint and
	 the offset and channels of a stop are all floating point; everything else a frame carries
	 is a word."

	^ #( #clips #edges #paints #stops )
]

{ #category : 'constants' }
VGTiledFillKernel class >> floatVariableNames [
	^ #( #coverage #runCursor #runFromCursor #endCursor #endResult #nearest )
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
VGTiledFillKernel class >> layerCount [
	"One layer: a tile is two dimensional, so the third dimension of the workgroup holds one
	 invocation."

	^ 1
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
VGTiledFillKernel class >> rowComponent [
	^ 1
]

{ #category : 'constants' }
VGTiledFillKernel class >> shaderCapability [
	"The serialiser maps this symbol to the Shader capability number, so the module names the
	 capability rather than repeating its value."

	^ #Shader
]

{ #category : 'constants' }
VGTiledFillKernel class >> signedVariableNames [
	"The three winding numbers, which run negative under the winding rule."

	^ #( #runFromWinding #endWinding #scanWinding )
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
VGTiledFillKernel class >> variableNames [
	"Every value the walk keeps between instructions, in the order it is declared."

	^ self wordVariableNames , self signedVariableNames , self floatVariableNames
]

{ #category : 'contract' }
VGTiledFillKernel class >> wordVariableNames [
	"The function variables that hold a word: the destination pixel, the source pixel of the
	 fill and whether the fill lays one down at all, the three loop counters, the stop loop with
	 the two stops it looks for and the flags that stand where VGTileCoverage answers early."

	^ #( #dest #source #hasSource #reference #sample #runsMore
	     #runFromSearching #runFromFound #endRunning #edge #nearestFound #stop
	     #beforeStop #afterStop #beforeFound #afterFound )
]

{ #category : 'inspecting' }
VGTiledFillKernel >> bindingRows [
	"The binding contract as the kernel itself declares it: the position of a name in
	 bindingNames is its binding number, and floatBindingNames says which of them carry
	 coordinates."

	^ self class bindingNames withIndexCollect: [ :each :index |
		  {
			  (index - 1) printString.
			  each asString.
			  ((self class floatBindingNames includes: each)
				   ifTrue: [ 'f32' ]
				   ifFalse: [ 'u32' ]) } ]
]

{ #category : 'building' }
VGTiledFillKernel >> buildModule [
	"Assemble the module. The built-ins and the buffers are declared before the function,
	 because a definition has to precede every use of its id, and the GLSL set is imported
	 because the walk takes a floor, a ceiling and three minima the core instruction set has
	 none of."

	builder := SpvBuilder new.
	builder addCapability: self class shaderCapability.
	self declareBuiltIns.
	self declareBuffers.
	glsl := builder importGLSL.
	values := Dictionary new.
	self emitMain.
	^ builder module
]

{ #category : 'private' }
VGTiledFillKernel >> componentOfBuiltIn: aBuiltIn at: anInteger [
	^ builder
		  emitCompositeExtract:
		  (builder emitLoad: (builtIns at: aBuiltIn) id type: self vectorType)
		  type: self wordType
		  indices: { anInteger }
]

{ #category : 'building' }
VGTiledFillKernel >> declareBuffers [
	"One variable per binding, numbered by its position in the contract. Two element types
	 serve all seven and the registry answers one array and one structure for each, so the
	 stride and the block decoration are written once per type and never twice."

	| pointerTypes |
	bindings := Dictionary new.
	pointerTypes := Dictionary new.
	self class bindingNames withIndexDo: [ :each :index |
		| element |
		element := self elementTypeOf: each.
		bindings
			at: each
			put: (self
					 newBufferVariableOfType:
					 (pointerTypes
						  at: element
						  ifAbsentPut: [ self newBufferPointerTypeOfElement: element ])
					 binding: index - 1) ]
]

{ #category : 'building' }
VGTiledFillKernel >> declareBuiltIns [
	"The built-ins are kept by their own number, so a reader of the module and a reader of this
	 class name the same thing."

	builtIns := Dictionary new.
	self class builtInNumbers do: [ :each |
		builtIns at: each put: (self newBuiltInVariableOf: each) ]
]

{ #category : 'building' }
VGTiledFillKernel >> declareFunctionVariables [
	"Every value the walk keeps between instructions, declared once in the function's first
	 block. SPIR-V has no early answer out of a loop, so each nil VGTileCoverage answers and
	 each loop it leaves early is carried here as a flag beside the value it guards."

	variables := Dictionary new.
	self class variableNames do: [ :each |
		variables
			at: each
			put: (builder emitVariableOfType: (self typeOfVariableNamed: each)) ]
]

{ #category : 'buffers' }
VGTiledFillKernel >> elementOf: aBindingName at: anIndexId [
	^ builder
		  emitLoad: (self pointerTo: aBindingName at: anIndexId)
		  type: (self elementTypeOf: aBindingName)
]

{ #category : 'buffers' }
VGTiledFillKernel >> elementOf: aBindingName atBase: aBaseId field: anInteger [
	"Fields count from one and a buffer is indexed from zero, so the word of a field sits one
	 before its number."

	^ self
		  elementOf: aBindingName
		  at: (self
				   sumOfWord: aBaseId
				   and: (self constantWord: anInteger - 1))
]

{ #category : 'private' }
VGTiledFillKernel >> elementTypeOf: aBindingName [
	^ (self class floatBindingNames includes: aBindingName)
		  ifTrue: [ self floatType ]
		  ifFalse: [ self wordType ]
]

{ #category : 'emitting' }
VGTiledFillKernel >> emitAliasedSpanFrom: aLeftId to: aRightId onSubRow: aSubRowId [
	"Antialiasing off is one sample at the centre of the pixel row, and the run is then the
	 whole of the pixel the clip allows: VGTileCoverage >> aliasedSpanAtX:onSubRow:do:."

	| winding |
	winding := self
		           emitWindingUpTo: (self
				            sumOfFloat: (self valueNamed: #pixelLeft)
				            and: (self constantFloat: self class halfUnit))
		           onSubRow: (self
				            sumOfFloat: (self floorOfFloat: aSubRowId)
				            and: (self constantFloat: self class halfUnit)).
	builder emitIf: (self emitIsInside: winding) then: [
		self
			store: (self
					 sumOfFloat: (self load: #coverage)
					 and: (self differenceOfFloat: aRightId and: aLeftId))
			into: #coverage ]
]

{ #category : 'emitting' }
VGTiledFillKernel >> emitAllowsRow [
	"The rows the walk visits at all: whole pixel rows, from the floor of the clip's top to the
	 ceiling of its bottom, which is VGTileCoverage >> allowsRowAt:."

	^ self
		  both: (self
				   float: (self valueNamed: #pixelRow)
				   atLeast: (self floorOfFloat: (self valueNamed: #clipTop)))
		  and: (self
				   float: (self valueNamed: #pixelRow)
				   below: (self ceilingOfFloat: (self valueNamed: #clipBottom)))
]

{ #category : 'emitting' }
VGTiledFillKernel >> emitBody [
	"Which tile this workgroup owns, which pixel of it this invocation owns, and whether that
	 pixel is inside the frame at all: a tile of the last column or the last row is short, and
	 the invocations past its edge have no pixel to draw."

	| tileBase height inside |
	tileBase := self
		            productOfWord:
		            (self
			             componentOfBuiltIn: SpvBuiltIn workgroupId
			             at: self class tileComponent)
		            and:
		            (self constantWord: VGTiledFillEncoding tileRecordWords).
	self
		remember: (self
				 elementOf: #frame
				 atBase: (self constantWord: 0)
				 field: self class frameWidthField)
		as: #frameWidth.
	height := self
		          elementOf: #frame
		          atBase: (self constantWord: 0)
		          field: self class frameHeightField.
	self
		remember: (self
				 sumOfWord: (self
						  elementOf: #tileTable
						  atBase: tileBase
						  field: VGTiledFillEncoding tileLeftField)
				 and: (self
						  componentOfBuiltIn: SpvBuiltIn localInvocationId
						  at: self class columnComponent))
		as: #pixelX.
	self
		remember: (self
				 sumOfWord: (self
						  elementOf: #tileTable
						  atBase: tileBase
						  field: VGTiledFillEncoding tileTopField)
				 and: (self
						  componentOfBuiltIn: SpvBuiltIn localInvocationId
						  at: self class rowComponent))
		as: #pixelY.
	self
		remember: (self
				 elementOf: #tileTable
				 atBase: tileBase
				 field: VGTiledFillEncoding referenceOffsetField)
		as: #referenceOffset.
	self
		remember: (self
				 elementOf: #tileTable
				 atBase: tileBase
				 field: VGTiledFillEncoding referenceCountField)
		as: #referenceCount.
	inside := self
		          both: (self
				           word: (self valueNamed: #pixelX)
				           below: (self valueNamed: #frameWidth))
		          and: (self word: (self valueNamed: #pixelY) below: height).
	builder emitIf: inside then: [ self emitPixel ]
]

{ #category : 'emission - entry' }
VGTiledFillKernel >> emitCoverageGivenInterior: aBooleanId [
	"The coverage of this pixel for this entry: one where the reference says the entry covers the
	 whole of the tile, and the walk over the edges where it does not. The walk samples fifteen
	 sub-rows of the pixel and scans the edges of the entry at each of them, so a tile deep
	 inside a shape pays all of that for an answer that was one from the start."

	self store: (self constantFloat: 0) into: #coverage.
	builder emitIf: aBooleanId then: [
		self store: (self constantFloat: 1) into: #coverage ].
	builder emitIf: (self negation: aBooleanId) then: [
		builder emitIf: self emitAllowsRow then: [ self emitCoverageOfSubRows ] ]
]

{ #category : 'emitting' }
VGTiledFillKernel >> emitCoverageOfSubRows [
	"The part of this pixel the fill covers, summed over the sub-rows of its row and capped at
	 one, which is VGTileCoverage >> atX:row:. The terms arrive in the order they arrive there,
	 so the sum is the same arithmetic in a narrower float."

	self store: (self constantWord: 0) into: #sample.
	builder
		emitWhile: [
			self
				word: (self load: #sample)
				below: (self constantWord: self class subRowCount) ]
		do: [
			self emitSpansOnSubRow: (self
					 sumOfFloat: (self valueNamed: #pixelRow)
					 and: (self
							  quotientOfFloat: (self
									   sumOfFloat: (self floatOfWord: (self load: #sample))
									   and: (self constantFloat: self class halfUnit))
							  by: (self constantFloat: self class subRowCount))).
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
	"The nearest crossing strictly right of that cursor, and whether my edges have one at all,
	 left in nearestFound. One scan of the edges, which is what a run costs here instead of a
	 sorted array of every crossing: VGTileCoverage >> crossingAfter:onSubRow:."

	self store: (self constantFloat: 0) into: #nearest.
	self store: (self constantWord: 0) into: #nearestFound.
	self store: (self constantWord: 0) into: #edge.
	builder
		emitWhile: [
		self word: (self load: #edge) below: (self valueNamed: #edgeCount) ]
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
	"Where the edge at that position of this entry crosses that sub-row, and whether it reaches
	 it at all: VGTileCoverage >> crossingOfEdgeAt:onSubRow: term for term, with the two answers
	 of nil carried as a flag beside the value. The edge is taken half open from its upper end.
	 A horizontal edge divides by the difference of its own two ends, so the divisor is one
	 where the edge does not reach the sub-row at all, which keeps an infinity out of a value
	 the walk then discards."

	| base x0 y0 x1 y1 reaches divisor |
	base := self
		        productOfWord: (self
				         sumOfWord: (self valueNamed: #edgeOffset)
				         and: anEdgeId)
		        and: (self constantWord: VGTiledFillEncoding edgeFloats).
	x0 := self
		      elementOf: #edges
		      atBase: base
		      field: VGTiledFillEncoding edgeStartXField.
	y0 := self
		      elementOf: #edges
		      atBase: base
		      field: VGTiledFillEncoding edgeStartYField.
	x1 := self
		      elementOf: #edges
		      atBase: base
		      field: VGTiledFillEncoding edgeEndXField.
	y1 := self
		      elementOf: #edges
		      atBase: base
		      field: VGTiledFillEncoding edgeEndYField.
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
				         sumOfWord: (self valueNamed: #edgeOffset)
				         and: anEdgeId)
		        and: (self constantWord: VGTiledFillEncoding edgeFloats).
	y0 := self
		      elementOf: #edges
		      atBase: base
		      field: VGTiledFillEncoding edgeStartYField.
	y1 := self
		      elementOf: #edges
		      atBase: base
		      field: VGTiledFillEncoding edgeEndYField.
	^ self
		  select: (self float: y1 above: y0)
		  ifTrue: (self constantSigned: 1)
		  ifFalse: (self constantSigned: -1)
		  type: self signedType
]

{ #category : 'emitting' }
VGTiledFillKernel >> emitEndOfRunFrom: aStartId to: aRightId onSubRow: aSubRowId [
	"Where the run that begins there stops, left in endResult: the first crossing right of it
	 that puts the walk outside the shape, or the right bound where none does before the pixel
	 ends, which is VGTileCoverage >> endOfRunFrom:to:onSubRow:. The right bound is stored
	 first, because it is the answer of both paths that leave the loop without a crossing."

	self store: aStartId into: #endCursor.
	self
		store: (self emitWindingUpTo: aStartId onSubRow: aSubRowId)
		into: #endWinding.
	self store: (self constantWord: 1) into: #endRunning.
	self store: aRightId into: #endResult.
	builder
		emitWhile: [
			self
				both: (self word: (self load: #endRunning) equals: (self constantWord: 1))
				and: (self float: (self load: #endCursor) below: aRightId) ]
		do: [
			| crossing stop |
			crossing := self
				            emitCrossingAfter: (self load: #endCursor)
				            onSubRow: aSubRowId.
			stop := self
				        either: (self
						         word: (self load: #nearestFound)
						         equals: (self constantWord: 0))
				        or: (self float: crossing atLeast: aRightId).
			builder
				emitIf: stop
				then: [ self store: (self constantWord: 0) into: #endRunning ].
			builder emitIf: (self negation: stop) then: [
				self store: crossing into: #endCursor.
				self
					store: (self
							 sumOfSigned: (self load: #endWinding)
							 and: (self emitWindingStepAt: crossing onSubRow: aSubRowId))
					into: #endWinding.
				builder
					emitIf:
						(self negation: (self emitIsInside: (self load: #endWinding)))
					then: [
						self store: (self load: #endCursor) into: #endResult.
						self store: (self constantWord: 0) into: #endRunning ] ] ]
]

{ #category : 'emission - entry' }
VGTiledFillKernel >> emitEntry [
	"One fill of this tile at this pixel: its header, its clip, the pixel its paint lays down
	 here, the coverage of the walk over it and the composition of the two into the destination.
	 The reference holds the identifier of the entry, counting from one as VGTiledFillEncoding
	 writes it, and in its top bit the mark that says the entry covers the whole of this tile.
	 A pixel the paint lays nothing down at is left alone, which the subset may do because every
	 operator in it is bounded, and which is what the software rasteriser does with the nil a
	 paint answers.
	 The paint and the composition are emitted by VGTiledFillPixelEmitter, which shares this
	 module while I emit this entry; the walk over the edges between them is my own."

	| reference identifier previous mask pixels |
	pixels := VGTiledFillPixelEmitter on: self.
	reference := self
		             elementOf: #entryRefs
		             at: (self
				              sumOfWord: (self valueNamed: #referenceOffset)
				              and: (self load: #reference)).
	identifier := self
		              bitsOfWord: reference
		              and:
		              (self constantWord:
				               VGTiledFillEncoding referenceIdentifierMask).
	previous := self
		            differenceOfWord: identifier
		            and: (self constantWord: 1).
	self
		rememberHeaderAt: (self
				 productOfWord: previous
				 and: (self constantWord: VGTiledFillEncoding entryHeaderWords)).
	self
		rememberClipAt: (self
				 productOfWord: previous
				 and: (self constantWord: VGTiledFillEncoding clipFloats)).
	pixels emitSource.
	self emitCoverageGivenInterior: (self emitIsInteriorReference: reference).
	mask := pixels emitMaskForCoverage: (self load: #coverage).
	builder
		emitIf: (self
				 both: (self word: (self constantWord: 0) below: mask)
				 and: (self word: (self constantWord: 0) below: (self load: #hasSource)))
		then: [ pixels emitCompositeWithMask: mask ]
]

{ #category : 'emitting' }
VGTiledFillKernel >> emitIsInside: aWindingId [
	"Whether that winding number stands inside the shape, under the fill rule the entry's
	 header names: VGSpanScanner >> isInside:. An odd number is the lowest bit set, which holds
	 for a negative winding as well, because a signed word is stored in two's complement."

	| evenOdd odd nonZero |
	evenOdd := self
		           word: (self valueNamed: #fillRule)
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

{ #category : 'emission - entry' }
VGTiledFillKernel >> emitIsInteriorReference: aReferenceId [
	"Whether that reference carries the mark of a tile the entry covers in full, which is
	 VGTiledFillEncoding class >> isInteriorReference: read in the kernel."

	^ self
		  word:
		  (self
			   bitsOfWord: aReferenceId
			   and:
			   (self constantWord: VGTiledFillEncoding interiorReferenceFlag))
		  equals:
		  (self constantWord: VGTiledFillEncoding interiorReferenceFlag)
]

{ #category : 'building' }
VGTiledFillKernel >> emitMain [
	"The entry point: its variables, its interface, the shape of its workgroup and the one
	 pixel it draws."

	| function |
	function := builder newFunction: builder types voidType.
	builder currentBlock: function addBlock.
	self declareFunctionVariables.
	builder
		addEntryPoint: function
		executionModel: SpvExecutionModel glCompute
		name: self class entryPointName
		interfaces: self interfaceVariables.
	builder
		addExecutionMode: function
		mode: SpvExecutionMode localSize
		literals: self localSize.
	self emitBody.
	builder emitReturn
]

{ #category : 'emitting' }
VGTiledFillKernel >> emitPixel [
	"The pixel of this invocation: the destination word read once, every entry of the tile
	 composited into it in the order the references hold them, and the word written back. One
	 invocation owns this pixel alone, so nothing else can have written it in between, which is
	 what lets the read stand outside the loop."

	| index |
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
	self store: (self elementOf: #target at: index) into: #dest.
	self store: (self constantWord: 0) into: #reference.
	builder
		emitWhile: [
		self word: (self load: #reference) below: (self valueNamed: #referenceCount) ]
		do: [
			self emitEntry.
			self
				store:
					(self sumOfWord: (self load: #reference) and: (self constantWord: 1))
				into: #reference ].
	self storeWord: (self load: #dest) into: #target at: index
]

{ #category : 'emitting' }
VGTiledFillKernel >> emitRunFrom: aCursorId to: aRightId onSubRow: aSubRowId [
	"The next inside run at or after that cursor: its start in runFromCursor, its end in
	 endResult, and whether there is one at all in the flag this answers. Nothing is sorted and
	 no crossing is kept, as in VGTileCoverage >> runFrom:to:onSubRow:: the winding where the
	 walk stands is one scan of the edges and the next crossing to the right of it is one more,
	 because an invocation can afford neither a sort nor a scratch array."

	self store: aCursorId into: #runFromCursor.
	self
		store: (self emitWindingUpTo: aCursorId onSubRow: aSubRowId)
		into: #runFromWinding.
	self
		store: (self searchingFlagFor: (self load: #runFromWinding))
		into: #runFromSearching.
	self store: (self constantWord: 1) into: #runFromFound.
	builder
		emitWhile: [
		self word: (self load: #runFromSearching) equals: (self constantWord: 1) ]
		do: [
			| crossing stop |
			crossing := self
				            emitCrossingAfter: (self load: #runFromCursor)
				            onSubRow: aSubRowId.
			stop := self
				        either: (self
						         word: (self load: #nearestFound)
						         equals: (self constantWord: 0))
				        or: (self float: crossing atLeast: aRightId).
			builder emitIf: stop then: [
				self store: (self constantWord: 0) into: #runFromFound.
				self store: (self constantWord: 0) into: #runFromSearching ].
			builder emitIf: (self negation: stop) then: [
				self store: crossing into: #runFromCursor.
				self
					store: (self
							 sumOfSigned: (self load: #runFromWinding)
							 and: (self emitWindingStepAt: crossing onSubRow: aSubRowId))
					into: #runFromWinding.
				self
					store: (self searchingFlagFor: (self load: #runFromWinding))
					into: #runFromSearching ] ].
	builder
		emitIf:
			(self word: (self load: #runFromFound) equals: (self constantWord: 1))
		then: [
			self
				emitEndOfRunFrom: (self load: #runFromCursor)
				to: aRightId
				onSubRow: aSubRowId ].
	^ self load: #runFromFound
]

{ #category : 'emitting' }
VGTiledFillKernel >> emitRunsFrom: aLeftId to: aRightId onSubRow: aSubRowId [
	"The inside runs between those two bounds, left to right, which is
	 VGTileCoverage >> runsFrom:to:onSubRow:do:. The walk stops where no run begins before the
	 right bound, and that answer of nil is the flag runsMore."

	self store: aLeftId into: #runCursor.
	self store: (self constantWord: 1) into: #runsMore.
	builder
		emitWhile: [
			self
				both: (self word: (self load: #runsMore) equals: (self constantWord: 1))
				and: (self float: (self load: #runCursor) below: aRightId) ]
		do: [
			| found |
			found := self
				         emitRunFrom: (self load: #runCursor)
				         to: aRightId
				         onSubRow: aSubRowId.
			builder
				emitIf: (self word: found equals: (self constantWord: 0))
				then: [ self store: (self constantWord: 0) into: #runsMore ].
			builder
				emitIf: (self word: found equals: (self constantWord: 1))
				then: [
					self
						store: (self
								 sumOfFloat: (self load: #coverage)
								 and: (self
										  differenceOfFloat: (self load: #endResult)
										  and: (self load: #runFromCursor)))
						into: #coverage.
					self store: (self load: #endResult) into: #runCursor ] ]
]

{ #category : 'emitting' }
VGTiledFillKernel >> emitSpansOnSubRow: aSubRowId [
	"My fill's inside runs within this pixel on that sub-row, trimmed to the clip, which is
	 VGTileCoverage >> spansAtX:onSubRow:do: and the two edges it trims to."

	| left right aliased |
	left := self
		        largerFloatOf: (self valueNamed: #pixelLeft)
		        and: (self valueNamed: #clipLeft).
	right := self
		         smallerFloatOf: (self
				          sumOfFloat: (self valueNamed: #pixelLeft)
				          and: (self constantFloat: 1))
		         and: (self valueNamed: #clipRight).
	aliased := self
		           word: (self valueNamed: #aliased)
		           equals:
		           (self constantWord: (VGTiledFillEncoding flagForAliased: true)).
	builder emitIf: (self float: right above: left) then: [
		builder
			emitIf: aliased
			then: [ self emitAliasedSpanFrom: left to: right onSubRow: aSubRowId ].
		builder
			emitIf: (self negation: aliased)
			then: [ self emitRunsFrom: left to: right onSubRow: aSubRowId ] ]
]

{ #category : 'emitting' }
VGTiledFillKernel >> emitWindingOnSubRow: aSubRowId accepting: aBlock [
	"What the crossings that block accepts contribute to the winding, which is
	 VGTileCoverage >> windingOnSubRow:crossing: inlined at each of its call sites: the even-odd
	 rule counts a crossing and the winding rule counts the direction the edge runs in."

	| evenOdd |
	evenOdd := self
		           word: (self valueNamed: #fillRule)
		           equals:
		           (self constantWord:
			            (VGTiledFillEncoding codeForFillRule: #evenOdd)).
	self store: (self constantSigned: 0) into: #scanWinding.
	self store: (self constantWord: 0) into: #edge.
	builder
		emitWhile: [
		self word: (self load: #edge) below: (self valueNamed: #edgeCount) ]
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
VGTiledFillKernel >> emitWindingStepAt: anX onSubRow: aSubRowId [
	"What the crossings at exactly that coordinate add to the winding. Two edges can cross one
	 point, and a walk that took them one at a time would call the space between them a run of
	 its own."

	^ self
		  emitWindingOnSubRow: aSubRowId
		  accepting: [ :crossing | self float: crossing equals: anX ]
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

{ #category : 'inspecting' }
VGTiledFillKernel >> inspectorBindings: aBuilder [
	<inspectorPresentationOrder: 11 title: 'Bindings'>
	"The seven buffers of one descriptor set, each with the number it is bound at and the width
	 of its own element."

	^ aBuilder newTable
		  addColumn: (SpStringTableColumn
				   title: 'Binding'
				   evaluated: [ :each | each first ]);
		  addColumn: (SpStringTableColumn
				   title: 'Buffer'
				   evaluated: [ :each | each second ]);
		  addColumn: (SpStringTableColumn
				   title: 'Element'
				   evaluated: [ :each | each third ]);
		  items: self bindingRows;
		  yourself
]

{ #category : 'inspecting' }
VGTiledFillKernel >> inspectorBindingsContext: aContext [
	aContext active: tileExtent isNotNil
]

{ #category : 'inspecting' }
VGTiledFillKernel >> inspectorModule: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Module'>
	"What the module a dispatch would be given really holds: the shape of its workgroup, the
	 buffers and built-ins it names, and the two counts that state the rule of this kernel —
	 nothing shared and nothing synchronised."

	^ aBuilder newTable
		  addColumn: (SpStringTableColumn
				   title: 'Fact'
				   evaluated: [ :each | each first ]);
		  addColumn: (SpStringTableColumn
				   title: 'Value'
				   evaluated: [ :each | each second ]);
		  items: self moduleRows;
		  yourself
]

{ #category : 'inspecting' }
VGTiledFillKernel >> inspectorModuleContext: aContext [
	aContext active: tileExtent isNotNil
]

{ #category : 'building' }
VGTiledFillKernel >> interfaceVariables [
	"Under SPIR-V 1.5 an entry point names every module-scope variable it touches, so a buffer
	 or a built-in left out of this list is a module a driver may refuse."

	^ (self class builtInNumbers collect: [ :each | builtIns at: each ])
	  , (self class bindingNames collect: [ :each | bindings at: each ])
]

{ #category : 'private' }
VGTiledFillKernel >> load: aName [
	^ builder
		  emitLoad: (variables at: aName)
		  type: (self typeOfVariableNamed: aName)
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

{ #category : 'accessing' }
VGTiledFillKernel >> module [
	"What I build, built once per instance: the build allocates result ids from one counter, so
	 it is a fresh builder each time or nothing."

	^ spirvModule ifNil: [ spirvModule := self buildModule ]
]

{ #category : 'inspecting' }
VGTiledFillKernel >> moduleRows [
	"What the emitted bytes say about themselves, read by the validator and not by this class,
	 so a view of them cannot restate a fact the module has stopped carrying. The kernel is
	 built afresh here, because a view may not leave the object it shows holding a module it
	 did not hold before."

	| fresh validator |
	fresh := self class onTileExtent: tileExtent.
	validator := PVSpirvValidator on: fresh spirv.
	^ {
		  { 'Bytes'. fresh spirv size printString }.
		  { 'Workgroup'. validator localSizeFromWords printString }.
		  { 'Built-ins'. (', ' join: validator builtInsFromWords) }.
		  { 'Storage buffers'.
		  (validator variableIdsInStorageClass: SpvStorageClass storageBuffer) size
			  printString }.
		  { 'Entry point interface'.
		  validator entryPointInterfaceIds size printString }.
		  { 'Workgroup storage'.
		  (validator variableIdsInStorageClass: SpvStorageClass workgroup) size
			  printString }.
		  { 'Barriers'.
		  (validator countOfOpcode: SpvOpcode opControlBarrier) printString }.
		  { 'Loops'.
		  (validator countOfOpcode: SpvOpcode opLoopMerge) printString }.
		  { 'Selections'.
		  (validator countOfOpcode: SpvOpcode opSelectionMerge) printString }.
		  { 'spirv-val'.
		  (PVSpirvValidator isAvailable
			   ifTrue: [
				   validator isValid
					   ifTrue: [ 'valid' ]
					   ifFalse: [ validator validationOutput ] ]
			   ifFalse: [ 'not installed' ]) } }
]

{ #category : 'building' }
VGTiledFillKernel >> newBufferPointerTypeOfElement: anElementType [
	"One runtime array of that element inside one structure, which is what a storage buffer
	 binding looks like. The stride belongs to the array type and the offset to the member:
	 spirv-val refuses a stride on a structure member."

	| array structure |
	array := builder types runtimeArrayType: anElementType.
	structure := builder types structType: { array }.
	builder
		addDecoration: array id
		decoration: SpvDecoration arrayStride
		literals: { self class elementStride }.
	builder
		addDecoration: structure id
		decoration: SpvDecoration block
		literals: #( ).
	builder
		addMemberDecoration: structure id
		member: PVSPIRVEmitter bufferMemberIndex
		decoration: SpvDecoration offset
		literals: { PVSPIRVEmitter bufferMemberOffset }.
	^ builder types
		  pointerType: SpvStorageClass storageBuffer
		  type: structure
]

{ #category : 'building' }
VGTiledFillKernel >> newBufferVariableOfType: aPointerType binding: anInteger [
	| variable |
	variable := builder
		            addGlobalVariable: aPointerType
		            storageClass: SpvStorageClass storageBuffer.
	builder
		addDecoration: variable id
		decoration: SpvDecoration descriptorSet
		literals: { self class descriptorSetIndex }.
	builder
		addDecoration: variable id
		decoration: SpvDecoration bindingDecoration
		literals: { anInteger }.
	^ variable
]

{ #category : 'building' }
VGTiledFillKernel >> newBuiltInVariableOf: aBuiltIn [
	| variable |
	variable := builder
		            addGlobalVariable:
		            (builder types
			             pointerType: SpvStorageClass input
			             type: self vectorType)
		            storageClass: SpvStorageClass input.
	builder
		addDecoration: variable id
		decoration: SpvDecoration builtIn
		literals: { aBuiltIn }.
	^ variable
]

{ #category : 'buffers' }
VGTiledFillKernel >> pointerTo: aBindingName at: anIndexId [
	"A pointer to one element of that buffer's runtime array: the structure's one member, then
	 the element inside it."

	^ builder
		  emitAccessChain: (bindings at: aBindingName) id
		  type: (builder types
				   pointerType: SpvStorageClass storageBuffer
				   type: (self elementTypeOf: aBindingName))
		  indices: {
				  (self constantWord: PVSPIRVEmitter bufferMemberIndex).
				  anIndexId }
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

{ #category : 'emitting' }
VGTiledFillKernel >> rememberClipAt: aBaseId [
	"The four sides of one entry's clip, which is a rectangle in this subset."

	#( #clipLeftField #clipTopField #clipRightField #clipBottomField ) do: [
		:each |
		self
			remember: (self
					 elementOf: #clips
					 atBase: aBaseId
					 field: (VGTiledFillEncoding perform: each))
			as: (each copyUpToLast: $F) asSymbol ]
]

{ #category : 'emission - entry' }
VGTiledFillKernel >> rememberHeaderAt: aBaseId [
	"The eleven words of one entry''s header, read once for the whole walk over it."

	#( #sourcePixelField #operatorField #fillRuleField #aliasedField
	   #alphaByteField #edgeOffsetField #edgeCountField #paintTagField
	   #paintBlockOffsetField #stopOffsetField #stopCountField ) do: [ :each |
		self
			remember: (self
					 elementOf: #headers
					 atBase: aBaseId
					 field: (VGTiledFillEncoding perform: each))
			as: (each copyUpToLast: $F) asSymbol ]
]

{ #category : 'emitting' }
VGTiledFillKernel >> searchingFlagFor: aWindingId [
	"One while the walk is still outside the shape and zero once it is inside, which is the
	 condition of VGTileCoverage >> runFrom:to:onSubRow: read as a word, because a loop of
	 SPIR-V branches on a value and not on a block."

	^ self
		  select: (self emitIsInside: aWindingId)
		  ifTrue: (self constantWord: 0)
		  ifFalse: (self constantWord: 1)
		  type: self wordType
]

{ #category : 'initialization' }
VGTiledFillKernel >> setTileExtent: anExtent [
	tileExtent := anExtent
]

{ #category : 'accessing' }
VGTiledFillKernel >> spirv [
	"The bytes of my module, which is what a shader module is created from."

	^ spirv ifNil: [ spirv := self module serialize ]
]

{ #category : 'private' }
VGTiledFillKernel >> store: anId into: aName [
	builder emitStore: anId at: (variables at: aName)
]

{ #category : 'buffers' }
VGTiledFillKernel >> storeWord: aValueId into: aBindingName at: anIndexId [
	builder
		emitStore: aValueId
		at: (self pointerTo: aBindingName at: anIndexId)
]

{ #category : 'accessing' }
VGTiledFillKernel >> tileExtent [
	^ tileExtent
]

{ #category : 'private' }
VGTiledFillKernel >> typeOfVariableNamed: aName [
	(self class signedVariableNames includes: aName) ifTrue: [
		^ self signedType ].
	(self class floatVariableNames includes: aName) ifTrue: [ ^ self floatType ].
	^ self wordType
]
