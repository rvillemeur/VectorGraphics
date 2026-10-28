"
I am a round trip on a machine with no Vulkan device, by construction, so a test can hold what
`VGVulkanRoundTrip` does when there is nothing to measure without depending on the machine it runs
on.
"
Class {
	#name : 'VGNoDeviceRoundTripStub',
	#superclass : 'VGVulkanRoundTrip',
	#category : 'VectorGraphics-Vulkan-Tests-Fixtures',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Fixtures'
}

{ #category : 'accessing' }
VGNoDeviceRoundTripStub class >> reason [
	"Why I have no device: because I am the fixture that has none."

	^ 'no device, by construction'
]

{ #category : 'running' }
VGNoDeviceRoundTripStub >> newSession [
	"No device ever, and the reason recorded as the real one records a driver fault."
	unavailableReason := self class reason.
	^ nil
]
