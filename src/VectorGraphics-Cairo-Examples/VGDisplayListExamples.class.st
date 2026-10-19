"
I hold the one-click examples for the retained display list and the software backend behind it.

My examples rebuild their object on every call and assert nothing. They show the first rule of the plan at work: a context records entries and rasterises nothing, so the pictures appear only when the list is drained into the surface.
"
Class {
	#name : 'VGDisplayListExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Cairo-Examples-Examples',
	#package : 'VectorGraphics-Cairo-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGDisplayListExamples class >> backendHoldingAFrame [
	<sampleInstance>
	"The software backend after a frame has been replayed on to it and before it drains: the
	 commands it holds are what a Vulkan backend would turn into draw calls instead."

	| backend |
	backend := VGSoftwareBackend new.
	self recordedFrame replayOn: backend.
	^ backend
]

{ #category : 'examples' }
VGDisplayListExamples class >> fillEntryOfAStar [
	<sampleInstance>
	"One entry of a frame on its own: the edges, the paint, the clip and the operator the backend
	 will be handed."

	^ VGFillEntry
		  segments: (VGPathExamples starPath segmentsWithFillRule: #winding)
		  paint: Color black
		  clip: (0 @ 0 corner: 64 @ 64)
		  operator: #over
]

{ #category : 'examples' }
VGDisplayListExamples class >> recordedFrame [
	<sampleInstance>
	"Two fills and a stroke recorded on a surface and not yet drained, so the list still holds the
	 whole frame and no pixel of the surface has been touched."

	| surface context |
	surface := VGCairoImageSurface extent: 64 @ 64.
	context := surface newContext.
	context
		rectangleX: 8 y: 8 width: 20 height: 20;
		fill;
		circleCenterX: 44 y: 44 radius: 14;
		fill;
		moveTo: 4 @ 60;
		lineTo: 60 @ 4;
		stroke.
	^ surface displayList
]
