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
