"
I hold the examples of the text route through real Cairo.

`VGAeTextContext` is the context Alexandrie builds for every surface since unit 4.1 of the font plan. Given a scaled font of this project it draws a run as one A8 mask a glyph, composited by Cairo itself, with no FreeType face anywhere. My examples draw such a run and answer the two objects a reader wants to look at: the surface, which holds the ink, and the scaled font, whose Cairo mask atlas is then warm and shows a mask a row.

I live beside the renderer and not beside `VGScaledFont`, because an example here names Alexandrie's own surface class and the examples of the engine name none of it.
"
Class {
	#name : 'VGAeTextContextExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Bloc-Examples-Text',
	#package : 'VectorGraphics-Bloc-Examples',
	#tag : 'Text'
}

{ #category : 'fixtures' }
VGAeTextContextExamples class >> exampleFontSize [
	"Big enough that a glyph mask has visible shape when it is inspected."

	^ 36
]

{ #category : 'fixtures' }
VGAeTextContextExamples class >> exampleRun [
	"A short run with round letters, straight letters and a space in it."

	^ 'Hamburg ef'
]

{ #category : 'fixtures' }
VGAeTextContextExamples class >> scaledFont [
	"The bundled default face at a readable size, with the identity as the user to device
	 matrix, so a measured number is a pixel count."

	^ VGScaledFont
		  fontFace: VGFontFace default
		  fontMatrix: (VGCairoMatrix newScalingBy: self exampleFontSize asPoint)
		  userToDeviceMatrix: VGCairoMatrix newIdentity
		  options: VGFontOptions new
]

{ #category : 'examples' }
VGAeTextContextExamples class >> scaledFontWithAWarmCairoMaskAtlas [
	<sampleInstance>
	"The scaled font after a run has been drawn through real Cairo twice, the second time moved
	 by a whole pixel. Its Cairo mask atlas then holds one mask a glyph, whatever the number of
	 glyphs drawn, which is what the Masks tab of the inspector shows."

	| surface context font |
	font := self scaledFont.
	surface := AeCairoImageSurface extent: 360 @ 80.
	context := surface newContext.
	context
		translateByX: 12 y: 56;
		sourceColorR: 0.1 g: 0.1 b: 0.35 a: 1.0;
		scaledFont: font;
		showGlyphs: (font glyphArrayForString: self exampleRun);
		translateByX: 1 y: 0;
		showGlyphs: (font glyphArrayForString: self exampleRun).
	surface flush.
	^ font
]

{ #category : 'examples' }
VGAeTextContextExamples class >> textRunDrawnThroughRealCairo [
	<sampleInstance>
	"A run of text drawn on a real Cairo surface through VGAeTextContext: every glyph is an A8
	 mask rasterised from our own outlines and composited by cairo_mask_surface, so the colour
	 comes from the Cairo source as it does for any other mask. No FreeType face takes part."

	| surface context font |
	font := self scaledFont.
	surface := AeCairoImageSurface extent: 360 @ 80.
	context := surface newContext.
	context
		translateByX: 12 y: 56;
		sourceColorR: 0.1 g: 0.1 b: 0.35 a: 1.0;
		scaledFont: font;
		showGlyphs: (font glyphArrayForString: self exampleRun).
	surface flush.
	^ surface
]
