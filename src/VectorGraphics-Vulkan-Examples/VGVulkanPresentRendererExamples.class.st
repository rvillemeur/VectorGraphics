"
I hold the example of the renderer that draws a window's frame on the device and presents it.

`VGVulkanPresentRenderer` records the space of a window, computes the frame on the device and
hands the dispatch to the host space, which copies it into the image the swapchain acquired. One
click opens a real, visible Vulkan window, presents the three frames `VGFrameDeviceBenchmark`
measures through it, and answers the renderer with its `Present` tab naming the frames it took,
the backend they were computed on and the surface they were recorded on.

The click opens a window and drives the device, so the example suite does not run it: an error
raised inside it opens a debugger on whichever process serves the call, and that process then
answers nothing. Every example named `open…` is kept out of the running gates for that reason.
Run this one by hand, alone, after committing.

The driver, the opt-in flag and the window are released in the reverse order they were acquired,
so the image is left as it was found and the renderer answered has no window any more.
See `VGVulkanPresentRenderer`, `VGVulkanPresentChainExamples` and `VGDrawnFrameElementExamples`.
"
Class {
	#name : 'VGVulkanPresentRendererExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Vulkan-Examples-Examples',
	#package : 'VectorGraphics-Vulkan-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGVulkanPresentRendererExamples class >> openWindowAndPresentTheBenchmarkFrames [
	<sampleInstance>
	"One click: a real, visible Vulkan window, the three frames VGFrameDeviceBenchmark measures
	 drawn on the device and presented through its swapchain two seconds apart, and the renderer
	 of that window answered once it is closed — its Present tab reads the frames it took and the
	 surface they were recorded on, both of which outlive the window. Answers nil on a machine
	 with no Vulkan device."
	"The space is shown rather than driven by hand, so the host, the window, the chain and the
	 renderer are the ones a Bloc space finds for itself while the driver is installed and this
	 project's presenting host is enabled. Each frame is settled before it is waited on, because
	 settling is what lays the element out and asks the renderer for the frame."
	"Named open… so that the example gates do not run it: see the class comment."

	| element space |
	VGVulkanDeviceSession default contextOrNil ifNil: [ ^ nil ].
	element := VGDrawnFrameElement new.
	^ PVVulkanDriver installDuring: [
		  VGVulkanPresentHost enableDuring: [
			  space := self spaceOfTheElement: element.
			  [
			  space show.
			  VGFrameDeviceBenchmark frameNames do: [ :each |
				  element drawBlock: (VGFrameDeviceBenchmark drawBlockNamed: each).
				  space invalidateAll.
				  space settle.
				  (Delay forSeconds: self secondsPerFrame) wait ].
			  space hostSpace renderer ] ensure: [ space close ] ] ]
]

{ #category : 'constants' }
VGVulkanPresentRendererExamples class >> secondsPerFrame [
	"How long each of the three frames stays on screen. Long enough to see which frame it is,
	 short enough that the window is gone before a watcher wonders whether it is stuck."

	^ 2
]

{ #category : 'examples' }
VGVulkanPresentRendererExamples class >> spaceOfTheElement: anElement [
	"A space holding that one element, sized for the frames the benchmark measures. The root is
	 told not to clip because a space lays its root out when it is opened and not before, and an
	 unopened root clips everything to the nothing it measures."

	| space |
	anElement extent: VGFrameDeviceBenchmark extentOfItsFrames.
	space := BlSpace new.
	space
		extent: VGFrameDeviceBenchmark extentOfItsFrames;
		title: self windowTitle.
	space root
		clipChildren: false;
		addChild: anElement.
	^ space
]

{ #category : 'constants' }
VGVulkanPresentRendererExamples class >> windowTitle [
	^ 'VectorGraphics frames presented from the device'
]

{ #category : 'examples' }
VGVulkanPresentRendererExamples >> openWindowAndPresentTheBenchmarkFrames [
	<sampleInstance>
	"One click: a real, visible Vulkan window, the three frames VGFrameDeviceBenchmark measures
	 drawn on the device and presented through its swapchain two seconds apart, and the renderer
	 of that window answered once the window is closed. Answers nil on a machine with no Vulkan
	 device."
	"The host space is built by hand, the way every device test of this unit builds it, and not
	 by showing the space: BlSpace >> show hands the space to BlHostRegistry default
	 preferredHost, which is set at image start and kept there, so a shown space opens on the
	 Morphic host and never reaches this one. The window, the surface, the swapchain and the
	 renderer are the real ones either way — only the frame loop is driven here rather than by
	 the universe, which is also why each frame is rendered directly and waited on instead of
	 settled."
	"Named open… so that the example gates do not run it: see the class comment."

	| element space hostSpace |
	VGVulkanDeviceSession default contextOrNil ifNil: [ ^ nil ].
	element := VGDrawnFrameElement new.
	^ PVVulkanDriver installDuring: [
		  VGVulkanPresentHost enableDuring: [
			  space := self spaceOfTheElement: element.
			  hostSpace := VGVulkanPresentHost default newHostSpaceFor: space.
			  hostSpace initializeRenderer.
			  [
			  hostSpace show.
			  VGFrameDeviceBenchmark frameNames do: [ :each |
				  element drawBlock: (VGFrameDeviceBenchmark drawBlockNamed: each).
				  space invalidateAll.
				  hostSpace render: space.
				  (Delay forSeconds: self secondsPerFrame) wait ].
			  hostSpace renderer ] ensure: [ hostSpace close ] ] ]
]

{ #category : 'examples' }
VGVulkanPresentRendererExamples >> spaceOfTheElement: anElement [
	"A space holding that one element, laid out and ready to be drawn, at the extent of the
	 frames the benchmark measures. The element is laid out while it is still detached and the
	 root is told not to clip, for the reason VGVulkanPresentRendererTest >> spaceOfShapes
	 gives: settling a space needs the pulse loop of a space the universe has opened, this space
	 is driven by hand instead, and an unsettled root stays at the extent it starts with, which
	 is none."

	| space |
	anElement extent: VGFrameDeviceBenchmark extentOfItsFrames.
	anElement forceLayout.
	space := BlSpace new.
	space
		extent: VGFrameDeviceBenchmark extentOfItsFrames;
		title: self windowTitle.
	space root
		clipChildren: false;
		addChild: anElement.
	^ space
]
