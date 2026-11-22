Class {
	#name : 'VGCopylessSurfaceStub',
	#superclass : 'Object',
	#category : 'VectorGraphics-Vulkan-Tests-Fixtures',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Fixtures'
}

{ #category : 'accessing' }
VGCopylessSurfaceStub >> capabilities [
	"What a driver answers about a surface, with the usage flags of a surface that accepts no
	 copy into its images. Answered in object memory so that a caller frees nothing."

	| capabilities |
	capabilities := VkSurfaceCapabilitiesKHR externalInstance.
	^ [ capabilities supportedUsageFlags: VkImageUsage colorAttachmentBit.
	  capabilities copyIntoObjectMemory ] ensure: [ capabilities getHandle free ]
]
