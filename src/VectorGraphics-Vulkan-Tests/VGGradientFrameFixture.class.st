"
I am the gradient frames the tests of unit 2.4 draw.
Two of the forty-one conformance cases are gradient fills, both of them two stops under the pad
extend through a nearly plain matrix, so the corpus alone leaves most of an evaluator untested. My
frames cover what it leaves out: the four extend modes, three stops, two stops at one offset, no
stops at all, a line of no length, a radial gradient that leaves a pixel with no acceptable root, a
pattern matrix that is not the identity, and a gradient under the source operator, under a constant
alpha and inside a fractional clip.
`frames` answers each of them as a name and a block that draws on a context, which is what the
rasteriser tests, the encoding tests and the device gate all take. I live in the test package
because a frame drawn to measure a difference is a fixture and not a sample of the engine.
"
Class {
	#name : 'VGGradientFrameFixture',
	#superclass : 'Object',
	#category : 'VectorGraphics-Vulkan-Tests-Fixtures',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Fixtures'
}

{ #category : 'constants' }
VGGradientFrameFixture class >> extent [
	"The extent of a conformance case, so that my frames and the two gradient cases of the corpus
	 are the same size and cost the same to compare."

	^ VGConformanceCorpus caseExtent
]

{ #category : 'building' }
VGGradientFrameFixture class >> frameOfPattern: aPattern [
	"One pattern over the whole target: a difference then comes from the geometry of the gradient
	 and never from the shape of the fill."

	^ [ :context |
	  context
		  sourcePattern: aPattern;
		  rectangleX: 0 y: 0 width: self extent x height: self extent y;
		  fill ]
]

{ #category : 'frames' }
VGGradientFrameFixture class >> frames [
	"Every frame of mine, each as the name it goes by and a block that draws it on a context. The
	 order is the order they are read in: the extend modes, then the stops, then the degenerate
	 gradients, then the radial geometry, then a gradient meeting an operator, an alpha and a
	 clip."

	^ {
		  (#linearUnderNone -> self linearUnderNone).
		  (#linearUnderPad -> self linearUnderPad).
		  (#linearUnderRepeat -> self linearUnderRepeat).
		  (#linearUnderReflect -> self linearUnderReflect).
		  (#linearWithThreeStops -> self linearWithThreeStops).
		  (#linearWithTwoStopsAtOneOffset -> self linearWithTwoStopsAtOneOffset).
		  (#linearWithNoStops -> self linearWithNoStops).
		  (#linearOfNoLength -> self linearOfNoLength).
		  (#linearThroughAPatternMatrix -> self linearThroughAPatternMatrix).
		  (#radialConcentric -> self radialConcentric).
		  (#radialOffCentre -> self radialOffCentre).
		  (#radialLeavingPixelsWithNoRoot -> self radialLeavingPixelsWithNoRoot).
		  (#gradientUnderTheSourceOperator -> self gradientUnderTheSourceOperator).
		  (#gradientThroughAConstantAlpha -> self gradientThroughAConstantAlpha).
		  (#gradientInsideAFractionalClip -> self gradientInsideAFractionalClip) }
]

{ #category : 'frames' }
VGGradientFrameFixture class >> gradientInsideAFractionalClip [
	"A clip on fractions of a pixel, so the coverage of unit 2.3 and the paint of this unit meet
	 in one frame and a partly covered pixel is quantised once and masked afterwards."

	| pattern |
	pattern := VGCairoRadialGradientPattern
		           innerCenter: 30 @ 30
		           innerRadius: 2
		           outerCenter: 34 @ 36
		           outerRadius: 30
		           addStopsFrom: self threeStopRamp.
	^ [ :context |
	  context
		  rectangleX: 6.25 y: 9.75 width: 44.5 height: 40.25;
		  clip;
		  sourcePattern: pattern;
		  circleCenterX: 30 y: 30 radius: 24.5;
		  fill ]
]

{ #category : 'frames' }
VGGradientFrameFixture class >> gradientThroughAConstantAlpha [
	"A constant alpha rides in the segments and reaches the mask as a byte, so this frame holds
	 the gradient against the alpha byte unit 2.3 already encodes."

	| pattern |
	pattern := VGCairoLinearGradientPattern
		           from: 0 @ 8
		           to: 0 @ 56
		           addStopsFrom: self threeStopRamp.
	^ [ :context |
	  context
		  sourceColorR: 0.0 g: 0.3 b: 0.5;
		  rectangleX: 0 y: 0 width: self extent x height: self extent y;
		  fill;
		  sourcePattern: pattern;
		  paintWithAlpha: 0.45 ]
]

{ #category : 'frames' }
VGGradientFrameFixture class >> gradientUnderTheSourceOperator [
	"The source operator writes the paint where the paint lays nothing down as well, so a gradient
	 under the none extend clears what it does not reach."

	| pattern |
	pattern := (VGCairoLinearGradientPattern
		            from: 16 @ 0
		            to: 48 @ 0
		            addStopsFrom: self twoStopRamp)
		           extend: #none;
		           yourself.
	^ [ :context |
	  context
		  sourceColorR: 0.2 g: 0.2 b: 0.2;
		  rectangleX: 0 y: 0 width: self extent x height: self extent y;
		  fill;
		  setOperatorSource;
		  sourcePattern: pattern;
		  rectangleX: 8 y: 8 width: 48 height: 48;
		  fill ]
]

{ #category : 'frames' }
VGGradientFrameFixture class >> linearOfNoLength [
	"A line of no length has no direction to project a point on, so this gradient lays nothing
	 down either, and an evaluator that divides by the length of the line answers a division by
	 zero here."

	^ self frameOfPattern: (VGCairoLinearGradientPattern
			   from: 20 @ 20
			   to: 20 @ 20
			   addStopsFrom: self twoStopRamp)
]

{ #category : 'building' }
VGGradientFrameFixture class >> linearRampExtendedBy: aSymbol [
	"A short diagonal ramp over a target four times as wide as it is, so that most of the target
	 reads an offset outside nought to one and the extend mode decides what is drawn there."

	^ self frameOfPattern:
		  ((VGCairoLinearGradientPattern
			    from: 16 @ 16
			    to: 32 @ 32
			    addStopsFrom: self twoStopRamp)
			   extend: aSymbol;
			   yourself)
]

{ #category : 'frames' }
VGGradientFrameFixture class >> linearThroughAPatternMatrix [
	"The pattern carries a matrix of its own, so the block a kernel reads holds something other
	 than the identity and the six matrix fields are really used."

	^ self frameOfPattern: ((VGCairoLinearGradientPattern
			    from: 0 @ 0
			    to: 32 @ 0
			    addStopsFrom: self twoStopRamp)
			   extend: #reflect;
			   matrix: (VGCairoMatrix newRotationByRadians: 0.4);
			   yourself)
]

{ #category : 'frames' }
VGGradientFrameFixture class >> linearUnderNone [
	"The one extend mode that leaves pixels untouched, so a frame of it holds both what the
	 gradient draws and what it must not."

	^ self linearRampExtendedBy: #none
]

{ #category : 'frames' }
VGGradientFrameFixture class >> linearUnderPad [
	^ self linearRampExtendedBy: #pad
]

{ #category : 'frames' }
VGGradientFrameFixture class >> linearUnderReflect [
	^ self linearRampExtendedBy: #reflect
]

{ #category : 'frames' }
VGGradientFrameFixture class >> linearUnderRepeat [
	^ self linearRampExtendedBy: #repeat
]

{ #category : 'frames' }
VGGradientFrameFixture class >> linearWithNoStops [
	"A gradient with no stops lays nothing down anywhere, so this frame is the empty one and the
	 surface keeps every pixel it had."

	^ self frameOfPattern:
		  (VGCairoLinearGradientPattern from: 0 @ 0 to: 64 @ 64)
]

{ #category : 'frames' }
VGGradientFrameFixture class >> linearWithThreeStops [
	"A stop search that only ever answers the first and the last stop draws this frame wrongly."

	^ self frameOfPattern: (VGCairoLinearGradientPattern
			   from: 4 @ 4
			   to: 60 @ 44
			   addStopsFrom: self threeStopRamp)
]

{ #category : 'frames' }
VGGradientFrameFixture class >> linearWithTwoStopsAtOneOffset [
	"A hard edge in the middle of the ramp, where the bracketing pair has a span of nothing."

	^ self frameOfPattern: (VGCairoLinearGradientPattern
			   from: 0 @ 0
			   to: 64 @ 0
			   addStopsFrom: self rampWithTwoStopsAtOneOffset)
]

{ #category : 'frames' }
VGGradientFrameFixture class >> radialConcentric [
	"Two circles about one centre, which is the case the corpus draws and the case the quadratic
	 reduces to a distance."

	^ self frameOfPattern: (VGCairoRadialGradientPattern
			   innerCenter: 32 @ 32
			   innerRadius: 4
			   outerCenter: 32 @ 32
			   outerRadius: 28
			   addStopsFrom: self twoStopRamp)
]

{ #category : 'frames' }
VGGradientFrameFixture class >> radialLeavingPixelsWithNoRoot [
	"Circles whose interpolation shrinks, under the extend that paints nothing outside the ramp:
	 a pixel no circle of a radius of its own passes through is left alone, which is the branch an
	 evaluator reaches by answering nothing at all rather than an offset."

	^ self frameOfPattern: ((VGCairoRadialGradientPattern
			    innerCenter: 24 @ 24
			    innerRadius: 22
			    outerCenter: 40 @ 40
			    outerRadius: 3
			    addStopsFrom: self twoStopRamp)
			   extend: #none;
			   yourself)
]

{ #category : 'frames' }
VGGradientFrameFixture class >> radialOffCentre [
	"Circles about different centres, which leaves the quadratic its two roots: the larger of the
	 two is the offset, and an evaluator that takes the smaller draws a different cone."

	^ self frameOfPattern: ((VGCairoRadialGradientPattern
			    innerCenter: 22 @ 26
			    innerRadius: 3
			    outerCenter: 38 @ 36
			    outerRadius: 26
			    addStopsFrom: self threeStopRamp)
			   extend: #pad;
			   yourself)
]

{ #category : 'constants' }
VGGradientFrameFixture class >> rampWithTwoStopsAtOneOffset [
	"Four stops, two of them at the same offset, which is how Cairo draws a hard edge inside a
	 ramp. The pair that brackets an offset at the edge itself has a zero span, so an evaluator
	 that divides by the span of the pair answers an infinity here."

	^ {
		  (0.0 -> (Color r: 1.0 g: 1.0 b: 0.0)).
		  (0.5 -> (Color r: 1.0 g: 0.0 b: 0.0)).
		  (0.5 -> (Color r: 0.0 g: 0.0 b: 1.0)).
		  (1.0 -> (Color r: 0.0 g: 1.0 b: 1.0)) }
]

{ #category : 'constants' }
VGGradientFrameFixture class >> threeStopRamp [
	"Three stops at uneven offsets, one of them translucent: a stop search that answers the middle
	 stop is wrong wherever it takes the first or the last instead, and a translucent stop shows
	 the unpremultiplied interpolation."

	^ {
		  (0.0 -> (Color r: 1.0 g: 0.1 b: 0.0)).
		  (0.35 -> (Color r: 0.0 g: 0.9 b: 0.3)).
		  (1.0 -> (Color r: 0.0 g: 0.2 b: 1.0 alpha: 0.4)) }
]

{ #category : 'constants' }
VGGradientFrameFixture class >> twoStopRamp [
	"The ramp the corpus draws its gradient cases with, so that a frame of mine differing from one
	 of theirs differs in its geometry and not in its colours."

	^ VGConformanceCorpus twoStopRamp
]
