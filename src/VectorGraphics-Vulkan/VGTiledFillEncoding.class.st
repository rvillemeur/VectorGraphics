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
		'buffers',
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

{ #category : 'constants' }
VGTiledFillEncoding class >> edgeEndXField [
	^ 3
]

{ #category : 'constants' }
VGTiledFillEncoding class >> edgeEndYField [
	^ 4
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

{ #category : 'constants' }
VGTiledFillEncoding class >> edgeStartXField [
	"The four floats one edge of a fill takes, in the order writeEdgesOf:at: writes them, which
	 is the order VGSegments holds a line in: the start, then the end."

	^ 1
]

{ #category : 'constants' }
VGTiledFillEncoding class >> edgeStartYField [
	^ 2
]

{ #category : 'layout' }
VGTiledFillEncoding class >> emptyMaskRectangle [
	"The rectangle an entry with no mask carries, and the rectangle a blit whose mask does not
	 meet its clip carries. Both read full alpha everywhere, because a pixel is tested against
	 the rectangle and this one holds none."

	^ 0 @ 0 corner: 0 @ 0
]

{ #category : 'layout' }
VGTiledFillEncoding class >> entryHeaderWords [
	"The words one entry of the header buffer takes. Eleven carry meaning and the rest is
	 padding: a power of two, so that a kernel reaches a header by a shift and not by a
	 multiplication."

	^ 16
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

{ #category : 'layout' }
VGTiledFillEncoding class >> gradientClassAtTag: aCode [
	"The gradient paint class that goes by that tag, asked of the classes themselves rather than
	 read from a table of mine, so a gradient added to the hierarchy needs no edit here."

	^ VGGradientPaint allSubclasses detect: [ :each | each paintTag = aCode ]
]

{ #category : 'codes' }
VGTiledFillEncoding class >> identifierOfReference: aWord [
	"The entry that reference names, counted from one, with the interior flag taken off."

	^ aWord bitAnd: self referenceIdentifierMask
]

{ #category : 'constants' }
VGTiledFillEncoding class >> interiorReferenceFlag [
	"The bit a reference word carries when the entry covers the whole of the tile it is a
	 reference of. It is the top bit of the word, which no identifier of a drawable frame can
	 reach: an entry count that high would need more memory for its headers alone than a device
	 has."

	^ 16r80000000
]

{ #category : 'codes' }
VGTiledFillEncoding class >> isInteriorReference: aWord [
	"Whether that reference says the entry covers the whole of its tile, so that the coverage of
	 every pixel of it is one."

	^ (aWord bitAnd: self interiorReferenceFlag) ~= 0
]

{ #category : 'layout' }
VGTiledFillEncoding class >> maskByteBits [
	"The bits one alpha byte of the mask buffer takes, which is the shift between two bytes of
	 one word."

	^ 8
]

{ #category : 'layout' }
VGTiledFillEncoding class >> maskBytesPerWord [
	"The alpha bytes of a mask that one word of the mask buffer holds. A storage buffer the
	 kernel reads holds words, so a byte at position p of the mask buffer sits in word p divided
	 by this one, at the shift the remainder names."

	^ 4
]

{ #category : 'layout' }
VGTiledFillEncoding class >> maskBytesShownPerEntry [
	"How many alpha bytes of a mask the Masks tab lists beside the count of them. A glyph mask
	 carries hundreds and a row of a table holds a few."

	^ 8
]

{ #category : 'layout' }
VGTiledFillEncoding class >> maskOffsetField [
	"Where the alpha bytes of this entry''s mask start, counted in bytes from the first byte of
	 the mask buffer. An entry with no mask leaves the field at zero and carries an empty
	 rectangle, which is what says it has none."

	^ 12
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
VGTiledFillEncoding class >> paintBlockFloats [
	"The floats one coefficient block takes. It is the paint ABI of rule 2 and not a number of
	 this class, so a paint that grows a field grows the buffer with it."

	^ VGPaint coefficientCount
]

{ #category : 'layout' }
VGTiledFillEncoding class >> paintBlockOffsetField [
	"Where the coefficient block of this fill starts, counted in blocks from the first block of
	 the buffer. Every entry writes a block of its own, so this is the entry index less one, and
	 the kernel reads the field rather than assuming that, because a later unit may let two
	 fills share one paint."

	^ 9
]

{ #category : 'layout' }
VGTiledFillEncoding class >> paintTagField [
	"How the kernel is to read the paint block of this fill. The code is the paint tag itself,
	 which is cairo_pattern_type_t, so a header and the pattern that built it carry the same
	 number and no table stands between them."

	^ 8
]

{ #category : 'layout' }
VGTiledFillEncoding class >> referenceCountField [
	^ 5
]

{ #category : 'codes' }
VGTiledFillEncoding class >> referenceFor: anIdentifier interior: aBoolean [
	"The reference word of that entry, marked or not. Both sides read this one place: the kernel
	 asks the flag of the word it loads and the decoder asks the identifier of the same word."

	^ aBoolean
		  ifTrue: [ anIdentifier bitOr: self interiorReferenceFlag ]
		  ifFalse: [ anIdentifier ]
]

{ #category : 'constants' }
VGTiledFillEncoding class >> referenceIdentifierMask [
	"The bits of a reference word that are the identifier of the entry, which is every bit but
	 the interior flag."

	^ self interiorReferenceFlag - 1
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

{ #category : 'layout' }
VGTiledFillEncoding class >> stopChannelFields [
	"Where the four channels of a stop sit, in the order a stop list keeps them."

	^ 2 to: 5
]

{ #category : 'layout' }
VGTiledFillEncoding class >> stopCountField [
	"How many stops this fill has. Zero stands both for a solid paint and for a gradient whose
	 stop list is empty, which Cairo draws as nothing at all, so the kernel needs no other mark
	 for either."

	^ 11
]

{ #category : 'layout' }
VGTiledFillEncoding class >> stopFloats [
	"The floats one stop takes: its offset along the ramp, then its four unpremultiplied
	 channels in the order red, green, blue, alpha."

	^ 5
]

{ #category : 'layout' }
VGTiledFillEncoding class >> stopOffsetField [
	"Where the stops of this fill start, counted in stops from the first stop of the buffer. A
	 paint with no stop list writes nothing there and leaves the count at zero."

	^ 10
]

{ #category : 'layout' }
VGTiledFillEncoding class >> stopPositionField [
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

{ #category : 'writing' }
VGTiledFillEncoding >> allocateBuffersFor: aCollection edges: anEdgeCount stops: aStopCount masks: aByteCount [
	"The buffers one frame rides to the device in. How large each of them is for that many
	 entries, edges, stops and mask bytes belongs to VGTiledFillBuffers, which knows their sizes
	 and nothing of what a record holds; what goes inside one is mine."

	buffers := VGTiledFillBuffers new.
	buffers
		allocateForEntries: aCollection size
		edges: anEdgeCount
		stops: aStopCount
		masks: aByteCount
]

{ #category : 'tiles' }
VGTiledFillEncoding >> binnedEntryCount [
	^ buffers entryRefs size
]

{ #category : 'decoding' }
VGTiledFillEncoding >> blockOfEntryAt: anIndex [
	"The coefficient block of that entry''s paint, the single floats of the buffer taken as they
	 stand: a paint keeps its block in single floats too, so nothing widens here."

	| base block |
	base := (buffers headers
	         at:
	         (anIndex - 1) * self class entryHeaderWords
	         + self class paintBlockOffsetField) * self class paintBlockFloats.
	block := Float32Array new: self class paintBlockFloats.
	1 to: self class paintBlockFloats do: [ :field |
		block at: field put: (buffers paints at: base + field) ].
	^ block
]

{ #category : 'decoding' }
VGTiledFillEncoding >> clipOfEntryAt: anIndex [
	| base |
	base := (anIndex - 1) * self class clipFloats.
	^ Rectangle
		  left: (buffers clips at: base + self class clipLeftField)
		  right: (buffers clips at: base + self class clipRightField)
		  top: (buffers clips at: base + self class clipTopField)
		  bottom: (buffers clips at: base + self class clipBottomField)
]

{ #category : 'accessing' }
VGTiledFillEncoding >> clips [
	^ buffers clips
]

{ #category : 'decoding' }
VGTiledFillEncoding >> coordinatesOfEntryAt: anIndex [
	"The edges of that entry as one flat array of ends, the single floats of the buffer widened
	 again unchanged."
	| base count start coordinates |
	base := (anIndex - 1) * self class entryHeaderWords.
	count := (buffers headers at: base + self class edgeCountField)
	         * self class edgeFloats.
	start := (buffers headers at: base + self class edgeOffsetField)
	         * self class edgeFloats.
	coordinates := Array new: count.
	1 to: count do: [ :offset |
		coordinates at: offset put: (buffers edges at: start + offset) ].
	^ coordinates
]

{ #category : 'reading' }
VGTiledFillEncoding >> decodeEntryAt: anIndex [
	"One entry out of the buffers and nothing else: this is what makes the step one rasteriser
	 draw from the encoding alone, and so what a test can hold the layout to before a kernel
	 exists. An entry whose mask rectangle is empty carries no mask and is the fill it looks
	 like; one with a rectangle is the masked fill a blit was written as."

	| base fill rectangle |
	base := (anIndex - 1) * self class entryHeaderWords.
	fill := VGFillEntry
		        segments: (self segmentsOfEntryAt: anIndex)
		        paint: (self paintOfEntryAt: anIndex)
		        clip: (VGClip bounds: (self clipOfEntryAt: anIndex))
		        operator:
		        (self class operatorAtCode:
			         (buffers headers at: base + self class operatorField)).
	rectangle := self maskRectangleOfEntryAt: anIndex.
	rectangle = self class emptyMaskRectangle ifTrue: [ ^ fill ].
	^ VGMaskedFillEntry
		  fill: fill
		  bytes: (self maskBytesOfEntryAt: anIndex)
		  over: rectangle
]

{ #category : 'accessing' }
VGTiledFillEncoding >> edgeCount [
	^ buffers edges size / self class edgeFloats
]

{ #category : 'initialization' }
VGTiledFillEncoding >> edgeCountOf: anEntry [
	^ anEntry segments coordinates size / self class edgeFloats
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
	base := (row - 1) * self class tileRecordWords.
	^ (1 to: (buffers tileTable at: base + self class referenceCountField)) collect: [
		  :position |
		  self entryAt: (self class identifierOfReference:
				   (buffers entryRefs
					    at:
					    (buffers tileTable at: base + self class referenceOffsetField)
					    + position)) ]
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
	^ buffers headers size / self class entryHeaderWords
]

{ #category : 'accessing' }
VGTiledFillEncoding >> entryRefs [
	^ buffers entryRefs
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
			  (buffers headers at: base + self class sourcePixelField) printStringHex.
			  entry operator.
			  entry segments fillRule.
			  entry segments isAliased.
			  (buffers headers at: base + self class alphaByteField).
			  (buffers headers at: base + self class edgeCountField).
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

{ #category : 'reading' }
VGTiledFillEncoding >> maskBytesOfEntryAt: anIndex [
	"The alpha bytes of that entry''s mask, read back out of the buffer of words in the order
	 they were written: one byte a pixel, row by row from the top left of its rectangle."

	| rectangle offset perWord bytes |
	rectangle := self maskRectangleOfEntryAt: anIndex.
	offset := buffers headers
		          at: (anIndex - 1) * self class entryHeaderWords
			          + self class maskOffsetField.
	perWord := self class maskBytesPerWord.
	bytes := ByteArray new: rectangle width * rectangle height.
	1 to: bytes size do: [ :index |
		| position |
		position := offset + index - 1.
		bytes
			at: index
			put: (((buffers maskBytes at: position // perWord + 1) bitShift:
					  (position \\ perWord * self class maskByteBits) negated)
					 bitAnd: self class fullAlphaByte) ].
	^ bytes
]

{ #category : 'reading' }
VGTiledFillEncoding >> maskRectangleOfEntryAt: anIndex [
	"The rectangle of that entry''s mask, read back out of the buffer. A mask rectangle is laid
	 out as a clip rectangle, so the field constants of a clip name its fields. Its sides are
	 whole pixels - it is the extents of a clip - so they widen from a single float unchanged and
	 are answered as whole numbers, which is what indexing a run of bytes by a row needs."

	| base |
	base := (anIndex - 1) * self class clipFloats.
	^ Rectangle
		  left: (buffers maskRects at: base + self class clipLeftField) truncated
		  right: (buffers maskRects at: base + self class clipRightField) truncated
		  top: (buffers maskRects at: base + self class clipTopField) truncated
		  bottom: (buffers maskRects at: base + self class clipBottomField) truncated
]

{ #category : 'accessing' }
VGTiledFillEncoding >> maskRects [
	^ buffers maskRects
]

{ #category : 'inspector' }
VGTiledFillEncoding >> maskRows [
	"One entry a row, with the rectangle and the bytes of its mask read back out of the mask
	 buffers. The bytes are counted and the first of them listed, because a glyph carries
	 hundreds and a row of a table holds a few."

	^ (1 to: self entryCount) collect: [ :index |
		  | bytes |
		  bytes := self maskBytesOfEntryAt: index.
		  {
			  index.
			  (self maskRectangleOfEntryAt: index).
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

{ #category : 'decoding' }
VGTiledFillEncoding >> paintOfEntryAt: anIndex [
	"The paint the buffers describe. A solid paint is the one pixel the header carries, which is
	 what the kernel will read of it; a gradient is rebuilt from its own block and then from its
	 stops, so the decode and the kernel read the same coefficients."

	| base tag paint |
	base := (anIndex - 1) * self class entryHeaderWords.
	tag := buffers headers at: base + self class paintTagField.
	tag = VGPixelPaint paintTag ifTrue: [
		^ VGPixelPaint pixel:
			  (buffers headers at: base + self class sourcePixelField) ].
	paint := (self class gradientClassAtTag: tag) fromBlock:
		         (self blockOfEntryAt: anIndex).
	(self stopsOfEntryAt: anIndex) do: [ :stop |
		paint addStopAt: stop key channels: stop value ].
	^ paint
]

{ #category : 'inspector' }
VGTiledFillEncoding >> paintRows [
	"Every paint of the frame as the buffers describe it: the class the tag resolves to, the
	 extend mode, how many stops it carries, and the two halves of its block that mean something
	 to a reader — the matrix and the type-specific fields, which are the ones after the filter.
	 Each row asks the decoder and the paint for the name of a code, so nothing here restates the
	 layout."
	^ (1 to: self entryCount) collect: [ :index |
		  | base paint block |
		  base := (index - 1) * self class entryHeaderWords.
		  paint := self paintOfEntryAt: index.
		  block := self blockOfEntryAt: index.
		  {
			  index.
			  paint class name.
			  (buffers headers at: base + self class paintTagField).
			  (VGPaint extendFor: (block at: VGPaint extendFieldIndex) truncated).
			  (buffers headers at: base + self class stopCountField).
			  (VGPaint matrixFieldIndices collect: [ :field | block at: field ]).
			  ((VGPaint filterFieldIndex + 1 to: self class paintBlockFloats)
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
		   (self class fillRuleAtCode: (buffers headers at: base + self class fillRuleField))
		   antialias:
		   (self class antialiasAtFlag: (buffers headers at: base + self class aliasedField)))
		  withAlpha:
		  (buffers headers at: base + self class alphaByteField) / self class fullAlphaByte
]

{ #category : 'writing' }
VGTiledFillEncoding >> setBinning: aBinning [
	"Write the frame out: a header, a clip rectangle, a mask rectangle, a paint block, a run of
	 edges, a run of stops and a run of mask bytes for every entry, then the table of the tiles it
	 touches and the references into it. Every entry is written as the fill it is drawn as, which
	 for a blit is a fill of its own narrowed clip carrying the alpha of its mask, so the buffers
	 describe one kind of entry and the kernel reads one kind. The entries are the binning's own
	 copy of the display list, so nothing here reads a frame that has already drained, and the
	 tiles are written from the binning itself, which knows the entries it binned and not the
	 fills they became."

	| entries edgeOffsets stopOffsets maskOffsets |
	grid := aBinning grid.
	decoded := Dictionary new.
	entries := aBinning entries collect: [ :each | each asTiledFill ].
	edgeOffsets := self offsetsFor: entries by: [ :each |
		               self edgeCountOf: each ].
	stopOffsets := self offsetsFor: entries by: [ :each |
		               self stopCountOf: each ].
	maskOffsets := self offsetsFor: entries by: [ :each |
		               self maskByteCountOf: each ].
	self
		allocateBuffersFor: entries
		edges: edgeOffsets last
		stops: stopOffsets last
		masks: maskOffsets last.
	entries withIndexDo: [ :each :index |
		self
			writeHeaderOf: each
			at: index
			edgeOffset: (edgeOffsets at: index)
			stopOffset: (stopOffsets at: index).
		self writeClipOf: each at: index.
		self writeEdgesOf: each at: (edgeOffsets at: index).
		self writePaintOf: each at: index stopOffset: (stopOffsets at: index).
		self writeMaskOf: each at: index offset: (maskOffsets at: index) ].
	self writeTilesOf: aBinning
]

{ #category : 'accessing' }
VGTiledFillEncoding >> stopCount [
	^ buffers stops size / self class stopFloats
]

{ #category : 'initialization' }
VGTiledFillEncoding >> stopCountOf: anEntry [
	"The stops of a fill''s paint, which a paint that is not a gradient has none of."

	^ anEntry paint hasStops
		  ifTrue: [ anEntry paint stops size ]
		  ifFalse: [ 0 ]
]

{ #category : 'inspector' }
VGTiledFillEncoding >> stopRows [
	"Every stop of every gradient of the frame, in the order the buffer holds them, with the
	 pixel its channels quantise to beside it. That pixel is the stop lookup table the kernel
	 searches, so a stop whose bytes drift from the software path is visible here."
	^ (1 to: self entryCount) inject: OrderedCollection new into: [ :rows :index |
		  | stopsOfEntry |
		  stopsOfEntry := self stopsOfEntryAt: index.
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

{ #category : 'decoding' }
VGTiledFillEncoding >> stopsOfEntryAt: anIndex [
	"The stops of that entry''s paint, each as its offset and its four unpremultiplied channels,
	 in the order the buffer holds them, which is the order the paint had them in."

	| base count start |
	base := (anIndex - 1) * self class entryHeaderWords.
	count := buffers headers at: base + self class stopCountField.
	start := buffers headers at: base + self class stopOffsetField.
	^ (1 to: count) collect: [ :index |
		  | stopBase |
		  stopBase := (start + index - 1) * self class stopFloats.
		  (buffers stops at: stopBase + self class stopPositionField)
		  -> (self class stopChannelFields collect: [ :field |
			   buffers stops at: stopBase + field ]) ]
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
		  base := (row - 1) * self class tileRecordWords.
		  {
			  (buffers tileTable at: base + self class tileIndexField).
			  ((buffers tileTable at: base + self class tileLeftField)
			   @ (buffers tileTable at: base + self class tileTopField)).
			  (buffers tileTable at: base + self class referenceOffsetField).
			  (buffers tileTable at: base + self class referenceCountField) } ]
]

{ #category : 'tiles' }
VGTiledFillEncoding >> touchedTileCount [
	^ buffers tileTable size / self class tileRecordWords
]

{ #category : 'tiles' }
VGTiledFillEncoding >> touchedTileIndexes [
	"The tiles the frame touches, read from the table itself."
	^ (1 to: self touchedTileCount) collect: [ :row |
		  buffers tileTable at:
			  (row - 1) * self class tileRecordWords + self class tileIndexField ]
]

{ #category : 'initialization' }
VGTiledFillEncoding >> writeClipOf: anEntry at: anIndex [
	"The clip of a fill in this subset is a rectangle, so its four sides are all of it."
	| base bounds |
	base := (anIndex - 1) * self class clipFloats.
	bounds := anEntry clip bounds.
	buffers clips at: base + self class clipLeftField put: bounds left.
	buffers clips at: base + self class clipTopField put: bounds top.
	buffers clips at: base + self class clipRightField put: bounds right.
	buffers clips at: base + self class clipBottomField put: bounds bottom
]

{ #category : 'initialization' }
VGTiledFillEncoding >> writeEdgesOf: anEntry at: anOffset [
	"The coordinates as the segments hold them, in the same order, narrowed to single floats by
	 the buffer itself."
	| base coordinates |
	base := anOffset * self class edgeFloats.
	coordinates := anEntry segments coordinates.
	1 to: coordinates size do: [ :offset |
		buffers edges at: base + offset put: (coordinates at: offset) ]
]

{ #category : 'initialization' }
VGTiledFillEncoding >> writeHeaderOf: anEntry at: anIndex edgeOffset: anOffset stopOffset: aStopOffset [
	"What a kernel needs of one fill and nothing more. A solid paint is sampled at the origin,
	 because it answers the same pixel everywhere and a pixel is less to read than a block; any
	 other paint is read from its block, and the tag says which."

	| base format |
	base := (anIndex - 1) * self class entryHeaderWords.
	format := self class targetFormat.
	buffers headers
		at: base + self class sourcePixelField
		put: (anEntry paint isSolid
				 ifTrue: [ anEntry paint pixelIn: format atX: 0 y: 0 ]
				 ifFalse: [ 0 ]).
	buffers headers
		at: base + self class operatorField
		put: (self class codeForOperator: anEntry operator).
	buffers headers
		at: base + self class fillRuleField
		put: (self class codeForFillRule: anEntry segments fillRule).
	buffers headers
		at: base + self class aliasedField
		put: (self class flagForAliased: anEntry segments isAliased).
	buffers headers
		at: base + self class alphaByteField
		put: (format shortByteOf: anEntry segments alpha).
	buffers headers at: base + self class edgeOffsetField put: anOffset.
	buffers headers
		at: base + self class edgeCountField
		put: (self edgeCountOf: anEntry).
	buffers headers
		at: base + self class paintTagField
		put: anEntry paint class paintTag.
	buffers headers at: base + self class paintBlockOffsetField put: anIndex - 1.
	buffers headers at: base + self class stopOffsetField put: aStopOffset.
	buffers headers
		at: base + self class stopCountField
		put: (self stopCountOf: anEntry)
]

{ #category : 'writing' }
VGTiledFillEncoding >> writeMaskBytes: aByteArray at: anOffset [
	"The alpha bytes of one mask into the buffer of words the kernel reads. The byte at position
	 p sits in the word p divided by the bytes a word holds, at the shift the remainder names,
	 which is the little-endian order the device reads that same word in. Each byte is written
	 once into a buffer that starts at zero, so a sum writes it."

	| perWord |
	perWord := self class maskBytesPerWord.
	1 to: aByteArray size do: [ :index |
		| position word |
		position := anOffset + index - 1.
		word := position // perWord + 1.
		buffers maskBytes
			at: word
			put: (buffers maskBytes at: word) + ((aByteArray at: index) bitShift:
					 position \\ perWord * self class maskByteBits) ]
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
	base := (anIndex - 1) * self class clipFloats.
	rectangle := anEntry tiledMaskRectangle.
	buffers maskRects at: base + self class clipLeftField put: rectangle left.
	buffers maskRects at: base + self class clipTopField put: rectangle top.
	buffers maskRects at: base + self class clipRightField put: rectangle right.
	buffers maskRects at: base + self class clipBottomField put: rectangle bottom.
	buffers headers
		at: (anIndex - 1) * self class entryHeaderWords
			+ self class maskOffsetField
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
	base := (anIndex - 1) * self class paintBlockFloats.
	paint := anEntry paint.
	1 to: self class paintBlockFloats do: [ :field |
		buffers paints at: base + field put: (paint coefficients at: field) ].
	paint hasStops ifFalse: [ ^ self ].
	paint stops withIndexDo: [ :stop :index |
		| stopBase |
		stopBase := (aStopOffset + index - 1) * self class stopFloats.
		buffers stops at: stopBase + self class stopPositionField put: stop key.
		self class stopChannelFields doWithIndex: [ :field :channel |
			buffers stops at: stopBase + field put: (stop value at: channel) ] ]
]

{ #category : 'initialization' }
VGTiledFillEncoding >> writeTileRecordAt: aRow tile: aTileIndex offset: anOffset count: aCount [
	"Where the tile is and which references belong to it. The corner is in whole pixels, which
	 is what a workgroup adds its own invocation to."
	| base bounds |
	base := (aRow - 1) * self class tileRecordWords.
	bounds := grid boundsOfTileAt: aTileIndex.
	buffers tileTable at: base + self class tileIndexField put: aTileIndex.
	buffers tileTable at: base + self class tileLeftField put: bounds left.
	buffers tileTable at: base + self class tileTopField put: bounds top.
	buffers tileTable at: base + self class referenceOffsetField put: anOffset.
	buffers tileTable at: base + self class referenceCountField put: aCount
]

{ #category : 'tiles' }
VGTiledFillEncoding >> writeTilesOf: aBinning [
	"One record a touched tile, in tile order so that a row can be found by a halving search,
	 and the references of a tile in the order the entries were drawn, because compositing is
	 not commutative. A reference also carries the mark the binning made of the pair: the entry
	 covers the whole of this tile, so the kernel takes the coverage as one there."

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
			buffers entryRefs
				at: offset + position
				put: (self class
						 referenceFor: (identifiers at: each)
						 interior: (aBinning isEntry: each interiorToTileAt: tileIndex)) ].
		offset := offset + tileEntries size ]
]
