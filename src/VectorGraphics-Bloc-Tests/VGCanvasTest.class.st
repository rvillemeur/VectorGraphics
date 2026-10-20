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

{ #category : 'tests - font bridge' }
VGCanvasTest >> testAFamilyTheFontManagerDoesNotKnowFallsBackToTheBundledFace [
	"A face the manager cannot name has no bytes anywhere, and raising inside the renderer would
	 lose the frame and with it the window. The bundled face is the stated fallback: wrong glyphs
	 are recoverable, a broken render loop is not."

	self
		assert: (VGCanvas
				 bytesForFamilyName: 'No Such Family At All'
				 styleName: 'Regular')
		equals: VGFontFace defaultBytes
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

{ #category : 'tests - font bridge' }
VGCanvasTest >> testAScaledFontIsBuiltOnTheBytesOfTheFaceBlocAskedFor [
	"Bloc asks the canvas for a scaled font by handing over a FreeType face and a size. The face is
	 a handle into the library this project replaces, so the only way to honour the request is to
	 find the bytes it was registered from and read them ourselves. The font matrix is the plain
	 scale by the size, as Cairo builds it."

	| canvas face font |
	canvas := VGCanvas extent: 10 @ 10.
	face := AeFontManager globalInstance defaultFace.
	font := canvas scaledFontForFace: face size: 17.
	self assert: font class equals: VGScaledFont.
	self
		assert: font fontFace bytes
		equals: (VGCanvas
				 bytesForFamilyName: face familyName
				 styleName: face styleName).
	self assert: font fontMatrix equals: (VGCairoMatrix newScalingByX: 17 y: 17)
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
VGCanvasTest >> testOneFontFaceIsKeptPerFamilyAndStyle [
	"The bundled face alone is nearly three hundred kilobytes of tables, so a face is parsed once
	 and kept. Two canvases asking for one family therefore share a face, and with it a glyph
	 cache, which is what makes a second text run cheap."

	| face first second |
	VGCanvas resetFaceCache.
	face := AeFontManager globalInstance defaultFace.
	first := (VGCanvas extent: 10 @ 10) scaledFontForFace: face size: 10.
	second := (VGCanvas extent: 10 @ 10) scaledFontForFace: face size: 20.
	self assert: first fontFace identicalTo: second fontFace.
	VGCanvas resetFaceCache.
	self
		deny: ((VGCanvas extent: 10 @ 10) scaledFontForFace: face size: 10) fontFace
		identicalTo: first fontFace
]

{ #category : 'tests' }
VGCanvasTest >> testOnlyTheOverriddenMethodsBuildACairoObject [
	"`AeCanvas` names a Cairo class in fifteen methods. Nine of them name only an enumeration or a
	 record of integers, which needs no replacement because nothing is called to read it. The
	 other six build a Cairo object. Five are overridden here. The sixth,
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
	self assert: (VGCanvas includesSelector: #setHighQualityOptions).
	self assert: (VGCanvas includesSelector: #setLowQualityOptions)
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
	 draws nothing."

	| classSide instanceSide |
	classSide := #( #extent: ).
	instanceSide := #( #newCairoSurfaceExtent: #setSourceLinearPatternStops:start:end:
	                   #setSourceRadialPatternStops:innerCenter:innerRadius:outerCenter:outerRadius:
	                   #newSurfaceWithGaussianShadow:width:canvasDo: #scaledFontForFace:size:
	                   #setHighQualityOptions #setLowQualityOptions ).
	classSide do: [ :each |
		self assert: (AeCanvas class includesSelector: each).
		self assert: (VGCanvas class includesSelector: each) ].
	instanceSide do: [ :each |
		self assert: (AeCanvas includesSelector: each).
		self assert: (VGCanvas includesSelector: each) ]
]
