"
I hold the facts about `VGCanvas`, the `AeCanvas` subclass that makes Bloc draw through
this project instead of through Cairo.
Half of me watches upstream: the creation methods a canvas sends to build a surface, a pattern, a
shadow or a scaled font are the only seam there is, so a test fails as soon as one of those
selectors leaves `AeCanvas`.
The other half watches the overrides themselves, including the bridge that turns the FreeType face
Bloc hands over into a font face of our own.
"
Class {
	#name : 'VGCanvasTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Bloc-Tests',
	#package : 'VectorGraphics-Bloc-Tests'
}

{ #category : 'running' }
VGCanvasTest >> inkBoxOf: aForm [
	"The whole pixel box holding every pixel the drawing touched, nil when nothing was drawn. A
	 pixel of a Cairo image surface read back as a Form carries its alpha in the high byte, and
	 an untouched pixel reads as transparent white, so alpha and not the whole word says ink.
	 The box of the inked pixels themselves holds their top left corners, so the corner moves
	 one pixel down and right to hold the pixels whole."

	| bits width inked box |
	bits := aForm bits.
	width := aForm width.
	inked := (1 to: aForm height) flatCollect: [ :row |
		         ((1 to: width) select: [ :column |
			          ((bits at: row - 1 * width + column) bitShift: -24) ~= 0 ])
			         collect: [ :column | column - 1 @ (row - 1) ] ].
	inked ifEmpty: [ ^ nil ].
	box := Rectangle encompassing: inked.
	^ box origin corner: box corner + (1 @ 1)
]

{ #category : 'running' }
VGCanvasTest >> ourClassesOverride: aSelector from: aBehavior upTo: anUpstreamBehavior [
	"Whether one of our own canvases on the stretch from `aBehavior` up to Alexandrie's, that one
	 excluded, implements the selector. Since unit 5.1 the stretch is two classes: `VGCanvas`
	 itself and the abstract `VGFontCanvas` it shares with `VGAeCanvas`, which holds the font
	 methods. Where the override sits is a design decision; that it exists is the seam."

	^ (aBehavior withAllSuperclasses copyUpTo: anUpstreamBehavior) anySatisfy: [ :each |
		  each includesSelector: aSelector ]
]

{ #category : 'fixture' }
VGCanvasTest >> scaledFontOfTheFixture [
	"Source Sans Pro regular at a readable size, with the identity as the user to device matrix,
	 so a measured number is a pixel count. The bytes are the bundled ones: measuring must not
	 depend on a FreeType face, which is what the canvas route still builds its own faces from."

	^ VGScaledFont
		  fontFace: (VGFontFace newForBytes: AeSourceSansPro_Regular fontContentsData)
		  fontMatrix: (VGCairoMatrix newScalingBy: 24 asPoint)
		  userToDeviceMatrix: VGCairoMatrix newIdentity
		  options: VGFontOptions new
]

{ #category : 'tests' }
VGCanvasTest >> testAFrameElementRefusesACanvasThatBuildsNoneOfOurDrawingContexts [
	"A frame block is written against the drawing context of this project, and a canvas of
	 Alexandrie's own builds one of Alexandrie's instead: a few selectors overlap and the rest
	 fail inside Cairo marshalling, far from the cause. The element has to say so itself."

	| element |
	element := VGDrawnFrameElement drawing: [ :context | context fill ].
	self
		should: [ element aeDrawGeometryOn: (AeCanvas extent: 8 @ 8) ]
		raise: Error
		withExceptionDo: [ :error |
			self deny: (error isKindOf: MessageNotUnderstood).
			self assert: (error messageText includesSubstring: 'VGCanvas') ]
]

{ #category : 'tests - overrides' }
VGCanvasTest >> testALinearGradientSourceIsOurOwnPattern [
	"Bloc asks the canvas for a linear gradient by handing it offset to colour associations. The
	 pattern built from them has to be ours, because a Cairo pattern is a call into the library
	 that is missing."

	| canvas |
	canvas := VGCanvas extent: 10 @ 10.
	canvas setSourceLinearPatternStops: {
			(0 -> Color red).
			(1 -> Color blue) } start: 0 @ 0 end: 10 @ 0.
	self assert: canvas privateAeCairoContext source class equals: VGCairoLinearGradientPattern
]

{ #category : 'tests - overrides' }
VGCanvasTest >> testARadialGradientSourceIsOurOwnPattern [
	"The radial gradient of a shadow or a round button takes two circles, and the same rule holds:
	 the pattern is ours."

	| canvas |
	canvas := VGCanvas extent: 10 @ 10.
	canvas
		setSourceRadialPatternStops: {
				(0 -> Color red).
				(1 -> Color blue) }
		innerCenter: 5 @ 5
		innerRadius: 0
		outerCenter: 5 @ 5
		outerRadius: 5.
	self assert: canvas privateAeCairoContext source class equals: VGCairoRadialGradientPattern
]

{ #category : 'tests' }
VGCanvasTest >> testARunMeasuredThroughTheCanvasCarriesOurOwnExtents [
	"Unit 4.3 of the font plan, the measuring site. The canvas asks the context it holds for the
	 extents of a laid out run and reads six numbers back; a font of ours answers them from its
	 own metrics, with no FreeType face and no Cairo scaled font in the way. The run holds a
	 space, which inks nothing, so the inked box and the advance cannot agree by accident.
	 The record the canvas fills holds doubles, so our exact fractions come back rounded to the
	 nearest double and the numbers are compared as floats."

	| font glyphs ours metrics advances |
	font := self scaledFontOfTheFixture.
	glyphs := font glyphArrayForString: 'a b'.
	ours := font glyphExtentsOf: glyphs.
	metrics := (VGCanvas extent: 10 @ 10) metricsFor: glyphs font: font.
	advances := glyphs inject: 0 @ 0 into: [ :sum :each |
		            sum + (font glyphAdvanceOf: each index) ].
	self assert: metrics bearingX closeTo: ours bearingX.
	self assert: metrics bearingY closeTo: ours bearingY.
	self assert: metrics width closeTo: ours width.
	self assert: metrics height closeTo: ours height.
	self assert: metrics advanceX closeTo: ours advanceX.
	self assert: metrics advanceY closeTo: ours advanceY.
	self assert: metrics advanceX closeTo: advances x.
	self assert: metrics width < metrics advanceX
]

{ #category : 'tests' }
VGCanvasTest >> testARunPathAppendedThroughTheCanvasInksOurOwnOutlines [
	"The site Bloc calls: BlTextBorderAttribute hands the canvas a path factory that sends
	 #appendGlyphsPath:font:, and the figure drawn from it is the text as a shape. The canvas
	 of this project holds a context of our own, so the glyphs of one of our fonts reach the
	 path as our own contours. Filling the figure has to ink inside the box our measuring
	 reports and to fill it: one glyph out of fifteen would otherwise pass. A pixel of margin,
	 because the rasteriser shades the pixels an edge crosses. The figure is a background with
	 no border, which is the canvas asking for a plain fill of the path."

	| font canvas glyphs origin extents expected inkBox |
	font := self scaledFontOfTheFixture.
	canvas := VGCanvas extent: 240 @ 60.
	glyphs := font glyphArrayForString: 'Hamburgefonstiv'.
	origin := 10 @ 44.
	canvas
		pathTranslate: origin;
		pathFactory: [ :cairoContext |
			canvas appendGlyphsPath: glyphs font: font ];
		setBackgroundWith: [ canvas setSourceColor: Color black ];
		setBorderOff;
		drawFigure.
	canvas privateAeCairoSurface flush.
	inkBox := self inkBoxOf: canvas privateAeCairoSurface asForm.
	extents := font glyphExtentsOf: glyphs.
	expected := ((extents bearing + origin) extent: extents extent) expandBy: 1.
	self deny: inkBox isNil.
	self assert: (expected containsRect: inkBox).
	self assert: inkBox width >= (expected width - 3).
	self assert: inkBox height >= (expected height - 3)
]

{ #category : 'tests - overrides' }
VGCanvasTest >> testASurfaceForALogicalExtentCarriesTheDeviceScale [
	"A canvas draws in points and its surface holds device pixels, so a canvas asked for a surface
	 of a logical extent answers one that is bigger by the device scale and that carries the scale
	 itself, which is how the canvas keeps drawing in points on a high resolution screen."

	| canvas surface |
	canvas := VGCanvas newFor: ((VGCairoImageSurface extent: 1 @ 1)
			          deviceScale: 2;
			          yourself).
	surface := canvas newCairoSurfaceExtent: 10 @ 20.
	self assert: surface class equals: VGCairoImageSurface.
	self assert: surface extent equals: 20 @ 40.
	self assert: surface deviceScaleMatrix equals: (VGCairoMatrix newScalingBy: 2 asPoint)
]

{ #category : 'tests - font bridge' }
VGCanvasTest >> testAnUnmodifiedCanvasAnswersOneOfOurScaledFontsForOneOfOurFaces [
	"The inherited scaledFontForFace:size: sends newCairoFontFace to the face it is given and
	 then asks that answer for a scaled font. A face of this project answers itself, so Alexandrie's
	 own canvas, with nothing overridden, builds one of our scaled fonts. This is the route Bloc
	 takes once the font manager is ours and the faces it hands over are ours: the canvas is
	 asked here by its own class on purpose, so the test cannot slide onto VGCanvas without
	 showing it.

	 The matrix is the one the inherited method builds, an AeCairoMatrix scaling by the size, and
	 it is handed to our scaled font unchanged. Nothing asks the font for its extents: the
	 inherited canvas carries AeCairoFontOptions, which do not understand hintsMetrics, and
	 teaching the text path to accept them belongs to unit 4."

	| canvas face font |
	canvas := AeCanvas extent: 10 @ 10.
	face := VGFontFace default.
	font := canvas scaledFontForFace: face size: 17.
	self assert: canvas class equals: AeCanvas.
	self assert: font class equals: VGScaledFont.
	self assert: font fontFace == face.
	self
		assert: font fontMatrix
		equals: (AeCairoMatrix newScalingByX: 17 y: 17)
]

{ #category : 'tests' }
VGCanvasTest >> testNoMethodOfThisProjectRecoversTheBytesBehindAFreeTypeFace [
	"A FreeType face carries a family name and a style name and no bytes, so every route from one
	 to a face of ours had to look the two names up in a foreign font registry. Unit 5.2 of the
	 font plan took that bridge away: the manager posed for the image is ours, so the face Bloc
	 hands a canvas is already one of ours and there is nothing to recover. These six selectors
	 are the bridge, and this project implements none of them any more. The scan is image-wide and
	 then kept to our own packages, because upstream implements newForFace: too, on its own Cairo
	 font face, and that one is not ours to delete."

	| dead strays |
	dead := #( #newForFace: #bytesForFamilyName:styleName:
	           #faceForFreeTypeFace: #fontFaceFor: #faceCache #resetFaceCache ).
	strays := dead flatCollect: [ :selector |
		          (SystemNavigation default allImplementorsOf: selector)
			          select: [ :each |
				          each package name beginsWith:
					          VGCairoReferenceScanner projectPackagePrefix ]
			          thenCollect: [ :each |
			          each methodClass name , ' >> ' , each selector ] ].
	self assert: strays asSortedCollection asArray equals: #(  )
]

{ #category : 'tests' }
VGCanvasTest >> testOnlyTheOverriddenMethodsBuildACairoObject [
	"`AeCanvas` names a Cairo class in fifteen methods. Nine of them name only an enumeration or a
	 record of integers, which needs no replacement because nothing is called to read it. The
	 other six build a Cairo object. Five are overridden by our canvases. The sixth,
	 `initializeFontOptions`, stores two shared records in class variables, and is answered by
	 overriding the two methods that read them, so the record is never asked for a field. A
	 seventh builder upstream would be a hole in the failover, so this test states the partition
	 and fails when it changes."

	| plainClassNames scanner builders |
	plainClassNames := #( #AeCairoStrokeCap #AeCairoStrokeJoin #AeCairoAntialias
	                      #AeCairoHintMetrics #AeCairoHintStyle #AeCairoTextExtents
	                      #AeCairoTextMetrics ).
	scanner := VGCairoReferenceScanner new.
	builders := (AeCanvas methods , AeCanvas class methods) select: [ :each |
		            (scanner cairoClassesNamedBy: each) anySatisfy: [ :class |
			            (plainClassNames includes: class name asSymbol) not ] ].
	self
		assertCollection: (builders collect: [ :each | each selector ]) asSet
		hasSameElements: #( #extent: #newCairoSurfaceExtent: #setSourceLinearPatternStops:start:end:
			 #setSourceRadialPatternStops:innerCenter:innerRadius:outerCenter:outerRadius:
			 #newSurfaceWithGaussianShadow:width:canvasDo: #initializeFontOptions ) asSet.
	self assert: (self
			 ourClassesOverride: #setHighQualityOptions
			 from: VGCanvas
			 upTo: AeCanvas).
	self assert: (self
			 ourClassesOverride: #setLowQualityOptions
			 from: VGCanvas
			 upTo: AeCanvas)
]

{ #category : 'tests' }
VGCanvasTest >> testTheBackendViewIsOfferedByBothCanvasesAndCountsTheirScaledFonts [
	"The Backend tab describes what a canvas draws with: the surface, the device scale, our font
	 options and the scaled fonts it has cached. All four are the business of `VGFontCanvas`
	 since unit 5.1, so both canvases offer the tab and both answer the same rows. `VGCanvas`
	 carried one row more until unit 5.2, counting the faces the FreeType bridge had cached;
	 the bridge is gone, so the override that appended that row is gone with it."

	| builder |
	builder := SpPresenterBuilder newApplication: SpApplication new.
	{ VGCanvas. VGAeCanvas } do: [ :each |
		| canvas presenter keys |
		canvas := each extent: 1 @ 1.
		canvas scaledFontForFace: VGFontFace default size: 17.
		presenter := (StInspectionContext new
			              inspectedObject: canvas;
			              methodSelector: #inspectorBackend:;
			              yourself) basicNewInspectionPresenter: builder.
		self assert: presenter notNil.
		presenter columns do: [ :column |
			presenter items do: [ :item | column evaluation value: item ] ].
		keys := presenter items collect: [ :item | item key ].
		self assert: (keys includes: 'Scaled fonts cached').
		self
			assert: (presenter items detect: [ :item | item key = 'Scaled fonts cached' ]) value
			equals: 1 ]
]

{ #category : 'tests' }
VGCanvasTest >> testTheFontOptionsAreOurOwnRecordAtBothQualities [
	"`AeCanvas` keeps its font options in a shared `AeCairoFontOptions`, and that record is a
	 Cairo object: reading one of its fields is a foreign call, which a canvas asked for a scaled
	 font makes on every text run. Ours holds our own record at both qualities, and a fresh canvas
	 holds one before it has ever been prepared for a surface, because text is measured first."

	| canvas |
	canvas := VGCanvas extent: 10 @ 10.
	self assert: VGCanvas newWithoutSurface fontOptions class equals: VGFontOptions.
	canvas setHighQualityOptions.
	self assert: canvas fontOptions hintStyle equals: #slight.
	self assert: canvas fontOptions hintMetrics equals: #on.
	canvas setLowQualityOptions.
	self assert: canvas fontOptions hintStyle equals: #none.
	self assert: canvas fontOptions hintMetrics equals: #off.
	self assert: canvas fontOptions antialias equals: #fast
]

{ #category : 'tests - font bridge' }
VGCanvasTest >> testTheScaledFontAnUnmodifiedCanvasAnswersMeasuresThroughAlexandriesOwnOptions [
	"A face of this project reached through Alexandrie's own canvas is scaled but, until this
	 gate, never measured: the canvas hands the scaled font an AeCairoFontOptions of its own, and
	 our measurements ask the options record one question it does not answer, hintsMetrics. Both
	 fontExtents and glyphAdvanceOf: raised a MessageNotUnderstood on it. VGFontOptions, the
	 record VGCanvas poses, answers the same question about itself.

	 The canvas asks Cairo for hinted metrics, so the ascent and the advance come back rounded to
	 whole pixels. They are asserted as integers rather than for their values: the rounding is
	 what proves the answer reached the measurement, and the values belong to the face."

	| font |
	font := (AeCanvas extent: 10 @ 10)
		        scaledFontForFace: VGFontFace default
		        size: 17.
	self assert: font options hintMetrics equals: AeCairoHintMetrics on.
	self assert: font fontExtents ascent isInteger.
	self assert: (font glyphAdvanceOf: 10) x isInteger
]

{ #category : 'tests' }
VGCanvasTest >> testTheScaledFontCarriesTheVeryFaceBlocHandedTheCanvas [
	"Bloc asks the canvas for a scaled font by handing over a face and a size. Until unit 5.2 of
	 the font plan that face was a FreeType handle, which carries a family name and a style name
	 and no bytes, so the canvas had to find the bytes it was registered from and read them back;
	 the test that stood here asserted those recovered bytes. The manager posed for the image is
	 ours now, so the face is already one of ours and the canvas passes it through untouched. The
	 font matrix is the plain scale by the size, as Cairo builds it."

	| canvas face font |
	canvas := VGCanvas extent: 10 @ 10.
	face := VGFontFace default.
	font := canvas scaledFontForFace: face size: 17.
	self assert: font class equals: VGScaledFont.
	self assert: font fontFace identicalTo: face.
	self assert: font fontMatrix equals: (VGCairoMatrix newScalingByX: 17 y: 17)
]

{ #category : 'tests' }
VGCanvasTest >> testTheSeamsViewOfEveryCanvasOfOursMarksThePulledUpFontMethodsAsOverridden [
	"The Seams tab answers, per upstream selector, whether a canvas of ours replaces it. Unit 5.1
	 moved the three font methods to `VGFontCanvas`, so a tab that only asked the class it was
	 opened on would report the font seam as a hole on `VGCanvas` and would not be offered at all
	 on `VGAeCanvas`, which does not descend from `VGCanvas`. `initializeFontOptions` is the one
	 builder we deliberately leave upstream, so it stays marked as not overridden."

	| builder |
	builder := SpPresenterBuilder newApplication: SpApplication new.
	{ VGFontCanvas. VGCanvas. VGAeCanvas } do: [ :each |
		| presenter overriddenColumn rowOf |
		presenter := (StInspectionContext new
			              inspectedObject: each;
			              methodSelector: #inspectorSeams:;
			              yourself) basicNewInspectionPresenter: builder.
		self assert: presenter notNil.
		overriddenColumn := presenter columns third.
		rowOf := [ :selector |
		          presenter items detect: [ :row | row key = selector ] ].
		self
			assert: (overriddenColumn evaluation value: (rowOf value: #setHighQualityOptions))
			equals: 'true'.
		self
			assert: (overriddenColumn evaluation value: (rowOf value: #initializeFontOptions))
			equals: 'false' ]
]

{ #category : 'tests - overrides' }
VGCanvasTest >> testTheShadowSurfaceIsOurOwnBlurredAlphaSurface [
	"A shadow is drawn once into an alpha surface, blurred, and then used as a mask. Two things
	 have to be ours here and both are asserted: the surface, and the canvas handed to the block
	 that draws into it, because the inherited method builds that canvas by naming `AeCanvas`.
	 Partly covered bytes prove the blur ran: a hard edged rectangle has none."

	| canvas alphaSurface drawnOn bytes |
	canvas := VGCanvas extent: 40 @ 40.
	drawnOn := nil.
	alphaSurface := canvas
		                newSurfaceWithGaussianShadow: 40 @ 40
		                width: 4
		                canvasDo: [ :alphaCanvas |
			                drawnOn := alphaCanvas.
			                alphaCanvas
				                pathFactory: [ :context |
					                context rectangleX: 10 y: 10 width: 20 height: 20 ];
				                setBackgroundWith: [
					                alphaCanvas setSourceColor: Color black ];
				                setBorderOff;
				                drawFigureAndPrepareToClip: false ].
	self assert: drawnOn class equals: VGCanvas.
	self assert: alphaSurface class equals: VGCairoImageSurface.
	self assert: alphaSurface format equals: VGCairoSurfaceFormat a8.
	bytes := alphaSurface data asArray.
	self deny: (bytes allSatisfy: [ :each | each = 0 ]).
	self assert: (bytes anySatisfy: [ :each | each > 0 and: [ each < 255 ] ])
]

{ #category : 'tests' }
VGCanvasTest >> testTheUpstreamCreationSelectorsStillExist [
	"These eight methods are the whole seam. Five of them build a Cairo object by naming its
	 class. `scaledFontForFace:size:` reaches Cairo without naming it, by sending
	 `newCairoFontFace` to the FreeType face. The two quality setters assign a shared
	 `AeCairoFontOptions`, whose four fields are foreign calls, so they are replaced rather than
	 the record. An upstream rename has to be noticed here, and not in a window that silently
	 draws nothing. The three font ones sit on `VGFontCanvas` since unit 5.1, so the override is
	 looked for over the pair rather than on `VGCanvas` alone."

	| classSide instanceSide |
	classSide := #( #extent: ).
	instanceSide := #( #newCairoSurfaceExtent: #setSourceLinearPatternStops:start:end:
	                   #setSourceRadialPatternStops:innerCenter:innerRadius:outerCenter:outerRadius:
	                   #newSurfaceWithGaussianShadow:width:canvasDo: #scaledFontForFace:size:
	                   #setHighQualityOptions #setLowQualityOptions ).
	classSide do: [ :each |
		self assert: (AeCanvas class includesSelector: each).
		self assert: (self
				 ourClassesOverride: each
				 from: VGCanvas class
				 upTo: AeCanvas class) ].
	instanceSide do: [ :each |
		self assert: (AeCanvas includesSelector: each).
		self assert: (self
				 ourClassesOverride: each
				 from: VGCanvas
				 upTo: AeCanvas) ]
]
