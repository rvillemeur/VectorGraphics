"
I hold the examples of `VGAeCanvas`, the canvas of the route where Cairo still draws the
pixels and this project only supplies the fonts.

One example per seam of that route: a canvas over a small surface, whose Cairo context is a
`VGAeTextContext`, the scaled font that canvas answers for a face of our own font manager, and
the one pixel offscreen that measures text through the same canvas before any window exists.

One click opens an inspector on the object Bloc itself would be handed on that route.
"
Class {
	#name : 'VGAeCanvasExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Bloc-Examples-Text',
	#package : 'VectorGraphics-Bloc-Examples',
	#tag : 'Text'
}

{ #category : 'examples' }
VGAeCanvasExamples class >> canvasOnASmallSurface [
	<sampleInstance>
	"A canvas over a Cairo surface, drawing through a `VGAeTextContext`: Cairo rasterises every
	 figure, and the text calls alone are answered by this project. The Backend tab shows the
	 surface it holds and the scaled fonts it has cached."

	^ VGAeCanvas extent: 40 @ 40
]

{ #category : 'examples' }
VGAeCanvasExamples class >> scaledFontForTheDefaultFace [
	<sampleInstance>
	"The scaled font this canvas answers for a face of our own font manager. The face is already
	 one of ours on this route, so nothing is bridged: `scaledFontForFace:size:` hands it
	 straight to `VGScaledFont`, which reads the bytes the manager registered."

	^ self canvasOnASmallSurface
		  scaledFontForFace: VGFontFace default
		  size: 17
]

{ #category : 'examples' }
VGAeCanvasExamples class >> textMeasuringOffscreen [
	<sampleInstance>
	"The offscreen this route measures text with before a window exists: the same canvas, one
	 pixel wide, built to answer scaled fonts and nothing else. Its Measuring tab names the
	 canvas and the measurer it holds."

	^ VGAeOffscreen new
		  ensureReady;
		  yourself
]
