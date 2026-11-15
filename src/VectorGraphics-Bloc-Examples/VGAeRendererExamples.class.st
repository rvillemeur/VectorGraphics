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
VGAeRendererExamples class >> openWindowWithTextDrawnByCairo [
	"The deliverable of unit 5.3: a real window of this machine, every pixel of it rasterised by
	 Cairo, with the glyphs read and scaled by this project and no FreeType face anywhere in the
	 route. Click it and read the two lines; close the window and the image is as it was.
	 The window has to outlive this method, so the renderer and the font manager cannot be put
	 back in an `ensure:`: a frame resolves its faces through `AeFontManager globalInstance`
	 again on every repaint. They are put back when the window closes instead.
	 The font directory Pharo ships is scanned on top of the manager's default faces, because
	 that is where Cascadia Code is, which the scene names."

	<sampleInstance>
	| previousRenderer previousManager space |
	previousRenderer := BlHostRenderer preferableClass.
	previousManager := VGFontManager managerUpstreamHolds.
	VGFontManager installGlobally.
	AeFontManager globalInstance scanDirectory:
		AeFilesystemResources fontsDirectory.
	BlHostRenderer preferableClass: VGAeRenderer.
	VGAeOffscreen resetInstance.
	space := BlSpace new.
	space extent: 320 @ 160.
	space title: 'Text drawn by Cairo, fonts of ours'.
	space root addChild: self textSceneInTwoSizes.
	space addEventHandlerOn: BlSpaceClosedEvent doOnce: [ :event |
		BlHostRenderer preferableClass: previousRenderer.
		VGFontManager restoreUpstreamManager: previousManager.
		VGAeOffscreen resetInstance ].
	space show.
	^ space
]

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
	previousManager := VGFontManager managerUpstreamHolds.
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
		VGFontManager restoreUpstreamManager: previousManager ]
]

{ #category : 'examples' }
VGAeRendererExamples class >> textSceneInTwoSizes [
	"The scene the window example of this route shows: one line of text in two sizes, on a
	 background that makes the compositing visible. The family is named rather than left to the
	 default face, so that what a reader sees is the font the catalogue found on the disk; Pharo
	 bundles Cascadia Code, so the name holds in any image of it.
	 The sister route has a scene of its own. The two are the same today and are kept apart on
	 purpose: each example reads on its own, and two occurrences are not yet a rule."

	<sampleInstance>
	| scene |
	scene := BlElement new
		         extent: 320 @ 160;
		         background: (Color gray: 0.95);
		         yourself.
	#( 12 36 ) doWithIndex: [ :size :index |
		| text |
		text := 'Drawn with our own fonts' asRopedText.
		text
			fontName: 'Cascadia Code';
			fontSize: size.
		scene addChild: (BlTextElement new
				 text: text;
				 position: 20 @ (20 + (index - 1 * 60));
				 yourself) ].
	^ scene
]
