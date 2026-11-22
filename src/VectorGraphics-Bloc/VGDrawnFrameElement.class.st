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

{ #category : 'constants' }
VGDrawnFrameElement class >> recordingExtent [
	"The extent of the throwaway surface frameReport records on. One pixel: the display list it
	 reads holds commands, so nothing of what is reported depends on this extent, and a larger
	 one would allocate a drawable for nothing."

	^ 1 @ 1
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
	 none of the clip the canvas prepared.
	 A surface that builds none of this project's contexts is refused here. My frame would
	 otherwise meet Alexandrie's own context, where a few selectors overlap by coincidence and
	 the rest fail deep inside Cairo marshalling, saying nothing about the cause."

	super aeDrawGeometryOn: aeCanvas.
	drawBlock ifNil: [ ^ self ].
	drawBlock value: (aeCanvas privateAeCairoSurface newVectorGraphicsContextOrNil
			 ifNil: [
				 self error:
					 'A frame of mine draws through a drawing context of this project, which only the surface of a VGCanvas builds.' ])
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

{ #category : 'reporting' }
VGDrawnFrameElement >> frameReport [
	"What my frame is made of, found by recording it rather than by describing it. The surface
	 recorded on is a throwaway one of one pixel: a display list holds the commands and not the
	 pixels, so the extent of the surface recorded on bounds nothing that is read here, and a
	 surface of my own extent would cost a drawable of memory and would answer nothing for an
	 element no space has laid out yet. The kinds are counted because what a frame is made of is
	 what decides which backend can draw it."

	| surface entries kinds |
	drawBlock ifNil: [ ^ { ('frame' -> 'none: I draw my background and my border only') } ].
	surface := VGCairoImageSurface extent: self class recordingExtent.
	drawBlock value: surface newContext.
	entries := surface displayList entries.
	kinds := (entries collect: [ :each | each class name asString ]) asBag.
	^ {
		  ('laid out at' -> self extent printString).
		  ('entries recorded' -> entries size printString).
		  ('kinds' -> ((kinds sortedCounts collect: [ :each |
				      each key printString , ' × ' , each value ]) inject: ''
			    into: [ :all :each |
			    all isEmpty
				    ifTrue: [ each ]
				    ifFalse: [ all , ', ' , each ] ])) }
]

{ #category : 'inspector' }
VGDrawnFrameElement >> inspectorFrame: aBuilder [
	"What the frame I hold records, read by recording it on a surface of my own extent. Reads
	 frameReport, so it cannot drift from what the block really draws, and touches neither me
	 nor the space I am in."

	<inspectorPresentationOrder: 10 title: 'Frame'>
	^ aBuilder newTable
		  addColumn:
			  (SpStringTableColumn title: 'Property' evaluated: [ :each | each key ]);
		  addColumn:
			  (SpStringTableColumn title: 'Value' evaluated: [ :each | each value ]);
		  items: self frameReport;
		  yourself
]

{ #category : 'inspector' }
VGDrawnFrameElement >> inspectorFrameContext: aContext [
	"Always: an element with no frame says so in its one row, which is the answer a reader of
	 this tab wants."

	aContext active: true
]
