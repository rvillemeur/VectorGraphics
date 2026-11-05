"
The examples of the SVG path parser: each parses a real SVG path string with `SVGPathParser parse:`, runs the commands it answers on a canvas and answers the Form.

They show the whole route a path string takes: the parser tokenises on the command letters and hands the numbers to SVGNumberStream, and the commands it builds are the ones PathCommandExamples builds by hand. Drawing the result needs a canvas, which is why this examples package depends on VectorGraphics-Engine too.

`newForm` and `newCanvasOn:` are the private helpers every example here uses.

## The examples

- `svgStar` — a five-pointed star, `M L L L L Z`
- `svgHeart` — a heart, six cubic Béziers
- `svgArrow` — an arrow, `M` and six lines
"
Class {
	#name : 'SVGPathExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Paths-Examples-Examples',
	#package : 'VectorGraphics-Paths-Examples',
	#tag : 'Examples'
}

{ #category : 'private' }
SVGPathExamples class >> newCanvasOn: aForm [
	"Identity transform set by VectorCanvas class >> onForm: — direct pixel coordinates."

	^ VectorCanvas onForm: aForm
]

{ #category : 'private' }
SVGPathExamples class >> newForm [
	"White 300x200 32-bit form ready for vector rendering."

	| form |
	form := Form extent: 300 @ 200 depth: 32.
	form fillColor: Color white.
	^ form
]

{ #category : 'svg examples' }
SVGPathExamples class >> svgArrow [
	"Right-pointing arrow parsed from an SVG path string.
	SVGPathExamples svgArrow inspect"
<sampleInstance>
	| form canvas cmds |
	form := self newForm.
	canvas := self newCanvasOn: form.
	cmds := SVGPathParser parse:
		'M 10 90 L 150 90 L 150 60 L 260 100 L 150 140 L 150 110 L 10 110 Z'.
	canvas
		strokeWidth: 1.5
		color: Color darkGray
		fillColor: (Color blue alpha: 0.7)
		do: [ canvas runPathCommands: cmds ].
	^ form
]

{ #category : 'svg examples' }
SVGPathExamples class >> svgHeart [
	"Heart shape built from cubic Bézier curves, parsed from an SVG path string.
	SVGPathExamples svgHeart inspect"
<sampleInstance>
	| form canvas cmds |
	form := self newForm.
	canvas := self newCanvasOn: form.
	cmds := SVGPathParser parse:
		'M 150 80 C 150 65 130 45 110 45 C 75 45 75 90 75 90 C 75 120 110 145 150 165 C 190 145 225 120 225 90 C 225 90 225 45 190 45 C 170 45 150 65 150 80 Z'.
	canvas
		strokeWidth: 1.5
		color: Color darkGray
		fillColor: (Color red alpha: 0.8)
		do: [ canvas runPathCommands: cmds ].
	^ form
]

{ #category : 'svg examples' }
SVGPathExamples class >> svgStar [
	"Five-pointed star parsed from an SVG path string, drawn by connecting every other vertex.
	SVGPathExamples svgStar inspect"
<sampleInstance>
	| form canvas cmds |
	form := self newForm.
	canvas := self newCanvasOn: form.
	cmds := SVGPathParser parse:
		'M 150 20 L 197 165 L 74 75 L 226 75 L 103 165 Z'.
	canvas
		strokeWidth: 1.5
		color: Color black
		fillColor: (Color yellow alpha: 0.8)
		do: [ canvas runPathCommands: cmds ].
	^ form
]
