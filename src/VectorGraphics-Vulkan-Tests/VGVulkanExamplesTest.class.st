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
		  VGTileBinningExamples.
		  VGTiledFillExamples.
		  VGVulkanBlurExamples.
		  VGVulkanDeviceSessionExamples.
		  VGFrameDeviceBenchmarkExamples.
		  VGFrameDrawingKitExamples.
		  VGFrameStageBenchmarkExamples.
		  VGKernelVisitCensusExamples }
]

{ #category : 'private' }
VGVulkanExamplesTest >> projectDefines: aCompiledMethod [
	"As my superclass, and the test packages of this project as well. The budget lives in
	 VectorGraphics-Vulkan-Tests, because measuring against Cairo means naming Alexandrie's
	 classes and a package the failover loads may name none, and its views are views an example
	 opens like any other. A test package of another project is still not ours to hold to these
	 rules, so the name is read at both ends."

	| package |
	package := aCompiledMethod package.
	^ (super projectDefines: aCompiledMethod) or: [
		  package notNil and: [
			  (package name beginsWith: 'VectorGraphics') and: [
				  package name endsWith: '-Tests' ] ] ]
]
