"
I hold the examples of VGVulkanRoundTrip: the measurement that decides whether a frame is worth
sending to a Vulkan device at all.
One click measures this machine — the bytes out, a trivial coverage fill, the bytes back, and the
same frame drawn on the software path — and answers the round trip with its verdict in the Budget
tab.
A machine with no device answers the reason instead, which is a result and not a failure.
"
Class {
	#name : 'VGVulkanRoundTripExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Vulkan-Examples-Examples',
	#package : 'VectorGraphics-Vulkan-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGVulkanRoundTripExamples class >> coverageKernel [
	<sampleInstance>
	"One click: the kernel whose dispatch is the fill rate of the gate, with its local size, its
	 parameters and the size of the module the DSL compiles it into. A class is its own single
	 instance, so this answers the class itself."

	^ VGVulkanCoverageKernel
]

{ #category : 'examples' }
VGVulkanRoundTripExamples class >> roundTripOnThisMachine [
	<sampleInstance>
	"One click: both sides of the gate of unit 2.1 measured on this machine. The three device
	 numbers are each averaged over the repeats with a warm-up pass thrown away, and the software
	 frame is the reference frame of unit 1.11 drawn on the pure Pharo path, so the comparison is
	 two measurements of one picture in one session. Opening a device costs a second or two, and a
	 machine with no device answers the reason it has none."

	^ VGVulkanRoundTrip reference runGate
]
