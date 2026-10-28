Extension { #name : 'PVComputeKernel' }

{ #category : '*VectorGraphics-Vulkan' }
PVComputeKernel >> rebindBuffer: aBuffer atBinding: anIndex [
	"PVComputeKernel is PharoVulkan's, and it binds its buffers once, in prepare. Unit 3.1 keeps
	 a prepared kernel for the whole image session and grows a buffer when a frame needs a larger
	 one, which asks the descriptor set to point at the new buffer without the pipeline being
	 built again. The extension lives here rather than upstream because the growth rule is this
	 project's and the set is already written by prepare in exactly this way."

	buffers at: anIndex + 1 put: aBuffer.
	descriptorSet updateStorageBuffer: aBuffer atBinding: anIndex
]

{ #category : '*VectorGraphics-Vulkan' }
PVComputeKernel >> recordComputeInto: aCommandBuffer groupsAcross: x down: y layers: z [
	"My pipeline, my set and one dispatch of that grid recorded into a command buffer somebody else
	 owns, which is what lets several kernels share one submission. PVComputeKernel is
	 PharoVulkan's and its own dispatch:y:z: allocates a command buffer, submits it and waits, so
	 a blur of six passes paid six submissions and about 0.43 ms of host time each. The extension
	 lives here rather than upstream because batching is this project's rule and the recording is
	 exactly what that method already records."
	aCommandBuffer bindComputePipeline: pipeline.
	aCommandBuffer
		bindDescriptorSets: (Array with: descriptorSet)
		pipelineLayout: pipelineLayout.
	aCommandBuffer dispatch: x y: y z: z
]
