"
One recorded frame of the tiled fill subset, written out as the flat buffers a dispatch uploads: `tileTable`, `entryRefs` and `headers` of unsigned words, and `clips` and `edges` of single floats. The words and the floats are kept in buffers of their own so that a kernel never bitcasts one into the other. The layout is class-side and nowhere else — one method a stride, one method a field — so the kernel of the next step and the writer here read the same names. Coordinates narrow to single floats here, because that is what the device computes in.

I also decode myself. `grid`, `touchedTileIndexes`, `touchedTileCount`, `binnedEntryCount` and `entriesOfTileAt:` are the five messages `VGTiledFillRasteriser` sends whatever it draws, and `entriesOfTileAt:` rebuilds its entries out of the buffers alone, as `VGFillEntry` holding a `VGPixelPaint`. So the rasteriser of the first step draws a frame from the encoding and from nothing else, and a test holds the layout against the same frame narrowed to single floats before any kernel exists. A header carries the premultiplied source pixel, the operator code, the fill rule code, the aliased flag, the alpha byte and the window of edges; a tile record carries the tile, its corner in whole pixels and the window of entry references, in tile order, so a row is found by a halving search here and handed to a workgroup there.

The frame is encoded for one surface format, which `targetFormat` names: the source pixel and the alpha byte are quantised while they are written.
"
Class {
	#name : 'VGTiledFillEncoding',
	#superclass : 'Object',
	#instVars : [
		'grid',
		'tileTable',
		'entryRefs',
		'headers',
		'clips',
		'edges',
		'decoded'
	],
	#category : 'VectorGraphics-Vulkan-Tiles',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Tiles'
}

{ #category : 'layout' }
VGTiledFillEncoding class >> aliasedField [
	^ 4
]

{ #category : 'codes' }
VGTiledFillEncoding class >> aliasedName [
	"Cairo's #none mode, which is the only antialiasing mode that changes what the rasteriser
	 does: the other six ask for antialiasing of one quality or another."
	^ #none
]

{ #category : 'layout' }
VGTiledFillEncoding class >> alphaByteField [
	"The one byte the coverage of this fill is scaled by. A constant alpha reaches the mask as a
	 byte and never as anything finer, so the byte is all a frame has to carry."
	^ 5
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

{ #category : 'layout' }
VGTiledFillEncoding class >> clipBottomField [
	^ 4
]

{ #category : 'layout' }
VGTiledFillEncoding class >> clipFloats [
	"The floats one clip rectangle takes: its four sides, in the order left, top, right, bottom."
	^ 4
]

{ #category : 'layout' }
VGTiledFillEncoding class >> clipLeftField [
	^ 1
]

{ #category : 'layout' }
VGTiledFillEncoding class >> clipRightField [
	^ 3
]

{ #category : 'layout' }
VGTiledFillEncoding class >> clipTopField [
	^ 2
]

{ #category : 'codes' }
VGTiledFillEncoding class >> codeForFillRule: aSymbol [
	^ self fillRuleNames indexOf: aSymbol
]

{ #category : 'codes' }
VGTiledFillEncoding class >> codeForOperator: anOperator [
	^ (self operatorTable detect: [ :each | each value = anOperator ]) key
]

{ #category : 'layout' }
VGTiledFillEncoding class >> edgeCountField [
	^ 7
]

{ #category : 'layout' }
VGTiledFillEncoding class >> edgeFloats [
	"The floats one edge takes: its two ends, as x then y."
	^ 4
]

{ #category : 'layout' }
VGTiledFillEncoding class >> edgeOffsetField [
	"Where the edges of this entry start, counted in edges from the first edge of the buffer."
	^ 6
]

{ #category : 'layout' }
VGTiledFillEncoding class >> entryHeaderWords [
	"The words one entry of the header buffer takes. Seven carry meaning and the eighth is
	 padding: a power of two, so that a kernel reaches a header by a shift and not by a
	 multiplication."
	^ 8
]

{ #category : 'codes' }
VGTiledFillEncoding class >> fillRuleAtCode: aCode [
	^ self fillRuleNames at: aCode
]

{ #category : 'layout' }
VGTiledFillEncoding class >> fillRuleField [
	^ 3
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

{ #category : 'layout' }
VGTiledFillEncoding class >> operatorField [
	^ 2
]

{ #category : 'codes' }
VGTiledFillEncoding class >> operatorTable [
	"The code each operator of the subset goes by. The operators are the rasteriser's own list,
	 so the subset is stated in one place, and the codes run from one, which leaves zero
	 standing for a word never written."
	^ VGTiledFillRasteriser supportedOperators withIndexCollect: [ :each :index |
		  index -> each ]
]

{ #category : 'layout' }
VGTiledFillEncoding class >> referenceCountField [
	^ 5
]

{ #category : 'layout' }
VGTiledFillEncoding class >> referenceOffsetField [
	"Where the references of this tile start, counted from the first reference and not from one,
	 because the kernel indexes from zero."
	^ 4
]

{ #category : 'layout' }
VGTiledFillEncoding class >> sourcePixelField [
	"The premultiplied pixel the fill's paint answers, because the kernel carries a pixel and
	 not a paint."
	^ 1
]

{ #category : 'codes' }
VGTiledFillEncoding class >> targetFormat [
	"The one surface format a frame is encoded for. The source pixel and the alpha byte of a
	 header are quantised here, so a target of any other format belongs to the software backend,
	 which is what the backend checks before it hands a frame to a device."
	^ VGCairoSurfaceFormat argb32
]

{ #category : 'layout' }
VGTiledFillEncoding class >> tileIndexField [
	^ 1
]

{ #category : 'layout' }
VGTiledFillEncoding class >> tileLeftField [
	^ 2
]

{ #category : 'layout' }
VGTiledFillEncoding class >> tileRecordWords [
	"The words one tile of the table takes: which tile it is, where it starts in pixels, and the
	 window of entry references that belong to it."
	^ 5
]

{ #category : 'layout' }
VGTiledFillEncoding class >> tileTopField [
	^ 3
]

{ #category : 'initialization' }
VGTiledFillEncoding >> allocateBuffersFor: aCollection [
	"The three buffers an entry writes into, sized by the frame alone, and the edge each entry
	 starts at, which is the running total of the edges before it."
	| offsets edgeCount |
	offsets := Array new: aCollection size.
	edgeCount := 0.
	aCollection withIndexDo: [ :each :index |
		offsets at: index put: edgeCount.
		edgeCount := edgeCount
		             + (each segments coordinates size / self class edgeFloats) ].
	headers := WordArray new: aCollection size * self class entryHeaderWords.
	clips := Float32Array new: aCollection size * self class clipFloats.
	edges := Float32Array new: edgeCount * self class edgeFloats.
	^ offsets
]

{ #category : 'tiles' }
VGTiledFillEncoding >> binnedEntryCount [
	^ entryRefs size
]

{ #category : 'decoding' }
VGTiledFillEncoding >> clipOfEntryAt: anIndex [
	| base |
	base := (anIndex - 1) * self class clipFloats.
	^ Rectangle
		  left: (clips at: base + self class clipLeftField)
		  right: (clips at: base + self class clipRightField)
		  top: (clips at: base + self class clipTopField)
		  bottom: (clips at: base + self class clipBottomField)
]

{ #category : 'accessing' }
VGTiledFillEncoding >> clips [
	^ clips
]

{ #category : 'decoding' }
VGTiledFillEncoding >> coordinatesOfEntryAt: anIndex [
	"The edges of that entry as one flat array of ends, the single floats of the buffer widened
	 again unchanged."
	| base count start coordinates |
	base := (anIndex - 1) * self class entryHeaderWords.
	count := (headers at: base + self class edgeCountField)
	         * self class edgeFloats.
	start := (headers at: base + self class edgeOffsetField)
	         * self class edgeFloats.
	coordinates := Array new: count.
	1 to: count do: [ :offset |
		coordinates at: offset put: (edges at: start + offset) ].
	^ coordinates
]

{ #category : 'decoding' }
VGTiledFillEncoding >> decodeEntryAt: anIndex [
	"One entry out of the buffers and nothing else: this is what makes the step one rasteriser
	 draw from the encoding alone, and so what a test can hold the layout to before a kernel
	 exists."
	| base |
	base := (anIndex - 1) * self class entryHeaderWords.
	^ VGFillEntry
		  segments: (self segmentsOfEntryAt: anIndex)
		  paint:
		  (VGPixelPaint pixel:
			   (headers at: base + self class sourcePixelField))
		  clip: (VGClip bounds: (self clipOfEntryAt: anIndex))
		  operator:
		  (self class operatorAtCode:
			   (headers at: base + self class operatorField))
]

{ #category : 'accessing' }
VGTiledFillEncoding >> edgeCount [
	^ edges size / self class edgeFloats
]

{ #category : 'accessing' }
VGTiledFillEncoding >> edges [
	^ edges
]

{ #category : 'tiles' }
VGTiledFillEncoding >> entriesOfTileAt: anIndex [
	"The entries of that tile, rebuilt from the buffers and in the order the references hold
	 them. A tile the frame does not touch has no record and no entry."
	| row base |
	row := self rowOfTileAt: anIndex.
	row ifNil: [ ^ #(  ) ].
	base := (row - 1) * self class tileRecordWords.
	^ (1 to: (tileTable at: base + self class referenceCountField)) collect: [
		  :position |
		  self entryAt: (entryRefs
				   at: (tileTable at: base + self class referenceOffsetField) + position) ]
]

{ #category : 'decoding' }
VGTiledFillEncoding >> entryAt: anIndex [
	"The entry the buffers describe, rebuilt as a display list entry of the kind the rasteriser
	 draws. It is remembered, because a frame holds far fewer entries than tiles and every tile
	 the entry reaches asks for it again."
	^ decoded at: anIndex ifAbsentPut: [ self decodeEntryAt: anIndex ]
]

{ #category : 'accessing' }
VGTiledFillEncoding >> entryCount [
	^ headers size / self class entryHeaderWords
]

{ #category : 'accessing' }
VGTiledFillEncoding >> entryRefs [
	^ entryRefs
]

{ #category : 'inspecting' }
VGTiledFillEncoding >> entryRows [
	"Every header beside the entry it decodes to, so that the words and their meaning are read
	 together. Each row asks the decoder rather than restating the layout."
	^ (1 to: self entryCount) collect: [ :index |
		  | base entry |
		  base := (index - 1) * self class entryHeaderWords.
		  entry := self entryAt: index.
		  {
			  index.
			  (headers at: base + self class sourcePixelField) printStringHex.
			  entry operator.
			  entry segments fillRule.
			  entry segments isAliased.
			  (headers at: base + self class alphaByteField).
			  (headers at: base + self class edgeCountField).
			  entry clip bounds } ]
]

{ #category : 'accessing' }
VGTiledFillEncoding >> grid [
	^ grid
]

{ #category : 'accessing' }
VGTiledFillEncoding >> headers [
	^ headers
]

{ #category : 'inspecting' }
VGTiledFillEncoding >> inspectorEntries: aBuilder [
	<inspectorPresentationOrder: 11 title: 'Entries'>
	"Every header of the frame, decoded: the premultiplied pixel, the operator, the fill rule,
	 whether the fill is aliased, the alpha byte the mask is scaled by, how many edges it holds
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
				   title: 'Edges'
				   evaluated: [ :each | (each at: 7) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Clip'
				   evaluated: [ :each | (each at: 8) printString ]);
		  items: self entryRows;
		  yourself
]

{ #category : 'inspecting' }
VGTiledFillEncoding >> inspectorEntriesContext: aContext [
	aContext active: headers isNotNil
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
	aContext active: tileTable isNotNil
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
		found := tileTable at:
			         (middle - 1) * self class tileRecordWords
			         + self class tileIndexField.
		found = anIndex ifTrue: [ ^ middle ].
		found < anIndex
			ifTrue: [ low := middle + 1 ]
			ifFalse: [ high := middle - 1 ] ].
	^ nil
]

{ #category : 'decoding' }
VGTiledFillEncoding >> segmentsOfEntryAt: anIndex [
	"The path of that entry, under the fill rule, the antialiasing mode and the alpha its header
	 names. The alpha is the byte read back as the fraction of full alpha it stands for, which
	 quantises to that byte again."
	| base |
	base := (anIndex - 1) * self class entryHeaderWords.
	^ (VGSegments
		   coordinates: (self coordinatesOfEntryAt: anIndex)
		   fillRule:
		   (self class fillRuleAtCode: (headers at: base + self class fillRuleField))
		   antialias:
		   (self class antialiasAtFlag: (headers at: base + self class aliasedField)))
		  withAlpha:
		  (headers at: base + self class alphaByteField) / self class fullAlphaByte
]

{ #category : 'initialization' }
VGTiledFillEncoding >> setBinning: aBinning [
	"Write the frame out: a header, a clip rectangle and a run of edges for every entry, then
	 the table of the tiles it touches and the references into it. The entries are the binning's
	 own copy of the display list, so nothing here reads a frame that has already drained."
	| entries offsets |
	grid := aBinning grid.
	decoded := Dictionary new.
	entries := aBinning entries.
	offsets := self allocateBuffersFor: entries.
	entries withIndexDo: [ :each :index |
		self writeHeaderOf: each at: index edgeOffset: (offsets at: index).
		self writeClipOf: each at: index.
		self writeEdgesOf: each at: (offsets at: index) ].
	self writeTilesOf: aBinning
]

{ #category : 'accessing' }
VGTiledFillEncoding >> tileTable [
	^ tileTable
]

{ #category : 'inspecting' }
VGTiledFillEncoding >> tileTableRows [
	"The table as a workgroup reads it, one row a touched tile."
	^ (1 to: self touchedTileCount) collect: [ :row |
		  | base |
		  base := (row - 1) * self class tileRecordWords.
		  {
			  (tileTable at: base + self class tileIndexField).
			  ((tileTable at: base + self class tileLeftField)
			   @ (tileTable at: base + self class tileTopField)).
			  (tileTable at: base + self class referenceOffsetField).
			  (tileTable at: base + self class referenceCountField) } ]
]

{ #category : 'tiles' }
VGTiledFillEncoding >> touchedTileCount [
	^ tileTable size / self class tileRecordWords
]

{ #category : 'tiles' }
VGTiledFillEncoding >> touchedTileIndexes [
	"The tiles the frame touches, read from the table itself."
	^ (1 to: self touchedTileCount) collect: [ :row |
		  tileTable at:
			  (row - 1) * self class tileRecordWords + self class tileIndexField ]
]

{ #category : 'initialization' }
VGTiledFillEncoding >> writeClipOf: anEntry at: anIndex [
	"The clip of a fill in this subset is a rectangle, so its four sides are all of it."
	| base bounds |
	base := (anIndex - 1) * self class clipFloats.
	bounds := anEntry clip bounds.
	clips at: base + self class clipLeftField put: bounds left.
	clips at: base + self class clipTopField put: bounds top.
	clips at: base + self class clipRightField put: bounds right.
	clips at: base + self class clipBottomField put: bounds bottom
]

{ #category : 'initialization' }
VGTiledFillEncoding >> writeEdgesOf: anEntry at: anOffset [
	"The coordinates as the segments hold them, in the same order, narrowed to single floats by
	 the buffer itself."
	| base coordinates |
	base := anOffset * self class edgeFloats.
	coordinates := anEntry segments coordinates.
	1 to: coordinates size do: [ :offset |
		edges at: base + offset put: (coordinates at: offset) ]
]

{ #category : 'initialization' }
VGTiledFillEncoding >> writeHeaderOf: anEntry at: anIndex edgeOffset: anOffset [
	"What a kernel needs of one fill and nothing more. The paint is sampled at the origin
	 because the subset holds solid paints alone, which answer the same pixel everywhere."
	| base format |
	base := (anIndex - 1) * self class entryHeaderWords.
	format := self class targetFormat.
	headers
		at: base + self class sourcePixelField
		put: (anEntry paint pixelIn: format atX: 0 y: 0).
	headers
		at: base + self class operatorField
		put: (self class codeForOperator: anEntry operator).
	headers
		at: base + self class fillRuleField
		put: (self class codeForFillRule: anEntry segments fillRule).
	headers
		at: base + self class aliasedField
		put: (self class flagForAliased: anEntry segments isAliased).
	headers
		at: base + self class alphaByteField
		put: (format shortByteOf: anEntry segments alpha).
	headers at: base + self class edgeOffsetField put: anOffset.
	headers
		at: base + self class edgeCountField
		put: anEntry segments coordinates size / self class edgeFloats
]

{ #category : 'initialization' }
VGTiledFillEncoding >> writeTileRecordAt: aRow tile: aTileIndex offset: anOffset count: aCount [
	"Where the tile is and which references belong to it. The corner is in whole pixels, which
	 is what a workgroup adds its own invocation to."
	| base bounds |
	base := (aRow - 1) * self class tileRecordWords.
	bounds := grid boundsOfTileAt: aTileIndex.
	tileTable at: base + self class tileIndexField put: aTileIndex.
	tileTable at: base + self class tileLeftField put: bounds left.
	tileTable at: base + self class tileTopField put: bounds top.
	tileTable at: base + self class referenceOffsetField put: anOffset.
	tileTable at: base + self class referenceCountField put: aCount
]

{ #category : 'initialization' }
VGTiledFillEncoding >> writeTilesOf: aBinning [
	"One record a touched tile, in tile order so that a row can be found by a halving search,
	 and the references of a tile in the order the entries were drawn, because compositing is
	 not commutative."
	| indexes identifiers offset |
	identifiers := IdentityDictionary new.
	aBinning entries withIndexDo: [ :each :index |
		identifiers at: each put: index ].
	indexes := aBinning touchedTileIndexes asSortedCollection asArray.
	tileTable := WordArray new: indexes size * self class tileRecordWords.
	entryRefs := WordArray new: aBinning binnedEntryCount.
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
			entryRefs at: offset + position put: (identifiers at: each) ].
		offset := offset + tileEntries size ]
]
