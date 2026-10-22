"
I hold the clip stack of unit 1.6 to what a live Cairo context does.

Every fact here was measured against Cairo before it was written down: a clip composes with a fill
geometrically and not as a coverage mask, which is why clipping a circle and filling the same circle
answers the circle alone rather than its coverage squared; a clip of no path clips everything away
and leaves the status successful; a clip lives in device space, so a later transformation does not
move it; and the fill rule and the antialiasing mode in force at the clip verb belong to that clip
for the rest of its life.
"
Class {
	#name : 'VGCairoClipTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Cairo-Tests-Tests',
	#package : 'VectorGraphics-Cairo-Tests',
	#tag : 'Tests'
}

{ #category : 'helpers' }
VGCairoClipTest >> maskThroughACircleClipOn: aSurfaceClass [
	"The same script on either family: a mask that is opaque on its left half and half
	 translucent on its right half, painted through an antialiased circular clip."

	| surface context mask maskContext |
	mask := aSurfaceClass extent: 32 @ 32.
	maskContext := mask newContext.
	maskContext sourceColorR: 1.0 g: 1.0 b: 1.0 a: 1.0.
	maskContext
		rectangleX: 0 y: 0 width: 16 height: 32;
		fill.
	maskContext sourceColorR: 1.0 g: 1.0 b: 1.0 a: 0.5.
	maskContext
		rectangleX: 16 y: 0 width: 16 height: 32;
		fill.
	mask flush.
	surface := aSurfaceClass extent: 32 @ 32.
	context := surface newContext.
	context
		circleCenterX: 16 y: 16 radius: 10;
		clip.
	context sourceColorR: 0.0 g: 0.0 b: 1.0 a: 1.0.
	context maskSurface: mask x: 0 y: 0.
	surface flush.
	^ surface asForm
]

{ #category : 'helpers' }
VGCairoClipTest >> newSurface [
	^ VGCairoImageSurface extent: 32 @ 32
]

{ #category : 'helpers' }
VGCairoClipTest >> opaqueBlack [
	^ 16rFF000000
]

{ #category : 'helpers' }
VGCairoClipTest >> pixelsOf: aSurface [
	"Every pixel of a surface as one array, so two paintings can be compared byte for byte."

	^ (0 to: aSurface height - 1) inject: OrderedCollection new into: [ :all :y |
		  0 to: aSurface width - 1 do: [ :x | all add: (aSurface pixelAtX: x y: y) ].
		  all ]
]

{ #category : 'helpers' }
VGCairoClipTest >> ringPathOn: aContext [
	"One path of two squares wound the same way, so the even-odd rule leaves the inner square
	 hollow and the winding rule fills it. The fill rule a clip keeps is read off that hole."

	aContext rectangle: (4 @ 4 corner: 28 @ 28).
	aContext rectangle: (12 @ 12 corner: 20 @ 20)
]

{ #category : 'tests' }
VGCairoClipTest >> testAClipComposesGeometricallyWithAFillAndIsIdempotent [
	"Measured on a live Cairo context: clipping a circle and painting answers the same bytes as
	 filling that circle, with no pixel differing anywhere, and clipping the same circle twice or
	 three times answers them again. A clip is therefore an intersection of shapes and not a
	 coverage mask: multiplying coverages would square the shade of every edge pixel."

	| clipped filled twice |
	clipped := self newSurface.
	filled := self newSurface.
	twice := self newSurface.
	(clipped newContext)
		circleCenterX: 16 y: 16 radius: 10;
		clip;
		paint.
	(filled newContext) circleCenterX: 16 y: 16 radius: 10; fill.
	(twice newContext)
		circleCenterX: 16 y: 16 radius: 10;
		clip;
		circleCenterX: 16 y: 16 radius: 10;
		clip;
		paint.
	self assert: (self pixelsOf: clipped) equals: (self pixelsOf: filled).
	self assert: (self pixelsOf: twice) equals: (self pixelsOf: filled)
]

{ #category : 'tests' }
VGCairoClipTest >> testAClipEdgeAndAFillEdgeIntersectRatherThanMultiply [
	"Measured: a clip from 20.5 and a fill from 20.75 leave a quarter of pixel twenty, which is
	 16r40000000 for opaque black. Multiplying the two coverages would leave an eighth, and that
	 is the whole reason the clip intersects spans instead of scaling coverage."

	| surface |
	surface := self newSurface.
	(surface newContext)
		rectangle: (20.5 @ 0 corner: 32 @ 32);
		clip;
		rectangle: (20.75 @ 0 corner: 32 @ 32);
		fill.
	self assert: (surface pixelAtX: 20 y: 5) equals: 16r40000000.
	self assert: (surface pixelAtX: 21 y: 5) equals: self opaqueBlack
]

{ #category : 'tests' }
VGCairoClipTest >> testAClipIsFixedInDeviceSpaceAndNotMovedByALaterTransformation [
	"Measured: Cairo transforms a path as its verbs are sent, so the clip is a device-space shape
	 from then on. Translating by half the surface after the clip does not carry the clip along:
	 the paint that follows still lands in the left half."

	| surface context |
	surface := self newSurface.
	context := surface newContext.
	context
		rectangle: (0 @ 0 corner: 16 @ 32);
		clip.
	context translateBy: 16 @ 0.
	context paint.
	self assert: (surface pixelAtX: 8 y: 16) equals: self opaqueBlack.
	self assert: (surface pixelAtX: 24 y: 16) equals: 0.
	self assert: context currentClip equals: (0 @ 0 corner: 16 @ 32)
]

{ #category : 'tests' }
VGCairoClipTest >> testAClipKeepsTheFillRuleItWasMadeWith [
	"Measured: the fill rule in force at the clip verb belongs to that clip for the rest of its
	 life. A ring clipped under the even-odd rule stays hollow when the winding rule is asked for
	 afterwards, and the same ring clipped under the winding rule is solid."

	| hollow solid context |
	hollow := self newSurface.
	context := hollow newContext.
	context useFillRuleEvenOdd.
	self ringPathOn: context.
	context clip.
	context useFillRuleWinding.
	context paint.
	self assert: (hollow pixelAtX: 8 y: 16) equals: self opaqueBlack.
	self assert: (hollow pixelAtX: 16 y: 16) equals: 0.
	solid := self newSurface.
	context := solid newContext.
	context useFillRuleWinding.
	self ringPathOn: context.
	context clip.
	context useFillRuleEvenOdd.
	context paint.
	self assert: (solid pixelAtX: 16 y: 16) equals: self opaqueBlack
]

{ #category : 'tests' }
VGCairoClipTest >> testAClipNarrowedToARectangleAllowsWhatItAllowedInside [
	"A mask carries no spans, so the backend scales it by the coverage of the clip and walks the
	 clip to do it. Walking the whole clip for a mask the size of a glyph is what a text run costs,
	 so the walk is narrowed to the rectangle of the mask; the narrowed clip must allow exactly
	 what the clip allowed inside that rectangle and visit no row outside it."

	| clip narrowed rows |
	clip := VGClip bounds: (0 @ 0 corner: 64 @ 64).
	narrowed := clip narrowedTo: (10 @ 20 corner: 14 @ 23).
	self assert: narrowed bounds equals: (10 @ 20 corner: 14 @ 23).
	self assert: narrowed shapes equals: clip shapes.
	rows := OrderedCollection new.
	narrowed coverageRowsDo: [ :y :coverage :left |
		rows add: y.
		self assert: left equals: 10.
		self assert: coverage size equals: 4.
		coverage do: [ :each | self assert: each equals: 1.0 ] ].
	self assert: rows asArray equals: #( 20 21 22 )
]

{ #category : 'tests' }
VGCairoClipTest >> testAClipNarrowedToARectangleItDoesNotMeetAllowsNothing [
	"A mask that falls outside the clip has no pixel to be scaled into, and a clip of no area is
	 not walked at all, which is the degenerate case the narrowing has to answer plainly rather
	 than with a rectangle whose left is past its right."

	| clip narrowed rows |
	clip := VGClip bounds: (0 @ 0 corner: 10 @ 10).
	narrowed := clip narrowedTo: (20 @ 20 corner: 30 @ 30).
	self assert: narrowed isEmpty.
	rows := OrderedCollection new.
	narrowed coverageRowsDo: [ :y :coverage :left | rows add: y ].
	self assert: rows asArray isEmpty
]

{ #category : 'tests' }
VGCairoClipTest >> testAClipOfNoPathClipsEverythingAwayAndKeepsTheStatusSuccessful [
	"Measured: clipping with an empty path is not an error. Cairo answers a successful status and
	 clips everything away, so the paint that follows writes no pixel and the clip extents
	 collapse to the origin."

	| surface context |
	surface := self newSurface.
	context := surface newContext.
	context clip.
	self assert: context status isSuccess.
	context paint.
	self assert: (surface pixelAtX: 0 y: 0) equals: 0.
	self assert: (surface pixelAtX: 16 y: 16) equals: 0.
	self assert: context currentClip equals: (0 @ 0 corner: 0 @ 0)
]

{ #category : 'tests' }
VGCairoClipTest >> testAFractionalClipEdgeCarriesFractionalCoverage [
	"Measured: a clip edge at 20.5 pays for half of pixel twenty. Opaque black is stored there as
	 16r80000000, and the solid r 0.5 g 0.25 b 0.75 alpha 0.5, which is 16r7F3F1F5F whole, is
	 stored as 16r40201030: the coverage scales every channel of the quantised pixel."

	| black colour |
	black := self newSurface.
	(black newContext)
		rectangle: (20.5 @ 0 corner: 32 @ 32);
		clip;
		paint.
	self assert: (black pixelAtX: 20 y: 5) equals: 16r80000000.
	self assert: (black pixelAtX: 21 y: 5) equals: self opaqueBlack.
	colour := self newSurface.
	(colour newContext)
		sourceColor: (Color r: 0.5 g: 0.25 b: 0.75 alpha: 0.5);
		rectangle: (20.5 @ 0 corner: 32 @ 32);
		clip;
		paint.
	self assert: (colour pixelAtX: 20 y: 5) equals: 16r40201030.
	self assert: (colour pixelAtX: 21 y: 5) equals: 16r7F3F1F5F
]

{ #category : 'tests' }
VGCairoClipTest >> testAMaskThroughAnAntialiasedClipCarriesTheClipsOwnCoverage [
	"A mask surface is not geometry, so a clip cannot meet it span by span the way it meets a
	 fill. Cairo scales the mask by the coverage of the clip instead, which leaves the rim of the
	 clip shaded in the result rather than hard. Measured against a live Cairo surface."

	| comparison |
	comparison := VGFormComparison
		              between: (self maskThroughACircleClipOn: VGCairoImageSurface)
		              and: (self maskThroughACircleClipOn: AeCairoImageSurface).
	self assert: comparison isComparable.
	self assert: comparison extraneousPixelCount equals: 0.
	self
		assert: comparison maximumChannelDistance
				<= VGConformanceCorpus antialiasingTolerance
		description: 'the rim of the clip differs from Cairo by '
			, comparison maximumChannelDistance printString
]

{ #category : 'tests' }
VGCairoClipTest >> testARectangleClipKeepsNoShapeAndARoundedOneKeepsItsOwn [
	"A clip of a device-space rectangle is the common case a Bloc element builds, and it needs no
	 scan conversion at all: the clip is its own bounds and the rasteriser trims spans against
	 them. Anything else is kept as a shape and scanned, which is what a rounded rectangle needs
	 if its corners are to clip away: the pixel at 4@4 is inside the bounds and outside the
	 shape."

	| context rounded |
	context := self newSurface newContext.
	context
		rectangle: (4 @ 4 corner: 28 @ 28);
		clip.
	self assert: context currentClipShape isRectangular.
	rounded := self newSurface.
	context := rounded newContext.
	context
		roundedRectangleLeft: 4
		top: 4
		right: 28
		bottom: 28
		tl: 8
		tr: 8
		br: 8
		bl: 8;
		clip;
		paint.
	self deny: context currentClipShape isRectangular.
	self assert: context currentClip equals: (4 @ 4 corner: 28 @ 28).
	self assert: (rounded pixelAtX: 4 y: 4) equals: 0.
	self assert: (rounded pixelAtX: 16 y: 16) equals: self opaqueBlack
]

{ #category : 'tests' }
VGCairoClipTest >> testAnAliasedClipCoversWholePixelsAndKeepsThatModeAfterwards [
	"Measured: the antialiasing mode in force at the clip verb belongs to that clip, and an
	 aliased clip is sampled once at the centre of each pixel. A clip whose left edge falls at
	 20.5 covers pixel twenty whole, because the centre of that pixel is the edge itself and the
	 span is taken from its left edge inclusive; an edge at 20.75 leaves it alone. Asking for the
	 default mode again before the paint changes neither answer."

	| surface |
	#( #( 20.5 16rFF000000 ) #( 20.25 16rFF000000 ) #( 20.75 0 ) ) do: [ :each |
		surface := self newSurface.
		(surface newContext)
			antialias: #none;
			rectangle: ((each at: 1) @ 0 corner: 32 @ 32);
			clip;
			antialias: #default;
			paint.
		self assert: (surface pixelAtX: 19 y: 5) equals: 0.
		self assert: (surface pixelAtX: 20 y: 5) equals: (each at: 2).
		self assert: (surface pixelAtX: 21 y: 5) equals: self opaqueBlack ]
]

{ #category : 'tests' }
VGCairoClipTest >> testClipConsumesThePathAndClipPreservingPathKeepsIt [
	"Measured: after #clip the path is gone, so a fill that follows paints nothing; after
	 #clipPreservingPath the same path is still there and the fill paints it."

	| consumed kept |
	consumed := self newSurface.
	kept := self newSurface.
	(consumed newContext)
		rectangle: (8 @ 8 corner: 24 @ 24);
		clip;
		fill.
	(kept newContext)
		rectangle: (8 @ 8 corner: 24 @ 24);
		clipPreservingPath;
		fill.
	self assert: (consumed pixelAtX: 16 y: 16) equals: 0.
	self assert: (kept pixelAtX: 16 y: 16) equals: self opaqueBlack
]

{ #category : 'tests' }
VGCairoClipTest >> testClipExtentsAreThePathBoundsRoundedOutToWholePixels [
	"Measured on a live Cairo context: the clip extents are the bounds of the clipping path
	 rounded out to whole pixels, with the surface as the outer limit, so a clip whose right edge
	 falls at 20.5 reports twenty-one. The clip itself keeps the fraction, which is what pays for
	 half of pixel twenty; the extents are what a paint fills before the clip trims it. A fresh
	 context is limited by the surface alone and a clip of nothing collapses to the origin."

	| context |
	context := self newSurface newContext.
	self assert: context currentClip equals: (0 @ 0 corner: 32 @ 32).
	context
		rectangle: (-10 @ -10 corner: 20.5 @ 20);
		clip.
	self assert: context currentClip equals: (0 @ 0 corner: 21 @ 20).
	context
		circleCenterX: 16 y: 16 radius: 4;
		clip.
	self assert: context currentClip equals: (12 @ 12 corner: 20 @ 20).
	context
		rectangle: (100 @ 100 corner: 104 @ 104);
		clip.
	self assert: context currentClip equals: (0 @ 0 corner: 0 @ 0)
]

{ #category : 'tests' }
VGCairoClipTest >> testNestedClipsIntersectAndADisjointPairPaintsNothing [
	"Measured: two rectangles leave their overlap and nothing else, and two rectangles that do not
	 meet leave clip extents of the origin alone and paint no pixel at all."

	| overlap disjoint context |
	overlap := self newSurface.
	(overlap newContext)
		rectangle: (4 @ 4 corner: 20 @ 20);
		clip;
		rectangle: (12 @ 12 corner: 28 @ 28);
		clip;
		paint.
	self assert: (overlap pixelAtX: 16 y: 16) equals: self opaqueBlack.
	self assert: (overlap pixelAtX: 8 y: 8) equals: 0.
	self assert: (overlap pixelAtX: 24 y: 24) equals: 0.
	disjoint := self newSurface.
	context := disjoint newContext.
	context
		rectangle: (0 @ 0 corner: 8 @ 8);
		clip;
		rectangle: (16 @ 16 corner: 24 @ 24);
		clip;
		paint.
	self assert: context currentClip equals: (0 @ 0 corner: 0 @ 0).
	self assert: (self pixelsOf: disjoint) equals: (self pixelsOf: self newSurface)
]

{ #category : 'tests' }
VGCairoClipTest >> testRestoringTheStateUnwindsAClip [
	"Measured: a clip belongs to the saved state, so the paint inside the block is held to the
	 rectangle and the paint after it covers the whole surface again."

	| surface context |
	surface := self newSurface.
	context := surface newContext.
	context restoreStateAfter: [
		context
			rectangle: (0 @ 0 corner: 8 @ 8);
			clip.
		self assert: context currentClip equals: (0 @ 0 corner: 8 @ 8) ].
	self assert: context currentClip equals: surface boundsRectangle.
	context paint.
	self assert: (surface pixelAtX: 31 y: 31) equals: self opaqueBlack
]

{ #category : 'tests' }
VGCairoClipTest >> testTheClipAChainOfParentsBuildsIsTheIntersectionInDeviceSpace [
	"The shape BlElement >> #aeApplyClippingWithAllParentsOn: builds: from the root down it
	 translates by each parent's position, lays that parent's geometry on the path and clips, so
	 every clip is stated in the user space of its own parent and has to become one device-space
	 intersection. A root at 4@4 clipping twenty-four by twenty-four and a child at 6@6 clipping
	 sixteen by sixteen leave the device rectangle 10@10 corner 26@26."

	| surface context |
	surface := self newSurface.
	context := surface newContext.
	context translateBy: 4 @ 4.
	context
		rectangle: (0 @ 0 corner: 24 @ 24);
		clip.
	context translateBy: 6 @ 6.
	context
		rectangle: (0 @ 0 corner: 16 @ 16);
		clip.
	context paint.
	self assert: context currentClip equals: (10 @ 10 corner: 26 @ 26).
	self assert: (surface pixelAtX: 10 y: 10) equals: self opaqueBlack.
	self assert: (surface pixelAtX: 25 y: 25) equals: self opaqueBlack.
	self assert: (surface pixelAtX: 9 y: 10) equals: 0.
	self assert: (surface pixelAtX: 26 y: 25) equals: 0
]

{ #category : 'tests' }
VGCairoClipTest >> testTwoClipsAreTheSameAsOneClipAndAFillOfTheOther [
	"Measured: clipping a rectangle, clipping a circle and painting leaves exactly the pixels that
	 clipping the rectangle and filling the circle leaves, byte for byte. The clip stack is one
	 intersection however its terms arrive."

	| both oneAndFill |
	both := self newSurface.
	oneAndFill := self newSurface.
	(both newContext)
		rectangle: (8 @ 8 corner: 24 @ 30);
		clip;
		circleCenterX: 16 y: 16 radius: 10;
		clip;
		paint.
	(oneAndFill newContext)
		rectangle: (8 @ 8 corner: 24 @ 30);
		clip;
		circleCenterX: 16 y: 16 radius: 10;
		fill.
	self assert: (self pixelsOf: both) equals: (self pixelsOf: oneAndFill)
]
