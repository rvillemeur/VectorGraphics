"
I hold the lifetime facts of VGVulkanDeviceSession: one context and one prepared kernel a tile extent for the whole image session, buffers that grow and never shrink, and a release that destroys what it held and leaves the next ask to probe again. A machine with no device has no context to hold, so every test of mine that needs one answers early there rather than failing.
"
Class {
	#name : 'VGVulkanDeviceSessionTest',
	#superclass : 'VGTiledFrameTestCase',
	#category : 'VectorGraphics-Vulkan-Tests-Tests',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Tests'
}

{ #category : 'private' }
VGVulkanDeviceSessionTest >> drawFrameOfExtent: anExtent on: aDispatch [
	"One frame of that size drawn on that dispatch: a circle, which touches enough tiles to need
	 every binding, and the pixels it drew answered."

	| encoding target |
	encoding := self
		            encodingOfExtent: anExtent
		            drawnWith: [ :aContext |
			            aContext
				            sourceColorR: 0.9 g: 0.2 b: 0.1 a: 1.0;
				            circleCenterX: anExtent x / 2
				            y: anExtent y / 2
				            radius: anExtent x / 3;
				            fill ].
	target := ByteArray new:
		          anExtent x * anExtent y
		          * VGTiledFillEncoding targetFormat bytesPerPixel.
	^ aDispatch draw: encoding into: target
]

{ #category : 'tests' }
VGVulkanDeviceSessionTest >> testABlurOnTheDeviceRunsOnTheDeviceTheSessionHolds [
	"The blur of unit 2.8 opened a context of its own, which is why a small shadow was slower on
	 the device than on the host. It draws on the session's device now, and destroys nothing of it:
	 the same context is there after the blur as before it."

	| session before filter surface |
	session := VGVulkanDeviceSession default.
	before := session contextOrNil.
	before ifNil: [ ^ self ].
	surface := VGCairoImageSurface
		           newFormat: VGCairoSurfaceFormat a8
		           extent: 32 @ 32.
	filter := VGVulkanBlurFilter new.
	filter
		surface: surface;
		applySigma: 4.
	self assert: filter ranOnTheDevice.
	self assert: session contextOrNil identicalTo: before
]

{ #category : 'tests' }
VGVulkanDeviceSessionTest >> testABufferGrowsForALargerFrameAndIsKeptForASmallerOne [
	"A buffer is grown when a frame needs it larger and kept when a frame needs it smaller, so a
	 window being resized pays for the largest frame once and not for every frame after it."

	| session dispatch small large kept |
	session := VGVulkanDeviceSession default.
	session contextOrNil ifNil: [ ^ self ].
	dispatch := session dispatchForTileExtent: 16 @ 16.
	self drawFrameOfExtent: 64 @ 64 on: dispatch.
	small := dispatch deviceBuffers at: #target.
	self drawFrameOfExtent: 256 @ 256 on: dispatch.
	large := dispatch deviceBuffers at: #target.
	self deny: large identicalTo: small.
	self assert: large size > small size.
	self drawFrameOfExtent: 64 @ 64 on: dispatch.
	kept := dispatch deviceBuffers at: #target.
	self assert: kept identicalTo: large.
	self assert: kept size equals: large size
]

{ #category : 'tests' }
VGVulkanDeviceSessionTest >> testAReleasedSessionHoldsNoDispatchAndNoDeviceObjectOfOne [
	"Release destroys what the session held, children before the device, and a dispatch it handed
	 out holds nothing of the device afterwards. The next ask builds both again."

	| session dispatch |
	session := VGVulkanDeviceSession default.
	session contextOrNil ifNil: [ ^ self ].
	dispatch := session dispatchForTileExtent: 16 @ 16.
	self drawFrameOfExtent: 64 @ 64 on: dispatch.
	session releaseDevice.
	self assert: dispatch kernel isNil.
	self assert: dispatch deviceBuffers isEmpty.
	self deny: (session dispatchForTileExtent: 16 @ 16) identicalTo: dispatch
]

{ #category : 'tests' }
VGVulkanDeviceSessionTest >> testAResidentDispatchKeepsItsKernelAndItsBuffersBetweenFrames [
	"The whole of the unit measured as identity rather than as time: the second frame of a session
	 finds the module, the pipeline, the descriptor set and every buffer already there."

	| session dispatch kernel buffers |
	session := VGVulkanDeviceSession default.
	session contextOrNil ifNil: [ ^ self ].
	dispatch := session dispatchForTileExtent: 16 @ 16.
	self drawFrameOfExtent: 64 @ 64 on: dispatch.
	kernel := dispatch kernel.
	buffers := dispatch deviceBuffers copy.
	self assert: kernel isNotNil.
	self assert: buffers size equals: VGTiledFillKernel bindingNames size.
	self drawFrameOfExtent: 64 @ 64 on: dispatch.
	self assert: dispatch kernel identicalTo: kernel.
	VGTiledFillKernel bindingNames do: [ :each |
		self
			assert: (dispatch deviceBuffers at: each)
			identicalTo: (buffers at: each) ]
]

{ #category : 'tests' }
VGVulkanDeviceSessionTest >> testASessionOfAnotherImageRunOpensItsDeviceAgainAndDestroysNothing [
	"The startup hook forgets the session in Default, and reaches no further: a session held in
	 an instance variable of a benchmark, a renderer or an inspector survives a save and a
	 restart with Vulkan handles of the run that saved the image. So the ask for a context
	 checks the run it belongs to as well, and a session of another run opens a device again
	 rather than answering handles that would take the virtual machine down.
	 The stale context and the stale dispatch here are plain objects, so destroying or releasing
	 either of them instead of dropping it fails this test with a doesNotUnderstand — dropping
	 is the whole point, since vkDestroy on a dangling handle is the same dereference as drawing
	 on one. Faking the run is the only way to hold a stale session without saving the image."

	| session |
	session := VGVulkanDeviceSession new.
	session contextOrNil ifNil: [ ^ self ].
	self assert: session isOfThisImageRun.
	(session instVarNamed: 'dispatches') at: 16 @ 16 put: Object new.
	session
		instVarNamed: 'context' put: Object new;
		instVarNamed: 'imageRun' put: nil.
	self deny: session isOfThisImageRun.
	self assert: session contextOrNil isNotNil.
	self assert: session isOfThisImageRun.
	self assert: (session instVarNamed: 'dispatches') isEmpty.
	session releaseDevice
]

{ #category : 'tests' }
VGVulkanDeviceSessionTest >> testAnImageStartForgetsTheDefaultSessionAndDoesNotReleaseIt [
	"What an image start must do with the session it came back holding: forget it, and send it
	 nothing at all. Releasing it would send vkDestroy to the handles of the virtual machine run
	 that saved the image, which is the same dereference of a dangling handle that starting a
	 frame on it is. The stand-in is a plain object, so any message the hook sends to the
	 session it forgets fails this test with a doesNotUnderstand."

	| default standIn |
	default := VGVulkanDeviceSession classVariableNamed: #Default.
	standIn := default value.
	[
	default value: Object new.
	VGVulkanDeviceSession startUp: true.
	self assert: default value isNil ] ensure: [ default value: standIn ]
]

{ #category : 'tests' }
VGVulkanDeviceSessionTest >> testTheDispatchOfATileExtentIsTheOneDispatchOfThatExtent [
	"A dispatch is held per tile extent, because the kernel it prepares is compiled for that
	 extent and nothing else of it depends on the frame."

	| session first |
	session := VGVulkanDeviceSession default.
	session contextOrNil ifNil: [ ^ self ].
	first := session dispatchForTileExtent: 16 @ 16.
	self assert: (session dispatchForTileExtent: 16 @ 16) identicalTo: first.
	self deny: (session dispatchForTileExtent: 8 @ 8) identicalTo: first.
	self assert: first context identicalTo: session contextOrNil
]

{ #category : 'tests' }
VGVulkanDeviceSessionTest >> testTheLifetimeRowsAskTheSessionItselfWhatRunItsDeviceBelongsTo [
	"The rows behind the Lifetime tab state the two facts the crash of this defect turned on:
	 whether the device held was opened by the run of the virtual machine that is running now,
	 and whether the class is registered to be told when an image starts. Both are asked of the
	 session and of the session manager rather than restated, so neither row can drift from the
	 code it reports. A session that has opened nothing answers the first with false, which is
	 the degenerate state, and a machine with no device never leaves it."

	| session valueOf |
	session := VGVulkanDeviceSession new.
	valueOf := [ :label |
	           (session lifetimeRows detect: [ :each | each first = label ])
		           second ].
	self deny: (valueOf value: 'Device of this image run').
	self assert: (valueOf value: 'Registered for an image start').
	self assert: (valueOf value: 'Dispatches kept') equals: 0.
	session contextOrNil ifNil: [ ^ self ].
	self assert: (valueOf value: 'Device of this image run').
	session forgetDeviceOfAnotherImageRun.
	self deny: (valueOf value: 'Device of this image run')
]

{ #category : 'tests' }
VGVulkanDeviceSessionTest >> testTheResidencyRowsNameEveryBufferEveryDispatchOfTheSessionHolds [
	"What the Residency tab reads, which is the only place the holding of a session is visible:
	 one row a buffer of every dispatch, with the tile extent that keyed it, and no row at all
	 once the session is released. The rows are read without opening a device, so a session that
	 was never asked for one answers none rather than probing for one."
	| session encoding dispatch rows extent |
	session := VGVulkanDeviceSession new.
	self assert: session residencyRows isEmpty.
	self assert: session unavailableReason isNil.
	self hasDevice ifFalse: [ ^ self ].
	extent := 32 @ 32.
	encoding := self
		            encodingOfExtent: extent
		            drawnWith: [ :aContext | aContext fill ].
	dispatch := session dispatchForEncoding: encoding.
	self drawFrameOfExtent: extent on: dispatch.
	rows := session residencyRows.
	self
		assert: (rows collect: [ :each | each at: 2 ]) asArray
		equals: (VGTiledFillKernel bindingNames select: [ :name |
				 dispatch deviceBuffers includesKey: name ]).
	rows do: [
		:each |
		self assert: (each at: 1) equals: encoding grid tileExtent.
		self assert: (each at: 3) > 0 ].
	session releaseDevice.
	self assert: session residencyRows isEmpty
]

{ #category : 'tests' }
VGVulkanDeviceSessionTest >> testTheSessionClassIsRegisteredWithTheSessionManager [
	"The device of a session belongs to the run of the virtual machine that opened it, and an
	 image saved with a session in Default comes back holding Vulkan handles of a process that
	 no longer exists. Dereferencing one of them kills the virtual machine outright rather than
	 raising anything an image can handle, so the class has to be told when the image starts,
	 and being told means being registered here."

	self
		assert: (SessionManager default hasRegistered: #VGVulkanDeviceSession)
]

{ #category : 'tests' }
VGVulkanDeviceSessionTest >> testTheSessionHoldsOneBlurDispatchAndDropsItWhenReleased [
	"A blur of a small shadow is the second thing the session exists for. It holds one blur
	 dispatch, not one a blur, so the kernels and the buffers of a blur outlive the blur that
	 built them; releasing the session drops it with everything else, and the next ask builds a
	 new one on a context opened again."
	| session first second |
	session := VGVulkanDeviceSession new.
	self hasDevice ifFalse: [ ^ self assert: session blurDispatch isNil ].
	first := session blurDispatch.
	self assert: session blurDispatch == first.
	self assert: first context == session context.
	session releaseDevice.
	second := session blurDispatch.
	self deny: second == first.
	self assert: second context == session context.
	session releaseDevice
]

{ #category : 'tests' }
VGVulkanDeviceSessionTest >> testTheSessionHoldsOneContextForEveryAskUntilItIsReleased [
	"The point of the unit: a context is opened once and answered again, and the one released is
	 not the one the next ask answers. A machine with no device holds nothing, which is not a
	 failure."

	| session first second |
	session := VGVulkanDeviceSession default.
	session contextOrNil ifNil: [ ^ self ].
	first := session contextOrNil.
	self assert: session contextOrNil identicalTo: first.
	session releaseDevice.
	self assert: session isReleased.
	second := session contextOrNil.
	self deny: second identicalTo: first.
	self deny: session isReleased
]

{ #category : 'tests' }
VGVulkanDeviceSessionTest >> testTheSessionIsTheOnlyPlaceAFrameOrAFilterOpensADevice [
	"A context opened anywhere else is a context paid for again, which is the cost this unit takes
	 out. The session is the one sender of computeContext in the packages that draw, and a test or
	 a benchmark that wants its own device asks the session for it as well. This method sends it
	 too, as the literal it scans for, so it allows itself."
	| senders allowed |
	allowed := { VGVulkanDeviceSession >> #contextOrNil. thisContext method }.
	senders := (SystemNavigation default allSendersOf: #computeContext) select: [ :each |
		           (each package name beginsWith: 'VectorGraphics') and: [
			           (allowed includes: each) not ] ].
	self
		assert: (senders collect: [ :each |
				 each methodClass name , ' >> ' , each selector ]) asSortedCollection asArray
		equals: #( )
]
