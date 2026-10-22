"
I am the backend that draws a frame on a Vulkan device.
My probe is a real dispatch and not a check that a library is present: it compiles the compute
path's own example kernel, adds two vectors on the device and reads the sums back, because a driver
that loads and a device that is listed say nothing about one that computes. It answers an instance
of me where that works and nil where it does not, and it never raises, because selection probes a
candidate without a handler of its own.
Unit 2.0 wires selection and the failover and nothing else, so every message of the boundary
VGBackend freezes raises VGBackendFailure here. The frame is then replayed on the software backend,
which is why a machine with a broken driver draws the same picture as one with no driver at all.
Units 2.1 to 2.6 fill the boundary in: I am the only class of this project allowed to name the
PharoVulkan bindings, and VGBackendSelectionTest holds the rest of it to that.
"
Class {
	#name : 'VGVulkanBackend',
	#superclass : 'VGBackend',
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
	^ self cannotDrawYet
]

{ #category : 'drawing - private' }
VGVulkanBackend >> cannotDrawYet [
	"Unit 2.0 wires selection and the failover and leaves the drawing to the units behind it. The
	 failure is raised before any pixel of mine is written, which is what the boundary asks of a
	 backend that can fail: a frame half drawn cannot be mended by replaying it elsewhere."

	^ VGBackendFailure
		  signalFor: self
		  because: 'the Vulkan backend draws no frame before unit 2.3'
]

{ #category : 'draining' }
VGVulkanBackend >> drainInto: aTarget [
	^ self cannotDrawYet
]

{ #category : 'drawing' }
VGVulkanBackend >> fillSegments: aSegments paint: aPaint clip: aClip operator: anOperator [
	^ self cannotDrawYet
]
