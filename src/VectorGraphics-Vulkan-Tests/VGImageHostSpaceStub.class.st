"
A host space of the presenting kind with no window and no swapchain: it hands the frame
block one plain image of its own and then does with the answer what VGVulkanPresentChain
does with it, which is to record the copy into that image and submit it. The renderer under
test cannot tell the difference, and the pixels stay readable afterwards because the image
is created as both ends of a copy. The drawn frame is tested offscreen this way: a real
swapchain image cannot be read back and a real window cannot be compared to a reference.

Build with onExtent:, send space: the space to draw and render: it. image answers the image
the frames were copied into, and presentedDispatchCount how many frames reached the device.
"
Class {
	#name : 'VGImageHostSpaceStub',
	#superclass : 'VGVulkanPresentHostSpace',
	#instVars : [
		'image',
		'commandPool',
		'stubExtent',
		'presentedDispatchCount'
	],
	#category : 'VectorGraphics-Vulkan-Tests-Fixtures',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Fixtures'
}

{ #category : 'instance creation' }
VGImageHostSpaceStub class >> onExtent: anExtent [
	"A stub over an image of that extent on the session's own device, with the renderer of a
	 presenting host space already initialised for it."

	^ self new initializeOnExtent: anExtent
]

{ #category : 'initialization' }
VGImageHostSpaceStub >> destroy [
	"Everything I built, in the reverse of the order I built it."

	commandPool ifNotNil: [ commandPool destroy. commandPool := nil ].
	image ifNotNil: [ image destroy. image := nil ]
]

{ #category : 'accessing' }
VGImageHostSpaceStub >> image [
	"The image every frame of mine was copied into."

	^ image
]

{ #category : 'initialization' }
VGImageHostSpaceStub >> initializeOnExtent: anExtent [
	"One image usable as both ends of a copy, one command pool for the submissions, and a
	 presenting renderer initialised for me. No window and no chain are built: everything the
	 renderer asks of me is answered here."

	| context |
	context := VGVulkanDeviceSession default context.
	stubExtent := anExtent.
	presentedDispatchCount := 0.
	image := VkImage
		         on: context device
		         format: VkFormat b8g8r8a8Unorm
		         extent: anExtent
		         usage:
		         (VkImageUsage transferDstBit bitOr: VkImageUsage transferSrcBit).
	commandPool := context device createCommandPool:
		               context computeQueueFamily.
	renderer := VGVulkanPresentRenderer new.
	renderer initializeForHostSpace: self
]

{ #category : 'accessing' }
VGImageHostSpaceStub >> physicalSize [
	"The extent I was built on. My superclass asks a window for its Vulkan drawable, and I own
	 no window."

	^ stubExtent asPhysicalSize
]

{ #category : 'presenting' }
VGImageHostSpaceStub >> presentFrameFor: logicalDamagedRectangle scaleFactor: aNumber during: aBlock [
	"What VGVulkanPresentChain does to a frame, without a swapchain to acquire from or a
	 presentation engine to hand the image to: the image is declared undefined, the block
	 answers the dispatch holding the frame it computed or nil for a frame with nothing to
	 draw, and a dispatch is copied into the image in a submission of mine. A frame that
	 answers nil leaves the image as it was, where the chain would clear it: this fixture is
	 read for the pixels a frame draws, and a cleared image says nothing about them."

	| dispatch command |
	image declareLayoutUndefined.
	dispatch := aBlock value: image.
	dispatch ifNil: [ ^ nil ].
	presentedDispatchCount := presentedDispatchCount + 1.
	command := commandPool allocateBuffer.
	command do: [ :recorder | dispatch recordCopyInto: image in: recorder ].
	VGVulkanDeviceSession default context computeQueue
		submit: command
		andWait: true.
	^ dispatch
]

{ #category : 'accessing' }
VGImageHostSpaceStub >> presentedDispatchCount [
	"How many frames answered a dispatch, which is how many reached the device."

	^ presentedDispatchCount
]

{ #category : 'accessing' }
VGImageHostSpaceStub >> scaleFactor [
	"One: a reference drawn for comparison is drawn at the same scale, and the scale a window
	 reports is the window system's business, not this fixture's."

	^ 1
]
