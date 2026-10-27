"
I hold the examples of the whole frame measurement: a window sized frame measured on the device, the same frame measured against the software path, and the census of what the device can draw of the frame unit 1.11 profiles.

Each is one click from the browser and each rebuilds its object. The two benchmarks open a device, which costs tens of milliseconds, and the one that measures the software path draws an eight hundred by six hundred frame on the processor, which takes a second or two. The census opens no device at all.

See VGFrameDeviceBenchmark and VGTiledFillSupportCensus.
"
Class {
	#name : 'VGFrameDeviceBenchmarkExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Vulkan-Examples-Examples',
	#package : 'VectorGraphics-Vulkan-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGFrameDeviceBenchmarkExamples class >> backgroundFrameAgainstTheSoftwarePath [
	<sampleInstance>
	"The cheapest frame the device draws — one solid fill over the whole extent — measured on the
	 device and then on the software path, so that the Benchmark tab carries both numbers and the
	 factor between them. It also carries whether the two paths laid down the same bytes, which is
	 what makes the factor worth reading.
	 This one draws a whole frame on the processor, so it takes a second or two."

	^ VGFrameDeviceBenchmark onTheBackgroundFrame run measureSoftwareFrame
]

{ #category : 'examples' }
VGFrameDeviceBenchmarkExamples class >> cardsFrameOnThisMachine [
	<sampleInstance>
	"A window sized frame of twelve cards, each clipped to itself, filled with a gradient and
	 bordered, measured on the device of this machine. The Benchmark tab names the tiles the frame
	 touches, what the encoding and the SPIR-V cost off the device, and what the dispatch costs on
	 it; the Device frame tab shows the picture that came back.
	 The software side of the comparison is left out here, because a frame of this size on the
	 processor takes a second or two and this example is opened to see the device."

	^ VGFrameDeviceBenchmark onTheCardsFrame run
]

{ #category : 'examples' }
VGFrameDeviceBenchmarkExamples class >> referenceFrameOnThisMachine [
	<sampleInstance>
	"The frame unit 1.11 profiles, drawn whole on the device of this machine. Every one of its
	 eighty eight entries is glyph blits and shaped clips, so until unit 2.7 the device drew none
	 of it; it is the first real window frame the tiled path draws. The Benchmark tab names the
	 tiles it touches and what the dispatch costs, and the Device frame tab shows the picture that
	 came back."
	"The software side is left out, as it is on the cards frame: this frame on the processor takes
	 three and a half seconds and the example is opened to see the device."

	^ VGFrameDeviceBenchmark onTheReferenceFrame run
]

{ #category : 'examples' }
VGFrameDeviceBenchmarkExamples class >> supportOfTheReferenceFrame [
	<sampleInstance>
	"What the tiled rasteriser can and cannot draw of the frame unit 1.11 profiles, entry by
	 entry. The Reasons tab apportions the eighty eight entries of that frame and the pixels
	 behind each refusal, and the Entries tab lists them in the order they were drawn.
	 No device is opened: the frame is recorded on the software path and the entries are read."

	^ VGTiledFillSupportCensus onTheReferenceFrame
]
