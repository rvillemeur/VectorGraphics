"
I am a Vulkan backend that refuses to touch host pixels. pixelsOf: and write:into: raise rather
than answering, so a frame drawn through me proves it never read a surface into host memory nor
wrote one back.

The gate of unit 7.3b uses me for the path that ends on the device, where those two copies are
exactly what the unit removes.
"
Class {
	#name : 'VGHostPixelRefusingBackendStub',
	#superclass : 'VGVulkanBackend',
	#category : 'VectorGraphics-Vulkan-Tests-Fixtures',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Fixtures'
}

{ #category : 'selection' }
VGHostPixelRefusingBackendStub class >> isCandidate [
	"I inherit from the Vulkan backend to draw a frame the way it does, but I am a fixture:
	 selection must never choose me, and a test holds me itself."

	^ false
]

{ #category : 'pixels' }
VGHostPixelRefusingBackendStub >> pixelsOf: aTarget [
	"The whole point of me: a frame that ends on the device reads no surface into host memory."

	self error: 'a frame that ends on the device read the pixels of a surface'
]

{ #category : 'pixels' }
VGHostPixelRefusingBackendStub >> write: aByteArray into: aTarget [
	"The whole point of me: a frame that ends on the device writes no surface back."

	self error: 'a frame that ends on the device wrote pixels into a surface'
]
