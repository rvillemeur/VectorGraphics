"
I am the buffers one frame of the tiled rasteriser rides to the device in, one for every binding of VGTiledFillKernel that an encoding answers.
A buffer of mine is either a WordArray or a Float32Array, which is what a storage buffer of the kernel holds, and VGTiledFillDispatch asks me for them by the name the kernel binds them under.
I know how large each of them is for a frame - a header, two rectangles and a paint block an entry, and as many edges, stops and mask bytes as the entries hold between them - and nothing of what goes inside one: VGTiledFillEncoding owns the layout of a record and writes mine through me.
"
Class {
	#name : 'VGTiledFillBuffers',
	#superclass : 'Object',
	#instVars : [
		'arrays'
	],
	#category : 'VectorGraphics-Vulkan-Tiles',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Tiles'
}

{ #category : 'allocating' }
VGTiledFillBuffers >> allocateForEntries: aCount edges: anEdgeCount stops: aStopCount masks: aByteCount [
	"The seven buffers an entry writes into, sized by the frame alone: a header, a clip
	 rectangle, a mask rectangle and a paint block an entry, and as many edges, stops and mask
	 bytes as the entries hold between them. The mask buffer holds words, because that is what a
	 storage buffer of the kernel holds, and a run of bytes that does not fill its last word
	 leaves the rest of it alone."

	arrays at: #headers put: (WordArray new: aCount * VGTiledFillLayout entryHeaderWords).
	arrays at: #clips put: (Float32Array new: aCount * VGTiledFillLayout clipFloats).
	arrays at: #maskRects put: (Float32Array new: aCount * VGTiledFillLayout clipFloats).
	arrays
		at: #paints
		put: (Float32Array new: aCount * VGTiledFillLayout paintBlockFloats).
	arrays at: #edges put: (Float32Array new: anEdgeCount * VGTiledFillLayout edgeFloats).
	arrays at: #stops put: (Float32Array new: aStopCount * VGTiledFillLayout stopFloats).
	arrays at: #maskBytes put: (WordArray new:
			 aByteCount + VGTiledFillLayout maskBytesPerWord - 1
			 // VGTiledFillLayout maskBytesPerWord)
]

{ #category : 'allocating' }
VGTiledFillBuffers >> allocateForPixels: aCount [
	"The pixels of the source surfaces a frame paints out of, which are counted over the entries
	 and not one an entry: only a fill whose paint is a surface carries any, and it carries one
	 for every pixel of that surface."

	arrays at: #sourcePixels put: (WordArray new: aCount)
]

{ #category : 'allocating' }
VGTiledFillBuffers >> allocateForShapes: aCount [
	"The shape records of a frame, which are counted over the entries and not one an entry: an
	 entry carries its fill and a record for every shape its clip was cut out with."

	arrays
		at: #shapes
		put: (WordArray new: aCount * VGTiledFillLayout shapeRecordWords)
]

{ #category : 'allocating' }
VGTiledFillBuffers >> allocateForTiles: aTileCount references: aReferenceCount [
	"The three buffers the tiles of a frame ride in, which are sized by the tiles the frame
	 touches and not by the entries it holds, and so are allocated after them. A reference
	 carries a word of its own in refShapes: the shape records its tile is to read for that
	 entry, which are the records of the row of tiles the tile is in and not of the whole shape."

	arrays
		at: #tileTable
		put: (WordArray new: aTileCount * VGTiledFillLayout tileRecordWords).
	arrays at: #entryRefs put: (WordArray new: aReferenceCount).
	arrays at: #refShapes put: (WordArray new: aReferenceCount)
]

{ #category : 'accessing' }
VGTiledFillBuffers >> bufferNamed: aName [
	"The buffer of that binding, or nothing where no frame has been written out yet. The
	 buffers are held by the name the kernel binds them under rather than one slot each,
	 because a binding added to the contract is then a buffer added to this set and not a
	 variable added to me."

	^ arrays at: aName ifAbsent: [ nil ]
]

{ #category : 'accessing' }
VGTiledFillBuffers >> bufferNames [
	"The bindings I hold a buffer for, which after a frame is written out is every binding of
	 the kernel an encoding answers."

	^ arrays keys
]

{ #category : 'inspector' }
VGTiledFillBuffers >> bufferRows [
	"One row a buffer the kernel binds, with the number of elements it holds and the bytes that
	 many elements upload as. The names are the bindings of the kernel itself, less the two that
	 are not written out of an encoding, so a binding added to the contract appears here without
	 this method being edited."

	^ (VGTiledFillKernel bindingNames reject: [ :each |
		   VGTiledFillDispatch bindingsNotOfAnEncoding includes: each ]) collect: [
		  :name |
		  | buffer |
		  buffer := self perform: name.
		  {
			  name.
			  (buffer ifNil: [ nil ] ifNotNil: [ buffer class name ]).
			  (buffer ifNil: [ 0 ] ifNotNil: [ buffer size ]).
			  (buffer ifNil: [ 0 ] ifNotNil: [ buffer size * 4 ]) } ]
]

{ #category : 'accessing' }
VGTiledFillBuffers >> clips [
	^ self bufferNamed: #clips
]

{ #category : 'accessing' }
VGTiledFillBuffers >> edges [
	^ self bufferNamed: #edges
]

{ #category : 'accessing' }
VGTiledFillBuffers >> entryRefs [
	^ self bufferNamed: #entryRefs
]

{ #category : 'accessing' }
VGTiledFillBuffers >> headers [
	^ self bufferNamed: #headers
]

{ #category : 'initialization' }
VGTiledFillBuffers >> initialize [
	super initialize.
	arrays := Dictionary new
]

{ #category : 'inspector' }
VGTiledFillBuffers >> inspectorBuffers: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Buffers'>
	"Every buffer of the set with the size it was allocated at, so that the cost of a frame on
	 the bus can be read off one tab. A buffer is four bytes an element either way, a word or a
	 float32, which is what a storage buffer of the kernel holds."

	^ aBuilder newTable
		  addColumn: (SpStringTableColumn
				   title: 'Buffer'
				   evaluated: [ :each | (each at: 1) asString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Holds'
				   evaluated: [ :each | (each at: 2) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Elements'
				   evaluated: [ :each | (each at: 3) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Bytes'
				   evaluated: [ :each | (each at: 4) printString ]);
		  items: self bufferRows;
		  yourself
]

{ #category : 'inspecting' }
VGTiledFillBuffers >> inspectorBuffersContext: aContext [
	"Nothing has been allocated until a frame is written out, and a tab of ten empty rows says
	 less than no tab at all."

	aContext active: self headers isNotNil
]

{ #category : 'accessing' }
VGTiledFillBuffers >> maskBytes [
	^ self bufferNamed: #maskBytes
]

{ #category : 'accessing' }
VGTiledFillBuffers >> maskRects [
	^ self bufferNamed: #maskRects
]

{ #category : 'accessing' }
VGTiledFillBuffers >> paints [
	^ self bufferNamed: #paints
]

{ #category : 'printing' }
VGTiledFillBuffers >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPut: $(;
		print: (self headers ifNil: [ 0 ] ifNotNil: [ :each | each size ]);
		nextPutAll: ' header words, ';
		print: (self maskBytes ifNil: [ 0 ] ifNotNil: [ :each | each size ]);
		nextPutAll: ' mask words)'
]

{ #category : 'accessing' }
VGTiledFillBuffers >> refShapes [
	^ self bufferNamed: #refShapes
]

{ #category : 'accessing' }
VGTiledFillBuffers >> shapes [
	^ self bufferNamed: #shapes
]

{ #category : 'accessing' }
VGTiledFillBuffers >> sourcePixels [
	^ self bufferNamed: #sourcePixels
]

{ #category : 'accessing' }
VGTiledFillBuffers >> stops [
	^ self bufferNamed: #stops
]

{ #category : 'accessing' }
VGTiledFillBuffers >> tileTable [
	^ self bufferNamed: #tileTable
]
