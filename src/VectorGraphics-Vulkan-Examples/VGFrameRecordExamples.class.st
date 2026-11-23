"
I hold the examples of unit 3.13: what a frame's recording counts, and what that recording costs against Cairo's whole frame. Each is one click from the browser and each rebuilds its object, so a change to the recording path shows up the next time an example is opened. `censusOfTheThreeFrames` draws six frames on the software path and takes a second or two; `recordComparisonOfTheReferenceVariants` draws four hundred and takes tens of seconds, which is the price of floors over twenty interleaved passes. Neither opens a device: the question of the unit is whether the host half of a frame already costs more than Cairo's whole frame, and a machine with no driver can answer it. See `VGFrameRecordCensus` and `VGFrameRecordComparison`.
"
Class {
	#name : 'VGFrameRecordExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Vulkan-Examples-Examples',
	#package : 'VectorGraphics-Vulkan-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGFrameRecordExamples class >> censusOfTheThreeFrames [
	<sampleInstance>
	"What the three frames of the budget record, at both extents they are measured at: the
	 entries by kind, the edges and coordinates the fills carry, the mask surfaces the blits
	 carry and how many of them are distinct, and the paints and clips built for them. The Rows
	 tab holds one line per frame and extent; the Census tab reads the busiest of them.
	 Nothing is timed here. The clock of the same question is
	 VGFrameRecordComparison overTheReferenceVariants."
	^ VGFrameRecordCensus overItsFrames
]
