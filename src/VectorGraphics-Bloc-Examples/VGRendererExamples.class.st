"
I hold the examples of `VGRenderer`, the host renderer Bloc chooses when this project is
the backend of the image.
One example answers a renderer prepared for a host space, one answers a space that has been
opened and drawn into a buffer of pixels with no window present, and one answers the form of
an element drawn through the same canvas.

"
Class {
	#name : 'VGRendererExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Bloc-Examples',
	#package : 'VectorGraphics-Bloc-Examples'
}

{ #category : 'examples - exporters' }
VGRendererExamples class >> formExportedThroughTheExporter [
	"The `Form` of an element drawn through the exporter hierarchy of `Bloc-Alexandrie`, whose one
	 backend method, `newCanvas:`, this project overrides. The element is laid out off the scene
	 graph, so the exporter lays it out itself."

	<sampleInstance>
	| element |
	element := BlElement new
		           extent: 30 @ 20;
		           background: Color green;
		           yourself.
	^ VGFormExporter new
		  element: element;
		  export
]

{ #category : 'examples - exporters' }
VGRendererExamples class >> formExporterForAnElement [
	"The exporter itself, with an element set and nothing exported yet, so its inspector can say
	 which canvas class it would build."

	<sampleInstance>
	^ VGFormExporter new
		  element: (BlElement new
				   extent: 30 @ 20;
				   background: Color green;
				   yourself);
		  yourself
]

{ #category : 'examples' }
VGRendererExamples class >> formOfADrawnElement [
	"The form Bloc answers for one element, drawn through our canvas. `BlElement >> aeAsForm`
	 names `AeCanvas` and is reached by no seam, so the renderer answers this through
	 `VGCanvas class >> formOfElement:`, which is derived from it."

	<sampleInstance>
	| element |
	element := BlElement new.
	element
		extent: 40 @ 20;
		background: Color blue.
	^ VGRenderer newFormFrom: element
]

{ #category : 'examples' }
VGRendererExamples class >> offscreenTextMeasurer [
	<sampleInstance>
	"The offscreen a renderer measures text with before a window exists, with its own canvas of
	 one pixel. `BAOffscreen` builds that canvas by naming `AeCanvas`, which is the only backend
	 decision in it."

	^ VGOffscreen new
		  ensureReady;
		  yourself
]

{ #category : 'examples - exporters' }
VGRendererExamples class >> pngExporterForAnElement [
	"The PNG exporter itself, with an element and a target in an in-memory file system, so the
	 example writes nothing to disk and its inspector can say which canvas class it would build."

	<sampleInstance>
	^ VGPngExporter new
		  element: (BlElement new
				   extent: 30 @ 20;
				   background: Color blue;
				   yourself);
		  target: FileSystem memory root / 'example.png';
		  yourself
]

{ #category : 'examples' }
VGRendererExamples class >> pngOfADrawnElement [
	"The bytes of the PNG Bloc writes for one element, drawn through our canvas by
	 `VGPngExporter`. The file is written into a memory file system, because an example is run by
	 a click in the browser and should leave nothing behind."

	<sampleInstance>
	| element file |
	element := BlElement new.
	element
		extent: 40 @ 20;
		background: Color blue.
	file := FileSystem memory root / 'element.png'.
	VGRenderer write: element asPngTo: file.
	^ file binaryReadStream upToEnd
]

{ #category : 'examples' }
VGRendererExamples class >> rendererPreparedForAHostSpace [
	<sampleInstance>
	"A renderer as a host space holds it: one canvas for the frame and one text measurer for
	 layout, both ours. Nothing is drawn yet, because a frame needs the pixels of a window."

	| renderer |
	renderer := VGRenderer new.
	renderer initializeForHostSpace: (VGPixelBufferHostSpace new
			 windowExtent: 100 @ 100;
			 canvasExtent: 100 @ 100;
			 yourself).
	^ renderer
]

{ #category : 'examples' }
VGRendererExamples class >> spaceDrawnIntoAPixelBuffer [
	"A real Bloc space, opened on a host with no window and drawn by this project's renderer into
	 a buffer of pixels. The Pixels tab of the inspector shows the frame that was drawn.
	 The image's own choice of renderer is put back afterwards, because an example must leave the
	 image it ran in as it found it."

	<sampleInstance>
	| previous space element |
	previous := BlHostRenderer preferableClass.
	space := BlSpace new
		         host: VGPixelBufferHost default;
		         yourself.
	space extent: 120 @ 90.
	element := BlElement new.
	element
		extent: 60 @ 40;
		background: Color red;
		position: 20 @ 20.
	space root addChild: element.
	[
		BlHostRenderer preferableClass: VGRenderer.
		space show.
		space settleForDuration: 5 seconds.
		^ space hostSpace ] ensure: [
			space close.
			VGPixelBufferHost cleanUp.
			BlHostRenderer preferableClass: previous ]
]
