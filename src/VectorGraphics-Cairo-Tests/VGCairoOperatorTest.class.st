"
I hold the facts of the twenty-nine Cairo compositing operators, every one of them measured on a live Cairo context: the code each one carries, what it writes over a known destination pixel at full coverage and at half, and which of them change a pixel no source covers.
"
Class {
	#name : 'VGCairoOperatorTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Cairo-Tests-Tests',
	#package : 'VectorGraphics-Cairo-Tests',
	#tag : 'Tests'
}

{ #category : 'measurements' }
VGCairoOperatorTest >> blendedChannelAllowance [
	"One step of a channel, which is what Cairo's own integer hue-saturation-luminosity
	 arithmetic leaves between its two routes to the same composite and between either of them
	 and the PDF formula. It is the allowance the surface tests already give a stray alpha."

	^ 1
]

{ #category : 'measurements' }
VGCairoOperatorTest >> cairoPixelForOperator: anOperator throughAlpha: anAlpha [
	"The pixel live Cairo writes when half of the source arrives as an alpha on the paint, which
	 Cairo folds into the colour and carries no mask for."

	| surface context |
	surface := AeCairoImageSurface extent: 2 @ 2.
	context := surface newContext.
	context
		sourceColor: self measuredDestinationColor;
		paint.
	context operator: (AeCairoOperator perform: anOperator operatorName).
	context sourceColor: self measuredSourceColor.
	context paintWithAlpha: anAlpha.
	surface flush.
	^ surface data uint32AtOffset: 0
]

{ #category : 'measurements' }
VGCairoOperatorTest >> cairoPixelForOperatorThroughGeometry: anOperator [
	"The pixel live Cairo writes when half of the source arrives as a rectangle covering half of
	 the pixel, which Cairo carries as a coverage mask."

	| surface context |
	surface := AeCairoImageSurface extent: 2 @ 2.
	context := surface newContext.
	context
		sourceColor: self measuredDestinationColor;
		paint.
	context operator: (AeCairoOperator perform: anOperator operatorName).
	context sourceColor: self measuredSourceColor.
	context
		rectangleX: 0 y: 0 width: 1 height: 0.5;
		fill.
	surface flush.
	^ surface data uint32AtOffset: 0
]

{ #category : 'running' }
VGCairoOperatorTest >> compositeForOperator: anOperator throughAlpha: anAlpha in: aFormat [
	"The pixel we write when a paint carries an alpha, by the same two routes Cairo has: the
	 operator says whether the alpha belongs in the paint's colour or in a mask."
	| colour paint mask |
	colour := self measuredSourceColor.
	anOperator foldsAnAlphaIntoThePaint
		ifTrue: [
			paint := VGColorPaint
				         r: colour red
				         g: colour green
				         b: colour blue
				         alpha: colour alpha * anAlpha.
			mask := 255 ]
		ifFalse: [
			paint := VGColorPaint color: colour.
			mask := aFormat shortByteOf: anAlpha ].
	^ anOperator
		  composeSource: (anOperator sourceFromPaint: paint in: aFormat atX: 0 y: 0)
		  mask: mask
		  over: self measuredDestinationPixel
		  in: aFormat
]

{ #category : 'measurements' }
VGCairoOperatorTest >> measuredDestinationColor [
	"The colour behind measuredDestinationPixel: a red at an alpha of a hundred and twenty-eight."

	^ Color r: 1 g: 0 b: 0 alpha: 128 / 255
]

{ #category : 'constants' }
VGCairoOperatorTest >> measuredDestinationPixel [
	"Half-transparent red, already on the surface when the operator runs."

	^ 16r80800000
]

{ #category : 'constants' }
VGCairoOperatorTest >> measuredFoldedPaintTable [
	"The first pair painted through an alpha of seven tenths, read off a live Cairo surface for
	 every operator. Cairo has two routes for that alpha and picks one by the operator: under
	 clear, source, in, out, destIn and destAtop it carries the alpha as a mask, and under the
	 other twenty-three it multiplies the paint's colour by it and paints with no mask at all.
	 The rows are what tells the two apart, so this table states the rule rather than the code
	 restating it."
	^ {
		  (#clear -> 16r26260000).
		  (#source -> 16r8026005A).
		  (#over -> 16rAC530059).
		  (#in -> 16r2D00002D).
		  (#out -> 16r2D00002D).
		  (#atop -> 16r8053002D).
		  (#dest -> 16r80800000).
		  (#destOver -> 16rAC80002C).
		  (#destIn -> 16r2D2D0000).
		  (#destOut -> 16r53530000).
		  (#destAtop -> 16r5A2D002D).
		  (#xor -> 16r7F53002C).
		  (#add -> 16rD9800059).
		  (#saturate -> 16rDA800059).
		  (#multiply -> 16rAC53002C).
		  (#screen -> 16rAC800059).
		  (#overlay -> 16rAC80002C).
		  (#darken -> 16rAC53002C).
		  (#lighten -> 16rAC800059).
		  (#colorDodge -> 16rAD80002C).
		  (#colorBurn -> 16rAD80002C).
		  (#hardLight -> 16rAC530059).
		  (#softLight -> 16rAD80002C).
		  (#difference -> 16rAC800059).
		  (#exclusion -> 16rAC800059).
		  (#hslHue -> 16rAD5C0959).
		  (#hslSaturation -> 16rAD80002C).
		  (#hslColor -> 16rAD5C0959).
		  (#hslLuminosity -> 16rAD63002C) }
]

{ #category : 'constants' }
VGCairoOperatorTest >> measuredFullCoverageTable [
	"What each operator writes over #measuredDestinationPixel when the whole pixel is covered by
	 #measuredSourcePixel. Every entry was read out of the raw ARGB32 bytes of a live Cairo
	 surface, one four by four surface an operator, painted with the destination colour and then
	 filled with an axis-aligned rectangle of the source colour."

	^ {
		  (#clear -> 16r00000000).
		  (#source -> 16r80000080).
		  (#over -> 16rC0400080).
		  (#in -> 16r40000040).
		  (#out -> 16r40000040).
		  (#atop -> 16r80400040).
		  (#dest -> 16r80800000).
		  (#destOver -> 16rC0800040).
		  (#destIn -> 16r40400000).
		  (#destOut -> 16r40400000).
		  (#destAtop -> 16r80400040).
		  (#xor -> 16r80400040).
		  (#add -> 16rFF800080).
		  (#saturate -> 16rFF80007F).
		  (#multiply -> 16rC0400040).
		  (#screen -> 16rC0800080).
		  (#overlay -> 16rC0800040).
		  (#darken -> 16rC0400040).
		  (#lighten -> 16rC0800080).
		  (#colorDodge -> 16rC080003F).
		  (#colorBurn -> 16rC080003F).
		  (#hardLight -> 16rC0400080).
		  (#softLight -> 16rC080003F).
		  (#difference -> 16rC0800080).
		  (#exclusion -> 16rC0800080).
		  (#hslHue -> 16rC04D0D80).
		  (#hslSaturation -> 16rC080003F).
		  (#hslColor -> 16rC04D0D80).
		  (#hslLuminosity -> 16rC057003F) }
]

{ #category : 'constants' }
VGCairoOperatorTest >> measuredHalvedPaintTable [
	"The first pair painted through an alpha of one half, read off a live Cairo surface. Under
	 clear and source, which carry the alpha as a mask, Cairo mixes the result with the
	 destination: that is why clear at half an alpha leaves half the destination standing rather
	 than clearing the pixel.
	 No hue-saturation-luminosity mode is in the table, because under a mask Cairo does not even
	 agree with itself about those four; that is what
	 testCairoDisagreesWithItselfOnAHueSaturationLuminosityModeUnderPartialCoverage states."
	^ {
		  (#clear -> 16r40400000).
		  (#source -> 16r80400040).
		  (#over -> 16rA0600040).
		  (#in -> 16r20000020).
		  (#out -> 16r20000020).
		  (#atop -> 16r80600020).
		  (#destIn -> 16r20200000).
		  (#destOut -> 16r60600000).
		  (#destAtop -> 16r40200020).
		  (#xor -> 16r80600020).
		  (#add -> 16rC0800040).
		  (#saturate -> 16rC0800040).
		  (#multiply -> 16rA0600020) }
]

{ #category : 'measurements' }
VGCairoOperatorTest >> measuredPaintAlpha [
	"The alpha the folded-paint table was measured through. Seven tenths is chosen because the two
	 routes Cairo has for a paint's alpha write different pixels at that value: folding it into the
	 colour gives the source an alpha of eighty-nine, carrying it as a mask gives it ninety, and
	 four of the operators read the difference."
	^ 0.7
]

{ #category : 'constants' }
VGCairoOperatorTest >> measuredSecondDestinationChannels [
	"The backdrop of the second measured pair, as the four channels themselves and not as a
	 Color: every channel of it differs from every other, so a mode that reads the channels apart
	 from each other cannot pass this pair by accident. A Pharo Color would not do, because it
	 keeps ten bits a channel and 0.2 is not one of them: driving live Cairo through a Color
	 writes a different pixel from this on twenty of the twenty-nine operators, the backdrop
	 itself included."
	^ #( 0.7 0.2 0.1 0.8 )
]

{ #category : 'constants' }
VGCairoOperatorTest >> measuredSecondDestinationPixel [
	"The pixel a live Cairo context lays down for measuredSecondDestinationChannels, which is
	 also what a solid paint of those channels quantises to through its four sixteen-bit shorts."
	^ 16rCC8F2814
]

{ #category : 'constants' }
VGCairoOperatorTest >> measuredSecondFullCoverageTable [
	"What each operator writes over measuredSecondDestinationPixel when the whole pixel is
	 covered by a solid paint of measuredSecondSourceColor. Read out of the raw ARGB32 bytes of a
	 live Cairo surface the same way measuredFullCoverageTable was: one four by four surface an
	 operator, painted with the destination colour and then filled with an axis-aligned rectangle
	 of the source colour."
	^ {
		  (#clear -> 16r00000000).
		  (#source -> 16r661E3D5C).
		  (#over -> 16rE0745568).
		  (#in -> 16r5218314A).
		  (#out -> 16r14060C12).
		  (#atop -> 16rCC6E4956).
		  (#dest -> 16rCC8F2814).
		  (#destOver -> 16rE0953426).
		  (#destIn -> 16r52391008).
		  (#destOut -> 16r7A56180C).
		  (#destAtop -> 16r663F1C1A).
		  (#xor -> 16r8E5C241E).
		  (#add -> 16rFFAD6570).
		  (#saturate -> 16rFF9E4642).
		  (#multiply -> 16rE06D2E25).
		  (#screen -> 16rE09C5B69).
		  (#overlay -> 16rE08B372D).
		  (#darken -> 16rE0743426).
		  (#lighten -> 16rE0955568).
		  (#colorDodge -> 16rE1AE4C6E).
		  (#colorBurn -> 16rE15C241E).
		  (#hardLight -> 16rE07D4162).
		  (#softLight -> 16rE18E3833).
		  (#difference -> 16rE07D4560).
		  (#exclusion -> 16rE08B5262).
		  (#hslHue -> 16rE1634457).
		  (#hslSaturation -> 16rE1953426).
		  (#hslColor -> 16rE1634457).
		  (#hslLuminosity -> 16rE1A64537) }
]

{ #category : 'constants' }
VGCairoOperatorTest >> measuredSecondSourceChannels [
	"The source of the second measured pair. Neither alpha is a half and no channel is zero,
	 which is what makes the pair worth measuring: the first pair sits on the rounding boundary
	 of every arithmetic at once and agrees with models that are wrong. Channels and not a
	 Color, for the reason measuredSecondDestinationChannels gives."
	^ #( 0.3 0.6 0.9 0.4 )
]

{ #category : 'measurements' }
VGCairoOperatorTest >> measuredSourceColor [
	"The colour behind measuredSourcePixel: a blue at an alpha of a hundred and twenty-eight."

	^ Color r: 0 g: 0 b: 1 alpha: 128 / 255
]

{ #category : 'constants' }
VGCairoOperatorTest >> measuredSourcePixel [
	"Half-transparent blue, premultiplied and quantised the way a solid colour is: this is the
	 pixel a live Cairo context lays down for r 0, g 0, b 1, alpha 0.5."

	^ 16r80000080
]

{ #category : 'running' }
VGCairoOperatorTest >> sourceForOperator: anOperator in: aFormat [
	"The source that operator asks for, from a solid paint of measuredSourceColor: a pixel word
	 for the twenty-one operators pixman composites on bytes and a wide pixel of four sixteen-bit
	 shorts for the eight it composites in floating point. The paint and not the pixel, because a
	 pixel word is all the precision a solid colour has lost. A Color serves this pair, whose
	 channels are a zero and a one and so exact in the ten bits a Pharo Color keeps."
	^ anOperator
		  sourceFromPaint: (VGColorPaint color: self measuredSourceColor)
		  in: aFormat
		  atX: 0
		  y: 0
]

{ #category : 'tests' }
VGCairoOperatorTest >> testAFillUnderAnUnboundedOperatorReportsTheWholeClipAsItsBoundingBox [
	"A fill under in, out, dest-in or dest-atop writes where its own shape covers nothing: it
	 takes the destination away outside the shape. The entry's bounding box is the dirty rectangle
	 of the frame and, from unit 2.2 on, the rectangle the binning reads, so a box that stops at
	 the shape loses every pixel the operator clears beyond it. VGBlitEntry already widens to the
	 clip for this reason."

	| surface context box outside alphaShift |
	alphaShift := 24.
	surface := VGCairoImageSurface extent: 40 @ 30.
	context := surface newContext.
	context sourceColorR: 1.0 g: 1.0 b: 1.0 a: 1.0.
	context paint.
	surface flush.
	outside := 35 @ 25.
	self
		assert: ((surface asForm pixelValueAt: outside) bitShift: alphaShift negated)
		equals: 255.
	context := surface newContext.
	context operator: VGCairoOperator in.
	context sourceColorR: 1.0 g: 0.0 b: 0.0 a: 1.0.
	context rectangleX: 5 y: 5 width: 10 height: 10.
	context fill.
	box := surface displayList boundingBox.
	surface flush.
	self
		assert: ((surface asForm pixelValueAt: outside) bitShift: alphaShift negated)
		equals: 0.
	self assert: (box containsPoint: outside).
	self assert: box equals: (0 @ 0 corner: 40 @ 30)
]

{ #category : 'tests' }
VGCairoOperatorTest >> testAnOperatorIsUnboundedExactlyWhenNoSourceStillChangesThePixel [
	"Cairo runs an operator over the whole clip and not only over the shape, which only shows on
	 the operators that write something where nothing is covered. The rule is not restated here:
	 each operator is asked what it writes at a mask of nothing, and that answer has to agree
	 with the flag the rasteriser reads."

	VGCairoOperator all do: [ :each |
		| untouched |
		untouched := each
			             composeSource: self measuredSourcePixel
			             mask: 0
			             over: self measuredDestinationPixel
			             in: VGCairoSurfaceFormat argb32.
		self
			assert: each isUnbounded = (untouched ~= self measuredDestinationPixel)
			description: each operatorName , ' disagrees with its own unbounded flag' ].
	self
		assert: ((VGCairoOperator all select: [ :each | each isUnbounded ]) collect: [ :each |
				 each operatorName ]) asSortedCollection asArray
		equals: #( #destAtop #destIn #in #out )
]

{ #category : 'tests' }
VGCairoOperatorTest >> testAnUnboundedOperatorClearsTheClipTheShapeMissesAndNothingOutsideIt [
	"Measured on a live Cairo context: under the in operator a fill of one pixel inside a clip of
	 sixteen leaves the other fifteen at nothing and the surface outside the clip exactly as it
	 was."

	| surface context |
	surface := VGCairoImageSurface extent: 8 @ 8.
	context := surface newContext.
	context
		sourceColorR: 1.0 g: 0.0 b: 0.0 a: 1.0;
		paint.
	context
		rectangleX: 2 y: 2 width: 4 height: 4;
		clip.
	context operator: VGCairoOperator in.
	context
		sourceColorR: 0.0 g: 0.0 b: 1.0 a: 0.5;
		rectangleX: 3 y: 3 width: 1 height: 1;
		fill.
	surface flush.
	self assert: (surface pixelAtX: 0 y: 0) equals: 16rFFFF0000.
	self assert: (surface pixelAtX: 3 y: 3) equals: 16r80000080.
	self assert: (surface pixelAtX: 5 y: 5) equals: 0.
	self assert: (surface pixelAtX: 2 y: 2) equals: 0
]

{ #category : 'tests' }
VGCairoOperatorTest >> testCairoDisagreesWithItselfOnAHueSaturationLuminosityModeUnderPartialCoverage [
	"Rendered live, both of them, because this is the one place where Cairo answers two different
	 pixels for the same intended composite: half of a translucent blue over a translucent red
	 under the luminosity mode. Through paint_with_alpha, which multiplies the colour and carries
	 no mask, it writes one pixel; through a rectangle covering half of the pixel, which carries a
	 coverage mask, it writes another, because the four hue-saturation-luminosity modes are
	 computed in premultiplied integer arithmetic that the mask enters differently. We follow the
	 route that scales the source, to within a step of a channel, which
	 testEveryBlendModeStaysWithinAStepOfLiveCairoUnderPartialCoverage holds every mode to. This
	 test fails if Cairo ever stops disagreeing, which would mean the divergence is ours to drop."

	self
		deny: (self cairoPixelForOperator: VGCairoOperator hslLuminosity throughAlpha: 128 / 255)
		equals: (self cairoPixelForOperatorThroughGeometry: VGCairoOperator hslLuminosity)
]

{ #category : 'tests' }
VGCairoOperatorTest >> testEveryBlendModeStaysWithinAStepOfLiveCairoUnderPartialCoverage [
	"The fifteen blend modes composite exactly as Cairo does at full coverage, which the measured
	 table states. Under partial coverage Cairo rounds some of them and truncates others, by mode
	 and by the route the coverage took, so this compares against a live render and allows the one
	 step those roundings differ by."
	| format |
	format := VGCairoSurfaceFormat argb32.
	(VGCairoOperator all select: [ :each | each isBlendMode ]) do: [ :operator |
		| ours reference complaint |
		reference := self cairoPixelForOperator: operator throughAlpha: 128 / 255.
		ours := operator
			        composeSource: (self sourceForOperator: operator in: format)
			        mask: 128
			        over: self measuredDestinationPixel
			        in: format.
		complaint := operator operatorName , ' wrote ' , (ours printStringBase: 16)
		             , ' where Cairo writes ' , (reference printStringBase: 16).
		self
			assert: (format alphaOfPixel: ours) = (format alphaOfPixel: reference)
			description: complaint.
		(format premultipliedChannelsOfPixel: ours)
			with: (format premultipliedChannelsOfPixel: reference)
			do: [ :channel :expected |
				self
					assert: (channel - expected) abs <= self blendedChannelAllowance
					description: complaint ] ]
]

{ #category : 'tests' }
VGCairoOperatorTest >> testEveryOperatorCarriesAPaintAlphaTheWayCairoDoes [
	"An alpha on a solid paint reaches the pixel by one of two routes, and which one it takes is
	 the operator's business: twenty-three of them let Cairo multiply the colour by the alpha and
	 paint with no mask, and six make it carry the alpha as a mask instead. The routes quantise
	 differently, so a wrong answer here is a pixel out."
	| format |
	format := VGCairoSurfaceFormat argb32.
	self measuredFoldedPaintTable do: [ :each |
		| operator written |
		operator := VGCairoOperator named: each key.
		written := self
			           compositeForOperator: operator
			           throughAlpha: self measuredPaintAlpha
			           in: format.
		self
			assert: written = each value
			description: operator operatorName , ' wrote ' , (written printStringBase: 16)
				, ' where Cairo writes ' , (each value printStringBase: 16) ]
]

{ #category : 'tests' }
VGCairoOperatorTest >> testEveryOperatorCarriesTheCodeCairoGivesIt [
	"The code is cairo_operator_t itself, so a phase two shader needs no translation table. The
	 numbers come from the live enumeration and not from a copy of it, and the count holds us to
	 the whole set."

	VGCairoOperator all do: [ :each |
		self
			assert: each code
			equals: (AeCairoOperator perform: each operatorName) value ].
	self assert: VGCairoOperator all size equals: AeCairoOperator enumDecl size / 2
]

{ #category : 'tests' }
VGCairoOperatorTest >> testEveryOperatorCompositesAHalvedPaintAsCairoDoes [
	"Half an alpha is the measurement that first showed the two routes apart: under clear and
	 source the pixel keeps half of the destination, which only a mask can do."
	| format |
	format := VGCairoSurfaceFormat argb32.
	self measuredHalvedPaintTable do: [ :each |
		| operator written |
		operator := VGCairoOperator named: each key.
		written := self compositeForOperator: operator throughAlpha: 0.5 in: format.
		self
			assert: written = each value
			description: operator operatorName , ' wrote ' , (written printStringBase: 16)
				, ' where Cairo writes ' , (each value printStringBase: 16) ]
]

{ #category : 'tests' }
VGCairoOperatorTest >> testEveryOperatorCompositesASecondMeasuredPairAsCairoDoes [
	"The whole operator set over a second measured pair. The source arrives from a solid paint
	 and not from a pixel word, because the operator decides what precision it needs the source
	 at: eight of the twenty-nine are composited by pixman in floating point, and those read the
	 sixteen-bit shorts a solid colour keeps rather than the eight bits a pixel keeps."
	| format paint |
	format := VGCairoSurfaceFormat argb32.
	paint := VGColorPaint
		         r: self measuredSecondSourceChannels first
		         g: (self measuredSecondSourceChannels at: 2)
		         b: (self measuredSecondSourceChannels at: 3)
		         alpha: (self measuredSecondSourceChannels at: 4).
	self measuredSecondFullCoverageTable do: [ :each |
		| operator written |
		operator := VGCairoOperator named: each key.
		written := operator
			           composeSource: (operator sourceFromPaint: paint in: format atX: 0 y: 0)
			           mask: 255
			           over: self measuredSecondDestinationPixel
			           in: format.
		self
			assert: written = each value
			description: each key , ' wrote ' , (written printStringBase: 16)
				, ' where Cairo writes ' , (each value printStringBase: 16) ]
]

{ #category : 'tests' }
VGCairoOperatorTest >> testEveryOperatorCompositesAtFullCoverageAsCairoDoes [
	"The whole operator set over one measured pair of pixels."
	| format |
	format := VGCairoSurfaceFormat argb32.
	self measuredFullCoverageTable do: [ :each |
		| operator written |
		operator := VGCairoOperator named: each key.
		written := operator
			           composeSource: (self sourceForOperator: operator in: format)
			           mask: 255
			           over: self measuredDestinationPixel
			           in: format.
		self
			assert: written = each value
			description: each key , ' wrote ' , (written printStringBase: 16)
				, ' where Cairo writes ' , (each value printStringBase: 16) ]
]

{ #category : 'tests' }
VGCairoOperatorTest >> testExactlyTheEightOperatorsPixmanDividesAreCompositedInFloatingPoint [
	"Pixman has an eight-bit combiner for twenty-one of the twenty-nine operators and only a
	 floating-point one for the other eight, which are the modes whose arithmetic divides: a
	 unified floating-point model was tried against all two hundred and sixty-one measured rows
	 and missed ninety-three of them, which is what proves the split. The eight are named here
	 because nothing in the arithmetic itself says which combiner pixman kept."
	| expected |
	expected := #( saturate colorDodge colorBurn softLight hslHue hslSaturation hslColor
		             hslLuminosity ) asSet.
	self
		assert:
		((VGCairoOperator all select: [ :each | each composesInFloatingPoint ]) collect: [ :each |
			 each operatorName ]) asSet = expected
]

{ #category : 'tests' }
VGCairoOperatorTest >> testTheOperatorStartsAtOverAndIsUnwoundWithTheState [
	"Over is Cairo's default operator, setOperatorClear is the one named shortcut Alexandrie
	 offers, and the operator belongs to the saved state like the matrix and the source."

	| context |
	context := (VGCairoImageSurface extent: 8 @ 8) newContext.
	self assert: context currentOperator equals: VGCairoOperator over.
	context restoreStateAfter: [
		context setOperatorClear.
		self assert: context currentOperator equals: VGCairoOperator clear ].
	self assert: context currentOperator equals: VGCairoOperator over
]
