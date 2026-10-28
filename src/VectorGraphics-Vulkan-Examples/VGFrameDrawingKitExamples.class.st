"
I hold the examples of VGFrameDrawingKit: the two sets of four classes a frame of the budget can be
drawn with, this project's and Alexandrie's. One click shows which class of mine answers to which
class of theirs, which is the pairing the measurements of phase 3 rest on.
No device and no surface is opened by any example here.
"
Class {
	#name : 'VGFrameDrawingKitExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Vulkan-Examples-Examples',
	#package : 'VectorGraphics-Vulkan-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGFrameDrawingKitExamples class >> kitOfAlexandrie [
	<sampleInstance>
	"The same four classes on the Cairo side, which is what a frame of the budget is measured
	 against. Opening both kits side by side is how the pairing was checked when phase 3 began."

	^ VGFrameDrawingKit alexandrie
]

{ #category : 'examples' }
VGFrameDrawingKitExamples class >> kitOfThisProject [
	<sampleInstance>
	"The four classes a frame of the budget is drawn with on this project's own path. The Classes
	 tab names each of them with the class of Alexandrie's it answers to, read from the kit of the
	 other side rather than written down, so a kit that gained a class and a counterpart that did
	 not is visible as an empty cell."

	^ VGFrameDrawingKit ours
]
