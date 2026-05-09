"
Abstract middle layer between VectorEngineAbstract (path state) and the concrete renderers.

VectorEnginePixel owns the pixel buffers (`alphaMask`, `edgeCounts`), the blending logic, and
the auxiliary stroke-width precomputed values. Subclasses differ only in buffer layout and
how they read/write per-pixel alpha values:

  VectorEngineWholePixel  — 1 byte/pixel (ByteArray), whole-pixel AA, good for hi-DPI displays
  VectorEngineSubPixel    — 4 bytes/pixel (WordArray, 3 used for R/G/B), sub-pixel AA for LCD

## Selection
VectorCanvas defaults to VectorEngineWholePixel. Calling `canvas doSubPixelAntiAliasing`
replaces it with VectorEngineSubPixel (done automatically by TTFontDescription for text).

## Key instVars
- `alphaMask`          — per-pixel minimum distance to trajectory; 16r7F=opaque, 16r00=transparent
- `edgeCounts`         — per-pixel winding-number deltas (for fill rendering)
- `blendLeft/Right/Top/Bottom` — bounding box of affected pixels (optimises blend pass)
- `strokeColor`, `fillColor`   — current drawing colors
- `clipLeft/Right/Top/Bottom`  — clipping rectangle in targetForm coordinates
- `auxStrokeWidthDilatedHalf`  — (strokeWidth + antiAliasingWidth) * 0.5
- `auxStrokeWidthDilatedHalfSquared` — square of the above (for distance comparisons)
- `auxStrokeWidthErodedHalfSquared`  — signed square of (strokeWidth - antiAliasingWidth) * 0.5

## Key methods
- `computeStrokeRadii: strokeWidth antiAliasingWidth: aaw` (class side)
  — pure computation of the three aux values; testable without a Form
- `pvtStrokeWidth: aNumber` — sets strokeWidth and refreshes all aux radius values
- `finishPath: ensureClosePath` — blend buffers into targetForm, reset alphaMask/edgeCounts
- `blendStrokeOnly`, `blendFillOnly`, `blendStrokeAndFill` — pixel-level compositing passes
- `primLineFromX:y:toX:y:hops:incrementX:incrementY:` — concrete hop walker (overrides abstract)
- `updateAlphasForX:y:` — subclassResponsibility (implemented by WholePixel and SubPixel)
"
Class {
	#name : 'VectorEnginePixel',
	#superclass : 'VectorEngineAbstract',
	#instVars : [
		'edgeCounts',
		'alphaMask',
		'blendLeft',
		'blendTop',
		'blendRight',
		'blendBottom',
		'strokeColor',
		'fillColor',
		'clipLeft',
		'clipTop',
		'clipRight',
		'clipBottom',
		'prevYTruncated',
		'auxAntiAliasingWidthScaledInverse',
		'auxStrokeWidthDilatedHalf',
		'auxStrokeWidthDilatedHalfSquared',
		'auxStrokeWidthErodedHalfSquared'
	],
	#category : 'VectorGraphics-Kernel',
	#package : 'VectorGraphics',
	#tag : 'Kernel'
}

{ #category : 'private' }
VectorEnginePixel class >> computeStrokeRadii: strokeWidth antiAliasingWidth: antiAliasingWidth [

	| dilatedHalf erodedHalf erodedHalfSquared |
	dilatedHalf := (strokeWidth + antiAliasingWidth) * 0.5.
	erodedHalf := (strokeWidth - antiAliasingWidth) * 0.5.
	erodedHalfSquared := erodedHalf * erodedHalf * erodedHalf sign.
	^ Dictionary new
		  at: #dilatedHalf put: dilatedHalf;
		  at: #dilatedHalfSquared put: dilatedHalf * dilatedHalf;
		  at: #erodedHalfSquared put: erodedHalfSquared;
		  yourself
]

{ #category : 'accessing' }
VectorEnginePixel >> antiAliasingWidth: aNumber [

	super antiAliasingWidth: aNumber.
	auxAntiAliasingWidthScaledInverse := 127.0 / antiAliasingWidth
]

{ #category : 'private - blend with mask' }
VectorEnginePixel >> blendHorizontalExpansion [
	"Extra horizontal pixel margin needed by sub-pixel sampling. Zero for whole-pixel AA."
	^ 0.0
]

{ #category : 'private - blend with mask' }
VectorEnginePixel >> blendStrokeOnly [

	| pixelIndex morphAtThisPixelId |
	blendTop to: blendBottom do: [ :displayY |
		pixelIndex := displayY * targetWidth + blendLeft.
		blendLeft to: blendRight do: [ :displayX |
			pixelIndex := pixelIndex + 1.
			(clippingMorphId = 0 or: [
				 morphAtThisPixelId := morphIds at: pixelIndex.
				 morphAtThisPixelId = clippingMorphId or: [
					 morphAtThisPixelId = currentMorphId ] ]) ifTrue: [
				self
					blendStrokeOnlyAtX: displayX
					y: displayY
					pixelIndex: pixelIndex ].
			alphaMask at: pixelIndex put: 0 ] ]
]

{ #category : 'accessing' }
VectorEnginePixel >> clipRect: aRectangle [

	"by convention, aRectangle includes left and top but does not include right and bottom.
		We do draw clipRight and clipBottom but not beyond. 	"

	"In targetForm coordinates"

	clipLeft := aRectangle left asInteger max: 0.
	clipTop := aRectangle top asInteger max: 0.
	clipRight := (aRectangle right asInteger min: targetWidth) - 1.
	clipBottom := (aRectangle bottom asInteger min: targetForm height)
	              - 1
]

{ #category : 'abstract' }
VectorEnginePixel >> finishPath: ensureClosePath [

	| hExp |
	ensureClosePath ifTrue: [
		(pathFirstX = pathCurrentX and: [ pathFirstY = pathCurrentY ])
			ifFalse: [ self basicClosePath ] ].

	hExp := self blendHorizontalExpansion.
	blendLeft   := (blendLeft   - auxStrokeWidthDilatedHalf - hExp) truncated + 1.
	blendTop    := (blendTop    - auxStrokeWidthDilatedHalf) truncated + 1.
	blendRight  := (blendRight  + auxStrokeWidthDilatedHalf + hExp) truncated + 1.
	blendBottom := (blendBottom + auxStrokeWidthDilatedHalf) truncated.

	morphBoundsLeft   := morphBoundsLeft   min: blendLeft.
	morphBoundsTop    := morphBoundsTop    min: blendTop.
	morphBoundsRight  := morphBoundsRight  max: blendRight.
	morphBoundsBottom := morphBoundsBottom max: blendBottom.

	blendLeft   := blendLeft   max: clipLeft.
	blendTop    := blendTop    max: clipTop.
	blendRight  := blendRight  min: clipRight.
	blendBottom := blendBottom min: clipBottom.

	(blendRight >= blendLeft and: [ blendBottom >= blendTop ]) ifTrue: [
		fillColor notNil
			ifTrue: [
				strokeColor notNil
					ifTrue: [ self blendStrokeAndFill ]
					ifFalse: [ self blendFillOnly ] ]
			ifFalse: [ self blendStrokeOnly ] ].

	pathFirstX := 0.0.
	pathFirstY := 0.0.
	pathCurrentX := 0.0.
	pathCurrentY := 0.0.
	previousCallX := 0.0.
	previousCallY := 0.0.
	previousCallControlX := previousCallX.
	previousCallControlY := previousCallY
]

{ #category : 'private' }
VectorEnginePixel >> initializePath [

	super initializePath.

	blendLeft := targetWidth. "drawable right. Will later be refined."
	blendTop := targetForm height. "drawable bottom. Will later be refined."
	blendRight := 0. "drawable left. Will later be refined."
	blendBottom := 0 "drawable top. Will later be refined."
]

{ #category : 'private' }
VectorEnginePixel >> newTrajectoryFragment [

	prevYTruncated := nil
]

{ #category : 'primitive algorithms' }
VectorEnginePixel >> primArcCenterX: cx centerY: cy radiusX: rx radiusY: ry start: startAngle rotationCos: thetaCos rotationSin: thetaSin hops: hops angleDelta: d [

	| angle xp yp x y |
	angle := startAngle.
	hops + 1 timesRepeat: [
		xp := angle cos * rx.
		yp := angle sin * ry.
		x := thetaCos * xp - (thetaSin * yp) + cx.
		y := thetaSin * xp + (thetaCos * yp) + cy.
		self updateAlphasForX: x y: y.
		self updateEdgesAndBoundsForX: x y: y.
		angle := angle + d ]
]

{ #category : 'primitive algorithms' }
VectorEnginePixel >> primCubicBezierFromX: xFrom y: yFrom toX: xTo y: yTo control1X: xControl1 y: yControl1 control2X: xControl2 y: yControl2 hops: hops [

	| t oneLessT increment f2 f3 f1 f23 f4 x y |
	t := 0.0.
	increment := 1.0 / hops.
	hops timesRepeat: [
		oneLessT := 1.0 - t.
		f1 := oneLessT * oneLessT * oneLessT.
		f23 := 3 * oneLessT * t.
		f2 := f23 * oneLessT.
		f3 := f23 * t.
		f4 := t * t * t.
		x := f1 * xFrom + (f2 * xControl1) + (f3 * xControl2) + (f4 * xTo).
		y := f1 * yFrom + (f2 * yControl1) + (f3 * yControl2) + (f4 * yTo).
		self updateAlphasForX: x y: y.
		self updateEdgesAndBoundsForX: x y: y.
		t := t + increment ].
	self updateAlphasForX: xTo y: yTo.
	self updateEdgesAndBoundsForX: xTo y: yTo
]

{ #category : 'primitive algorithms' }
VectorEnginePixel >> primLineFromX: xFrom y: yFrom toX: xTo y: yTo hops: hops incrementX: incrementX incrementY: incrementY [

	| x y |
	x := xFrom.
	y := yFrom.
	hops timesRepeat: [
		self updateAlphasForX: x y: y.
		self updateEdgesAndBoundsForX: x y: y.
		x := x + incrementX.
		y := y + incrementY ].
	self updateAlphasForX: xTo y: yTo.
	self updateEdgesAndBoundsForX: xTo y: yTo
]

{ #category : 'primitive algorithms' }
VectorEnginePixel >> primQuadraticBezierFromX: xFrom y: yFrom toX: xTo y: yTo controlX: xControl y: yControl hops: hops [

	| t oneLessT increment f2 f3 f1 x y |
	t := 0.0.
	increment := 1.0 / hops.
	hops timesRepeat: [
		oneLessT := 1.0 - t.
		f1 := oneLessT * oneLessT.
		f2 := 2 * oneLessT * t.
		f3 := t * t.
		x := f1 * xFrom + (f2 * xControl) + (f3 * xTo).
		y := f1 * yFrom + (f2 * yControl) + (f3 * yTo).
		self updateAlphasForX: x y: y.
		self updateEdgesAndBoundsForX: x y: y.
		t := t + increment ].
	self updateAlphasForX: xTo y: yTo.
	self updateEdgesAndBoundsForX: xTo y: yTo
]

{ #category : 'private' }
VectorEnginePixel >> pvtFillColor: aFillColorOrNil [

	fillColor := aFillColorOrNil
]

{ #category : 'private' }
VectorEnginePixel >> pvtStrokeColor: aStrokeColorOrNil [

	strokeColor := aStrokeColorOrNil
]

{ #category : 'private' }
VectorEnginePixel >> pvtStrokeWidth: aNumber [

	| radii |
	super pvtStrokeWidth: aNumber.
	radii := self class computeStrokeRadii: strokeWidth antiAliasingWidth: antiAliasingWidth.
	auxStrokeWidthDilatedHalf := radii at: #dilatedHalf.
	auxStrokeWidthDilatedHalfSquared := radii at: #dilatedHalfSquared.
	auxStrokeWidthErodedHalfSquared := radii at: #erodedHalfSquared
]

{ #category : 'primitive algorithms - aux' }
VectorEnginePixel >> updateAlphasForX: x y: y [

	^ self subclassResponsibility
]

{ #category : 'primitive algorithms - aux' }
VectorEnginePixel >> updateEdgesAndBoundsForX: x y: y [

	^ self subclassResponsibility
]
