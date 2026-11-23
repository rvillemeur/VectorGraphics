"
I hold the gate of unit 7.3b: a frame that ends on the device rather than in host memory.

The dispatch copies its target buffer into a VkImage by vkCmdCopyBufferToImage, with the layout
transitions around it, and VGVulkanBackend asks for that instead of draining into a surface. What
I prove is that the pixels are the same ones: the image read back holds what the software backend
draws for the same frame, within the tolerance of VGTiledFrameTestCase, and the frame pays no
readback stage and copies no pixels through the host on the way.
"
Class {
	#name : 'VGTiledImageCopyTest',
	#superclass : 'VGTiledFrameTestCase',
	#category : 'VectorGraphics-Vulkan-Tests-Tests',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Tests'
}

{ #category : 'fixtures' }
VGTiledImageCopyTest >> recordFrame: aBlock on: aBackend [
	"That frame recorded on the backend and not drained, which is what a surface does to the
	 backend it holds: it replays its display list and drains afterwards."

	| surface |
	surface := VGCairoImageSurface extent: self caseExtent.
	aBlock value: surface newContext.
	surface displayList replayOn: aBackend.
	surface displayList reset
]

{ #category : 'tests' }
VGTiledImageCopyTest >> testABackendWithNothingRecordedAnswersNoDispatch [
	"A frame that recorded nothing asks the device for nothing: the backend answers nil rather
	 than a dispatch over an empty encoding, and the caller takes that as the frame it has to
	 fill the image with by itself."

	| backend |
	self hasDevice ifFalse: [ ^ self ].
	backend := VGVulkanBackend new.
	self assert:
		(backend dispatchOfRecordedFrameForExtent: self caseExtent) isNil
]

{ #category : 'tests' }
VGTiledImageCopyTest >> testAFrameThatEndsInAnImagePaysTheCopyAndNoReadback [
	"The two last stages belong to one kind of frame each. A frame that ends in an image is
	 timed for its copy and reaches no readback at all, so a report of it shows a copy row and
	 no readback row. The dispatch is my own and not the session's, because a dispatch asked to
	 record its stages records them for every frame after, and the session's draws the frames
	 of every other test."

	| encoding dispatch image |
	self hasDevice ifFalse: [ ^ self ].
	encoding := self
		            encodingOfExtent: self caseExtent
		            drawnWith: self mixedFillFrame.
	dispatch := VGTiledFillDispatch on:
		            VGVulkanDeviceSession default context.
	image := self imageOfExtent: self caseExtent.
	[
	dispatch recordStages.
	dispatch draw: encoding endingIn: image.
	self assert: (dispatch stageMicroseconds includesKey: #copy).
	self deny: (dispatch stageMicroseconds includesKey: #readback).
	self assert: (dispatch microsecondsOfStage: #copy) isNil not ]
		ensure: [
			dispatch releaseDevice.
			image destroy ]
]

{ #category : 'tests' }
VGTiledImageCopyTest >> testAFrameThatEndsOnTheDeviceCopiesNoPixelThroughTheHost [
	"What the unit removes: the two host copies a drained frame pays, one reading the surface
	 into packed bytes and one writing them back. A backend whose pixelsOf: and write:into:
	 raise draws the same frame into an image without reaching either, and still lays down the
	 pixels the software backend draws."

	| backend image |
	self hasDevice ifFalse: [ ^ self ].
	backend := VGHostPixelRefusingBackendStub new.
	image := self imageOfExtent: self caseExtent.
	[
	self recordFrame: self mixedFillFrame on: backend.
	backend drawFrameInto: image.
	self
		deny: ((self pixelsOfImage: image) allSatisfy: [ :each | each = 0 ])
		description: 'the frame laid down no pixel at all' ] ensure: [
		image destroy ]
]

{ #category : 'tests' }
VGTiledImageCopyTest >> testAFrameWithNothingRecordedLeavesTheImageAsItWas [
	"The degenerate frame: a backend drained into an image with nothing recorded asks nothing
	 of a device and writes nothing, so the image still holds the picture the frame before it
	 left there."

	| backend image drawn |
	self hasDevice ifFalse: [ ^ self ].
	backend := VGVulkanBackend new.
	image := self imageOfExtent: self caseExtent.
	[
	self recordFrame: self mixedFillFrame on: backend.
	backend drawFrameInto: image.
	drawn := self pixelsOfImage: image.
	backend drawFrameInto: image.
	self assert: (self pixelsOfImage: image) equals: drawn ] ensure: [
		image destroy ]
]

{ #category : 'tests' }
VGTiledImageCopyTest >> testEveryCaseOfTheSubsetDrawsIntoAnImageWhatTheSoftwareBackendDraws [
	"The gate of unit 7.3b. Every case of the conformance corpus the subset draws is drawn once
	 through the copy into an image and once by the software backend, and the two pictures are
	 the same within the tolerance the device is held to everywhere else. One image is made for
	 the whole walk, because every case is of one extent and a frame overwrites all of it."

	| image |
	self hasDevice ifFalse: [ ^ self ].
	image := self imageOfExtent: self caseExtent.
	[
	self supportedCasesDo: [ :case :draw :entries |
		| comparison backend |
		backend := VGVulkanBackend new.
		self recordFrame: draw on: backend.
		backend drawFrameInto: image.
		comparison := VGFormComparison
			              between: (self formOfImage: image)
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
			description: case name ] ] ensure: [ image destroy ]
]

{ #category : 'tests' }
VGTiledImageCopyTest >> testTheBackendAnswersTheDispatchThatHoldsTheRecordedFrame [
	"The seam the presenting path draws through: the backend encodes and dispatches the frame
	 recorded on it for the extent asked for, and answers the dispatch that holds the result in
	 its target buffer, with no copy and no readback. The caller records the copy where its own
	 submission needs it. The pixels are the ones a drain into a surface of the same extent
	 writes, because the same frame is encoded for the same extent either way."

	| backend dispatch image pool command drained |
	self hasDevice ifFalse: [ ^ self ].
	backend := VGVulkanBackend new.
	image := self imageOfExtent: self caseExtent.
	pool := VGVulkanDeviceSession default context device createCommandPool:
		        VGVulkanDeviceSession default context computeQueueFamily.
	[
	self recordFrame: self mixedFillFrame on: backend.
	backend drawFrameInto: image.
	drained := self pixelsOfImage: image.
	self recordFrame: self mixedFillFrame on: backend.
	dispatch := backend dispatchOfRecordedFrameForExtent: self caseExtent.
	self deny: dispatch isNil.
	command := pool allocateBuffer.
	command do: [ :recorder | dispatch recordCopyInto: image in: recorder ].
	VGVulkanDeviceSession default context computeQueue
		submit: command
		andWait: true.
	self assert: (self pixelsOfImage: image) equals: drained ] ensure: [
		pool destroy.
		image destroy ]
]

{ #category : 'tests' }
VGTiledImageCopyTest >> testTheBackendDrawsItsRecordedFrameStraightIntoAnImage [
	"The path a presenting window takes: the backend is given a frame the way a surface gives
	 it one, by replaying a display list, and then drains it into an image rather than into the
	 pixels of a surface. What the image holds afterwards is what the software backend draws
	 for the same frame."

	| backend image comparison |
	self hasDevice ifFalse: [ ^ self ].
	backend := VGVulkanBackend new.
	image := self imageOfExtent: self caseExtent.
	[
	self recordFrame: self mixedFillFrame on: backend.
	backend drawFrameInto: image.
	comparison := VGFormComparison
		              between: (self formOfImage: image)
		              and: (self
				               softwareFormOfExtent: self caseExtent
				               drawnWith: self mixedFillFrame).
	self assert:
		(comparison pixelsFartherThan: self class deviceChannelTolerance) = 0.
	self assert: comparison differingPixelCount
		<= self class devicePixelsAllowedToDifferPerCase ] ensure: [
		image destroy ]
]

{ #category : 'tests' }
VGTiledImageCopyTest >> testTheCopyIntoAnImageIsRecordedInTheCallersOwnSubmission [
	"A presented frame cannot pay for a submission of its own: the copy into the acquired image
	 has to sit in the submission that waits on the image being available and signals the one
	 the presentation engine waits on. So the copy is recordable on a command buffer the caller
	 owns, and the dispatch neither submits nor times it — a copy stage is recorded only by the
	 path that owns the submission. The dispatch is my own, because one asked to record its
	 stages records them for every frame after, and the session's draws the frames of the other
	 tests."

	| encoding pixelCount dispatch readBack image pool command context |
	self hasDevice ifFalse: [ ^ self ].
	context := VGVulkanDeviceSession default context.
	encoding := self
		            encodingOfExtent: self caseExtent
		            drawnWith: self mixedFillFrame.
	pixelCount := self caseExtent x * self caseExtent y
	              * VGTiledFillEncoding targetFormat bytesPerPixel.
	dispatch := VGTiledFillDispatch on: context.
	readBack := ByteArray new: pixelCount.
	image := self imageOfExtent: self caseExtent.
	pool := context device createCommandPool: context computeQueueFamily.
	[
	dispatch recordStages.
	dispatch draw: encoding into: readBack.
	dispatch draw: encoding into: (ByteArray new: pixelCount) readBack: false.
	command := pool allocateBuffer.
	command do: [ :recorder | dispatch recordCopyInto: image in: recorder ].
	self
		deny: (dispatch stageMicroseconds includesKey: #copy)
		description: 'recording the copy timed a stage, so it submitted on its own'.
	context computeQueue submit: command andWait: true.
	self
		deny: (readBack allSatisfy: [ :each | each = 0 ])
		description: 'the frame laid down no pixel at all'.
	self assert: (self pixelsOfImage: image) equals: readBack ] ensure: [
		dispatch releaseDevice.
		pool destroy.
		image destroy ]
]

{ #category : 'tests' }
VGTiledImageCopyTest >> testTheImageAFrameEndsInHoldsThePixelsTheSameFrameReadBackHolds [
	"A frame that ends on the device writes into the image what a frame read back writes into
	 the host. The same encoding is drawn twice from a zeroed target, once ending in an image
	 and once read back, and the bytes of the image are the bytes of the readback."

	| encoding dispatch readBack image |
	self hasDevice ifFalse: [ ^ self ].
	encoding := self
		            encodingOfExtent: self caseExtent
		            drawnWith: self mixedFillFrame.
	dispatch := VGVulkanDeviceSession default dispatchForEncoding: encoding.
	readBack := ByteArray new: encoding targetByteCount.
	dispatch draw: encoding into: readBack.
	image := self imageOfExtent: self caseExtent.
	[
	dispatch draw: encoding endingIn: image.
	self
		deny: (readBack allSatisfy: [ :each | each = 0 ])
		description: 'the frame laid down no pixel at all'.
	self assert: (self pixelsOfImage: image) equals: readBack ]
		ensure: [ image destroy ]
]
