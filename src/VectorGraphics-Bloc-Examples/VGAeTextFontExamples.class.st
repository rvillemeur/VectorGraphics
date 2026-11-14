"
I hold the examples of the adapter that answers an Alexandrie context for one of our scaled fonts.

`VGAeTextFont` is the object a `VGScaledFont` answers through `#aeTextFont`, and the one that implements Alexandrie's five text verbs. It holds the A8 masks Cairo rasterised for the glyphs drawn through it, so the object a reader wants to look at is one whose atlas is warm: my example draws a run twice and answers the adapter behind it.

I read the font and the run from my sibling `VGAeTextContextExamples`, because the run that warms the atlas is drawn through one of its contexts and the fixture belongs there. No examples class of another layer can be read from here: this package may name the Bloc renderer, the Cairo backend and the font reader, and no examples package but its own.
"
Class {
	#name : 'VGAeTextFontExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Bloc-Examples-Text',
	#package : 'VectorGraphics-Bloc-Examples',
	#tag : 'Text'
}

{ #category : 'fixtures' }
VGAeTextFontExamples class >> exampleRun [
	"The run the context examples draw, for the same reason."

	^ VGAeTextContextExamples exampleRun
]

{ #category : 'fixtures' }
VGAeTextFontExamples class >> scaledFont [
	"The font the context examples draw with: the run that warms my atlas is drawn through
	 one of their contexts, so the fixture belongs to them."

	^ VGAeTextContextExamples scaledFont
]

{ #category : 'examples' }
VGAeTextFontExamples class >> textFontWithAWarmCairoMaskAtlas [
	<sampleInstance>
	"The adapter of a scaled font after a run has been drawn through real Cairo twice, the
	 second time moved by a whole pixel. Its mask atlas then holds one mask a glyph,
	 whatever the number of glyphs drawn, which is what the Cairo masks tab of the
	 inspector shows."

	| surface context font |
	font := self scaledFont.
	surface := AeCairoImageSurface extent: 360 @ 80.
	context := VGAeTextContext newFor: surface.
	context
		translateByX: 12 y: 56;
		sourceColorR: 0.1 g: 0.1 b: 0.35 a: 1.0;
		scaledFont: font;
		showGlyphs: (font glyphArrayForString: self exampleRun);
		translateByX: 1 y: 0;
		showGlyphs: (font glyphArrayForString: self exampleRun).
	surface flush.
	^ font aeTextFont
]
