"
I hold the Vulkan backend to the contract VGBackend freezes.
Three facts: it offers itself for selection ahead of the software backend, its probe answers an
instance of it or nothing at all on whichever machine the suite runs, and every drawing message it
inherits raises VGBackendFailure until unit 2.3 gives it pixels to write.
The fourth test draws a real frame through it and requires the picture the software backend draws,
which is the proof that the failover is arranged and not merely described.
I keep and restore the selection state of VGBackend, because forcing a backend or failing one is
class-side state that would otherwise leak into the next test.
"
Class {
	#name : 'VGVulkanBackendTest',
	#superclass : 'TestCase',
	#instVars : [
		'savedPreference',
		'savedRejections'
	],
	#category : 'VectorGraphics-Vulkan-Tests-Tests',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Tests'
}

{ #category : 'running' }
VGVulkanBackendTest >> frame [
	"The frame the backend tests draw, the same fixture the selection tests of the engine use, so
	 that a picture drawn here is held against the same picture."

	^ VGBackendFrameFixture new
]

{ #category : 'running' }
VGVulkanBackendTest >> setUp [
	"The preference and the rejections are class-side state of VGBackend, so a test that forces a
	 backend or fails one would leak into the next. Keep both and put them back."

	super setUp.
	savedPreference := VGBackend preferredClassOrNil.
	savedRejections := VGBackend rejectedClasses
]

{ #category : 'running' }
VGVulkanBackendTest >> tearDown [
	VGBackend restorePreference: savedPreference rejections: savedRejections.
	super tearDown
]

{ #category : 'tests' }
VGVulkanBackendTest >> testAFrameForcedOnTheVulkanBackendIsDrawnBySoftwareAnyway [
	"The failover with the real backend and not a stub: a surface forced onto it draws the
	 picture the software backend draws, and the Vulkan backend is out of selection afterwards."

	| expected drawn |
	expected := self frame drawnBy: VGSoftwareBackend new.
	VGBackend clearPreference.
	drawn := self frame drawnBy: VGVulkanBackend new.
	self assert: drawn bits equals: expected bits.
	self assert: (VGBackend rejectedClasses includes: VGVulkanBackend).
	self assert: VGBackend preferredClass equals: VGSoftwareBackend
]

{ #category : 'tests' }
VGVulkanBackendTest >> testEveryDrawingMessageFailsUntilTheBackendDraws [
	"Unit 2.0 wires the failover and nothing else, so the backend answers the whole boundary with
	 a failure that names it. The selectors are read from VGBackend itself rather than listed
	 here, so a boundary message added later is held to the same rule."

	| backend |
	backend := VGVulkanBackend new.
	VGBackend selectors do: [ :each |
		| arguments raised |
		arguments := (1 to: each numArgs) collect: [ :index | nil ].
		raised := [
		          backend perform: each withArguments: arguments.
		          nil ]
			          on: VGBackendFailure
			          do: [ :failure | failure ].
		self assert: raised notNil.
		self assert: raised backend identicalTo: backend ]
]

{ #category : 'tests' }
VGVulkanBackendTest >> testTheBackendIsProbedBeforeTheSoftwareOne [
	"It stands for selection, and it stands ahead of the failover, or a machine with a device
	 would still draw every pixel on the processor. A failover earlier in the session leaves this
	 backend out of selection on purpose, and the fact stated here is the order and not the
	 state, so the state is cleared first."

	VGBackend restorePreference: nil rejections: #( ).
	self assert: VGVulkanBackend isCandidate.
	self
		assert: VGVulkanBackend preferenceRank < VGSoftwareBackend preferenceRank.
	self assert: (VGBackend candidateClasses includes: VGVulkanBackend).
	self
		assert: (VGBackend candidateClasses indexOf: VGVulkanBackend)
		< (VGBackend candidateClasses indexOf: VGSoftwareBackend)
]

{ #category : 'tests' }
VGVulkanBackendTest >> testTheProbeAnswersTheBackendOrNothing [
	"The probe runs a real dispatch, so its answer depends on the machine the suite runs on: an
	 instance of the backend where a device computes, nil where none does. What may never happen
	 is a raise, because selection probes a candidate without a handler of its own."

	| probed |
	probed := VGVulkanBackend probe.
	probed ifNotNil: [ self assert: probed class equals: VGVulkanBackend ]
]
