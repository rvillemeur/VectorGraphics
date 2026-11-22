"
I am a Vulkan backend that records a frame and then fails to compute it: dispatchOfRecordedFrameForExtent:
raises VGBackendFailure before any command is recorded.

I stand for the device lost in the middle of a window's frame, which is the case a presenting renderer
cannot fall back from: a window of this host has no surface to draw on the processor. I count the
attempts so a test can prove the renderer asked once and did not retry, and I raise before recording
anything, which is the contract every backend that can fail keeps.
"
Class {
	#name : 'VGFailingDispatchBackendStub',
	#superclass : 'VGVulkanBackend',
	#instVars : [
		'dispatchAttempts'
	],
	#category : 'VectorGraphics-Vulkan-Tests-Fixtures',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Fixtures'
}

{ #category : 'accessing' }
VGFailingDispatchBackendStub >> dispatchAttempts [
	"How many times a frame recorded on me was asked for its dispatch. One is all a presenting
	 renderer may try, because a window of that host has no second path to draw on."

	^ dispatchAttempts
]

{ #category : 'drawing' }
VGFailingDispatchBackendStub >> dispatchOfRecordedFrameForExtent: anExtent [
	"The raise comes before a command is recorded, so no caller is left holding a dispatch that
	 half ran."

	dispatchAttempts := dispatchAttempts + 1.
	VGBackendFailure
		signalFor: self
		because: 'this backend fails when the frame is dispatched'
]

{ #category : 'initialization' }
VGFailingDispatchBackendStub >> initialize [
	super initialize.
	dispatchAttempts := 0
]
