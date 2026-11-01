"
I am the renderer of a window that presents from the device. I override render:, because it is BARenderer >> render: that sends lockSurfaceFor:scaleFactor:during:, and the point of this path is that no CPU surface is ever locked.

I answer for a VGVulkanPresentHostSpace and fall back to the inherited CPU frame for every other host space. The fallback is not politeness: BlHostRenderer class >> availableClasses is self allSubclasses, so I appear in Bloc's renderer setting and preferableClass can pick me for an ordinary window, and drawing that window through the inherited path is better than failing to draw it. The test is a kind-of test on the host space rather than a question asked of it, because no method of this project may be installed on a Bloc class and VGRendererTest holds that rule.

In unit 7.1 my presenting branch counts the frame and draws nothing: the window, the absence of an SDL accelerated renderer and the route a frame takes are what that unit holds. The swapchain arrives in 7.2 and the drawing in 7.4.
"
Class {
	#name : 'VGVulkanPresentRenderer',
	#superclass : 'VGRenderer',
	#instVars : [
		'frameCount'
	],
	#category : 'VectorGraphics-Vulkan-Present',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Present'
}

{ #category : 'accessing' }
VGVulkanPresentRenderer class >> label [
	"What Bloc calls this engine in its renderer setting, where availableClasses offers every
	 subclass of BlHostRenderer. Distinct from my superclass's label, which names the software
	 path that draws every other window."

	^ 'VectorGraphics on a Vulkan swapchain'
]

{ #category : 'accessing' }
VGVulkanPresentRenderer >> frameCount [
	"How many frames I have presented since I was last initialised for a host space. Unit 7.1
	 reads it to see which route a frame took, because that unit presents nothing yet."

	^ frameCount
]

{ #category : 'initialization' }
VGVulkanPresentRenderer >> initialize [
	super initialize.
	frameCount := 0
]

{ #category : 'rendering' }
VGVulkanPresentRenderer >> render: aHostSpace [
	"A frame of a presenting window. Any other host space is drawn by the inherited CPU frame,
	 because BlHostRenderer class >> availableClasses is self allSubclasses: I appear in Bloc's
	 renderer setting and preferableClass can pick me for an ordinary window, which has to be
	 drawn rather than refused.
	 The three early answers are my superclass's — an invalid renderer, a host space with no
	 space, and a space with nothing dirty — and the dirty elements are cleared whatever the
	 frame does. Unit 7.1 counts the frame and draws nothing: the swapchain arrives in 7.2 and
	 the drawing in 7.4."

	| space |
	(aHostSpace isKindOf: VGVulkanPresentHostSpace) ifFalse: [
		^ super render: aHostSpace ].
	self isValid ifFalse: [ ^ self ].
	space := aHostSpace space.
	space ifNil: [ ^ self ].
	space hasDirtyElements ifFalse: [ ^ self ].
	[ frameCount := frameCount + 1 ] ensure: [ space clearDirtyElements ]
]
