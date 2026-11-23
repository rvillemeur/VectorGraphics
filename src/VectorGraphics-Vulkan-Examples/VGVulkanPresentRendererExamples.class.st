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
VGVulkanPresentRendererExamples class >> intervalsOfFrameNamed: aName presentedIn: aHostSpace of: aSpace [
	"One frame presented presentsPerFrame times, every present timed from the host, as one
	 round of one comparison. The first present is thrown away: it is the one that builds the
	 pipeline of that tile extent and acquires the first image of the swapchain."
	| comparison intervals |
	comparison := VGPresentPathComparison
		              frameName: aName
		              extent: aSpace extent
		              path: VGPresentPathBenchmark presentedPathName.
	aSpace invalidateAll.
	aHostSpace render: aSpace.
	intervals := (1 to: self presentsPerFrame) collect: [ :each |
		             | started |
		             started := Time microsecondClockValue.
		             aSpace invalidateAll.
		             aHostSpace render: aSpace.
		             Time microsecondClockValue - started ].
	comparison addRound: intervals stages: Dictionary new.
	^ comparison
]

{ #category : 'examples' }
VGVulkanPresentRendererExamples class >> openWindowAndPresentTheBenchmarkFrames [
	<sampleInstance>
	"One click: a real, visible Vulkan window, the three frames VGFrameDeviceBenchmark measures
	 drawn on the device and presented through its swapchain, and the interval each frame
	 achieved answered as one VGPresentPathComparison a frame once the window is closed.
	 Answers nil on a machine with no Vulkan device.
	 This is the windowed half of unit 7.6. The offscreen half, VGPresentPathBenchmark, is what
	 the two paths are compared on, because every present here waits for the vertical blank: a
	 FIFO swapchain is what VkRenderConfig asks for, so the intervals below are the refresh
	 period of the screen wherever the frame is faster than it, and they say that the path keeps
	 up and nothing about how fast it is."
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
			  VGFrameDeviceBenchmark frameNames collect: [ :each |
				  element drawBlock:
					  (VGFrameDeviceBenchmark drawBlockNamed: each).
				  self
					  intervalsOfFrameNamed: each
					  presentedIn: hostSpace
					  of: space ] ] ensure: [ hostSpace close ] ] ]
]

{ #category : 'constants' }
VGVulkanPresentRendererExamples class >> presentsPerFrame [
	"How many times each of the three frames is drawn and presented. The swapchain of this
	 project is FIFO, so a present waits for the vertical blank and the count is also how long
	 the frame stays on screen: a hundred and twenty presents are two seconds at sixty hertz,
	 which is what secondsPerFrame asked for when the frames were shown one present each.
	 Long enough to see which frame it is, short enough that the window is gone before a watcher
	 wonders whether it is stuck."
	^ 120
]

{ #category : 'examples' }
VGVulkanPresentRendererExamples class >> spaceOfElement: anElement extent: anExtent [
	"A space of that one element at that extent, laid out and ready to be drawn by hand.
	 The element is laid out while it is still detached, because settling a space needs the
	 pulse loop of a space the universe has opened and none of the spaces built here is ever
	 opened; and the root is told not to clip, because an unsettled root stays at the extent it
	 starts with, which is none, and would clip everything away.
	 This is the fixture the tests of the renderer build their spaces from as well: the recipe
	 was written out in three places before, with the same reason each time."

	| space |
	anElement extent: anExtent.
	anElement forceLayout.
	space := BlSpace new.
	space extent: anExtent.
	space root
		clipChildren: false;
		addChild: anElement.
	^ space
]

{ #category : 'examples' }
VGVulkanPresentRendererExamples class >> spaceOfTheElement: anElement [
	"The space the window example presents: that one element at the extent of the frames the
	 benchmark measures, titled for the window it opens."

	^ (self
		   spaceOfElement: anElement
		   extent: VGFrameDeviceBenchmark extentOfItsFrames)
		  title: self windowTitle;
		  yourself
]

{ #category : 'constants' }
VGVulkanPresentRendererExamples class >> windowTitle [
	^ 'VectorGraphics frames presented from the device'
]
