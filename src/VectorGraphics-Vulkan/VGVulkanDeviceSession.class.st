"
The device this image draws on, held for as long as the image runs. A Vulkan compute context costs 37 to 52 ms to open, a prepared kernel another 1.8 ms and the frame buffers half a millisecond more, and none of that depends on the frame: `default` answers the one session, `contextOrNil` the one context it opened (nil, with `unavailableReason` set, where no device computes), and `dispatchForTileExtent:` a VGTiledFillDispatch that keeps its kernel, its pipeline and its buffers between frames. `release` destroys all of it in the order Vulkan asks for and leaves the next ask to probe again, which is what a test of the lifetime and a machine whose driver has gone need. I hold a device and never a backend: unit 2.0's rule is that selection decides a backend class and hands out no instance, so `VGVulkanBackend` asks me for the device of each frame and is still built one a surface.
"
Class {
	#name : 'VGVulkanDeviceSession',
	#superclass : 'Object',
	#instVars : [
		'context',
		'dispatches',
		'unavailableReason',
		'blur'
	],
	#classVars : [
		'Default'
	],
	#category : 'VectorGraphics-Vulkan-Backend',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Backend'
}

{ #category : 'constants' }
VGVulkanDeviceSession class >> blurRowLabel [
	"What a row of my residency names the blur dispatch by, where a fill dispatch is named by the
	 tile extent that keyed it. The blur is one for the session and has no extent of its own."
	^ #blur
]

{ #category : 'accessing' }
VGVulkanDeviceSession class >> default [
	"The session of this image. One object, because the device it holds is one device and the
	 saving of the unit is that a second frame finds it already open."

	^ Default ifNil: [ Default := self new ]
]

{ #category : 'constants' }
VGVulkanDeviceSession class >> noDeviceErrorMessage [
	"What a caller that insists on a device is told where none computes, with the reason the
	 driver gave appended."

	^ 'no device on this machine computes: '
]

{ #category : 'accessing' }
VGVulkanDeviceSession class >> releaseDefault [
	"The session of this image released, if one was ever asked for. A test of the lifetime and a
	 driver that has gone both need the device let go of without the next ask being told no."

	Default ifNil: [ ^ self ].
	Default releaseDevice
]

{ #category : 'accessing' }
VGVulkanDeviceSession >> blurDispatch [
	"The one blur dispatch of this session, built on the first blur and kept for every blur after
	 it, or nil where no device computes. One for the session and not one a blur, because the two
	 kernels of a blur are prepared for the module and for nothing of the field, and the field
	 buffers are grown to the largest blur the session has seen rather than created and destroyed
	 around each one."
	self contextOrNil ifNil: [ ^ nil ].
	^ blur ifNil: [ blur := VGBlurDispatch on: context ]
]

{ #category : 'accessing' }
VGVulkanDeviceSession >> context [
	"The context of this session, raising where no device on this machine computes. A caller that
	 draws under a handler asks for it this way; one that has a host path of its own asks
	 contextOrNil."

	^ self contextOrNil ifNil: [
		  VkError signal: self class noDeviceErrorMessage , unavailableReason ]
]

{ #category : 'accessing' }
VGVulkanDeviceSession >> contextOrNil [
	"The context of this session, opened on the first ask and answered unopened afterwards, or
	 nil where no device on this machine computes. Every fault of a driver is caught here,
	 whatever class it arrives as, because a frame asks me for a device and takes the software
	 path when there is none."

	context ifNotNil: [ ^ context ].
	unavailableReason ifNotNil: [ ^ nil ].
	^ context := [ VkContext computeContext ]
		  on: Error
		  do: [ :failure |
			  unavailableReason := failure description.
			  nil ]
]

{ #category : 'accessing' }
VGVulkanDeviceSession >> dispatchForEncoding: anEncoding [
	"The dispatch that draws that frame, which is the one of its tile extent."

	^ self dispatchForTileExtent: anEncoding grid tileExtent
]

{ #category : 'accessing' }
VGVulkanDeviceSession >> dispatchForTileExtent: aPoint [
	"The dispatch of that tile extent, prepared on its first frame and kept for every frame after
	 it, or nil where no device computes. One a tile extent, because the module and the pipeline
	 of a dispatch are compiled for the extent and nothing else of either depends on the frame."

	self contextOrNil ifNil: [ ^ nil ].
	^ dispatches
		  at: aPoint
		  ifAbsentPut: [ VGTiledFillDispatch on: context ]
]

{ #category : 'initialization' }
VGVulkanDeviceSession >> initialize [
	super initialize.
	dispatches := Dictionary new
]

{ #category : 'inspector' }
VGVulkanDeviceSession >> inspectorResidency: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Residency'>
	"What I hold between frames, which is the whole of unit 3.1: one row a buffer of every
	 dispatch I keep, with the tile extent that keyed it and the bytes it has been grown to. A
	 released session holds nothing and the table is empty, which is the fact the tab is for.
	 The rows are read off the dispatches I already hold, so opening the tab never opens a
	 device and never changes what a frame would pay next."
	^ aBuilder newTable
		  addColumn: (SpStringTableColumn
				   title: 'Tile extent'
				   evaluated: [ :each | (each at: 1) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Binding'
				   evaluated: [ :each | (each at: 2) asString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Bytes'
				   evaluated: [ :each | (each at: 3) printString ]);
		  items: self residencyRows;
		  yourself
]

{ #category : 'inspector' }
VGVulkanDeviceSession >> inspectorResidencyContext: aContext [

	"An empty table is the fact the tab states for a released session, so the gate asks only that
	 the dispatches I read the rows from exist at all."

	aContext active: dispatches notNil
]

{ #category : 'testing' }
VGVulkanDeviceSession >> isReleased [
	"Whether I hold nothing at all. A session that has never been asked for a device is released
	 in exactly the same sense: there is nothing of a device to let go of."

	^ context isNil
]

{ #category : 'printing' }
VGVulkanDeviceSession >> printOn: aStream [
	"The state a reader of a stack or an inspector title needs first: whether I hold a device,
	 how many tile extents I keep for it, and the reason where I could not open one."
	super printOn: aStream.
	context ifNotNil: [
		aStream
			nextPutAll: ' (';
			print: dispatches size;
			nextPutAll: (dispatches size = 1
					 ifTrue: [ ' tile extent resident)' ]
					 ifFalse: [ ' tile extents resident)' ]).
		^ self ].
	unavailableReason
		ifNil: [ aStream nextPutAll: ' (no device asked for yet)' ]
		ifNotNil: [ aStream nextPutAll: ' (no device: ' , unavailableReason , ')' ]
]

{ #category : 'lifetime' }
VGVulkanDeviceSession >> releaseDevice [
	"Everything I hold destroyed, children before the device, and the reason for a machine with no
	 device forgotten so that the next ask probes again rather than answering a stale no."
	dispatches valuesDo: [ :each | each releaseDevice ].
	dispatches removeAll.
	blur ifNotNil: [ blur releaseDevice ].
	blur := nil.
	context ifNotNil: [ context destroy ].
	context := nil.
	unavailableReason := nil
]

{ #category : 'inspecting' }
VGVulkanDeviceSession >> residencyRows [
	"One row a buffer of everything I hold: the dispatch the buffer belongs to, which is the tile
	 extent that keyed a fill dispatch or the symbol the blur is named by, the binding the buffer
	 is bound at and the bytes it has been grown to. The names are read off each dispatch's own
	 contract, and only the dispatches I already hold are read: an inspection may not open a
	 device."
	| rows |
	rows := OrderedCollection new.
	(dispatches keys asSortedCollection: [ :a :b | a x * a y <= (b x * b y) ]) do: [
		:extent |
		| held |
		held := (dispatches at: extent) deviceBuffers.
		VGTiledFillKernel bindingNames do: [ :name |
			(held at: name ifAbsent: [ nil ]) ifNotNil: [ :buffer |
				rows add: {
						extent.
						name.
						buffer size } ] ] ].
	blur ifNotNil: [
		blur bufferNamesHeld do: [ :name |
			rows add: {
					self class blurRowLabel.
					name.
					(blur deviceBuffers at: name) size } ] ].
	^ rows asArray
]

{ #category : 'accessing' }
VGVulkanDeviceSession >> unavailableReason [
	"Why this machine has no device, as the driver put it, or nil where one computes or none has
	 been asked for yet."

	^ unavailableReason
]
