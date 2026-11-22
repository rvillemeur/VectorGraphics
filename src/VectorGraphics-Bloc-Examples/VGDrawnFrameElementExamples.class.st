"
I hold the examples of the Bloc element that draws a frame of this project's drawing context.

`VGDrawnFrameElement` is what puts a frame written against a drawing context — a case of
`VGConformanceCorpus`, one of the three frames of `VGFrameDeviceBenchmark` — inside a Bloc space,
and a space is what the renderer of a window draws. One click answers such an element, laid out
and ready to be drawn; its `Frame` tab names what the frame records, which is what decides
whether a device can draw it.

See `VGDrawnFrameElement` and `VGVulkanPresentRendererTest`, which draws every case of the
corpus through one of these.
"
Class {
	#name : 'VGDrawnFrameElementExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Bloc-Examples',
	#package : 'VectorGraphics-Bloc-Examples'
}

{ #category : 'constants' }
VGDrawnFrameElementExamples class >> cardBorderWidth [
	^ 2
]

{ #category : 'examples' }
VGDrawnFrameElementExamples class >> drawCardOn: aContext [
	"A frame of three entries written against the drawing context: a filled background, a
	 filled card and the stroke of its border. It is written here rather than taken from the
	 benchmarks because this package stands below them in the layering, and three entries are
	 all the Frame tab of the element has to report."

	| box |
	aContext sourceColor: Color veryVeryLightGray.
	aContext rectangle: (0 @ 0 extent: self frameExtent).
	aContext fill.
	box := (self frameExtent / 4) asIntegerPoint extent:
		       (self frameExtent / 2) asIntegerPoint.
	aContext sourceColor: Color white.
	aContext rectangle: box.
	aContext fill.
	aContext sourceColor: Color gray.
	aContext strokeSize: self cardBorderWidth.
	aContext rectangle: box.
	aContext stroke
]

{ #category : 'examples' }
VGDrawnFrameElementExamples class >> elementDrawingACard [
	"One click: a card on its background as a Bloc element, which is what puts a frame written
	 against this project''s drawing context inside a Bloc space. Read the Frame tab: the entries
	 the frame records are what every backend of this project is asked to draw. The element is
	 laid out by the space it is put in, so the tab reports no extent for this one, which no
	 space holds and no window shows."

	<sampleInstance>
	| element |
	element := VGDrawnFrameElement drawing: [ :context | self drawCardOn: context ].
	element extent: self frameExtent.
	^ element
]

{ #category : 'constants' }
VGDrawnFrameElementExamples class >> frameExtent [
	"The extent of the element the example answers, and of the frame it draws."

	^ 120 @ 80
]
