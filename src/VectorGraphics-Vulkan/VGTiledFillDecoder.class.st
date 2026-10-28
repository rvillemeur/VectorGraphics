"
I read one frame back out of the buffers a VGTiledFillEncoding wrote.

The encoding knows where every record goes and I know how to read one, so the two sides of the
layout are written once each and a test can hold either of them alone. What I answer are display
list entries of the kind VGTiledFillRasteriser draws: an entry with its own segments, paint, clip
and operator, rebuilt from words and single floats. I remember every entry I decode, because a
frame holds far fewer entries than tiles and every tile an entry reaches asks for it again.

The codes a header carries are named by VGTiledFillEncoding class, which is where the tables that
wrote them live; the offsets and the fields are VGTiledFillLayout.
"
Class {
	#name : 'VGTiledFillDecoder',
	#superclass : 'Object',
	#instVars : [
		'buffers',
		'decoded'
	],
	#category : 'VectorGraphics-Vulkan-Tiles',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Tiles'
}

{ #category : 'instance creation' }
VGTiledFillDecoder class >> on: aBuffers [
	"The decoder of a set of buffers an encoding has already written."

	^ self new setBuffers: aBuffers
]

{ #category : 'decoding' }
VGTiledFillDecoder >> blockOfEntryAt: anIndex [
	"The coefficient block of the paint of that entry, the single floats of the buffer taken as
	 they stand: a paint keeps its block in single floats too, so nothing widens here."

	| base block |
	base := (buffers headers
	         at:
	         (anIndex - 1) * VGTiledFillLayout entryHeaderWords
	         + VGTiledFillLayout paintBlockOffsetField) * VGTiledFillLayout paintBlockFloats.
	block := Float32Array new: VGTiledFillLayout paintBlockFloats.
	1 to: VGTiledFillLayout paintBlockFloats do: [ :field |
		block at: field put: (buffers paints at: base + field) ].
	^ block
]

{ #category : 'decoding' }
VGTiledFillDecoder >> clipOfEntryAt: anIndex [
	"The clip of that entry: the rectangle its bounds were written as, cut down by every shape
	 of its own shape run."

	| base |
	base := (anIndex - 1) * VGTiledFillLayout clipFloats.
	^ VGClip
		  bounds: (Rectangle
				   left: (buffers clips at: base + VGTiledFillLayout clipLeftField)
				   right: (buffers clips at: base + VGTiledFillLayout clipRightField)
				   top: (buffers clips at: base + VGTiledFillLayout clipTopField)
				   bottom: (buffers clips at: base + VGTiledFillLayout clipBottomField))
		  shapes: (self clipShapesOfEntryAt: anIndex)
]

{ #category : 'decoding' }
VGTiledFillDecoder >> clipShapesOfEntryAt: anIndex [
	"The shapes the clip of that entry was cut out with, which are every shape of the entry but
	 the fill."

	^ (self shapesOfEntryAt: anIndex) allButFirst
]

{ #category : 'decoding' }
VGTiledFillDecoder >> coordinatesFrom: aStart count: aCount [
	"A run of the edge buffer as one flat array of ends."

	| coordinates |
	coordinates := Array new: aCount.
	1 to: aCount do: [ :offset |
		coordinates at: offset put: (buffers edges at: aStart + offset) ].
	^ coordinates
]

{ #category : 'decoding' }
VGTiledFillDecoder >> decodeEntryAt: anIndex [
	"One entry out of the buffers and nothing else: this is what makes the step one rasteriser
	 draw from the encoding alone, and so what a test can hold the layout to before a kernel
	 exists. An entry whose mask rectangle is empty carries no mask and is the fill it looks
	 like; one with a rectangle is the masked fill a blit was written as."

	| base fill rectangle |
	base := (anIndex - 1) * VGTiledFillLayout entryHeaderWords.
	fill := VGFillEntry
		        segments: (self segmentsOfEntryAt: anIndex)
		        paint: (self paintOfEntryAt: anIndex)
		        clip: (self clipOfEntryAt: anIndex)
		        operator:
		        (VGTiledFillEncoding operatorAtCode:
			         (buffers headers at: base + VGTiledFillLayout operatorField)).
	rectangle := self maskRectangleOfEntryAt: anIndex.
	rectangle = VGTiledFillLayout emptyMaskRectangle ifTrue: [ ^ fill ].
	^ VGMaskedFillEntry
		  fill: fill
		  bytes: (self maskBytesOfEntryAt: anIndex)
		  over: rectangle
]

{ #category : 'decoding' }
VGTiledFillDecoder >> entryAt: anIndex [
	"The entry the buffers describe, rebuilt as a display list entry of the kind the rasteriser
	 draws. It is remembered, because a frame holds far fewer entries than tiles and every tile
	 the entry reaches asks for it again."

	^ decoded at: anIndex ifAbsentPut: [ self decodeEntryAt: anIndex ]
]

{ #category : 'accessing' }
VGTiledFillDecoder >> entryCount [
	^ buffers headers size // VGTiledFillLayout entryHeaderWords
]

{ #category : 'inspecting' }
VGTiledFillDecoder >> inspectorShapes: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Shapes'>
	"The shape run of every entry as I read it: which shape of the entry it is, whether it is
	 the fill or a shape of its clip, how many edges it holds, the fill rule it is read under
	 and whether it is aliased. A fill and a clip shape are one kind of record, so the kernel
	 walks them all the same way and this table is the whole of what it knows about a shape."

	^ aBuilder newTable
		  addColumn: (SpStringTableColumn
				   title: 'Entry'
				   evaluated: [ :each | (each at: 1) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Shape'
				   evaluated: [ :each | (each at: 2) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Of'
				   evaluated: [ :each | each at: 3 ]);
		  addColumn: (SpStringTableColumn
				   title: 'Edges'
				   evaluated: [ :each | (each at: 4) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Fill rule'
				   evaluated: [ :each | (each at: 5) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Aliased'
				   evaluated: [ :each | (each at: 6) printString ]);
		  items: self shapeRows;
		  yourself
]

{ #category : 'inspecting' }
VGTiledFillDecoder >> inspectorShapesContext: aContext [
	aContext active: buffers isNotNil
]

{ #category : 'decoding' }
VGTiledFillDecoder >> maskBytesOfEntryAt: anIndex [
	"The alpha bytes of the mask of that entry, read back out of the buffer of words in the order
	 they were written: one byte a pixel, row by row from the top left of its rectangle."

	| rectangle offset perWord bytes |
	rectangle := self maskRectangleOfEntryAt: anIndex.
	offset := buffers headers
		          at: (anIndex - 1) * VGTiledFillLayout entryHeaderWords
			          + VGTiledFillLayout maskOffsetField.
	perWord := VGTiledFillLayout maskBytesPerWord.
	bytes := ByteArray new: rectangle width * rectangle height.
	1 to: bytes size do: [ :index |
		| position |
		position := offset + index - 1.
		bytes
			at: index
			put: (((buffers maskBytes at: position // perWord + 1) bitShift:
					  (position \\ perWord * VGTiledFillLayout maskByteBits) negated)
					 bitAnd: VGTiledFillEncoding fullAlphaByte) ].
	^ bytes
]

{ #category : 'decoding' }
VGTiledFillDecoder >> maskRectangleOfEntryAt: anIndex [
	"The rectangle of the mask of that entry, read back out of the buffer. A mask rectangle is
	 laid out as a clip rectangle, so the field constants of a clip name its fields. Its sides
	 are whole pixels - it is the extents of a clip - so they widen from a single float unchanged
	 and are answered as whole numbers, which is what indexing a run of bytes by a row needs."

	| base |
	base := (anIndex - 1) * VGTiledFillLayout clipFloats.
	^ Rectangle
		  left: (buffers maskRects at: base + VGTiledFillLayout clipLeftField) truncated
		  right: (buffers maskRects at: base + VGTiledFillLayout clipRightField) truncated
		  top: (buffers maskRects at: base + VGTiledFillLayout clipTopField) truncated
		  bottom: (buffers maskRects at: base + VGTiledFillLayout clipBottomField) truncated
]

{ #category : 'decoding' }
VGTiledFillDecoder >> paintOfEntryAt: anIndex [
	"The paint the buffers describe. A solid paint is the one pixel the header carries, which is
	 what the kernel reads of it; a surface paint is its own block over a surface rebuilt from
	 the pixel buffer; a gradient is rebuilt from its own block and then from its stops. The
	 block is read in every case but the solid one, so the decode and the kernel read the same
	 coefficients."

	| base tag paint |
	base := (anIndex - 1) * VGTiledFillLayout entryHeaderWords.
	tag := buffers headers at: base + VGTiledFillLayout paintTagField.
	tag = VGPixelPaint paintTag ifTrue: [
		^ VGPixelPaint pixel:
			  (buffers headers at: base + VGTiledFillLayout sourcePixelField) ].
	tag = VGSurfacePaint paintTag ifTrue: [
		^ (VGSurfacePaint fromBlock: (self blockOfEntryAt: anIndex))
			  surface: (self surfaceOfEntryAt: anIndex);
			  yourself ].
	paint := (VGTiledFillEncoding gradientClassAtTag: tag) fromBlock:
		         (self blockOfEntryAt: anIndex).
	(self stopsOfEntryAt: anIndex) do: [ :stop |
		paint addStopAt: stop key channels: stop value ].
	^ paint
]

{ #category : 'printing' }
VGTiledFillDecoder >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPut: $(;
		print: self entryCount;
		nextPutAll: ' entries)'
]

{ #category : 'reading' }
VGTiledFillDecoder >> segmentsOfEntryAt: anIndex [
	"The path of that entry: the first shape of its run, which is its fill, under the alpha its
	 header names. The alpha is the byte read back as the fraction of full alpha it stands for,
	 which quantises to that byte again."

	| base fill |
	base := (anIndex - 1) * VGTiledFillLayout entryHeaderWords.
	fill := self shapeAtOffset:
		        (buffers headers at: base + VGTiledFillLayout shapeOffsetField).
	^ (VGSegments
		   coordinates: fill segments
		   fillRule: fill fillRule
		   antialias: fill antialias)
		  withAlpha:
		  (buffers headers at: base + VGTiledFillLayout alphaByteField)
		  / VGTiledFillEncoding fullAlphaByte
]

{ #category : 'initialization' }
VGTiledFillDecoder >> setBuffers: aBuffers [
	buffers := aBuffers.
	decoded := Dictionary new
]

{ #category : 'decoding' }
VGTiledFillDecoder >> shapeAtOffset: anOffset [
	"One shape out of its record, as a scanner. The offset counts shapes from the first shape of
	 the buffer, which is how the header of an entry names the start of its own run."

	| record |
	record := anOffset * VGTiledFillLayout shapeRecordWords.
	^ VGSpanScanner
		  segments: (self
				   coordinatesFrom:
				   (buffers shapes at: record + VGTiledFillLayout shapeEdgeOffsetField)
				   * VGTiledFillLayout edgeFloats
				   count:
				   (buffers shapes at: record + VGTiledFillLayout shapeEdgeCountField)
				   * VGTiledFillLayout edgeFloats)
		  fillRule: (VGTiledFillEncoding fillRuleAtCode:
				   (buffers shapes at: record + VGTiledFillLayout shapeFillRuleField))
		  antialias: (VGTiledFillEncoding antialiasAtFlag:
				   (buffers shapes at: record + VGTiledFillLayout shapeAliasedField))
]

{ #category : 'inspecting' }
VGTiledFillDecoder >> shapeRows [
	"Every shape of every entry of the frame, the fill first and the shapes of its clip after
	 it, each read back out of its own record. The number of edges and the fill rule are asked
	 of the scanner the record decodes to, so a field written into the wrong word shows here."

	^ (1 to: self entryCount) inject: OrderedCollection new into: [ :rows :index |
		  (self shapesOfEntryAt: index) doWithIndex: [ :shape :ordinal |
			  rows add: {
					  index.
					  ordinal.
					  (ordinal = 1
						   ifTrue: [ 'fill' ]
						   ifFalse: [ 'clip' ]).
					  shape size.
					  shape fillRule.
					  shape isAliased } ].
		  rows ]
]

{ #category : 'decoding' }
VGTiledFillDecoder >> shapesOfEntryAt: anIndex [
	"Every shape of that entry: the fill first and the shapes of its clip after it, in the order
	 they were written."

	| base offset count |
	base := (anIndex - 1) * VGTiledFillLayout entryHeaderWords.
	offset := buffers headers at: base + VGTiledFillLayout shapeOffsetField.
	count := buffers headers at: base + VGTiledFillLayout shapeCountField.
	^ (1 to: count) collect: [ :ordinal |
		  self shapeAtOffset: offset + ordinal - 1 ]
]

{ #category : 'decoding' }
VGTiledFillDecoder >> stopsOfEntryAt: anIndex [
	"The stops of the paint of that entry, each as its offset and its four unpremultiplied
	 channels, in the order the buffer holds them, which is the order the paint had them in."

	| base count start |
	base := (anIndex - 1) * VGTiledFillLayout entryHeaderWords.
	count := buffers headers at: base + VGTiledFillLayout stopCountField.
	start := buffers headers at: base + VGTiledFillLayout stopOffsetField.
	^ (1 to: count) collect: [ :index |
		  | stopBase |
		  stopBase := (start + index - 1) * VGTiledFillLayout stopFloats.
		  (buffers stops at: stopBase + VGTiledFillLayout stopPositionField)
		  -> (VGTiledFillLayout stopChannelFields collect: [ :field |
			   buffers stops at: stopBase + field ]) ]
]

{ #category : 'decoding' }
VGTiledFillDecoder >> surfaceOfEntryAt: anIndex [
	"The source surface of that entry, rebuilt from the pixel buffer: the extent is the two
	 fields of its own block that the paint ABI names for it, and the pixels are the run the
	 header names, packed to that width. The bytes are the surface's to read and not to own, and
	 its format is the one a frame is encoded for, which is what the subset holds a source to."

	| base block width height bytes offset stride |
	base := (anIndex - 1) * VGTiledFillLayout entryHeaderWords.
	block := self blockOfEntryAt: anIndex.
	width := (block at: VGPaint surfaceWidthFieldIndex) rounded.
	height := (block at: VGPaint surfaceHeightFieldIndex) rounded.
	offset := buffers headers at: base + VGTiledFillLayout pixelOffsetField.
	stride := VGTiledFillEncoding targetFormat bytesPerPixel.
	bytes := ByteArray new: width * height * stride.
	1 to: width * height do: [ :index |
		bytes
			uint32AtOffset: index - 1 * stride
			put: (buffers sourcePixels at: offset + index) ].
	^ VGCairoImageSurface
		  unownedNewForData: bytes
		  format: VGTiledFillEncoding targetFormat
		  width: width
		  height: height
		  stride: width * stride
]
