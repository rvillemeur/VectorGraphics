"
I hold the examples of VGPresentPathBenchmark, the measurement of unit 7.6: the path that ends on the device against the path that ends in the host's own pixels. My examples run a short benchmark rather than the verdict one — three rounds of forty draws a path at two extents takes minutes, and an example is opened to see the shape of a report, not to publish a number. The verdict run is VGPresentPathBenchmark class >> onTheThreeFrames, started by hand.
"
Class {
	#name : 'VGPresentPathBenchmarkExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Vulkan-Examples-Examples',
	#package : 'VectorGraphics-Vulkan-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGPresentPathBenchmarkExamples class >> onTheThreeFramesOnThisMachine [
	<sampleInstance>
	"The three benchmark frames measured on both paths at both extents, one round of three timed
	 draws a path. The Verdict tab reads one row a frame an extent, with the fastest draw of each
	 path and the factor between them; the Draws tab reads every comparison of the run, and a
	 comparison opened from it shows what one draw of that path is made of.
	 The counts are small on purpose: the verdict run is three rounds of forty draws a path and
	 takes minutes, which is a thing to start by hand and not to open from a browser."
	^ (VGPresentPathBenchmark rounds: 1 timedDraws: 3) run
]
