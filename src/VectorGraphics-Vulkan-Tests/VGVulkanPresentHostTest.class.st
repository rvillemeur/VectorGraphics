"
I hold unit 7.1 of the present plan: a Bloc window opened on PharoVulkan's driver that owns no SDL accelerated renderer and no streaming texture, so that nothing in a frame drawn on it can take the CPU route.

My first two tests are about which host a space is given, because three SDL2 hosts now answer isSupported and BlHostRegistry sorts hosts by order alone, where all three answer 10: the partition between them has to be exact in every combination of driver and opt-in, not merely under the driver. The rest build a real window, which is what PVGraphicsTest does for the scenes, and close it in the test itself rather than in tearDown, so that one failing assertion cannot leave a window behind.
"
Class {
	#name : 'VGVulkanPresentHostTest',
	#superclass : 'TestCase',
	#instVars : [
		'previousRendererClass'
	],
	#category : 'VectorGraphics-Vulkan-Tests-Tests',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Tests'
}

{ #category : 'accessing' }
VGVulkanPresentHostTest class >> resizeTimeout [
	"How long a test waits for the window system to answer a resize before it fails. Generous,
	 because a compositor is free to take its time, and bounded, because a suite that hangs
	 tells nobody anything."

	^ 5 seconds
]

{ #category : 'running' }
VGVulkanPresentHostTest >> setUp [
	"BlHostRenderer class >> preferableClass caches the renderer the whole image draws through,
	 and one of my tests sets it to prove that picking mine for an ordinary window still draws, so
	 the previous choice is put back afterwards."

	super setUp.
	previousRendererClass := BlHostRenderer preferableClass
]

{ #category : 'running' }
VGVulkanPresentHostTest >> tearDown [
	"Asking a registry which hosts are available builds the singleton of every supported host, and
	 BlOSWindowSDL2Host class >> default registers that singleton in the image's own registry too.
	 Neither host of this project may stay there once the driver and the opt-in they answer to are
	 gone, and the renderer the image draws through is put back as it was."

	BlHostRenderer preferableClass: previousRendererClass.
	VGPixelBufferHost cleanUp.
	VGVulkanPresentHost cleanUp.
	VGVulkanDriverSdl2Host cleanUp.
	super tearDown
]

{ #category : 'tests' }
VGVulkanPresentHostTest >> testAFrameOfMySpaceReachesMyRendererAndNotTheSurfaceLock [
	"The route a frame takes, which is the whole of this unit: the space asks its host space, the
	 host space asks its renderer, and the renderer counts the frame where BARenderer would have
	 locked a surface. The space is invalidated first because both methods answer early for a
	 space with no dirty elements, and the frame is counted once per render, not once per pulse."

	self withHostSpaceDo: [ :hostSpace |
		self assert: hostSpace renderer class equals: VGVulkanPresentRenderer.
		self assert: hostSpace renderer frameCount equals: 0.
		hostSpace space invalidateAll.
		hostSpace render: hostSpace space.
		self assert: hostSpace renderer frameCount equals: 1 ]
]

{ #category : 'tests - presenting' }
VGVulkanPresentHostTest >> testClosingMyHostSpaceDestroysItsChainAndItsContext [
	"The window, the chain over it and the Vulkan context the chain was built on all end when
	 the space does, in that reverse order, and nothing is left on the device. The context is
	 the host space's own for now: the session's context is built for compute and carries none
	 of the instance extensions a surface needs, and unit 7.3 is where the two become one."

	self withPresentingHostSpaceDo: [ :hostSpace |
		| chain context |
		chain := hostSpace presentChain.
		context := hostSpace presentContext.
		self deny: chain isDestroyed.
		hostSpace close.
		self assert: chain isDestroyed.
		self assert: hostSpace presentContextOrNil isNil.
		self assert: context device isNil ]
]

{ #category : 'tests' }
VGVulkanPresentHostTest >> testExactlyOneSdl2HostIsSupportedInEveryCombination [
	"Which SDL2 host the registry picks must never be a coin toss. There are three of us now and
	 BlHostRegistry >> registerHost: sorts by order alone, where all three answer 10, so the
	 three cases have to partition in every combination of driver and opt-in — four of them, not
	 the two §6b had to answer for."

	| sdl2Hosts supported |
	sdl2Hosts := BlOSWindowSDL2Host withAllSubclasses.
	supported := [ (sdl2Hosts select: [ :each | each isSupported ]) asArray ].
	VGVulkanDriverSdl2HostTest withDriverClass: OSSDL2Driver during: [
		self assert: supported value equals: { BlOSWindowSDL2Host }.
		VGVulkanPresentHost enableDuring: [
			self assert: supported value equals: { BlOSWindowSDL2Host } ] ].
	PVVulkanDriver installDuring: [
		self assert: supported value equals: { VGVulkanDriverSdl2Host }.
		VGVulkanPresentHost enableDuring: [
			self assert: supported value equals: { VGVulkanPresentHost } ] ]
]

{ #category : 'tests - presenting' }
VGVulkanPresentHostTest >> testMyHostSpacePresentsFramesThatCycleThroughItsSwapchainImages [
	"Unit 7.2 through the host space rather than through the chain directly: the method Bloc's
	 renderer will send in 7.4 is presentFrameFor:scaleFactor:during:, and it has to acquire an
	 image, hand that image to the block and present it. More frames than the swapchain holds,
	 so an index that never comes round shows up here."

	self withPresentingHostSpaceDo: [ :hostSpace |
		| indexes imagesSeen chain |
		indexes := OrderedCollection new.
		imagesSeen := OrderedCollection new.
		chain := hostSpace presentChain.
		chain imageCount * 2 + 1 timesRepeat: [
			indexes add: (hostSpace
					 presentFrameFor: (0 @ 0 extent: chain extent)
					 scaleFactor: 1
					 during: [ :image | imagesSeen add: image ]) ].
		self assert: imagesSeen size equals: indexes size.
		self
			assert: indexes asSet asSortedCollection asArray
			equals: (0 to: chain imageCount - 1) asArray ]
]

{ #category : 'tests' }
VGVulkanPresentHostTest >> testMyRendererDrawsTheCpuFrameForAHostSpaceThatDoesNotPresent [
	"BlHostRenderer class >> availableClasses is self allSubclasses, so my renderer appears in
	 Bloc's renderer setting and preferableClass can pick it for an ordinary window. Such a window
	 has to be drawn, not refused: the inherited CPU frame answers for it, and the pixel buffer
	 host space lends a byte array the way a window lends its texture. The frame count stays at
	 zero, because nothing was presented."

	| space element |
	BlHostRenderer preferableClass: VGVulkanPresentRenderer.
	element := BlElement new
		           extent: 40 @ 30;
		           background: Color red;
		           yourself.
	space := BlSpace new
		         host: VGPixelBufferHost default;
		         yourself.
	space extent: 100 @ 100.
	space root addChild: element.
	[
	space show.
	space settleForDuration: 5 seconds.
	self assert: space hostSpace renderer class equals: VGVulkanPresentRenderer.
	self deny: (space hostSpace pixels allSatisfy: [ :each | each = 0 ]).
	self assert: space hostSpace renderer frameCount equals: 0 ] ensure: [
		space close ]
]

{ #category : 'tests' }
VGVulkanPresentHostTest >> testMyWindowOwnsNoSdlAcceleratedRenderer [
	"The condition §6a found at the host-space level, and the reason this unit is three subclasses
	 rather than a renderer: BlOSWindowSDL2HostSpace >> initializeWithAttributes: ends by sending
	 newBlocRenderer, which creates an SDL accelerated renderer on the window handle, and a window
	 that presents a Vulkan swapchain cannot also own one. Mine is never built, so there is
	 nothing on the handle that could present CPU pixels."

	self withHostSpaceDo: [ :hostSpace |
		self assert: hostSpace backendWindow renderer isNil ]
]

{ #category : 'tests - presenting' }
VGVulkanPresentHostTest >> testTheChainOfMyHostSpaceIsKeptUntilTheDrawableChangesAndIsThenRebuilt [
	"A swapchain is created for one drawable extent and is not valid for another, so a resized
	 window needs a new one — and an unchanged window must not get one every frame, which is
	 what the first two assertions hold. The resize is a real one: SDL answers the new drawable
	 through SDL_Vulkan_GetDrawableSize, and the chain is rebuilt because it no longer matches
	 it."

	self withPresentingHostSpaceDo: [ :hostSpace |
		| first resized |
		first := hostSpace presentChain.
		self assert: hostSpace presentChain identicalTo: first.
		self assert: first matchesDrawable.
		hostSpace windowExtent: hostSpace backendWindow vulkanDrawableExtent * 2.
		self
			waitUntil: [ first matchesDrawable not ]
			description: 'the window system has to answer the new drawable extent'.
		resized := hostSpace presentChain.
		self deny: resized identicalTo: first.
		self assert: first isDestroyed.
		self
			assert: resized extent
			equals: hostSpace backendWindow vulkanDrawableExtent ]
]

{ #category : 'tests' }
VGVulkanPresentHostTest >> testTheCpuSurfaceLockIsRefusedByMyHostSpace [
	"A frame that reached the lock would have taken the CPU route this phase exists to remove,
	 and there is no texture behind it to lock either. Hearing about it is better than drawing it,
	 so the inherited method is refused rather than left to fail on a nil texture."

	self withHostSpaceDo: [ :hostSpace |
		self
			should: [
				hostSpace
					lockSurfaceFor: (0 @ 0 extent: 10 @ 10)
					scaleFactor: 1
					during: [ :aCanvas | aCanvas ] ]
			raise: ShouldNotImplement ]
]

{ #category : 'tests' }
VGVulkanPresentHostTest >> testThePhysicalSizeOfMyHostSpaceComesFromTheVulkanDrawable [
	"The one inherited answer that an absent SDL renderer breaks rather than merely changes:
	 BlOSWindowSDL2HostSpace >> physicalSize is `window canvasExtent asPhysicalSize`, and
	 OSBackendWindow >> canvasExtent is `renderer canvasExtent`, so without a renderer the
	 inherited method sends canvasExtent to nil. SDL answers the same question for a Vulkan
	 window, and the answer has to match the drawable the swapchain will be created with."

	self withHostSpaceDo: [ :hostSpace |
		self
			assert: hostSpace physicalSize
			equals: hostSpace backendWindow vulkanDrawableExtent asPhysicalSize.
		self deny: hostSpace physicalSize isZero ]
]

{ #category : 'tests' }
VGVulkanPresentHostTest >> testThePresentHostIsSupportedOnlyWhileEnabledUnderTheVulkanDriver [
	"Four states, because two things have to be true at once. The driver is the half §6b already
	 holds. The opt-in is the half §8 of the present plan asks for: Bloc's default stays Cairo,
	 so presenting is something a caller asks for, never something an image starts doing by
	 itself, and a host that answered on the driver alone would present every window opened
	 inside any PVVulkanDriver installDuring:."

	VGVulkanDriverSdl2HostTest withDriverClass: OSSDL2Driver during: [
		self deny: VGVulkanPresentHost isSupported.
		VGVulkanPresentHost enableDuring: [
			self deny: VGVulkanPresentHost isSupported ] ].
	PVVulkanDriver installDuring: [
		self deny: VGVulkanPresentHost isSupported.
		VGVulkanPresentHost enableDuring: [
			self assert: VGVulkanPresentHost isSupported ] ]
]

{ #category : 'tests' }
VGVulkanPresentHostTest >> testTheWindowOfMyHostSpaceIsAVulkanWindow [
	"PVVulkanDriver answers an OSSDL2VulkanBackendWindow only for attributes that carry
	 vulkanAttributes and falls through to super for every other window, so the class of the
	 backend window is the one place that says whether my host really asked for a Vulkan window."

	self withHostSpaceDo: [ :hostSpace |
		self
			assert: hostSpace backendWindow class
			equals: OSSDL2VulkanBackendWindow ]
]

{ #category : 'running' }
VGVulkanPresentHostTest >> waitUntil: aBlock description: aString [
	"A window system answers a resize when it chooses to, not when the test asks, so a test
	 that reads the drawable extent straight after the request reads the old one. The wait is
	 bounded and fails with the reason rather than hanging the suite."

	| deadline |
	deadline := DateAndTime now + self class resizeTimeout.
	[ aBlock value ] whileFalse: [
		DateAndTime now > deadline ifTrue: [ ^ self fail: aString ].
		(Delay forMilliseconds: 20) wait ]
]

{ #category : 'running' }
VGVulkanPresentHostTest >> withHostSpaceDo: aBlock [
	"A host space of mine over a real window, closed whatever the block does with it. The window
	 is hidden, because the attributes a Bloc host builds start invisible. The space is never
	 opened: the host builds the window, which is what these tests read, and opening the space
	 would hand it to the universe as well. The renderer is initialised here because a window
	 host space has it done when its window is created, and BlSpace >> validateHostSpaceDrawing
	 only does it again once the window has resized."

	^ self withPresentHostDuring: [
		  | hostSpace |
		  hostSpace := VGVulkanPresentHost default newHostSpaceFor: BlSpace new.
		  hostSpace initializeRenderer.
		  [ aBlock value: hostSpace ] ensure: [ hostSpace close ] ]
]

{ #category : 'running' }
VGVulkanPresentHostTest >> withPresentHostDuring: aBlock [
	"The two states my subject needs at once: PharoVulkan's driver installed, so that a window is
	 created with SDL_WINDOW_VULKAN in its flags, and presenting opted into, so that my host
	 answers supported. Both are put back when the block ends, whatever the block does."

	^ PVVulkanDriver installDuring: [ VGVulkanPresentHost enableDuring: aBlock ]
]

{ #category : 'running' }
VGVulkanPresentHostTest >> withPresentingHostSpaceDo: aBlock [
	"A host space of mine whose window is shown, because a presentation engine owes a hidden
	 window nothing and an acquire against one can wait until its bound runs out. Answers
	 without evaluating the block when this machine has no Vulkan device, which is how every
	 device test of this project answers. The host space is closed whatever the block does,
	 and closing it is what destroys the chain and the context it built."

	VGVulkanDeviceSession default contextOrNil ifNil: [ ^ self ].
	^ self withPresentHostDuring: [
		  | hostSpace |
		  hostSpace := VGVulkanPresentHost default newHostSpaceFor: BlSpace new.
		  hostSpace initializeRenderer.
		  [
		  hostSpace show.
		  aBlock value: hostSpace ] ensure: [ hostSpace close ] ]
]
