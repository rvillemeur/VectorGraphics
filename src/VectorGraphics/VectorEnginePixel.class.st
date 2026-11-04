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

{ #category : 'private' }
VectorEnginePixel >> blendPath [

	"A hook: an engine that only measures overrides this and writes nothing. The blend box
	is already clipped here, and the colours say which pass to run."

	fillColor notNil
		ifTrue: [
			strokeColor notNil
				ifTrue: [ self blendStrokeAndFill ]
				ifFalse: [ self blendFillOnly ] ]
		ifFalse: [ self blendStrokeOnly ]
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
		self blendPath ].

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

{ #category : 'inspector' }
VectorEnginePixel >> inspectorBufferContentEntries [
	"One row per fact about what the three buffers hold, each holding the block that reads it, so
	a row is measured when it is drawn and cannot drift from the engine."

	^ {
		  ('slots per buffer' -> [ alphaMask size ]) .
		  ('alpha mask' -> [ alphaMask class name ]) .
		  ('alpha mask, pixels not zero' -> [ self inspectorPixelsSetIn: alphaMask ]) .
		  ('alpha mask, largest value' -> [ alphaMask max ]) .
		  ('edge counts' -> [ edgeCounts class name ]) .
		  ('edge counts, pixels not zero' -> [ self inspectorPixelsSetIn: edgeCounts ]) .
		  ('morph ids, pixels not zero' -> [ self inspectorPixelsSetIn: morphIds ]) }
]

{ #category : 'inspector' }
VectorEnginePixel >> inspectorBufferEntries [
	"What the Buffers view shows, in two halves: what the buffers hold, then the geometry the
	blend will read."

	^ self inspectorBufferContentEntries , self inspectorBufferGeometryEntries
]

{ #category : 'inspector' }
VectorEnginePixel >> inspectorBufferGeometryEntries [
	"One row per number the blend pass will read: the box it walks, the box it is clipped to and
	the radii computed from the stroke width and the anti-aliasing width."

	^ {
		  ('blend box' -> [ blendLeft @ blendTop corner: blendRight @ blendBottom ]) .
		  ('clip box, last pixel drawn' -> [ clipLeft @ clipTop corner: clipRight @ clipBottom ]) .
		  ('anti-aliasing width' -> [ antiAliasingWidth ]) .
		  ('stroke width' -> [ strokeWidth ]) .
		  ('dilated half width' -> [ auxStrokeWidthDilatedHalf ]) .
		  ('eroded half width, squared and signed' -> [ auxStrokeWidthErodedHalfSquared ]) .
		  ('hops per pixel' -> [ hopsPerPixel ]) .
		  ('horizontal expansion of the blend box' -> [ self blendHorizontalExpansion ]) }
]

{ #category : 'inspector' }
VectorEnginePixel >> inspectorBuffers [
	<inspectorPresentationOrder: 20 title: 'Buffers'>
	"What the three buffers of this engine hold now, counted rather than described. The blend pass
	zeroes alphaMask and edgeCounts at every pixel it visits, so after a finished drawing both are
	empty and only morphIds still says anything: a reader who wants to see coverage must inspect
	an engine during a path, which is what
	VectorCanvasExample class >> exampleEngineDuringAFillPath answers."

	^ SpTablePresenter new
		  addColumn: ((SpStringTableColumn title: 'Buffer' evaluated: [ :each | each key ]) width: 200);
		  addColumn: (SpStringTableColumn title: 'Now' evaluated: [ :each | each value value printString ]);
		  items: self inspectorBufferEntries;
		  yourself
]

{ #category : 'inspector' }
VectorEnginePixel >> inspectorPixelsSetIn: aBuffer [
	"How many pixels of one buffer hold anything. The blend pass zeroes a pixel as it reads it,
	so this is zero after a finished drawing."

	^ aBuffer count: [ :each | each ~= 0 ]
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
