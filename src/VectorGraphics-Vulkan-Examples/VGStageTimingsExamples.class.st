"
I hold the examples of `VGStageTimings`: what the passes of a benchmark read for each stage of a frame, with the phases of the host half under the encode they are inside of.

One click shows the table a report is printed from — a mean and a floor for each stage — without a report and without a device, since the host half of a frame asks for no driver.
"
Class {
	#name : 'VGStageTimingsExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Vulkan-Examples-Examples',
	#package : 'VectorGraphics-Vulkan-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGStageTimingsExamples class >> timingsOfTheHostHalfOfABudgetFrame [
	<sampleInstance>
	"The timings of the cheapest frame of the budget, measured on the host alone: the encode
	 over three passes with the eleven phases of the host half under it. The Stages tab names
	 each stage, the mean of its passes and the fastest of them, and a stage taken apart names
	 the timings it is made of.
	 No device is asked for anything: a display list, a binning and a buffer are all built on
	 the host. This takes a few tens of milliseconds."

	^ (VGFrameStageBenchmark onTheBackgroundFrame measureEncoding) timings
]
