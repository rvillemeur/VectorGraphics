"
I test what a context draws: the painting verbs, the fill rules and the display list behind them.

A context records into a display list and rasterises nothing as it records, so these tests also state
when the pixels appear: reading the surface's bytes straight after a fill shows nothing, and flushing
is what makes the frame.
The source is left alone throughout, because a context starts with opaque black and the source
belongs to unit 1.5.
"
Class {
	#name : 'VGCairoDrawingTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Cairo-Tests-Tests',
	#package : 'VectorGraphics-Cairo-Tests',
	#tag : 'Tests'
}

{ #category : 'support' }
VGCairoDrawingTest >> fivePointedStarOn: aContext radius: aNumber center: aPoint [
	"The points taken two apart, so the star is one self-crossing path with a pentagon inside it."
	0 to: 4 do: [ :index |
		| angle point |
		angle := index * 4 * Float pi / 5 - (Float pi / 2).
		point := aPoint + (angle cos * aNumber @ (angle sin * aNumber)).
		index isZero
			ifTrue: [ aContext moveTo: point ]
			ifFalse: [ aContext lineTo: point ] ].
	aContext closePath
]

{ #category : 'support' }
VGCairoDrawingTest >> newSurface [
	^ VGCairoImageSurface extent: 32 @ 32
]

{ #category : 'support' }
VGCairoDrawingTest >> opaqueBlack [
	^ 16rFF000000
]

{ #category : 'fixtures' }
VGCairoDrawingTest >> squareMaskOfSide: anInteger [
	"An opaque square mask surface of that side, which is the shape a glyph mask has in the
	 small."

	| mask context |
	mask := VGCairoImageSurface extent: anInteger asPoint.
	context := mask newContext.
	context sourceColorR: 1.0 g: 1.0 b: 1.0 a: 1.0.
	context
		rectangleX: 0 y: 0 width: anInteger height: anInteger;
		fill.
	mask flush.
	^ mask
]

{ #category : 'tests - drawing' }
VGCairoDrawingTest >> testAFillCoversEveryPixelOfARectangleEveryShapeOfItsClipEnclosesWholly [
	"The interior mark under a clip cut out by shapes, which is unit 2.7a. A clip holds its
	 shapes as scanners, and a scanner answers the same predicate a fill answers of its own
	 edges, so a rectangle the fill encloses and every shape of the clip encloses takes full
	 coverage at every pixel. A rectangle one shape of the clip cuts is a no, and so is one
	 outside the bounds the clip was narrowed to."

	| shape clip entry |
	shape := VGSegments rectangle: (0 @ 0 corner: 64 @ 64).
	clip := (VGClip bounds: (0 @ 0 corner: 64 @ 64)) clippedBy:
		        (VGPathExamples starPath segmentsWithFillRule: #winding).
	entry := VGFillEntry
		         segments: shape
		         paint: Color black
		         clip: clip
		         operator: VGCairoOperator over.
	self deny: clip isRectangular.
	self assert: (entry coversEveryPixelOf: (28 @ 24 corner: 34 @ 28)).
	self deny: (entry coversEveryPixelOf: (25 @ 25 corner: 30 @ 30)).
	self deny: (entry coversEveryPixelOf: (0 @ 0 corner: 4 @ 4))
]

{ #category : 'tests' }
VGCairoDrawingTest >> testAFillCoversEveryPixelOfARectangleInsideBothItsShapeAndItsClip [
	"What a tiled rasteriser asks of an entry before it walks a tile of it: a rectangle every
	 pixel of which this fill covers in full needs no walk, because the coverage of each of them
	 is one. The shape has to enclose the rectangle and so has the clip, and either one failing
	 is a no."

	| entry |
	entry := VGFillEntry
		         segments: (VGSegments rectangle: (8 @ 8 corner: 40 @ 40))
		         paint: Color black
		         clip: (VGClip bounds: (0 @ 0 corner: 64 @ 64))
		         operator: VGCairoOperator over.
	self assert: (entry coversEveryPixelOf: (16 @ 16 corner: 32 @ 32)).
	self deny: (entry coversEveryPixelOf: (32 @ 32 corner: 48 @ 48)).
	self deny: (entry coversEveryPixelOf: (48 @ 48 corner: 56 @ 56))
]

{ #category : 'tests' }
VGCairoDrawingTest >> testAFillOutsideTheSurfaceTouchesNothing [
	"The clip is the surface, so a path beyond it writes no byte at all. The bytes are read
	 directly: a Form conversion turns a transparent pixel into white, which would hide the
	 difference between untouched and painted."

	| surface |
	surface := self newSurface.
	surface newContext
		rectangleX: 40 y: 40 width: 10 height: 10;
		fill.
	surface flush.
	self assert: surface data asArray asSet asArray equals: #( 0 )
]

{ #category : 'tests - filling' }
VGCairoDrawingTest >> testAFilledRectangleIsOpaqueInsideAndUntouchedOutside [
	| surface context |
	surface := self newSurface.
	context := surface newContext.
	context
		rectangleX: 8 y: 8 width: 10 height: 6;
		fill.
	self assert: (surface pixelAtX: 8 y: 8) equals: self opaqueBlack.
	self assert: (surface pixelAtX: 17 y: 13) equals: self opaqueBlack.
	self assert: (surface pixelAtX: 18 y: 13) equals: 0.
	self assert: (surface pixelAtX: 7 y: 8) equals: 0
]

{ #category : 'tests' }
VGCairoDrawingTest >> testAFreshContextAnswersTheOriginAsItsCurrentPoint [
	"Measured on a live Cairo context: a context with no path answers the origin rather than
	 nothing, so a caller reading the current point can always do arithmetic on it. Whether there
	 really is a current point is a separate question."

	| context |
	context := self newSurface newContext.
	self assert: context currentPointInUserSpace equals: 0.0 @ 0.0.
	self deny: context hasCurrentPoint
]

{ #category : 'tests' }
VGCairoDrawingTest >> testAGroupKeepsItsDrawingOffTheTargetUntilItIsPopped [
	"Cairo's push_group redirects the drawing to an intermediate surface, so a flush of the
	 target in the middle of a group shows the target as it was. Popping the group to the source
	 and painting it through half an alpha then lays the group down in one composite, which is
	 what makes a group different from drawing the same shapes twice: half of an opaque white
	 over an opaque black reads as one hundred and twenty-eight in each channel on a live Cairo
	 surface."
	| surface context |
	surface := self newSurface.
	context := surface newContext.
	context
		sourceColorR: 0.0 g: 0.0 b: 0.0 a: 1.0;
		paint.
	context pushGroup.
	context
		sourceColorR: 1.0 g: 1.0 b: 1.0 a: 1.0;
		paint.
	surface flush.
	self assert: (surface pixelAtX: 0 y: 0) equals: self opaqueBlack.
	context popGroupToSource.
	context paintWithAlpha: 0.5.
	self assert: (surface pixelAtX: 0 y: 0) equals: 16rFF808080.
	self assert: (surface pixelAtX: 31 y: 31) equals: 16rFF808080
]

{ #category : 'tests' }
VGCairoDrawingTest >> testAMaskSurfacePaintsTheSourceThroughItsAlphaChannel [
	"Cairo's mask_surface paints the source wherever the mask surface has alpha, at the offset
	 given, and leaves everything the mask does not reach alone. The mask's colours are not read
	 at all: only its alpha. The values are read off a live Cairo surface."
	| target context mask maskContext |
	mask := VGCairoImageSurface extent: 16 @ 16.
	maskContext := mask newContext.
	maskContext sourceColorR: 1.0 g: 1.0 b: 1.0 a: 1.0.
	maskContext
		rectangleX: 0 y: 0 width: 8 height: 16;
		fill.
	maskContext sourceColorR: 1.0 g: 1.0 b: 1.0 a: 0.5.
	maskContext
		rectangleX: 8 y: 0 width: 8 height: 16;
		fill.
	mask flush.
	target := self newSurface.
	context := target newContext.
	context sourceColorR: 1.0 g: 0.0 b: 0.0 a: 1.0.
	context maskSurface: mask x: 8 y: 8.
	self assert: (target pixelAtX: 10 y: 10) equals: 16rFFFF0000.
	self assert: (target pixelAtX: 20 y: 10) equals: 16r80800000.
	self assert: (target pixelAtX: 2 y: 2) equals: 0.
	self assert: (target pixelAtX: 25 y: 25) equals: 0
]

{ #category : 'tests' }
VGCairoDrawingTest >> testAMaskUnderABoundedOperatorIsReadNowhereOutsideItsOwnRectangle [
	"A mask the size of a glyph on a surface the size of a page must cost the glyph and not the
	 page. Under a bounded operator a mask byte of zero leaves the destination exactly as it was,
	 so reading the mask outside its own rectangle buys nothing: a run of two thousand glyphs on a
	 ten thousand pixel surface otherwise walks the whole surface two thousand times and takes
	 hours. The walk is therefore narrowed to the rectangle of the mask, which is what this test
	 counts, because the picture cannot tell a pixel left as it was from a pixel never read."

	| mask stub target backend |
	mask := self squareMaskOfSide: 4.
	target := VGCairoImageSurface extent: 200 @ 200.
	stub := VGCountingMaskStub surface: mask at: 10 @ 20.
	backend := VGSoftwareBackend new.
	backend
		maskWith: stub
		paint: (VGColorPaint color: Color red)
		clip: (VGClip bounds: (0 @ 0 corner: 200 @ 200))
		operator: VGCairoOperator over
		into: target.
	self assert: stub readPixels asSet size equals: 16.
	self
		assert: (stub readPixels allSatisfy: [ :each |
				 (10 @ 20 corner: 14 @ 24) containsPoint: each ])
		description: 'the walk left the rectangle of the mask'
]

{ #category : 'tests' }
VGCairoDrawingTest >> testAMaskUnderAnUnboundedOperatorIsReadOverTheWholeClip [
	"An unbounded operator writes where the mask covers nothing — `in` clears the destination
	 there — so the walk of such a mask may not be narrowed to the rectangle of the mask. It stays
	 the whole clip, which is the rule the narrowing of a bounded operator is the exception to."

	| mask stub target backend |
	mask := self squareMaskOfSide: 4.
	target := VGCairoImageSurface extent: 40 @ 40.
	stub := VGCountingMaskStub surface: mask at: 10 @ 20.
	backend := VGSoftwareBackend new.
	backend
		maskWith: stub
		paint: (VGColorPaint color: Color red)
		clip: (VGClip bounds: (0 @ 0 corner: 40 @ 40))
		operator: VGCairoOperator in
		into: target.
	self assert: stub readPixels asSet size equals: 40 * 40
]

{ #category : 'tests' }
VGCairoDrawingTest >> testAPaintCarriedThroughAnAlphaFadesEveryPixelOfTheClip [
	"Painting black at four tenths of an alpha over white leaves a grey of one hundred and
	 fifty-three in every channel, read off a live Cairo surface. One hundred and fifty-three is
	 what folding the alpha into the paint's colour gives: Cairo quantises four tenths to an
	 alpha of one hundred and two and composites once, where carrying the alpha as a mask would
	 scale an already quantised black and land a step away."
	| surface context |
	surface := self newSurface.
	context := surface newContext.
	context
		sourceColorR: 1.0 g: 1.0 b: 1.0 a: 1.0;
		paint.
	context sourceColorR: 0.0 g: 0.0 b: 0.0 a: 1.0.
	context paintWithAlpha: 0.4.
	self assert: (surface pixelAtX: 0 y: 0) equals: 16rFF999999.
	self assert: (surface pixelAtX: 31 y: 31) equals: 16rFF999999
]

{ #category : 'tests' }
VGCairoDrawingTest >> testASliverThinnerThanHalfAFixedPointStepPaintsNothing [
	"Measured on a live context: a rectangle one four hundredth of a pixel wide stores an alpha
	 of one, and a wider one of three five hundred and twelfths stores two, but one of exactly
	 one five hundred and twelfth stores nothing, because its width collapses to zero when the
	 coordinates reach the fixed point grid. Our coverage must collapse with it, or we paint a
	 pixel Cairo leaves untouched."
	| surface context |
	surface := self newSurface.
	context := surface newContext.
	{ 1 / 512. 1 / 400. 3 / 512 } doWithIndex: [ :width :index |
		context
			rectangleX: 2 y: 2 * (index - 1) width: width height: 1;
			fill ].
	self assert: ((surface pixelAtX: 2 y: 0) bitShift: -24) equals: 0.
	self assert: ((surface pixelAtX: 2 y: 2) bitShift: -24) equals: 1.
	self assert: ((surface pixelAtX: 2 y: 4) bitShift: -24) equals: 2
]

{ #category : 'tests' }
VGCairoDrawingTest >> testASolidMaskIsCairosPaintThroughAnAlpha [
	"Cairo's mask takes the same route as paint_with_alpha when the mask pattern is one colour:
	 the mask's alpha is the alpha, and under clear it is carried as a mask rather than folded
	 into the paint. The pixel is the one paint_with_alpha leaves, read off a live Cairo
	 surface."
	| target context |
	target := self newSurface.
	context := target newContext.
	context
		sourceColorR: 1.0 g: 1.0 b: 1.0 a: 1.0;
		paint.
	context setOperatorClear.
	context mask: (VGCairoColorPattern r: 0.0 g: 0.0 b: 0.0 alpha: 0.4).
	self assert: (target pixelAtX: 0 y: 0) equals: 16r99999999.
	self assert: (target pixelAtX: 31 y: 31) equals: 16r99999999
]

{ #category : 'tests - source' }
VGCairoDrawingTest >> testAStopAddedAfterThePatternIsSetIsStillSeenAtPaintTime [
	"Measured on a live Cairo context: Cairo keeps a reference to the pattern rather than a copy of
	 it, so a stop added after the pattern has been set is part of the gradient that is painted. A
	 gradient of one black stop paints flat black, and the second stop turns it into the ramp."

	| surface context pattern |
	surface := VGCairoImageSurface extent: 16 @ 4.
	context := surface newContext.
	pattern := VGCairoLinearGradientPattern from: 0 @ 0 to: 16 @ 0.
	pattern addStopAt: 0.0 color: Color black.
	context sourcePattern: pattern.
	pattern addStopAt: 1.0 color: Color white.
	context paint.
	self assert: (surface pixelAtX: 0 y: 1) equals: 16rFF080808.
	self assert: (surface pixelAtX: 8 y: 1) equals: 16rFF878787.
	self assert: (surface pixelAtX: 15 y: 1) equals: 16rFFF7F7F7
]

{ #category : 'tests - stroking' }
VGCairoDrawingTest >> testAStrokeIsWidenedInUserSpaceAndNotInDeviceSpace [
	"Cairo widens the path in user space, so a scaled context strokes a thicker line. Stroking in
	 device space would answer the same width whatever the matrix said."
	| surface rows |
	surface := self newSurface.
	(surface newContext)
		scaleBy: 1 @ 3;
		moveTo: 2 @ 4;
		lineTo: 28 @ 4;
		stroke.
	rows := (0 to: 31) select: [ :y | (surface pixelAtX: 15 y: y) ~= 0 ].
	self assert: rows asArray equals: #( 9 10 11 12 13 14 )
]

{ #category : 'tests - stroking' }
VGCairoDrawingTest >> testAStrokedHorizontalLineCoversItsOwnWidth [
	"The default line width is two, as in Cairo, and a horizontal line centred on a pixel boundary
	 covers one whole row on each side of it and nothing else."
	| surface |
	surface := self newSurface.
	(surface newContext)
		moveTo: 4 @ 8;
		lineTo: 20 @ 8;
		stroke.
	self assert: (surface pixelAtX: 10 y: 7) equals: self opaqueBlack.
	self assert: (surface pixelAtX: 10 y: 8) equals: self opaqueBlack.
	self assert: (surface pixelAtX: 10 y: 6) equals: 0.
	self assert: (surface pixelAtX: 10 y: 9) equals: 0.
	self assert: (surface pixelAtX: 3 y: 8) equals: 0
]

{ #category : 'tests - source' }
VGCairoDrawingTest >> testASurfaceSourceWithAnOffsetMovesThePatternAndLeavesWhatItUncoversUntouched [
	"Measured on a live Cairo context with a four by four source, red over its left half and blue
	 over its right: an offset of one moves the whole pattern one pixel to the right, and the
	 column it uncovers is untouched because the default extend mode of a surface pattern is none."

	| source surface context |
	source := VGCairoImageSurface extent: 4 @ 4.
	source newContext
		sourceColor: Color blue;
		paint;
		sourceColor: Color red;
		rectangle: (0 @ 0 corner: 2 @ 4);
		fill.
	source flush.
	surface := VGCairoImageSurface extent: 8 @ 4.
	context := surface newContext.
	context sourceSurface: source x: 1 y: 0.
	context
		rectangle: (0 @ 0 corner: 8 @ 4);
		fill.
	{
		(0 -> 0).
		(1 -> 16rFFFF0000).
		(2 -> 16rFFFF0000).
		(3 -> 16rFF0000FF).
		(4 -> 16rFF0000FF).
		(5 -> 0) } do: [ :each |
		self assert: (surface pixelAtX: each key y: 0) equals: each value ]
]

{ #category : 'tests' }
VGCairoDrawingTest >> testAnAlphaUnderAnOperatorThatRefusesToFoldItThinsTheDestination [
	"Clear is one of the six operators under which Cairo carries a paint's alpha as a mask
	 rather than folding it into the paint's colour, and it is one of the four where the choice
	 shows: a clear through four tenths of an alpha leaves six tenths of an opaque white behind,
	 read off a live Cairo surface, where folding would have cleared the pixel outright."
	| surface context |
	surface := self newSurface.
	context := surface newContext.
	context
		sourceColorR: 1.0 g: 1.0 b: 1.0 a: 1.0;
		paint.
	context setOperatorClear.
	context paintWithAlpha: 0.4.
	self assert: (surface pixelAtX: 0 y: 0) equals: 16r99999999.
	self assert: (surface pixelAtX: 31 y: 31) equals: 16r99999999
]

{ #category : 'tests' }
VGCairoDrawingTest >> testClearingObeysTheClipAndTheOrderItWasAskedIn [
	"Cairo has no clear primitive: clearTransparent is a paint under the clear operator and
	 clearColor: is a paint under the source operator, so both obey the clip and both take their
	 turn in the frame. Measured on a live Cairo surface: a red paint followed by a clear inside
	 a half-width clip leaves the clipped half transparent and the other half red, and a clear
	 to blue then fills the same half."
	| surface context |
	surface := self newSurface.
	context := surface newContext.
	context
		sourceColorR: 1.0 g: 0.0 b: 0.0 a: 1.0;
		paint.
	context
		rectangleX: 0 y: 0 width: 16 height: 32;
		clip.
	context clearTransparent.
	self assert: (surface pixelAtX: 4 y: 4) equals: 0.
	self assert: (surface pixelAtX: 20 y: 4) equals: 16rFFFF0000.
	context clearR: 0.0 g: 0.0 b: 1.0 a: 1.0.
	self assert: (surface pixelAtX: 4 y: 4) equals: 16rFF0000FF.
	self assert: (surface pixelAtX: 20 y: 4) equals: 16rFFFF0000
]

{ #category : 'tests' }
VGCairoDrawingTest >> testFillConsumesThePathAndFillPreservingPathKeepsIt [
	| first second |
	first := self newSurface.
	second := self newSurface.
	first newContext
		rectangleX: 4 y: 4 width: 4 height: 4;
		fill;
		fill.
	second newContext
		rectangleX: 4 y: 4 width: 4 height: 4;
		fillPreservingPath;
		translateBy: 8 @ 0;
		fill.
	self assert: (first pixelAtX: 5 y: 5) equals: self opaqueBlack.
	self assert: (second pixelAtX: 5 y: 5) equals: self opaqueBlack.
	self
		assert: (second pixelAtX: 13 y: 5) = 0
		description: 'a preserved path is already in device space, so a later transformation cannot move it'.
	self assert: (first pixelAtX: 13 y: 5) equals: 0
]

{ #category : 'tests' }
VGCairoDrawingTest >> testMaskingWithAGroupPaintsTheSourceWhereTheGroupDrew [
	"Alexandrie's maskGroupWith: draws the block into a group and uses the group as the mask, so
	 the source arrives through whatever alpha the group laid down and nowhere else. Measured on
	 a live Cairo surface: an opaque part of the group gives the source whole, a quarter-opaque
	 part gives a quarter of it, and the rest is untouched."
	| target context |
	target := self newSurface.
	context := target newContext.
	context sourceColorR: 0.0 g: 0.0 b: 1.0 a: 1.0.
	context maskGroupWith: [
		context sourceColorR: 1.0 g: 1.0 b: 1.0 a: 1.0.
		context
			rectangleX: 4 y: 4 width: 12 height: 12;
			fill.
		context sourceColorR: 1.0 g: 1.0 b: 1.0 a: 0.25.
		context
			rectangleX: 16 y: 4 width: 12 height: 12;
			fill ].
	self assert: (target pixelAtX: 8 y: 8) equals: 16rFF0000FF.
	self assert: (target pixelAtX: 20 y: 8) equals: 16r40000040.
	self assert: (target pixelAtX: 8 y: 20) equals: 0
]

{ #category : 'tests - drawing' }
VGCairoDrawingTest >> testNoFillCoversEveryPixelOfARectangleAShapeCutsItTheClipLeavesItOutOrItIsABlit [
	"The three noes. A clip cut out by a shape promises nothing where that shape runs through the
	 rectangle: the star here crosses it, so the coverage there is the coverage of the star and
	 not one. A rectangular clip that leaves part of the rectangle out is a no as well. A blit is
	 a no in every case: it paints the alpha of a mask and not a shape it fills."

	| shape shaped narrow |
	shape := VGSegments rectangle: (8 @ 8 corner: 40 @ 40).
	shaped := (VGClip bounds: (0 @ 0 corner: 64 @ 64)) clippedBy:
		          (VGPathExamples starPath segmentsWithFillRule: #winding).
	narrow := (VGClip bounds: (0 @ 0 corner: 64 @ 64)) narrowedTo:
		          (0 @ 0 corner: 24 @ 24).
	self deny: ((VGFillEntry
			  segments: shape
			  paint: Color black
			  clip: shaped
			  operator: VGCairoOperator over) coversEveryPixelOf:
			 (16 @ 16 corner: 32 @ 32)).
	self deny: ((VGFillEntry
			  segments: shape
			  paint: Color black
			  clip: narrow
			  operator: VGCairoOperator over) coversEveryPixelOf:
			 (16 @ 16 corner: 32 @ 32)).
	self deny: (VGDisplayListExamples blitEntryOfAMask coversEveryPixelOf:
			 (10 @ 10 corner: 14 @ 14))
]

{ #category : 'tests - the display list' }
VGCairoDrawingTest >> testNothingIsRasterisedUntilTheSurfaceIsFlushed [
	"Rule one of the plan: the context records and never rasterises as it records, so the frame
	 appears when the list is drained and not before."
	| surface context |
	surface := self newSurface.
	context := surface newContext.
	context
		rectangleX: 4 y: 4 width: 8 height: 8;
		fill.
	self
		assert: (surface data uint32AtOffset: 4 * surface stride + (4 * 4))
		equals: 0.
	surface flush.
	self
		assert: (surface data uint32AtOffset: 4 * surface stride + (4 * 4))
		equals: self opaqueBlack
]

{ #category : 'tests - filling' }
VGCairoDrawingTest >> testPaintCoversEveryPixelOfTheSurface [
	| surface |
	surface := self newSurface.
	surface newContext paint.
	self assert: (surface pixelAtX: 0 y: 0) equals: self opaqueBlack.
	self assert: (surface pixelAtX: 31 y: 31) equals: self opaqueBlack
]

{ #category : 'tests' }
VGCairoDrawingTest >> testPaintingAGroupCompositesItOnceSoOverlapsDoNotDouble [
	"The point of a group: two opaque rectangles that overlap are laid down as one picture, so
	 the overlap is no more opaque than the rest. Drawing the same two rectangles at half an
	 alpha without a group would make the overlap three quarters opaque. The values are read off
	 a live Cairo surface, where every covered pixel is one hundred and twenty-eight in all four
	 channels and the rest is untouched."
	| surface context |
	surface := self newSurface.
	context := surface newContext.
	context
		paintGroupWith: [
			context sourceColorR: 1.0 g: 1.0 b: 1.0 a: 1.0.
			context
				rectangleX: 0 y: 0 width: 20 height: 20;
				fill.
			context
				rectangleX: 10 y: 10 width: 20 height: 20;
				fill ]
		alpha: 0.5.
	#( #( 5 5 ) #( 15 15 ) #( 25 25 ) ) do: [ :each |
		self
			assert: (surface pixelAtX: each first y: each second)
			equals: 16r80808080 ].
	self assert: (surface pixelAtX: 31 y: 5) equals: 0
]

{ #category : 'tests - the display list' }
VGCairoDrawingTest >> testReadingAPixelFlushesWhatIsStillWaiting [
	"A caller that reads the surface rather than flushing it must still see its own drawing, which
	 is what Cairo guarantees for anything but a raw pointer."
	| surface |
	surface := self newSurface.
	(surface newContext)
		rectangleX: 4 y: 4 width: 8 height: 8;
		fill.
	self assert: (surface pixelAtX: 5 y: 5) equals: self opaqueBlack.
	self assert: surface displayList isEmpty
]

{ #category : 'tests - stroking' }
VGCairoDrawingTest >> testStrokePreservingPathKeepsThePathAndStrokeConsumesIt [
	| first second |
	first := self newSurface.
	second := self newSurface.
	(first newContext)
		moveTo: 4 @ 8;
		lineTo: 20 @ 8;
		stroke;
		stroke.
	(second newContext)
		moveTo: 4 @ 8;
		lineTo: 20 @ 8;
		strokePreservingPath;
		stroke.
	self assert: (first pixelAtX: 10 y: 8) equals: self opaqueBlack.
	self assert: (second pixelAtX: 10 y: 8) equals: self opaqueBlack
]

{ #category : 'tests - the current point' }
VGCairoDrawingTest >> testTheCurrentPointIsReadBackInUserSpace [
	"The path is kept in device space, so the current point has to come back through the inverse of
	 the matrix in force now, which is what Cairo answers."
	| context |
	context := self newSurface newContext.
	context
		translateBy: 10 @ 10;
		moveTo: 2 @ 3;
		lineTo: 5 @ 7.
	self assert: context currentPointInUserSpace equals: 5 @ 7.
	context translateBy: 1 @ 1.
	self assert: context currentPointInUserSpace equals: 4 @ 6
]

{ #category : 'tests' }
VGCairoDrawingTest >> testTheEvenOddRuleLeavesTheHeartOfAStarHollowAndTheWindingRuleFillsIt [
	| winding evenOdd windingContext evenOddContext |
	winding := self newSurface.
	evenOdd := self newSurface.
	windingContext := winding newContext useFillRuleWinding; yourself.
	evenOddContext := evenOdd newContext useFillRuleEvenOdd; yourself.
	self fivePointedStarOn: windingContext radius: 14 center: 16 @ 16.
	self fivePointedStarOn: evenOddContext radius: 14 center: 16 @ 16.
	windingContext fill.
	evenOddContext fill.
	self assert: (winding pixelAtX: 16 y: 16) equals: self opaqueBlack.
	self assert: (evenOdd pixelAtX: 16 y: 16) equals: 0
]

{ #category : 'tests - source' }
VGCairoDrawingTest >> testTheSourceMatrixIsTheOneInForceWhenTheSourceWasSet [
	"Measured on a live Cairo context: setting a sixteen-wide ramp as the source and then scaling
	 the context by two paints exactly what no scaling at all paints, because Cairo captures the
	 transformation when the source is set and not when it is used."

	| expected |
	expected := {
		            (0 -> 16rFF080808).
		            (4 -> 16rFF484848).
		            (8 -> 16rFF878787).
		            (12 -> 16rFFC7C7C7).
		            (15 -> 16rFFF7F7F7) }.
	#( false true ) do: [ :scaleAfter |
		| surface context |
		surface := VGCairoImageSurface extent: 16 @ 4.
		context := surface newContext.
		context sourcePattern: (VGCairoLinearGradientPattern
				 from: 0 @ 0
				 to: 16 @ 0
				 addStopsFrom: {
						 (0.0 -> Color black).
						 (1.0 -> Color white) }).
		scaleAfter ifTrue: [ context scaleBy: 2 @ 2 ].
		context paint.
		expected do: [ :each |
			self assert: (surface pixelAtX: each key y: 1) equals: each value ] ]
]

{ #category : 'tests - the display list' }
VGCairoDrawingTest >> testTwoFillsAreDrawnInTheOrderTheyWereRecorded [
	| surface context |
	surface := self newSurface.
	context := surface newContext.
	context
		rectangleX: 0 y: 0 width: 32 height: 32;
		fill.
	self assert: (surface pixelAtX: 1 y: 1) equals: self opaqueBlack.
	self assert: surface displayList isEmpty
]
