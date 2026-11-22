"
I am a Bloc element whose painting is a frame of this project's own drawing context: I hold a one
argument block, and I send it the context of the canvas I am drawn on after my geometry, my
background and my border have been drawn.

I exist because a frame written against a drawing context — a case of VGConformanceCorpus, a frame
of VGFrameDeviceBenchmark — has no other way into a Bloc space, and a space is what a window's
renderer draws. An image background would reach a window too, but as one blit of pixels already
drawn, which measures and proves nothing about the path that draws the frame.

The block draws inside a saved context, so nothing it sets reaches the elements drawn after me.
See VGDrawnFrameElementExamples and VGVulkanPresentRendererTest.
"
Class {
	#name : 'VGDrawnFrameElement',
	#superclass : 'BlElement',
	#instVars : [
		'drawBlock'
	],
	#category : 'VectorGraphics-Bloc-Elements',
	#package : 'VectorGraphics-Bloc',
	#tag : 'Elements'
}

{ #category : 'instance creation' }
VGDrawnFrameElement class >> drawing: aBlock [
	"An element that draws that one argument block on the context of the canvas it is drawn on."

	^ self new
		  drawBlock: aBlock;
		  yourself
]

{ #category : 'drawing' }
VGDrawnFrameElement >> aeDrawGeometryOn: aeCanvas [
	"My geometry, my background and my border as any element draws them, and then my frame on a
	 context of my own over the surface of the canvas. The context is a fresh one rather than
	 the canvas's: a frame written against a drawing context expects the source, the operator,
	 the line options and the matrix a new context starts with, and a canvas that has drawn an
	 element before me leaves its own there — so the same frame would draw one picture on a
	 fresh surface and another one here. The surface is shared, so the frame is recorded in the
	 same display list as everything else of the space, in the order the elements are drawn.
	 Nothing of mine reaches the canvas's own state either, which is why no save is needed.
	 A frame larger than my extent is not clipped to me, because a context of its own carries
	 none of the clip the canvas prepared."

	super aeDrawGeometryOn: aeCanvas.
	drawBlock ifNil: [ ^ self ].
	drawBlock value: aeCanvas privateAeCairoSurface newContext
]

{ #category : 'accessing' }
VGDrawnFrameElement >> drawBlock [
	"The frame I draw, as a one argument block taking a drawing context. An element with none
	 draws its background and its border and nothing else."

	^ drawBlock
]

{ #category : 'accessing' }
VGDrawnFrameElement >> drawBlock: aBlock [
	drawBlock := aBlock
]
