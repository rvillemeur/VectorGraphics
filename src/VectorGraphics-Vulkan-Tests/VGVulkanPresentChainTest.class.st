"
I hold what the swapchain of a presenting window has to be: the one format this project renders in, the frames it presents in sequence through its image count, and the order it destroys its parts in.

Two of my tests need neither a device nor a window, because the format refusal is a comparison of two numbers. The rest open a real window and a real device, and answer early when the image has neither, the way every other device test of this project does.
"
Class {
	#name : 'VGVulkanPresentChainTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Vulkan-Tests-Tests',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Tests'
}

{ #category : 'accessing' }
VGVulkanPresentChainTest class >> presentedFrameCount [
	"More frames than any swapchain has images, so the index really has to come round."
	^ 30
]

{ #category : 'accessing' }
VGVulkanPresentChainTest class >> windowExtent [
	"Small, because nothing is drawn into it: these tests watch the frame cycle and the
	 lifetime, not the pixels."
	^ 320 @ 240
]

{ #category : 'accessing' }
VGVulkanPresentChainTest class >> windowTitle [
	^ 'VectorGraphics present chain'
]

{ #category : 'tests - lifetime' }
VGVulkanPresentChainTest >> testADestroyedChainHoldsNoPartAndToleratesASecondDestroy [
	"Nothing is left on the device, and the chain says so itself rather than leaving a caller
	 to read ten slots. A second destroy is harmless because my fixture destroys the chain on
	 the way out and a test may have destroyed it already, and because a window closed twice
	 is the same case."
	self withChainDo: [ :chain |
		chain destroy.
		self assert: chain isDestroyed.
		self assert: chain partsInCreationOrder isEmpty.
		chain destroy.
		self assert: chain isDestroyed ]
]

{ #category : 'tests - format' }
VGVulkanPresentChainTest >> testAFormatOtherThanTheOneThisProjectRendersInIsRefused [
	"Refused out loud, and not worked around: a surface that offers no b8g8r8a8Unorm would
	 present the kernel's words with their channels swapped, and a frame drawn in the wrong
	 colours is worse than a window that says why it cannot open. The message names both
	 formats, because the one a machine does offer is what a reader needs next."
	| offered message |
	offered := VkRenderConfig formatRenderedIn + 1.
	message := [
	           VGVulkanPresentChain verifyFormat: offered.
	           nil ]
		           on: Error
		           do: [ :error | error messageText ].
	self assert: message isNotNil.
	self assert:
		(message includesSubstring: VkRenderConfig formatRenderedIn printString).
	self assert: (message includesSubstring: offered printString)
]

{ #category : 'tests - lifetime' }
VGVulkanPresentChainTest >> testTheChainDestroysItsPartsInTheReverseOfTheOrderItBuiltThem [
	"A framebuffer references an image view of the swapchain, and a swapchain references the
	 surface, so destroying forwards would hand the driver objects whose dependencies are
	 already gone. The order is stated once, in the order of creation, and destruction reads
	 it backwards — so this holds the one list rather than a sequence written out twice."
	self withChainDo: [ :chain |
		self
			assert: chain partsInDestructionOrder
			equals: chain partsInCreationOrder reversed.
		self assert: chain partsInCreationOrder first identicalTo: chain surface.
		self assert: chain partsInDestructionOrder first identicalTo: chain fence ]
]

{ #category : 'tests - frames' }
VGVulkanPresentChainTest >> testTheChainOfARealWindowRendersInTheFormatThisProjectRendersIn [
	"The refusal above is arithmetic; this is the machine. The extent is the drawable SDL
	 answers for a Vulkan window, which is the one the swapchain is created with, and the
	 image count is what the driver made rather than what was asked for."
	self withChainDo: [ :chain |
		self assert: chain format equals: VkRenderConfig formatRenderedIn.
		self assert: chain extent equals: chain backendWindow vulkanDrawableExtent.
		self assert: chain imageCount >= 1 ]
]

{ #category : 'tests - format' }
VGVulkanPresentChainTest >> testTheFormatThisProjectRendersInIsAccepted [
	"The format is not a property of a surface but a choice this project makes: the kernel
	 writes b8g8r8a8Unorm words and a presented frame has to be the same bytes an offscreen
	 frame is, so a swapchain of that format is the only one a presenting chain accepts."
	VGVulkanPresentChain verifyFormat: VkRenderConfig formatRenderedIn
]

{ #category : 'tests - frames' }
VGVulkanPresentChainTest >> testThirtyFramesPresentInSequenceAndTheImageIndexCyclesThroughTheImageCount [
	"The whole of this unit, measured on the one thing a presented frame answers: the index of
	 the image it went into. Thirty frames of a swapchain of two or three images must visit
	 every index and nothing beyond, and the block the chain evaluates is handed the image of
	 that index, which is what unit 7.4 draws into."
	self withChainDo: [ :chain |
		| indexes imagesSeen |
		indexes := OrderedCollection new.
		imagesSeen := OrderedCollection new.
		self class presentedFrameCount timesRepeat: [
			indexes add: (chain presentFrameDuring: [ :image |
					 imagesSeen add: image ]) ].
		self assert: indexes size equals: self class presentedFrameCount.
		self assert: imagesSeen size equals: self class presentedFrameCount.
		self
			assert: indexes asSet asSortedCollection asArray
			equals: (0 to: chain imageCount - 1) asArray.
		self deny: (indexes anySatisfy: [ :each | each >= chain imageCount ]) ]
]

{ #category : 'running' }
VGVulkanPresentChainTest >> withChainDo: aBlock [
	"A chain of mine over a real, visible Vulkan window, with everything released in the
	 reverse of the order it was acquired whatever the block does: chain, context, window,
	 driver. The window is visible because presenting to a hidden one proves nothing about
	 the presentation engine. Answers without evaluating the block when this machine has no
	 Vulkan device, which is how every device test of this project answers."
	| attributes |
	VGVulkanDeviceSession default contextOrNil ifNil: [ ^ self ].
	attributes := PVWindowAttributes newVulkan.
	attributes
		title: self class windowTitle;
		extent: self class windowExtent;
		windowCentered: true.
	^ PVVulkanDriver installDuring: [
		  | window |
		  window := OSWindow createWithAttributes: attributes.
		  [
		  | backendWindow context |
		  backendWindow := window backendWindow.
		  context := VkContext graphicsContextForExtensions:
			             backendWindow requiredInstanceExtensions.
		  [
		  | chain |
		  chain := VGVulkanPresentChain
			           onContext: context
			           backendWindow: backendWindow.
		  [ aBlock value: chain ] ensure: [ chain destroy ] ] ensure: [
			  context destroy ] ] ensure: [ window destroy ] ]
]
