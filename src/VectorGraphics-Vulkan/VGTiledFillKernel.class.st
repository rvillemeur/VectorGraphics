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
		'tileExtent'
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
	"The thirteen buffers I read, in the order they are bound: the eleven an encoding writes,
	 the pixels of the target and the size of the frame. A binding number is the position of the
	 name here, counted from zero, so this one list states the whole contract."

	^ #( #tileTable #entryRefs #refShapes #headers #clips #edges #shapes #paints
	     #stops #maskRects #maskBytes #target #frame )
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
	 fill and whether the fill lays one down at all, the byte the mask of the fill carries here,
	 the three loop counters, the record of the shape the walk stands in and the verdicts of a
	 sweep over the shapes, the stop loop with the two stops it looks for and the flags that
	 stand where VGTileCoverage answers early."

	^ #( #dest #source #hasSource #maskByte #reference #sample #edge #shape
	     #shapeEdgeOffset #shapeEdgeCount #shapeFillRule #shapeAliased
	     #hasAntialiased #allows #insideAll #inside #nextInside #nearestFound
	     #stop #beforeStop #afterStop #beforeFound #afterFound )
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
		            (self constantWord: VGTiledFillLayout tileRecordWords).
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
						  field: VGTiledFillLayout tileLeftField)
				 and: (self
						  componentOfBuiltIn: SpvBuiltIn localInvocationId
						  at: self class columnComponent))
		as: #pixelX.
	self
		remember: (self
				 sumOfWord: (self
						  elementOf: #tileTable
						  atBase: tileBase
						  field: VGTiledFillLayout tileTopField)
				 and: (self
						  componentOfBuiltIn: SpvBuiltIn localInvocationId
						  at: self class rowComponent))
		as: #pixelY.
	self
		remember: (self
				 elementOf: #tileTable
				 atBase: tileBase
				 field: VGTiledFillLayout referenceOffsetField)
		as: #referenceOffset.
	self
		remember: (self
				 elementOf: #tileTable
				 atBase: tileBase
				 field: VGTiledFillLayout referenceCountField)
		as: #referenceCount.
	inside := self
		          both: (self
				           word: (self valueNamed: #pixelX)
				           below: (self valueNamed: #frameWidth))
		          and: (self word: (self valueNamed: #pixelY) below: height).
	builder emitIf: inside then: [ self emitPixel ]
]

{ #category : 'emitting' }
VGTiledFillKernel >> emitCoverageGivenInterior: aBooleanId [
	"The coverage of this pixel for this entry: one where the reference says the entry covers the
	 whole of the tile, and the walk over the shapes where it does not. The walk samples fifteen
	 sub-rows of the pixel and scans the edges of every shape of the entry at each of them, so a
	 tile deep inside a shape pays all of that for an answer that was one from the start. Which
	 shapes are antialiased is read once a pixel and not once a sub-row."

	self store: (self constantFloat: 0) into: #coverage.
	builder emitIf: aBooleanId then: [
		self store: (self constantFloat: 1) into: #coverage ].
	builder emitIf: (self negation: aBooleanId) then: [
		self emitHasAntialiasedShape.
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

{ #category : 'emitting' }
VGTiledFillKernel >> emitEntry [
	"One fill of this tile at this pixel: its header, its clip, the rectangle of its mask, the
	 pixel its paint lays down here, the coverage of the walk over it and the composition of the
	 two into the destination.
	 The reference holds the identifier of the entry, counting from one as VGTiledFillEncoding
	 writes it, and in its top bit the mark that says the entry covers the whole of this tile.
	 Beside it, under the same index, rides the block of shape records this tile is to read for
	 that entry: the records of the row of tiles this tile lies in, each naming only the edges
	 of its shape that reach the rows of that row. An edge whose own rows miss this tile cannot
	 cross a sub-row of it, so the short run and the whole shape give the same coverage.
	 A pixel the paint lays nothing down at is left alone, which the subset may do because every
	 operator in it is bounded, and which is what the software rasteriser does with the nil a
	 paint answers.
	 The mask scales the coverage after the alpha of the fill does, which is the order
	 VGTiledFillRasteriser scales them in and the order the software backend scales a blit in;
	 an entry that carries no mask answers full alpha and scaling by that leaves a byte as it
	 was, so one path serves a fill and a blit alike.
	 The paint and the composition are emitted by VGTiledFillPixelEmitter, which shares this
	 module while I emit this entry; the walk over the edges between them is my own."

	| reference identifier previous mask pixels at |
	pixels := VGTiledFillPixelEmitter on: self.
	at := self
		      sumOfWord: (self valueNamed: #referenceOffset)
		      and: (self load: #reference).
	reference := self elementOf: #entryRefs at: at.
	self
		remember: (self elementOf: #refShapes at: at)
		as: #shapeOffset.
	identifier := self
		              bitsOfWord: reference
		              and:
		              (self constantWord:
				               VGTiledFillLayout referenceIdentifierMask).
	previous := self
		            differenceOfWord: identifier
		            and: (self constantWord: 1).
	self
		rememberHeaderAt: (self
				 productOfWord: previous
				 and: (self constantWord: VGTiledFillLayout entryHeaderWords)).
	self
		rememberClipAt: (self
				 productOfWord: previous
				 and: (self constantWord: VGTiledFillLayout clipFloats)).
	self
		rememberMaskRectAt: (self
				 productOfWord: previous
				 and: (self constantWord: VGTiledFillLayout clipFloats)).
	pixels emitSource.
	self emitCoverageGivenInterior: (self emitIsInteriorReference: reference).
	mask := pixels emitMaskForCoverage: (self load: #coverage).
	mask := pixels emitScaleOfByte: mask by: self emitMaskByte.
	builder
		emitIf: (self
				 both: (self word: (self constantWord: 0) below: mask)
				 and: (self word: (self constantWord: 0) below: (self load: #hasSource)))
		then: [ pixels emitCompositeWithMask: mask ]
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
VGTiledFillKernel >> emitShapesDo: aBlock [
	"That block once for every shape of the entry, the fill first and the shapes of its clip
	 after it, with the record of the shape in hand. No shape loop of mine runs inside another,
	 so one counter serves them all."

	self store: (self constantWord: 0) into: #shape.
	builder
		emitWhile: [
		self word: (self load: #shape) below: (self valueNamed: #shapeCount) ]
		do: [
			self rememberShapeAt: (self
					 sumOfWord: (self valueNamed: #shapeOffset)
					 and: (self load: #shape)).
			aBlock value.
			self
				store: (self sumOfWord: (self load: #shape) and: (self constantWord: 1))
				into: #shape ]
]

{ #category : 'emitting' }
VGTiledFillKernel >> emitSpansOnSubRow: aSubRowId [
	"The parts of this pixel the entry covers inside its clip on that sub-row, trimmed to the
	 clip and to the pixel, which is VGTileCoverage >> spansAtX:onSubRow:do: and the two edges
	 it trims to. The aliased shapes gate the pixel and then leave the window alone; the
	 antialiased ones are swept together, and where there is none the whole window is covered."

	| left right |
	left := self
		        largerFloatOf: (self valueNamed: #pixelLeft)
		        and: (self valueNamed: #clipLeft).
	right := self
		         smallerFloatOf: (self
				          sumOfFloat: (self valueNamed: #pixelLeft)
				          and: (self constantFloat: 1))
		         and: (self valueNamed: #clipRight).
	builder emitIf: (self float: right above: left) then: [
		builder
			emitIf: (self emitAliasedShapesAllowPixelOnSubRow: aSubRowId)
			then: [
				| swept |
				swept := self
					         word: (self load: #hasAntialiased)
					         equals: (self constantWord: 1).
				builder emitIf: (self negation: swept) then: [
					self
						store: (self
								 sumOfFloat: (self load: #coverage)
								 and: (self differenceOfFloat: right and: left))
						into: #coverage ].
				builder
					emitIf: swept
					then: [ self emitSweepFrom: left to: right onSubRow: aSubRowId ] ] ]
]

{ #category : 'emitting' }
VGTiledFillKernel >> emitSweepFrom: aLeftId to: aRightId onSubRow: aSubRowId [
	"The parts of that window every antialiased shape calls inside, added to the coverage left
	 to right: VGTileCoverage >> sweepFrom:to:onSubRow:do:. A piece runs from where the last
	 shape lets it in to where the first one shuts it out, so a crossing that leaves the verdict
	 alone does not cut a piece in two and the sums are the same floats the software rasteriser
	 adds. Nothing is sorted and no crossing is kept: the verdict at a point is one scan of the
	 edges of each shape and the next crossing right of it is one more."

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
				self emitAddPieceFrom: (self load: #start) to: aRightId.
				self store: aRightId into: #cursor ].
			builder emitIf: (self negation: ends) then: [
				self
					store: (self emitIsInsideAllAt: next onSubRow: aSubRowId)
					into: #nextInside.
				builder emitIf: (self negation: (self
							  word: (self load: #nextInside)
							  equals: (self load: #inside))) then: [
					self emitAddPieceFrom: (self load: #start) to: next.
					builder
						emitIf: (self word: (self load: #inside) equals: (self constantWord: 0))
						then: [ self store: next into: #start ].
					self store: (self load: #nextInside) into: #inside ].
				self store: next into: #cursor ] ]
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
					 field: (VGTiledFillLayout perform: each))
			as: (each copyUpToLast: $F) asSymbol ]
]

{ #category : 'emitting' }
VGTiledFillKernel >> rememberHeaderAt: aBaseId [
	"The words of the header of one entry that I read, read once for the whole walk over it.
	 What a shape of the entry is read under is not among them: a fill and a shape of its clip
	 each carry their own record. Nor is the start of the whole-shape run of the entry, which
	 the header does carry and which a backend replaying a frame off the buffers alone reads: a
	 reference of this tile names the block of records of its own row of tiles instead."

	#( #sourcePixelField #operatorField #alphaByteField #shapeCountField
	   #paintTagField #paintBlockOffsetField #stopOffsetField #stopCountField
	   #maskOffsetField ) do: [ :each |
		self
			remember: (self
					 elementOf: #headers
					 atBase: aBaseId
					 field: (VGTiledFillLayout perform: each))
			as: (each copyUpToLast: $F) asSymbol ]
]

{ #category : 'emitting' }
VGTiledFillKernel >> rememberMaskRectAt: aBaseId [
	"The four sides of the rectangle of the mask of one entry. A mask rectangle is laid out as a
	 clip rectangle, so the field constants of a clip name its fields, and the names these are
	 remembered under are their own because a pixel is tested against both rectangles."

	#( #clipLeftField #clipTopField #clipRightField #clipBottomField )
		with: #( #maskLeft #maskTop #maskRight #maskBottom )
		do: [ :field :name |
			self
				remember: (self
						 elementOf: #maskRects
						 atBase: aBaseId
						 field: (VGTiledFillLayout perform: field))
				as: name ]
]

{ #category : 'emitting' }
VGTiledFillKernel >> rememberShapeAt: aShapeId [
	"The record of one shape of the entry, kept in variables and not as values, because the walk
	 reads another shape at every turn of its shape loop. The fill is the first shape of an entry
	 and a shape of its clip is read in exactly the same way."

	| base |
	base := self
		        productOfWord: aShapeId
		        and: (self constantWord: VGTiledFillLayout shapeRecordWords).
	#( #shapeEdgeOffsetField #shapeEdgeCountField #shapeFillRuleField
	   #shapeAliasedField ) do: [ :each |
		self
			store: (self
					 elementOf: #shapes
					 atBase: base
					 field: (VGTiledFillLayout perform: each))
			into: (each copyUpToLast: $F) asSymbol ]
]

{ #category : 'initialization' }
VGTiledFillKernel >> setTileExtent: anExtent [
	tileExtent := anExtent
]

{ #category : 'accessing' }
VGTiledFillKernel >> tileExtent [
	^ tileExtent
]
