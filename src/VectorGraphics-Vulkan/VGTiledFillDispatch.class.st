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
		'bytes',
		'stages'
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
	 order draw:into: wraps them in and the order a report shows them in. This table is the
	 only place that names a stage: a report reads it, and a test reads the source of draw:into:
	 against it so that a stage cannot be timed under a name no report shows.
	 The first of them writes the buffers of the already built encoding and is not the building
	 of that encoding, which a frame pays before a dispatch is asked for anything."

	^ #( #writeBuffers #module #allocate #prepare #upload #dispatch #readback
	     #release )
]

{ #category : 'inspecting' }
VGTiledFillDispatch >> bufferRows [
	"One row a binding, in the order the descriptor set holds them: what the kernel reads it as,
	 how many words went out and the first words of them, read out of the bytes themselves rather
	 than out of the encoding, so that what is shown is what the device was given."

	| stride |
	stride := VGTiledFillKernel elementStride.
	^ VGTiledFillKernel bindingNames withIndexCollect: [ :name :index |
		  | run count |
		  run := bytes at: name.
		  count := run size / stride.
		  {
			  (index - 1).
			  name.
			  ((VGTiledFillKernel floatBindingNames includes: name)
				   ifTrue: [ #float32 ]
				   ifFalse: [ #uint32 ]).
			  count.
			  ((1 to: (count min: self class shownWordCount)) collect: [ :word |
				   (VGTiledFillKernel floatBindingNames includes: name)
					   ifTrue: [ run float32AtOffset: word - 1 * stride ]
					   ifFalse: [ run uint32AtOffset: word - 1 * stride ] ]) } ]
]

{ #category : 'accessing' }
VGTiledFillDispatch >> bytes [
	"What the last frame uploaded, by binding name, kept so that it can be read after the device
	 is gone."

	^ bytes
]

{ #category : 'dispatching' }
VGTiledFillDispatch >> bytesOf: anEncoding target: aByteArray [
	"The bytes of every binding the kernel reads, by name: the buffers of the encoding as they
	 lie in object memory, the pixels of the target as they are, and the frame record written
	 here. The names are the contract of the kernel with the two that are not an encoding buffer
	 taken off it, so a binding added to that contract is named in one place and reaches the
	 device without this method being edited."

	| answer |
	answer := Dictionary new.
	(VGTiledFillKernel bindingNames
		 reject: [ :each | self class bindingsNotOfAnEncoding includes: each ])
		do: [ :each |
			answer at: each put: (self bytesOfWords: (anEncoding perform: each)) ].
	answer at: #target put: aByteArray.
	answer at: #frame put: (self frameRecordOf: anEncoding).
	^ answer
]

{ #category : 'encoding' }
VGTiledFillDispatch >> bytesOfWords: aBitsArray [
	"One run of bytes holding the words of that array in the order and the width the device reads
	 them. basicAt: answers the stored word of a WordArray and the bit pattern of a Float32Array,
	 so one method narrows both and a float is never bitcast through a Float on the way."

	| answer stride |
	stride := VGTiledFillKernel elementStride.
	answer := ByteArray new: aBitsArray size * stride.
	1 to: aBitsArray size do: [ :index |
		answer
			uint32AtOffset: index - 1 * stride
			put: (aBitsArray basicAt: index) ].
	^ answer
]

{ #category : 'accessing' }
VGTiledFillDispatch >> context [
	^ context
]

{ #category : 'dispatching' }
VGTiledFillDispatch >> dispatch: aKernel over: anEncoding [
	"One workgroup for every tile the frame touches."

	self timeStage: #dispatch during: [
		aKernel
			dispatch: anEncoding touchedTileCount
			y: self class rowsPerDispatch
			z: self class layersPerDispatch ]
]

{ #category : 'dispatching' }
VGTiledFillDispatch >> draw: anEncoding into: aByteArray [
	"One frame on the device: a buffer for every binding, the bytes of each uploaded, one
	 workgroup for every tile the frame touches, and the target read back into the bytes it came
	 from. A frame that touches no tile has nothing to dispatch and leaves the pixels alone.
	 Each step is one stage of the frame, which a plain dispatch evaluates and does not time: the
	 stages are what unit 3.0 measures a frame in, and measuring them anywhere but inside the
	 frame a tool really draws would measure a different frame."

	| kernel buffers |
	self
		timeStage: #writeBuffers
		during: [ self encode: anEncoding target: aByteArray ].
	anEncoding touchedTileCount = 0 ifTrue: [ ^ aByteArray ].
	kernel := self kernelOf: anEncoding.
	buffers := self newBuffers.
	[
	self prepare: kernel on: buffers.
	self upload: buffers.
	self dispatch: kernel over: anEncoding.
	self readback: buffers into: aByteArray ] ensure: [
		self release: kernel and: buffers ].
	^ aByteArray
]

{ #category : 'encoding' }
VGTiledFillDispatch >> encode: anEncoding target: aByteArray [
	"The bytes of one frame, kept so that what a dispatch sent can be read after the device is
	 gone. A frame is encoded on its own where no device computes, which is what an example on a
	 machine with no driver can still show."

	^ bytes := self bytesOf: anEncoding target: aByteArray
]

{ #category : 'encoding' }
VGTiledFillDispatch >> frameRecordOf: anEncoding [
	"The extent of the frame, which is what the kernel measures a pixel of the last tile of a row
	 or a column against."

	| answer stride extent |
	stride := VGTiledFillKernel elementStride.
	extent := anEncoding grid extent.
	answer := ByteArray new: VGTiledFillKernel frameRecordWords * stride.
	answer
		uint32AtOffset: VGTiledFillKernel frameWidthField - 1 * stride
		put: extent x.
	answer
		uint32AtOffset: VGTiledFillKernel frameHeightField - 1 * stride
		put: extent y.
	^ answer
]

{ #category : 'inspecting' }
VGTiledFillDispatch >> inspectorBuffers: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Buffers'>
	"What went to the device, binding by binding: the binding number, the name the kernel reads
	 it by, the element type it is read as, the words that went out and the first of them."

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
		  items: self bufferRows;
		  yourself
]

{ #category : 'inspecting' }
VGTiledFillDispatch >> inspectorBuffersContext: aContext [
	aContext active: bytes isNotNil
]

{ #category : 'measuring' }
VGTiledFillDispatch >> isRecordingStages [
	^ stages notNil
]

{ #category : 'dispatching' }
VGTiledFillDispatch >> kernelOf: anEncoding [
	"The compiled kernel for the tile extent of that encoding. The module comes from
	 VGTiledFillKernel's cache, because it depends on the tile extent alone."

	^ self
		  timeStage: #module
		  during: [
			  PVComputeKernel
				  on: context
				  spirv:
				  (VGTiledFillKernel spirvOnTileExtent: anEncoding grid tileExtent) ]
]

{ #category : 'measuring' }
VGTiledFillDispatch >> microsecondsOfStage: aSymbol [
	"What that stage cost over every frame I drew, or nil where it was never reached."

	^ self stageMicroseconds at: aSymbol ifAbsent: [ nil ]
]

{ #category : 'dispatching' }
VGTiledFillDispatch >> newBuffers [
	"One device buffer for every binding of the kernel, sized by the bytes written for it."

	^ self
		  timeStage: #allocate
		  during: [
			  VGTiledFillKernel bindingNames collect: [ :each |
				  VkBuffer
					  storageBuffer: (self wordCountOf: (bytes at: each))
					  on: context device ] ]
]

{ #category : 'dispatching' }
VGTiledFillDispatch >> prepare: aKernel on: aCollectionOfBuffers [
	"Every buffer bound in binding order, then the descriptor set and the pipeline built."

	self timeStage: #prepare during: [
		aCollectionOfBuffers do: [ :each | aKernel bindBuffer: each ].
		aKernel prepare ]
]

{ #category : 'printing' }
VGTiledFillDispatch >> printOn: aStream [
	aStream nextPutAll: self class name.
	bytes ifNil: [ ^ self ].
	aStream
		nextPutAll: ' of ';
		print: (bytes at: #target) size / VGTiledFillEncoding targetFormat bytesPerPixel;
		nextPutAll: ' pixels'
]

{ #category : 'dispatching' }
VGTiledFillDispatch >> readback: aCollectionOfBuffers into: aByteArray [
	"The target buffer read back into the bytes it was written from."

	self timeStage: #readback during: [
		(aCollectionOfBuffers
			 at: (VGTiledFillKernel bindingNames indexOf: #target))
			readbackInto: aByteArray ]
]

{ #category : 'measuring' }
VGTiledFillDispatch >> recordStages [
	"Time every stage of the frames I draw from here on. A dispatch of a running tool does not,
	 because the clock is read twice a stage and a stage can be shorter than the reading; the
	 benchmark asks, and nothing else does."

	stages := Dictionary new.
	^ self
]

{ #category : 'dispatching' }
VGTiledFillDispatch >> release: aKernel and: aCollectionOfBuffers [
	"The kernel is destroyed before the buffers, because a buffer freed under a live pipeline
	 takes the image with it."

	self timeStage: #release during: [
		aKernel destroy.
		aCollectionOfBuffers do: [ :each | each destroy ] ]
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
VGTiledFillDispatch >> upload: aCollectionOfBuffers [
	"The bytes of each binding into the buffer that was sized for it, the two held together by
	 the index of the binding name."

	self timeStage: #upload during: [
		VGTiledFillKernel bindingNames withIndexDo: [ :each :index |
			(aCollectionOfBuffers at: index) uploadBytes: (bytes at: each) ] ]
]

{ #category : 'encoding' }
VGTiledFillDispatch >> wordCountOf: aByteArray [
	"The words a buffer holds, which is never none: an empty binding still owes the device a
	 buffer."

	^ aByteArray size / VGTiledFillKernel elementStride
		  max: self class emptyBufferWordCount
]
