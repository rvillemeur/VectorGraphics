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
		'blur',
		'imageRun'
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

{ #category : 'class initialization' }
VGVulkanDeviceSession class >> initialize [
	"The hook Pharo sends when this class is installed, used for the one thing the session class
	 needs of the system: to be told when the image starts. A session is only valid inside the
	 run of the virtual machine that opened its device, and an image is routinely saved with one
	 in Default."

	SessionManager default registerUserClassNamed: self name asSymbol
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

{ #category : 'system startup' }
VGVulkanDeviceSession class >> startUp: isImageStarting [
	"Forget the session the image came back holding. Its context, its buffers and its command
	 pool are Vulkan handles of the virtual machine run that saved the image, and that process
	 is gone: reading one of them takes the virtual machine down without raising anything, which
	 is what a frame drawn on a restored session did before this hook existed.
	 The session is dropped and not released, because vkDestroy on a dangling handle is the same
	 dereference as drawing on it. Nothing of the device leaks: the device went with the process,
	 and what is let go of here is only the Pharo object that described it."

	isImageStarting ifTrue: [ Default := nil ]
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
	 path when there is none.
	 A session that was saved into the image and came back in it holds handles of the run that
	 saved it, and answering those would take the virtual machine down on the next frame, so the
	 run is checked before the context is answered and a device of another run is dropped here."

	context ifNotNil: [
		self isOfThisImageRun ifTrue: [ ^ context ].
		self forgetDeviceOfAnotherImageRun ].
	unavailableReason ifNotNil: [ ^ nil ].
	imageRun := Smalltalk session.
	^ context := [ VkContext computeContext ]
		  on: Error
		  do: [ :failure |
			  unavailableReason := failure description.
			  imageRun := nil.
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

{ #category : 'lifetime' }
VGVulkanDeviceSession >> forgetDeviceOfAnotherImageRun [
	"Let go of everything I hold without sending any of it a message. The context, the dispatches
	 and the blur are Vulkan handles of a virtual machine run that has ended, so vkDestroy on one
	 of them is the dereference of a dangling handle that kills the virtual machine — the very
	 crash releasing them looks like it would avoid. Nothing of the device leaks: the device went
	 with the process. The reason a machine had no device is forgotten too, so that the next ask
	 probes this run's driver rather than answering the last run's no."

	context := nil.
	blur := nil.
	dispatches removeAll.
	unavailableReason := nil.
	imageRun := nil
]

{ #category : 'initialization' }
VGVulkanDeviceSession >> initialize [
	super initialize.
	dispatches := Dictionary new
]

{ #category : 'inspector' }
VGVulkanDeviceSession >> inspectorLifetime: aBuilder [
	<inspectorPresentationOrder: 11 title: 'Lifetime'>
	"How long the device I hold is mine, which is what the stale session defect turned on: a
	 session saved into an image comes back holding handles of the run that saved it, and the
	 row naming the run says so before a frame finds out the hard way. The values come from
	 lifetimeRows, which asks the predicate, the dispatches and the session manager themselves,
	 so the tab reports the code rather than repeating it. Opening the tab opens no device and
	 releases none, so an inspection never changes what the next frame pays."

	^ aBuilder newTable
		  addColumn: (SpStringTableColumn
				   title: 'Fact'
				   evaluated: [ :each | each first ]);
		  addColumn: (SpStringTableColumn
				   title: 'Answer'
				   evaluated: [ :each | each second printString ]);
		  items: self lifetimeRows;
		  yourself
]

{ #category : 'inspector' }
VGVulkanDeviceSession >> inspectorLifetimeContext: aContext [
	"The tab states its facts for a session that holds nothing as well as for one that holds a
	 device — a released session and a machine with no driver are exactly the states the rows
	 were written for — so the only thing it needs is the dictionary the dispatch count is read
	 from."

	aContext active: dispatches notNil
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
VGVulkanDeviceSession >> isOfThisImageRun [
	"Whether the device I hold was opened by the run of the virtual machine that is running now.
	 A session that holds no device answers false, whether it has never opened one or has
	 released the one it opened: there is nothing of this run or of any other in it."

	^ context isNotNil and: [ imageRun == Smalltalk session ]
]

{ #category : 'testing' }
VGVulkanDeviceSession >> isReleased [
	"Whether I hold nothing at all. A session that has never been asked for a device is released
	 in exactly the same sense: there is nothing of a device to let go of."

	^ context isNil
]

{ #category : 'inspecting' }
VGVulkanDeviceSession >> lifetimeRows [
	"One row a fact about the device I hold and how long it is mine: whether I hold one at all,
	 whether the run that opened it is the run that is going now, how many dispatches hang off
	 it, whether my class will be told when an image starts, and the reason a machine without a
	 driver gave. Every value is asked of the object that owns it — the predicate, the dictionary
	 and the session manager — so that a row cannot say one thing while the code does another.
	 Reading them opens no device, which is what lets an inspector show them."

	^ {
		  { 'Holds a device'. context isNotNil }.
		  { 'Device of this image run'. self isOfThisImageRun }.
		  { 'Dispatches kept'. dispatches size }.
		  { 'Registered for an image start'.
		  SessionManager default hasRegistered: self class name asSymbol }.
		  { 'Reason there is no device'. unavailableReason ifNil: [ 'none given' ] } }
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
