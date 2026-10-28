"
I hold the examples of VGFrameStageBenchmark: a frame of the budget measured stage by stage on the
device of this machine, with the Cairo figure for the same picture measured beside it.
One click shows where the milliseconds of a frame go and how far they are from Cairo, which is the
question phase 3 opens with.
An example here opens a device and draws several frames, so it takes a second or two.
"
Class {
	#name : 'VGFrameStageBenchmarkExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Vulkan-Examples-Examples',
	#package : 'VectorGraphics-Vulkan-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGFrameStageBenchmarkExamples class >> stagesOfTheBackgroundFrame [
	<sampleInstance>
	"The cheapest frame the device draws — one solid fill over the whole extent — measured stage
	 by stage, with the same picture drawn by Cairo beside it. The Benchmark tab names each stage
	 of the dispatch and what it cost, then the Cairo figure, so the gap between the two paths is
	 read as a sum of parts rather than as one number; the Cairo frame tab shows the picture Cairo
	 drew and the Device frame tab the picture the device drew.
	 This opens a device and draws several frames, so it takes a second or two."

	^ VGFrameStageBenchmark onTheBackgroundFrame run
]
