Extension { #name : 'VkAccess2' }

{ #category : '*VectorGraphics-Vulkan' }
VkAccess2 class >> shaderReadBit [
	"VK_ACCESS_2_SHADER_READ_BIT, bit 5, which covers a storage buffer read by a compute shader.
	 See shaderWriteBit for why the wider bit and not the storage one, and why the extension is
	 here."
	^ 32
]

{ #category : '*VectorGraphics-Vulkan' }
VkAccess2 class >> shaderWriteBit [
	"VK_ACCESS_2_SHADER_WRITE_BIT, bit 6, which covers a storage buffer written by a compute
	 shader. The wider bit is used rather than VK_ACCESS_2_SHADER_STORAGE_WRITE_BIT because that
	 one is bit 33 and a 64-bit literal, and this one is the superset Vulkan defines for it. The
	 extension lives in this project because PharoVulkan names only the bits it records itself."
	^ 64
]
