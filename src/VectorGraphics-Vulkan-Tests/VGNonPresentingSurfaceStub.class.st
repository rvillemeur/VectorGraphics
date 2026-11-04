"
A surface whose queue families cannot present on it, which no machine with a working window system offers and which therefore cannot be obtained from a driver. It answers false to supportsPresentation:, the one message VGVulkanPresentChain class >> verifySurface:presentsOnQueueFamily: sends, so the refusal can be tested without a device.
"
Class {
	#name : 'VGNonPresentingSurfaceStub',
	#superclass : 'Object',
	#category : 'VectorGraphics-Vulkan-Tests-Fixtures',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Fixtures'
}

{ #category : 'testing' }
VGNonPresentingSurfaceStub >> supportsPresentation: aQueueFamilyIndex [
	^ false
]
