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
VGCanvasExamples class >> fontFaceForTheFontManagersDefaultFace [
	<sampleInstance>
	"The face of ours for the FreeType face the font manager answers. A FreeType face carries a
	 family name and a style name and no bytes, so the face is built from the bytes the manager
	 registered under those two names; this is the resolution a drawing uses when it holds no
	 canvas."

	^ VGFontFace newForFace: AeFontManager globalInstance defaultFace
]

{ #category : 'examples' }
VGCanvasExamples class >> scaledFontForTheDefaultFace [
	<sampleInstance>
	"The scaled font the canvas answers for a FreeType face and a size, built from the bytes the
	 font manager registered that face from, because the face itself is a handle into the library
	 this project replaces."

	^ self canvasOnASmallSurface
		  scaledFontForFace: AeFontManager globalInstance defaultFace
		  size: 17
]
