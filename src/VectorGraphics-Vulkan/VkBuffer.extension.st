Extension { #name : 'VkBuffer' }

{ #category : '*VectorGraphics-Vulkan' }
VkBuffer >> mappingOrNil [
	"The host address I am mapped at, or nothing where I am not mapped. Asking does not map,
	 which is what lets a tool report the mapping a frame really holds; VkBuffer >> sessionPointer
	 is what makes one. The reader is ours and not PharoVulkan's, as the mapping rule is."

	^ mappedPointer
]

{ #category : '*VectorGraphics-Vulkan' }
VkBuffer >> readbackInto: aByteArray [
	"My bytes into that array, in one call of libc, through the mapping I keep for the session.
	 This is the device to host step that section 2.2 of the plan makes the known risk of the
	 whole phase: a frame that ends in host memory pays this copy, and unit 3.4 makes it a
	 request so that a frame which ends on the device pays nothing. See VkBuffer >> uploadBytes:
	 for why the method is ours and not PharoVulkan's."

	LibC memCopy: self sessionPointer to: aByteArray size: aByteArray size
]

{ #category : '*VectorGraphics-Vulkan' }
VkBuffer >> sessionPointer [
	"The host address of my memory, mapped on the first ask and kept until I am destroyed. One
	 frame of the tiled fill writes fourteen buffers and reads one back, so a mapping a call
	 would be thirty calls into the driver a frame for an address that never moves while a buffer
	 lives. My memory is host visible and coherent, which is what lets a write through a kept
	 pointer reach the device with no flush of a range, and freeing memory that is still mapped
	 unmaps it, so nothing is owed at destroy.
	 VkBuffer is PharoVulkan's and this method is ours, as VkBuffer >> uploadBytes: is: it is our
	 measurement that a frame cannot afford the mapping. Anything that unmaps me leaves me with
	 no pointer, and the next ask maps again."

	^ mappedPointer ifNil: [ self map ]
]

{ #category : '*VectorGraphics-Vulkan' }
VkBuffer >> uploadBits: aBitsObject byteCount: aCount [
	"That many bytes of the object's own memory into my mapped block, in one call of libc. The
	 words of a WordArray and the floats of a Float32Array lie in object memory in the order and
	 the width a storage buffer reads them, so a caller needs no run of bytes packed between its
	 array and me. The count is checked before the pointer is touched: the bytes go out through a
	 raw pointer, so a count larger than my own would land outside my memory rather than fail."

	(self fitsByteCount: aCount) ifFalse: [
		SizeMismatch signal: aCount printString
			, ' bytes do not fit a buffer of ' , size printString , ' bytes' ].
	LibC memCopy: aBitsObject to: self sessionPointer size: aCount
]

{ #category : '*VectorGraphics-Vulkan' }
VkBuffer >> uploadBytes: aByteArray [
	"Those bytes into my mapped block, in one call of libc. VkBuffer is PharoVulkan's and this
	 method is ours, because it is our measurement that it is needed: copyFromByteArray: writes
	 the bytes one at a time from Smalltalk, which cost 31 ms of every frame unit 2.1 measured.
	 Three classes of ours uploaded a block before this method existed, each with its own copy of
	 the two lines. A run of bytes is a bits object like any other, so the one copy and the one
	 mapping rule are VkBuffer >> uploadBits:byteCount:'s."

	^ self uploadBits: aByteArray byteCount: aByteArray size
]
