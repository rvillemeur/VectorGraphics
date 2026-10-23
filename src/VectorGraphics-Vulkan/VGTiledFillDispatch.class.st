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
		'bytes'
	],
	#category : 'VectorGraphics-Vulkan-Tiles',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Tiles'
}

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
	"The bytes of every binding the kernel reads, by name: the three word buffers and the four
	 float buffers of the encoding as they lie in object memory, the pixels of the target as
	 they are, and the frame record written here, because the extent is the one thing an
	 encoding does not carry into a buffer."

	| answer |
	answer := Dictionary new.
	#( #tileTable #entryRefs #headers ) do: [ :each |
		answer at: each put: (self bytesOfWords: (anEncoding perform: each)) ].
	#( #clips #edges #paints #stops ) do: [ :each |
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

{ #category : 'drawing' }
VGTiledFillDispatch >> draw: anEncoding into: aByteArray [
	"One frame on the device: a buffer for every binding, the bytes of each uploaded, one
	 workgroup for every tile the frame touches, and the target read back into the bytes it came
	 from. A frame that touches no tile has nothing to dispatch and leaves the pixels alone. The
	 kernel is destroyed before the buffers, because a buffer freed under a live pipeline takes
	 the image with it."

	| kernel buffers names |
	self encode: anEncoding target: aByteArray.
	anEncoding touchedTileCount = 0 ifTrue: [ ^ aByteArray ].
	names := VGTiledFillKernel bindingNames.
	kernel := PVComputeKernel
		          on: context
		          spirv:
		          (VGTiledFillKernel onTileExtent: anEncoding grid tileExtent) spirv.
	buffers := names collect: [ :each |
		           VkBuffer
			           storageBuffer: (self wordCountOf: (bytes at: each))
			           on: context device ].
	[
	buffers do: [ :each | kernel bindBuffer: each ].
	kernel prepare.
	names withIndexDo: [ :each :index |
		self upload: (bytes at: each) into: (buffers at: index) ].
	kernel
		dispatch: anEncoding touchedTileCount
		y: self class rowsPerDispatch
		z: self class layersPerDispatch.
	self readback: (buffers at: (names indexOf: #target)) into: aByteArray ]
		ensure: [
			kernel destroy.
			buffers do: [ :each | each destroy ] ].
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

{ #category : 'printing' }
VGTiledFillDispatch >> printOn: aStream [
	aStream nextPutAll: self class name.
	bytes ifNil: [ ^ self ].
	aStream
		nextPutAll: ' of ';
		print: (bytes at: #target) size / VGTiledFillEncoding targetFormat bytesPerPixel;
		nextPutAll: ' pixels'
]

{ #category : 'copying' }
VGTiledFillDispatch >> readback: aBuffer into: aByteArray [
	"The device to host step, which section 2.2 of the plan makes the known risk of the whole
	 phase: the frame ends in host memory, so every frame pays this copy."

	| pointer |
	pointer := aBuffer map.
	[ LibC memCopy: pointer to: aByteArray size: aByteArray size ] ensure: [
		aBuffer unmap ]
]

{ #category : 'initialization' }
VGTiledFillDispatch >> setContext: aContext [
	context := aContext
]

{ #category : 'copying' }
VGTiledFillDispatch >> upload: aByteArray into: aBuffer [
	"The host to device step: one memcpy into the mapped block. The copyFromByteArray: of VkBuffer
	 writes the bytes one at a time from Smalltalk, which costs an interpreted send a byte, so
	 the copy is made through libc instead."

	| pointer |
	pointer := aBuffer map.
	[ LibC memCopy: aByteArray to: pointer size: aByteArray size ] ensure: [
		aBuffer unmap ]
]

{ #category : 'encoding' }
VGTiledFillDispatch >> wordCountOf: aByteArray [
	"The words a buffer holds, which is never none: an empty binding still owes the device a
	 buffer."

	^ aByteArray size / VGTiledFillKernel elementStride
		  max: self class emptyBufferWordCount
]
