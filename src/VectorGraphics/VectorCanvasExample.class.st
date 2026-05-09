"
Runnable examples demonstrating VectorCanvas rendering capabilities.

All methods are class-side. Each example creates an off-screen Form, draws on it via
VectorCanvas, and returns the Form for inspection or display.

To run an example, evaluate in a Playground:
  VectorCanvasExample exampleLine inspect
  VectorCanvasExample exampleTriangle display
  VectorCanvasExample exampleCompositeDrawing display

The private helpers `newForm` and `newCanvasOn:` are shared across all examples.

## Examples by shape type
- `exampleLine`                    — single diagonal line (strokeWidth:color:do:)
- `exampleLineConvenience`         — same via line:to:width:color: convenience method
- `examplePolyLine`                — connected polyline through multiple points
- `exampleCubicBezier`             — cubic Bézier through 4 control points
- `exampleQuadraticBezier`         — quadratic Bézier through 3 control points
- `exampleCircleStroke`            — stroked circle (ellipse with equal radii)
- `exampleCircleFill`              — filled circle
- `exampleEllipse`                 — ellipse with stroke + fill
- `exampleFilledRectangle`         — solid rectangle via fillRectangle:color:
- `exampleStrokedRectangle`        — rectangle outline via frameRectangle:borderWidth:color:
- `exampleStrokedAndFilledRectangle` — rectangle with both stroke and fill
- `exampleRoundedRectangle`        — filled rounded-corner rectangle
- `exampleTriangle`                — triangle with stroke and semi-transparent fill
- `exampleCompositeDrawing`        — multiple shapes layered on one canvas
"
Class {
	#name : 'VectorCanvasExample',
	#superclass : 'Object',
	#category : 'VectorGraphics-Examples',
	#package : 'VectorGraphics',
	#tag : 'Examples'
}

{ #category : 'examples' }
VectorCanvasExample class >> exampleCircleFill [
	"Filled circle using fillColor:do: with an ellipse of equal radii.
	VectorCanvasExample exampleCircleFill inspect"
<sampleInstance>
	| form canvas |
	form := self newForm.
	canvas := self newCanvasOn: form.
	canvas fillColor: Color orange do: [
		canvas ellipseCenterX: 150 y: 100 rx: 70 ry: 70 ].
	^ form
]

{ #category : 'examples' }
VectorCanvasExample class >> exampleCircleStroke [
	"Stroked circle outline using strokeWidth:color:do:.
	VectorCanvasExample exampleCircleStroke inspect"
<sampleInstance>
	| form canvas |
	form := self newForm.
	canvas := self newCanvasOn: form.
	canvas strokeWidth: 3.0 color: Color black do: [
		canvas ellipseCenterX: 150 y: 100 rx: 70 ry: 70 ].
	^ form
]

{ #category : 'examples' }
VectorCanvasExample class >> exampleCompositeDrawing [
	"Multiple shapes on one canvas demonstrating layering.
	VectorCanvasExample exampleCompositeDrawing inspect"
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
VectorCanvasExample class >> exampleCubicBezier [
	"Cubic Bezier curve through 4 control points.
	VectorCanvasExample exampleCubicBezier inspect"
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
VectorCanvasExample class >> exampleEllipse [
	"Ellipse with both stroke and fill using the FormCanvas-protocol method.
	VectorCanvasExample exampleEllipse inspect"
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
VectorCanvasExample class >> exampleFilledRectangle [
	"Solid filled rectangle using fillRectangle:color:.
	VectorCanvasExample exampleFilledRectangle inspect"
<sampleInstance>
	| form canvas |
	form := self newForm.
	canvas := self newCanvasOn: form.
	canvas fillRectangle: (50 @ 40 extent: 200 @ 120) color: (Color blue alpha: 0.7).
	^ form
]

{ #category : 'examples' }
VectorCanvasExample class >> exampleLine [
	"Simple stroked line from one point to another using strokeWidth:color:do:.
	VectorCanvasExample exampleLine inspect"
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
VectorCanvasExample class >> exampleLineConvenience [
	"Line using the FormCanvas-protocol convenience method line:to:width:color:.
	VectorCanvasExample exampleLineConvenience inspect"
<sampleInstance>
	| form canvas |
	form := self newForm.
	canvas := self newCanvasOn: form.
	canvas line: 30 @ 50 to: 270 @ 150 width: 3.0 color: Color purple.
	^ form
]

{ #category : 'examples' }
VectorCanvasExample class >> examplePolyLine [
	"Polyline through multiple points using polyLine:.
	VectorCanvasExample examplePolyLine inspect"
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
VectorCanvasExample class >> exampleQuadraticBezier [
	"Quadratic Bezier curve through 3 control points.
	VectorCanvasExample exampleQuadraticBezier inspect"
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
VectorCanvasExample class >> exampleRoundedRectangle [
	"Filled rounded-corner rectangle using roundRect:color:radius:.
	VectorCanvasExample exampleRoundedRectangle inspect"
<sampleInstance>
	| form canvas |
	form := self newForm.
	canvas := self newCanvasOn: form.
	canvas roundRect: (50 @ 40 extent: 200 @ 120) color: (Color green alpha: 0.8) radius: 25.
	^ form
]

{ #category : 'examples' }
VectorCanvasExample class >> exampleStrokedAndFilledRectangle [
	"Rectangle with both stroke and fill using frameAndFillRectangle:fillColor:borderWidth:borderColor:.
	VectorCanvasExample exampleStrokedAndFilledRectangle inspect"
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
VectorCanvasExample class >> exampleStrokedRectangle [
	"Rectangle outline only using frameRectangle:borderWidth:color:.
	VectorCanvasExample exampleStrokedRectangle inspect"
<sampleInstance>
	| form canvas |
	form := self newForm.
	canvas := self newCanvasOn: form.
	canvas frameRectangle: (50 @ 40 extent: 200 @ 120) borderWidth: 3.0 color: Color red.
	^ form
]

{ #category : 'examples' }
VectorCanvasExample class >> exampleTriangle [
	"Triangle with stroke and fill using moveToX:y:, lineToX:y:, closePath.
	VectorCanvasExample exampleTriangle inspect"
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

{ #category : 'private' }
VectorCanvasExample class >> newCanvasOn: aForm [
	"Identity transform set by VectorCanvas class >> onForm: — direct pixel coordinates."

	^ VectorCanvas onForm: aForm
]

{ #category : 'private' }
VectorCanvasExample class >> newForm [
	"White 300x200 32-bit form ready for vector rendering."

	| form |
	form := Form extent: 300 @ 200 depth: 32.
	form fillColor: Color white.
	^ form
]

{ #category : 'see class side' }
VectorCanvasExample >> seeClassSide [
]
