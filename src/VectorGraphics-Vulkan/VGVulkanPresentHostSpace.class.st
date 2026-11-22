"
I am the host space of a window that presents from the device. I own the window and, from unit 7.2 on, the VkSurface and VkSwapchain over it; my renderer owns the drawing, exactly as in Bloc's own pair.

Two inherited methods make the window a CPU window and I replace both. initializeWithAttributes: ends by sending newBlocRenderer, which builds an SDL accelerated renderer on the window handle; a window that presents a Vulkan swapchain cannot also own one, so I create the window without it. initializeRenderer builds an SDL_TEXTUREACCESS_STREAMING texture over that renderer, and lockSurfaceFor:scaleFactor:during: locks it, fills it through the renderer and presents it with sdlRenderer copy:. I own no texture, so the lock is shouldNotImplement: a frame that reached it would have taken the CPU route this unit exists to remove, and I would rather hear about it than draw it.

I cannot reach BlHostSpace >> initializeRenderer by sending super, since my superclass's own method stands between us, so my version repeats its one line and says here why.
"
Class {
	#name : 'VGVulkanPresentHostSpace',
	#superclass : 'BlOSWindowSDL2HostSpace',
	#instVars : [
		'presentChain'
	],
	#category : 'VectorGraphics-Vulkan-Present',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Present'
}

{ #category : 'accessing' }
VGVulkanPresentHostSpace >> backendWindow [
	"The window the driver really built. Unit 7.2 creates the VkSurface from it, and unit 7.1
	 reads its class to see that it carries SDL_WINDOW_VULKAN."

	^ window backendWindow
]

{ #category : 'host space - displaying' }
VGVulkanPresentHostSpace >> close [
	"The chain, then the window my superclass closes. The context is not destroyed here since
	 unit 7.3: it is the session's one device, which outlives this window and which the next
	 frame of any kind still draws on. The surface inside the chain belongs to the instance that
	 context holds, so the chain goes first. Tolerates a second close, as my superclass's does,
	 since a test may close a space its fixture closes again."

	presentChain ifNotNil: [
		presentChain destroy.
		presentChain := nil ].
	super close
]

{ #category : 'initialization' }
VGVulkanPresentHostSpace >> initializeRenderer [
	"BlHostSpace's own line and nothing else. My superclass's version builds the streaming
	 texture, the SDL renderer handle and the two addresses a CPU frame locks, none of which
	 exists here, and super reaches that version rather than the one above it."

	renderer initializeForHostSpace: self
]

{ #category : 'initialization' }
VGVulkanPresentHostSpace >> initializeWithAttributes: initialAttributes [
	"The inherited method without its last statement, which is `window newBlocRenderer`: that
	 creates an SDL accelerated renderer on the window handle, and a window presenting a Vulkan
	 swapchain cannot also own one. The rest is repeated because a method cannot run all of an
	 inherited method but its last line."

	OSWindowDriver current ensureEventLoop.
	window := OSWindow createWithAttributes: initialAttributes.
	window eventHandler: (BlOSWindowEventHandler
			 window: self
			 time: space time
			 keyboardKeyTable: keyboardKeyTable).
	window startTextInput
]

{ #category : 'rendering' }
VGVulkanPresentHostSpace >> lockSurfaceFor: logicalDamagedRectangle scaleFactor: aNumber during: aBlock [
	"Refused: I own no streaming texture to lock, and a frame that arrived here would have taken
	 the CPU route this phase exists to remove. Failing loudly is the point — the alternative is
	 a frame that quietly costs what §7b measures."

	^ self shouldNotImplement
]

{ #category : 'host space - geometry' }
VGVulkanPresentHostSpace >> physicalSize [
	"The framebuffer size, which my superclass asks the window for as its canvas extent. That
	 answer comes from the SDL accelerated renderer — OSBackendWindow >> canvasExtent is
	 `renderer canvasExtent` — and I own none, so the inherited method would send canvasExtent to
	 nil. SDL answers the same question for a Vulkan window through SDL_Vulkan_GetDrawableSize,
	 which is what vulkanDrawableExtent asks, and it is the extent the swapchain of unit 7.2 is
	 created with as well."

	^ self backendWindow vulkanDrawableExtent asPhysicalSize
]

{ #category : 'presenting' }
VGVulkanPresentHostSpace >> presentChain [
	"The chain over this window: surface, swapchain, render pass, one framebuffer per image,
	 and the frame synchronisation. One chain per drawable extent, kept for as long as it
	 matches — a swapchain is created for one extent and is not valid for another, so a resized
	 window is answered by destroying the chain and building the next one, and an unresized
	 window keeps the one it has instead of paying for a swapchain every frame."

	presentChain ifNotNil: [
		presentChain matchesDrawable ifTrue: [ ^ presentChain ].
		presentChain destroy.
		presentChain := nil ].
	^ presentChain := VGVulkanPresentChain
		                  onContext: self presentContext
		                  backendWindow: self backendWindow
]

{ #category : 'accessing' }
VGVulkanPresentHostSpace >> presentContext [
	"The Vulkan context this host space presents through: the session's one device, which does
	 compute and presentation both since unit 7.3. Asking for it is what rebuilds a compute-only
	 context into a presenting one, so a frame that opened a device before this window existed
	 leaves no second device behind.
	 Nothing is cached here. The session holds the context and may release and rebuild it, and a
	 copy kept here would outlive the handles it names. A machine that cannot present never
	 reaches this method: VGVulkanPresentHost class >> isSupported asks the session first, and
	 the host is not offered at all."

	^ VGVulkanDeviceSession default presentableContextOrNil
]

{ #category : 'accessing' }
VGVulkanPresentHostSpace >> presentContextOrNil [
	"The context this host space would present through if the session holds a presenting one
	 now, and nil otherwise. Tests read this rather than presentContext, which would open a
	 device to answer the question."

	| session |
	session := VGVulkanDeviceSession default.
	^ session isPresenting ifTrue: [ session context ]
]

{ #category : 'rendering' }
VGVulkanPresentHostSpace >> presentFrameFor: logicalDamagedRectangle scaleFactor: aNumber during: aBlock [
	"The frame of a presenting window, where BARenderer sends lockSurfaceFor:scaleFactor:during:
	 on the CPU path: acquire an image of the swapchain, evaluate the block with it, present it,
	 and answer the index presented. The damaged rectangle and the scale factor are the
	 arguments the method this replaces is given, and they are the ones unit 7.4 draws from;
	 this unit clears the image and presents it whatever they say, because a swapchain image is
	 not the previous frame and a partial frame would leave the rest of it undefined."

	^ self presentChain presentFrameDuring: aBlock
]

{ #category : 'frames' }
VGVulkanPresentHostSpace >> presentsFramesOnDevice [
	"True: my frames are computed on the device and copied into an image of my swapchain, and
	 lockSurfaceFor:scaleFactor:during: refuses, so nothing of mine is drawn on the processor."

	^ true
]
