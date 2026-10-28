Extension { #name : 'VkCommandBuffer' }

{ #category : '*VectorGraphics-Vulkan' }
VkCommandBuffer class >> computeToComputeBarrier [
	"The barrier a recording needs between two compute dispatches of one command buffer: what the
	 first wrote through a storage buffer becomes visible to the read of the second. Dispatches in
	 one command buffer are not ordered against each other without it. The caller owns the block
	 and must free its handle, which is how this class's own hostReadBarrier answers one. The
	 extension lives in this project because the batching rule is this project's; the bits it
	 names are extensions of PharoVulkan's constant classes for the same reason."
	| barrier |
	barrier := VkMemoryBarrier2 externalInstance.
	^ barrier
		  srcStageMask: VkPipelineStage2 computeShaderBit;
		  srcAccessMask: VkAccess2 shaderWriteBit;
		  dstStageMask: VkPipelineStage2 computeShaderBit;
		  dstAccessMask: VkAccess2 shaderReadBit;
		  yourself
]

{ #category : '*VectorGraphics-Vulkan' }
VkCommandBuffer >> recordComputeToComputeBarrier [
	"Records the compute to compute barrier, freeing the block once the driver has read it, which
	 is how barrierForHostRead records its own. The extension lives in this project because the
	 batching of a blur's passes into one submission is this project's rule."
	| barrier |
	barrier := self class computeToComputeBarrier.
	[ self recordBarrier: barrier ] ensure: [ barrier getHandle free ]
]
