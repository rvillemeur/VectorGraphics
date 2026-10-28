"
One recorded frame of the tiled fill subset, written out as the flat buffers a dispatch uploads: one buffer a binding of `VGTiledFillKernel`, held by `VGTiledFillBuffers`, which knows how large each of them is and nothing of what a record inside one holds. The words and the floats are kept in buffers of their own so that a kernel never bitcasts one into the other. The layout is class-side and nowhere else — one method a stride, one method a field — so the kernel of the next step and the writer here read the same names. Coordinates narrow to single floats here, because that is what the device computes in.

I also decode myself. `grid`, `touchedTileIndexes`, `touchedTileCount`, `binnedEntryCount` and `entriesOfTileAt:` are the five messages `VGTiledFillRasteriser` sends whatever it draws, and `entriesOfTileAt:` rebuilds its entries out of the buffers alone, as `VGFillEntry` holding a `VGPixelPaint`. So the rasteriser of the first step draws a frame from the encoding and from nothing else, and a test holds the layout against the same frame narrowed to single floats before any kernel exists. A header carries the premultiplied source pixel, the operator code, the fill rule code, the aliased flag, the alpha byte and the window of edges; a tile record carries the tile, its corner in whole pixels and the window of entry references, in tile order, so a row is found by a halving search here and handed to a workgroup there.

The frame is encoded for one surface format, which `targetFormat` names: the source pixel and the alpha byte are quantised while they are written.
"
Class {
	#name : 'VGTiledFillEncoding',
	#superclass : 'Object',
	#instVars : [
		'grid',
		'buffers',
		'decoder',
		'bands'
	],
	#category : 'VectorGraphics-Vulkan-Tiles',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Tiles'
}

{ #category : 'codes' }
VGTiledFillEncoding class >> aliasedName [
	"Cairo's #none mode, which is the only antialiasing mode that changes what the rasteriser
	 does: the other six ask for antialiasing of one quality or another."
	^ #none
]

{ #category : 'codes' }
VGTiledFillEncoding class >> antialiasAtFlag: aFlag [
	^ aFlag = (self flagForAliased: true)
		  ifTrue: [ self aliasedName ]
		  ifFalse: [ self antialiasedName ]
]

{ #category : 'codes' }
VGTiledFillEncoding class >> antialiasedName [
	"The mode every entry that is not aliased is decoded under. The six antialiasing modes are
	 sampled the same way, so the buffer carries the distinction the rasteriser makes and not
	 the one Cairo's enumeration makes."
	^ #default
]

{ #category : 'codes' }
VGTiledFillEncoding class >> codeForFillRule: aSymbol [
	^ self fillRuleNames indexOf: aSymbol
]

{ #category : 'codes' }
VGTiledFillEncoding class >> codeForOperator: anOperator [
	^ (self operatorTable detect: [ :each | each value = anOperator ]) key
]

{ #category : 'codes' }
VGTiledFillEncoding class >> fillRuleAtCode: aCode [
	^ self fillRuleNames at: aCode
]

{ #category : 'codes' }
VGTiledFillEncoding class >> fillRuleNames [
	"The two rules a fill can be drawn under, and the order is the order of their codes."
	^ #( #winding #evenOdd )
]

{ #category : 'codes' }
VGTiledFillEncoding class >> flagForAliased: aBoolean [
	^ aBoolean asBit
]

{ #category : 'codes' }
VGTiledFillEncoding class >> fullAlphaByte [
	"The alpha byte of a fill faded by nothing at all, and the divisor that reads a byte back as
	 the alpha it stands for. The format keeps a channel as a sixteen-bit short and stores its
	 top byte, so two hundred and fifty-seven times a byte, shifted down by eight, is that byte
	 again: a byte read back this way quantises to itself."
	^ 255
]

{ #category : 'layout' }
VGTiledFillEncoding class >> gradientClassAtTag: aCode [
	"The gradient paint class that goes by that tag, asked of the classes themselves rather than
	 read from a table of mine, so a gradient added to the hierarchy needs no edit here."

	^ VGGradientPaint allSubclasses detect: [ :each | each paintTag = aCode ]
]

{ #category : 'layout' }
VGTiledFillEncoding class >> maskBytesShownPerEntry [
	"How many alpha bytes of a mask the Masks tab lists beside the count of them. A glyph mask
	 carries hundreds and a row of a table holds a few."

	^ 8
]

{ #category : 'instance creation' }
VGTiledFillEncoding class >> of: aDisplayList extent: anExtent [
	"The frame of a surface of that extent, binned over a grid of the default tile size and
	 encoded."
	^ self on: (VGTileBinning of: aDisplayList extent: anExtent)
]

{ #category : 'instance creation' }
VGTiledFillEncoding class >> of: aDisplayList grid: aGrid [
	^ self on: (VGTileBinning of: aDisplayList grid: aGrid)
]

{ #category : 'instance creation' }
VGTiledFillEncoding class >> on: aBinning [
	"The frame a binning holds, written out as buffers."
	^ self new setBinning: aBinning
]

{ #category : 'codes' }
VGTiledFillEncoding class >> operatorAtCode: aCode [
	^ (self operatorTable detect: [ :each | each key = aCode ]) value
]

{ #category : 'codes' }
VGTiledFillEncoding class >> operatorTable [
	"The code each operator of the subset goes by. The operators are the rasteriser's own list,
	 so the subset is stated in one place, and the codes run from one, which leaves zero
	 standing for a word never written."
	^ VGTiledFillRasteriser supportedOperators withIndexCollect: [ :each :index |
		  index -> each ]
]

{ #category : 'codes' }
VGTiledFillEncoding class >> targetFormat [
	"The one surface format a frame is encoded for. The source pixel and the alpha byte of a
	 header are quantised here, so a target of any other format belongs to the software backend,
	 which is what the backend checks before it hands a frame to a device."
	^ VGCairoSurfaceFormat argb32
]

{ #category : 'private' }
VGTiledFillEncoding >> allocateBuffersFor: aCollection offsets: aDictionary [
	"The buffers one frame rides to the device in, sized by the entries it holds and by the
	 totals the offsets end in. How large each of them is for those counts belongs to
	 VGTiledFillBuffers, which knows their sizes and nothing of what a record holds; what goes
	 inside one is mine. The shape and the edge buffer carry the band blocks after the whole
	 shapes, so the bands are told where theirs begin."

	buffers := VGTiledFillBuffers new.
	buffers
		allocateForEntries: aCollection size
		edges: (aDictionary at: #edges) last + bands edgeCount
		stops: (aDictionary at: #stops) last
		masks: (aDictionary at: #maskBytes) last.
	buffers allocateForShapes:
		(aDictionary at: #shapes) last + bands blockCount.
	bands shapeBase: (aDictionary at: #shapes) last.
	decoder := VGTiledFillDecoder on: buffers
]

{ #category : 'tiles' }
VGTiledFillEncoding >> binnedEntryCount [
	^ buffers entryRefs size
]

{ #category : 'accessing' }
VGTiledFillEncoding >> clips [
	^ buffers clips
]

{ #category : 'accessing' }
VGTiledFillEncoding >> decoder [
	"The reader of the buffers I wrote. What a record holds is stated once on each side: I know
	 where every field goes and it knows how to read one back."

	^ decoder
]

{ #category : 'accessing' }
VGTiledFillEncoding >> edgeCount [
	^ buffers edges size / VGTiledFillLayout edgeFloats
]

{ #category : 'accessing' }
VGTiledFillEncoding >> edges [
	^ buffers edges
]

{ #category : 'decoding' }
VGTiledFillEncoding >> entriesOfTileAt: anIndex [
	"The entries of that tile, rebuilt from the buffers and in the order the references hold
	 them. A tile the frame does not touch has no record and no entry. The identifier is read
	 out of the reference, because the reference also carries the interior flag."

	| row base |
	row := self rowOfTileAt: anIndex.
	row ifNil: [ ^ #(  ) ].
	base := (row - 1) * VGTiledFillLayout tileRecordWords.
	^ (1 to: (buffers tileTable at: base + VGTiledFillLayout referenceCountField)) collect: [
		  :position |
		  self entryAt: (VGTiledFillLayout identifierOfReference:
				   (buffers entryRefs
					    at:
					    (buffers tileTable at: base + VGTiledFillLayout referenceOffsetField)
					    + position)) ]
]

{ #category : 'decoding' }
VGTiledFillEncoding >> entryAt: anIndex [
	^ decoder entryAt: anIndex
]

{ #category : 'accessing' }
VGTiledFillEncoding >> entryCount [
	^ buffers headers size / VGTiledFillLayout entryHeaderWords
]

{ #category : 'accessing' }
VGTiledFillEncoding >> entryRefs [
	^ buffers entryRefs
]

{ #category : 'reporting' }
VGTiledFillEncoding >> entryRows [
	"Every header beside the entry it decodes to, so that the words and their meaning are read
	 together. Each row asks the decoder rather than restating the layout, and the count of
	 shapes is the fill and the shapes of its clip together."

	^ (1 to: self entryCount) collect: [ :index |
		  | base entry |
		  base := (index - 1) * VGTiledFillLayout entryHeaderWords.
		  entry := self entryAt: index.
		  {
			  index.
			  (buffers headers at: base + VGTiledFillLayout sourcePixelField) printStringHex.
			  entry operator.
			  entry segments fillRule.
			  entry segments isAliased.
			  (buffers headers at: base + VGTiledFillLayout alphaByteField).
			  (buffers headers at: base + VGTiledFillLayout shapeCountField).
			  entry clip bounds } ]
]

{ #category : 'accessing' }
VGTiledFillEncoding >> grid [
	^ grid
]

{ #category : 'accessing' }
VGTiledFillEncoding >> headers [
	^ buffers headers
]

{ #category : 'inspecting' }
VGTiledFillEncoding >> inspectorEntries: aBuilder [
	<inspectorPresentationOrder: 11 title: 'Entries'>
	"Every header of the frame, decoded: the premultiplied pixel, the operator, the fill rule,
	 whether the fill is aliased, the alpha byte the mask is scaled by, how many shapes it is read through
	 and the clip rectangle it is trimmed to."
	^ aBuilder newTable
		  addColumn: (SpStringTableColumn
				   title: 'Entry'
				   evaluated: [ :each | (each at: 1) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Pixel'
				   evaluated: [ :each | each at: 2 ]);
		  addColumn: (SpStringTableColumn
				   title: 'Operator'
				   evaluated: [ :each | (each at: 3) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Fill rule'
				   evaluated: [ :each | (each at: 4) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Aliased'
				   evaluated: [ :each | (each at: 5) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Alpha byte'
				   evaluated: [ :each | (each at: 6) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Shapes'
				   evaluated: [ :each | (each at: 7) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Clip'
				   evaluated: [ :each | (each at: 8) printString ]);
		  items: self entryRows;
		  yourself
]

{ #category : 'inspecting' }
VGTiledFillEncoding >> inspectorEntriesContext: aContext [
	aContext active: buffers isNotNil
]

{ #category : 'inspector' }
VGTiledFillEncoding >> inspectorMasks: aBuilder [
	<inspectorPresentationOrder: 14 title: 'Masks'>
	"The mask buffers as the kernel reads them: the rectangle written for each entry and the
	 bytes that lie under it, read back out of the buffers themselves. An entry that carries no
	 mask has an empty rectangle and no bytes at all, which is how one code path draws a fill and
	 a blit alike."

	^ aBuilder newTable
		  addColumn: (SpStringTableColumn
				   title: 'Entry'
				   evaluated: [ :each | (each at: 1) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Rectangle'
				   evaluated: [ :each | (each at: 2) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Bytes'
				   evaluated: [ :each | (each at: 3) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Alphas'
				   evaluated: [ :each | (each at: 4) printString ]);
		  items: self maskRows;
		  yourself
]

{ #category : 'inspector' }
VGTiledFillEncoding >> inspectorMasksContext: aContext [
	aContext active: buffers isNotNil
]

{ #category : 'inspector' }
VGTiledFillEncoding >> inspectorPaints: aBuilder [
	<inspectorPresentationOrder: 12 title: 'Paints'>
	"Every paint of the frame read back out of the paint buffer: the class its tag resolves to,
	 the tag itself, the extend mode, the number of stops, the matrix and the type-specific
	 fields of its block."
	^ aBuilder newTable
		  addColumn: (SpStringTableColumn
				   title: 'Entry'
				   evaluated: [ :each | (each at: 1) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Paint'
				   evaluated: [ :each | each at: 2 ]);
		  addColumn: (SpStringTableColumn
				   title: 'Tag'
				   evaluated: [ :each | (each at: 3) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Extend'
				   evaluated: [ :each | (each at: 4) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Stops'
				   evaluated: [ :each | (each at: 5) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Matrix'
				   evaluated: [ :each | (each at: 6) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Geometry'
				   evaluated: [ :each | (each at: 7) printString ]);
		  items: self paintRows;
		  yourself
]

{ #category : 'inspector' }
VGTiledFillEncoding >> inspectorPaintsContext: aContext [
	aContext active: buffers isNotNil
]

{ #category : 'inspector' }
VGTiledFillEncoding >> inspectorStops: aBuilder [
	<inspectorPresentationOrder: 13 title: 'Stops'>
	"The stop buffer as the kernel searches it: the entry a stop belongs to, its place in that
	 entry, its offset, its four unpremultiplied channels and the premultiplied pixel they
	 quantise to. The tab is empty where no paint of the frame carries a stop."
	^ aBuilder newTable
		  addColumn: (SpStringTableColumn
				   title: 'Entry'
				   evaluated: [ :each | (each at: 1) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Stop'
				   evaluated: [ :each | (each at: 2) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Offset'
				   evaluated: [ :each | (each at: 3) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Channels'
				   evaluated: [ :each | (each at: 4) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Pixel'
				   evaluated: [ :each | (each at: 5) printStringHex ]);
		  items: self stopRows;
		  yourself
]

{ #category : 'inspector' }
VGTiledFillEncoding >> inspectorStopsContext: aContext [
	aContext active: buffers isNotNil
]

{ #category : 'inspecting' }
VGTiledFillEncoding >> inspectorTileTable: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Tile table'>
	"The tile table as it was written: which tile each row owns, where that tile starts in whole
	 pixels, and the window of entry references inside it."
	^ aBuilder newTable
		  addColumn: (SpStringTableColumn
				   title: 'Tile'
				   evaluated: [ :each | (each at: 1) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Corner'
				   evaluated: [ :each | (each at: 2) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'References from'
				   evaluated: [ :each | (each at: 3) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'References'
				   evaluated: [ :each | (each at: 4) printString ]);
		  items: self tileTableRows;
		  yourself
]

{ #category : 'inspecting' }
VGTiledFillEncoding >> inspectorTileTableContext: aContext [
	aContext active: buffers isNotNil
]

{ #category : 'writing' }
VGTiledFillEncoding >> maskByteCountOf: anEntry [
	"The alpha bytes the mask of an entry takes, which an entry that is not a blit has none of."

	^ anEntry tiledMaskBytes size
]

{ #category : 'accessing' }
VGTiledFillEncoding >> maskBytes [
	^ buffers maskBytes
]

{ #category : 'accessing' }
VGTiledFillEncoding >> maskRects [
	^ buffers maskRects
]

{ #category : 'inspecting' }
VGTiledFillEncoding >> maskRows [
	"One entry a row, with the rectangle and the bytes of its mask read back out of the mask
	 buffers. The bytes are counted and the first of them listed, because a glyph carries
	 hundreds and a row of a table holds a few."

	^ (1 to: self entryCount) collect: [ :index |
		  | bytes |
		  bytes := decoder maskBytesOfEntryAt: index.
		  {
			  index.
			  (decoder maskRectangleOfEntryAt: index).
			  bytes size.
			  (bytes first: (bytes size min: self class maskBytesShownPerEntry)) } ]
]

{ #category : 'initialization' }
VGTiledFillEncoding >> offsetsFor: aCollection by: aBlock [
	"The running total of aBlock over the entries: where each entry starts in the buffer that
	 holds that thing. It answers one number more than there are entries, the last being the
	 total, which is the size the buffer is allocated at."

	| offsets total |
	offsets := Array new: aCollection size + 1.
	total := 0.
	aCollection withIndexDo: [ :each :index |
		offsets at: index put: total.
		total := total + (aBlock value: each) ].
	offsets at: aCollection size + 1 put: total.
	^ offsets
]

{ #category : 'writing' }
VGTiledFillEncoding >> offsetsOf: aCollection [
	"Where every entry starts in each of the four buffers whose records are counted over the
	 whole frame and not one an entry, by the name of that buffer. Each answer holds one number
	 more than there are entries, the last being the total the buffer is allocated at."

	^ Dictionary newFrom: {
		  (#edges -> (self offsetsFor: aCollection by: [ :each |
			    self totalEdgeCountOf: each ])).
		  (#shapes -> (self offsetsFor: aCollection by: [ :each |
			    self shapeCountOf: each ])).
		  (#stops -> (self offsetsFor: aCollection by: [ :each |
			    self stopCountOf: each ])).
		  (#maskBytes -> (self offsetsFor: aCollection by: [ :each |
			    self maskByteCountOf: each ])) }
]

{ #category : 'inspecting' }
VGTiledFillEncoding >> paintRows [
	"Every paint of the frame as the buffers describe it: the class the tag resolves to, the
	 extend mode, how many stops it carries, and the two halves of its block that mean something
	 to a reader - the matrix and the type-specific fields, which are the ones after the filter.
	 Each row asks the decoder and the paint for the name of a code, so nothing here restates the
	 layout."

	^ (1 to: self entryCount) collect: [ :index |
		  | base paint block |
		  base := (index - 1) * VGTiledFillLayout entryHeaderWords.
		  paint := decoder paintOfEntryAt: index.
		  block := decoder blockOfEntryAt: index.
		  {
			  index.
			  paint class name.
			  (buffers headers at: base + VGTiledFillLayout paintTagField).
			  (VGPaint extendFor: (block at: VGPaint extendFieldIndex) truncated).
			  (buffers headers at: base + VGTiledFillLayout stopCountField).
			  (VGPaint matrixFieldIndices collect: [ :field | block at: field ]).
			  ((VGPaint filterFieldIndex + 1 to: VGTiledFillLayout paintBlockFloats)
				   collect: [ :field | block at: field ]) } ]
]

{ #category : 'accessing' }
VGTiledFillEncoding >> paints [
	^ buffers paints
]

{ #category : 'printing' }
VGTiledFillEncoding >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPut: $(;
		print: self entryCount;
		nextPutAll: ' entries, ';
		print: self edgeCount;
		nextPutAll: ' edges, ';
		print: self touchedTileCount;
		nextPutAll: ' tiles)'
]

{ #category : 'accessing' }
VGTiledFillEncoding >> refShapes [
	^ buffers refShapes
]

{ #category : 'tiles' }
VGTiledFillEncoding >> rowOfTileAt: anIndex [
	"The row of the table that owns that tile, or nil. The records are written in tile order, so
	 a halving search finds one; on the device no search happens at all, because a workgroup is
	 handed the row it owns."
	| low high |
	low := 1.
	high := self touchedTileCount.
	[ low <= high ] whileTrue: [
		| middle found |
		middle := low + high // 2.
		found := buffers tileTable at:
			         (middle - 1) * VGTiledFillLayout tileRecordWords
			         + VGTiledFillLayout tileIndexField.
		found = anIndex ifTrue: [ ^ middle ].
		found < anIndex
			ifTrue: [ low := middle + 1 ]
			ifFalse: [ high := middle - 1 ] ].
	^ nil
]

{ #category : 'private' }
VGTiledFillEncoding >> setBinning: aBinning [
	"Write the frame out: a header, a clip rectangle, a mask rectangle, a paint block, a run of
	 shapes, a run of edges, a run of stops and a run of mask bytes for every entry, then the
	 blocks of shape records its rows of tiles read, then the table of the tiles it touches and
	 the references into it. Every entry is written as the fill it is drawn as, which for a blit
	 is a fill of its own narrowed clip carrying the alpha of its mask, so the buffers describe
	 one kind of entry and the kernel reads one kind. The entries are the binnings own copy of
	 the display list, so nothing here reads a frame that has already drained, and the tiles are
	 written from the binning itself, which knows the entries it binned and not the fills they
	 became."

	| entries offsets |
	grid := aBinning grid.
	entries := aBinning entries collect: [ :each | each asTiledFill ].
	bands := VGTiledFillBands binning: aBinning fills: entries.
	offsets := self offsetsOf: entries.
	self allocateBuffersFor: entries offsets: offsets.
	entries withIndexDo: [ :each :index |
		self writeEntry: each at: index offsets: offsets ].
	self writeBandBlocksAt: offsets.
	self writeTilesOf: aBinning
]

{ #category : 'writing' }
VGTiledFillEncoding >> shapeCountOf: anEntry [
	^ (self shapesOf: anEntry) size
]

{ #category : 'accessing' }
VGTiledFillEncoding >> shapes [
	^ buffers shapes
]

{ #category : 'private' }
VGTiledFillEncoding >> shapesOf: anEntry [
	"The shapes of an entry, in the order its records are written in. VGTiledFillBands answers
	 them, because the blocks it cuts into rows of tiles and the records written here must agree
	 about which shape is which."

	^ VGTiledFillBands shapesOf: anEntry
]

{ #category : 'accessing' }
VGTiledFillEncoding >> stopCount [
	^ buffers stops size / VGTiledFillLayout stopFloats
]

{ #category : 'initialization' }
VGTiledFillEncoding >> stopCountOf: anEntry [
	"The stops of a fill''s paint, which a paint that is not a gradient has none of."

	^ anEntry paint hasStops
		  ifTrue: [ anEntry paint stops size ]
		  ifFalse: [ 0 ]
]

{ #category : 'inspecting' }
VGTiledFillEncoding >> stopRows [
	"Every stop of every gradient of the frame, in the order the buffer holds them, with the
	 pixel its channels quantise to beside it. That pixel is the stop lookup table the kernel
	 searches, so a stop whose bytes drift from the software path is visible here."

	^ (1 to: self entryCount) inject: OrderedCollection new into: [ :rows :index |
		  | stopsOfEntry |
		  stopsOfEntry := decoder stopsOfEntryAt: index.
		  stopsOfEntry doWithIndex: [ :stop :ordinal |
			  rows add: {
					  index.
					  ordinal.
					  stop key.
					  stop value.
					  (self class targetFormat pixelForRgba: stop value) } ].
		  rows ]
]

{ #category : 'accessing' }
VGTiledFillEncoding >> stops [
	^ buffers stops
]

{ #category : 'accessing' }
VGTiledFillEncoding >> tileTable [
	^ buffers tileTable
]

{ #category : 'inspecting' }
VGTiledFillEncoding >> tileTableRows [
	"The table as a workgroup reads it, one row a touched tile."
	^ (1 to: self touchedTileCount) collect: [ :row |
		  | base |
		  base := (row - 1) * VGTiledFillLayout tileRecordWords.
		  {
			  (buffers tileTable at: base + VGTiledFillLayout tileIndexField).
			  ((buffers tileTable at: base + VGTiledFillLayout tileLeftField)
			   @ (buffers tileTable at: base + VGTiledFillLayout tileTopField)).
			  (buffers tileTable at: base + VGTiledFillLayout referenceOffsetField).
			  (buffers tileTable at: base + VGTiledFillLayout referenceCountField) } ]
]

{ #category : 'writing' }
VGTiledFillEncoding >> totalEdgeCountOf: anEntry [
	"The edges of every shape of an entry, which is the room its run of the edge buffer takes.
	 The edges of the fill come first, so the offset of the entry is the offset of its fill too."

	^ (self shapesOf: anEntry) inject: 0 into: [ :total :shape |
		  total + (shape segments size / VGTiledFillLayout edgeFloats) ]
]

{ #category : 'tiles' }
VGTiledFillEncoding >> touchedTileCount [
	^ buffers tileTable size / VGTiledFillLayout tileRecordWords
]

{ #category : 'tiles' }
VGTiledFillEncoding >> touchedTileIndexes [
	"The tiles the frame touches, read from the table itself."
	^ (1 to: self touchedTileCount) collect: [ :row |
		  buffers tileTable at:
			  (row - 1) * VGTiledFillLayout tileRecordWords + VGTiledFillLayout tileIndexField ]
]

{ #category : 'private' }
VGTiledFillEncoding >> writeBandBlocksAt: aDictionary [
	"The band blocks: one block of shape records for every row of tiles an entry reaches, each
	 record naming only the edges of that shape which reach the rows of that row, and those
	 edges copied after the whole shapes in the edge buffer. An edge lying in two rows of tiles
	 is written in both of them, which is what buys the kernel a short run: an edge whose own
	 rows miss the rows of a tile cannot cross a sub-row of it, so a tile reading its own row
	 reads fewer edges for the same coverage. The blocks are written in the order
	 VGTiledFillBands lays them out, so a reference finds one by arithmetic and not by a search."

	| record cursor |
	record := (aDictionary at: #shapes) last.
	cursor := (aDictionary at: #edges) last.
	bands blocksDo: [ :index :row |
		(bands shapesOfEntry: index) withIndexDo: [ :shape :ordinal |
			| indexes |
			indexes := bands
				           edgeIndexesOfEntry: index
				           shape: ordinal
				           inRow: row.
			self
				writeShapeRecordAt: record
				for: shape
				edgeOffset: cursor
				count: indexes size.
			indexes do: [ :offset |
				1 to: VGTiledFillLayout edgeFloats do: [ :each |
					buffers edges
						at: cursor * VGTiledFillLayout edgeFloats + each
						put: (shape segments at: offset + each - 1) ].
				cursor := cursor + 1 ].
			record := record + 1 ] ]
]

{ #category : 'initialization' }
VGTiledFillEncoding >> writeClipOf: anEntry at: anIndex [
	"The clip of a fill in this subset is a rectangle, so its four sides are all of it."
	| base bounds |
	base := (anIndex - 1) * VGTiledFillLayout clipFloats.
	bounds := anEntry clip bounds.
	buffers clips at: base + VGTiledFillLayout clipLeftField put: bounds left.
	buffers clips at: base + VGTiledFillLayout clipTopField put: bounds top.
	buffers clips at: base + VGTiledFillLayout clipRightField put: bounds right.
	buffers clips at: base + VGTiledFillLayout clipBottomField put: bounds bottom
]

{ #category : 'writing' }
VGTiledFillEncoding >> writeEdgesOf: anEntry at: anOffset [
	"The coordinates of every shape of the entry, the fill first and the shapes of its clip
	 after it, each shape as its scanner holds them and in that order, narrowed to single floats
	 by the buffer itself."

	| cursor |
	cursor := anOffset * VGTiledFillLayout edgeFloats.
	(self shapesOf: anEntry) do: [ :shape |
		| coordinates |
		coordinates := shape segments.
		1 to: coordinates size do: [ :offset |
			buffers edges at: cursor + offset put: (coordinates at: offset) ].
		cursor := cursor + coordinates size ]
]

{ #category : 'writing' }
VGTiledFillEncoding >> writeEntry: anEntry at: anIndex offsets: aDictionary [
	"One entry into every buffer that holds a part of it, at the offsets the frame gave it."

	| edgeOffset |
	edgeOffset := (aDictionary at: #edges) at: anIndex.
	self
		writeHeaderOf: anEntry
		at: anIndex
		stopOffset: ((aDictionary at: #stops) at: anIndex).
	self
		writeShapesOf: anEntry
		at: anIndex
		shapeOffset: ((aDictionary at: #shapes) at: anIndex)
		edgeOffset: edgeOffset.
	self writeClipOf: anEntry at: anIndex.
	self writeEdgesOf: anEntry at: edgeOffset.
	self writePaintOf: anEntry at: anIndex stopOffset: ((aDictionary at: #stops) at: anIndex).
	self
		writeMaskOf: anEntry
		at: anIndex
		offset: ((aDictionary at: #maskBytes) at: anIndex)
]

{ #category : 'writing' }
VGTiledFillEncoding >> writeHeaderOf: anEntry at: anIndex stopOffset: aStopOffset [
	"What a kernel needs of one entry and nothing more. What a shape of the entry is read under
	 is not here: the fill and every shape of its clip carry their own record, and the header
	 says only where the run of them starts. A solid paint is sampled at the origin, because it
	 answers the same pixel everywhere and a pixel is less to read than a block; any other paint
	 is read from its block, and the tag says which."

	| base format |
	base := (anIndex - 1) * VGTiledFillLayout entryHeaderWords.
	format := self class targetFormat.
	buffers headers
		at: base + VGTiledFillLayout sourcePixelField
		put: (anEntry paint isSolid
				 ifTrue: [ anEntry paint pixelIn: format atX: 0 y: 0 ]
				 ifFalse: [ 0 ]).
	buffers headers
		at: base + VGTiledFillLayout operatorField
		put: (self class codeForOperator: anEntry operator).
	buffers headers
		at: base + VGTiledFillLayout alphaByteField
		put: (format shortByteOf: anEntry segments alpha).
	buffers headers
		at: base + VGTiledFillLayout paintTagField
		put: anEntry paint class paintTag.
	buffers headers at: base + VGTiledFillLayout paintBlockOffsetField put: anIndex - 1.
	buffers headers at: base + VGTiledFillLayout stopOffsetField put: aStopOffset.
	buffers headers
		at: base + VGTiledFillLayout stopCountField
		put: (self stopCountOf: anEntry)
]

{ #category : 'writing' }
VGTiledFillEncoding >> writeMaskBytes: aByteArray at: anOffset [
	"The alpha bytes of one mask into the buffer of words the kernel reads. The byte at position
	 p sits in the word p divided by the bytes a word holds, at the shift the remainder names,
	 which is the little-endian order the device reads that same word in. Each byte is written
	 once into a buffer that starts at zero, so a sum writes it."

	| perWord |
	perWord := VGTiledFillLayout maskBytesPerWord.
	1 to: aByteArray size do: [ :index |
		| position word |
		position := anOffset + index - 1.
		word := position // perWord + 1.
		buffers maskBytes
			at: word
			put: (buffers maskBytes at: word) + ((aByteArray at: index) bitShift:
					 position \\ perWord * VGTiledFillLayout maskByteBits) ]
]

{ #category : 'writing' }
VGTiledFillEncoding >> writeMaskOf: anEntry at: anIndex offset: anOffset [
	"The rectangle of an entry''s mask and the run of alpha bytes inside it. A mask rectangle is
	 laid out as a clip rectangle - four sides in the order left, top, right, bottom - so the
	 field constants of a clip name its fields too. An entry with no mask writes the empty
	 rectangle and no byte at all: the kernel tests a pixel against the rectangle and answers
	 full alpha outside it, and scaling a byte by full alpha leaves it as it was, so nothing else
	 has to mark the difference."

	| base rectangle |
	base := (anIndex - 1) * VGTiledFillLayout clipFloats.
	rectangle := anEntry tiledMaskRectangle.
	buffers maskRects at: base + VGTiledFillLayout clipLeftField put: rectangle left.
	buffers maskRects at: base + VGTiledFillLayout clipTopField put: rectangle top.
	buffers maskRects at: base + VGTiledFillLayout clipRightField put: rectangle right.
	buffers maskRects at: base + VGTiledFillLayout clipBottomField put: rectangle bottom.
	buffers headers
		at: (anIndex - 1) * VGTiledFillLayout entryHeaderWords
			+ VGTiledFillLayout maskOffsetField
		put: anOffset.
	self writeMaskBytes: anEntry tiledMaskBytes at: anOffset
]

{ #category : 'initialization' }
VGTiledFillEncoding >> writePaintOf: anEntry at: anIndex stopOffset: aStopOffset [
	"The coefficient block of the fill''s paint as the paint itself holds it, and its stops
	 beside it. The block is already a run of single floats, so it travels unchanged; a stop
	 carries its offset along the ramp and then its four unpremultiplied channels, which is how
	 the stop list keeps a colour and what an interpolation in the kernel needs."

	| base paint |
	base := (anIndex - 1) * VGTiledFillLayout paintBlockFloats.
	paint := anEntry paint.
	1 to: VGTiledFillLayout paintBlockFloats do: [ :field |
		buffers paints at: base + field put: (paint coefficients at: field) ].
	paint hasStops ifFalse: [ ^ self ].
	paint stops withIndexDo: [ :stop :index |
		| stopBase |
		stopBase := (aStopOffset + index - 1) * VGTiledFillLayout stopFloats.
		buffers stops at: stopBase + VGTiledFillLayout stopPositionField put: stop key.
		VGTiledFillLayout stopChannelFields doWithIndex: [ :field :channel |
			buffers stops at: stopBase + field put: (stop value at: channel) ] ]
]

{ #category : 'private' }
VGTiledFillEncoding >> writeShapeRecordAt: aRecord for: aShape edgeOffset: anEdgeOffset count: aCount [
	"One shape record: where its edges start, how many of them there are, the fill rule it is
	 read under and whether it is aliased. A whole shape and a shape narrowed to one row of
	 tiles are written by the same method, because the kernel reads one kind of record and the
	 count is the only thing that differs."

	| base |
	base := aRecord * VGTiledFillLayout shapeRecordWords.
	buffers shapes
		at: base + VGTiledFillLayout shapeEdgeOffsetField
		put: anEdgeOffset.
	buffers shapes at: base + VGTiledFillLayout shapeEdgeCountField put: aCount.
	buffers shapes
		at: base + VGTiledFillLayout shapeFillRuleField
		put: (self class codeForFillRule: aShape fillRule).
	buffers shapes
		at: base + VGTiledFillLayout shapeAliasedField
		put: (self class flagForAliased: aShape isAliased)
]

{ #category : 'private' }
VGTiledFillEncoding >> writeShapesOf: anEntry at: anIndex shapeOffset: aShapeOffset edgeOffset: anEdgeOffset [
	"The whole-shape run of one entry and the two header fields that find it. The kernel does
	 not read this run — a reference names a block of the entry's own row of tiles instead — but
	 a backend replaying a frame off the buffers alone reads the whole of every shape, and so
	 does the decoder, so it is written and it is where the edges of the entry lie."

	| base cursor |
	base := (anIndex - 1) * VGTiledFillLayout entryHeaderWords.
	buffers headers at: base + VGTiledFillLayout shapeOffsetField put: aShapeOffset.
	buffers headers
		at: base + VGTiledFillLayout shapeCountField
		put: (self shapeCountOf: anEntry).
	cursor := anEdgeOffset.
	(self shapesOf: anEntry) withIndexDo: [ :shape :ordinal |
		| count |
		count := shape segments size / VGTiledFillLayout edgeFloats.
		self
			writeShapeRecordAt: aShapeOffset + ordinal - 1
			for: shape
			edgeOffset: cursor
			count: count.
		cursor := cursor + count ]
]

{ #category : 'initialization' }
VGTiledFillEncoding >> writeTileRecordAt: aRow tile: aTileIndex offset: anOffset count: aCount [
	"Where the tile is and which references belong to it. The corner is in whole pixels, which
	 is what a workgroup adds its own invocation to."
	| base bounds |
	base := (aRow - 1) * VGTiledFillLayout tileRecordWords.
	bounds := grid boundsOfTileAt: aTileIndex.
	buffers tileTable at: base + VGTiledFillLayout tileIndexField put: aTileIndex.
	buffers tileTable at: base + VGTiledFillLayout tileLeftField put: bounds left.
	buffers tileTable at: base + VGTiledFillLayout tileTopField put: bounds top.
	buffers tileTable at: base + VGTiledFillLayout referenceOffsetField put: anOffset.
	buffers tileTable at: base + VGTiledFillLayout referenceCountField put: aCount
]

{ #category : 'private' }
VGTiledFillEncoding >> writeTilesOf: aBinning [
	"One record a touched tile, in tile order so that a row can be found by a halving search,
	 and the references of a tile in the order the entries were drawn, because compositing is
	 not commutative. A reference also carries the mark the binning made of the pair: the entry
	 covers the whole of this tile, so the kernel takes the coverage as one there. Beside each
	 reference goes the block of shape records that tile is to read for that entry, which is the
	 block of the row of tiles the tile lies in."

	| indexes identifiers offset |
	identifiers := IdentityDictionary new.
	aBinning entries withIndexDo: [ :each :index |
		identifiers at: each put: index ].
	indexes := aBinning touchedTileIndexes asSortedCollection asArray.
	buffers allocateForTiles: indexes size references: aBinning binnedEntryCount.
	offset := 0.
	indexes withIndexDo: [ :tileIndex :row |
		| tileEntries |
		tileEntries := aBinning entriesOfTileAt: tileIndex.
		self
			writeTileRecordAt: row
			tile: tileIndex
			offset: offset
			count: tileEntries size.
		tileEntries withIndexDo: [ :each :position |
			| identifier |
			identifier := identifiers at: each.
			buffers entryRefs
				at: offset + position
				put: (VGTiledFillLayout
						 referenceFor: identifier
						 interior: (aBinning isEntry: each interiorToTileAt: tileIndex)).
			buffers refShapes
				at: offset + position
				put: (bands blockOfEntry: identifier inRowOfTile: tileIndex) ].
		offset := offset + tileEntries size ]
]
