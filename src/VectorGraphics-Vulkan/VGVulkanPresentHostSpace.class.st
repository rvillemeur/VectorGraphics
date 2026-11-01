"
I am the host space of a window that presents from the device. I own the window and, from unit 7.2 on, the VkSurface and VkSwapchain over it; my renderer owns the drawing, exactly as in Bloc's own pair.

Two inherited methods make the window a CPU window and I replace both. initializeWithAttributes: ends by sending newBlocRenderer, which builds an SDL accelerated renderer on the window handle; a window that presents a Vulkan swapchain cannot also own one, so I create the window without it. initializeRenderer builds an SDL_TEXTUREACCESS_STREAMING texture over that renderer, and lockSurfaceFor:scaleFactor:during: locks it, fills it through the renderer and presents it with sdlRenderer copy:. I own no texture, so the lock is shouldNotImplement: a frame that reached it would have taken the CPU route this unit exists to remove, and I would rather hear about it than draw it.

I cannot reach BlHostSpace >> initializeRenderer by sending super, since my superclass's own method stands between us, so my version repeats its one line and says here why.
"
Class {
	#name : 'VGVulkanPresentHostSpace',
	#superclass : 'BlOSWindowSDL2HostSpace',
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
