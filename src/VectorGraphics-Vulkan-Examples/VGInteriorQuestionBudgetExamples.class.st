"
I hold the examples of VGInteriorQuestionBudget: what each stage of the interior question of a
tile binning costs, timed apart over the three frames of VGFrameDeviceBenchmark.

One click puts the questions a stage was asked beside the fastest pass of it, which is the pair of
numbers a lever against those milliseconds has to be chosen on. The counts behind the figures are
VGInteriorQuestionCensus's, whose examples VGInteriorQuestionCensusExamples holds.

No device is opened: an example here draws the frames on the processor and times loops over them.
"
Class {
	#name : 'VGInteriorQuestionBudgetExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Vulkan-Examples-Examples',
	#package : 'VectorGraphics-Vulkan-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGInteriorQuestionBudgetExamples class >> floorsOfTheStagesOfTheThreeFrames [
	<sampleInstance>
	"What each stage of the interior question costs, over every frame of the budget at the
	 extent they are drawn for. The Floors tab puts the questions a stage was asked beside the
	 fastest pass of it, so a reader divides one by the other and sees that the clip's bounding
	 rectangle answers a question in a tenth of a microsecond while the edges of a fill, the
	 fill rule at a centre and the shapes of a clip each take half of one or more.
	 Twenty passes over three frames, which takes a few seconds; no device is opened."
	^ VGInteriorQuestionBudget overTheThreeFrames
]
