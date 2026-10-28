Extension { #name : 'VkPipelineStage2' }

{ #category : '*VectorGraphics-Vulkan' }
VkPipelineStage2 class >> computeShaderBit [
	"VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT, bit 11. PharoVulkan's own constant class names only
	 the bits that project records, and this project records a compute to compute dependency, which
	 it does not. The extension lives here rather than upstream for that reason; a mask carrying it
	 shows as hex in that class's Barrier tab, which is what namedBits says of any bit it does not
	 name."
	^ 2048
]
