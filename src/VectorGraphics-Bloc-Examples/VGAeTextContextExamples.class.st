"
I hold the examples of the text route through real Cairo.

`VGAeTextContext` is the context Alexandrie builds for every surface since unit 4.1 of the font plan. Given a scaled font of this project it draws a run as one A8 mask a glyph, composited by Cairo itself, with no FreeType face anywhere. My examples draw such a run and answer the objects a reader wants to look at: the surface, which holds the ink, the record the font extents site filled, and the context whose path a run was appended to. The adapter whose atlas such a run warms is the subject of `VGAeTextFontExamples`, which reads my font and my run.

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

{ #category : 'examples' }
VGAeTextContextExamples class >> fontExtentsFilledIntoAnAlexandrieRecord [
	<sampleInstance>
	"The font extents site of unit 4.5: the five numbers a text backend lays lines out with -
	 ascent, descent, line height and the widest advance the face allows - read back from the
	 record Alexandrie owns, filled by our own font rather than by Cairo. They are the numbers
	 the font answers, turned into the C doubles the record holds."

	| context |
	context := VGAeTextContext newFor: (AeCairoImageSurface extent: 20 @ 20).
	context scaledFont: self scaledFont.
	^ context fontExtents
]

{ #category : 'examples' }
VGAeTextContextExamples class >> glyphsPathOfARunOnACairoSurface [
	<sampleInstance>
	"The path site of unit 4.4: a run laid out with one of our fonts, appended to the path of a
	 context drawing on a surface Alexandrie made, as our own outlines. The context answers its
	 current path, and the surface behind it has nothing drawn on it: appending a path inks
	 nothing."

	| font context |
	font := self scaledFont.
	context := VGAeTextContext newFor: (AeCairoImageSurface extent: 120 @ 40).
	context
		translateBy: 6 @ 28;
		scaledFont: font;
		appendGlyphsPath: (font glyphArrayForString: self exampleRun).
	^ context
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
VGAeTextContextExamples class >> textRunDrawnThroughRealCairo [
	<sampleInstance>
	"A run of text drawn on a real Cairo surface through VGAeTextContext: every glyph is an A8
	 mask rasterised from our own outlines and composited by cairo_mask_surface, so the colour
	 comes from the Cairo source as it does for any other mask. No FreeType face takes part."

	| surface context font |
	font := self scaledFont.
	surface := AeCairoImageSurface extent: 360 @ 80.
	context := VGAeTextContext newFor: surface.
	context
		translateByX: 12 y: 56;
		sourceColorR: 0.1 g: 0.1 b: 0.35 a: 1.0;
		scaledFont: font;
		showGlyphs: (font glyphArrayForString: self exampleRun).
	surface flush.
	^ surface
]
