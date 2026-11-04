"
I hold the example of the swapchain this project presents its frames through.

`VGVulkanPresentChain` owns the Vulkan objects built over one window: the surface, the swapchain, the render pass, a framebuffer per image, the command pool and buffer, the two semaphores and the fence. One click opens a real, visible Vulkan window, presents thirty frames through it, and answers the chain with its `Frames` tab naming the format and extent the driver gave, the indexes the frames went into, and whether they covered every image of the swapchain.

The click opens a window and drives the device, so the example suite does not run it: an error raised inside it opens a debugger on whichever process serves the call, and that process then answers nothing. `VGCairoExamplesTest >> windowExampleMethods` keeps every example named `open…` out of the running gates and holds the rule structurally instead. Run this one by hand, alone, after committing.

Everything acquired is released in the reverse order whatever the click does — chain, context, window, driver — so the image is left as it was found, and the chain answered is already destroyed. See `VGVulkanPresentChain` and `VGVulkanPresentHostExamples`.
"
Class {
	#name : 'VGVulkanPresentChainExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Vulkan-Examples-Examples',
	#package : 'VectorGraphics-Vulkan-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGVulkanPresentChainExamples class >> openWindowAndPresentFrames [
	<sampleInstance>
	"One click: a real, visible Vulkan window, thirty frames cleared and presented through a
	 chain of its own, and the chain answered with the window already closed — its Frames tab
	 reads presentedIndexes, which outlives the swapchain for exactly this reason. The window
	 is visible because presenting to a hidden one proves nothing about the presentation
	 engine. Answers nil on a machine with no Vulkan device.

	 Named open… so that the example gates do not run it: see the class comment."

	| attributes |
	VGVulkanDeviceSession default contextOrNil ifNil: [ ^ nil ].
	attributes := PVWindowAttributes newVulkan.
	attributes
		title: self windowTitle;
		extent: self windowExtent;
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
		  [
		  self presentedFrameCount timesRepeat: [
			  chain presentFrameDuring: [ :image | image ] ].
		  chain ] ensure: [ chain destroy ] ] ensure: [ context destroy ] ]
			  ensure: [ window destroy ] ]
]

{ #category : 'accessing' }
VGVulkanPresentChainExamples class >> presentedFrameCount [
	"Thirty frames: enough for the image index to cycle through a swapchain of two, three or
	 four images several times, and short enough that the window is gone before a watcher
	 wonders whether it is stuck."

	^ 30
]

{ #category : 'accessing' }
VGVulkanPresentChainExamples class >> windowExtent [
	^ 320 @ 240
]

{ #category : 'accessing' }
VGVulkanPresentChainExamples class >> windowTitle [
	^ 'VectorGraphics present chain'
]
