"
Abstract base for the production vector rasterizer. Owns the path state machine and the
complete SVG-style drawing API. Concrete rendering is left to VectorEnginePixel subclasses.

## Class hierarchy
  VectorEngineAbstract (path state + drawing API)
    └── VectorEnginePixel (alphaMask + edgeCounts buffers, blend logic)
            ├── VectorEngineWholePixel  (1 byte/pixel, hi-DPI)
            └── VectorEngineSubPixel    (4 bytes/pixel, sub-pixel AA for LCD)

## Path state machine
Drawing methods are prefixed `abs_` (absolute coordinates) or `rel_` (relative).
All path state is managed in instVars:
- `pathCurrentX/Y`       — current pen position, updated by every drawing operation
- `pathFirstX/Y`         — position of the most recent `abs_MoveTo:`, used by `do_ClosePath`
- `previousCallX/Y`      — previous call's endpoint, used by smooth Bézier commands
- `previousCallControlX/Y` — previous control point, used by smooth quadratic commands
- `hopsPerPixel`         — sub-pixel sampling density (higher = smoother curves, slower)

## Stroke/fill entry points
All drawing must happen inside one of:
- `strokeWidth: color: do:`           — stroke only
- `fillColor: do:`                    — fill only
- `strokeWidth: color: fillColor: do:` — both
These set up state (hopsPerPixel, strokeWidth, initializePath) and call `finishPath:` after.

## Key drawing methods (abs_ variants; rel_ variants delegate to abs_)
- `abs_MoveTo: aPoint`         — start new subpath
- `abs_LineTo: aPoint`         — straight line
- `abs_LineToX:`               — horizontal line (keeps current y)
- `abs_LineToY:`               — vertical line (keeps current x)
- `abs_CubicBezierTo: aPoint control1: c1 control2: c2` — cubic Bézier
- `abs_QuadraticBezierTo: aPoint control: cPoint` — quadratic Bézier
- `abs_ArcTo: aPoint radiusX: radiusY: ...`   — elliptical arc
- `abs_EllipseCenter: aPoint radiusX: radiusY: ...` — full ellipse
- `do_ClosePath`           — line back to pathFirstX/Y

## Subclass responsibilities
- `newTrajectoryFragment`  — called at start of each subpath
- `primLineFromX:y:toX:y:hops:incrementX:incrementY:` — low-level hop walker
- `primCubicBezierFromX:...`, `primQuadraticBezierFromX:...`, `primArcCenterX:...`
- `finishPath: ensureClosePath`        — blend alphaMask into targetForm and reset buffers
- `updateAlphasForX:y:`, `updateEdgesAndBoundsForX:y:` — per-hop pixel updates
"
Class {
	#name : 'VectorEngineAbstract',
	#superclass : 'Object',
	#instVars : [
		'targetForm',
		'morphIds',
		'targetWidth',
		'antiAliasingWidth',
		'strokeWidth',
		'currentMorphId',
		'clippingMorphId',
		'morphBoundsLeft',
		'morphBoundsTop',
		'morphBoundsRight',
		'morphBoundsBottom',
		'hopsPerPixel',
		'pathFirstX',
		'pathFirstY',
		'pathCurrentX',
		'pathCurrentY',
		'previousCallX',
		'previousCallY',
		'previousCallControlX',
		'previousCallControlY'
	],
	#category : 'VectorGraphics-Kernel',
	#package : 'VectorGraphics',
	#tag : 'Kernel'
}

{ #category : 'instance creation' }
VectorEngineAbstract class >> defaultAntiAliasingWidth [

	^ 1.0
]

{ #category : 'instance creation' }
VectorEngineAbstract class >> onForm: aForm [

	^ self new initializeOnForm: aForm
]

{ #category : 'paths - absolute coordinates' }
VectorEngineAbstract >> abs_ArcTo: aPoint radiusX: mrx radiusY: mry angleOfXAxis: theta largeFlag: doLargerArc sweepFlag: useIncreasingAngles [

	self
		basicArcToX: aPoint x
		y: aPoint y
		radiusX: mrx
		radiusY: mry
		angleOfXAxis: theta
		largeFlag: doLargerArc
		sweepFlag: useIncreasingAngles
]

{ #category : 'paths - absolute coordinates' }
VectorEngineAbstract >> abs_CircleCenter: aPoint radius: mr [

	self
		basicArcCenterX: aPoint x
		centerY: aPoint y
		radiusX: mr
		radiusY: mr
		rotationAngle: 0.0
		start: 0.0
		sweep: Float pi * 2;
		basicClosePath
]

{ #category : 'paths - absolute coordinates' }
VectorEngineAbstract >> abs_CubicBezierSmoothTo: aPoint control2: c2 [

	| mirroredControl |
	mirroredControl := previousCallX + (previousCallX - previousCallControlX)
		@ (previousCallY + (previousCallY - previousCallControlY)).
	self abs_CubicBezierTo: aPoint control1: mirroredControl control2: c2
]

{ #category : 'paths - absolute coordinates' }
VectorEngineAbstract >> abs_CubicBezierTo: aPoint control1: c1 control2: c2 [

	self
		basicCubicBezierToX: aPoint x
		y: aPoint y
		control1X: c1 x
		y: c1 y
		control2X: c2 x
		y: c2 y.
	previousCallX := aPoint x.
	previousCallY := aPoint y.
	previousCallControlX := c2 x.
	previousCallControlY := c2 y
]

{ #category : 'paths - absolute coordinates' }
VectorEngineAbstract >> abs_EllipseCenter: aPoint radiusX: mrx radiusY: mry [

	self
		basicArcCenterX: aPoint x
		centerY: aPoint y
		radiusX: mrx
		radiusY: mry
		rotationAngle: 0.0
		start: 0.0
		sweep: Float pi * 2;
		basicClosePath
]

{ #category : 'paths - absolute coordinates' }
VectorEngineAbstract >> abs_EllipseCenter: aPoint radiusX: mrx radiusY: mry rotationAngle: theta [

	self
		basicArcCenterX: aPoint x
		centerY: aPoint y
		radiusX: mrx
		radiusY: mry
		rotationAngle: theta
		start: 0.0
		sweep: Float pi * 2;
		basicClosePath
]

{ #category : 'paths - absolute coordinates' }
VectorEngineAbstract >> abs_EllipseCenter: aPoint radiusX: mrx radiusY: mry rotationAngle: theta start: startAngle sweep: sweepAngle [

	self
		basicArcCenterX: aPoint x
		centerY: aPoint y
		radiusX: mrx
		radiusY: mry
		rotationAngle: theta
		start: startAngle
		sweep: sweepAngle
]

{ #category : 'paths - absolute coordinates' }
VectorEngineAbstract >> abs_LineTo: aPoint [

	self basicLineToX: aPoint x y: aPoint y.
	previousCallX := aPoint x.
	previousCallY := aPoint y.
	previousCallControlX := previousCallX.
	previousCallControlY := previousCallY
]

{ #category : 'paths - absolute coordinates' }
VectorEngineAbstract >> abs_LineToX: xTo [

	self abs_LineTo: xTo @ previousCallY
]

{ #category : 'paths - absolute coordinates' }
VectorEngineAbstract >> abs_LineToY: yTo [

	self abs_LineTo: previousCallX @ yTo
]

{ #category : 'paths - absolute coordinates' }
VectorEngineAbstract >> abs_MoveTo: aPoint [

	self basicMoveToX: aPoint x y: aPoint y.
	previousCallX := aPoint x.
	previousCallY := aPoint y.
	previousCallControlX := previousCallX.
	previousCallControlY := previousCallY
]

{ #category : 'paths - absolute coordinates' }
VectorEngineAbstract >> abs_QuadraticBezierSmoothTo: aPoint [

	| mirroredControl |
	mirroredControl := previousCallX + (previousCallX - previousCallControlX)
		@ (previousCallY + (previousCallY - previousCallControlY)).
	self abs_QuadraticBezierTo: aPoint control: mirroredControl
]

{ #category : 'paths - absolute coordinates' }
VectorEngineAbstract >> abs_QuadraticBezierTo: aPoint control: cPoint [

	self
		basicQuadraticBezierToX: aPoint x
		y: aPoint y
		controlX: cPoint x
		y: cPoint y.
	previousCallX := aPoint x.
	previousCallY := aPoint y.
	previousCallControlX := cPoint x.
	previousCallControlY := cPoint y
]

{ #category : 'accessing' }
VectorEngineAbstract >> antiAliasingWidth: aNumber [

	antiAliasingWidth := aNumber
]

{ #category : 'private - paths - pixel coordinates' }
VectorEngineAbstract >> basicArcCenterX: cx centerY: cy radiusX: rx radiusY: ry rotationAngle: theta start: startAngle sweep: sweepAngle [

	| d hops angle thetaCos thetaSin xp yp x0 y0 |
	thetaCos := theta cos.
	thetaSin := theta sin.
	angle := startAngle.
	xp := angle cos * rx.
	yp := angle sin * ry.
	x0 := thetaCos * xp - (thetaSin * yp) + cx.
	y0 := thetaSin * xp + (thetaCos * yp) + cy.
	(startAngle ~= 0.0 or: [ sweepAngle ~= Float twoPi ])
		ifTrue: [ self basicLineToX: x0 y: y0 ]
		ifFalse: [
			self newTrajectoryFragment.
			pathFirstX := x0.
			pathFirstY := y0 ].

	hops := (rx + ry * 4 * sweepAngle abs / (2 * Float pi) * hopsPerPixel)
		        truncated + 1.
	d := sweepAngle / hops.

	self
		primArcCenterX: cx
		centerY: cy
		radiusX: rx
		radiusY: ry
		start: startAngle
		rotationCos: thetaCos
		rotationSin: thetaSin
		hops: hops
		angleDelta: d.

	angle := startAngle + sweepAngle.
	xp := angle cos * rx.
	yp := angle sin * ry.
	pathCurrentX := thetaCos * xp - (thetaSin * yp) + cx.
	pathCurrentY := thetaSin * xp + (thetaCos * yp) + cy
]

{ #category : 'private - paths - pixel coordinates' }
VectorEngineAbstract >> basicArcToX: x2 y: y2 radiusX: rx radiusY: ry angleOfXAxis: phi largeFlag: doLargerArc sweepFlag: useIncreasingAngles [

	| x1 y1 cosPhi sinPhi x12hd y12hd x1p y1p rxSq rySq x1pSq y1pSq bigSqR bigSqRNumerator bigSqRDenominator sign cxp cyp cx cy theta1 theta2 deltaTheta scaleSq scale newRx newRy |
	x1 := pathCurrentX.
	y1 := pathCurrentY.
	(x2 = x1 and: [ y2 = y1 ]) ifTrue: [ ^ self ].
	(rx = 0.0 or: [ ry = 0.0 ]) ifTrue: [ ^ self basicLineToX: x2 y: y2 ].
	rx < 0 ifTrue: [
		^ self
			  basicArcToX: x2
			  y: y2
			  radiusX: 0.0 - rx
			  radiusY: ry
			  angleOfXAxis: phi
			  largeFlag: doLargerArc
			  sweepFlag: useIncreasingAngles ].
	ry < 0 ifTrue: [
		^ self
			  basicArcToX: x2
			  y: y2
			  radiusX: rx
			  radiusY: 0.0 - ry
			  angleOfXAxis: phi
			  largeFlag: doLargerArc
			  sweepFlag: useIncreasingAngles ].

	cosPhi := phi cos.
	sinPhi := phi sin.
	x12hd := x1 - x2 * 0.5.
	y12hd := y1 - y2 * 0.5.
	x1p := cosPhi * x12hd + (sinPhi * y12hd).
	y1p := cosPhi * y12hd - (sinPhi * x12hd).

	rxSq := rx * rx.
	rySq := ry * ry.
	x1pSq := x1p * x1p.
	y1pSq := y1p * y1p.
	scaleSq := x1pSq / rxSq + (y1pSq / rySq).
	scaleSq > 1 ifTrue: [
		scale := scaleSq sqrt.
		newRx := scale * rx.
		newRy := scale * ry.
		(newRx = rx or: [ newRy = ry ]) ifTrue: [
			newRx := scaleSq * rx.
			newRy := scaleSq * ry ].
		^ self
			  basicArcToX: x2
			  y: y2
			  radiusX: newRx
			  radiusY: newRy
			  angleOfXAxis: phi
			  largeFlag: doLargerArc
			  sweepFlag: useIncreasingAngles ].
	bigSqRNumerator := rxSq * rySq - (rxSq * y1pSq) - (rySq * x1pSq).
	bigSqRDenominator := rxSq * y1pSq + (rySq * x1pSq).
	sign := doLargerArc = useIncreasingAngles
		        ifTrue: [ -1 ]
		        ifFalse: [ 1 ].
	bigSqR := (bigSqRNumerator / bigSqRDenominator max: 0.0) sqrt * sign.
	cxp := bigSqR * rx * y1p / ry.
	cyp := 0.0 - (bigSqR * ry * x1p / rx).

	cx := cosPhi * cxp - (sinPhi * cyp) + (x1 + x2 * 0.5).
	cy := sinPhi * cxp + (cosPhi * cyp) + (y1 + y2 * 0.5).

	theta1 := (x1p - cxp / rx @ (y1p - cyp / ry)) theta.
	theta2 := (0 - x1p - cxp / rx @ (0 - y1p - cyp / ry)) theta.
	deltaTheta := theta2 - theta1.
	useIncreasingAngles = (deltaTheta > 0) ifFalse: [
		deltaTheta > 0
			ifTrue: [ deltaTheta := deltaTheta - Float pi - Float pi ]
			ifFalse: [ deltaTheta := deltaTheta + Float pi + Float pi ] ].

	self
		basicArcCenterX: cx
		centerY: cy
		radiusX: rx
		radiusY: ry
		rotationAngle: phi
		start: theta1
		sweep: deltaTheta
]

{ #category : 'private - paths - pixel coordinates' }
VectorEngineAbstract >> basicClosePath [

	self basicLineToX: pathFirstX y: pathFirstY
]

{ #category : 'private - paths - pixel coordinates' }
VectorEngineAbstract >> basicCubicBezierToX: xTo y: yTo control1X: xC1 y: yC1 control2X: xC2 y: yC2 [

	| dx dy hops |
	dx := (xC1 - pathCurrentX) abs + (xC2 - xC1) abs + (xTo - xC2) abs.
	dy := (yC1 - pathCurrentY) abs + (yC2 - yC1) abs + (yTo - yC2) abs.
	hops := ((dx max: dy) * hopsPerPixel) truncated + 1.

	self
		primCubicBezierFromX: pathCurrentX
		y: pathCurrentY
		toX: xTo
		y: yTo
		control1X: xC1
		y: yC1
		control2X: xC2
		y: yC2
		hops: hops.

	pathCurrentX := xTo.
	pathCurrentY := yTo
]

{ #category : 'private - paths - pixel coordinates' }
VectorEngineAbstract >> basicLineToX: xTo y: yTo [

	| dx dy hops incrementX incrementY |
	dy := yTo - pathCurrentY.
	dx := xTo - pathCurrentX.
	hops := ((dx abs max: dy abs) * hopsPerPixel) truncated + 1.
	incrementX := dx * 1.0 / hops.
	incrementY := dy * 1.0 / hops.

	self
		primLineFromX: pathCurrentX
		y: pathCurrentY
		toX: xTo
		y: yTo
		hops: hops
		incrementX: incrementX
		incrementY: incrementY.

	pathCurrentX := xTo.
	pathCurrentY := yTo
]

{ #category : 'private - paths - pixel coordinates' }
VectorEngineAbstract >> basicMoveToX: x y: y [

	self newTrajectoryFragment.
	pathFirstX := x.
	pathFirstY := y.
	pathCurrentX := x.
	pathCurrentY := y
]

{ #category : 'private - paths - pixel coordinates' }
VectorEngineAbstract >> basicQuadraticBezierToX: xTo y: yTo controlX: xC y: yC [

	| dx dy hops |
	dx := (xC - pathCurrentX) abs + (xTo - xC) abs.
	dy := (yC - pathCurrentY) abs + (yTo - yC) abs.
	hops := ((dx max: dy) * hopsPerPixel) truncated + 1.

	self
		primQuadraticBezierFromX: pathCurrentX
		y: pathCurrentY
		toX: xTo
		y: yTo
		controlX: xC
		y: yC
		hops: hops.

	pathCurrentX := xTo.
	pathCurrentY := yTo
]

{ #category : 'accessing' }
VectorEngineAbstract >> clippingMorph: aMorph [

	clippingMorphId := aMorph ifNil: [ 0 ] ifNotNil: [ aMorph morphId ]
]

{ #category : 'accessing' }
VectorEngineAbstract >> currentMorph: aMorph [

	currentMorphId := aMorph ifNil: [ 0 ] ifNotNil: [ aMorph morphId ]
]

{ #category : 'text' }
VectorEngineAbstract >> displayUtf8: aByteArray at: aPoint trueTypeFont: aTTFontDescription color: aColor scaleX: ssx scaleY: ssy [

	"ssx and ssy to honor font pointSize"

	| destX destY sx sy contourData contourDataIndexes trueTypeScale cpX cpY epX epY moveToX moveToY advanceWidth boundsLeft boundsRight boundsTop boundsBottom numContours numBeziers baseIndex |
	trueTypeScale := 1.0 / aTTFontDescription letterMTopSideBearing.
	sx := ssx * trueTypeScale.
	sy := ssy * trueTypeScale.
	contourData := aTTFontDescription contourDataForUtf8.
	contourDataIndexes := aTTFontDescription contourDataIndexesByUtf8.
	self fillColor: aColor do: [
		destY := aPoint y.
		destX := aPoint x.
		baseIndex := 0.
		aByteArray do: [ :byte |
			| i |
			i := contourDataIndexes at: baseIndex + byte + 1.
			i < 0
				ifTrue: [ baseIndex := i negated ]
				ifFalse: [
					advanceWidth := contourData at: i.
					i := i + 1.
					boundsLeft := contourData at: i.
					i := i + 1.
					boundsRight := contourData at: i.
					i := i + 1.
					boundsTop := contourData at: i.
					i := i + 1.
					boundsBottom := contourData at: i.
					i := i + 1.
					numContours := (contourData at: i) asInteger.
					i := i + 1.
					numContours timesRepeat: [
						numBeziers := (contourData at: i) asInteger.
						i := i + 1.
						moveToX := contourData at: i.
						i := i + 1.
						moveToY := contourData at: i.
						i := i + 1.
						self abs_MoveTo: (moveToX * sx + destX) @ (moveToY * sy + destY).
						numBeziers timesRepeat: [
							epX := contourData at: i.
							i := i + 1.
							epY := contourData at: i.
							i := i + 1.
							cpX := contourData at: i.
							i := i + 1.
							cpY := contourData at: i.
							i := i + 1.
							self
								rel_QuadraticBezierTo: (epX * sx) @ (epY * sy)
								control: (cpX * sx) @ (cpY * sy) ] ].
					destX := destX + (advanceWidth * sx).
					baseIndex := 0 ] ] ]
]

{ #category : 'paths - absolute coordinates' }
VectorEngineAbstract >> do_ClosePath [

	"abs/rel meaningless here"

	self basicClosePath.
	previousCallX := pathCurrentX.
	previousCallY := pathCurrentY.
	previousCallControlX := previousCallX.
	previousCallControlY := previousCallY
]

{ #category : 'stroke & fill' }
VectorEngineAbstract >> fillColor: aFillColor do: pathCommandsBlock [

	"Prepare parameters for drawing fill."

	(aFillColor isNil or: [ aFillColor alpha = 0.0 ]) ifTrue: [ ^ self ].
	self pvtStrokeWidth: 0.0.
	self pvtStrokeColor: nil.
	self pvtFillColor: aFillColor.
	hopsPerPixel := 8. "See #experimentHopsPerPixel3"
	self initializePath.
	pathCommandsBlock valueWithPossibleArgument: self.
	self finishPath: true
]

{ #category : 'abstract' }
VectorEngineAbstract >> finishPath: aPath [
^ self subclassResponsibility
]

{ #category : 'accessing' }
VectorEngineAbstract >> geometryTransformation: aGeometryTransformation [
	"No-op. AffineTransformation (Cuis-specific) removed; coordinates pass directly to rendering primitives."
]

{ #category : 'private' }
VectorEngineAbstract >> initializeOnForm: aForm [

	clippingMorphId := 0.
	currentMorphId := 0.
	self pvtSetForm: aForm
]

{ #category : 'private' }
VectorEngineAbstract >> initializePath [

	pathFirstX := 0.
	pathFirstY := 0.
	pathCurrentX := 0.0.
	pathCurrentY := 0.0.
	previousCallX := 0.0.
	previousCallY := 0.0.
	previousCallControlX := previousCallX.
	previousCallControlY := previousCallY.
	self newTrajectoryFragment
]

{ #category : 'morphic' }
VectorEngineAbstract >> morph: aMorph isAtPoint: aPoint [

	| index |
	index := aPoint y * targetWidth + aPoint x + 1.
	(index between: 1 and: morphIds size) ifFalse: [ ^ false ].
	^ (morphIds at: index) = aMorph morphId
]

{ #category : 'accessing' }
VectorEngineAbstract >> morphBoundsAfterDraw [

	"In targetForm coordinates.
	Doesn't include any clipping rect (neither clip rect parameter to bound drawn area, nor possible clipping to owner shape or bounds).
	Only valid _after_ drawing currentMorph."

	^ morphBoundsLeft @ morphBoundsTop corner:
		  morphBoundsRight @ morphBoundsBottom + 1
]

{ #category : 'private' }
VectorEngineAbstract >> newTrajectoryFragment [
^self subclassResponsibility

]

{ #category : 'primitive algorithms' }
VectorEngineAbstract >> primArcCenterX: cx centerY: cy radiusX: rx radiusY: ry start: startAngle rotationCos: thetaCos rotationSin: thetaSin hops: hops angleDelta: d [
^self subclassResponsibility
]

{ #category : 'primitive algorithms' }
VectorEngineAbstract >> primCubicBezierFromX: xFrom y: yFrom toX: xTo y: yTo control1X: xControl1 y: yControl1 control2X: xControl2 y: yControl2 hops: hops [
^self subclassResponsibility
]

{ #category : 'primitive algorithms' }
VectorEngineAbstract >> primLineFromX: xFrom y: yFrom toX: xTo y: yTo hops: hops incrementX: incrementX incrementY: incrementY [

^self subclassResponsibility
]

{ #category : 'primitive algorithms' }
VectorEngineAbstract >> primQuadraticBezierFromX: xFrom y: yFrom toX: xTo y: yTo controlX: xControl y: yControl hops: hops [
	^self subclassResponsibility
]

{ #category : 'abstract' }
VectorEngineAbstract >> pvtFillColor: aFillColor [
^ self subclassResponsibility
]

{ #category : 'private' }
VectorEngineAbstract >> pvtSetForm: aForm [

	targetForm := aForm.
	morphIds := WordArray new: targetForm width * targetForm height.
	targetWidth := targetForm width.
	self resetMorphBounds.
	self clipRect: targetForm boundingBox.
	self antiAliasingWidth: self class defaultAntiAliasingWidth
]

{ #category : 'abstract' }
VectorEngineAbstract >> pvtStrokeColor: aColor [
^self subclassResponsibility
]

{ #category : 'private' }
VectorEngineAbstract >> pvtStrokeWidth: aNumber [

	strokeWidth := aNumber
]

{ #category : 'paths - relative coordinates' }
VectorEngineAbstract >> rel_ArcTo: aPoint radiusX: mrx radiusY: mry angleOfXAxis: theta largeFlag: doLargerArc sweepFlag: useIncreasingAngles [

	self
		abs_ArcTo: previousCallX + aPoint x @ (previousCallY + aPoint y)
		radiusX: mrx
		radiusY: mry
		angleOfXAxis: theta
		largeFlag: doLargerArc
		sweepFlag: useIncreasingAngles
]

{ #category : 'paths - relative coordinates' }
VectorEngineAbstract >> rel_CubicBezierSmoothTo: aPoint control2: c2 [

	self
		abs_CubicBezierSmoothTo: previousCallX + aPoint x @ (previousCallY + aPoint y)
		control2: previousCallX + c2 x @ (previousCallY + c2 y)
]

{ #category : 'paths - relative coordinates' }
VectorEngineAbstract >> rel_CubicBezierTo: aPoint control1: c1 control2: c2 [

	self
		abs_CubicBezierTo: previousCallX + aPoint x @ (previousCallY + aPoint y)
		control1: previousCallX + c1 x @ (previousCallY + c1 y)
		control2: previousCallX + c2 x @ (previousCallY + c2 y)
]

{ #category : 'paths - relative coordinates' }
VectorEngineAbstract >> rel_LineTo: aPoint [

	self abs_LineTo: previousCallX + aPoint x @ (previousCallY + aPoint y)
]

{ #category : 'paths - relative coordinates' }
VectorEngineAbstract >> rel_MoveTo: aPoint [

	self abs_MoveTo: previousCallX + aPoint x @ (previousCallY + aPoint y)
]

{ #category : 'paths - relative coordinates' }
VectorEngineAbstract >> rel_QuadraticBezierSmoothTo: aPoint [

	self abs_QuadraticBezierSmoothTo: previousCallX + aPoint x @ (previousCallY + aPoint y)
]

{ #category : 'paths - relative coordinates' }
VectorEngineAbstract >> rel_QuadraticBezierTo: aPoint control: cPoint [

	self
		abs_QuadraticBezierTo: previousCallX + aPoint x @ (previousCallY + aPoint y)
		control: previousCallX + cPoint x @ (previousCallY + cPoint y)
]

{ #category : 'private' }
VectorEngineAbstract >> resetMorphBounds [

	morphBoundsTop := targetForm height - 1.
	morphBoundsBottom := 0.
	morphBoundsLeft := targetWidth - 1.
	morphBoundsRight := 0
]

{ #category : 'stroke & fill' }
VectorEngineAbstract >> strokeWidth: clientStrokeWidth color: aStrokeColor do: pathCommandsBlock [

	"Prepare parameters for drawing stroke."

	self
		strokeWidth: clientStrokeWidth
		color: aStrokeColor
		do: pathCommandsBlock
		ensureClosePath: false
]

{ #category : 'stroke & fill' }
VectorEngineAbstract >> strokeWidth: clientStrokeWidth color: aStrokeColor do: pathCommandsBlock ensureClosePath: ensureClosePath [

	"Prepare parameters for drawing stroke."

	| aStrokeWidth |
	(aStrokeColor isNil or: [ aStrokeColor alpha = 0.0 ]) ifTrue: [
		^ self ].
	clientStrokeWidth = 0.0 ifTrue: [ ^ self ].
	aStrokeWidth := clientStrokeWidth.
	aStrokeWidth < antiAliasingWidth
		ifTrue: [
			self pvtStrokeWidth: antiAliasingWidth.
			self pvtStrokeColor: (aStrokeColor alpha:
					 aStrokeColor alpha * aStrokeWidth / antiAliasingWidth) ]
		ifFalse: [
			self pvtStrokeWidth: aStrokeWidth.
			self pvtStrokeColor: aStrokeColor ].
	self pvtFillColor: nil.
	hopsPerPixel := 10.0 / strokeWidth + 1. "See #experimentHopsPerPixel2"

	self initializePath.
	pathCommandsBlock valueWithPossibleArgument: self.
	self finishPath: ensureClosePath
]

{ #category : 'stroke & fill' }
VectorEngineAbstract >> strokeWidth: clientStrokeWidth color: aStrokeColor fillColor: aFillColor do: pathCommandsBlock [

	"Prepare parameters for drawing stroke, fill, or both."

	| aStrokeWidth |
	(aStrokeColor isNil or: [ aStrokeColor alpha = 0.0 ]) ifTrue: [
		^ self fillColor: aFillColor do: pathCommandsBlock ].
	clientStrokeWidth = 0.0 ifTrue: [
		^ self fillColor: aFillColor do: pathCommandsBlock ].
	(aFillColor isNil or: [ aFillColor alpha = 0.0 ]) ifTrue: [
		^ self
			  strokeWidth: clientStrokeWidth
			  color: aStrokeColor
			  do: pathCommandsBlock ].

	aStrokeWidth := clientStrokeWidth.
	(aStrokeWidth < antiAliasingWidth and: [ aStrokeColor ~= aFillColor ])
		ifTrue: [
			self fillColor: aFillColor do: pathCommandsBlock.
			self
				strokeWidth: clientStrokeWidth
				color: aStrokeColor
				do: pathCommandsBlock
				ensureClosePath: true.
			^ self ].

	self pvtStrokeWidth: aStrokeWidth.
	self pvtStrokeColor: aStrokeColor.
	self pvtFillColor: aFillColor.
	hopsPerPixel := aStrokeWidth < antiAliasingWidth
		                ifTrue: [ 8 ]
		                ifFalse: [ 10.0 / strokeWidth + 1 max: 2 ].

	self initializePath.
	pathCommandsBlock valueWithPossibleArgument: self.
	self finishPath: true
]
