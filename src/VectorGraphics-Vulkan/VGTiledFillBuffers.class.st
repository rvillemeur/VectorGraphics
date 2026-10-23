"
I am the buffers one frame of the tiled rasteriser rides to the device in, one for every binding of VGTiledFillKernel that an encoding answers.
A buffer of mine is either a WordArray or a Float32Array, which is what a storage buffer of the kernel holds, and VGTiledFillDispatch asks me for them by the name the kernel binds them under.
I know how large each of them is for a frame - a header, two rectangles and a paint block an entry, and as many edges, stops and mask bytes as the entries hold between them - and nothing of what goes inside one: VGTiledFillEncoding owns the layout of a record and writes mine through me.
"
Class {
	#name : 'VGTiledFillBuffers',
	#superclass : 'Object',
	#instVars : [
		'tileTable',
		'entryRefs',
		'headers',
		'clips',
		'edges',
		'paints',
		'stops',
		'maskRects',
		'maskBytes'
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

	headers := WordArray new: aCount * VGTiledFillEncoding entryHeaderWords.
	clips := Float32Array new: aCount * VGTiledFillEncoding clipFloats.
	maskRects := Float32Array new: aCount * VGTiledFillEncoding clipFloats.
	paints := Float32Array new: aCount * VGTiledFillEncoding paintBlockFloats.
	edges := Float32Array new: anEdgeCount * VGTiledFillEncoding edgeFloats.
	stops := Float32Array new: aStopCount * VGTiledFillEncoding stopFloats.
	maskBytes := WordArray new:
		             aByteCount + VGTiledFillEncoding maskBytesPerWord - 1
			             // VGTiledFillEncoding maskBytesPerWord
]

{ #category : 'allocating' }
VGTiledFillBuffers >> allocateForTiles: aTileCount references: aReferenceCount [
	"The two buffers the tiles of a frame ride in, which are sized by the tiles the frame
	 touches and not by the entries it holds, and so are allocated after them."

	tileTable := WordArray new:
		             aTileCount * VGTiledFillEncoding tileRecordWords.
	entryRefs := WordArray new: aReferenceCount
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
	^ clips
]

{ #category : 'accessing' }
VGTiledFillBuffers >> edges [
	^ edges
]

{ #category : 'accessing' }
VGTiledFillBuffers >> entryRefs [
	^ entryRefs
]

{ #category : 'accessing' }
VGTiledFillBuffers >> headers [
	^ headers
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

{ #category : 'inspector' }
VGTiledFillBuffers >> inspectorBuffersContext: aContext [
	"Nothing has been allocated until a frame is written out, and a tab of nine empty rows says
	 less than no tab at all."

	aContext active: headers isNotNil
]

{ #category : 'accessing' }
VGTiledFillBuffers >> maskBytes [
	^ maskBytes
]

{ #category : 'accessing' }
VGTiledFillBuffers >> maskRects [
	^ maskRects
]

{ #category : 'accessing' }
VGTiledFillBuffers >> paints [
	^ paints
]

{ #category : 'printing' }
VGTiledFillBuffers >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPut: $(;
		print: (headers ifNil: [ 0 ] ifNotNil: [ headers size ]);
		nextPutAll: ' header words, ';
		print: (maskBytes ifNil: [ 0 ] ifNotNil: [ maskBytes size ]);
		nextPutAll: ' mask words)'
]

{ #category : 'accessing' }
VGTiledFillBuffers >> stops [
	^ stops
]

{ #category : 'accessing' }
VGTiledFillBuffers >> tileTable [
	^ tileTable
]
