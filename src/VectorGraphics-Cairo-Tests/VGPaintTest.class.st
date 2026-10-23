"
I hold the tests of the paint ABI, the frozen hand-over between the drawing API and the backend.

A paint is a tag, a block of thirty-two-bit floats and, for a gradient, a list of stops. My tests read the block field by field, so a change of layout fails here rather than in a picture, and they check every paint against values measured on a live Cairo context.
"
Class {
	#name : 'VGPaintTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Cairo-Tests-Tests',
	#package : 'VectorGraphics-Cairo-Tests',
	#tag : 'Tests'
}

{ #category : 'private' }
VGPaintTest >> blackToWhiteFrom: aPoint to: anotherPoint [
	^ (VGLinearGradientPaint from: aPoint to: anotherPoint)
		  addStopAt: 0.0 color: Color black;
		  addStopAt: 1.0 color: Color white;
		  yourself
]

{ #category : 'private' }
VGPaintTest >> channelsOf: anArray [
	"The four channels a picture would show for those unpremultiplied channels. A value measured
	 off a live Cairo surface has been through two steps: Cairo stores the pixel premultiplied and
	 rounded to a byte, and a reader divides the alpha back out and truncates. A test quoting a
	 measured number has to come back through the same two steps. A paint that paints nothing
	 answers nil, which is not a transparent colour: nothing is composited at all."

	| format word alpha |
	anArray ifNil: [ ^ nil ].
	format := VGCairoSurfaceFormat argb32.
	word := format pixelForRgba: anArray.
	alpha := (word bitShift: -24) bitAnd: 255.
	alpha = 0 ifTrue: [ ^ #( 0 0 0 0 ) ].
	^ (({ 16. 8. 0 } collect: [ :shift |
		    (((word bitShift: shift negated) bitAnd: 255) * (255.0 / alpha)) asInteger ])
	   copyWith: alpha)
]

{ #category : 'private' }
VGPaintTest >> everyKindOfPaint [
	"One of each tag, so a test can hold the shape of the ABI without naming a layout."

	^ {
		  (VGColorPaint color: Color red).
		  (VGSurfacePaint surface: (VGCairoImageSurface extent: 4 @ 4)).
		  (VGLinearGradientPaint from: 0 @ 0 to: 64 @ 0).
		  (VGRadialGradientPaint
			   innerCenter: 0 @ 0
			   innerRadius: 0
			   outerCenter: 0 @ 0
			   outerRadius: 32) }
]

{ #category : 'private' }
VGPaintTest >> redAndBlueSurface [
	"Four pixels square: red over the top left quadrant, blue over the rest. Small enough that a
	 test can name every pixel it reads."

	| surface context |
	surface := VGCairoImageSurface extent: 4 @ 4.
	context := surface newContext.
	context sourceColor: Color blue.
	context paint.
	context sourceColor: Color red.
	context rectangle: (0 @ 0 corner: 2 @ 2).
	context fill.
	surface flush.
	^ surface
]

{ #category : 'tests' }
VGPaintTest >> testAColourPaintAnswersItsOwnColourAtEveryPoint [
	"A colour built from a Pharo Color carries that Color's ten-bit quantisation: a half reads 127
	 and not 128, which is what live Cairo writes for the same Color because Alexandrie hands it
	 the same four accessors. A colour built from floats keeps the half."

	| paint |
	paint := VGColorPaint color: (Color r: 1 g: 0 b: 0 alpha: 0.5).
	self assert: (self channelsOf: (paint rgbaAtX: 0.5 y: 0.5)) equals: #( 255 0 0 127 ).
	self
		assert: (self channelsOf: (paint rgbaAtX: 1000.5 y: -17.5))
		equals: (self channelsOf: (paint rgbaAtX: 0.5 y: 0.5)).

	self
		assert: (self channelsOf: ((VGColorPaint r: 1.0 g: 0.0 b: 0.0 alpha: 0.5)
				  rgbaAtX: 0.5 y: 0.5))
		equals: #( 255 0 0 128 )
]

{ #category : 'tests - evaluation' }
VGPaintTest >> testAConcentricRadialGradientRampsWithTheDistanceBetweenItsTwoRadii [
	"Measured on a live Cairo context, centre 32@32, inner radius 8, outer 32, read on row 32 of a
	 surface 64 square: the offset is the distance from the centre less the inner radius, over the
	 difference of the radii, and the sample point is the centre of the pixel on both axes."

	| paint |
	paint := (VGRadialGradientPaint
		          innerCenter: 32 @ 32
		          innerRadius: 8
		          outerCenter: 32 @ 32
		          outerRadius: 32)
		         addStopAt: 0.0 color: Color black;
		         addStopAt: 1.0 color: Color white;
		         yourself.
	{
		(32 -> 0).
		(36 -> 0).
		(40 -> 5).
		(44 -> 48).
		(48 -> 90).
		(56 -> 175).
		(63 -> 250) } do: [ :each |
		self
			assert: (self channelsOf: (paint rgbaAtX: each key + 0.5 y: 32.5)) third
			equals: each value ]
]

{ #category : 'tests - evaluation' }
VGPaintTest >> testAGradientInterpolatesUnpremultipliedSoATransparentStopKeepsItsOwnHue [
	"Measured on a live Cairo context: a gradient from transparent blue to opaque red reads
	 129, 130, 0, 126 at the centre of pixel 32 of a surface 64 wide. Premultiplied interpolation
	 would answer a different hue there, and the eight-bit value is what a premultiplied store and
	 an unpremultiplied read of the picture leave behind."

	| paint |
	paint := VGLinearGradientPaint from: 0 @ 0 to: 64 @ 0.
	paint addStopAt: 0.0 color: (Color blue alpha: 0.0).
	paint addStopAt: 1.0 color: (Color red alpha: 1.0).
	self
		assert: (self channelsOf: (paint rgbaAtX: 32.5 y: 2.5))
		equals: #( 130 0 126 129 )
]

{ #category : 'tests - evaluation' }
VGPaintTest >> testAGradientOfNoStopsPaintsNothingAndOneOfOneStopPaintsThatColourEverywhere [
	"Both measured: a gradient with no stop leaves every pixel untouched, and a gradient with a
	 single stop at one half paints that colour over the whole surface, inside the line and
	 outside it."

	| empty single |
	empty := VGLinearGradientPaint from: 0 @ 0 to: 64 @ 0.
	self assert: (empty rgbaAtX: 32.5 y: 2.5) equals: nil.
	single := VGLinearGradientPaint from: 0 @ 0 to: 64 @ 0.
	single addStopAt: 0.5 color: Color green.
	#( 0.5 32.5 1000.5 ) do: [ :x |
		self
			assert: (self channelsOf: (single rgbaAtX: x y: 2.5))
			equals: #( 0 255 0 255 ) ]
]

{ #category : 'tests - patterns' }
VGPaintTest >> testAGradientPatternTakesItsStopsOneByOneOrAllAtOnce [
	"Alexandrie's two ways of naming the same gradient have to answer the same paint, because the
	 corpus names gradients both ways."

	| stops oneByOne allAtOnce |
	stops := {
		         (0.0 -> Color red).
		         (1.0 -> Color blue) }.
	oneByOne := VGCairoLinearGradientPattern from: 0 @ 0 to: 8 @ 0.
	stops do: [ :each | oneByOne addStopAt: each key color: each value ].
	allAtOnce := VGCairoLinearGradientPattern
		             from: 0 @ 0
		             to: 8 @ 0
		             addStopsFrom: stops.
	self assert: oneByOne paint stops equals: allAtOnce paint stops.
	self
		assert: (self channelsOf: (allAtOnce paint rgbaAtX: 4 y: 0))
		equals: (self channelsOf: (oneByOne paint rgbaAtX: 4 y: 0))
]

{ #category : 'tests - evaluation' }
VGPaintTest >> testALinearGradientRampsAlongItsLineExactlyAsLiveCairoDoes [
	"Measured on a live Cairo context: a black to white gradient from the origin to 64@0, painted
	 over a surface 64 wide, answers these values on the blue channel at the centre of each pixel.
	 The ramp is exact, not quantised: a two-hundred-and-fifty-six-entry table that truncates
	 reads 7 where Cairo reads 8 at the far end of a long ramp."

	| paint |
	paint := self blackToWhiteFrom: 0 @ 0 to: 64 @ 0.
	{
		(0 -> 2).
		(8 -> 34).
		(16 -> 66).
		(32 -> 129).
		(48 -> 193).
		(63 -> 253) } do: [ :each |
		self
			assert: (self channelsOf: (paint rgbaAtX: each key + 0.5 y: 2.5)) third
			equals: each value ]
]

{ #category : 'tests' }
VGPaintTest >> testAPaintDecodesItsMatrixOnceAndSettingItDecodesItAgain [
	"The matrix is asked for at every pixel of every fill, so decoding the six fields of the block
	 into a VGCairoMatrix on each call dominated a frame: rendering the twenty-nine operator cases
	 of the Alexandrie corpus spent its time in a dictionary built once per pixel. The block stays
	 the truth and the decoded matrix is kept beside it, so a later matrix: has to be seen."

	| paint |
	paint := self blackToWhiteFrom: 0 @ 0 to: 64 @ 0.
	self assert: paint matrix == paint matrix.
	paint matrix: (VGCairoMatrix newScalingBy: 2 @ 2).
	self assert: paint matrix sx equals: 2.
	self assert: paint matrix == paint matrix
]

{ #category : 'tests - block' }
VGPaintTest >> testAPaintRebuildsItselfFromItsOwnBlockAndItsStopsFromChannels [
	"The block of rule 2 is all a reader is given, and phase 2 hands it to a device and takes it
	 back: a paint built from the block of another paint of its class carries the same sixteen
	 floats and reads the same geometry, matrix and extend mode out of them. The stops travel
	 beside the block as channels and not as colours, because that is what a buffer of floats
	 holds, and a stop added from channels is the stop the colour added."

	| gradient rebuilt channels |
	gradient := (VGLinearGradientPaint from: 3 @ 5 to: 40 @ 11)
		            extend: #reflect;
		            matrix: (VGCairoMatrix newRotationByRadians: 0.4);
		            yourself.
	gradient addStopAt: 0.25 color: (Color r: 0.2 g: 0.4 b: 0.6 alpha: 0.8).
	channels := gradient stops first value.
	rebuilt := VGLinearGradientPaint fromBlock: gradient coefficients.
	rebuilt addStopAt: 0.25 channels: channels.
	self assert: rebuilt coefficients equals: gradient coefficients.
	self assert: rebuilt from equals: gradient from.
	self assert: rebuilt to equals: gradient to.
	self assert: rebuilt extend equals: #reflect.
	self
		assert: (rebuilt matrix value: 7 @ 9)
		equals: (gradient matrix value: 7 @ 9).
	self assert: rebuilt stops first key equals: 0.25.
	self assert: rebuilt stops first value equals: channels.
	self
		assert: (rebuilt rgbaAtX: 12 y: 8)
		equals: (gradient rgbaAtX: 12 y: 8)
]

{ #category : 'tests' }
VGPaintTest >> testAPatternDescribesItselfByAskingItsOwnPaint [
	| pattern description bare |
	pattern := VGPaintExamples linearGradientPattern.
	description := pattern paintDescription.
	self
		assert: ((description collect: [ :each | each key ]) asArray)
		equals: #( 'type' 'tag' 'extend' 'filter' 'matrix' 'paint at an identity device matrix' ).
	self assert: (description detect: [ :each | each key = 'type' ]) value equals: #linear.
	self
		assert: (description detect: [ :each | each key = 'tag' ]) value
		equals: pattern paint tag.
	self
		assert: (description detect: [ :each | each key = 'extend' ]) value
		equals: pattern extend.
	self
		assert: (description detect: [ :each | each key = 'filter' ]) value
		equals: pattern filter.
	self
		assert: (description detect: [ :each | each key = 'matrix' ]) value
		equals: pattern matrix.
	self
		assert: ((description detect: [ :each | each key = 'paint at an identity device matrix' ])
				 value coefficients asArray)
		equals: (pattern paintForDeviceMatrix: VGCairoMatrix newIdentity) coefficients asArray.
	"A gradient with no stop at all paints nothing, and describes itself all the same."
	bare := VGCairoLinearGradientPattern from: 0 @ 0 to: 1 @ 0.
	self assert: bare paintDescription size equals: description size.
	self assert: (bare paintDescription detect: [ :each | each key = 'type' ]) value equals: #linear
]

{ #category : 'tests - patterns' }
VGPaintTest >> testAPatternHandsItsExtendModeAndItsFilterStraightToItsPaint [
	| pattern |
	pattern := VGCairoSurfacePattern surface: (VGCairoImageSurface extent: 4 @ 4).
	self assert: pattern extend equals: #none.
	self assert: pattern filter equals: #good.
	pattern extend: #repeat.
	pattern filter: AeCairoSamplingFilter nearest.
	self assert: pattern paint extend equals: #repeat.
	self assert: pattern paint filter equals: #nearest
]

{ #category : 'tests - patterns' }
VGPaintTest >> testAPatternMatrixAndTheTransformationAtSetSourceTimeBothReachThePaint [
	"The paint's matrix maps a device point into paint space, and a device point gets there in two
	 steps: back through the transformation that was in force when the source was set, and then
	 forward through the pattern's own matrix."

	| pattern paint |
	pattern := VGCairoLinearGradientPattern from: 0 @ 0 to: 8 @ 0.
	pattern matrix: (VGCairoMatrix newScalingBy: 2 @ 2).
	paint := pattern paintForDeviceMatrix: (VGCairoMatrix newTranslationBy: 4 @ 0).
	self assert: (paint pointInPaintSpaceX: 6 y: 0) equals: 4 @ 0.
	self assert: (pattern matrix value: 1 @ 1) equals: 2 @ 2
]

{ #category : 'tests - evaluation' }
VGPaintTest >> testASurfacePaintReadsItsSurfacePixelForPixelAndPaintsNothingOutsideIt [
	"Measured on a live Cairo context: a four by four surface, red over its top left quadrant and
	 blue elsewhere, used as the source at the origin, reads red at pixel 0 and 1, blue at 2 and 3
	 and nothing at all at 4, because the default extend mode of a surface pattern is none."

	| paint |
	paint := VGSurfacePaint surface: self redAndBlueSurface.
	self assert: (self channelsOf: (paint rgbaAtX: 0.5 y: 0.5)) equals: #( 255 0 0 255 ).
	self assert: (self channelsOf: (paint rgbaAtX: 1.5 y: 0.5)) equals: #( 255 0 0 255 ).
	self assert: (self channelsOf: (paint rgbaAtX: 2.5 y: 0.5)) equals: #( 0 0 255 255 ).
	self assert: (self channelsOf: (paint rgbaAtX: 3.5 y: 0.5)) equals: #( 0 0 255 255 ).
	self assert: (paint rgbaAtX: 4.5 y: 0.5) equals: nil.
	paint extend: #repeat.
	self assert: (self channelsOf: (paint rgbaAtX: 4.5 y: 0.5)) equals: #( 255 0 0 255 )
]

{ #category : 'tests - abi' }
VGPaintTest >> testAnExtendModeAndAFilterAreNamedBySymbolByCodeAndByAlexandriesOwnValue [
	"Cairo's own numbers are the codes the block carries, so a caller may name either vocabulary
	 and an Alexandrie enumeration member normalises to the same name."

	| paint |
	paint := VGColorPaint color: Color red.
	VGPaint extendNames do: [ :each |
		self assert: (VGPaint extendFor: each value) equals: each value.
		self assert: (VGPaint extendFor: each key) equals: each value.
		paint extend: each key.
		self assert: paint extend equals: each value ].
	VGPaint filterNames do: [ :each |
		self assert: (VGPaint filterFor: each value) equals: each value.
		self assert: (VGPaint filterFor: each key) equals: each value ].
	self assert: (VGPaint extendFor: AeCairoExtendMode reflect) equals: #reflect.
	self assert: (VGPaint filterFor: AeCairoSamplingFilter nearest) equals: #nearest.
	self assert: (VGPaint extendFor: #nonsense) equals: nil
]

{ #category : 'tests' }
VGPaintTest >> testEachPaintQuantisesItsOwnWayAndAnswersNoPixelWhereItPaintsNothing [
	"A solid colour and a gradient disagree by one on most colours, because Cairo quantises them
	 differently, so the paint and not the format decides which rule applies. Both are measured
	 against a live Cairo context."

	| format solid ramp |
	format := VGCairoSurfaceFormat argb32.
	solid := VGColorPaint color: (Color r: 0.5 g: 0.25 b: 0.75 alpha: 0.5).
	self assert: (solid pixelIn: format atX: 0 y: 0) equals: 16r7F3F1F5F.
	ramp := (VGLinearGradientPaint from: 0 @ 0 to: 64 @ 0)
		        extend: #pad;
		        addStopAt: 0.0 color: (Color r: 0.0 g: 0.0 b: 1.0 alpha: 0.0);
		        addStopAt: 1.0 color: (Color r: 1.0 g: 0.0 b: 0.0 alpha: 1.0);
		        yourself.
	self assert: (ramp pixelIn: format atX: 16 y: 0) equals: 16r42110031.
	self assert: (ramp pixelIn: format atX: 32 y: 0) equals: 16r81420040.
	"Coverage is a mask on the pixel the paint has already quantised, and it scales the alpha
	 along with the colours: a clip edge through the middle of the pixel stores 16r40201030 for
	 that solid and 16r41210020 for pixel thirty-two of that ramp, both measured."
	self assert: (solid pixelIn: format atX: 0 y: 0 coverage: 0.5) equals: 16r40201030.
	self assert: (ramp pixelIn: format atX: 32 y: 0 coverage: 0.5) equals: 16r41210020.
	"A paint that lays nothing down at a pixel answers no pixel at all, and the one underneath
	 stays as it was."
	self
		assert: (VGPaintExamples surfacePaintThatPaintsNothingOutsideItsTile
				 pixelIn: format
				 atX: 100
				 y: 100
				 coverage: 1.0)
		equals: nil
]

{ #category : 'tests - patterns' }
VGPaintTest >> testEachPatternClassCarriesAPaintOfItsOwnTagAndAnswersItsOwnType [
	"A pattern is the Cairo-facing wrapper and a paint is what the backend reads, so each pattern
	 class names one paint class and the tag of that paint is Cairo's own pattern type number."

	| patterns |
	patterns := {
		            ((VGCairoColorPattern r: 1 g: 0 b: 0) -> #solid).
		            ((VGCairoSurfacePattern surface: (VGCairoImageSurface extent: 4 @ 4))
		             -> #surface).
		            ((VGCairoLinearGradientPattern from: 0 @ 0 to: 8 @ 0) -> #linear).
		            ((VGCairoRadialGradientPattern
			              innerCenter: 0 @ 0
			              innerRadius: 1
			              outerCenter: 0 @ 0
			              outerRadius: 8) -> #radial) }.
	patterns do: [ :each |
		self assert: each key type equals: each value.
		self
			assert: each key paint tag
			equals: (VGPaint codeFor: each value in: VGPaint typeNames) ]
]

{ #category : 'tests - abi' }
VGPaintTest >> testEveryPaintCarriesABlockOfTheSameSizeAndATagOfItsOwn [
	"The point of the ABI: one block shape for every paint, so the backend reads the first eight
	 fields without asking what the paint is, and the tag says how to read the rest."

	| paints bytesPerFloat |
	bytesPerFloat := 4.
	paints := self everyKindOfPaint.
	paints do: [ :each |
		self assert: each coefficients size equals: VGPaint coefficientCount.
		self
			assert: each coefficients byteSize
			equals: VGPaint coefficientCount * bytesPerFloat.
		self assert: each tag isInteger ].
	self
		assert: (paints collect: [ :each | each tag ]) asSet size
		equals: paints size
]

{ #category : 'tests' }
VGPaintTest >> testOnlyAColourIsSolidAndFadingItMultipliesItsAlpha [
	"Cairo folds an alpha into the paint's colour only when the paint is solid, so the paint
	 itself has to say whether it is one. Fading answers a copy: the paint of a recorded entry
	 must not change under it."
	| paint faded |
	paint := VGColorPaint r: 1.0 g: 0.5 b: 0.0 alpha: 0.5.
	self assert: paint isSolid.
	self deny: VGLinearGradientPaint new isSolid.
	faded := paint fadedBy: 0.5.
	self
		assert: (faded rgbaInPaintSpace: 0 @ 0)
		equals: { 1.0. 0.5. 0.0. 0.25 }.
	self
		assert: (paint rgbaInPaintSpace: 0 @ 0)
		equals: { 1.0. 0.5. 0.0. 0.5 }
]

{ #category : 'tests' }
VGPaintTest >> testSamplingTheStopTableIsNotTheBytesTheStopsThemselvesGive [
	"Why the GPU evaluator of unit 2.4 searches the stops instead of reading the table of rule 2:
	 the table describes two hundred and fifty-six offsets, and an offset between two of them has
	 to be quantised to one, which moves the colour. Over a sweep of one thousand and twenty-four
	 offsets of a three-stop ramp, 898 of the 4096 channel samples differ from the exact
	 evaluation, the farthest by two. Measured on the two gradient cases of the conformance corpus
	 the same way, 2498 of 16384 channel samples of the linear case and 1548 of the radial case
	 move, each of them by one. So a device that sampled the table could not hold the byte for byte
	 gate against the software backend, and this test fails if the drift ever goes away, which is
	 the day the table may be read in the path again."

	| paint table size drift worst |
	paint := VGLinearGradientPaint from: 0 @ 0 to: 1 @ 0.
	paint addStopAt: 0.0 color: Color red.
	paint addStopAt: 0.25 color: Color green.
	paint addStopAt: 1.0 color: Color blue.
	size := VGGradientPaint stopTableSize.
	table := paint stopTable.
	drift := 0.
	worst := 0.
	0 to: 1023 do: [ :step |
		| offset index exact |
		offset := step / 1023.
		index := (offset * (size - 1)) rounded.
		exact := (paint rgbaAtOffset: offset) collect: [ :each |
			         (each * 255) rounded ].
		1 to: 4 do: [ :channel |
			| sampled |
			sampled := table at: index * 4 + channel.
			sampled = (exact at: channel) ifFalse: [
				drift := drift + 1.
				worst := worst max: (sampled - (exact at: channel)) abs ] ] ].
	self assert: drift equals: 898.
	self assert: worst equals: 2
]

{ #category : 'tests - abi' }
VGPaintTest >> testTheBlockLayoutNamesEveryFieldOnceAndNoOther [
	"The layout is the ABI, so it has to describe the whole block and nothing beyond it."

	| layout |
	layout := VGPaint blockLayout.
	self assert: layout size equals: VGPaint coefficientCount.
	self
		assert: (layout collect: [ :each | each key ]) asArray
		equals: (1 to: VGPaint coefficientCount) asArray.
	self
		assert: (layout collect: [ :each | each value ]) asSet size
		equals: layout size.
	self
		assert: VGPaint matrixFieldIndices asArray
		equals: (1 to: VGPaint matrixFieldOrder size) asArray
]

{ #category : 'tests - abi' }
VGPaintTest >> testTheFirstEightFieldsMeanTheSameThingForEveryTag [
	"A reader of the block takes the matrix, the extend mode and the filter without asking what
	 the paint is. Writing each of them back through the accessors has to land in the same fields
	 whatever the tag."

	| matrix |
	matrix := VGCairoMatrix newX: 3 y: 4 sx: 2 sy: 5 shx: 6 shy: 7.
	self everyKindOfPaint do: [ :each |
		each matrix: matrix.
		each extend: #reflect.
		each filter: #nearest.
		self assert: each matrix equals: matrix.
		self assert: each extend equals: #reflect.
		self assert: each filter equals: #nearest.
		self
			assert: (each coefficients at: VGPaint extendFieldIndex)
			equals: (VGPaint codeFor: #reflect in: VGPaint extendNames).
		self
			assert: (each coefficients at: VGPaint filterFieldIndex)
			equals: (VGPaint codeFor: #nearest in: VGPaint filterNames) ]
]

{ #category : 'tests - evaluation' }
VGPaintTest >> testTheFourExtendModesClampWrapReflectAndVanishOutsideAGradient [
	"Measured on a live Cairo context with a black to white gradient from 16@0 to 32@0, read on the
	 blue channel at the centre of pixel zero: none paints nothing at all, pad holds the first
	 stop, repeat wraps the offset into zero to one, and reflect folds it into a triangle of
	 period two."

	| expected |
	expected := {
		            (#none -> nil).
		            (#pad -> 0).
		            (#repeat -> 8).
		            (#reflect -> 247) }.
	expected do: [ :each |
		| paint read |
		paint := self blackToWhiteFrom: 16 @ 0 to: 32 @ 0.
		paint extend: each key.
		read := self channelsOf: (paint rgbaAtX: 0.5 y: 2.5).
		self assert: (read ifNotNil: [ read third ]) equals: each value ]
]

{ #category : 'tests' }
VGPaintTest >> testTheMatrixOfAPaintMapsADevicePointIntoItsOwnSpace [
	"Measured on a live Cairo context: the same gradient under a pattern matrix that scales by two
	 reads 131 at the centre of pixel 16 instead of 66, because the matrix maps the device point
	 into the pattern's own space and so halves the width of the ramp."

	| paint |
	paint := self blackToWhiteFrom: 0 @ 0 to: 64 @ 0.
	paint matrix: (VGCairoMatrix newScalingBy: 2 @ 2).
	self
		assert: (self channelsOf: (paint rgbaAtX: 16.5 y: 2.5)) third
		equals: 131
]

{ #category : 'tests' }
VGPaintTest >> testTheStopTableAgreesWithTheExactEvaluationAtItsOwnSamplePoints [
	"The optional two-hundred-and-fifty-six-entry table of rule 2 exists for a shader, which wants
	 one texture read instead of a search through the stops. Phase 1 does not use it, because a
	 quantised table drifts from live Cairo; this holds it to the exact evaluation at the points it
	 does describe, so the two backends cannot disagree about the stops themselves. The table holds
	 unpremultiplied channels, because that is what the stops themselves hold."

	| paint table size |
	paint := VGLinearGradientPaint from: 0 @ 0 to: 1 @ 0.
	paint addStopAt: 0.0 color: Color red.
	paint addStopAt: 0.25 color: Color green.
	paint addStopAt: 1.0 color: Color blue.
	size := VGGradientPaint stopTableSize.
	table := paint stopTable.
	self assert: table size equals: size * 4.
	0 to: size - 1 do: [ :index |
		| expected |
		expected := (paint rgbaAtOffset: index / (size - 1)) collect: [ :each |
			            (each * 255) rounded ].
		1 to: 4 do: [ :channel |
			self
				assert: (table at: index * 4 + channel)
				equals: (expected at: channel) ] ]
]
