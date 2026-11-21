"
I state what a `VGAeCanvas` is: the canvas of the route where Cairo still draws every pixel and the fonts are this project's.

Two facts make that route exist. The surface and the context are real Cairo ones, because Cairo is what draws here, and the context is a `VGAeTextContext`, because the stock one dies marshalling a `VGScaledFont` into `cairo_set_scaled_font`. The scaled font the canvas answers for a face is one of ours, with a font matrix of ours, because our text sites read it.

`prepareForSurface:` is four lines of Alexandrie's with one word changed, so a test here holds it against the upstream source, as `VGRendererTest` does for `VGCanvas class >> formOfElement:`.
"
Class {
	#name : 'VGAeCanvasTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Bloc-Text-Tests-Text',
	#package : 'VectorGraphics-Bloc-Text-Tests',
	#tag : 'Text'
}

{ #category : 'tests' }
VGAeCanvasTest >> testPrepareForSurfaceStaysDerivedFromUpstream [
	"`VGAeCanvas >> prepareForSurface:` is Alexandrie's own method with one send changed: the
	 context is built by our class instead of being asked of the surface, because an extension
	 that redefines `AeCairoSurface >> newContext` cannot leave that checkout clean. The two are
	 held together here, so a change upstream fails a test instead of quietly leaving a frame
	 without its device scale or its quality options. The guard that reinstalls our font manager
	 is dropped before the comparison: it is a statement upstream has no reason to hold, and the
	 pin is about the rest of the method."

	| ours upstream |
	ours := ((VGAeCanvas >> #prepareForSurface:) sourceCode
		         copyReplaceAll: 'VGFontManager ensureUpstreamHoldsMine.'
		         with: '')
		        copyReplaceAll: 'VGAeTextContext unownedNewFor: aeCairoSurface'
		        with: 'cairoSurface newContext'.
	upstream := (AeCanvas >> #prepareForSurface:) sourceCode.
	self
		assert: (RBParser parseMethod: ours) body
		equals: (RBParser parseMethod: upstream) body
]

{ #category : 'tests' }
VGAeCanvasTest >> testTheCanvasDrawsThroughRealCairoWithAContextThatRoutesText [
	"The whole point of this canvas: Cairo composites every pixel, so the surface and the context
	 are Alexandrie's own classes, and the context is the one that asks a font of ours for its
	 text adapter instead of marshalling it into cairo_set_scaled_font."

	| canvas |
	canvas := VGAeCanvas extent: 10 @ 10.
	self
		assert: canvas privateAeCairoSurface class
		equals: AeCairoImageSurface.
	self
		assert: canvas privateAeCairoContext class
		equals: VGAeTextContext
]

{ #category : 'tests' }
VGAeCanvasTest >> testTheSameFaceAndSizeAnswerTheSameScaledFont [
	"The inherited method returns from inside its own `ifAbsentPut:` block, so the cache it
	 writes into is never read and every text run rebuilds its scaled font, parsing the outlines
	 again. The method this canvas inherits from `VGFontCanvas` leaves the block normally."

	| canvas face |
	canvas := VGAeCanvas extent: 10 @ 10.
	face := VGFontFace default.
	self
		assert: (canvas scaledFontForFace: face size: 17)
		identicalTo: (canvas scaledFontForFace: face size: 17)
]

{ #category : 'tests' }
VGAeCanvasTest >> testTheScaledFontForAFaceIsOneOfOursUnderOurOwnMatrixAndOptions [
	"What Bloc asks the canvas for before it draws or measures any text. The face is already
	 ours, since the font manager is; the font, the font matrix and the options record have to
	 be ours as well, because our text sites read all three."

	| canvas face font |
	canvas := VGAeCanvas extent: 10 @ 10.
	face := VGFontFace default.
	font := canvas scaledFontForFace: face size: 17.
	self assert: font class equals: VGScaledFont.
	self assert: font fontFace == face.
	self
		assert: font fontMatrix
		equals: (VGCairoMatrix newScalingByX: 17 y: 17).
	self assert: font options class equals: VGFontOptions
]

{ #category : 'tests' }
VGAeCanvasTest >> testTheScaledFontsCachedAreReadableByFaceAndSizeWithoutReflection [
	"The cache a reader needs to state what a frame resolved: three tests of this project used
	 to reach into the `scaledFontCache` variable with `instVarNamed:`, which no rename would
	 follow. Three facts: the reader answers the fonts built, keyed by the face and the size
	 they were asked for, and what it answers is a copy, so a reader cannot evict what the
	 canvas is drawing with."

	| canvas face font cached |
	canvas := VGAeCanvas extent: 10 @ 10.
	face := VGFontFace default.
	font := canvas scaledFontForFace: face size: 17.
	cached := canvas cachedScaledFontsByFaceAndSize.
	self assert: cached size equals: 1.
	self
		assert: (cached keys collect: [ :each | each first -> each second ]) asArray
		equals: { face -> 17 }.
	self assert: cached anyOne identicalTo: font.
	cached removeAll.
	self
		assert: (canvas scaledFontForFace: face size: 17)
		identicalTo: font
]
