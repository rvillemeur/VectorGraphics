"
I am the backend that draws a frame on a Vulkan device.

My probe is a real dispatch and not a check that a library is present: it compiles the compute path's own example kernel, adds two vectors on the device and reads the sums back, because a driver that loads and a device that is listed say nothing about one that computes. It answers an instance of me where that works and nil where it does not, and it never raises, because selection probes a candidate without a handler of its own.

I record the frame I am given and draw it when I am drained. `fillSegments:paint:clip:operator:` builds the entry and keeps it, and an entry the tiled fill subset refuses — a gradient, a surface or a mesh paint, a shaped clip, or an operator that writes where no source covers — fails the frame there and then, while the surface can still replay the whole of it on the software backend. A surface blit is no fill and fails the same way. On `drainInto:` the frame is binned and encoded by `VGTiledFillEncoding`, dispatched through `VGTiledFillDispatch` over one workgroup a tile, and written into the target last of all, so that a fault of a driver leaves the target as it was. A target of another format than the one a frame is encoded for is refused before the first pixel too.

The device is opened and destroyed around one frame, which is what unit 2.3 needs and no more: a later unit keeps it between frames.

I am one of the classes of the Vulkan packages allowed to name the PharoVulkan bindings, and `VGCairoReferenceScanner` holds every other package of this project to naming none of them.
"
Class {
	#name : 'VGVulkanBackend',
	#superclass : 'VGBackend',
	#instVars : [
		'recordedFrame'
	],
	#category : 'VectorGraphics-Vulkan-Backend',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Backend'
}

{ #category : 'selection - private' }
VGVulkanBackend class >> computesTheProbeSumOn: aContext [
	"Whether the device adds two vectors and gives the sums back. The kernel is the one the
	 compute path's own example compiles, so the probe exercises the whole way from a Pharo method
	 to a result in a buffer: the compiler, the SPIR-V module, the descriptor set, the dispatch
	 and the readback. Everything it opened is destroyed before the answer, kernel before buffers,
	 because a buffer freed under a live pipeline takes the image with it."

	| kernel buffers |
	kernel := PVComputeKernel
		          fromMethod: PVComputeKernel exampleKernelMethod
		          on: aContext.
	buffers := (1 to: PVComputeKernel exampleBufferCount) collect: [ :each |
		           VkBuffer
			           storageBuffer: PVComputeKernel exampleElementCount
			           on: aContext device ].
	^ [
	  buffers do: [ :each |
		  each putF32s: self probeTerms.
		  kernel bindBuffer: each ].
	  kernel prepare.
	  kernel
		  dispatch: self probeWorkgroupCount
		  y: self probeWorkgroupCount
		  z: self probeWorkgroupCount.
	  buffers last getF32s = self probeSums ] ensure: [
		  kernel destroy.
		  buffers do: [ :each | each destroy ] ]
]

{ #category : 'selection' }
VGVulkanBackend class >> isCandidate [
	"I stand for selection wherever this package is loaded. Whether I can draw is the probe's
	 answer and not mine."

	^ true
]

{ #category : 'selection' }
VGVulkanBackend class >> preferenceRank [
	"I draw on a device, so I am probed before the software backend and used whenever my probe
	 answers."

	^ self hardwareRank
]

{ #category : 'selection' }
VGVulkanBackend class >> probe [
	"An instance of me if a device on this machine really computes, nil if none does. Every fault
	 of a driver is caught, whatever class it arrives as: a missing library, a device that refuses
	 a queue and a dispatch that answers rubbish are one answer here, which is that I am not
	 available. The handler answers nil rather than swallowing the fault, because a candidate is
	 probed by selection without a handler of its own."

	| context |
	context := [ VkContext computeContext ]
		           on: Error
		           do: [ :failure | nil ].
	context ifNil: [ ^ nil ].
	^ [
	  [ (self computesTheProbeSumOn: context) ifTrue: [ self new ] ]
		  on: Error
		  do: [ :failure | nil ] ] ensure: [ context destroy ]
]

{ #category : 'selection - private' }
VGVulkanBackend class >> probeSums [
	"What the device owes back: the terms added to themselves, since the probe hands the same
	 vector to both inputs of the kernel."

	^ self probeTerms collect: [ :each | each + each ]
]

{ #category : 'selection - private' }
VGVulkanBackend class >> probeTerms [
	"The floats the probe adds. Small whole numbers, because they are exact in a 32-bit float
	 both as terms and as sums, so the readback is compared for equality and not for closeness.
	 There is one per element the example kernel's buffers hold."

	^ (1 to: PVComputeKernel exampleElementCount) collect: [ :each |
		  each asFloat ]
]

{ #category : 'selection - private' }
VGVulkanBackend class >> probeWorkgroupCount [
	"One workgroup in each dimension. The example kernel declares a local size that covers its
	 own buffers in a single workgroup, so one is the whole dispatch."

	^ 1
]

{ #category : 'drawing' }
VGVulkanBackend >> blitSurface: aSurface at: aPoint paint: aPaint clip: aClip operator: anOperator [
	"Recorded and not drawn, as a fill is. The blit itself is recorded and not the fill the tiled
	 rasteriser rewrites it into, because the surface may still replay this frame on the software
	 backend and that backend draws a blit from its mask."

	| entry |
	entry := VGBlitEntry
		         surface: aSurface
		         at: aPoint
		         paint: aPaint
		         clip: aClip
		         operator: anOperator.
	(VGTiledFillRasteriser supportsEntry: entry) ifFalse: [
		^ self refuseBecause: 'a blit outside the tiled fill subset' ].
	recordedFrame add: entry
]

{ #category : 'draining' }
VGVulkanBackend >> dispatch: anEncoding into: aByteArray [
	"The device trip, with every fault of a driver answered as a refusal: a missing library, a
	 device that refuses a queue and a dispatch that raises are one answer here, which is that
	 this frame belongs to the software backend. The context is created and destroyed around the
	 one frame; a later unit keeps a device between frames, which is where the 72 ms of a context
	 stop being paid once a frame."

	| context |
	context := nil.
	^ [
	  [
	  context := VkContext computeContext.
	  (VGTiledFillDispatch on: context) draw: anEncoding into: aByteArray ]
		  on: Error
		  do: [ :failure |
			  self refuseBecause: 'the device failed the frame: ' , failure description ] ]
		  ensure: [ context ifNotNil: [ context destroy ] ]
]

{ #category : 'draining' }
VGVulkanBackend >> drainInto: aTarget [
	"The frame on the device: binned, encoded, dispatched over one workgroup a tile, and the
	 pixels written into the target last of all, so that a fault of a driver leaves the target as
	 it was. The recorded frame is dropped either way, because the surface replays its own list
	 and not mine."

	[ self drawRecordedFrameInto: aTarget ] ensure: [ recordedFrame reset ]
]

{ #category : 'draining' }
VGVulkanBackend >> drawRecordedFrameInto: aTarget [
	"Nothing recorded is nothing to draw and no device to ask for. A target of another format
	 belongs to the software backend, because a frame is encoded for one format and quantised
	 while it is encoded."

	| pixels |
	recordedFrame isEmpty ifTrue: [ ^ self ].
	aTarget format = VGTiledFillEncoding targetFormat ifFalse: [
		^ self refuseBecause: 'a target of a format the frame is not encoded for' ].
	pixels := self pixelsOf: aTarget.
	self
		dispatch:
			(VGTiledFillEncoding of: recordedFrame extent: aTarget extent)
		into: pixels.
	self write: pixels into: aTarget
]

{ #category : 'drawing' }
VGVulkanBackend >> fillSegments: aSegments paint: aPaint clip: aClip operator: anOperator [
	"Recorded and not drawn. An entry the tiled fill subset refuses fails the frame here, while
	 the surface can still replay the whole of it on the software backend."

	| entry |
	entry := VGFillEntry
		         segments: aSegments
		         paint: aPaint
		         clip: aClip
		         operator: anOperator.
	(VGTiledFillRasteriser supportsEntry: entry) ifFalse: [
		^ self refuseBecause: 'an entry outside the tiled fill subset' ].
	recordedFrame add: entry
]

{ #category : 'initialization' }
VGVulkanBackend >> initialize [
	"A backend of mine records the frame it is given and draws it when it is drained, which is
	 what the boundary asks of a backend that can fail: the whole frame is checked before its
	 first pixel."

	super initialize.
	recordedFrame := VGDisplayList new
]

{ #category : 'pixels' }
VGVulkanBackend >> pixelsOf: aTarget [
	"The pixels of the target, packed row after row with no padding, because the kernel indexes a
	 pixel by its row and its column alone. They are a copy and not the bytes of the surface: the
	 device writes into the copy, and the target is written once the frame has come back whole."

	| rowBytes answer |
	rowBytes := aTarget width * aTarget format bytesPerPixel.
	answer := ByteArray new: rowBytes * aTarget height.
	0 to: aTarget height - 1 do: [ :row |
		answer
			replaceFrom: row * rowBytes + 1
			to: row + 1 * rowBytes
			with: aTarget data
			startingAt: row * aTarget stride + 1 ].
	^ answer
]

{ #category : 'accessing' }
VGVulkanBackend >> recordedFrame [
	"The frame recorded on me and not yet drained."

	^ recordedFrame
]

{ #category : 'failing' }
VGVulkanBackend >> refuseBecause: aReason [
	"A refusal and not a frame half drawn: a backend may fail while a frame is recorded or while
	 it is drained, never between its first pixel and its last."

	^ VGBackendFailure signalFor: self because: aReason
]

{ #category : 'pixels' }
VGVulkanBackend >> write: aByteArray into: aTarget [
	"The frame back into the target, row by row, because a target may hold padding at the end of
	 a row and nothing of this frame belongs there."

	| rowBytes |
	rowBytes := aTarget width * aTarget format bytesPerPixel.
	0 to: aTarget height - 1 do: [ :row |
		aTarget data
			replaceFrom: row * aTarget stride + 1
			to: row * aTarget stride + rowBytes
			with: aByteArray
			startingAt: row * rowBytes + 1 ]
]
