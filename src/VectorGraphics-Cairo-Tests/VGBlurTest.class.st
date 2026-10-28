"
I gate unit 1.9: the Gaussian blur that a shadow is made of.

A shadow is an alpha-only surface with the element's geometry drawn on it and then blurred, so the blur is the whole of the picture's softness and a byte of difference is visible. Alexandrie blurs with three passes of a box blur, after the reference implementation its class comment names, and I hold our filter to Alexandrie's own output byte for byte on identical input, because the arithmetic is integer and deterministic and nothing about it has to be approximated.
"
Class {
	#name : 'VGBlurTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Cairo-Tests-Tests',
	#package : 'VectorGraphics-Cairo-Tests',
	#tag : 'Tests'
}

{ #category : 'private' }
VGBlurTest >> alexandrieSurfaceOfExtent: anExtent seededWith: aByteArray [
	| surface |
	surface := AeCairoImageSurface extent: anExtent format: AeCairoSurfaceFormat a8.
	aByteArray doWithIndex: [ :each :index | surface data unsignedByteAt: index put: each ].
	surface markDirty.
	^ surface
]

{ #category : 'private' }
VGBlurTest >> bytesOf: aSurface [
	^ (1 to: aSurface byteSize) collect: [ :each | aSurface data unsignedByteAt: each ]
]

{ #category : 'fixtures' }
VGBlurTest >> filterClass [
	"The filter every test of mine blurs with. A subclass answers the device filter here, so that
	 the whole of this class, Alexandrie comparisons and all, is run against it as well."

	^ VGA8GaussianBlurFilter
]

{ #category : 'oracles' }
VGBlurTest >> naiveBlurOf: aByteArray columns: aColumnCount rows: aRowCount sigma: aSigma [
	"The whole blur the slow way: each box radius of the sigma run once along the rows and once
	 down the columns, in the order the filter runs them."

	| source shape |
	source := aByteArray copy.
	shape := aColumnCount @ aRowCount.
	(self filterClass
		 boxRadiiForSigma: aSigma
		 passes: self filterClass defaultPassCount) do: [ :radius |
		source := self
			          naiveBoxOf: source
			          shape: shape
			          radius: radius
			          along: #rows.
		source := self
			          naiveBoxOf: source
			          shape: shape
			          radius: radius
			          along: #columns ].
	^ source
]

{ #category : 'oracles' }
VGBlurTest >> naiveBoxOf: aByteArray shape: aPoint radius: aRadius along: anAxis [
	"One box pass written the slow way: every pixel reads its own window, one byte at a time, with
	 the first and the last byte of the row or the column repeated outside. The filter walks the
	 same window as a running sum, which is cheaper and harder to read, so this is what holds it.
	 The x of the shape is the stride of the field in bytes and not its width, because that is the
	 row the bytes really sit in."

	| target diameter columnCount rowCount |
	columnCount := aPoint x.
	rowCount := aPoint y.
	target := aByteArray copy.
	diameter := aRadius + aRadius + 1.
	0 to: rowCount - 1 do: [ :row |
		0 to: columnCount - 1 do: [ :column |
			| sum |
			sum := 0.
			aRadius negated to: aRadius do: [ :offset |
				| x y |
				x := anAxis = #rows
					     ifTrue: [ (column + offset max: 0) min: columnCount - 1 ]
					     ifFalse: [ column ].
				y := anAxis = #rows
					     ifTrue: [ row ]
					     ifFalse: [ (row + offset max: 0) min: rowCount - 1 ].
				sum := sum + (aByteArray at: y * columnCount + x + 1) ].
			target
				at: row * columnCount + column + 1
				put: (self filterClass averageOfSum: sum overDiameter: diameter) ] ].
	^ target
]

{ #category : 'private' }
VGBlurTest >> ourSurfaceOfExtent: anExtent seededWith: aByteArray [
	| surface |
	surface := VGCairoImageSurface newFormat: VGCairoSurfaceFormat a8 extent: anExtent.
	aByteArray doWithIndex: [ :each :index | surface data unsignedByteAt: index put: each ].
	^ surface
]

{ #category : 'private' }
VGBlurTest >> seedBytesOfSize: anInteger [
	"A deterministic pattern with no symmetry of its own, so that a blur that reads a byte from the
	 wrong row cannot pass."

	^ (1 to: anInteger) collect: [ :each | each * 37 \\ 251 ]
]

{ #category : 'tests' }
VGBlurTest >> testARadiusOfZeroLeavesEveryByteAlone [
	| surface seed |
	seed := self seedBytesOfSize: 64.
	surface := self ourSurfaceOfExtent: 13 @ 4 seededWith: seed.
	self filterClass new
		surface: surface;
		applyRadius: 0.
	self assert: (self bytesOf: surface) asArray equals: seed asArray
]

{ #category : 'tests' }
VGBlurTest >> testASigmaOfZeroLeavesEveryByteAlone [
	| surface seed |
	seed := self seedBytesOfSize: 64.
	surface := self ourSurfaceOfExtent: 13 @ 4 seededWith: seed.
	self filterClass new
		surface: surface;
		applySigma: 0.
	self assert: (self bytesOf: surface) asArray equals: seed asArray
]

{ #category : 'tests' }
VGBlurTest >> testBlurringADotSpreadsItSymmetricallyAroundItself [
	"A single lit pixel in the middle of a square answers a figure symmetric in both axes, which is
	 the one property a Gaussian has that a wrongly indexed box pass loses."

	| surface extent middle bytes alphaAt |
	extent := 24 @ 24.
	middle := 12.
	surface := self ourSurfaceOfExtent: extent seededWith: (ByteArray new: 24 * 24).
	surface data unsignedByteAt: middle * 24 + middle + 1 put: 255.
	self filterClass new
		surface: surface;
		applySigma: 3.
	bytes := self bytesOf: surface.
	alphaAt := [ :x :y | bytes at: y * 24 + x + 1 ].
	1 to: 6 do: [ :step |
		self assert: (alphaAt value: middle + step value: middle) equals: (alphaAt value: middle - step value: middle).
		self assert: (alphaAt value: middle value: middle + step) equals: (alphaAt value: middle value: middle - step) ].
	self assert: (alphaAt value: middle value: middle) > (alphaAt value: middle + 3 value: middle)
]

{ #category : 'tests' }
VGBlurTest >> testBlurringAFieldOfOneValueLeavesItAlone [
	"A box pass of a constant field answers the same constant, because every window holds the same
	 value, and the edge handling repeats the first and the last sample rather than reading zero
	 outside. A blur that darkens a flat field is reading outside its own surface."

	| surface bytes |
	surface := self ourSurfaceOfExtent: 16 @ 12 seededWith: ((1 to: 16 * 12) collect: [ :each | 200 ]).
	self filterClass new
		surface: surface;
		applyRadius: 5.
	bytes := self bytesOf: surface.
	self assert: (bytes allSatisfy: [ :each | each = 200 ])
]

{ #category : 'tests' }
VGBlurTest >> testBlurringAWidthWithStridePaddingAgreesWithAlexandrieToo [
	"Cairo aligns the stride of an alpha surface to four bytes, so a width of thirteen carries three
	 padding bytes a row, and the blur runs along the stride rather than along the width. Those
	 padding bytes therefore take part, which bleeds the end of one row into the start of the next.
	 That is Alexandrie behaviour and not a choice of ours, and this test is here to say so: the
	 filter is held to the same bytes, padding and all."

	| seed ours theirs |
	seed := self seedBytesOfSize: 16 * 9.
	ours := self ourSurfaceOfExtent: 13 @ 9 seededWith: seed.
	theirs := self alexandrieSurfaceOfExtent: 13 @ 9 seededWith: seed.
	self assert: ours stride equals: 16.
	self filterClass new
		surface: ours;
		applyRadius: 6.
	AeCairoA8FastGaussianBlurFilter new
		surface: theirs;
		applyRadius: 6.
	self assert: (self bytesOf: ours) asArray equals: (self bytesOf: theirs) asArray
]

{ #category : 'tests' }
VGBlurTest >> testBlurringAgreesWithAlexandrieByteForByte [
	"The arithmetic is integer and deterministic, so there is nothing here to approximate: given
	 the same bytes, the same radius and the same number of passes, the two filters must write the
	 same bytes. The width is a multiple of four, so the stride carries no padding."

	| seed ours theirs |
	seed := self seedBytesOfSize: 16 * 12.
	ours := self ourSurfaceOfExtent: 16 @ 12 seededWith: seed.
	theirs := self alexandrieSurfaceOfExtent: 16 @ 12 seededWith: seed.
	self filterClass new
		surface: ours;
		applyRadius: 8.
	AeCairoA8FastGaussianBlurFilter new
		surface: theirs;
		applyRadius: 8.
	self assert: (self bytesOf: ours) asArray equals: (self bytesOf: theirs) asArray
]

{ #category : 'tests' }
VGBlurTest >> testTheBlurOfAFieldIsTheClampedWindowAverageOfEveryByte [
	"What a box pass writes is the average of its own window, the first and the last byte of the
	 row repeated outside it, and that average is a sum of bytes times the reciprocal of the
	 diameter, floored. The filter walks the window as a running sum, which is the same arithmetic
	 in a cheaper order. This test holds it to the window itself, computed one pixel at a time, and
	 so also holds averageOfSum:overDiameter: to the bytes the filter really writes: the device
	 reproduces that named arithmetic and must not be reading a rule nothing checks."

	| seed surface |
	seed := self seedBytesOfSize: 16 * 16.
	surface := self ourSurfaceOfExtent: 16 @ 16 seededWith: seed.
	self filterClass new
		surface: surface;
		applySigma: 4.
	self
		assert: (self bytesOf: surface) asArray
		equals: (self naiveBlurOf: seed columns: 16 rows: 16 sigma: 4) asArray
]

{ #category : 'tests' }
VGBlurTest >> testTheBoxRadiiOfASigmaAreTheOnesAlexandrieUses [
	"The three box radii are what makes three box passes approximate a Gaussian, so they are the
	 one number the filter cannot choose for itself. Alexandrie computes them from the reference
	 implementation and is asked for them here."

	#( 1 2 3 4.5 10 25 ) do: [ :sigma |
		| theirs |
		theirs := (AeCairoA8GaussianBlurFilter new boxRadiusStreamForSigma: sigma n: 3) upToEnd.
		self
			assert: (self filterClass boxRadiiForSigma: sigma passes: 3)
			equals: theirs asArray ]
]

{ #category : 'tests' }
VGBlurTest >> testTheFilterDrawsWhatTheSurfaceStillOwesBeforeItReadsAnyByte [
	"Our surface records a frame and draws it when something reads its pixels, which Alexandrie has
	 no equivalent of. A filter that read the bytes without draining the display list would blur
	 the frame before this one."

	| drawn flushed |
	drawn := VGCairoImageSurface newFormat: VGCairoSurfaceFormat a8 extent: 16 @ 12.
	drawn newContext
		sourceColorR: 0 g: 0 b: 0 a: 1;
		rectangleX: 4 y: 3 width: 7 height: 5;
		fill.
	flushed := VGCairoImageSurface newFormat: VGCairoSurfaceFormat a8 extent: 16 @ 12.
	flushed newContext
		sourceColorR: 0 g: 0 b: 0 a: 1;
		rectangleX: 4 y: 3 width: 7 height: 5;
		fill.
	flushed flush.
	self filterClass new
		surface: drawn;
		applyRadius: 4.
	self filterClass new
		surface: flushed;
		applyRadius: 4.
	self assert: (self bytesOf: drawn) asArray equals: (self bytesOf: flushed) asArray.
	self deny: ((self bytesOf: drawn) allSatisfy: [ :each | each = 0 ])
]

{ #category : 'tests' }
VGBlurTest >> testTheSigmaOfARadiusIsTheRatioAlexandrieShadowsUse [
	"A Bloc shadow names a width, Cairo blurs by a standard deviation, and the ratio between them
	 is the one Alexandrie settled on; the sigma is rounded to a whole number because the box
	 radii are integers anyway."

	#( 0 1 4 8 14 ) do: [ :radius |
		self
			assert: (self filterClass sigmaForRadius: radius)
			equals: (radius / self filterClass radiusToSigmaRatio) rounded ]
]
