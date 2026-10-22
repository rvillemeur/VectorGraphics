"
I hold the trivial coverage shader unit 2.1 measures the fill rate with: one invocation per pixel,
writing full coverage, which is the cheapest kernel that still touches every pixel of the frame.
It is a `<gpu>` method compiled by the PharoVulkan DSL, and it lives here rather than among
PharoVulkan's own kernel examples because it belongs to this project's measurement and not to
theirs.
"
Class {
	#name : 'VGVulkanCoverageKernel',
	#superclass : 'Object',
	#category : 'VectorGraphics-Vulkan-Budget',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Budget'
}

{ #category : 'inspector' }
VGVulkanCoverageKernel class >> inspectorKernel: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Kernel'>
	"What the measured dispatch really is: the local size the annotation declares, the parameters
	 it binds and the size of the module the DSL compiles the method into. Every row is read from
	 the method itself, by compiling it, so the tab cannot drift from the kernel it describes.
	 Compiling opens no device."

	| method annotation rows |
	method := VGVulkanRoundTrip coverageKernelMethod.
	annotation := PVTypeAnnotation fromMethod: method.
	rows := OrderedCollection new.
	rows add: 'selector' -> method selector.
	rows add: 'local size' -> annotation localSize.
	annotation params do: [ :each |
		rows add: 'parameter ' , each name -> each type ].
	rows add: 'SPIR-V bytes' -> (PVKernelCompiler compile: method) size.
	^ aBuilder newTable
		  items: rows asArray;
		  addColumn:
			  (SpStringTableColumn title: 'Part' evaluated: [ :each | each key ]);
		  addColumn: (SpStringTableColumn
				   title: 'Value'
				   evaluated: [ :each | each value printString ]);
		  yourself
]

{ #category : 'inspector' }
VGVulkanCoverageKernel class >> inspectorKernelContext: aContext [
	"Only the class that really holds the measured kernel describes it."

	aContext active:
		(self includesSelector: VGVulkanRoundTrip coverageKernelMethod selector)
]

{ #category : 'kernels' }
VGVulkanCoverageKernel >> coverageOf: wi out: output [
	"Full coverage for every pixel of the frame. The cheapest kernel that still writes one value
	 per pixel, so the number it yields is the fill rate of the write and not of any arithmetic."
	<gpu>
	<param: #workItem named: #wi>
	<param: #bufferOf_f32 named: #output>

	output at: wi x put: 1.0
]
