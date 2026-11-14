"
I check the adapter that answers an Alexandrie context for one of our scaled fonts.

`VGScaledFont` is the font model: a face, a matrix, the metrics and the outlines it reads from them. Nothing in it is Alexandrie's, and nothing in it should be. The five verbs an Alexandrie context sends a scaled font — pose, show, measure, path, font extents — and the Cairo masks they rasterise live on `VGAeTextFont` instead, which a font answers through `#aeTextFont` and keeps, so the masks a run warms are there for the run after it.

So I check three things: that the adapter answers every one of those five verbs and the font model answers none of them, that a font answers one and the same adapter however often it is asked, and that a second run through a second context reads the masks the first one rasterised.
"
Class {
	#name : 'VGAeTextFontTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Bloc-Tests-Text',
	#package : 'VectorGraphics-Bloc-Tests',
	#tag : 'Text'
}

{ #category : 'running' }
VGAeTextFontTest >> drawGlyphs: aGlyphArray ofFont: aScaledFont [
	"Draw a run through a context of ours on a surface of its own, the way Alexandrie draws
	 one, and answer nothing: what the run leaves behind is on the font's adapter."

	| surface context |
	surface := AeCairoImageSurface extent: 240 @ 60.
	context := VGAeTextContext newFor: surface.
	context
		translateBy: 10 @ 44;
		sourceColorR: 0.0 g: 0.0 b: 0.0 a: 1.0;
		scaledFont: aScaledFont;
		showGlyphs: aGlyphArray.
	surface flush
]

{ #category : 'running' }
VGAeTextFontTest >> scaledFontOfTheFixture [
	"Source Sans Pro regular at a size big enough that a glyph covers several pixels, with the
	 identity as the user to device matrix, so a measured number is a pixel count."

	^ VGScaledFont
		  fontFace: (VGFontFace newForBytes: AeSourceSansPro_Regular fontContentsData)
		  fontMatrix: (VGCairoMatrix newScalingBy: 24 asPoint)
		  userToDeviceMatrix: VGCairoMatrix newIdentity
		  options: VGFontOptions new
]

{ #category : 'tests' }
VGAeTextFontTest >> testAFontAnswersOneAndTheSameAdapterHoweverOftenItIsAsked [
	"The adapter holds the masks Cairo rasterised, so it has to be the font's own and be kept.
	 A new one each time would throw the atlas away at every pose, and the font it answers for
	 has to be the one that was asked."

	| font |
	font := self scaledFontOfTheFixture.
	self assert: font aeTextFont identicalTo: font aeTextFont.
	self assert: font aeTextFont scaledFont identicalTo: font
]

{ #category : 'tests' }
VGAeTextFontTest >> testASecondRunReadsTheMasksTheFirstRunRasterised [
	"The reason the adapter is kept on the font and not built per pose. Each context of a frame
	 poses the font again; the masks Cairo rasterised for the first run must still be there for
	 the second, so a run drawn twice through two contexts rasterises each glyph once. The run
	 has repeated letters, so the count of masks is below the count of glyphs from the start."

	| font glyphs afterFirst afterSecond |
	font := self scaledFontOfTheFixture.
	glyphs := font glyphArrayForString: 'Hamburgefonstiv'.
	self assert: font aeTextFont cairoMaskAssociations isEmpty.
	self drawGlyphs: glyphs ofFont: font.
	afterFirst := font aeTextFont cairoMaskAssociations size.
	self drawGlyphs: glyphs ofFont: font.
	afterSecond := font aeTextFont cairoMaskAssociations size.
	self assert: afterFirst > 0.
	self assert: afterSecond equals: afterFirst
]

{ #category : 'tests' }
VGAeTextFontTest >> testTheAdapterAnswersEveryAlexandrieVerbAndTheFontModelAnswersNone [
	"The extraction itself. The five verbs are the ones an Alexandrie context sends the scaled
	 font it was posed; they belong to the adapter, and the font model must not understand one
	 of them, or the Alexandrie route would still reach it."

	| font adapter |
	font := self scaledFontOfTheFixture.
	adapter := font aeTextFont.
	#( poseOnAeContext: showGlyphs:size:onAeContext:
	   glyphExtentsOf:size:into:onAeContext:
	   appendPathOfGlyphs:length:onAeContext: fontExtentsInto:onAeContext: )
		do: [ :each |
			self
				assert: (adapter respondsTo: each)
				description: 'the adapter does not answer ' , each.
			self
				deny: (VGScaledFont canUnderstand: each)
				description: 'the font model still answers ' , each ]
]
