"
I cover the ARGB32 target of unit 1.1: how a VGCairoImageSurface stores pixels, reports its stride, hands them out as a Form or a Color, takes them back from a Form, and renders into memory the host supplied. Premultiplied alpha is the fact most of my tests state, because it is the one that silently produces wrong colours when it is wrong. Two of my tests are the unit 1.1 gate: a surface over an externally supplied buffer whose stride is larger than four bytes per pixel must write every pixel at the right byte offset and must leave the padding bytes between rows untouched.
"
Class {
	#name : 'VGCairoSurfaceTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Cairo-Tests-Tests',
	#package : 'VectorGraphics-Cairo-Tests',
	#tag : 'Tests'
}

{ #category : 'support' }
VGCairoSurfaceTest >> assertColour: aColour isWithinOneUnitOf: anotherColour [
	"One unit per channel on a scale of 255, which is the tolerance the plan sets for unit 1.1."

	#( #red #green #blue #alpha ) do: [ :each |
		| one other |
		one := (aColour perform: each) * 255.
		other := (anotherColour perform: each) * 255.
		self
			assert: (one - other) abs <= 1.0
			description: each , ' is ' , one printString , ' but ' , other printString , ' was expected' ]
]

{ #category : 'support' }
VGCairoSurfaceTest >> cairoReferenceForTranslucentOverTranslucent [
	"The pixel Cairo itself leaves when it paints my two translucent colours one over the other.
	 Rendered live, because Alexandrie and libcairo are in this image; a committed PNG would only
	 repeat it."
	| surface context |
	surface := AeCairoImageSurface extent: 2 @ 2.
	context := surface newContext.
	context
		sourceColor: self translucentRed;
		paint.
	context
		sourceColor: self translucentBlue;
		paint.
	surface flush.
	^ surface data uint32AtOffset: 0
]

{ #category : 'support' }
VGCairoSurfaceTest >> hostBufferHeight [
	^ 2
]

{ #category : 'support' }
VGCairoSurfaceTest >> hostBufferStride [
	"Four bytes of padding after every row, which is what a host window with an aligned row pitch
	 hands over."

	^ self hostBufferWidth * 4 + 4
]

{ #category : 'support' }
VGCairoSurfaceTest >> hostBufferWidth [
	^ 3
]

{ #category : 'support' }
VGCairoSurfaceTest >> newHostBuffer [
	"A ByteArray stands in for the host address: both it and an ExternalAddress answer
	 #uint32AtOffset:put:, so the surface takes either, and a test needs no external memory."

	^ ByteArray new: self hostBufferStride * self hostBufferHeight withAll: 16rEE
]

{ #category : 'tests - geometry' }
VGCairoSurfaceTest >> testA8StrideIsAlignedToFourBytes [
	"Cairo aligns every row to a four-byte boundary, so an A8 surface seven pixels wide has a stride
	 of eight, not seven."

	| surface |
	surface := VGCairoImageSurface extent: 7 @ 3 format: VGCairoSurfaceFormat a8.
	self assert: surface stride equals: 8.
	self assert: surface byteSize equals: 24.
	self assert: surface status isSuccess
]

{ #category : 'tests - format' }
VGCairoSurfaceTest >> testAFormatReadsAndWritesAPixelAsFourUnpremultipliedFloats [
	"The rasteriser evaluates a paint in floating point, and a Pharo Color keeps only ten bits a
	 channel, so the format has to take and answer channels as floats or the last bit of a ramp is
	 lost on the way through. Half-transparent red shows it: through four floats the pixel is
	 16r80800000, and through a Color it is 16r7F7F0000, because a half rounds down to five hundred
	 and eleven of the ten bits a Color keeps, and the alpha it rounds to premultiplies the red."

	| argb a8 rgb24 |
	argb := VGCairoSurfaceFormat argb32.
	a8 := VGCairoSurfaceFormat a8.
	rgb24 := VGCairoSurfaceFormat rgb24.

	self assert: (argb pixelForRgba: #( 1.0 0.0 0.0 0.5 )) equals: 16r80800000.

	"Measured in live Cairo: these are the channels a sixty-four wide ramp from transparent blue to
	 opaque red holds at the centre of pixel 32, and this is the word Cairo writes for them."
	self
		assert: (argb pixelForRgba: { 0.5078125. 0.0. 0.4921875. 0.5078125 })
		equals: 16r81420040.
	self
		assert: (argb pixelForColor: (Color r: 1.0 g: 0.0 b: 0.0 alpha: 0.5))
		equals: 16r7F7F0000.
	self assert: (argb rgbaForPixel: 16r80800000) equals: { 1.0. 0.0. 0.0. 128 / 255 }.

	self
		assert: (argb rgbaForPixel: (argb pixelForRgba: #( 1.0 1.0 1.0 1.0 )))
		equals: #( 1.0 1.0 1.0 1.0 ).

	"A pixel of no alpha premultiplied its channels away, so nothing is left to divide back out."
	self assert: (argb rgbaForPixel: 0) equals: #( 0.0 0.0 0.0 0.0 ).

	"A8 carries alpha alone, and RGB24 carries no alpha at all and so reads back opaque."
	self assert: (a8 pixelForRgba: #( 1.0 1.0 1.0 0.5 )) equals: 128.
	self assert: (a8 rgbaForPixel: 128) equals: { 0.0. 0.0. 0.0. 128 / 255 }.
	self assert: (rgb24 rgbaForPixel: (rgb24 pixelForRgba: #( 1.0 0.0 0.0 0.5 ))) equals: #( 1.0 0.0 0.0 1.0 )
]

{ #category : 'tests' }
VGCairoSurfaceTest >> testASolidColourQuantisesThroughSixteenBitShortsAndAGradientThroughBytes [
	"Measured against live Cairo on six colours and on nine pixels of a ramp. Cairo keeps a solid
	 colour as four sixteen-bit shorts, each the truncated product of the channel, the alpha and
	 sixty-five thousand five hundred and thirty-five, and stores the top byte of each; a gradient
	 it evaluates into bytes and rounds. The two rules differ by one on most colours, so each
	 paint has to quantise its own way."

	| format solid |
	format := VGCairoSurfaceFormat argb32.
	solid := #( 0.5004887585532747 0.25024437927663734 0.7497556207233627 0.4980392156862745 ).
	self assert: (format pixelForRgbaThroughShorts: solid) equals: 16r7F3F1F5F.
	self assert: (format pixelForRgba: solid) equals: 16r7F40205F.
	self
		assert: (format pixelForRgbaThroughShorts: #( 0.09970674486803519 0.6999022482893451 0.3998044965786901 1.0 ))
		equals: 16rFF19B366.
	self
		assert: (format pixelForRgbaThroughShorts: #( 1.0 0.0 0.0 0.24705882352941178 ))
		equals: 16r3F3F0000.
	"An alpha only surface carries no colour to premultiply and a plain RGB one carries no alpha,
	 so on both the two rules part by rounding alone."
	self assert: (VGCairoSurfaceFormat a8 pixelForRgbaThroughShorts: solid) equals: 127.
	self assert: (VGCairoSurfaceFormat a8 pixelForRgba: solid) equals: 127.
	self
		assert: (VGCairoSurfaceFormat rgb24 pixelForRgbaThroughShorts: #( 1.0 0.0 0.5019607843137255 1.0 ))
		equals: (VGCairoSurfaceFormat rgb24 pixelForRgba: #( 1.0 0.0 0.5019607843137255 1.0 ))
]

{ #category : 'tests - geometry' }
VGCairoSurfaceTest >> testArgb32StrideIsFourBytesPerPixel [
	| surface |
	surface := VGCairoImageSurface extent: 7 @ 3.
	self assert: surface width equals: 7.
	self assert: surface height equals: 3.
	self assert: surface extent equals: 7 @ 3.
	self assert: surface stride equals: 28.
	self assert: surface byteSize equals: 84.
	self assert: surface status isSuccess
]

{ #category : 'tests - form' }
VGCairoSurfaceTest >> testAsFormAnswersStraightAlphaPixels [
	"A Form holds straight alpha, so the premultiplied pixels must be divided back out."

	| surface colour form |
	surface := VGCairoImageSurface extent: 2 @ 2.
	colour := Color r: 1.0 g: 0.0 b: 0.0 alpha: 128 / 255.
	surface newContext clearColor: colour.
	form := surface asForm.
	self assert: form extent equals: 2 @ 2.
	self assert: form depth equals: 32.
	self assertColour: (form colorAt: 0 @ 0) isWithinOneUnitOf: colour
]

{ #category : 'tests - form' }
VGCairoSurfaceTest >> testAsFormOfATransparentSurfaceIsWhiteAndTransparent [
	"Alexandrie answers 16r00FFFFFF for a fully transparent pixel, and a Form that differed there
	 would blit differently, so we answer the same."

	| surface form |
	surface := VGCairoImageSurface extent: 2 @ 2.
	form := surface asForm.
	self assert: (form bits allSatisfy: [ :each | each = 16r00FFFFFF ])
]

{ #category : 'tests - pixels' }
VGCairoSurfaceTest >> testClearColorRoundTripsThroughColorAt [
	| surface colour read |
	surface := VGCairoImageSurface extent: 2 @ 2.
	colour := Color r: 0.8 g: 0.4 b: 0.2 alpha: 0.6.
	surface newContext clearColor: colour.
	read := surface colorAt: 1 @ 1.
	self assertColour: read isWithinOneUnitOf: colour
]

{ #category : 'tests - pixels' }
VGCairoSurfaceTest >> testClearColorStoresPremultipliedPixels [
	"Half-transparent red is 16r80800000, not 16r80FF0000."

	| surface pixel |
	surface := VGCairoImageSurface extent: 2 @ 2.
	surface newContext clearColor: (Color r: 1.0 g: 0.0 b: 0.0 alpha: 128 / 255).
	pixel := surface pixelAtX: 1 y: 1.
	self assert: (pixel bitShift: -24) equals: 128.
	self assert: ((pixel bitShift: -16) bitAnd: 255) equals: 128.
	self assert: ((pixel bitShift: -8) bitAnd: 255) equals: 0.
	self assert: (pixel bitAnd: 255) equals: 0
]

{ #category : 'tests - pixels' }
VGCairoSurfaceTest >> testClearTransparentEmptiesTheSurface [
	| surface context |
	surface := VGCairoImageSurface extent: 2 @ 2.
	context := surface newContext.
	context clearColor: Color red.
	context clearTransparent.
	self assert: (surface colorAt: 0 @ 0) equals: Color transparent.
	self assert: (surface pixelAtX: 1 y: 0) equals: 0
]

{ #category : 'tests - pixels' }
VGCairoSurfaceTest >> testDataAnswersTheBufferThePixelsLiveIn [
	| data surface |
	data := self newHostBuffer.
	surface := VGCairoImageSurface
		           unownedNewForData: data
		           format: VGCairoSurfaceFormat argb32
		           width: self hostBufferWidth
		           height: self hostBufferHeight
		           stride: self hostBufferStride.
	self assert: surface data identicalTo: data.
	self assert: (VGCairoImageSurface extent: 2 @ 2) data size equals: 16
]

{ #category : 'tests - device space' }
VGCairoSurfaceTest >> testDeviceOffsetAndScaleRoundTrip [
	| surface |
	surface := VGCairoImageSurface extent: 8 @ 8.
	self assert: surface deviceOffset equals: 0 @ 0.
	self assert: surface deviceScale equals: 1 @ 1.
	surface deviceOffset: -4 @ -6.
	surface deviceScaleX: 2 y: 3.
	self assert: surface deviceOffset equals: -4 @ -6.
	self assert: surface deviceScale equals: 2 @ 3.
	surface deviceScale: 1.5 @ 1.5.
	self assert: surface deviceScale equals: 1.5 @ 1.5
]

{ #category : 'tests' }
VGCairoSurfaceTest >> testExternalSurfaceLeavesThePaddingBytesAlone [
	"The bytes between rows belong to the host, so nothing may write them."

	| data surface paddingOffsets |
	data := self newHostBuffer.
	surface := VGCairoImageSurface
		           unownedNewForData: data
		           format: VGCairoSurfaceFormat argb32
		           width: self hostBufferWidth
		           height: self hostBufferHeight
		           stride: self hostBufferStride.
	surface newContext clearColor: Color white.
	paddingOffsets := (0 to: self hostBufferHeight - 1) flatCollect: [ :row |
		                  | rowStart |
		                  rowStart := row * self hostBufferStride + (self hostBufferWidth * 4).
		                  rowStart to: rowStart + 3 ].
	paddingOffsets do: [ :each |
		self
			assert: (data at: each + 1) = 16rEE
			description: 'byte ' , each printString , ' of the host buffer was overwritten' ]
]

{ #category : 'tests - host memory' }
VGCairoSurfaceTest >> testExternalSurfaceWritesEveryPixelAtTheGivenStride [
	"The unit 1.1 gate: a stride larger than four bytes per pixel must land in the right bytes."

	| data surface offsetOfSecondRow |
	data := self newHostBuffer.
	surface := VGCairoImageSurface
		           unownedNewForData: data
		           format: VGCairoSurfaceFormat argb32
		           width: self hostBufferWidth
		           height: self hostBufferHeight
		           stride: self hostBufferStride.
	self assert: surface status isSuccess.
	surface newContext clearColor: (Color r: 1.0 g: 1.0 b: 1.0).
	offsetOfSecondRow := self hostBufferStride.
	self assert: (data uint32AtOffset: 0) equals: 16rFFFFFFFF.
	self assert: (data uint32AtOffset: offsetOfSecondRow) equals: 16rFFFFFFFF.
	self
		assert: (data uint32AtOffset: offsetOfSecondRow + ((self hostBufferWidth - 1) * 4))
		equals: 16rFFFFFFFF
]

{ #category : 'tests - lifecycle' }
VGCairoSurfaceTest >> testFinishIsIdempotentAndStopsFurtherDrawing [
	| surface |
	surface := VGCairoImageSurface extent: 2 @ 2.
	surface newContext clearColor: Color red.
	surface finish.
	surface finish.
	self assert: surface isFinished.
	self assert: (surface colorAt: 0 @ 0) equals: Color red.
	self should: [ surface newContext clearColor: Color blue ] raise: Error
]

{ #category : 'tests - lifecycle' }
VGCairoSurfaceTest >> testFlushAnswersTheSurfaceAndChangesNothing [
	"A software surface has no pending operations, so #flush is only a seam; it must still answer the
	 surface, because Alexandrie's callers cascade from it."

	| surface |
	surface := VGCairoImageSurface extent: 2 @ 2.
	surface newContext clearColor: Color red.
	self assert: surface flush identicalTo: surface.
	self assert: (surface colorAt: 0 @ 0) equals: Color red
]

{ #category : 'tests - form' }
VGCairoSurfaceTest >> testFormRoundTripKeepsOpaqueColours [
	| form surface read |
	form := Form extent: 3 @ 2 depth: 32.
	form fillColor: (Color r: 0.2 g: 0.6 b: 0.9).
	surface := VGCairoImageSurface fromForm: form.
	read := surface asForm.
	self assert: read extent equals: 3 @ 2.
	self assertColour: (read colorAt: 2 @ 1) isWithinOneUnitOf: (form colorAt: 2 @ 1)
]

{ #category : 'tests - pixels' }
VGCairoSurfaceTest >> testFreshSurfaceIsFullyTransparent [
	| surface |
	surface := VGCairoImageSurface extent: 4 @ 4.
	self assert: (surface colorAt: 0 @ 0) equals: Color transparent.
	self assert: (surface colorAtX: 3 y: 3) equals: Color transparent.
	self assert: (surface pixelAtX: 2 y: 2) equals: 0
]

{ #category : 'tests' }
VGCairoSurfaceTest >> testFromFormPremultipliesThePixels [
	| form surface |
	form := Form extent: 2 @ 2 depth: 32.
	form fillColor: (Color r: 1.0 g: 0.0 b: 0.0 alpha: 128 / 255).
	surface := VGCairoImageSurface fromForm: form.
	self assert: surface extent equals: 2 @ 2.
	self assert: (((surface pixelAtX: 0 y: 0) bitShift: -16) bitAnd: 255) equals: 128
]

{ #category : 'tests - lifecycle' }
VGCairoSurfaceTest >> testNewContextTargetsTheSurface [
	| surface context |
	surface := VGCairoImageSurface extent: 4 @ 4.
	context := surface newContext.
	self assert: context currentTarget identicalTo: surface
]

{ #category : 'tests - lifecycle' }
VGCairoSurfaceTest >> testSimilarA8SurfaceIsSuccessfulAndEightBitsDeep [
	"AeCanvas builds its shadow mask this way and sends #status #ensureIsSuccess to the result."

	| surface mask |
	surface := VGCairoImageSurface extent: 8 @ 8.
	mask := surface
		        newSimilarImageFormat: VGCairoSurfaceFormat a8
		        width: 5
		        height: 4.
	self assert: mask extent equals: 5 @ 4.
	self assert: mask format equals: VGCairoSurfaceFormat a8.
	self assert: mask stride equals: 8.
	mask status ensureIsSuccess.
	self assert: (mask colorAt: 0 @ 0) equals: Color transparent
]

{ #category : 'tests' }
VGCairoSurfaceTest >> testSourceOverBlendIsPremultipliedAndRounded [
	"Source-over on premultiplied pixels is source + destination scaled by one minus the source
	 alpha, and the division by 255 rounds."
	| format blended |
	format := VGCairoSurfaceFormat argb32.
	blended := format
		           blendPixel: (format pixelForColor: self translucentBlue)
		           over: (format pixelForColor: self translucentRed).
	self assert: blended equals: 16rBF40007F
]

{ #category : 'tests - host memory' }
VGCairoSurfaceTest >> testStrideSmallerThanOneRowIsRefusedByStatus [
	"Cairo answers a surface whose status is CAIRO_STATUS_INVALID_STRIDE rather than signalling, and
	 AeCanvas asks a surface for its status, so we do the same."

	| surface |
	surface := VGCairoImageSurface
		           unownedNewForData: (ByteArray new: 64)
		           format: VGCairoSurfaceFormat argb32
		           width: 4
		           height: 4
		           stride: 8.
	self deny: surface status isSuccess.
	self should: [ surface status ensureIsSuccess ] raise: Error
]

{ #category : 'tests' }
VGCairoSurfaceTest >> testTranslucentOverTranslucentMatchesTheCairoReference [
	"The unit 1.1 gate: translucent over translucent, within one unit per channel of what Cairo
	 produces for the same two colours."
	| surface |
	VGCairoInventory isLiveCairoAvailable ifFalse: [ ^ self skip ].
	surface := VGCairoImageSurface extent: 2 @ 2.
	surface fillPixel: (surface format pixelForColor: self translucentRed).
	surface blendPixel: (surface format pixelForColor: self translucentBlue).
	self
		assertColour: (surface colorAt: 0 @ 0)
		isWithinOneUnitOf: (surface format colorForPixel:
				 self cairoReferenceForTranslucentOverTranslucent)
]

{ #category : 'tests - lifecycle' }
VGCairoSurfaceTest >> testWritePngRoundTripsThroughThePharoReader [
	| surface file read |
	surface := VGCairoImageSurface extent: 4 @ 3.
	surface newContext clearColor: (Color r: 0.1 g: 0.5 b: 0.9).
	file := FileSystem memory root / 'surface.png'.
	surface writePngTo: file.
	self assert: file exists.
	read := PNGReadWriter formFromStream: file binaryReadStream.
	self assert: read extent equals: 4 @ 3.
	self assertColour: (read colorAt: 1 @ 1) isWithinOneUnitOf: (Color r: 0.1 g: 0.5 b: 0.9)
]

{ #category : 'support' }
VGCairoSurfaceTest >> translucentBlue [
	^ Color r: 0.0 g: 0.0 b: 1.0 alpha: 0.5
]

{ #category : 'support' }
VGCairoSurfaceTest >> translucentRed [
	"Half-transparent red and half-transparent blue are the pair the unit 1.1 gate paints, one over
	 the other."
	^ Color r: 1.0 g: 0.0 b: 0.0 alpha: 0.5
]
