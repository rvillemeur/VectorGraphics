"
I check the Cairo context that knows our scaled fonts.

Alexandrie builds a context for every surface it draws on, and sends the text selectors of that context whatever scaled font the canvas carries. A `VGScaledFont` is not an `AeCairoScaledFont`, so a text selector that reaches the FFI call with ours dies marshalling it. `VGAeTextContext` is the context Alexandrie builds instead: it routes every text selector to the scaled font it is given, which answers for itself, and a real `AeCairoScaledFont` routes straight back to the stock implementation.

So I check two things: that a surface really answers one of ours, and that nothing else about drawing changed — a figure with no text in it is pixel for pixel what the stock context draws.
"
Class {
	#name : 'VGAeTextContextTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Bloc-Tests-Text',
	#package : 'VectorGraphics-Bloc-Tests',
	#tag : 'Text'
}

{ #category : 'running' }
VGAeTextContextTest >> formOfTheFigureDrawnWith: aBlock [
	"Draw the same text-free figure through the context the block builds for a fresh surface,
	 and answer what landed on the surface."

	| surface context |
	surface := AeCairoImageSurface extent: 24 @ 16.
	context := aBlock value: surface.
	context
		sourceColorR: 0.2 g: 0.4 b: 0.9 a: 1.0;
		rectangleX: 2 y: 3 width: 10 height: 8;
		fill;
		sourceColorR: 0.9 g: 0.3 b: 0.1 a: 1.0;
		circleCenterX: 17 y: 9 radius: 5;
		fill.
	surface flush.
	^ surface asForm
]

{ #category : 'private' }
VGAeTextContextTest >> inkBoxOf: aForm [
	"The whole pixel box holding every pixel the drawing touched, nil when nothing was drawn.
	 The box of the inked pixels themselves holds their top left corners, so the corner moves
	 one pixel down and right to hold the pixels whole."

	| inked box |
	inked := self inkedPixelsOf: aForm.
	inked ifEmpty: [ ^ nil ].
	box := Rectangle encompassing: inked.
	^ box origin corner: box corner + (1 @ 1)
]

{ #category : 'private' }
VGAeTextContextTest >> inkedPixelsOf: aForm [
	"Every pixel the drawing touched, as zero-based points. A pixel of a Cairo image surface
	 read back as a Form carries its alpha in the high byte, and an untouched pixel reads as
	 transparent white, so alpha and not the whole word says ink."

	| bits width |
	bits := aForm bits.
	width := aForm width.
	^ (1 to: aForm height) flatCollect: [ :row |
		  ((1 to: width) select: [ :column |
			   ((bits at: row - 1 * width + column) bitShift: -24) ~= 0 ])
			  collect: [ :column | column - 1 @ (row - 1) ] ]
]

{ #category : 'running' }
VGAeTextContextTest >> receiverAndSelectorNotUnderstoodIn: aBlock [
	"The class of the receiver and the selector of the message aBlock fails on, nil when it
	 does not fail."

	^ [
	  aBlock value.
	  nil ]
		  on: MessageNotUnderstood
		  do: [ :error | error receiver class -> error message selector ]
]

{ #category : 'running' }
VGAeTextContextTest >> scaledFontOfTheFixture [
	"Source Sans Pro regular at a size big enough that a glyph covers several pixels, with the
	 identity as the user to device matrix, so a measured number is a pixel count."

	^ VGScaledFont
		  fontFace: (VGFontFace newForBytes: AeSourceSansPro_Regular fontContentsData)
		  fontMatrix: (VGCairoMatrix newScalingBy: 24 asPoint)
		  userToDeviceMatrix: VGCairoMatrix newIdentity
		  options: VGFontOptions new
]

{ #category : 'tests' }
VGAeTextContextTest >> testAFigureWithNoTextIsPixelForPixelWhatTheStockContextDraws [
	"Substituting the context must change text and nothing else, so a figure of plain shapes has
	 to come out of mine identical to the one the stock context draws."

	| ours stock |
	ours := self formOfTheFigureDrawnWith: [ :surface | surface newContext ].
	stock := self formOfTheFigureDrawnWith: [ :surface |
		         AeCairoContext newFor: surface ].

	self deny: (stock bits allSatisfy: [ :each | each = 0 ]).
	self assert: ours extent equals: stock extent.
	self assert: ours bits asArray equals: stock bits asArray
]

{ #category : 'tests' }
VGAeTextContextTest >> testAGlyphRunDrawnThroughTheRealCairoInksInsideItsRunExtents [
	"The criterion of decision 11: ink on the surface, inside the extents of the run. Reading the
	 pixels back is what proves the masks were composited by Cairo itself, which no counter on
	 the atlas can say. A pixel of margin, because the rasteriser shades the pixels an edge
	 crosses. The ink also has to fill its box, or one glyph drawn out of fifteen would pass."

	| font surface context inkBox extents origin expected |
	font := self scaledFontOfTheFixture.
	surface := AeCairoImageSurface extent: 240 @ 60.
	context := surface newContext.
	origin := 10 @ 44.
	context
		translateBy: origin;
		sourceColorR: 0.0 g: 0.0 b: 0.0 a: 1.0;
		scaledFont: font;
		showGlyphs: (font glyphArrayForString: 'Hamburgefonstiv').
	surface flush.

	inkBox := self inkBoxOf: surface asForm.
	extents := font textExtentsOf: 'Hamburgefonstiv'.
	expected := ((extents bearing + origin) extent: extents extent) expandBy: 1.

	self deny: inkBox isNil.
	self assert: (expected containsRect: inkBox).
	self assert: inkBox width >= (expected width - 3).
	self assert: inkBox height >= (expected height - 3)
]

{ #category : 'tests' }
VGAeTextContextTest >> testARealCairoFontStillDrawsThroughCairoItself [
	"The other half of the substitution: a scaled font Cairo can draw sends every text call back
	 to the inherited implementation, so an image with no font manager of ours is untouched. The
	 font is Cairo's own toy font, which Cairo builds and owns: a FreeType face of our making
	 would need the lifetime keeper, which lives in a package this one may not name."

	| surface context font inkBox |
	surface := AeCairoImageSurface extent: 240 @ 60.
	context := surface newContext.
	context
		translateByX: 10 y: 44;
		sourceColorR: 0.0 g: 0.0 b: 0.0 a: 1.0;
		selectFont: 'sans-serif'
		slant: AeCairoFontSlant normal
		weight: AeCairoFontWeight normal;
		fontSize: 24.
	font := context scaledFont.
	context
		scaledFont: font;
		showGlyphs: (font glyphArrayForString: 'Hamburgefonstiv').
	surface flush.

	inkBox := self inkBoxOf: surface asForm.
	self assert: context ownScaledFont isNil.
	self deny: inkBox isNil.
	self assert: inkBox width > 100
]

{ #category : 'tests' }
VGAeTextContextTest >> testEverySurfaceAnswersTheContextThatKnowsOurFonts [
	"Decision 7 of the plan: one substitution site, AeCairoSurface >> newContext, which covers
	 window, composition layers, shadows, exporters and offscreen at once."

	| surface |
	surface := AeCairoImageSurface extent: 10 @ 10.

	self assert: surface newContext class equals: VGAeTextContext
]

{ #category : 'tests' }
VGAeTextContextTest >> testTheTextSitesTheLaterUnitsDeliverFailNamingOurOwnFontAndSelector [
	"Measuring, pathing and font extents are units 4.3, 4.4 and 4.5 of the font plan. Until they
	 land, each site has to fail on our own class naming the method that is missing, and never
	 reach the FFI call: marshalling a VGScaledFont into cairo_set_scaled_font dies far from the
	 cause, on VGFontFace >> #tfPointerAddress."

	| font surface context glyphs |
	font := self scaledFontOfTheFixture.
	surface := AeCairoImageSurface extent: 20 @ 20.
	context := surface newContext.
	context scaledFont: font.
	glyphs := font glyphArrayForString: 'a'.

	self
		assert: (self receiverAndSelectorNotUnderstoodIn: [
				 context
					 getGlyphExtentsOf: glyphs
					 size: 1
					 into: AeCairoTextExtents new ])
		equals: VGScaledFont -> #glyphExtentsOf:size:into:onAeContext:.
	self
		assert: (self receiverAndSelectorNotUnderstoodIn: [
				 context appendGlyphsPath: glyphs ])
		equals: VGScaledFont -> #appendPathOfGlyphs:length:onAeContext:.
	self
		assert:
			(self receiverAndSelectorNotUnderstoodIn: [ context fontExtents ])
		equals: VGScaledFont -> #fontExtentsInto:onAeContext:
]
