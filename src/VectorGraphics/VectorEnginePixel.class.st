"
# can you explain simply the difference between VectorEnginePixel, VectorEngineSubPixel and VectorEngineWholePixel ?


## Three levels, same algorithm, different anti-aliasing resolution:

  ---
  VectorEnginePixel (abstract base)
  Owns alphaMask and edgeCounts buffers. Defines the shared path-traversal and Bézier logic. Subclasses differ only in how those buffers are sized and read.

  ---
  VectorEngineWholePixel
  - 1 byte per pixel for both buffers (ByteArray)
  - Treats each screen pixel as a single unit
  - Good for hi-DPI displays where physical pixels are already tiny — no sub-pixel trickery needed
  - Less memory, simpler blending

  ---
  VectorEngineSubPixel
  - 1 word (4 bytes) per pixel — 3 bytes used for R, G, B channels independently (WordArray, accessed via bytesAt:)
  - Shifts the red and blue sub-pixel samples by ±subPixelDelta (0.25 pixel)
  - Exploits LCD sub-pixel layout: each channel hits a different physical stripe, tripling effective horizontal resolution
  - Best for normal-DPI screens with RGB stripe LCDs — edges look sharper
  - More memory, more complex blending (per-channel alpha)

  ---
  Summary table:

  ┌────────────────┬─────────────────┬────────────────┐
  │                │   WholePixel    │    SubPixel    │
  ├────────────────┼─────────────────┼────────────────┤
  │ Buffer type    │ ByteArray       │ WordArray      │
  ├────────────────┼─────────────────┼────────────────┤
  │ Bytes/pixel    │ 1               │ 4 (3 used)     │
  ├────────────────┼─────────────────┼────────────────┤
  │ Channels       │ 1 (luminance)   │ 3 (R, G, B)    │
  ├────────────────┼─────────────────┼────────────────┤
  │ Target display │ hi-DPI / retina │ normal-DPI LCD │
  ├────────────────┼─────────────────┼────────────────┤
  │ AA quality     │ whole-pixel AA  │ sub-pixel AA   │
  └────────────────┴─────────────────┴────────────────┘


❯ how do you tell which engine to use ?

  Searched for 2 patterns, read 1 file (ctrl+o to expand)

● Two places decide:

  1. VectorCanvas >> setForm: (line 943) — called during initialization via onForm:. Always starts with VectorEngineWholePixel.

  2. VectorCanvas >> doSubPixelAntiAliasing (line 115) — called explicitly to switch to VectorEngineSubPixel. Replaces the engine on the existing canvas.

  So the flow is:
  VectorCanvas onForm: aForm
      → setForm: aForm
      → engine := VectorEngineWholePixel onForm: form   ← default

  canvas doSubPixelAntiAliasing                          ← opt-in upgrade
      → engine := VectorEngineSubPixel onForm: form

  TTFontDescription calls doSubPixelAntiAliasing automatically when rendering text glyphs (lines 238, 312) — sub-pixel is used for fonts by default. For
  everything else (shapes, paths) you get whole-pixel AA unless you call doSubPixelAntiAliasing yourself.


❯ how do you tell which engine to use ?

  Searched for 2 patterns, read 1 file (ctrl+o to expand)

● Two places decide:

  1. VectorCanvas >> setForm: (line 943) — called during initialization via onForm:. Always starts with VectorEngineWholePixel.

  2. VectorCanvas >> doSubPixelAntiAliasing (line 115) — called explicitly to switch to VectorEngineSubPixel. Replaces the engine on the existing canvas.

  So the flow is:
  VectorCanvas onForm: aForm
      → setForm: aForm
      → engine := VectorEngineWholePixel onForm: form   ← default

  canvas doSubPixelAntiAliasing                          ← opt-in upgrade
      → engine := VectorEngineSubPixel onForm: form

  TTFontDescription calls doSubPixelAntiAliasing automatically when rendering text glyphs (lines 238, 312) — sub-pixel is used for fonts by default. For
  everything else (shapes, paths) you get whole-pixel AA unless you call doSubPixelAntiAliasing yourself.

. VectorEngine (superclass: Object) is a sibling of VectorEngineAbstract, not a subclass. It's the standalone reference implementation.

  Full actual hierarchy:

  Object
  ├── VectorEngine          (standalone, test reference — ByteArray buffers, simple)
  └── VectorEngineAbstract  (abstract — path state, drawing API)
          └── VectorEnginePixel   (abstract — pixel buffers, blend machinery)
                  ├── VectorEngineSubPixel
                  └── VectorEngineWholePixel

  Merging VectorEnginePixel into VectorEngineAbstract would load blendLeft/Right/Top/Bottom, strokeColor, fillColor, clipLeft/Right/Top/Bottom, alphaMask,
  edgeCounts, prevYTruncated, and all the aux* instVars onto VectorEngineAbstract — even though nothing needs them there. It would also make the class harder
   to understand (path logic mixed with pixel buffer logic).

  VectorEnginePixel earns its place: it groups everything specific to the buffer/blending layer, keeping VectorEngineAbstract focused on path state and the
  drawing API.


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
