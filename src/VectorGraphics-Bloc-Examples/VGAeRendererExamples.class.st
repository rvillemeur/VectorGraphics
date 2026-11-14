"
I hold the examples of `VGAeRenderer`, the host renderer Bloc chooses when the image draws
through Cairo and reads its fonts from this project.

One example answers a renderer prepared for a host space, and one answers a space holding text
that has been opened and drawn into a buffer of pixels with no window present. The second is the
route of unit 5.1 end to end: Cairo rasterised the frame, and the glyphs in it came from our own
scaled fonts.
"
Class {
	#name : 'VGAeRendererExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Bloc-Examples-Text',
	#package : 'VectorGraphics-Bloc-Examples',
	#tag : 'Text'
}

{ #category : 'examples' }
VGAeRendererExamples class >> rendererPreparedForAHostSpace [
	<sampleInstance>
	"A renderer as a host space holds it: one canvas for the frame and one text measurer for
	 layout, both of this route. Nothing is drawn yet, because a frame needs the pixels of a
	 window. The Renderer tab names the canvas and the measurer."

	| renderer |
	renderer := VGAeRenderer new.
	renderer initializeForHostSpace: (VGPixelBufferHostSpace new
			 windowExtent: 100 @ 100;
			 canvasExtent: 100 @ 100;
			 yourself).
	^ renderer
]

{ #category : 'examples' }
VGAeRendererExamples class >> spaceWithTextDrawnIntoAPixelBuffer [
	<sampleInstance>
	"A real Bloc space holding text, opened on a host with no window and drawn by this route:
	 Cairo rasterised every pixel and the glyphs came from our own scaled fonts. The Pixels tab
	 of the inspector shows the frame that was drawn.
	 The image's own choice of renderer and font manager are put back afterwards, because an
	 example must leave the image it ran in as it found it."

	| previousRenderer previousManager space element |
	previousRenderer := BlHostRenderer preferableClass.
	previousManager := (AeFontManager class slotNamed: #globalInstance) read:
		                   AeFontManager.
	space := BlSpace new
		         host: VGPixelBufferHost default;
		         yourself.
	space extent: 120 @ 90.
	element := BlTextElement new
		           text: 'Hello' asRopedText;
		           position: 20 @ 20;
		           yourself.
	space root addChild: element.
	[
	VGFontManager installGlobally.
	BlHostRenderer preferableClass: VGAeRenderer.
	VGAeOffscreen resetInstance.
	space show.
	space settleForDuration: 5 seconds.
	^ space hostSpace ] ensure: [
		space close.
		VGPixelBufferHost cleanUp.
		VGAeOffscreen resetInstance.
		BlHostRenderer preferableClass: previousRenderer.
		(AeFontManager class slotNamed: #globalInstance)
			write: previousManager
			to: AeFontManager ]
]
