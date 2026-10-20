"
I hold the examples of `VGFrameProfile`: a profile of a frame small enough to measure in a fraction of a second, and the scene a frame is made of. One click on either shows what unit 1.11 measured, with the stages, the two frame times and both frames as inspector tabs.

The reference profile — the one the plan's numbers come from — is `VGFrameProfile reference`, which takes seconds rather than a fraction of one, so it is not an example.
"
Class {
	#name : 'VGFrameProfileExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Bloc-Examples',
	#package : 'VectorGraphics-Bloc-Examples'
}

{ #category : 'constants' }
VGFrameProfileExamples class >> exampleExtent [
	"Small enough that drawing it through a software rasteriser is a click and not a wait."

	^ 120 @ 100
]

{ #category : 'examples' }
VGFrameProfileExamples class >> profileOfOneCard [
	<sampleInstance>
	"A frame of one card, measured and attributed. The frame is small because an example is a
	 click: the reference frame of the plan is a window, and a window takes seconds in a software
	 rasteriser."

	| profile |
	profile := VGFrameProfile new.
	profile
		extent: self exampleExtent;
		cards: 1;
		frames: 1.
	profile run.
	^ profile
]

{ #category : 'examples' }
VGFrameProfileExamples class >> sceneOfOneCard [
	<sampleInstance>
	"The element tree a profiled frame draws, laid out, with its text measured through this
	 project's renderer. Nothing is drawn, so this is the cheap half of the example above."

	| profile |
	profile := VGFrameProfile new.
	profile
		extent: self exampleExtent;
		cards: 1.
	^ profile sceneForRendererClass: VGRenderer
]
