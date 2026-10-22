"
I hold the examples of the Vulkan backend to the same five rules as the examples of the engine:
every holder carries a comment, every example rebuilds its object, every example runs and answers
something, every view has a gate and every view builds and fills its cells.
I inherit all five from VGCairoExamplesTest and only name the holders of this package, which is why
I define no test of my own.
"
Class {
	#name : 'VGVulkanExamplesTest',
	#superclass : 'VGCairoExamplesTest',
	#category : 'VectorGraphics-Vulkan-Tests-Tests',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Tests'
}

{ #category : 'accessing' }
VGVulkanExamplesTest >> exampleHolders [
	^ {
		  VGVulkanBackendExamples.
		  VGVulkanRoundTripExamples.
		  VGTileBinningExamples }
]
