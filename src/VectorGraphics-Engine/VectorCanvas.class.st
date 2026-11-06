"
A drawing surface over a 32-bit `Form` that renders vector graphics through the VectorEngine
pipeline. It is independent of Morphic: in Cuis it stood in for `Canvas` and was handed to the
morph tree, and the inheritance was dropped here because Morphic is not a target of this project.
Coordinates are pixel-direct — there is no transformation state.

It owns a VectorEngineWholePixel by default; calling `doSubPixelAntiAliasing` replaces it with
VectorEngineSubPixel for higher-quality text rendering (TTFontDescription does this automatically
when rendering glyphs).

## Relationships

- Wraps a VectorEngineWholePixel or VectorEngineSubPixel, plus a VectorEngineBoundsFinder that
  measures without painting.
- PathCommand >> runOn: sends canvas messages (multiLineTo:, closePath, etc.) to VectorCanvas,
  which delegates them to the engine's basic walks.
- TTFontDescription uses VectorCanvas to rasterize glyph outlines into FormGlyph instances.

## Entry point

`VectorCanvas class >> onForm:` — creates a canvas backed by the given Form, which it answers back
through `form`.

## Key methods

- `doSubPixelAntiAliasing`            — switch to sub-pixel engine (called before text rendering)
- `strokeWidth:color:do:`             — stroke a path at the given width and colour
- `fillColor:do:`                     — fill a closed path
- `strokeWidth:color:fillColor:do:`   — combined stroke and fill
- `multiLineTo:points:`, `multiMoveTo:points:`, `multiCurveTo:...`, `closePath`, etc.
                                      — path construction messages received from
                                        PathCommand >> runOn:
- `updatingMorphBoundsDo:`            — run a block through the measuring engine instead of the
                                        painting one, then read `measuredMorphBounds`

Example:

```smalltalk
| target canvas |
target := Form extent: 64 @ 64 depth: 32.
canvas := VectorCanvas onForm: target.
canvas fillColor: Color red do: [
	canvas moveToX: 8 y: 8; lineToX: 56 y: 8; lineToX: 32 y: 56; closePath ].
canvas form
```
"
Class {
	#name : 'VectorCanvas',
	#superclass : 'Object',
	#instVars : [
		'boundsFinderEngine',
		'form',
		'engine',
		'currentMorph',
		'clippingMorphDisplayBounds'
	],
	#category : 'VectorGraphics-Engine-Kernel',
	#package : 'VectorGraphics-Engine',
	#tag : 'Kernel'
}

{ #category : 'instance creation' }
VectorCanvas class >> onForm: aForm [
	"Create a VectorCanvas rendering directly to aForm.
	In Cuis this was inherited from Canvas; Pharo's Canvas does not provide it.
	AffineTransformation (Cuis-specific) removed — coordinates are pixel-direct."

	| canvas |
	canvas := self new.
	canvas setForm: aForm.
	^ canvas
]

{ #category : 'accessing' }
VectorCanvas >> boundsFinderEngine [

	^ boundsFinderEngine
]

{ #category : 'paths' }
VectorCanvas >> closePath [

	engine do_ClosePath
]

{ #category : 'paths' }
VectorCanvas >> cubicBezier: points [
	"points must be of size 4
	http://en.wikipedia.org/wiki/Bezier_curve"

	| start control1 control2 end |
	start := points first.
	control1 := points second.
	control2 := points third.
	end := points fourth.
	engine abs_MoveTo: start.
	engine abs_CubicBezierTo: end control1: control1 control2: control2
]

{ #category : 'paths' }
VectorCanvas >> curveToX: xTo y: yTo control1X: xC1 y: yC1 control2X: xC2 y: yC2 [

	engine abs_CubicBezierTo: xTo @ yTo control1: xC1 @ yC1 control2: xC2 @ yC2
]

{ #category : 'private' }
VectorCanvas >> doSubPixelAntiAliasing [

	"
	Instead of just whole pixel anti-aliasing.
	"

	engine := VectorEngineSubPixel onForm: form.
	boundsFinderEngine mirror: engine
]

{ #category : 'paths' }
VectorCanvas >> ellipseCenterX: mcx y: mcy rx: mrx ry: mry [

	engine abs_EllipseCenter: mcx @ mcy radiusX: mrx radiusY: mry
]

{ #category : 'drawing - shapes' }
VectorCanvas >> ellipseCenterX: mcx y: mcy rx: mrx ry: mry borderWidth: morphStrokeWidth borderColor: strokeColorOrGradient fillColor: fillColorOrGradient [

	self
		strokeWidth: morphStrokeWidth
		color: strokeColorOrGradient
		fillColor: fillColorOrGradient
		do: [ 
			self
				ellipseCenterX: mcx
				y: mcy
				rx: mrx
				ry: mry ]
]

{ #category : 'accessing' }
VectorCanvas >> engine [

	^ engine
]

{ #category : 'context and parameters for path' }
VectorCanvas >> fillColor: aFillColor do: pathCommandsBlock [

	"Prepare parameters for drawing stroke, fill, or both."

	engine fillColor: aFillColor do: pathCommandsBlock
]

{ #category : 'drawing - shapes' }
VectorCanvas >> fillRectangle: aRectangle color: aColor [

	"For BitBltCanvas protocol, aRectangle:
	- uses Squeak / Smalltalk-80 convention: do include topLeft, but don't include bottomRight. (too pixel oriented for M3 taste)"

	self fillColor: aColor do: [ 
		self
			rectangleMinX: aRectangle left - 0.5
			maxX: aRectangle right - 0.5
			minY: aRectangle top - 0.5
			maxY: aRectangle bottom - 0.5 ]
]

{ #category : 'accessing' }
VectorCanvas >> form [
	"The form the two engines paint on. Reading the pixels back is how a drawing ends."

	^ form
]

{ #category : 'drawing - shapes' }
VectorCanvas >> frameAndFillRectangle: aRectangle fillColor: aColor borderWidth: borderWidth borderColor: borderColor [

	"For BitBltCanvas protocol, aRectangle:
	- uses Squeak / Smalltalk-80 convention: do include topLeft, but don't include bottomRight. (too pixel oriented for M3 taste)"

	self
		strokeWidth: borderWidth
		color: borderColor
		fillColor: aColor
		do: [ 
			self
				rectangleMinX: aRectangle left - 0.5
				maxX: aRectangle right - 0.5
				minY: aRectangle top - 0.5
				maxY: aRectangle bottom - 0.5 ]
]

{ #category : 'drawing - shapes' }
VectorCanvas >> frameRectangle: aRectangle borderWidth: borderWidth color: borderColor [

	"For BitBltCanvas protocol, aRectangle:
	- means the bounding rectangle of the affected pixels, not the rectangle followed by the tip
	- uses Squeak / Smalltalk-80 convention: do include topLeft, but don't include bottomRight. (too pixel oriented for M3 taste)"

	| d1 d2 |
	d1 := borderWidth * 0.5 - 0.5.
	d2 := borderWidth * 0.5 + 0.5.

	self strokeWidth: borderWidth color: borderColor do: [ 
		self
			rectangleMinX: aRectangle left + d1
			maxX: aRectangle right - d2
			minY: aRectangle top + d1
			maxY: aRectangle bottom - d2 ]
]

{ #category : 'inspector' }
VectorCanvas >> inspectorEngineEntries [
	"The two engines and the morph the pixels are filed under. The morph row asks the real
	question rather than restating it: currentMorph: needs a morph that answers morphId."

	^ {
		  ('engine that draws' -> [ engine class name ]) .
		  ('engine that measures' -> [ boundsFinderEngine class name ]) .
		  ('engine in use now' -> [ self inspectorEngineInUse ]) .
		  ('bounds the last drawing covered' -> [ engine morphBoundsAfterDraw ]) .
		  ('morph the pixels are filed under' -> [ currentMorph ]) .
		  ('that morph answers morphId' -> [ currentMorph notNil and: [ currentMorph respondsTo: #morphId ] ]) .
		  ('display bounds of the clipping morph' -> [ clippingMorphDisplayBounds ]) }
]

{ #category : 'inspector' }
VectorCanvas >> inspectorEngineInUse [
	"Which of the two engines a drawing would go to now. Inside updatingMorphBoundsDo: it is the
	one that measures, which in this port is nil, since nothing ever builds one."

	engine == boundsFinderEngine ifTrue: [ ^ 'the one that measures' ].
	^ 'the one that draws'
]

{ #category : 'inspector' }
VectorCanvas >> inspectorFormEntries [
	"The form this canvas draws on. A canvas refuses any depth but 32, so the row is there to
	show which form it got rather than to warn of another depth."

	^ {
		  ('form drawn on' -> [ form ]) .
		  ('extent' -> [ form extent ]) .
		  ('depth' -> [ form depth ]) }
]

{ #category : 'inspector' }
VectorCanvas >> inspectorTarget: aBuilder [
	<inspectorPresentationOrder: 20 title: 'Target'>
	"What this canvas draws on and with. Two engines are held: engine draws, boundsFinderEngine
	measures, and updatingMorphBoundsDo: swaps the second in for the duration of a block. The
	morph row asks the real question rather than restating it: currentMorph: needs a morph that
	answers morphId, and nothing in this image does, so a hit test over morphIds finds nothing
	until a morph class answers it."

	^ aBuilder newTable
		  addColumn: ((SpStringTableColumn title: 'What' evaluated: [ :each | each key ]) width: 240);
		  addColumn: (SpStringTableColumn title: 'Now' evaluated: [ :each | each value value printString ]);
		  items: self inspectorTargetEntries;
		  yourself
]

{ #category : 'inspector' }
VectorCanvas >> inspectorTargetEntries [
	"What the Target view shows, in two halves: the form drawn on, then the two engines."

	^ self inspectorFormEntries , self inspectorEngineEntries
]

{ #category : 'drawing - shapes' }
VectorCanvas >> line: pt1 to: pt2 width: morphStrokeWidth color: aStrokeColor [

	self strokeWidth: morphStrokeWidth color: aStrokeColor do: [ 
		self moveToX: pt1 x y: pt1 y.
		self lineToX: pt2 x y: pt2 y ]
]

{ #category : 'paths' }
VectorCanvas >> lineToX: xTo y: yTo [

	engine abs_LineTo: xTo @ yTo
]

{ #category : 'accessing' }
VectorCanvas >> measuredMorphBounds [

	"The area the drawing inside the last #updatingMorphBoundsDo: would have covered,
	in form coordinates, with no clipping applied."

	^ boundsFinderEngine morphBoundsAfterDraw
]

{ #category : 'paths' }
VectorCanvas >> moveToX: x y: y [

	engine abs_MoveTo: x @ y
]

{ #category : 'paths - sequences' }
VectorCanvas >> multiArc: coordinatesAreRelative rs: rs xAxisRotations: xAxisRotations toPoints: toPoints doLargerArcs: doLargerArcs useIncreasingAngless: useIncreasingAngless [

	| to r |
	coordinatesAreRelative
		ifFalse: [
			1 to: toPoints size do: [ :i |
				to := toPoints at: i.
				r := rs at: i.
				engine
					abs_ArcTo: to
					radiusX: r x
					radiusY: r y
					angleOfXAxis: (xAxisRotations at: i)
					largeFlag: (doLargerArcs at: i)
					sweepFlag: (useIncreasingAngless at: i) ] ]
		ifTrue: [
			1 to: toPoints size do: [ :i |
				to := toPoints at: i.
				r := rs at: i.
				engine
					rel_ArcTo: to
					radiusX: r x
					radiusY: r y
					angleOfXAxis: (xAxisRotations at: i)
					largeFlag: (doLargerArcs at: i)
					sweepFlag: (useIncreasingAngless at: i) ] ]
]

{ #category : 'paths - sequences' }
VectorCanvas >> multiCurveTo: coordinatesAreRelative toPoints: toPoints control1Points: control1Points control2Points: control2Points [

	| c1 c2 to |
	coordinatesAreRelative
		ifFalse: [
			1 to: toPoints size do: [ :i |
				to := toPoints at: i.
				c1 := control1Points at: i.
				c2 := control2Points at: i.
				engine abs_CubicBezierTo: to control1: c1 control2: c2 ] ]
		ifTrue: [
			1 to: toPoints size do: [ :i |
				to := toPoints at: i.
				c1 := control1Points at: i.
				c2 := control2Points at: i.
				engine rel_CubicBezierTo: to control1: c1 control2: c2 ] ]
]

{ #category : 'paths - sequences' }
VectorCanvas >> multiCurveToSmooth: coordinatesAreRelative toPoints: toPoints control2Points: control2Points [

	| c2 to |
	coordinatesAreRelative
		ifFalse: [
			1 to: toPoints size do: [ :i |
				to := toPoints at: i.
				c2 := control2Points at: i.
				engine abs_CubicBezierSmoothTo: to control2: c2 ] ]
		ifTrue: [
			1 to: toPoints size do: [ :i |
				to := toPoints at: i.
				c2 := control2Points at: i.
				engine rel_CubicBezierSmoothTo: to control2: c2 ] ]
]

{ #category : 'paths - sequences' }
VectorCanvas >> multiLineTo: coordinatesAreRelative points: toPoints [

	| to |
	coordinatesAreRelative
		ifFalse: [
			1 to: toPoints size do: [ :i |
				to := toPoints at: i.
				engine abs_LineTo: to ] ]
		ifTrue: [
			1 to: toPoints size do: [ :i |
				to := toPoints at: i.
				engine rel_LineTo: to ] ]
]

{ #category : 'paths - sequences' }
VectorCanvas >> multiLineTo: coordinatesAreRelative xs: xs [

	coordinatesAreRelative
		ifFalse: [ xs do: [ :x | engine abs_LineToX: x ] ]
		ifTrue: [ xs do: [ :x | engine rel_LineTo: x @ 0 ] ]
]

{ #category : 'paths - sequences' }
VectorCanvas >> multiLineTo: coordinatesAreRelative ys: ys [

	coordinatesAreRelative
		ifFalse: [ ys do: [ :y | engine abs_LineToY: y ] ]
		ifTrue: [ ys do: [ :y | engine rel_LineTo: 0 @ y ] ]
]

{ #category : 'paths - sequences' }
VectorCanvas >> multiMoveTo: coordinatesAreRelative points: points [

	| isFirst |
	isFirst := true.
	coordinatesAreRelative
		ifFalse: [
			points do: [ :p |
				isFirst
					ifTrue: [ engine abs_MoveTo: p ]
					ifFalse: [ engine abs_LineTo: p ].
				isFirst := false ] ]
		ifTrue: [
			points do: [ :p |
				isFirst
					ifTrue: [ engine rel_MoveTo: p ]
					ifFalse: [ engine rel_LineTo: p ].
				isFirst := false ] ]
]

{ #category : 'paths - sequences' }
VectorCanvas >> multiQuadraticCurveTo: coordinatesAreRelative toPoints: toPoints controlPoints: controlPoints [

	| c to |
	coordinatesAreRelative
		ifFalse: [
			1 to: toPoints size do: [ :i |
				to := toPoints at: i.
				c := controlPoints at: i.
				engine abs_QuadraticBezierTo: to control: c ] ]
		ifTrue: [
			1 to: toPoints size do: [ :i |
				to := toPoints at: i.
				c := controlPoints at: i.
				engine rel_QuadraticBezierTo: to control: c ] ]
]

{ #category : 'paths - sequences' }
VectorCanvas >> multiQuadraticCurveToSmooth: coordinatesAreRelative toPoints: toPoints [

	| to |
	coordinatesAreRelative
		ifFalse: [
			1 to: toPoints size do: [ :i |
				to := toPoints at: i.
				engine abs_QuadraticBezierSmoothTo: to ] ]
		ifTrue: [
			1 to: toPoints size do: [ :i |
				to := toPoints at: i.
				engine rel_QuadraticBezierSmoothTo: to ] ]
]

{ #category : 'paths' }
VectorCanvas >> polyLine: points [

	engine abs_MoveTo: points first.
	2 to: points size do: [ :i | engine abs_LineTo: (points at: i) ]
]

{ #category : 'paths' }
VectorCanvas >> quadraticBezier: points [

	"points must be of size 3
	http://en.wikipedia.org/wiki/Bezier_curve"

	engine abs_MoveTo: points first.
	engine abs_QuadraticBezierTo: points third control: points second
]

{ #category : 'paths' }
VectorCanvas >> rectangleMinX: xMin maxX: xMax minY: yMin maxY: yMax [

	engine
		abs_MoveTo: xMin @ yMin;
		abs_LineTo: xMax @ yMin;
		abs_LineTo: xMax @ yMax;
		abs_LineTo: xMin @ yMax;
		do_ClosePath
]

{ #category : 'paths' }
VectorCanvas >> roundBottomRectangleMinX: xMin maxX: xMax minY: yMin maxY: yMax rx: mrx ry: mry [

	| corner1 corner2 corner3 corner4 dx dy p5 p6 p7 p8 |
	(mrx = 0.0 or: [ mry = 0.0 ]) ifTrue: [ 
		^ self
			  rectangleMinX: xMin
			  maxX: xMax
			  minY: yMin
			  maxY: yMax ].

	corner1 := xMin @ yMin.
	corner2 := xMax @ yMin.
	corner3 := xMax @ yMax.
	corner4 := xMin @ yMax.
	dx := mrx @ 0.
	dy := 0 @ mry.
	p5 := corner3 - dy.
	p6 := corner3 - dx.
	p7 := corner4 + dx.
	p8 := corner4 - dy.
	"
	rx := dx r.
	ry := dy r.
	phi := dx theta.
	doLargerArc := false.
	useIncreasingAngles := true.
	"
	engine
		abs_MoveTo: corner1;
		abs_LineTo: corner2;
		abs_LineTo: p5;
		abs_QuadraticBezierTo: p6 control: corner3;
		abs_LineTo: p7;
		abs_QuadraticBezierTo: p8 control: corner4;
		do_ClosePath
]

{ #category : 'drawing - shapes' }
VectorCanvas >> roundRect: aRectangle color: aColor radius: r [

	"For BitBltCanvas protocol, aRectangle:
		- uses Squeak / Smalltalk-80 convention: do include topLeft, but don't include bottomRight. (too pixel oriented for M3 taste)"

	self fillColor: aColor do: [ 
		self
			roundRectangleMinX: aRectangle left - 0.5
			maxX: aRectangle right - 0.5
			minY: aRectangle top - 0.5
			maxY: aRectangle bottom - 0.5
			rx: r
			ry: r ]
]

{ #category : 'paths' }
VectorCanvas >> roundRectangleMinX: xMin maxX: xMax minY: yMin maxY: yMax rx: mrx ry: mry [

	| corner1 corner2 corner3 corner4 dx dy p1 p2 p3 p4 p5 p6 p7 p8 |
	(mrx = 0.0 or: [ mry = 0.0 ]) ifTrue: [ 
		^ self
			  rectangleMinX: xMin
			  maxX: xMax
			  minY: yMin
			  maxY: yMax ].

	corner1 := xMin @ yMin.
	corner2 := xMax @ yMin.
	corner3 := xMax @ yMax.
	corner4 := xMin @ yMax.
	dx := mrx @ 0.
	dy := 0 @ mry.
	p1 := corner1 + dy.
	p2 := corner1 + dx.
	p3 := corner2 - dx.
	p4 := corner2 + dy.
	p5 := corner3 - dy.
	p6 := corner3 - dx.
	p7 := corner4 + dx.
	p8 := corner4 - dy.
	"
	rx := dx r.
	ry := dy r.
	phi := dx theta.
	doLargerArc := false.
	useIncreasingAngles := true.
	"
	engine
		abs_MoveTo: p1;
		abs_QuadraticBezierTo: p2 control: corner1;
		abs_LineTo: p3;
		abs_QuadraticBezierTo: p4 control: corner2;
		abs_LineTo: p5;
		abs_QuadraticBezierTo: p6 control: corner3;
		abs_LineTo: p7;
		abs_QuadraticBezierTo: p8 control: corner4;
		do_ClosePath
]

{ #category : 'paths' }
VectorCanvas >> roundTopRectangleMinX: xMin maxX: xMax minY: yMin maxY: yMax rx: mrx ry: mry [

	| corner1 corner2 corner3 corner4 dx dy p1 p2 p3 p4 |
	(mrx = 0.0 or: [ mry = 0.0 ]) ifTrue: [ 
		^ self
			  rectangleMinX: xMin
			  maxX: xMax
			  minY: yMin
			  maxY: yMax ].

	corner1 := xMin @ yMin.
	corner2 := xMax @ yMin.
	corner3 := xMax @ yMax.
	corner4 := xMin @ yMax.
	dx := mrx @ 0.
	dy := 0 @ mry.
	p1 := corner1 + dy.
	p2 := corner1 + dx.
	p3 := corner2 - dx.
	p4 := corner2 + dy.
	"
	rx := dx r.
	ry := dy r.
	phi := dx theta.
	doLargerArc := false.
	useIncreasingAngles := true.
	"
	engine
		abs_MoveTo: p1;
		abs_QuadraticBezierTo: p2 control: corner1;
		abs_LineTo: p3;
		abs_QuadraticBezierTo: p4 control: corner2;
		abs_LineTo: corner3;
		abs_LineTo: corner4;
		do_ClosePath
]

{ #category : 'paths' }
VectorCanvas >> runPathCommands: aCollection [

	aCollection do: [ :cmd | cmd runOn: self ]
]

{ #category : 'private' }
VectorCanvas >> setClipRect: aRectangle [

	"In targetForm coordinates"
	engine clipRect: aRectangle
]

{ #category : 'private' }
VectorCanvas >> setForm: aForm [

	aForm depth = 32 ifFalse: [ 
		self error: 'VectorCanvas can only work on 32 bit destination' ].
	form := aForm.
	engine := VectorEngineWholePixel onForm: form.
	boundsFinderEngine := VectorEngineBoundsFinder onForm: form mirroring: engine
]

{ #category : 'context and parameters for path' }
VectorCanvas >> strokeWidth: morphStrokeWidth color: aStrokeColor do: pathCommandsBlock [

	"Prepare parameters for drawing stroke, fill, or both."

	"Gradients should be transformed with currentTransformation!"

	engine
		strokeWidth: morphStrokeWidth
		color: aStrokeColor
		do: pathCommandsBlock
]

{ #category : 'context and parameters for path' }
VectorCanvas >> strokeWidth: morphStrokeWidth color: aStrokeColor fillColor: aFillColor do: pathCommandsBlock [

	"Prepare parameters for drawing stroke, fill, or both."

	"Gradients should be transformed with currentTransformation!"

	engine
		strokeWidth: morphStrokeWidth
		color: aStrokeColor
		fillColor: aFillColor
		do: pathCommandsBlock
]

{ #category : 'private' }
VectorCanvas >> updatingMorphBoundsDo: aBlock [

	| prevEngine |
	prevEngine := engine.
	[
	engine := boundsFinderEngine.
	boundsFinderEngine resetMorphBounds.
	aBlock value ] ensure: [ engine := prevEngine ]
]
