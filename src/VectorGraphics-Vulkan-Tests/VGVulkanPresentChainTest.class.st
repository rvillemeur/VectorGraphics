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

{ #category : 'tests - presentation' }
VGVulkanPresentChainTest >> testAQueueFamilyThatCannotPresentOnTheSurfaceIsRefused [
	"Submitting and presenting on a queue whose family cannot present on the surface is
	 invalid use that no validation layer catches when the layers are off: the driver may
	 answer nothing at all, and the acquire of the next frame then waits for an image that
	 never comes back. The chain asks before it presents, and says which family it asked
	 about."

	| message |
	message := [
	           VGVulkanPresentChain
		           verifySurface: VGNonPresentingSurfaceStub new
		           presentsOnQueueFamily: 7.
	           nil ]
		           on: Error
		           do: [ :error | error messageText ].
	self assert: message isNotNil.
	self assert: (message includesSubstring: '7')
]

{ #category : 'tests - waiting' }
VGVulkanPresentChainTest >> testEveryWaitOfAPresentedFrameIsBounded [
	"On 4 November a present loop with two unbounded waits in it froze this image for minutes:
	 a fence wait and an image acquire are plain uFFI calls, so the virtual machine is inside
	 the driver with the user interface stopped, and no Pharo process can interrupt it. The
	 bound converts that freeze into a raise. This test holds the bound rather than the
	 comment, because the next person to copy the hello-triangle loop would copy Vk noTimeout
	 with it."

	| timeout source |
	timeout := VGVulkanPresentChain frameTimeoutNanoseconds.
	self assert: timeout > 0.
	self assert: timeout < Vk noTimeout.
	self
		assert: timeout <= (10 raisedTo: 10)
		description: 'a bound of more than ten seconds is a freeze by another name'.
	source := VGVulkanPresentChain >> #presentFrameDuring:.
	self assert: (source sendsSelector: #frameTimeoutNanoseconds).
	self assert: (source sendsSelector: #acquireNextImage:fence:timeout:).
	self deny: (source sendsSelector: #noTimeout)
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

{ #category : 'tests - frames' }
VGVulkanPresentChainTest >> testTheChainRemembersTheIndexesItPresentedAndStillAnswersThemWhenDestroyed [
	"The cycle is the fact this unit is about, so the chain keeps it rather than leaving a
	 caller to collect it: presentedIndexes is what the inspector view reads and what an
	 example hands back. It outlives destroy, because an example destroys everything it built
	 before it answers and a window already closed is exactly when a reader wants to see what
	 it did."

	self withChainDo: [ :chain |
		| answered |
		answered := (1 to: self class presentedFrameCount) collect: [ :each |
			            chain presentFrameDuring: [ :image |  ] ].
		self assert: chain presentedIndexes asArray equals: answered asArray.
		chain destroy.
		self assert: chain presentedIndexes asArray equals: answered asArray ]
]

{ #category : 'tests - format' }
VGVulkanPresentChainTest >> testTheFormatThisProjectRendersInIsAccepted [
	"The format is not a property of a surface but a choice this project makes: the kernel
	 writes b8g8r8a8Unorm words and a presented frame has to be the same bytes an offscreen
	 frame is, so a swapchain of that format is the only one a presenting chain accepts."
	VGVulkanPresentChain verifyFormat: VkRenderConfig formatRenderedIn
]

{ #category : 'tests' }
VGVulkanPresentChainTest >> testTheFramesViewReadsTheChainAndChangesNothingInIt [
	"No device: a chain that holds no part answers every row of the report, which is what the
	 tab has to do after an example closes its window — so its gate stays active there, unlike
	 the Parts gate. The cells are pulled by hand because a table column's block runs once per
	 drawn row and nothing is drawn here."

	| chain view rows before context |
	chain := VGVulkanPresentChain new.
	before := chain presentedIndexes asArray.
	context := StInspectionContext new.
	chain inspectorFramesContext: context.
	self assert: context isActive.
	view := chain inspectorFrames:
		        (SpPresenterBuilder newApplication: SpApplication new).
	rows := view items.
	self assert: rows size equals: chain frameReport size.
	self
		assert: (rows collect: [ :each | each key ]) asArray
		equals: (chain frameReport collect: [ :each | each key ]) asArray.
	view columns do: [ :column |
		rows do: [ :row | self assert: (column evaluation value: row) isString ] ].
	self assert: (rows detect: [ :each | each key = 'destroyed' ]) value equals: 'true'.
	self
		assert: (rows detect: [ :each | each key = 'frames presented' ]) value
		equals: '0'.
	self assert: chain presentedIndexes asArray equals: before.
	self assert: chain partsInCreationOrder isEmpty
]

{ #category : 'tests' }
VGVulkanPresentChainTest >> testThePartsViewNumbersThePartsByDestructionAndIsGatedOnHoldingSome [
	"The Parts tab, device-free. A chain that holds no part has no tab, which is the gate; and
	 the numbering it would show is read from partsInDestructionOrder rather than written in
	 the view, so a part added to the chain appears in it on its own."

	| chain view context |
	chain := VGVulkanPresentChain new.
	context := StInspectionContext new.
	chain inspectorPartsContext: context.
	self deny: context isActive.
	view := chain inspectorParts:
		        (SpPresenterBuilder newApplication: SpApplication new).
	self assert: view items isEmpty.
	self assert: (view columns collect: [ :each | each title ]) asArray
		equals: #( 'Destroyed' 'Part' ).
	self assert: (chain partsInDestructionOrder
			 collect: [ :each | chain partsInCreationOrder indexOf: each ]) asArray
		equals: (1 to: chain partsInCreationOrder size) asArray reversed
]

{ #category : 'tests - presentation' }
VGVulkanPresentChainTest >> testTheQueueTheChainPresentsOnCanPresentOnItsSurface [
	"The refusal above is a stub; this is the machine. The chain submits and presents on the
	 one queue its context holds, so that queue's family has to be one the surface accepts.
	 This is the fact the chain verifies while it is being built, asserted here against a real
	 surface so that a machine where it does not hold fails a test rather than a window."

	self withChainDo: [ :chain |
		self assert:
			(chain surface supportsPresentation: chain context computeQueueFamily) ]
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
