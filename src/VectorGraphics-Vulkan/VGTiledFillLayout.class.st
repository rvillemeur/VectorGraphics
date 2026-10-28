"
The layout of the flat buffers one recorded frame rides to the device in: one method a stride, one method a field of a record, and the packing of a reference word. I hold no state and I answer nothing of a frame. `VGTiledFillEncoding` writes the records, `VGTiledFillRasteriser` reads them back and `VGTiledFillKernel` reads them on the device, and all three read these names, so a field cannot mean one thing to the writer and another to the kernel. A stride is counted in elements of the buffer it indexes - words for a header, single floats for a clip rectangle or an edge - and a field is one based, as a buffer is.
"
Class {
	#name : 'VGTiledFillLayout',
	#superclass : 'Object',
	#category : 'VectorGraphics-Vulkan-Tiles',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Tiles'
}

{ #category : 'layout' }
VGTiledFillLayout class >> alphaByteField [
	"The one byte the coverage of this fill is scaled by. A constant alpha reaches the mask as a
	 byte and never as anything finer, so the byte is all a frame has to carry."
	^ 3
]

{ #category : 'layout' }
VGTiledFillLayout class >> clipBottomField [
	^ 4
]

{ #category : 'layout' }
VGTiledFillLayout class >> clipFloats [
	"The floats one clip rectangle takes: its four sides, in the order left, top, right, bottom."
	^ 4
]

{ #category : 'layout' }
VGTiledFillLayout class >> clipLeftField [
	^ 1
]

{ #category : 'layout' }
VGTiledFillLayout class >> clipRightField [
	^ 3
]

{ #category : 'layout' }
VGTiledFillLayout class >> clipTopField [
	^ 2
]

{ #category : 'constants' }
VGTiledFillLayout class >> edgeEndXField [
	^ 3
]

{ #category : 'constants' }
VGTiledFillLayout class >> edgeEndYField [
	^ 4
]

{ #category : 'layout' }
VGTiledFillLayout class >> edgeFloats [
	"The floats one edge takes: its two ends, as x then y."
	^ 4
]

{ #category : 'constants' }
VGTiledFillLayout class >> edgeStartXField [
	"The four floats one edge of a fill takes, in the order writeEdgesOf:at: writes them, which
	 is the order VGSegments holds a line in: the start, then the end."

	^ 1
]

{ #category : 'constants' }
VGTiledFillLayout class >> edgeStartYField [
	^ 2
]

{ #category : 'layout' }
VGTiledFillLayout class >> emptyMaskRectangle [
	"The rectangle an entry with no mask carries, and the rectangle a blit whose mask does not
	 meet its clip carries. Both read full alpha everywhere, because a pixel is tested against
	 the rectangle and this one holds none."

	^ 0 @ 0 corner: 0 @ 0
]

{ #category : 'constants' }
VGTiledFillLayout class >> entryHeaderWords [
	"The words one entry of the header buffer takes. Ten carry meaning and the rest is padding: a
	 power of two, so that a kernel reaches a header by a shift and not by a multiplication."

	^ 16
]

{ #category : 'codes' }
VGTiledFillLayout class >> identifierOfReference: aWord [
	"The entry that reference names, counted from one, with the interior flag taken off."

	^ aWord bitAnd: self referenceIdentifierMask
]

{ #category : 'inspector' }
VGTiledFillLayout class >> inspectorRecords: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Records'>

	^ aBuilder newTable
		  addColumn: (SpStringTableColumn title: 'Record' evaluated: [ :each | each first ]);
		  addColumn:
			  (SpStringTableColumn title: 'Index' evaluated: [ :each | each second printString ]);
		  addColumn:
			  (SpStringTableColumn title: 'Of' evaluated: [ :each | each third printString ]);
		  addColumn: (SpStringTableColumn title: 'Field' evaluated: [ :each | each fourth ]);
		  items: self recordRows;
		  yourself
]

{ #category : 'inspector' }
VGTiledFillLayout class >> inspectorRecordsContext: aContext [
	"The layout is one table for the whole hierarchy, which here is this class alone."

	^ aContext active: self superclass = Object
]

{ #category : 'constants' }
VGTiledFillLayout class >> interiorReferenceFlag [
	"The bit a reference word carries when the entry covers the whole of the tile it is a
	 reference of. It is the top bit of the word, which no identifier of a drawable frame can
	 reach: an entry count that high would need more memory for its headers alone than a device
	 has."

	^ 16r80000000
]

{ #category : 'codes' }
VGTiledFillLayout class >> isInteriorReference: aWord [
	"Whether that reference says the entry covers the whole of its tile, so that the coverage of
	 every pixel of it is one."

	^ (aWord bitAnd: self interiorReferenceFlag) ~= 0
]

{ #category : 'layout' }
VGTiledFillLayout class >> maskByteBits [
	"The bits one alpha byte of the mask buffer takes, which is the shift between two bytes of
	 one word."

	^ 8
]

{ #category : 'layout' }
VGTiledFillLayout class >> maskBytesPerWord [
	"The alpha bytes of a mask that one word of the mask buffer holds. A storage buffer the
	 kernel reads holds words, so a byte at position p of the mask buffer sits in word p divided
	 by this one, at the shift the remainder names."

	^ 4
]

{ #category : 'layout' }
VGTiledFillLayout class >> maskOffsetField [
	"Where the alpha bytes of this entry''s mask start, counted in bytes from the first byte of
	 the mask buffer. An entry with no mask leaves the field at zero and carries an empty
	 rectangle, which is what says it has none."

	^ 10
]

{ #category : 'layout' }
VGTiledFillLayout class >> operatorField [
	^ 2
]

{ #category : 'layout' }
VGTiledFillLayout class >> paintBlockFloats [
	"The floats one coefficient block takes. It is the paint ABI of rule 2 and not a number of
	 this class, so a paint that grows a field grows the buffer with it."

	^ VGPaint coefficientCount
]

{ #category : 'layout' }
VGTiledFillLayout class >> paintBlockOffsetField [
	"Where the coefficient block of this fill starts, counted in blocks from the first block of
	 the buffer. Every entry writes a block of its own, so this is the entry index less one, and
	 the kernel reads the field rather than assuming that, because a later unit may let two
	 fills share one paint."

	^ 7
]

{ #category : 'layout' }
VGTiledFillLayout class >> paintTagField [
	"How the kernel is to read the paint block of this fill. The code is the paint tag itself,
	 which is cairo_pattern_type_t, so a header and the pattern that built it carry the same
	 number and no table stands between them."

	^ 6
]

{ #category : 'layout' }
VGTiledFillLayout class >> pixelOffsetField [
	"Where the pixels of the source surface of this fill's paint start, counted in pixels from
	 the first pixel of the pixel buffer. A fill of any other paint leaves the field at zero and
	 writes no pixel, which is what its tag already says."

	^ 11
]

{ #category : 'constants' }
VGTiledFillLayout class >> recordFields [
	"The fields of every record these buffers hold, by the selector that answers that records
	 stride. The encoding writes a field at a time and the kernel reads one at a time, so nothing
	 else reads this table: it is here for the test that holds every field inside its own record."

	^ Dictionary newFrom: {
		  (#entryHeaderWords -> #( #sourcePixelField #operatorField #alphaByteField
		     #shapeOffsetField #shapeCountField #paintTagField #paintBlockOffsetField
		     #stopOffsetField #stopCountField #maskOffsetField #pixelOffsetField )).
		  (#shapeRecordWords
		   -> #( #shapeEdgeOffsetField #shapeEdgeCountField #shapeFillRuleField
		      #shapeAliasedField )).
		  (#clipFloats
		   -> #( #clipLeftField #clipTopField #clipRightField #clipBottomField )).
		  (#edgeFloats
		   -> #( #edgeStartXField #edgeStartYField #edgeEndXField #edgeEndYField )).
		  (#stopFloats -> #( #stopPositionField )).
		  (#tileRecordWords
		   -> #( #tileIndexField #tileLeftField #tileTopField #referenceOffsetField
		      #referenceCountField )) }
]

{ #category : 'inspecting' }
VGTiledFillLayout class >> recordRows [
	"One row a word of every record, so a word no field names shows as spare: the header has six
	 of those, which is the room a later unit has to grow into."

	| rows |
	rows := OrderedCollection new.
	self recordFields keys asSortedCollection do: [ :stride |
		| words fields |
		words := self perform: stride.
		fields := self recordFields at: stride.
		1 to: words do: [ :index |
			| field |
			field := fields detect: [ :each | (self perform: each) = index ] ifNone: [ nil ].
			field ifNil: [ "the channels of a stop are a run and not a field each"
				(stride = #stopFloats and: [ self stopChannelFields includes: index ])
					ifTrue: [ field := #stopChannelFields ] ].
			rows add: {
					stride.
					index.
					words.
					(field ifNil: [ 'spare' ] ifNotNil: [ field asString ]) } ] ].
	^ rows
]

{ #category : 'layout' }
VGTiledFillLayout class >> referenceCountField [
	^ 5
]

{ #category : 'codes' }
VGTiledFillLayout class >> referenceFor: anIdentifier interior: aBoolean [
	"The reference word of that entry, marked or not. Both sides read this one place: the kernel
	 asks the flag of the word it loads and the decoder asks the identifier of the same word."

	^ aBoolean
		  ifTrue: [ anIdentifier bitOr: self interiorReferenceFlag ]
		  ifFalse: [ anIdentifier ]
]

{ #category : 'constants' }
VGTiledFillLayout class >> referenceIdentifierMask [
	"The bits of a reference word that are the identifier of the entry, which is every bit but
	 the interior flag."

	^ self interiorReferenceFlag - 1
]

{ #category : 'layout' }
VGTiledFillLayout class >> referenceOffsetField [
	"Where the references of this tile start, counted from the first reference and not from one,
	 because the kernel indexes from zero."
	^ 4
]

{ #category : 'constants' }
VGTiledFillLayout class >> shapeAliasedField [

	^ 4
]

{ #category : 'constants' }
VGTiledFillLayout class >> shapeCountField [

	^ 5
]

{ #category : 'constants' }
VGTiledFillLayout class >> shapeEdgeCountField [

	^ 2
]

{ #category : 'constants' }
VGTiledFillLayout class >> shapeEdgeOffsetField [
	"Where the edges of this shape start, counted in edges from the first edge of the buffer."

	^ 1
]

{ #category : 'constants' }
VGTiledFillLayout class >> shapeFillRuleField [

	^ 3
]

{ #category : 'constants' }
VGTiledFillLayout class >> shapeOffsetField [
	"Where the shapes of this entry start, counted in shapes from the first shape of the buffer.
	 The fill is the first of them and the shapes of its clip follow, so the count is never zero."

	^ 4
]

{ #category : 'constants' }
VGTiledFillLayout class >> shapeRecordWords [
	"The words one shape of an entry takes. A fill and every shape its clip was cut out with are
	 one kind of record, so the kernel reads a shape the same way wherever it came from."

	^ 4
]

{ #category : 'layout' }
VGTiledFillLayout class >> sourcePixelField [
	"The premultiplied pixel the fill's paint answers, because the kernel carries a pixel and
	 not a paint."
	^ 1
]

{ #category : 'layout' }
VGTiledFillLayout class >> stopChannelFields [
	"Where the four channels of a stop sit, in the order a stop list keeps them."

	^ 2 to: 5
]

{ #category : 'layout' }
VGTiledFillLayout class >> stopCountField [
	"How many stops this fill has. Zero stands both for a solid paint and for a gradient whose
	 stop list is empty, which Cairo draws as nothing at all, so the kernel needs no other mark
	 for either."

	^ 9
]

{ #category : 'layout' }
VGTiledFillLayout class >> stopFloats [
	"The floats one stop takes: its offset along the ramp, then its four unpremultiplied
	 channels in the order red, green, blue, alpha."

	^ 5
]

{ #category : 'layout' }
VGTiledFillLayout class >> stopOffsetField [
	"Where the stops of this fill start, counted in stops from the first stop of the buffer. A
	 paint with no stop list writes nothing there and leaves the count at zero."

	^ 8
]

{ #category : 'layout' }
VGTiledFillLayout class >> stopPositionField [
	^ 1
]

{ #category : 'layout' }
VGTiledFillLayout class >> tileIndexField [
	^ 1
]

{ #category : 'layout' }
VGTiledFillLayout class >> tileLeftField [
	^ 2
]

{ #category : 'layout' }
VGTiledFillLayout class >> tileRecordWords [
	"The words one tile of the table takes: which tile it is, where it starts in pixels, and the
	 window of entry references that belong to it."
	^ 5
]

{ #category : 'layout' }
VGTiledFillLayout class >> tileTopField [
	^ 3
]
