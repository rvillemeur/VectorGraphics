"
I hold the examples of VGInteriorQuestionCensus: where the interior question of a tile binning
stops, counted over the three frames of VGFrameDeviceBenchmark at both extents.

One click shows which test of VGFillEntry >> coversEveryPixelOf: the questions of a frame are
paid in — the clip's bounds, the edges of the fill, the fill rule at a centre — which is what
decides where a lever against those 4.313 ms can go.

No device is opened: an example here draws a frame on the processor and counts.
"
Class {
	#name : 'VGInteriorQuestionCensusExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Vulkan-Examples-Examples',
	#package : 'VectorGraphics-Vulkan-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGInteriorQuestionCensusExamples class >> stagesOfTheThreeFrames [
	<sampleInstance>
	"Where the interior question stops, over every frame of the budget at both extents. The
	 Stages tab reads the stages from the predicate's own order, so a reader sees at once that a
	 third of the questions of the reference frame are refused by the clip's bounding rectangle,
	 which costs one rectangle test, while the edge test and the fill rule are paid for by far
	 fewer.
	 The six frames are drawn and the six grids walked here, which takes about a second; no
	 device is opened."
	^ VGInteriorQuestionCensus new
		  rows;
		  yourself
]
