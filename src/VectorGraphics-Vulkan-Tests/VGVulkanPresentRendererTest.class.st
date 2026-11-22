"
The frame of a presenting window, drawn where no window is: the renderer draws a real Bloc
space through VGImageHostSpaceStub, which hands it one plain image and copies the frame
into it, and the pixels of that image are held to what the software backend draws from the
same space. A window shows the same frames and proves nothing a reference can be compared
to, which is why the window is a smoke test of its own and this is the gate.
"
Class {
	#name : 'VGVulkanPresentRendererTest',
	#superclass : 'VGTiledFrameTestCase',
	#category : 'VectorGraphics-Vulkan-Tests-Tests',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Tests'
}

{ #category : 'running' }
VGVulkanPresentRendererTest >> softwareFormOfSpace: aSpace extent: anExtent [
	"The frame that space draws on the processor, which is the oracle of every frame the
	 renderer draws on the device. The canvas is built the way a renderer builds one, so the
	 two frames differ by the backend and by nothing else."

	| surface canvas |
	surface := VGCairoImageSurface extent: anExtent.
	canvas := VGCanvas newWithoutSurface.
	canvas prepareForSurface: surface.
	canvas clippingRectangle: (0 @ 0 extent: anExtent).
	aSpace aeFullDrawOn: canvas.
	canvas removeSurface.
	surface backend: VGSoftwareBackend new.
	surface flush.
	^ surface asForm
]

{ #category : 'fixture' }
VGVulkanPresentRendererTest >> spaceDrawing: aBlock extent: anExtent [
	"A Bloc space whose one element draws that frame of this project's drawing context, laid out
	 and ready to be drawn, the way spaceOfShapes builds its own."

	^ VGVulkanPresentRendererExamples
		  spaceOfElement: (VGDrawnFrameElement drawing: aBlock)
		  extent: anExtent
]

{ #category : 'fixture' }
VGVulkanPresentRendererTest >> spaceOfShapes [
	"A Bloc space of three overlapping elements, laid out and ready to be drawn: a frame of it
	 is a frame of fills and nothing the subset refuses, which is what a presented window draws
	 too. VGVulkanPresentRendererExamples class >> spaceOfElement:extent: lays the content out
	 and says why it is laid out detached."

	| content |
	content := BlElement new
		           background: (Color r: 0.1 g: 0.7 b: 0.2);
		           yourself.
	content
		addChild: (BlElement new
				 background: (Color
						  r: 0.9
						  g: 0.4
						  b: 0.0
						  alpha: 0.6);
				 extent: 30 @ 24;
				 position: 5 @ 7;
				 yourself);
		addChild: (BlElement new
				 background: (Color r: 0.0 g: 0.2 b: 0.8);
				 extent: 18 @ 18;
				 position: 24 @ 26;
				 yourself).
	^ VGVulkanPresentRendererExamples
		  spaceOfElement: content
		  extent: self caseExtent
]

{ #category : 'tests' }
VGVulkanPresentRendererTest >> testAFrameTheDeviceRefusesPresentsNothingAndTakesTheBackendOutOfSelection [
	"A device that fails during a frame of a window: the renderer has no surface to fall back
	 on, so the frame is lost rather than drawn on the processor. Nothing is presented — the
	 host space is given no dispatch — the backend is asked once and not retried, and the
	 backend class is taken out of selection, which is what sends the next window of this image
	 to the software backend."

	| hostSpace space preference rejections backend |
	self hasDevice ifFalse: [ ^ self ].
	space := self spaceOfShapes.
	hostSpace := VGImageHostSpaceStub onExtent: self caseExtent.
	preference := VGBackend preferredClassOrNil.
	rejections := VGBackend rejectedClasses.
	backend := VGFailingDispatchBackendStub new.
	[
	hostSpace renderer backend: backend.
	hostSpace space: space.
	space invalidateAll.
	hostSpace render: space.
	self assert: hostSpace presentedDispatchCount equals: 0.
	self assert: backend dispatchAttempts equals: 1.
	self assert: (VGBackend rejectedClasses includes:
			 VGFailingDispatchBackendStub) ] ensure: [
		VGBackend restorePreference: preference rejections: rejections.
		hostSpace destroy ]
]

{ #category : 'tests' }
VGVulkanPresentRendererTest >> testAPresentedFrameCopiesNoPixelThroughTheHost [
	"The presented path pays neither host copy. A backend whose pixelsOf: and write:into:
	 raise draws the frame of the space and the image still carries it, so nothing between the
	 space and the swapchain image read a surface into host memory or wrote one back."

	| hostSpace space |
	self hasDevice ifFalse: [ ^ self ].
	space := self spaceOfShapes.
	hostSpace := VGImageHostSpaceStub onExtent: self caseExtent.
	[
	hostSpace renderer backend: VGHostPixelRefusingBackendStub new.
	hostSpace space: space.
	space invalidateAll.
	hostSpace render: space.
	self assert: hostSpace presentedDispatchCount equals: 1.
	self
		deny: ((self pixelsOfImage: hostSpace image) allSatisfy: [ :each |
				 each = 0 ])
		description: 'the presented frame laid down no pixel at all' ] ensure: [
		hostSpace destroy ]
]

{ #category : 'tests' }
VGVulkanPresentRendererTest >> testEveryCaseOfTheCorpusReachesTheImageWithThePixelsTheSoftwareBackendDraws [
	"The gate of this unit, offscreen: every case of the conformance corpus the subset draws,
	 drawn as a Bloc space through the presenting renderer into a real image, lays down the
	 pixels the software backend lays down. The image is the one a swapchain would hand over,
	 and the comparison is the one every device test of this corpus makes — no pixel farther
	 than the tolerance in any channel, and at most the measured count of pixels differing at
	 all — so a screenshot of a window is never needed to know the frame arrived."

	self hasDevice ifFalse: [ ^ self ].
	self supportedCasesDo: [ :case :draw :entries |
		| hostSpace space comparison |
		space := self spaceDrawing: draw extent: case extent.
		hostSpace := VGImageHostSpaceStub onExtent: case extent.
		[
		hostSpace space: space.
		space invalidateAll.
		hostSpace render: space.
		self
			assert: hostSpace presentedDispatchCount = 1
			description: case name.
		comparison := VGFormComparison
			              between: (self formOfImage: hostSpace image)
			              and: (self
					               softwareFormOfExtent: case extent
					               drawnWith: draw).
		self
			assert:
			(comparison pixelsFartherThan: self class deviceChannelTolerance) = 0
			description: case name.
		self
			assert: comparison differingPixelCount
				    <= self class devicePixelsAllowedToDifferPerCase
			description: case name ] ensure: [ hostSpace destroy ] ]
]

{ #category : 'tests' }
VGVulkanPresentRendererTest >> testTheFrameOfASpaceReachesTheImageWithThePixelsTheSoftwareBackendDraws [
	"The gate of unit 7.4: the renderer draws the space it is given on the device and the frame
	 ends in the image the host space handed it, holding what the software backend draws from
	 the same space. One render is one frame, and the frame reached the device rather than being
	 refused, which presentedDispatchCount says."

	| space hostSpace comparison |
	self hasDevice ifFalse: [ ^ self ].
	space := self spaceOfShapes.
	hostSpace := VGImageHostSpaceStub onExtent: self caseExtent.
	[
	hostSpace space: space.
	space invalidateAll.
	hostSpace render: space.
	self assert: hostSpace presentedDispatchCount equals: 1.
	comparison := VGFormComparison
		              between: (self formOfImage: hostSpace image)
		              and: (self
				               softwareFormOfSpace: space
				               extent: self caseExtent).
	self
		assert:
		(comparison pixelsFartherThan: self class deviceChannelTolerance) = 0
		description: 'the presented frame is not the frame drawn on the processor'.
	self
		assert: comparison differingPixelCount
			    <= self class devicePixelsAllowedToDifferPerCase
		description: 'too many pixels of the presented frame differ' ] ensure: [
		hostSpace destroy ]
]
