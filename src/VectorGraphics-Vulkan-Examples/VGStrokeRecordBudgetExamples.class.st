"
I hold the examples of VGStrokeRecordBudget: the readings unit 3.15 chooses its lever on.
Running one takes seconds and opens no device.
"
Class {
	#name : 'VGStrokeRecordBudgetExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Vulkan-Examples-Examples',
	#package : 'VectorGraphics-Vulkan-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGStrokeRecordBudgetExamples class >> floorsOfThePartsOfTheThreeStrokes [
	<sampleInstance>
	"What each part of a stroke recording costs, over one card border, over the twelve of a
	 whole reference frame, and over a straight line. The Floors tab puts the edge count of a
	 subject beside the floor of every loop timed over it, so a reader sees which part of the
	 recording the frame pays for and what the empty loop around it costs.
	 Forty passes over three subjects, which takes seconds; no device is opened."

	^ VGStrokeRecordBudget overTheThreeSubjects
]
