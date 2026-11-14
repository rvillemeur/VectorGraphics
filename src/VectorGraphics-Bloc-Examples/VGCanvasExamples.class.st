"
I hold the examples of `VGCanvas`, the canvas Bloc draws every element through when this
project is the chosen backend.
One example per creation seam: the surface, a gradient source, the blurred alpha surface of
a shadow, and a scaled font for the face the font manager answers.
One click opens an inspector on the object Bloc itself would be handed.

"
Class {
	#name : 'VGCanvasExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Bloc-Examples',
	#package : 'VectorGraphics-Bloc-Examples'
}

{ #category : 'examples' }
VGCanvasExamples class >> blurredShadowAlphaSurface [
	<sampleInstance>
	"The alpha surface a drop shadow is drawn into and then blurred in. Bloc asks the canvas for
	 it, draws the silhouette into the canvas it is handed, and uses the result as a mask."

	^ self canvasOnASmallSurface
		  newSurfaceWithGaussianShadow: 40 @ 40
		  width: 4
		  canvasDo: [ :alphaCanvas |
			  alphaCanvas
				  pathFactory: [ :context |
					  context rectangleX: 10 y: 10 width: 20 height: 20 ];
				  setBackgroundWith: [ alphaCanvas setSourceColor: Color black ];
				  setBorderOff;
				  drawFigureAndPrepareToClip: false ]
]

{ #category : 'examples' }
VGCanvasExamples class >> canvasFilledWithALinearGradient [
	<sampleInstance>
	"A canvas whose surface holds one rectangle filled through the linear gradient seam, which is
	 the one Bloc uses for every gradient background."

	| canvas |
	canvas := self canvasOnASmallSurface.
	canvas
		pathFactory: [ :context | context rectangleX: 0 y: 0 width: 40 height: 40 ];
		setBackgroundWith: [
			canvas
				setSourceLinearPatternStops: {
						(0 -> Color red).
						(1 -> Color blue) }
				start: 0 @ 0
				end: 40 @ 0 ];
		setBorderOff;
		drawFigureAndPrepareToClip: false.
	^ canvas
]

{ #category : 'examples' }
VGCanvasExamples class >> canvasOnASmallSurface [
	<sampleInstance>
	"A canvas over a surface of our own, which is what `AeCanvas class >> extent:` builds through
	 Cairo and what Bloc asks for whenever it needs to measure text without a window."

	^ VGCanvas extent: 40 @ 40
]

{ #category : 'examples' }
VGCanvasExamples class >> metricsOfARunMeasuredThroughTheCanvas [
	<sampleInstance>
	"The measuring site of unit 4.3: a run laid out with one of our fonts, measured through the
	 canvas of this project. The canvas asks the context it holds, the context asks the font,
	 and the six numbers come back in the record the canvas owns. No FreeType face and no Cairo
	 scaled font take part."

	| font |
	font := self scaledFontForTheDefaultFace.
	^ (VGCanvas extent: 10 @ 10)
		  metricsFor: (font glyphArrayForString: 'Hi a')
		  font: font
]

{ #category : 'examples' }
VGCanvasExamples class >> runPathFilledThroughTheCanvas [
	<sampleInstance>
	"The path site as Bloc reaches it: the canvas is given a path factory that appends the
	 glyphs of a run, and the figure drawn from it is the text as a filled shape. This is what
	 a text border and a text shadow are built on."

	| font canvas glyphs |
	font := self scaledFontForTheDefaultFace.
	canvas := VGCanvas extent: 120 @ 40.
	glyphs := font glyphArrayForString: 'Hi a'.
	canvas
		pathTranslate: 6 @ 28;
		pathFactory: [ :cairoContext |
			canvas appendGlyphsPath: glyphs font: font ];
		setBackgroundWith: [ canvas setSourceColor: Color black ];
		setBorderOff;
		drawFigure.
	canvas privateAeCairoSurface flush.
	^ canvas privateAeCairoSurface asForm
]

{ #category : 'examples' }
VGCanvasExamples class >> scaledFontAnUnmodifiedCanvasAnswers [
	<sampleInstance>
	"The scaled font Alexandrie's own canvas answers for a face of this project, with nothing
	 overridden. The inherited scaledFontForFace:size: sends newCairoFontFace to the face, which
	 answers itself, so the canvas builds a VGScaledFont without naming a class of either backend.
	 Its companion scaledFontForTheDefaultFace shows the same seam through VGCanvas, whose own
	 scaledFontForFace:size: is the one that keeps a scaled font per face and size."

	^ (AeCanvas extent: 10 @ 10)
		  scaledFontForFace: VGFontFace default
		  size: 17
]

{ #category : 'examples' }
VGCanvasExamples class >> scaledFontForTheDefaultFace [
	<sampleInstance>
	"The scaled font the canvas answers for the face Bloc hands it with a size. The face is the
	 default face of one of our font managers, which is what Bloc has to hand over since the
	 manager posed for the image is ours: it carries its own bytes, so the canvas passes it
	 straight to VGScaledFont and nothing is bridged. Until unit 5.2 of the font plan the face
	 was a FreeType handle and this example showed the bytes being matched back out of the
	 manager''s entries. The manager is built here rather than posed, because an example changes
	 nothing in the image it runs in."

	^ self canvasOnASmallSurface
		  scaledFontForFace: VGFontManager newWithDefaultFaces defaultFace
		  size: 17
]
