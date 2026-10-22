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
VGDisplayListExamples class >> blitEntryOfAMask [
	<sampleInstance>
	"One entry of a frame that paints through a mask rather than over a shape: the mask surface and
	 where it sits, the paint it lets through, the clip and the operator the backend will be
	 handed. The operator is the object and not its name, because an entry asks it whether it is
	 unbounded to know what it can touch."
	^ VGBlitEntry
		  surface: self surfaceMaskOfATile surface
		  at: 8 @ 8
		  paint: Color red
		  clip: (VGClip bounds: (0 @ 0 corner: 64 @ 64))
		  operator: VGCairoOperator over
]

{ #category : 'examples' }
VGDisplayListExamples class >> fillEntryOfAStar [
	<sampleInstance>
	"One entry of a frame on its own: the edges, the paint, the clip and the operator the backend
	 will be handed. The clip of a whole surface is a rectangle of a clip, which keeps no shape.
	 The operator is the object a recorded frame carries and not a symbol naming it: the entry asks
	 it whether it is unbounded when it answers its bounding box."

	^ VGFillEntry
		  segments: (VGPathExamples starPath segmentsWithFillRule: #winding)
		  paint: Color black
		  clip: (VGClip bounds: (0 @ 0 corner: 64 @ 64))
		  operator: VGCairoOperator over
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

{ #category : 'examples' }
VGDisplayListExamples class >> surfaceMaskOfATile [
	<sampleInstance>
	"A mask the backend can read: a little surface whose left half is opaque and whose right half
	 carries half an alpha, sitting at a point of the target. Painting through it paints the source
	 whole on one side, half on the other, and not at all beyond the tile, which is Cairo's extend
	 mode of none."
	| tile context |
	tile := VGCairoImageSurface
		        newFormat: VGCairoSurfaceFormat argb32
		        extent: 16 @ 16.
	context := tile newContext.
	context sourceColorR: 1.0 g: 1.0 b: 1.0 a: 1.0.
	context rectangleX: 0 y: 0 width: 8 height: 16.
	context fill.
	context sourceColorR: 1.0 g: 1.0 b: 1.0 a: 0.5.
	context rectangleX: 8 y: 0 width: 8 height: 16.
	context fill.
	tile flush.
	^ VGCairoSurfaceMask surface: tile at: 8 @ 8
]
