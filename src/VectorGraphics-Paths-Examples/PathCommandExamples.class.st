"
The examples of the path commands: each builds a collection of PathCommand objects and runs it with `canvas runPathCommands:`, which is the route SVG path data takes once it is parsed.

They answer a Form, so they draw on a canvas and this examples package depends on VectorGraphics-Engine as well as on VectorGraphics-Paths. The parsing side is SVGPathExamples.

`newForm` and `newCanvasOn:` are the private helpers every example here uses.

## The examples

- `pathCommandTriangle` — M, L, L, Z
- `pathCommandRelativeLines` — M and relative l commands
- `pathCommandCubicBezier` — M and C
- `pathCommandArc` — M and A, an elliptical arc
- `pathCommandMixed` — a star from M, a multi-point L and Z
"
Class {
	#name : 'PathCommandExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Paths-Examples-Examples',
	#package : 'VectorGraphics-Paths-Examples',
	#tag : 'Examples'
}

{ #category : 'private' }
PathCommandExamples class >> newCanvasOn: aForm [
	"Identity transform set by VectorCanvas class >> onForm: — direct pixel coordinates."

	^ VectorCanvas onForm: aForm
]

{ #category : 'private' }
PathCommandExamples class >> newForm [
	"White 300x200 32-bit form ready for vector rendering."

	| form |
	form := Form extent: 300 @ 200 depth: 32.
	form fillColor: Color white.
	^ form
]

{ #category : 'path command examples' }
PathCommandExamples class >> pathCommandArc [
	"Elliptical arc drawn via PathArcCommand — SVG 'A' command.
	Draws a large-arc sweep from (50,100) to (250,100) with rx=100 ry=60.
	PathCommandExamples pathCommandArc inspect"
<sampleInstance>
	| form canvas cmds |
	form := self newForm.
	canvas := self newCanvasOn: form.
	cmds := OrderedCollection new.
	cmds add: (PathMoveToCommand to: 50 @ 100).
	cmds add: (PathArcCommand
		to: 250 @ 100
		rx: 100 ry: 60
		xAxisRotationDegrees: 0
		largeArc: true
		sweep: true).
	canvas strokeWidth: 2.0 color: Color blue do: [ canvas runPathCommands: cmds ].
	^ form
]

{ #category : 'path command examples' }
PathCommandExamples class >> pathCommandCubicBezier [
	"Cubic Bézier curve built from PathMoveToCommand + PathCurveToCommand.
	Equivalent to SVG path 'M 30 150 C 100 20 200 20 270 150'.
	PathCommandExamples pathCommandCubicBezier inspect"
<sampleInstance>
	| form canvas cmds |
	form := self newForm.
	canvas := self newCanvasOn: form.
	cmds := OrderedCollection new.
	cmds add: (PathMoveToCommand to: 30 @ 150).
	cmds add: (PathCurveToCommand
		to: 270 @ 150
		control1: 100 @ 20
		control2: 200 @ 20).
	canvas strokeWidth: 2.0 color: Color blue do: [ canvas runPathCommands: cmds ].
	^ form
]

{ #category : 'path command examples' }
PathCommandExamples class >> pathCommandMixed [
	"Star shape combining PathMoveToCommand, PathLineToCommand, and PathCloseCommand.
	Demonstrates running a mixed collection of PathCommand objects on one canvas.
	PathCommandExamples pathCommandMixed inspect"
<sampleInstance>
	| form canvas cmds |
	form := self newForm.
	canvas := self newCanvasOn: form.
	cmds := OrderedCollection new.
	cmds add: (PathMoveToCommand to: 150 @ 20).
	cmds add: (PathLineToCommand toPoints: {
		58 @ 190. 270 @ 75. 30 @ 75. 242 @ 190 }).
	cmds add: PathCloseCommand new.
	canvas
		strokeWidth: 2.0
		color: Color black
		fillColor: (Color yellow alpha: 0.6)
		do: [ canvas runPathCommands: cmds ].
	^ form
]

{ #category : 'path command examples' }
PathCommandExamples class >> pathCommandRelativeLines [
	"Zigzag drawn with relative PathLineToCommands (SVG 'l' lowercase).
	Each line-to is offset from the current pen position.
	PathCommandExamples pathCommandRelativeLines inspect"
<sampleInstance>
	| form canvas cmds |
	form := self newForm.
	canvas := self newCanvasOn: form.
	cmds := OrderedCollection new.
	cmds add: (PathMoveToCommand to: 20 @ 100).
	cmds add: (PathLineToCommand toRelativePoint: 50 @ -60).
	cmds add: (PathLineToCommand toRelativePoint: 50 @ 60).
	cmds add: (PathLineToCommand toRelativePoint: 50 @ -60).
	cmds add: (PathLineToCommand toRelativePoint: 50 @ 60).
	cmds add: (PathLineToCommand toRelativePoint: 50 @ -60).
	canvas strokeWidth: 2.0 color: Color magenta do: [ canvas runPathCommands: cmds ].
	^ form
]

{ #category : 'path command examples' }
PathCommandExamples class >> pathCommandTriangle [
	"Triangle drawn entirely via PathCommand objects instead of canvas API calls.
	Equivalent to SVG path 'M 150 25 L 270 175 L 30 175 Z'.
	PathCommandExamples pathCommandTriangle inspect"
<sampleInstance>
	| form canvas cmds |
	form := self newForm.
	canvas := self newCanvasOn: form.
	cmds := OrderedCollection new.
	cmds add: (PathMoveToCommand to: 150 @ 25).
	cmds add: (PathLineToCommand toPoint: 270 @ 175).
	cmds add: (PathLineToCommand toPoint: 30 @ 175).
	cmds add: PathCloseCommand new.
	canvas
		strokeWidth: 2.0
		color: Color black
		fillColor: (Color red alpha: 0.7)
		do: [ canvas runPathCommands: cmds ].
	^ form
]
