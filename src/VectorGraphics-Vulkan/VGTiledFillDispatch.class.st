"
I send one encoded frame of the tiled fill subset to a Vulkan device and bring its pixels back.

A frame arrives as a `VGTiledFillEncoding` and a run of bytes holding the destination pixels packed row after row. I allocate one storage buffer for every binding `VGTiledFillKernel` declares, upload the bytes of each, dispatch one workgroup for every tile the frame touches, and read the target buffer back into the bytes it came from. `draw:into:` is the whole of it, and `bytesOf:target:` is what it uploads, which needs no device and is held by a test on every machine.

The words and the floats of an encoding are read through `basicAt:`, which answers the stored word of a `WordArray` and the bit pattern of a `Float32Array`, so one method narrows both and neither is bitcast through a Float. The extent is the one thing an encoding does not carry into a buffer, so I write the frame record myself.

I take a context and never make one: the backend owns the device, and a dispatch owns the buffers of one frame alone. The kernel is destroyed before the buffers, since a buffer freed under a live pipeline takes the image with it.
"
Class {
	#name : 'VGTiledFillDispatch',
	#superclass : 'Object',
	#traits : 'TVGStageRecording',
	#classTraits : 'TVGStageRecording classTrait',
	#instVars : [
		'context',
		'kernel',
		'buffers',
		'tileExtent',
		'prepared',
		'blocks',
		'commandPool'
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
VGTiledFillDispatch class >> bufferUsage [
	"What every buffer of a frame is created for. The storage bit is what the kernel reads and
	 writes them through; the transfer source bit is what lets the target buffer be the source
	 of a copy into an image, which is how a frame that ends on the device ends. One usage for
	 every binding rather than one for the target and another for the rest: a buffer that is
	 never copied pays nothing for being allowed to be."

	^ VkBufferUsage storageBufferBit bitOr: VkBufferUsage transferSrcBit
]

{ #category : 'constants' }
VGTiledFillDispatch class >> clearedOnTheDeviceLabel [
	"What the buffer table says of a binding no block of the frame names: the destination of a
	 frame that ends on the device, which the device clears and the kernel then writes."

	^ 'cleared on the device'
]

{ #category : 'constants' }
VGTiledFillDispatch class >> clearedTargetWord [
	"The word a cleared destination pixel holds: transparent black, four zero bytes, which is
	 what the host destination of a frame that reads back starts as."

	^ 0
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
	 order the drawing methods wrap them in and the order a report shows them in. This table is
	 the only place that names a stage: a report reads it, and a test reads the source of the
	 frame against it so that a stage cannot be timed under a name no report shows.
	 The first of them is named writeBuffers for the frames of units 3.0 to 3.3, where it packed
	 the words of the already built encoding into runs of bytes; since unit 3.4 it writes the
	 frame record alone and names the blocks the upload reads, and the name is kept so that the
	 figures of every unit can be read against each other. It is not the building of the
	 encoding, which a frame pays before a dispatch is asked for anything.
	 There is no release among them, because unit 3.1 keeps the device objects of a frame for the
	 session and a frame pays nothing to let go of them. There is no clear either: unit 7.5 gave
	 the fill of the destination a stage of its own, and unit 7.6 folded that fill into the
	 command buffer of the dispatch, where it is a part of the dispatch and no longer a stage.
	 Two of them are paid by one kind of frame each: a frame that ends on the device copies its
	 target buffer into an image, and a frame that asks for its pixels pays the readback. A
	 report shows a row for the ones its frame paid."
	^ #( #writeBuffers #module #allocate #prepare #upload #dispatch #copy
	     #readback )
]

{ #category : 'constants' }
VGTiledFillDispatch class >> uploadedFromTheHostLabel [
	"What the buffer table says of a binding the frame uploaded."

	^ 'uploaded from the host'
]

{ #category : 'encoding' }
VGTiledFillDispatch >> blockOfBinding: aName [
	"The words the host gave that binding for this frame, or nil when it gave none. A frame
	 that ends on the device gives none for the destination: the pixels the kernel composes
	 over are in its buffer already."
	^ blocks at: aName ifAbsent: [ nil ]
]

{ #category : 'accessing' }
VGTiledFillDispatch >> blocks [
	"What the last frame uploaded, by binding name: one block of words a binding, kept so that
	 what a dispatch sent can be read after the device is gone."

	^ blocks
]

{ #category : 'encoding' }
VGTiledFillDispatch >> blocksOf: anEncoding [
	"The block of words of every binding the kernel reads off the encoding itself, by name,
	 plus the frame record written here. The destination pixels are not among them: a frame
	 that ends on the device composes over what the target buffer already holds, and a frame
	 that reads back names its own destination through blocksOf:target:."

	| answer |
	answer := Dictionary new.
	(VGTiledFillKernel bindingNames
		 reject: [ :each | self class bindingsNotOfAnEncoding includes: each ])
		do: [ :each | answer at: each put: (anEncoding perform: each) ].
	answer at: #frame put: (self frameRecordOf: anEncoding).
	^ answer
]

{ #category : 'encoding' }
VGTiledFillDispatch >> blocksOf: anEncoding target: aByteArray [
	"The blocks of the encoding and the destination pixels the caller owns, which is the frame
	 that ends in the host. Nothing is copied: a WordArray and a Float32Array already hold
	 their elements in the order and the width a storage buffer reads them, so the upload
	 writes out of these very objects."
	^ (self blocksOf: anEncoding)
		  at: VGTiledFillKernel targetBinding put: aByteArray;
		  yourself
]

{ #category : 'accessing' }
VGTiledFillDispatch >> bufferOfBinding: aName [
	"The device buffer kept for that binding, or nil where no frame has needed one yet. The
	 companion of blockOfBinding:, which answers what the host filled it with."
	^ buffers at: aName ifAbsent: [ nil ]
]

{ #category : 'inspecting' }
VGTiledFillDispatch >> bufferRowOfBinding: aName at: anIndex [
	"What the kernel reads that binding as, how many words it holds, the first of them, the
	 host address its buffer is mapped at and where the words came from. The words are read out
	 of the block the device was given rather than out of the encoding, and the address is
	 asked of the buffer itself, so a row cannot say the frame sent something it did not or
	 that a mapping is held where none is."
	| block count |
	block := self blockOfBinding: aName.
	count := self wordCountOfBinding: aName filledBy: block.
	^ {
		  (anIndex - 1).
		  aName.
		  ((VGTiledFillKernel floatBindingNames includes: aName)
			   ifTrue: [ #float32 ]
			   ifFalse: [ #uint32 ]).
		  count.
		  (self firstWordsOfBlock: block upTo: count).
		  (buffers
			   at: aName
			   ifPresent: [ :buffer | buffer mappingOrNil ]
			   ifAbsent: [ nil ]).
		  (block
			   ifNil: [ self class clearedOnTheDeviceLabel ]
			   ifNotNil: [ self class uploadedFromTheHostLabel ]) }
]

{ #category : 'inspecting' }
VGTiledFillDispatch >> bufferRows [
	"One row a binding, in the order the descriptor set holds them."

	^ VGTiledFillKernel bindingNames withIndexCollect: [ :name :index |
		  self bufferRowOfBinding: name at: index ]
]

{ #category : 'encoding' }
VGTiledFillDispatch >> bufferSizeForBinding: aName in: anEncoding [
	"The bytes the buffer of that binding must hold for this frame: what the binding owes the
	 device, rounded up to a whole number of elements and never smaller than the empty buffer,
	 because a storage buffer of no bytes is refused at descriptor update."
	^ ((self byteCountOfBinding: aName in: anEncoding)
	    / VGTiledFillKernel elementStride
	    max: self class emptyBufferWordCount)
	  * VGTiledFillKernel elementStride
]

{ #category : 'encoding' }
VGTiledFillDispatch >> byteCountOfBinding: aName in: anEncoding [
	"The bytes the buffer of that binding owes the device. A binding the host filled is as
	 large as its block; the one it did not is the destination of a frame that ends on the
	 device, and its size is the encoding's own rule, since no host block states it."
	^ (self blockOfBinding: aName)
		  ifNil: [ anEncoding targetByteCount ]
		  ifNotNil: [ :block | self byteCountOfBlock: block ]
]

{ #category : 'encoding' }
VGTiledFillDispatch >> byteCountOfBlock: aBlock [
	"The bytes of that block, asked of the block itself: a WordArray counts words, a Float32Array
	 counts floats and the pixels of the target count bytes, while the device is given bytes
	 either way."

	^ aBlock byteSize
]

{ #category : 'drawing' }
VGTiledFillDispatch >> clearAndDispatchOver: anEncoding [
	"One workgroup for every tile the frame touches, with the fill of the destination recorded
	 in front of it where the frame brings none from the host, in one command buffer and one
	 submission. Unit 7.5 filled the destination in a submission of its own, which cost a frame
	 that ends on the device a second wait on the queue; unit 7.6 measured that and folded it in
	 here.
	 The barrier between the two is what makes the fold legal: the fill is a transfer write and
	 the kernel reads those pixels through a storage buffer, and a fill and a dispatch in one
	 command buffer are not ordered against each other without it.
	 A frame that brings its own destination fills nothing: the upload overwrites every pixel
	 the kernel reads."
	self timeStage: #dispatch during: [
		| command |
		command := self frameCommandPool allocateBuffer.
		command do: [ :recorder |
			(self hostFilled: VGTiledFillKernel targetBinding) ifFalse: [
				recorder
					recordFillOfBuffer:
					(self bufferOfBinding: VGTiledFillKernel targetBinding)
					with: self class clearedTargetWord.
				recorder recordFillToComputeBarrier ].
			kernel
				recordComputeInto: recorder
				groupsAcross: anEncoding touchedTileCount
				down: self class rowsPerDispatch
				layers: self class layersPerDispatch ].
		context computeQueue submit: command andWait: true ]
]

{ #category : 'drawing' }
VGTiledFillDispatch >> computeFrameOf: anEncoding [
	"The steps of one frame on the device: the kernel of this tile extent prepared, a buffer for
	 every binding large enough to hold what the frame owes it, the blocks uploaded and one
	 workgroup dispatched for every tile the frame touches, with the destination filled in front
	 of that dispatch where the frame brings none from the host. A frame that touches no tile
	 has nothing to dispatch and leaves the pixels alone.
	 Nothing of the device is destroyed at the end of a frame: the kernel, the pipeline and the
	 buffers are what unit 3.1 keeps for the session and releaseDevice is what lets go of them."
	anEncoding touchesNoTile ifTrue: [ ^ self ].
	self residentKernelFor: anEncoding.
	self growBuffersFor: anEncoding.
	self prepareOnce.
	self upload.
	self clearAndDispatchOver: anEncoding
]

{ #category : 'accessing' }
VGTiledFillDispatch >> context [
	^ context
]

{ #category : 'drawing' }
VGTiledFillDispatch >> copyTargetInto: anImage [
	"The target buffer into that image, in one submission of my own, for a frame that nobody
	 else is recording around. The command pool is kept for the session like everything else of
	 the device here, so a frame pays one allocation of a command buffer and not one of a pool."
	self timeStage: #copy during: [
		| command |
		command := self frameCommandPool allocateBuffer.
		command do: [ :recorder | self recordCopyInto: anImage in: recorder ].
		context computeQueue submit: command andWait: true ]
]

{ #category : 'accessing' }
VGTiledFillDispatch >> deviceBuffers [
	"The device buffer of every binding, keyed by the name of the binding. Empty where no frame
	 has been drawn since I was last released."

	^ buffers
]

{ #category : 'drawing' }
VGTiledFillDispatch >> draw: anEncoding [
	"One frame that ends on the device, drawn into the target buffer I own. No destination
	 comes from the host and none goes back to it: the pixels this frame composes over are the
	 ones the buffer already holds, which is what unit 7.5 removed the upload for, and
	 readbackInto: fetches the result later if anyone asks."

	self timeStage: #writeBuffers during: [ self packBlocksOf: anEncoding ].
	self computeFrameOf: anEncoding
]

{ #category : 'drawing' }
VGTiledFillDispatch >> draw: anEncoding endingIn: anImage [
	"One frame that ends on the device: drawn with no host destination and no readback, then
	 the target buffer copied into that image. Nothing of the frame reaches the host, which is
	 the whole point of the unit; the caller owns the image and the layout it wants it in
	 afterwards, because the chain that presents it has its own semaphores to fit around the
	 transition.

	 A frame that touches no tile dispatches nothing and copies nothing: the image holds
	 whatever it held, which is what the target buffer holds too."

	self draw: anEncoding.
	anEncoding touchesNoTile ifTrue: [ ^ anImage ].
	self copyTargetInto: anImage.
	^ anImage
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
	"One frame that ends in the host: the destination pixels are the caller's and they are
	 uploaded with the blocks of the encoding, because only the caller knows what has touched
	 them since the last frame. The readback is a request because a caller that means to read
	 them later asks readbackInto: for them then.

	 A frame that touches no tile has nothing to dispatch and leaves the pixels alone."

	self timeStage: #writeBuffers during: [
		self packBlocksOf: anEncoding target: aByteArray ].
	anEncoding touchesNoTile ifTrue: [ ^ aByteArray ].
	self computeFrameOf: anEncoding.
	aBoolean ifTrue: [ self readbackInto: aByteArray ].
	^ aByteArray
]

{ #category : 'inspecting' }
VGTiledFillDispatch >> firstWordsOfBlock: aBlock upTo: aCount [
	"The first words of that block, as many of them as a row shows. A binding with no block
	 shows none: its words are on the device, and reading them back is what the frame that
	 leaves them there was built to avoid."

	aBlock ifNil: [ ^ #(  ) ].
	^ (1 to: (aCount min: self class shownWordCount)) collect: [ :word |
		  self wordOfBlock: aBlock at: word ]
]

{ #category : 'accessing' }
VGTiledFillDispatch >> frameCommandPool [
	"The pool this dispatch cuts its own command buffers from — the one a frame is dispatched
	 in and the one a copy into an image is recorded in — made on the first frame and kept until
	 the device is released. The kernel has a pool of its own, which is where the blur's passes
	 are recorded."
	^ commandPool ifNil: [
		  commandPool := context device createCommandPool:
			              context computeQueueFamily ]
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
VGTiledFillDispatch >> growBuffersFor: anEncoding [
	"Every binding holding a buffer large enough for this frame. A buffer is made when there is
	 none and when the frame needs one larger than the last did, and it is never made smaller: a
	 frame that shrinks would otherwise pay an allocation for shrinking and another for growing
	 back. A grown buffer is pointed at by the descriptor set before the one it replaces is
	 destroyed, because a descriptor left pointing at freed memory takes the image with it on
	 the next dispatch."
	self timeStage: #allocate during: [
		VGTiledFillKernel bindingNames withIndexDo: [ :name :index |
			| needed held |
			needed := self bufferSizeForBinding: name in: anEncoding.
			held := buffers at: name ifAbsent: [ nil ].
			(held isNil or: [ held size < needed ]) ifTrue: [
				| grown |
				grown := VkBuffer
					         on: context device
					         size: needed
					         usage: self class bufferUsage.
				buffers at: name put: grown.
				prepared ifTrue: [
					kernel rebindBuffer: grown atBinding: index - 1 ].
				held ifNotNil: [ held destroy ] ] ] ]
]

{ #category : 'encoding' }
VGTiledFillDispatch >> hostFilled: aName [
	"Whether the host gave that binding words of its own for this frame."
	^ (self blockOfBinding: aName) notNil
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
	 it by, the element type it is read as, the words it holds, the first of them, the host
	 address the buffer is mapped at, which is the one mapping the session keeps, and where the
	 words came from. The last column is how the destination of a frame that ends on the device
	 is told from one the host filled: it shows no words, because nothing read them back."

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
		  addColumn: (SpStringTableColumn
				   title: 'Filled by'
				   evaluated: [ :each | (each at: 7) asString ]);
		  items: self bufferRows;
		  yourself
]

{ #category : 'inspecting' }
VGTiledFillDispatch >> inspectorBuffersContext: aContext [
	aContext active: blocks isNotNil
]

{ #category : 'inspector' }
VGTiledFillDispatch >> inspectorStages: aBuilder [
	<inspectorPresentationOrder: 20 title: 'Stages'>
	"What the frames I drew cost, stage by stage. A stage shows as unreached rather than as
	 nought, which is how a frame that ended on the device is told from one read back into the
	 host: the first pays the copy and never the readback, the second the other way about. A
	 dispatch that was never asked to record its stages shows every row unreached, because
	 reading the clock twice a stage is a cost a running tool does not pay."

	^ aBuilder newTable
		  addColumn: (SpStringTableColumn
				   title: 'Stage'
				   evaluated: [ :each | (each at: 1) asString ]);
		  addColumn: (SpStringTableColumn title: 'Microseconds' evaluated: [
					   :each |
					   (each at: 2)
						   ifNil: [ 'not reached' ]
						   ifNotNil: [ :microseconds | microseconds printString ] ]);
		  items: self stageRows;
		  yourself
]

{ #category : 'inspector' }
VGTiledFillDispatch >> inspectorStagesContext: aContext [
	"The table of stages stands as soon as the class names them, which is always: a dispatch
	 that drew nothing shows every row unreached, and that is a fact worth showing."

	aContext active: true
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
VGTiledFillDispatch >> packBlocksOf: anEncoding [
	"The blocks of one frame that ends on the device, named and kept, so that what a dispatch
	 sent can be read after the device is gone. Nothing is packed: the blocks are the
	 encoding's own arrays, and only the frame record is written here."

	^ blocks := self blocksOf: anEncoding
]

{ #category : 'encoding' }
VGTiledFillDispatch >> packBlocksOf: anEncoding target: aByteArray [
	"The blocks of one frame named and kept, so that what a dispatch sent can be read after the
	 device is gone and what it would send can be read where no device computes at all. Nothing
	 is packed in the sense a frame once was: the blocks are the encoding's own arrays, and only
	 the frame record is written here."

	^ blocks := self blocksOf: anEncoding target: aByteArray
]

{ #category : 'drawing' }
VGTiledFillDispatch >> prepareOnce [
	"The descriptor set, the pipeline and the command pool of my kernel, built on the first frame
	 of my tile extent and kept afterwards. A buffer grown later is pointed at by the set itself,
	 so a frame never prepares twice."
	prepared ifTrue: [ ^ self ].
	self timeStage: #prepare during: [
		VGTiledFillKernel bindingNames do: [ :name |
			kernel bindBuffer: (self bufferOfBinding: name) ].
		kernel prepare.
		prepared := true ]
]

{ #category : 'printing' }
VGTiledFillDispatch >> printOn: aStream [
	aStream nextPutAll: self class name.
	blocks ifNil: [ ^ self ].
	aStream
		nextPutAll: ' of ';
		print: (blocks at: VGTiledFillKernel targetBinding) size
			/ VGTiledFillEncoding targetFormat bytesPerPixel;
		nextPutAll: ' pixels'
]

{ #category : 'drawing' }
VGTiledFillDispatch >> readbackInto: aByteArray [
	"The target buffer read back into the bytes it was written from."
	self timeStage: #readback during: [
		(self bufferOfBinding: VGTiledFillKernel targetBinding) readbackInto:
			aByteArray ]
]

{ #category : 'drawing' }
VGTiledFillDispatch >> recordCopyInto: anImage in: aRecorder [
	"The target buffer into that image, recorded and not submitted: the image moved to the
	 layout a copy writes into and the whole extent copied. The caller owns the submission, so
	 a presented frame can fit the copy between the semaphores its chain waits on and signals.
	 The region is freed here because the driver has read it by the time recording returns."
	| region |
	region := VkCommandBuffer regionForExtent: anImage extent.
	[
	anImage transitionTo: VkImageLayout transferDstOptimal in: aRecorder.
	aRecorder
		recordCopyOfBuffer:
		(self bufferOfBinding: VGTiledFillKernel targetBinding)
		toImage: anImage
		layout: VkImageLayout transferDstOptimal
		region: region ] ensure: [ region getHandle free ]
]

{ #category : 'device' }
VGTiledFillDispatch >> releaseDevice [
	"Everything of the device I hold destroyed, the kernel before the buffers, because a buffer
	 freed under a live pipeline takes the image with it. I am drawable again afterwards and build
	 what the next frame needs: the session that holds me releases me when the device goes, and a
	 frame of another tile extent releases me for itself."

	kernel ifNotNil: [
		kernel destroy.
		kernel := nil ].
	buffers valuesDo: [ :each | each destroy ].
	commandPool ifNotNil: [
		commandPool destroy.
		commandPool := nil ].
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

{ #category : 'accessing' }
VGTiledFillDispatch >> stageRows [
	"Every stage a frame can pay, in the order the table names them, each with what the frames
	 I drew paid for it or nil where it was never reached. The names are read off the table
	 itself, so a stage cannot be shown here under a name no report shows, and the two last
	 rows are where the kind of frame I drew can be read: one of them is always unreached."

	^ self class stageNames collect: [ :each |
		  {
			  each.
			  (self microsecondsOfStage: each) } ]
]

{ #category : 'drawing' }
VGTiledFillDispatch >> upload [
	"The words of each block into the buffer kept for it, the two held together by the name of
	 the binding. The copy reads the block's own memory, so a frame pays one copy a binding and
	 not two. A binding the host did not fill sends nothing: the destination of a frame that
	 ends on the device is already in its buffer, which is what unit 7.5 removed the transfer
	 for."
	self timeStage: #upload during: [
		VGTiledFillKernel bindingNames do: [ :name |
			(self blockOfBinding: name) ifNotNil: [ :block |
				(self bufferOfBinding: name)
					uploadBits: block
					byteCount: (self byteCountOfBlock: block) ] ] ]
]

{ #category : 'inspecting' }
VGTiledFillDispatch >> wordCountOfBinding: aName filledBy: aBlock [
	"The words the buffer of that binding holds. A binding no block names is the destination of
	 a frame that ends on the device: its words are counted off the buffer, which is the only
	 thing that knows how many there are."

	aBlock ifNotNil: [
		^ (self byteCountOfBlock: aBlock) / VGTiledFillKernel elementStride ].
	^ (buffers
		   at: aName
		   ifPresent: [ :buffer | buffer size ]
		   ifAbsent: [ 0 ]) / VGTiledFillKernel elementStride
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
