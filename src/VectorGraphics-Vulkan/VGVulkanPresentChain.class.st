"
I am the presentation half of a presenting window: the `VkSurface` over its handle, the `VkSwapchain` over that surface, the render pass and framebuffers over the swapchain's own image views, and the one command buffer, two semaphores and fence a frame loop needs. `VGVulkanPresentHostSpace` owns one of me and hands me the frames it is asked for.

I do not own the `VkContext`. A device lives longer than a window and a second window of the same image should not open a second one, so my host space creates the context and destroys it; I am handed it and I destroy nothing of it. Unit 7.3 decides whether that context becomes the one `VGVulkanDeviceSession` holds, which it has to be before a tiled fill can write into an image I acquired: a swapchain image belongs to the device its swapchain was created on, and the session's compute context is created from an instance that carries none of the window-system extensions a surface needs.

`presentFrameDuring:` is one frame: wait on the fence of the previous frame, acquire the next image, evaluate the block with it, clear it through a render pass, submit, present, and answer the image index so a caller can watch the cycle advance. Every wait of that frame is bounded by `frameTimeoutNanoseconds`, because a wait inside a plain uFFI call stops the whole virtual machine and no Pharo process can interrupt it; an unbounded one is `VkSwapchain >> acquireNextImage:fence:`, which no frame path of this project sends. The clear is what unit 7.4's drawing replaces; until then it is the whole of the frame, and it is a render pass rather than a `vkCmdClearColorImage` because the pass already leaves the image in `presentSrcKHR` and so needs no barrier written by hand.

My format is checked rather than adapted. `verifyFormat:` refuses any swapchain format but `VkRenderConfig formatRenderedIn`, because the kernel writes that format's words and a presented frame has to be the bytes an offscreen frame is. `verifySurface:presentsOnQueueFamily:` refuses a queue family the surface cannot present on, before a swapchain is created over it.

My parts are destroyed in the reverse of the order they were created, which `partsInCreationOrder` states once and `destroy` reads backwards. Renraku counts my variables as excessive and they are: one slot per Vulkan object I own is the point of me, and splitting them across helper objects would move the destruction order out of the one list that states it. The twelfth, `presentedIndexes`, is the only one that is not a Vulkan object — it outlives `destroy` so that my `Frames` tab still answers for a chain whose window is already closed.
"
Class {
	#name : 'VGVulkanPresentChain',
	#superclass : 'Object',
	#instVars : [
		'context',
		'backendWindow',
		'surface',
		'swapchain',
		'renderPass',
		'framebuffers',
		'commandPool',
		'commandBuffer',
		'imageAvailable',
		'renderFinished',
		'fence',
		'presentedIndexes'
	],
	#category : 'VectorGraphics-Vulkan-Present',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Present'
}

{ #category : 'constants' }
VGVulkanPresentChain class >> frameTimeoutNanoseconds [
	"One second: longer than any frame a presentation engine owes us, shorter than a user's
	 patience. Every wait of a frame is bounded by it, because a fence wait and an image
	 acquire are plain uFFI calls — the virtual machine sits inside the driver for as long as
	 they take, no Pharo process runs, and an unbounded one froze this image on 4 November.
	 Past the bound the driver raises, which is what a caller can see and a test can catch."

	^ 1000000000
]

{ #category : 'instance creation' }
VGVulkanPresentChain class >> onContext: aVkContext backendWindow: aVulkanBackendWindow [
	"Answer a built chain, or nothing at all. A raise part-way through building would
	 otherwise strand the Vulkan objects already created on an instance no caller receives,
	 and there would be no way left to destroy them. destroy tolerates nil slots, so it is
	 safe on a half-built chain — this is PVHelloTriangleScene class >> prepare:backendWindow:
	 and for the same reason."
	| chain |
	chain := self new.
	[
	chain initializeContext: aVkContext backendWindow: aVulkanBackendWindow ]
		ifCurtailed: [ chain destroy ].
	^ chain
]

{ #category : 'format' }
VGVulkanPresentChain class >> verifyFormat: aFormat [
	"The format a swapchain really came back with, against the one this project renders in.
	 A surface that offers no b8g8r8a8Unorm would present the kernel's words with their
	 channels swapped, so this refuses rather than adapts, and the message names both numbers
	 because the one the machine does offer is what a reader needs next."
	aFormat = VkRenderConfig formatRenderedIn ifTrue: [ ^ self ].
	self error: 'A presenting swapchain must render in format '
		, VkRenderConfig formatRenderedIn printString , ', and this surface offered '
		, aFormat printString
]

{ #category : 'verifying' }
VGVulkanPresentChain class >> verifySurface: aSurface presentsOnQueueFamily: aQueueFamilyIndex [
	"Refuse a queue family the surface does not accept. Presenting on such a queue is invalid
	 use that nothing reports when the validation layers are off: the frame goes nowhere and
	 the next acquire waits for an image the presentation engine never gives back."

	(aSurface supportsPresentation: aQueueFamilyIndex) ifTrue: [ ^ self ].
	self error: 'Queue family ' , aQueueFamilyIndex printString
		, ' cannot present on this surface'
]

{ #category : 'accessing' }
VGVulkanPresentChain >> backendWindow [
	^ backendWindow
]

{ #category : 'accessing' }
VGVulkanPresentChain >> context [
	^ context
]

{ #category : 'lifetime' }
VGVulkanPresentChain >> destroy [
	"Every object I own, in the reverse of the order I built it, after the device has finished
	 the frame that may still be in flight: destroying a resource the device is still reading
	 is undefined behaviour, and with the validation layers off it surfaces as a segfault
	 rather than an error. Safe to run twice, because a host space closing reaches this from
	 an ensure: block that may already have run."
	self waitForDevice.
	self partsInDestructionOrder do: [ :each | each destroy ].
	surface := nil.
	swapchain := nil.
	renderPass := nil.
	framebuffers := nil.
	commandBuffer := nil.
	commandPool := nil.
	imageAvailable := nil.
	renderFinished := nil.
	fence := nil
]

{ #category : 'accessing' }
VGVulkanPresentChain >> extent [
	"The swapchain's own extent, which is the drawable it was created with and not whatever the
	 window answers now: a resize is answered by building a new chain, so mine never changes."
	^ swapchain extent
]

{ #category : 'accessing' }
VGVulkanPresentChain >> fence [
	^ fence
]

{ #category : 'accessing' }
VGVulkanPresentChain >> format [
	^ swapchain format
]

{ #category : 'reporting' }
VGVulkanPresentChain >> frameReport [
	"What this chain is and what it did, each row asking the live object rather than restating
	 it, and every row answering after destroy as well: an example hands back a chain whose
	 window is already closed. The swapchain is gone then, so what it answered is read through
	 presentedIndexes, which the chain keeps."

	| imageCountOrNil gone |
	gone := 'gone with the swapchain'.
	imageCountOrNil := swapchain ifNotNil: [ :each | each imageCount ].
	^ {
		  ('destroyed' -> self isDestroyed printString).
		  ('parts alive' -> self partsInCreationOrder size printString).
		  ('format' -> (swapchain
			    ifNil: [ gone ]
			    ifNotNil: [ :each |
				    (VkFormat nameForValue: each format) ifNil: [
					    each format printString ] ])).
		  ('extent' -> (swapchain
			    ifNil: [ gone ]
			    ifNotNil: [ :each | each extent printString ])).
		  ('image count'
		   -> (imageCountOrNil ifNil: [ gone ] ifNotNil: [ :each | each printString ])).
		  ('frames presented' -> self presentedIndexes size printString).
		  ('indexes presented' -> self presentedIndexes asArray printString).
		  ('every image presented' -> (imageCountOrNil
			    ifNil: [ 'unknown without the swapchain' ]
			    ifNotNil: [ :count | (self presentedIndexes asSet size = count) printString ])).
		  ('frame wait bound'
		   -> (self class frameTimeoutNanoseconds printString , ' ns')).
		  ('matches the drawable' -> self matchesDrawable printString) }
]

{ #category : 'accessing' }
VGVulkanPresentChain >> framebuffers [
	^ framebuffers
]

{ #category : 'accessing' }
VGVulkanPresentChain >> imageCount [
	"What the driver really made, which may be more images than the request asked for."
	^ swapchain imageCount
]

{ #category : 'initialization' }
VGVulkanPresentChain >> initialize [
	super initialize.
	presentedIndexes := OrderedCollection new
]

{ #category : 'initialization' }
VGVulkanPresentChain >> initializeContext: aVkContext backendWindow: aVulkanBackendWindow [
	"In the order partsInCreationOrder states, which destruction reads backwards. The extent
	 is the drawable SDL answers for a Vulkan window and never the window's logical size: on a
	 scaled display the two differ, and the swapchain's images are the drawable's pixels. Both
	 refusals happen as soon as the driver has answered: a surface that offers another format
	 would present swapped channels, and a queue family that cannot present would swallow
	 every frame."

	context := aVkContext.
	backendWindow := aVulkanBackendWindow.
	surface := VkSurface
		           fromWindow: backendWindow
		           instance: context instance
		           physicalDevice: context physicalDevice.
	self class
		verifySurface: surface
		presentsOnQueueFamily: context computeQueueFamily.
	swapchain := VkSwapchain
		             on: context device
		             surface: surface
		             extent: backendWindow vulkanDrawableExtent.
	self class verifyFormat: swapchain format.
	renderPass := VkRenderPass
		              createColorPassDevice: context device
		              format: swapchain format.
	framebuffers := swapchain imageViews collect: [ :view |
		                VkFramebuffer
			                on: context device
			                renderPass: renderPass
			                imageView: view
			                extent: self extent ].
	commandPool := VkCommandPool
		               on: context device
		               queueFamilyIndex: context computeQueueFamily.
	commandBuffer := commandPool allocateBuffer.
	imageAvailable := VkSemaphoreWrapper createDevice: context device.
	renderFinished := VkSemaphoreWrapper createDevice: context device.
	fence := VkFenceWrapper createSignaledDevice: context device
]

{ #category : 'inspector' }
VGVulkanPresentChain >> inspectorFrames: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Frames'>
	"The unit's own gate, read live: the format and extent the driver gave, the indexes this
	 chain presented in order, and whether they covered every image of the swapchain. Reads
	 frameReport, so it cannot drift from what the chain answers, and writes nothing."

	^ aBuilder newTable
		  addColumn:
			  (SpStringTableColumn title: 'Property' evaluated: [ :each | each key ]);
		  addColumn:
			  (SpStringTableColumn title: 'Value' evaluated: [ :each | each value ]);
		  items: self frameReport;
		  yourself
]

{ #category : 'inspector' }
VGVulkanPresentChain >> inspectorFramesContext: aContext [
	"Always: the Frames tab answers for a live chain and for a destroyed one alike, and after
	 destroy it is the only tab that still says anything."

	aContext active: true
]

{ #category : 'inspector' }
VGVulkanPresentChain >> inspectorParts: aBuilder [
	<inspectorPresentationOrder: 20 title: 'Parts'>
	"The order this chain destroys in, which is partsInCreationOrder read backwards: one row
	 per part, numbered by when it is destroyed. The list is sampled from the chain rather
	 than written here, so a part added to the chain appears without this view being touched."

	| parts |
	parts := self partsInDestructionOrder.
	^ aBuilder newTable
		  addColumn: (SpStringTableColumn
				   title: 'Destroyed'
				   evaluated: [ :each | (parts indexOf: each) printString ]);
		  addColumn:
			  (SpStringTableColumn title: 'Part' evaluated: [ :each | each class name ]);
		  items: parts;
		  yourself
]

{ #category : 'inspector' }
VGVulkanPresentChain >> inspectorPartsContext: aContext [
	"Only while the chain holds parts. A destroyed chain holds none, and a tab that says so
	 with an empty table says less than no tab at all; the Frames tab names the destruction."

	aContext active: self isDestroyed not
]

{ #category : 'lifetime' }
VGVulkanPresentChain >> isDestroyed [
	"I hold no part of my own. The surface is the first thing built and the last destroyed, so
	 it is the one slot that answers for all of them, and the list says so rather than this
	 naming a slot twice."
	^ self partsInCreationOrder isEmpty
]

{ #category : 'testing' }
VGVulkanPresentChain >> matchesDrawable [
	"Whether my swapchain's images are still the size of my window's drawable. A resize is
	 answered by building a new chain and destroying this one, because a swapchain cannot be
	 resized: its images are allocated at the extent it was created with."
	^ self isDestroyed not and: [
		  self extent = backendWindow vulkanDrawableExtent ]
]

{ #category : 'lifetime' }
VGVulkanPresentChain >> partsInCreationOrder [
	"Every Vulkan object I own, in the order I built it, and nothing I was handed: the context
	 is not mine. A framebuffer references an image view of the swapchain and the swapchain
	 references the surface, so this order is also the order of dependency, which is why
	 destruction is this list backwards and not a second list that could drift from it.
	 The command buffer is absent on purpose: the pool frees its buffers and a buffer has no
	 destroy of its own."
	^ (Array streamContents: [ :out |
		   out nextPut: surface; nextPut: swapchain; nextPut: renderPass.
		   framebuffers ifNotNil: [ out nextPutAll: framebuffers ].
		   out
			   nextPut: commandPool;
			   nextPut: imageAvailable;
			   nextPut: renderFinished;
			   nextPut: fence ]) reject: #isNil
]

{ #category : 'lifetime' }
VGVulkanPresentChain >> partsInDestructionOrder [
	^ self partsInCreationOrder reversed
]

{ #category : 'presenting' }
VGVulkanPresentChain >> presentFrameDuring: aBlock [
	"One frame: wait for the previous one, acquire an image, hand that image to the block,
	 clear it, submit and present. Answers the index of the image presented, which is what
	 says the cycle is a cycle, and keeps it in presentedIndexes. Both waits are bounded by
	 frameTimeoutNanoseconds; neither may be unbounded, since both run inside a plain uFFI
	 call that stops the whole virtual machine while it waits. The clear is a render pass
	 because the pass this chain builds is the one that leaves the image in presentSrcKHR, and
	 the pass is closed here: a command buffer's end does not close it."

	| imageIndex |
	fence waitTimeout: self class frameTimeoutNanoseconds.
	fence reset.
	imageIndex := swapchain
		              acquireNextImage: imageAvailable handle
		              fence: ExternalAddress null
		              timeout: self class frameTimeoutNanoseconds.
	aBlock value: (swapchain images at: imageIndex + 1).
	commandPool reset.
	commandBuffer do: [ :recorder |
		recorder
			beginRenderPass: renderPass
			framebuffer: (framebuffers at: imageIndex + 1)
			extent: self extent
			clearColor: VkRenderConfig clearColorBlackOpaque.
		recorder endRenderPass ].
	context computeQueue
		submitGraphics: commandBuffer
		waitSemaphore: imageAvailable
		signalSemaphore: renderFinished
		fence: fence.
	swapchain
		present: imageIndex
		queue: context computeQueue
		waitSemaphore: renderFinished handle.
	presentedIndexes add: imageIndex.
	^ imageIndex
]

{ #category : 'accessing' }
VGVulkanPresentChain >> presentedIndexes [
	"Every swapchain index this chain has presented, in order. It is the one thing a presented
	 frame answers, so the chain keeps it: the inspector view reads it, and it outlives destroy
	 because an example closes its window before it hands the chain back."

	^ presentedIndexes
]

{ #category : 'accessing' }
VGVulkanPresentChain >> renderPass [
	^ renderPass
]

{ #category : 'accessing' }
VGVulkanPresentChain >> surface [
	^ surface
]

{ #category : 'accessing' }
VGVulkanPresentChain >> swapchain [
	^ swapchain
]

{ #category : 'lifetime' }
VGVulkanPresentChain >> waitForDevice [
	"Block until the device has finished every command submitted through my queue. The context
	 is not mine, so one already destroyed or never given is simply skipped — destroy is
	 reached from ensure: blocks, where a half-built chain is the normal case."
	context ifNil: [ ^ self ].
	(context device isNotNil and: [ context computeQueue isNotNil ]) ifFalse: [
		^ self ].
	context computeQueue waitIdle
]
