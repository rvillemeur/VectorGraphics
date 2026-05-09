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
- `pathFirstX/Y`         — position of the most recent `abs_MoveToX:y:`, used by `do_ClosePath`
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
- `abs_MoveToX:y:`         — start new subpath
- `abs_LineToX:y:`         — straight line
- `abs_LineToX:`           — horizontal line (keeps current y)
- `abs_LineToY:`           — vertical line (keeps current x)
- `abs_CubicBezierToX:y:control1X:y:control2X:y:` — cubic Bézier
- `abs_QuadraticBezierToX:y:controlX:y:` — quadratic Bézier
- `abs_ArcToX:y:radiusX:radiusY:...`   — elliptical arc
- `abs_EllipseCenterX:y:radiusX:radiusY:...` — full ellipse
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
VectorEngineAbstract >> abs_ArcToX: cx y: cy radiusX: mrx radiusY: mry angleOfXAxis: theta largeFlag: doLargerArc sweepFlag: useIncreasingAngles [

	" (VectorEngineSubPixel onForm: Display) 
		strokeWidth: 1.0 color: Color black do: [ :engine | 
					engine 			abs_MoveToX: 100 y: 100;			abs_ArcToX: 200 y: 200 radiusX: 200 radiusY: 100 angleOfXAxis: 0 largeFlag: true sweepFlag: true;			abs_MoveToX: 100 y: 100;			abs_ArcToX: 200 y: 200 radiusX: 200 radiusY: 100 angleOfXAxis: 0 largeFlag: true sweepFlag: false ].(VectorEngineSubPixel onForm: Display)	geometryTransformation: (AffineTransformation withRadians: 0.5 scale: 1.2 position: 200@100); 	strokeWidth: 1.0 color: Color black do: [ :engine |		engine 			abs_MoveToX: 100 y: 100;			abs_ArcToX: 200 y: 200 radiusX: 200 radiusY: 100 angleOfXAxis: 0 largeFlag: true sweepFlag: true;			abs_MoveToX: 100 y: 100;			abs_ArcToX: 200 y: 200 radiusX: 200 radiusY: 100 angleOfXAxis: 0 largeFlag: true sweepFlag: false ].Display forceToScreen"

	"geometryTransformation (AffineTransformation) removed — coordinates passed through as-is"
	self
		basicArcToX: cx
		y: cy
		radiusX: mrx
		radiusY: mry
		angleOfXAxis: theta
		largeFlag: doLargerArc
		sweepFlag: useIncreasingAngles
]

{ #category : 'paths - absolute coordinates' }
VectorEngineAbstract >> abs_CircleCenterX: cx y: cy radius: mr [

	" (VectorEngineSubPixel onForm: Display) 	strokeWidth: 2.0 color: Color black do: [ :engine | 		engine 			abs_CircleCenterX: 200 y: 150 radius: 80]. Display forceToScreen " 
	"geometryTransformation (AffineTransformation) removed — coordinates passed through as-is"
	self
		basicArcCenterX: cx
		centerY: cy
		radiusX: mr
		radiusY: mr
		rotationAngle: 0.0
		start: 0.0
		sweep: Float pi * 2;
		basicClosePath
]

{ #category : 'paths - absolute coordinates' }
VectorEngineAbstract >> abs_CubicBezierSmoothToX: xTo y: yTo control2X: xC y: yC [

	"Cubic Bezier
	http://en.wikipedia.org/wiki/Bezier_curve
	Smooth squence of curves: use as control1 point, last used control2 point."

	"Check that behavior is correct!"

	"
(VectorEngineSubPixel  onForm: Display)
	geometryTransformation: (AffineTransformation withRadians: 0 scale: 1.0 position: 100@300);
	strokeWidth: 10 color: (Color green alpha: 0.7) do: [ :engine |
		engine abs_CircleCenterX: 150 y: 300 radius: 10.
		engine abs_CircleCenterX: 600 y: 400 radius: 6.
		engine abs_MoveToX: 100 y: 50.
		engine
			abs_CubicBezierToX: 600 y: 100 control1X: 150 y: 300 control2X: 600 y: 400
			].
(VectorEngineSubPixel  onForm: Display)
	geometryTransformation: (AffineTransformation withRadians: 0 scale: 1.0 position: 100@300);
	strokeWidth: 10 color: (Color red alpha: 0.7) do: [ :engine |
		engine abs_CircleCenterX: 600 y: -200 radius: 10.
		engine abs_CircleCenterX: 100 y: -100 radius: 6.
		engine abs_MoveToX: 600 y: 100.
		engine
			abs_CubicBezierToX: 300 y: 100 control1X: 600 y: -200 control2X: 100 y: -100
			].
Display forceToScreen.
	"

	"
(VectorEngineSubPixel onForm: Display)
	geometryTransformation: (AffineTransformation withRadians: 0 scale: 1.0 position: 100@300);
	strokeWidth: 10 color: (Color black alpha: 0.7) fillColor: (Color orange alpha: 0.8) do: [ :engine |
		engine abs_MoveToX: 100 y: 50.
		engine
			abs_CubicBezierToX: 600 y: 100 control1X: 150 y: 300 control2X: 600 y: 400;
			abs_CubicBezierSmoothToX: 300 y: 100 control2X: 100 y: -100
			].
Display forceToScreen
	"

	| mirroredContolX mirroredContolY |
	mirroredContolX := previousCallX
	                   + (previousCallX - previousCallControlX).
	mirroredContolY := previousCallY
	                   + (previousCallY - previousCallControlY).
	self
		abs_CubicBezierToX: xTo
		y: yTo
		control1X: mirroredContolX
		y: mirroredContolY
		control2X: xC
		y: yC
]

{ #category : 'paths - absolute coordinates' }
VectorEngineAbstract >> abs_CubicBezierToX: xTo y: yTo control1X: xC1 y: yC1 control2X: xC2 y: yC2 [

	"Cubic Bezier
	http://en.wikipedia.org/wiki/Bezier_curve"

	"
(VectorEngineSubPixel onForm: Display)
	strokeWidth: 1.0 color: Color black do: [ :engine |
		engine
			abs_MoveToX: 100 y: 100;
			abs_CubicBezierToX: 300 y: 200 control1X: 110 y: 110 control2X: 200 y: 200 ].
Display forceToScreen
	"

	"
(VectorEngineSubPixel onForm: Display)
	strokeWidth: 10 color: (Color black alpha: 0.7) fillColor: (Color orange alpha: 0.8) do: [ :engine |
		engine abs_MoveToX: 100 y: 50.
		engine
			abs_CubicBezierToX: 600 y: 100
			control1X: 150 y: 300
			control2X: 600 y: 400 ].
Display forceToScreen
	"

	"geometryTransformation (AffineTransformation) removed — coordinates passed through as-is"
	self
		basicCubicBezierToX: xTo
		y: yTo
		control1X: xC1
		y: yC1
		control2X: xC2
		y: yC2.
	previousCallX := xTo.
	previousCallY := yTo.
	previousCallControlX := xC2.
	previousCallControlY := yC2
]

{ #category : 'paths - absolute coordinates' }
VectorEngineAbstract >> abs_EllipseCenterX: cx y: cy radiusX: mrx radiusY: mry [

	"
(VectorEngineSubPixel onForm: Display)
	strokeWidth: 2.0 color: Color black do: [ :engine |
		engine
			abs_EllipseCenterX: 200 y: 150 radiusX: 100 radiusY: 50].
(VectorEngineSubPixel onForm: Display)
	geometryTransformation: (AffineTransformation withRadians: 1 scale: 1.2 position: 200@100);
	strokeWidth: 2.0 color: Color black do: [ :engine |
		engine
			abs_EllipseCenterX: 200 y: 150 radiusX: 100 radiusY: 50].
Display forceToScreen
"

	"geometryTransformation (AffineTransformation) removed — coordinates passed through as-is"
	self
		basicArcCenterX: cx
		centerY: cy
		radiusX: mrx
		radiusY: mry
		rotationAngle: 0.0
		start: 0.0
		sweep: Float pi * 2;
		basicClosePath
]

{ #category : 'paths - absolute coordinates' }
VectorEngineAbstract >> abs_EllipseCenterX: cx y: cy radiusX: mrx radiusY: mry rotationAngle: theta [

	"
(VectorEngineSubPixel onForm: Display)
	strokeWidth: 2.0 color: Color black do: [ :engine |
		engine
			abs_EllipseCenterX: 200 y: 150 radiusX: 100 radiusY: 50 rotationAngle: -0.5 ].
(VectorEngineSubPixel onForm: Display)
	geometryTransformation: (AffineTransformation withRadians: 1 scale: 1.2 position: 200@100);
	strokeWidth: 2.0 color: Color black do: [ :engine |
		engine
			abs_EllipseCenterX: 200 y: 150 radiusX: 100 radiusY: 50 rotationAngle: -0.5 ].
Display forceToScreen
"

	"geometryTransformation (AffineTransformation) removed — coordinates passed through as-is"
	self
		basicArcCenterX: cx
		centerY: cy
		radiusX: mrx
		radiusY: mry
		rotationAngle: theta
		start: 0.0
		sweep: Float pi * 2;
		basicClosePath
]

{ #category : 'paths - absolute coordinates' }
VectorEngineAbstract >> abs_EllipseCenterX: cx y: cy radiusX: mrx radiusY: mry rotationAngle: theta start: startAngle sweep: sweepAngle [

	"Currently draws a line from pathCurrentX@pathCurrentY to start (if startAngle ~= 0.0 or sweepAngle ~= Float twoPi).
	This could be useful for proper fills. But might not be what is desired in some cases.
	Implement desired behavior when clear."

	"
(VectorEngineSubPixel onForm: Display)
	strokeWidth: 2.0 color: Color black do: [ :engine |
		engine
			abs_EllipseCenterX: 200 y: 150 radiusX: 100 radiusY: 50 rotationAngle: 0.0 start: 0.1 sweep: 6 ].
(VectorEngineSubPixel onForm: Display)
	geometryTransformation: (AffineTransformation withRadians: 0.5 scale: 1.0 position: 200@100);
	strokeWidth: 2.0 color: Color black do: [ :engine |
		engine
			abs_EllipseCenterX: 200 y: 150 radiusX: 100 radiusY: 50 rotationAngle: 0.0 start: 0.1 sweep: 6].
(VectorEngineSubPixel onForm: Display)
	strokeWidth: 2.0 color: Color black do: [ :engine |
		engine
			abs_EllipseCenterX: 200 y: 350 radiusX: 100 radiusY: 50 rotationAngle: 0.5 start: 0.1 sweep: 6 ].
Display forceToScreen.
"

	"geometryTransformation (AffineTransformation) removed — coordinates passed through as-is"
	self
		basicArcCenterX: cx
		centerY: cy
		radiusX: mrx
		radiusY: mry
		rotationAngle: theta
		start: startAngle
		sweep: sweepAngle
]

{ #category : 'paths - absolute coordinates' }
VectorEngineAbstract >> abs_LineToX: xTo [

	"
(VectorEngineSubPixel onForm: Display)
	strokeWidth: 2.0 color: Color black do: [ :engine |
		engine
			abs_MoveToX: 100 y: 100;
			abs_LineToX: 200 ].
Display forceToScreen
"

	"
(VectorEngineSubPixel onForm: Display)
	geometryTransformation: (AffineTransformation withScale: 10);
	strokeWidth: 2 color: (Color black alpha: 0.7) fillColor: (Color orange alpha: 0.4) do: [ :engine |
		engine abs_MoveToX: 10 y: 5.
		engine abs_LineToX: 50.
		engine abs_LineToX: 60 y: 10 ].
Display forceToScreen
"

	self abs_LineToX: xTo y: previousCallY
]

{ #category : 'paths - absolute coordinates' }
VectorEngineAbstract >> abs_LineToX: xTo y: yTo [

	"
(VectorEngineSubPixel onForm: Display)
	strokeWidth: 2.0 color: Color black do: [ :engine |
		engine
			abs_MoveToX: 100 y: 100;
			abs_LineToX: 200 y: 150 ].
Display forceToScreen
"

	"
(VectorEngineSubPixel onForm: Display)
	geometryTransformation: (AffineTransformation withScale: 10);
	strokeWidth: 2 color: (Color black alpha: 0.7) fillColor: (Color orange alpha: 0.4) do: [ :engine |
		engine abs_MoveToX: 10 y: 5.
		engine abs_LineToX: 15 y: 30.
		engine abs_LineToX: 60 y: 10 ].
Display forceToScreen
"

	"geometryTransformation (AffineTransformation) removed — coordinates passed through as-is"
	self basicLineToX: xTo y: yTo.
	previousCallX := xTo.
	previousCallY := yTo.
	previousCallControlX := previousCallX.
	previousCallControlY := previousCallY
]

{ #category : 'paths - absolute coordinates' }
VectorEngineAbstract >> abs_LineToY: yTo [

	"
(VectorEngineSubPixel onForm: Display)
	strokeWidth: 2.0 color: Color black do: [ :engine |
		engine
			abs_MoveToX: 100 y: 100;
			abs_LineToY: 200 ].
Display forceToScreen
"

	"
(VectorEngineSubPixel onForm: Display)
	geometryTransformation: (AffineTransformation withScale: 10);
	strokeWidth: 2 color: (Color black alpha: 0.7) fillColor: (Color orange alpha: 0.4) do: [ :engine |
		engine abs_MoveToX: 10 y: 5.
		engine abs_LineToY: 50.
		engine abs_LineToX: 60 y: 10 ].
Display forceToScreen
"

	self abs_LineToX: previousCallX y: yTo
]

{ #category : 'paths - absolute coordinates' }
VectorEngineAbstract >> abs_MoveToX: x y: y [

	"
(VectorEngineSubPixel onForm: Display)
	strokeWidth: 1.0 color: Color black do: [ :engine |
		engine
			abs_MoveToX: 100 y: 100;
			abs_LineToX: 200 y: 150 ].
Display forceToScreen
"

	"
(VectorEngineSubPixel onForm: Display)
	geometryTransformation: (AffineTransformation withScale: 10);
	strokeWidth: 2 color: (Color black alpha: 0.7) fillColor: (Color orange alpha: 0.4) do: [ :engine |
		engine abs_MoveToX: 10 y: 5.
		engine abs_LineToX: 15 y: 30.
		engine abs_LineToX: 60 y: 10 ].
Display forceToScreen
"

	"geometryTransformation (AffineTransformation) removed — coordinates passed through as-is"
	self basicMoveToX: x y: y.
	previousCallX := x.
	previousCallY := y.
	previousCallControlX := previousCallX.
	previousCallControlY := previousCallY
]

{ #category : 'paths - absolute coordinates' }
VectorEngineAbstract >> abs_QuadraticBezierSmoothToX: xTo y: yTo [

	"
(VectorEngineSubPixel onForm: Display)
	geometryTransformation: (AffineTransformation withRadians: 0 scale: 1.0 position: 100@300);
	strokeWidth: 10 color: (Color green alpha: 0.7) do: [ :engine |
		engine abs_CircleCenterX: 450 y: 300 radius: 10.
		engine abs_MoveToX: 100 y: 50.
		engine
			abs_QuadraticBezierToX: 600 y: 100 controlX: 450 y: 300
			].
(VectorEngineSubPixel onForm: Display)
	geometryTransformation: (AffineTransformation withRadians: 0 scale: 1.0 position: 100@300);
	strokeWidth: 10 color: (Color red alpha: 0.7) do: [ :engine |
		engine abs_CircleCenterX: 750 y: -100 radius: 10.
		engine abs_MoveToX: 600 y: 100.
		engine
			abs_QuadraticBezierToX: 300 y: 100 controlX: 750 y: -100
			].
Display forceToScreen.
"

	"
(VectorEngineSubPixel onForm: Display)
	geometryTransformation: (AffineTransformation withRadians: 0 scale: 1.0 position: 100@300);
	strokeWidth: 10 color: (Color black alpha: 0.7) fillColor: (Color orange alpha: 0.8) do: [ :engine |
		engine abs_MoveToX: 100 y: 50.
		engine
			abs_QuadraticBezierToX: 600 y: 100 controlX: 450 y: 300;
			abs_QuadraticBezierSmoothToX: 300 y: 100
			].
Display forceToScreen
"

	| mirroredContolX mirroredContolY |
	mirroredContolX := previousCallX
	                   + (previousCallX - previousCallControlX).
	mirroredContolY := previousCallY
	                   + (previousCallY - previousCallControlY).
	self
		abs_QuadraticBezierToX: xTo
		y: yTo
		controlX: mirroredContolX
		y: mirroredContolY
]

{ #category : 'paths - absolute coordinates' }
VectorEngineAbstract >> abs_QuadraticBezierToX: xTo y: yTo controlX: xC y: yC [

	"
(VectorEngineSubPixel onForm: Display)
	strokeWidth: 3.0 color: Color black do: [ :engine |
		engine
			abs_MoveToX: 100 y: 100;
			abs_QuadraticBezierToX: 300 y: 200 controlX: 100 y: 210 ].
Display forceToScreen
	"

	"
(VectorEngineSubPixel onForm: Display)
	geometryTransformation: (AffineTransformation withRadians: 1 scale: 3 position: 200@100);
	strokeWidth: 2 color: (Color black alpha: 0.7) fillColor: (Color orange alpha: 0.4) do: [ :engine |
		engine abs_MoveToX: 10 y: 5.
		engine abs_QuadraticBezierToX: 60 y: 10 controlX: 15 y: 30 ].
Display forceToScreen
	"

	"geometryTransformation (AffineTransformation) removed — coordinates passed through as-is"
	self
		basicQuadraticBezierToX: xTo
		y: yTo
		controlX: xC
		y: yC.
	previousCallX := xTo.
	previousCallY := yTo.
	previousCallControlX := xC.
	previousCallControlY := yC
]

{ #category : 'accessing' }
VectorEngineAbstract >> antiAliasingWidth: aNumber [

	antiAliasingWidth := aNumber
]

{ #category : 'private - paths - pixel coordinates' }
VectorEngineAbstract >> basicArcCenterX: cx centerY: cy radiusX: rx radiusY: ry rotationAngle: theta start: startAngle sweep: sweepAngle [

	"
(VectorEngineSubPixel onForm: Display)
	strokeWidth: 2.0 color: Color black fillColor: Color red do: [ :engine |
		engine basicArcCenterX: 100 centerY: 100 radiusX: 80 radiusY: 40 rotationAngle: -0.2 start: 0 sweep: Float pi * 2 ].
Display forceToScreen.
"

	| d hops angle thetaCos thetaSin xp yp x0 y0 |
	"Por supuesto probar tambien rx no igual a ry, y uno (o ambos) menor que el ancho de trazo..."
	thetaCos := theta cos.
	thetaSin := theta sin.
	angle := startAngle.
	xp := angle cos * rx.
	yp := angle sin * ry.
	x0 := thetaCos * xp - (thetaSin * yp) + cx.
	y0 := thetaSin * xp + (thetaCos * yp) + cy.
	(startAngle ~= 0.0 or: [ sweepAngle ~= Float twoPi ])
		ifTrue: [ "If an arc (not whole circle/ellipse, join with a line, to ensure closed path. For example, window frames" 
			self basicLineToX: x0 y: y0 ]
		ifFalse: [ "trajectory starts here. Eventually, #closePath should draw a line to here""Next point will be first in a new trajectory fragment"
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

	"
(VectorEngineSubPixel onForm: Display)
	strokeWidth: 1.0 color: Color black do: [ :engine |
		engine
			basicMoveToX: 100 y: 100;
			basicArcToX: 200 y: 200 radiusX: 200 radiusY: 100 angleOfXAxis: 0 largeFlag: true sweepFlag: true;
			basicMoveToX: 100 y: 100;
			basicArcToX: 200 y: 200 radiusX: 200 radiusY: 100 angleOfXAxis: 0 largeFlag: true sweepFlag: false ].
Display forceToScreen
"

	"Calcular: cx, cy, rx, ry, phi, theta1, deltaTheta"

	| x1 y1 cosPhi sinPhi x12hd y12hd x1p y1p rxSq rySq x1pSq y1pSq bigSqR bigSqRNumerator bigSqRDenominator sign cxp cyp cx cy theta1 theta2 deltaTheta scaleSq scale newRx newRy |
	x1 := pathCurrentX.
	y1 := pathCurrentY.
	"Handle out of range parameters as requested by the w3 implementation notes"
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
	"step 1 in http://www.w3.org/TR/SVG/implnote.html#ArcImplementationNotes"
	x12hd := x1 - x2 * 0.5.
	y12hd := y1 - y2 * 0.5.
	x1p := cosPhi * x12hd + (sinPhi * y12hd).
	y1p := cosPhi * y12hd - (sinPhi * x12hd).

	"step 2"
	rxSq := rx * rx.
	rySq := ry * ry.
	x1pSq := x1p * x1p.
	y1pSq := y1p * y1p.
	"ensure radii are large enough"
	scaleSq := x1pSq / rxSq + (y1pSq / rySq).
	scaleSq > 1 ifTrue: [ 
		scale := scaleSq sqrt.
		newRx := scale * rx.
		newRy := scale * ry.
		(newRx = rx or: [ newRy = ry ]) ifTrue: [ "This happens when scaleSq is so close to 1, that the multiplication rounds to the same numbers"
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
	bigSqR := (bigSqRNumerator / bigSqRDenominator max: 0.0) sqrt * sign. "This only can be < 0.0 because of rounding errors. Take 0.0 in such cases."
	cxp := bigSqR * rx * y1p / ry.
	cyp := 0.0 - (bigSqR * ry * x1p / rx).

	"step 3"
	cx := cosPhi * cxp - (sinPhi * cyp) + (x1 + x2 * 0.5).
	cy := sinPhi * cxp + (cosPhi * cyp) + (y1 + y2 * 0.5).

	"
| u v a |
Transcript clear.
u := 1@4. v := 7@2.
a := ((u dotProduct: v) / (u r * v r) ) arcCos.
a := a * (((u x * v y) - (u y * v x)) sign).
a print.
(v theta - u theta) print.
Ojo al primitivizar. Para ellos, el theta va entre -pi y pi. Para Squeak va entre cero y 2pi...
"

	"step 4"
	"Ojo signo del angulo y del eje y!!!!!"
	theta1 := (x1p - cxp / rx @ (y1p - cyp / ry)) theta.
	theta2 := (0 - x1p - cxp / rx @ (0 - y1p - cyp / ry)) theta.
	deltaTheta := theta2 - theta1.
	useIncreasingAngles = (deltaTheta > 0) ifFalse: [ 
		deltaTheta > 0
			ifTrue: [ deltaTheta := deltaTheta - Float pi - Float pi ]
			ifFalse: [ deltaTheta := deltaTheta + Float pi + Float pi ] ].
	"Y aca calcular como dar vuelta deltaTheta, ver."


	"Finalmente, estudiar la correccion de valores fuera de rango"


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

	"
(VectorEngineSubPixel onForm: Display)
	strokeWidth: 1.0 color: Color black fillColor: Color red do: [ :engine |
		engine
			abs_MoveToX: 100 y: 100;
			abs_ArcToX: 200 y: 200 radiusX: 200 radiusY: 100 angleOfXAxis: 0 largeFlag: true sweepFlag: true;
			do_ClosePath ].
Display forceToScreen
"

	self basicLineToX: pathFirstX y: pathFirstY
]

{ #category : 'private - paths - pixel coordinates' }
VectorEngineAbstract >> basicCubicBezierToX: xTo y: yTo control1X: xC1 y: yC1 control2X: xC2 y: yC2 [

	"Cubic Bezier
	http://en.wikipedia.org/wiki/Bezier_curve"

	"
(VectorEngineSubPixel onForm: Display)
	strokeWidth: 1.0 color: Color black do: [ :engine |
		engine
			abs_MoveToX: 100 y: 100;
			abs_CubicBezierToX: 300 y: 200 control1X: 110 y: 110 control2X: 200 y: 200 ].
Display forceToScreen
	"

	"
(VectorEngineSubPixel onForm: Display)
	strokeWidth: 10 color: (Color black alpha: 0.7) fillColor: (Color orange alpha: 0.8) do: [ :engine |
		engine abs_MoveToX: 100 y: 50.
		engine
			abs_CubicBezierToX: 600 y: 100
			control1X: 150 y: 300
			control2X: 600 y: 400 ].
Display forceToScreen
	"

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

	"
(VectorEngineSubPixel onForm: Display)
	strokeWidth: 1.0 color: Color black do: [ :engine |
		engine
			abs_MoveToX: 100 y: 100;
			abs_LineToX: 300 y: 150 ].
Display forceToScreen
"

	"
(VectorEngineSubPixel onForm: Display)
	strokeWidth: 25.0 color: Color black do: [ :engine |
		engine
			abs_MoveToX: 100 y: 100;
			abs_LineToX: 500 y: 200 ].
Display forceToScreen
"

	"
(VectorEngineSubPixel onForm: Display)
	strokeWidth: 2 color: (Color black alpha: 0.7) fillColor: (Color orange alpha: 0.4) do: [ :engine |
		engine abs_MoveToX: 30 y: 15.
		engine abs_LineToX: 45 y: 90.
		engine abs_LineToX: 180 y: 30 ].
Display forceToScreen
"

	| dx dy hops incrementX incrementY |
	dy := yTo - pathCurrentY.
	dx := xTo - pathCurrentX.
	"Optimizar. En todas las lineas, bounds. En verticales, mucho mas. En horiz, no EdgeCounts! Ver 02"
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

	"
(VectorEngineSubPixel onForm: Display)
	strokeWidth: 1.0 color: Color black do: [ :engine |
		engine
			abs_MoveToX: 100 y: 100;
			abs_LineToX: 200 y: 150;
			abs_MoveToX: 210 y: 150;
			abs_LineToX: 300 y: 200 ].
Display forceToScreen
"

	"A discontinuity in the trajectory"

	"We are starting a new trajectory, or at a discontinuity in trajectory.
	Eventually #closeTrajectory should draw a line to here"

	"Next point will be first in a new trajectory fragment"

	self newTrajectoryFragment.
	pathFirstX := x.
	pathFirstY := y.
	pathCurrentX := x.
	pathCurrentY := y
]

{ #category : 'private - paths - pixel coordinates' }
VectorEngineAbstract >> basicQuadraticBezierToX: xTo y: yTo controlX: xC y: yC [

	"
(VectorEngineSubPixel onForm: Display)
	strokeWidth: 1.0 color: Color black do: [ :engine |
		engine
			abs_MoveToX: 100 y: 100;
			abs_QuadraticBezierToX: 300 y: 200 controlX: 100 y: 210 ].
Display forceToScreen
	"

	"
(VectorEngineSubPixel onForm: Display)
	strokeWidth: 2 color: (Color black alpha: 0.7) fillColor: (Color orange alpha: 0.4) do: [ :engine |
		engine abs_MoveToX: 10 y: 5.
		engine abs_QuadraticBezierToX: 60 y: 10 controlX: 15 y: 30 ].
Display forceToScreen
	"

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
						self abs_MoveToX: moveToX * sx + destX y: moveToY * sy + destY.
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
								rel_QuadraticBezierToX: epX * sx
								y: epY * sy
								controlX: cpX * sx
								y: cpY * sy ] ].
					destX := destX + (advanceWidth * sx).
					baseIndex := 0 ] ] ]
]

{ #category : 'paths - absolute coordinates' }
VectorEngineAbstract >> do_ClosePath [

	"abs/rel meaningless here"

	"
(VectorEngineSubPixel onForm: Display)
	strokeWidth: 2.0 color: Color black do: [ :engine |
		engine
			abs_MoveToX: 100 y: 100;
			abs_CubicBezierToX: 300 y: 200 control1X: 110 y: 110 control2X: 200 y: 200;
			abs_CubicBezierToX: 300 y: 120 control1X: 310 y: 110 control2X: 200 y: 200;
			do_ClosePath;
			abs_LineToX: 150 y: 300 ].
Display forceToScreen
"

	"geometryTransformation (AffineTransformation) removed — coordinates passed through as-is"
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

	"geometryTransformation := MorphicTranslation new." "Identity"
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
VectorEngineAbstract >> rel_ArcToX: cx y: cy radiusX: mrx radiusY: mry angleOfXAxis: theta largeFlag: doLargerArc sweepFlag: useIncreasingAngles [

	"
(VectorEngineSubPixel onForm: Display)
	strokeWidth: 1.0 color: Color black do: [ :engine |
		engine
			abs_MoveToX: 100 y: 100;
			abs_ArcToX: 200 y: 200 radiusX: 200 radiusY: 100 angleOfXAxis: 0 largeFlag: true sweepFlag: true;
			rel_ArcToX: 200 y: 200 radiusX: 200 radiusY: 100 angleOfXAxis: 0 largeFlag: true sweepFlag: false;
			do_ClosePath ].
Display forceToScreen
"

	self
		abs_ArcToX: previousCallX + cx
		y: previousCallY + cy
		radiusX: mrx
		radiusY: mry
		angleOfXAxis: theta
		largeFlag: doLargerArc
		sweepFlag: useIncreasingAngles
]

{ #category : 'paths - relative coordinates' }
VectorEngineAbstract >> rel_CubicBezierSmoothToX: xTo y: yTo control2X: xC y: yC [

	"Cubic Bezier
	http://en.wikipedia.org/wiki/Bezier_curve
	Smooth squence of curves: use as control1 point, last used control2 point."

	"Check that behavior is correct!"

	"
(VectorEngineSubPixel onForm: Display)
	geometryTransformation: (AffineTransformation withRadians: 1 scale: 0.2 position: 200@100);
	strokeWidth: 10 color: (Color black alpha: 0.7) fillColor: (Color orange alpha: 0.8) do: [ :engine |
		engine abs_MoveToX: 100 y: 50.
		engine
			abs_CubicBezierToX: 600 y: 100 control1X: 150 y: 300 control2X: 600 y: 400;
			rel_CubicBezierToX: 300 y: 300 control1X: 0 y: 0 control2X: 100 y: 100
			].
Display forceToScreen
	"

	"
(VectorEngineSubPixel onForm: Display)
	geometryTransformation: (AffineTransformation withRadians: 1 scale: 0.2 position: 200@100);
	strokeWidth: 10 color: (Color black alpha: 0.7) fillColor: (Color orange alpha: 0.8) do: [ :engine |
		engine abs_MoveToX: 100 y: 50.
		engine
			abs_CubicBezierToX: 600 y: 100 control1X: 150 y: 300 control2X: 600 y: 400;
			rel_CubicBezierSmoothToX: 300 y: 300 control2X: 100 y: 100
			].
Display forceToScreen
	"

	"
(VectorEngineSubPixel onForm: Display)
	geometryTransformation: (AffineTransformation withRadians: 1 scale: 0.2 position: 200@100);
	strokeWidth: 10 color: (Color black alpha: 0.7) fillColor: (Color orange alpha: 0.8) do: [ :engine |
		engine abs_MoveToX: 100 y: 50.
		engine
			abs_CubicBezierSmoothToX: 600 y: 100 control2X: 600 y: 400;
			abs_CubicBezierSmoothToX: 300 y: 300 control2X: 100 y: 100
			].
Display forceToScreen
	"

	self
		abs_CubicBezierSmoothToX: previousCallX + xTo
		y: previousCallY + yTo
		control2X: previousCallX + xC
		y: previousCallY + yC
]

{ #category : 'paths - relative coordinates' }
VectorEngineAbstract >> rel_CubicBezierToX: xTo y: yTo control1X: xC1 y: yC1 control2X: xC2 y: yC2 [

	"Cubic Bezier
	http://en.wikipedia.org/wiki/Bezier_curve"

	"
(VectorEngineSubPixel onForm: Display)
	strokeWidth: 1.0 color: Color black do: [ :engine |
		engine
			abs_MoveToX: 100 y: 100;
			abs_CubicBezierToX: 300 y: 200 control1X: 110 y: 110 control2X: 200 y: 200 ];
	strokeWidth: 1.0 color: Color red do: [ :engine |
		engine
			abs_MoveToX: 100 y: 100;
			rel_CubicBezierToX: 300 y: 200 control1X: 110 y: 110 control2X: 200 y: 200 ].
Display forceToScreen
	"

	"
(VectorEngineSubPixel onForm: Display)
	strokeWidth: 10 color: (Color black alpha: 0.7) fillColor: (Color orange alpha: 0.8) do: [ :engine |
		engine abs_MoveToX: 100 y: 50.
		engine
			abs_CubicBezierToX: 600 y: 100
			control1X: 150 y: 300
			control2X: 600 y: 400 ];
	strokeWidth: 10 color: (Color red alpha: 0.7) fillColor: (Color orange alpha: 0.8) do: [ :engine |
		engine abs_MoveToX: 100 y: 50.
		engine
			rel_CubicBezierToX: 600 y: 100
			control1X: 150 y: 300
			control2X: 600 y: 400 ].
Display forceToScreen
	"

	self
		abs_CubicBezierToX: previousCallX + xTo
		y: previousCallY + yTo
		control1X: previousCallX + xC1
		y: previousCallY + yC1
		control2X: previousCallX + xC2
		y: previousCallY + yC2
]

{ #category : 'paths - relative coordinates' }
VectorEngineAbstract >> rel_LineToX: xTo y: yTo [

	"
(VectorEngineSubPixel onForm: Display)
	strokeWidth: 2.0 color: Color black do: [ :engine |
		engine
			abs_MoveToX: 100 y: 100;
			abs_LineToX: 200 y: 150];
	strokeWidth: 2.0 color: Color red do: [ :engine |
		engine
			abs_MoveToX: 100 y: 100;
			rel_LineToX: 200 y: 150].
Display forceToScreen
"

	"
(VectorEngineSubPixel onForm: Display)
	geometryTransformation: (AffineTransformation withScale: 10);
	strokeWidth: 2 color: (Color black alpha: 0.7) fillColor: (Color orange alpha: 0.4) do: [ :engine |
		engine abs_MoveToX: 10 y: 5.
		engine abs_LineToX: 15 y: 30.
		engine abs_LineToX: 60 y: 10 ];
	geometryTransformation: (AffineTransformation withScale: 10);
	strokeWidth: 2 color: (Color red alpha: 0.7) fillColor: (Color orange alpha: 0.4) do: [ :engine |
		engine abs_MoveToX: 10 y: 5.
		engine rel_LineToX: 15 y: 30.
		engine rel_LineToX: 60 y: 10 ].
Display forceToScreen
"

	self abs_LineToX: previousCallX + xTo y: previousCallY + yTo
]

{ #category : 'paths - relative coordinates' }
VectorEngineAbstract >> rel_MoveToX: x y: y [

	"
(VectorEngineSubPixel onForm: Display)
	strokeWidth: 2.0 color: Color black do: [ :engine |
		engine
			abs_MoveToX: 100 y: 100;
			abs_LineToX: 200 y: 150];
	strokeWidth: 2.0 color: Color red do: [ :engine |
		engine
			abs_MoveToX: 100 y: 100;
			rel_LineToX: 200 y: 150].
Display forceToScreen
"

	"
(VectorEngineSubPixel onForm: Display)
	geometryTransformation: (AffineTransformation withScale: 10);
	strokeWidth: 2 color: (Color black alpha: 0.7) fillColor: (Color orange alpha: 0.4) do: [ :engine |
		engine abs_MoveToX: 10 y: 5.
		engine abs_LineToX: 15 y: 30.
		engine abs_LineToX: 60 y: 10 ];
	geometryTransformation: (AffineTransformation withScale: 10);
	strokeWidth: 2 color: (Color red alpha: 0.7) fillColor: (Color orange alpha: 0.4) do: [ :engine |
		engine abs_MoveToX: 10 y: 5.
		engine rel_LineToX: 15 y: 30.
		engine rel_LineToX: 60 y: 10 ].
Display forceToScreen
"

	self abs_MoveToX: previousCallX + x y: previousCallY + y
]

{ #category : 'paths - relative coordinates' }
VectorEngineAbstract >> rel_QuadraticBezierSmoothToX: xTo y: yTo [

	"
(VectorEngineSubPixel onForm: Display)
	geometryTransformation: (AffineTransformation withRadians: 0 scale: 1.0 position: 100@300);
	strokeWidth: 10 color: (Color green alpha: 0.7) do: [ :engine |
		engine abs_CircleCenterX: 550 y: 350 radius: 10.
		engine abs_MoveToX: 100 y: 50.
		engine
			rel_QuadraticBezierToX: 600 y: 100 controlX: 450 y: 300
			].
(VectorEngineSubPixel onForm: Display)
	geometryTransformation: (AffineTransformation withRadians: 0 scale: 1.0 position: 100@300);
	strokeWidth: 10 color: (Color red alpha: 0.7) do: [ :engine |
		engine abs_CircleCenterX: 850 y: -50 radius: 10.
		engine abs_MoveToX: 700 y: 150.
		engine
			rel_QuadraticBezierToX: -300 y: -50 controlX: 150 y: -200
			].
Display forceToScreen.
"

	"
(VectorEngineSubPixel onForm: Display)
	geometryTransformation: (AffineTransformation withRadians: 0 scale: 1.0 position: 100@300);
	strokeWidth: 10 color: (Color black alpha: 0.7) fillColor: (Color orange alpha: 0.8) do: [ :engine |
		engine abs_MoveToX: 100 y: 50.
		engine
			rel_QuadraticBezierToX: 600 y: 100 controlX: 450 y: 300;
			rel_QuadraticBezierSmoothToX: -300 y: -50
			].
Display forceToScreen
"

	self
		abs_QuadraticBezierSmoothToX: previousCallX + xTo
		y: previousCallY + yTo
]

{ #category : 'paths - relative coordinates' }
VectorEngineAbstract >> rel_QuadraticBezierToX: xTo y: yTo controlX: xC y: yC [

	"
(VectorEngineSubPixel onForm: Display)
	strokeWidth: 3.0 color: Color black do: [ :engine |
		engine
			abs_MoveToX: 100 y: 100;
			abs_QuadraticBezierToX: 300 y: 200 controlX: 100 y: 210 ];
	strokeWidth: 3.0 color: Color red do: [ :engine |
		engine
			abs_MoveToX: 100 y: 100;
			rel_QuadraticBezierToX: 300 y: 200 controlX: 100 y: 210 ].
Display forceToScreen
	"

	"
(VectorEngineSubPixel onForm: Display)
	geometryTransformation: (AffineTransformation withRadians: 1 scale: 3 position: 200@100);
	strokeWidth: 2 color: (Color black alpha: 0.7) fillColor: (Color orange alpha: 0.4) do: [ :engine |
		engine abs_MoveToX: 10 y: 5.
		engine abs_QuadraticBezierToX: 60 y: 10 controlX: 15 y: 30 ];
	strokeWidth: 2 color: (Color red alpha: 0.7) fillColor: (Color green alpha: 0.4) do: [ :engine |
		engine abs_MoveToX: 10 y: 5.
		engine rel_QuadraticBezierToX: 60 y: 10 controlX: 15 y: 30 ].
Display forceToScreen
	"

	self
		abs_QuadraticBezierToX: previousCallX + xTo
		y: previousCallY + yTo
		controlX: previousCallX + xC
		y: previousCallY + yC
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

	"geometryTransformation (AffineTransformation) removed — stroke width used as-is"
	| aStrokeWidth |
	(aStrokeColor isNil or: [ aStrokeColor alpha = 0.0 ]) ifTrue: [
		^ self ].
	clientStrokeWidth = 0.0 ifTrue: [ ^ self ].
	aStrokeWidth := clientStrokeWidth.
	aStrokeWidth < antiAliasingWidth
		ifTrue: [ "If the requested stroke width is too thin, make them wide enough to be properly sampled."
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

	"If stroke is thinner than antiAliasingWidth, we need to make it wider and less opaque.
	But this requires doing fill first and the blending stroke over it, or else fill gets eroded by widened stroke.
	(this is only relevant if fill ~= stroke~)"
	"geometryTransformation (AffineTransformation) removed — stroke width used as-is"
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
