"
I send one encoded frame of the tiled fill subset to a Vulkan device and bring its pixels back.

A frame arrives as a `VGTiledFillEncoding` and a run of bytes holding the destination pixels packed row after row. I allocate one storage buffer for every binding `VGTiledFillKernel` declares, upload the bytes of each, dispatch one workgroup for every tile the frame touches, and read the target buffer back into the bytes it came from. `draw:into:` is the whole of it, and `bytesOf:target:` is what it uploads, which needs no device and is held by a test on every machine.

The words and the floats of an encoding are read through `basicAt:`, which answers the stored word of a `WordArray` and the bit pattern of a `Float32Array`, so one method narrows both and neither is bitcast through a Float. The extent is the one thing an encoding does not carry into a buffer, so I write the frame record myself.

I take a context and never make one: the backend owns the device, and a dispatch owns the buffers of one frame alone. The kernel is destroyed before the buffers, since a buffer freed under a live pipeline takes the image with it.
"
Class {
	#name : 'VGTiledFillDispatch',
	#superclass : 'Object',
	#instVars : [
		'context',
		'stages',
		'kernel',
		'buffers',
		'tileExtent',
		'prepared',
		'blocks'
	],
	#category : 'VectorGraphics-Vulkan-Tiles',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Tiles'
}

{ #category : 'constants' }
VGTiledFillDispatch class >> bindingsNotOfAnEncoding [
	"The two bindings of the kernel that an encoding does not answer: the pixels of the target,
	 which the caller owns, and the record of the frame, which is written here because the extent
	 is the one thing an encoding does not carry into a buffer."

	^ #( #target #frame )
]

{ #category : 'constants' }
VGTiledFillDispatch class >> emptyBufferWordCount [
	"Vulkan refuses a buffer of no bytes, so a binding with nothing behind it is one word wide.
	 The kernel never reads that word: a frame with no entry of its own touches no tile, and a
	 tile that is dispatched has edges."

	^ 1
]

{ #category : 'constants' }
VGTiledFillDispatch class >> layersPerDispatch [
	^ 1
]

{ #category : 'instance' }
VGTiledFillDispatch class >> on: aContext [
	"A dispatch that draws on that context. The device belongs to the backend and not to me: it
	 outlives one frame, and the buffers of a frame do not."

	^ self new setContext: aContext
]

{ #category : 'constants' }
VGTiledFillDispatch class >> rowsPerDispatch [
	"The kernel reads the tile it owns from the x component of the workgroup id, so a dispatch is
	 one row of workgroups and nothing more."

	^ 1
]

{ #category : 'constants' }
VGTiledFillDispatch class >> shownWordCount [
	"The words of a binding the Buffers tab prints, which is as many as a row reads at a glance
	 and no statement about the buffer itself."

	^ 6
]

{ #category : 'constants' }
VGTiledFillDispatch class >> stageNames [
	"The stages one frame on the device is paid in, in the order it pays them, which is the
	 order draw:into:readBack: wraps them in and the order a report shows them in. This table is
	 the only place that names a stage: a report reads it, and a test reads the source of the
	 frame against it so that a stage cannot be timed under a name no report shows.
	 The first of them is named writeBuffers for the frames of units 3.0 to 3.3, where it packed
	 the words of the already built encoding into runs of bytes; since unit 3.4 it writes the
	 frame record alone and names the blocks the upload reads, and the name is kept so that the
	 figures of every unit can be read against each other. It is not the building of the
	 encoding, which a frame pays before a dispatch is asked for anything.
	 There is no release among them, because unit 3.1 keeps the device objects of a frame for the
	 session and a frame pays nothing to let go of them. The last of them is paid only by a frame
	 that asks for its pixels: a frame that ends on the device reaches no readback and is
	 reported with no row for one."

	^ #( #writeBuffers #module #allocate #prepare #upload #dispatch #readback )
]

{ #category : 'accessing' }
VGTiledFillDispatch >> blocks [
	"What the last frame uploaded, by binding name: one block of words a binding, kept so that
	 what a dispatch sent can be read after the device is gone."

	^ blocks
]

{ #category : 'encoding' }
VGTiledFillDispatch >> blocksOf: anEncoding target: aByteArray [
	"The block of words of every binding the kernel reads, by name: the buffers of the encoding
	 as they lie in object memory, the pixels of the target as they are, and the frame record
	 written here. Nothing is copied: a WordArray and a Float32Array already hold their elements
	 in the order and the width a storage buffer reads them, so the upload writes out of these
	 very objects. The names are the contract of the kernel with the two that are not an encoding
	 buffer taken off it, so a binding added to that contract is named in one place and reaches
	 the device without this method being edited."

	| answer |
	answer := Dictionary new.
	(VGTiledFillKernel bindingNames
		 reject: [ :each | self class bindingsNotOfAnEncoding includes: each ])
		do: [ :each | answer at: each put: (anEncoding perform: each) ].
	answer at: #target put: aByteArray.
	answer at: #frame put: (self frameRecordOf: anEncoding).
	^ answer
]

{ #category : 'inspecting' }
VGTiledFillDispatch >> bufferRows [
	"One row a binding, in the order the descriptor set holds them: what the kernel reads it as,
	 how many words went out, the first words of them and the host address the buffer is mapped
	 at. The words are read out of the block the device was given rather than out of the
	 encoding, and the address is asked of the buffer itself, so a row cannot say the frame sent
	 something it did not or that a mapping is held where none is."

	^ VGTiledFillKernel bindingNames withIndexCollect: [ :name :index |
		  | block count |
		  block := blocks at: name.
		  count := (self byteCountOfBlock: block)
		           / VGTiledFillKernel elementStride.
		  {
			  (index - 1).
			  name.
			  ((VGTiledFillKernel floatBindingNames includes: name)
				   ifTrue: [ #float32 ]
				   ifFalse: [ #uint32 ]).
			  count.
			  ((1 to: (count min: self class shownWordCount)) collect: [ :word |
				   self wordOfBlock: block at: word ]).
			  (buffers
				   at: name
				   ifPresent: [ :buffer | buffer mappingOrNil ]
				   ifAbsent: [ nil ]) } ]
]

{ #category : 'encoding' }
VGTiledFillDispatch >> byteCountOfBlock: aBlock [
	"The bytes of that block, asked of the block itself: a WordArray counts words, a Float32Array
	 counts floats and the pixels of the target count bytes, while the device is given bytes
	 either way."

	^ aBlock byteSize
]

{ #category : 'accessing' }
VGTiledFillDispatch >> context [
	^ context
]

{ #category : 'accessing' }
VGTiledFillDispatch >> deviceBuffers [
	"The device buffer of every binding, keyed by the name of the binding. Empty where no frame
	 has been drawn since I was last released."

	^ buffers
]

{ #category : 'dispatching' }
VGTiledFillDispatch >> dispatchOver: anEncoding [
	"One workgroup for every tile the frame touches."

	self timeStage: #dispatch during: [
		kernel
			dispatch: anEncoding touchedTileCount
			y: self class rowsPerDispatch
			z: self class layersPerDispatch ]
]

{ #category : 'drawing' }
VGTiledFillDispatch >> draw: anEncoding into: aByteArray [
	"One frame on the device whose pixels the host then reads, which is every frame that ends in
	 a surface. The readback is what makes it so, and draw:into:readBack: is where a frame that
	 ends on the device says otherwise."

	^ self draw: anEncoding into: aByteArray readBack: true
]

{ #category : 'drawing' }
VGTiledFillDispatch >> draw: anEncoding into: aByteArray readBack: aBoolean [
	"One frame on the device: the blocks of the frame named, a buffer for every binding large
	 enough to hold them, the kernel of this tile extent prepared, one workgroup for every tile
	 the frame touches, and, where the caller asks for it, the target read back into the bytes it
	 came from. A frame that touches no tile has nothing to dispatch and leaves the pixels alone.
	 The readback is a request because a frame that ends on the device has no use for it: the
	 pixels stay in the target buffer, which the next frame of the same dispatch reads as its own
	 destination, and readbackInto: fetches them later if anyone asks.
	 Nothing of the device is destroyed at the end of a frame: the kernel, the pipeline and the
	 buffers are what unit 3.1 keeps for the session, the mapping of each buffer is what unit 3.4
	 keeps, and releaseDevice is what lets go of them.
	 Each step is one stage of the frame, which a plain dispatch evaluates and does not time: the
	 stages are what unit 3.0 measures a frame in, and measuring them anywhere but inside the
	 frame a tool really draws would measure a different frame."

	self timeStage: #writeBuffers during: [
		self packBlocksOf: anEncoding target: aByteArray ].
	anEncoding touchedTileCount = 0 ifTrue: [ ^ aByteArray ].
	self residentKernelFor: anEncoding.
	self growBuffers.
	self prepareOnce.
	self upload.
	self dispatchOver: anEncoding.
	aBoolean ifTrue: [ self readbackInto: aByteArray ].
	^ aByteArray
]

{ #category : 'encoding' }
VGTiledFillDispatch >> frameRecordOf: anEncoding [
	"The extent of the frame, which is what the kernel measures a pixel of the last tile of a row
	 or a column against. It is a WordArray and not a run of bytes, because it rides to the
	 device with the blocks of the encoding and they are all uploaded the one way."

	| answer extent |
	extent := anEncoding grid extent.
	answer := WordArray new: VGTiledFillKernel frameRecordWords.
	answer at: VGTiledFillKernel frameWidthField put: extent x.
	answer at: VGTiledFillKernel frameHeightField put: extent y.
	^ answer
]

{ #category : 'dispatching' }
VGTiledFillDispatch >> growBuffers [
	"Every binding holding a buffer large enough for the block of this frame. A buffer is made
	 when there is none and when the frame needs one larger than the last did, and it is never
	 made smaller: a frame that shrinks would otherwise pay an allocation for shrinking and
	 another for growing back. A grown buffer is pointed at by the descriptor set before the one
	 it replaces is destroyed, because a descriptor left pointing at freed memory takes the image
	 with it on the next dispatch."

	self timeStage: #allocate during: [
		VGTiledFillKernel bindingNames withIndexDo: [ :name :index |
			| needed held |
			needed := (self wordCountOfBlock: (blocks at: name))
			          * VGTiledFillKernel elementStride.
			held := buffers at: name ifAbsent: [ nil ].
			(held isNil or: [ held size < needed ]) ifTrue: [
				| grown |
				grown := VkBuffer
					         on: context device
					         size: needed
					         usage: VkBuffer storageBufferUsage.
				buffers at: name put: grown.
				prepared ifTrue: [
					kernel rebindBuffer: grown atBinding: index - 1 ].
				held ifNotNil: [ held destroy ] ] ] ]
]

{ #category : 'initialization' }
VGTiledFillDispatch >> initialize [
	super initialize.
	buffers := Dictionary new.
	prepared := false
]

{ #category : 'inspecting' }
VGTiledFillDispatch >> inspectorBuffers: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Buffers'>
	"What went to the device, binding by binding: the binding number, the name the kernel reads
	 it by, the element type it is read as, the words that went out, the first of them and the
	 host address the buffer is mapped at, which is the one mapping the session keeps."

	^ aBuilder newTable
		  addColumn: (SpStringTableColumn
				   title: 'Binding'
				   evaluated: [ :each | (each at: 1) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Name'
				   evaluated: [ :each | (each at: 2) asString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Read as'
				   evaluated: [ :each | (each at: 3) asString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Words'
				   evaluated: [ :each | (each at: 4) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'First words'
				   evaluated: [ :each | (each at: 5) printString ]);
		  addColumn: (SpStringTableColumn title: 'Mapped at' evaluated: [ :each |
					   (each at: 6)
						   ifNil: [ 'no buffer yet' ]
						   ifNotNil: [ :pointer | pointer printString ] ]);
		  items: self bufferRows;
		  yourself
]

{ #category : 'inspecting' }
VGTiledFillDispatch >> inspectorBuffersContext: aContext [
	aContext active: blocks isNotNil
]

{ #category : 'measuring' }
VGTiledFillDispatch >> isRecordingStages [
	^ stages notNil
]

{ #category : 'accessing' }
VGTiledFillDispatch >> kernel [
	"The kernel I keep prepared for my tile extent, or nil where no frame has been drawn since I
	 was last released."

	^ kernel
]

{ #category : 'measuring' }
VGTiledFillDispatch >> microsecondsOfStage: aSymbol [
	"What that stage cost over every frame I drew, or nil where it was never reached."

	^ self stageMicroseconds at: aSymbol ifAbsent: [ nil ]
]

{ #category : 'encoding' }
VGTiledFillDispatch >> packBlocksOf: anEncoding target: aByteArray [
	"The blocks of one frame named and kept, so that what a dispatch sent can be read after the
	 device is gone and what it would send can be read where no device computes at all. Nothing
	 is packed in the sense a frame once was: the blocks are the encoding's own arrays, and only
	 the frame record is written here."

	^ blocks := self blocksOf: anEncoding target: aByteArray
]

{ #category : 'dispatching' }
VGTiledFillDispatch >> prepareOnce [
	"The descriptor set, the pipeline and the command pool of my kernel, built on the first frame
	 of my tile extent and kept afterwards. A buffer grown later is pointed at by the set itself,
	 so a frame never prepares twice."

	prepared ifTrue: [ ^ self ].
	self timeStage: #prepare during: [
		VGTiledFillKernel bindingNames do: [ :name |
			kernel bindBuffer: (buffers at: name) ].
		kernel prepare.
		prepared := true ]
]

{ #category : 'printing' }
VGTiledFillDispatch >> printOn: aStream [
	aStream nextPutAll: self class name.
	blocks ifNil: [ ^ self ].
	aStream
		nextPutAll: ' of ';
		print: (blocks at: #target) size / VGTiledFillEncoding targetFormat bytesPerPixel;
		nextPutAll: ' pixels'
]

{ #category : 'dispatching' }
VGTiledFillDispatch >> readbackInto: aByteArray [
	"The target buffer read back into the bytes it was written from."

	self timeStage: #readback during: [
		(buffers at: #target) readbackInto: aByteArray ]
]

{ #category : 'measuring' }
VGTiledFillDispatch >> recordStages [
	"Time every stage of the frames I draw from here on. A dispatch of a running tool does not,
	 because the clock is read twice a stage and a stage can be shorter than the reading; the
	 benchmark asks, and nothing else does."

	stages := Dictionary new.
	^ self
]

{ #category : 'releasing' }
VGTiledFillDispatch >> releaseDevice [
	"Everything of the device I hold destroyed, the kernel before the buffers, because a buffer
	 freed under a live pipeline takes the image with it. I am drawable again afterwards and build
	 what the next frame needs: the session that holds me releases me when the device goes, and a
	 frame of another tile extent releases me for itself."

	kernel ifNotNil: [
		kernel destroy.
		kernel := nil ].
	buffers valuesDo: [ :each | each destroy ].
	buffers removeAll.
	prepared := false.
	tileExtent := nil
]

{ #category : 'dispatching' }
VGTiledFillDispatch >> residentKernelFor: anEncoding [
	"The kernel of my tile extent, compiled on the first frame and kept for every frame after it.
	 A frame of another tile extent needs another module and another pipeline, so it releases what
	 I hold first: the device objects of a tile extent are of no use to any other."

	^ self timeStage: #module during: [
		  | extent |
		  extent := anEncoding grid tileExtent.
		  extent = tileExtent ifFalse: [
			  self releaseDevice.
			  tileExtent := extent ].
		  kernel ifNil: [
			  kernel := PVComputeKernel
				            on: context
				            spirv: (VGTiledFillKernel spirvOnTileExtent: extent) ].
		  kernel ]
]

{ #category : 'initialization' }
VGTiledFillDispatch >> setContext: aContext [
	context := aContext
]

{ #category : 'measuring' }
VGTiledFillDispatch >> stageMicroseconds [
	"What each stage of the frames I drew cost, summed over every frame, keyed by stage name. A
	 stage that was never reached is absent rather than nought, so that a frame which returned
	 early can be told from one whose stage was too fast to measure."

	^ stages ifNil: [ Dictionary new ]
]

{ #category : 'measuring' }
VGTiledFillDispatch >> timeStage: aSymbol during: aBlock [
	"The block, answering what it answers, with the microseconds it took added to that stage
	 where a caller asked for the stages. A dispatch that was not asked evaluates the block and
	 reads no clock at all, so the stages cost a running tool nothing."

	| answer started |
	stages ifNil: [ ^ aBlock value ].
	started := Time microsecondClockValue.
	answer := aBlock value.
	stages
		at: aSymbol
		put: (stages at: aSymbol ifAbsent: [ 0 ])
			+ (Time microsecondClockValue - started).
	^ answer
]

{ #category : 'dispatching' }
VGTiledFillDispatch >> upload [
	"The words of each block into the buffer kept for it, the two held together by the name of
	 the binding. The copy reads the block's own memory, so a frame pays one copy a binding and
	 not two."

	self timeStage: #upload during: [
		VGTiledFillKernel bindingNames do: [ :name |
			| block |
			block := blocks at: name.
			(buffers at: name)
				uploadBits: block
				byteCount: (self byteCountOfBlock: block) ] ]
]

{ #category : 'encoding' }
VGTiledFillDispatch >> wordCountOfBlock: aBlock [
	"The words a buffer holds for that block, which is never none: an empty binding still owes
	 the device a buffer."

	^ (self byteCountOfBlock: aBlock) / VGTiledFillKernel elementStride
		  max: self class emptyBufferWordCount
]

{ #category : 'inspecting' }
VGTiledFillDispatch >> wordOfBlock: aBlock at: anIndex [
	"One word of a block as the kernel reads it, counted from one. A WordArray and a
	 Float32Array hold a word an element and answer it themselves; the pixels of the target are
	 a run of bytes, and four of them make the word."

	^ (aBlock isKindOf: ByteArray)
		  ifTrue: [
			  aBlock uint32AtOffset:
				  anIndex - 1 * VGTiledFillKernel elementStride ]
		  ifFalse: [ aBlock at: anIndex ]
]
