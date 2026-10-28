"
I hold the examples of VGKernelVisitCensus: the reads the tiled fill kernel makes of an encoding,
counted against the reads the work really needs.
One click shows the repetition the kernel is built on — every column of a tile sweeping the same
sub-rows, every invocation of a tile reading the same records — which is what the units after this
one remove.
No device is opened: an example here encodes a frame on the processor and counts.
"
Class {
	#name : 'VGKernelVisitCensusExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Vulkan-Examples-Examples',
	#package : 'VectorGraphics-Vulkan-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGKernelVisitCensusExamples class >> visitsOfOneFillOverSixteenTiles [
	<sampleInstance>
	"The smallest census worth reading: one fill over a 64 by 64 surface, which is sixteen tiles
	 and every one of them interior to the fill. An interior reference is visited and read and
	 never swept, so the Counts tab shows no edge read at all beside 8192 record reads — the
	 repetition unit 3.2 removes, with none of the repetition unit 3.3 removes to hide it.
	 The fill reaches ten pixels past each side of the frame, because a tile the border of a fill
	 runs through is not interior to it and the whole outer ring would otherwise be swept."

	| surface |
	surface := VGCairoImageSurface extent: 64 @ 64.
	surface newContext
		sourceColor: Color blue;
		rectangleX: -10 y: -10 width: 84 height: 84;
		fill.
	^ VGKernelVisitCensus of:
		  (VGTiledFillEncoding of: surface displayList extent: 64 @ 64)
]

{ #category : 'examples' }
VGKernelVisitCensusExamples class >> visitsOfTheReferenceFrame [
	<sampleInstance>
	"What the kernel reads to draw the frame unit 1.11 profiles: the tiles, the references, the
	 edge reads and the record reads, each beside the number the work really needs. The Counts tab
	 carries the ratios too, and each of them is a property of the kernel — the width of a tile for
	 the sweeps, the invocations of a tile for the records — so the tab names where the dispatch of
	 that frame spends its time.
	 The frame is encoded on the processor, which takes a moment; no device is opened."

	^ VGKernelVisitCensus of:
		  (VGFrameDeviceBenchmark onTheReferenceFrame measureEncoding encoding)
]
