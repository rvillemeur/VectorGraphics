Extension { #name : 'VkBuffer' }

{ #category : '*VectorGraphics-Vulkan' }
VkBuffer >> readbackInto: aByteArray [
	"My bytes into that array, in one call of libc. This is the device to host step that section 2.2
	 of the plan makes the known risk of the whole phase: a frame ends in host memory, so every
	 frame pays this copy. See VkBuffer >> uploadBytes: for why the method is ours and not
	 PharoVulkan's."

	| pointer |
	pointer := self map.
	[ LibC memCopy: pointer to: aByteArray size: aByteArray size ] ensure: [
		self unmap ]
]

{ #category : '*VectorGraphics-Vulkan' }
VkBuffer >> uploadBytes: aByteArray [
	"Those bytes into my mapped block, in one call of libc. VkBuffer is PharoVulkan's and this
	 method is ours, because it is our measurement that it is needed: copyFromByteArray: writes the
	 bytes one at a time from Smalltalk, which cost 31 ms of every frame unit 2.1 measured. Three
	 classes of ours uploaded a block before this method existed, each with its own copy of the two
	 lines."

	| pointer |
	pointer := self map.
	[ LibC memCopy: aByteArray to: pointer size: aByteArray size ] ensure: [
		self unmap ]
]
