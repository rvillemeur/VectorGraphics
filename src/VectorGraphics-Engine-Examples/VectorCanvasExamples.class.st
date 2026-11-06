"
The examples of the drawing engine: every one builds an off-screen Form, draws on it through a VectorCanvas and answers the Form, so one click in the browser shows the picture.

These are the examples that need nothing but VectorGraphics-Engine. The path command and SVG examples live in PathCommandExamples and SVGPathExamples, and the text ones in TextDrawingExamples, because each of those needs a package this one does not.

`newForm` and `newCanvasOn:` are the private helpers every example here uses.

## The examples

- `line`, `lineConvenience`, `polyLine` — strokes, the second through the `line:to:width:color:` convenience
- `cubicBezier`, `quadraticBezier` — curves through their control points
- `circleStroke`, `circleFill`, `ellipse` — ellipses, stroked, filled, and both at once
- `filledRectangle`, `strokedRectangle`, `strokedAndFilledRectangle`, `roundedRectangle`
- `triangle`, `compositeDrawing` — a closed path with a translucent fill, and several shapes layered
- `canvasAfterADrawing`, `engineDuringAFillPath`, `boundsFinderAfterMeasuringATriangle` — the canvas, the engine and the bounds finder themselves, for the inspector views of those classes
"
Class {
	#name : 'VectorCanvasExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Engine-Examples-Examples',
	#package : 'VectorGraphics-Engine-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VectorCanvasExamples class >> boundsFinderAfterMeasuringATriangle [

	"The engine a canvas measures with, after a drawing has been measured and not painted.
	The form it was given stays white: only the morph bounds change.
	The Measurement view then shows the box it measured, the margins it took from the engine
	it mirrors, and that it owns no buffer at all.
	VectorCanvasExamples boundsFinderAfterMeasuringATriangle inspect"

	<sampleInstance>
	| canvas |
	canvas := self newCanvasOn: self newForm.
	canvas updatingMorphBoundsDo: [
		canvas strokeWidth: 2.0 color: Color black fillColor: Color yellow do: [
			canvas moveToX: 60 y: 40.
			canvas lineToX: 240 y: 60.
			canvas lineToX: 150 y: 170.
			canvas closePath ] ].
	^ canvas boundsFinderEngine
]

{ #category : 'examples' }
VectorCanvasExamples class >> canvasAfterADrawing [
	"The canvas itself after something has painted through it, rather than the form it painted.
	The Target view then shows what the canvas draws on, which engine draws and which measures,
	the clip rectangle and the bounds the drawing covered.
	VectorCanvasExamples canvasAfterADrawing inspect"

	<sampleInstance>
	| canvas |
	canvas := self newCanvasOn: self newForm.
	canvas strokeWidth: 2.0 color: Color black fillColor: Color yellow do: [
		canvas moveToX: 60 y: 40.
		canvas lineToX: 240 y: 60.
		canvas lineToX: 150 y: 170.
		canvas closePath ].
	^ canvas
]

{ #category : 'examples' }
VectorCanvasExamples class >> circleFill [
	"Filled circle using fillColor:do: with an ellipse of equal radii.
	VectorCanvasExamples circleFill inspect"
<sampleInstance>
	| form canvas |
	form := self newForm.
	canvas := self newCanvasOn: form.
	canvas fillColor: Color orange do: [
		canvas ellipseCenterX: 150 y: 100 rx: 70 ry: 70 ].
	^ form
]

{ #category : 'examples' }
VectorCanvasExamples class >> circleStroke [
	"Stroked circle outline using strokeWidth:color:do:.
	VectorCanvasExamples circleStroke inspect"
<sampleInstance>
	| form canvas |
	form := self newForm.
	canvas := self newCanvasOn: form.
	canvas strokeWidth: 3.0 color: Color black do: [
		canvas ellipseCenterX: 150 y: 100 rx: 70 ry: 70 ].
	^ form
]

{ #category : 'examples' }
VectorCanvasExamples class >> compositeDrawing [
	"Multiple shapes on one canvas demonstrating layering.
	VectorCanvasExamples compositeDrawing inspect"
<sampleInstance>
	| form canvas |
	form := self newForm.
	canvas := self newCanvasOn: form.
	canvas roundRect: (10 @ 10 extent: 280 @ 180) color: (Color gray: 0.9) radius: 15.
	canvas fillColor: (Color blue alpha: 0.7) do: [
		canvas ellipseCenterX: 80 y: 100 rx: 50 ry: 50 ].
	canvas
		strokeWidth: 1.5
		color: Color darkGray
		fillColor: (Color red alpha: 0.6)
		do: [
			canvas moveToX: 180 y: 35.
			canvas lineToX: 265 y: 165.
			canvas lineToX: 95 y: 165.
			canvas closePath ].
	canvas strokeWidth: 1.5 color: Color black do: [
		canvas ellipseCenterX: 220 y: 80 rx: 50 ry: 25 ].
	^ form
]

{ #category : 'examples' }
VectorCanvasExamples class >> cubicBezier [
	"Cubic Bezier curve through 4 control points.
	VectorCanvasExamples cubicBezier inspect"
<sampleInstance>
	| form canvas |
	form := self newForm.
	canvas := self newCanvasOn: form.
	canvas strokeWidth: 2.0 color: Color blue do: [
		canvas cubicBezier: {
				30 @ 100.
				100 @ 20.
				200 @ 180.
				270 @ 100 } ].
	^ form
]

{ #category : 'examples' }
VectorCanvasExamples class >> ellipse [
	"Ellipse with both stroke and fill using the FormCanvas-protocol method.
	VectorCanvasExamples ellipse inspect"
<sampleInstance>
	| form canvas |
	form := self newForm.
	canvas := self newCanvasOn: form.
	canvas
		ellipseCenterX: 150
		y: 100
		rx: 120
		ry: 60
		borderWidth: 3.0
		borderColor: Color black
		fillColor: (Color cyan alpha: 0.8).
	^ form
]

{ #category : 'examples' }
VectorCanvasExamples class >> engineDuringAFillPath [
	"An engine holding a path it has walked and not yet blended, which is the only state in which
	its buffers hold anything: the blend pass zeroes both of them as it goes.
	The empty fill call first is how the engine is given its stroke radii and its hops per pixel
	through the public entry; the second path is then walked and left unblended.
	VectorCanvasExamples engineDuringAFillPath inspect"

	<sampleInstance>
	| engine |
	engine := VectorEngineSubPixel onForm: self newForm.
	engine fillColor: Color red do: [ :each | ].
	engine initializePath.
	engine abs_MoveTo: 60 @ 40.
	engine abs_LineTo: 240 @ 60.
	engine abs_LineTo: 150 @ 170.
	engine do_ClosePath.
	^ engine
]

{ #category : 'examples' }
VectorCanvasExamples class >> filledRectangle [
	"Solid filled rectangle using fillRectangle:color:.
	VectorCanvasExamples filledRectangle inspect"
<sampleInstance>
	| form canvas |
	form := self newForm.
	canvas := self newCanvasOn: form.
	canvas fillRectangle: (50 @ 40 extent: 200 @ 120) color: (Color blue alpha: 0.7).
	^ form
]

{ #category : 'examples' }
VectorCanvasExamples class >> line [
	"Simple stroked line from one point to another using strokeWidth:color:do:.
	VectorCanvasExamples line inspect"
<sampleInstance>
	| form canvas |
	form := self newForm.
	canvas := self newCanvasOn: form.
	canvas strokeWidth: 2.0 color: Color black do: [
		canvas moveToX: 30 y: 50.
		canvas lineToX: 270 y: 150 ].
	^ form
]

{ #category : 'examples' }
VectorCanvasExamples class >> lineConvenience [
	"Line using the FormCanvas-protocol convenience method line:to:width:color:.
	VectorCanvasExamples lineConvenience inspect"
<sampleInstance>
	| form canvas |
	form := self newForm.
	canvas := self newCanvasOn: form.
	canvas line: 30 @ 50 to: 270 @ 150 width: 3.0 color: Color purple.
	^ form
]

{ #category : 'private' }
VectorCanvasExamples class >> newCanvasOn: aForm [
	"Identity transform set by VectorCanvas class >> onForm: — direct pixel coordinates."

	^ VectorCanvas onForm: aForm
]

{ #category : 'private' }
VectorCanvasExamples class >> newForm [
	"White 300x200 32-bit form ready for vector rendering."

	| form |
	form := Form extent: 300 @ 200 depth: 32.
	form fillColor: Color white.
	^ form
]

{ #category : 'examples' }
VectorCanvasExamples class >> polyLine [
	"Polyline through multiple points using polyLine:.
	VectorCanvasExamples polyLine inspect"
<sampleInstance>
	| form canvas points |
	form := self newForm.
	canvas := self newCanvasOn: form.
	points := {
		30 @ 100.
		80 @ 40.
		130 @ 130.
		180 @ 50.
		230 @ 110.
		270 @ 60 }.
	canvas strokeWidth: 2.0 color: Color magenta do: [ canvas polyLine: points ].
	^ form
]

{ #category : 'examples' }
VectorCanvasExamples class >> quadraticBezier [
	"Quadratic Bezier curve through 3 control points.
	VectorCanvasExamples quadraticBezier inspect"
<sampleInstance>
	| form canvas |
	form := self newForm.
	canvas := self newCanvasOn: form.
	canvas strokeWidth: 2.0 color: (Color green darker) do: [
		canvas quadraticBezier: {
				30 @ 150.
				150 @ 20.
				270 @ 150 } ].
	^ form
]

{ #category : 'examples' }
VectorCanvasExamples class >> roundedRectangle [
	"Filled rounded-corner rectangle using roundRect:color:radius:.
	VectorCanvasExamples roundedRectangle inspect"
<sampleInstance>
	| form canvas |
	form := self newForm.
	canvas := self newCanvasOn: form.
	canvas roundRect: (50 @ 40 extent: 200 @ 120) color: (Color green alpha: 0.8) radius: 25.
	^ form
]

{ #category : 'examples' }
VectorCanvasExamples class >> strokedAndFilledRectangle [
	"Rectangle with both stroke and fill using frameAndFillRectangle:fillColor:borderWidth:borderColor:.
	VectorCanvasExamples strokedAndFilledRectangle inspect"
<sampleInstance>
	| form canvas |
	form := self newForm.
	canvas := self newCanvasOn: form.
	canvas
		frameAndFillRectangle: (50 @ 40 extent: 200 @ 120)
		fillColor: Color yellow
		borderWidth: 4.0
		borderColor: Color darkGray.
	^ form
]

{ #category : 'examples' }
VectorCanvasExamples class >> strokedRectangle [
	"Rectangle outline only using frameRectangle:borderWidth:color:.
	VectorCanvasExamples strokedRectangle inspect"
<sampleInstance>
	| form canvas |
	form := self newForm.
	canvas := self newCanvasOn: form.
	canvas frameRectangle: (50 @ 40 extent: 200 @ 120) borderWidth: 3.0 color: Color red.
	^ form
]

{ #category : 'examples' }
VectorCanvasExamples class >> triangle [
	"Triangle with stroke and fill using moveToX:y:, lineToX:y:, closePath.
	VectorCanvasExamples triangle inspect"
<sampleInstance>
	| form canvas |
	form := self newForm.
	canvas := self newCanvasOn: form.
	canvas
		strokeWidth: 2.0
		color: Color black
		fillColor: (Color red alpha: 0.7)
		do: [
			canvas moveToX: 150 y: 25.
			canvas lineToX: 270 y: 175.
			canvas lineToX: 30 y: 175.
			canvas closePath ].
	^ form
]
