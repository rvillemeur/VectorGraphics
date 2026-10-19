"
I hold the one-click examples for the paints and the patterns, which are where a painting verb takes its colour from.

A pattern is the Cairo-facing object a caller builds and keeps; a paint is the block of coefficients the backend reads, and the two carry the same tag. Each of my examples rebuilds its object on every call and asserts nothing. Between them they show the three things worth looking at: the layout of the coefficient block, the ramp a gradient evaluates, and the point at which an extend mode stops painting.
"
Class {
	#name : 'VGPaintExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Cairo-Examples-Examples',
	#package : 'VectorGraphics-Cairo-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGPaintExamples class >> colourPaint [
	<sampleInstance>
	"The paint of a solid colour, which is what every one of the sixteen coefficients of a paint
	 can be read off in the Block tab."

	^ VGColorPaint r: 0.9 g: 0.3 b: 0.1 alpha: 1.0
]

{ #category : 'examples' }
VGPaintExamples class >> colourPattern [
	<sampleInstance>
	"The pattern a context builds for itself when it is asked for a flat colour, and the pattern
	 its default source is."

	^ VGCairoColorPattern r: 0.9 g: 0.3 b: 0.1 alpha: 1.0
]

{ #category : 'examples' }
VGPaintExamples class >> linearGradientPaint [
	<sampleInstance>
	"The two stop ramp of the conformance corpus, laid along the first sixty-four pixels of a row
	 and set to pad, so a point past either end keeps the colour of the end stop."

	^ (VGLinearGradientPaint from: 0 @ 0 to: 64 @ 0)
		  extend: #pad;
		  addStopAt: 0.0 color: (Color r: 1.0 g: 0.9 b: 0.2);
		  addStopAt: 1.0 color: (Color r: 0.1 g: 0.2 b: 0.8);
		  yourself
]

{ #category : 'examples' }
VGPaintExamples class >> linearGradientPattern [
	<sampleInstance>
	"A gradient pattern with a matrix of its own: the ramp is declared over a unit length and the
	 matrix scales it over sixty-four pixels, which is the Cairo way round. A pattern matrix maps a
	 point of the space the pattern is used in into the space the pattern is declared in, so it is
	 the inverse of the transformation a reader expects."

	| pattern |
	pattern := VGCairoLinearGradientPattern
		           from: 0 @ 0
		           to: 1 @ 0
		           addStopsFrom: {
				           (0.0 -> (Color r: 1.0 g: 0.9 b: 0.2)).
				           (1.0 -> (Color r: 0.1 g: 0.2 b: 0.8)) }.
	pattern matrix: (VGCairoMatrix newScalingBy: (1 / 64) @ 1).
	^ pattern
]

{ #category : 'examples' }
VGPaintExamples class >> radialGradientPaint [
	<sampleInstance>
	"Two circles sharing a centre, which is the degenerate radial Cairo solves without a quadratic:
	 the ramp runs from the middle of a sixty-four pixel square out to its edge."

	^ (VGRadialGradientPaint
		   innerCenter: 32 @ 32
		   innerRadius: 0
		   outerCenter: 32 @ 32
		   outerRadius: 32)
		  addStopAt: 0.0 color: Color white;
		  addStopAt: 1.0 color: (Color r: 0.1 g: 0.2 b: 0.8);
		  yourself
]

{ #category : 'examples' }
VGPaintExamples class >> radialGradientPattern [
	<sampleInstance>
	"The two circle form Cairo solves with a quadratic: the inner circle sits off the centre of the
	 outer one, which is the shape of a lit sphere."

	^ VGCairoRadialGradientPattern
		  innerCenter: 24 @ 24
		  innerRadius: 4
		  outerCenter: 32 @ 32
		  outerRadius: 32
		  addStopsFrom: {
				  (0.0 -> Color white).
				  (1.0 -> (Color r: 0.1 g: 0.2 b: 0.8)) }
]

{ #category : 'examples' }
VGPaintExamples class >> repeatingLinearGradientPaint [
	<sampleInstance>
	"The same ramp over eight pixels and set to repeat, so the Ramp tab shows the offset folding
	 back into zero to one on either side of the gradient."

	^ (VGLinearGradientPaint from: 0 @ 0 to: 8 @ 0)
		  extend: #repeat;
		  addStopAt: 0.0 color: (Color r: 1.0 g: 0.9 b: 0.2);
		  addStopAt: 1.0 color: (Color r: 0.1 g: 0.2 b: 0.8);
		  yourself
]

{ #category : 'examples' }
VGPaintExamples class >> repeatingSurfacePaint [
	<sampleInstance>
	"A surface paint over the tile, set to repeat, so every point of the plane reads a pixel of the
	 tile. The Extend tab is worth reading on this one and on the next."

	^ (VGSurfacePaint surface: self tile)
		  extend: #repeat;
		  yourself
]

{ #category : 'examples' }
VGPaintExamples class >> surfacePaintThatPaintsNothingOutsideItsTile [
	<sampleInstance>
	"The same tile with the default extend mode, none, which is the one mode that answers no
	 colour at all: outside the tile the paint lays nothing down and the pixel underneath stays
	 as it was."

	^ VGSurfacePaint surface: self tile
]

{ #category : 'examples' }
VGPaintExamples class >> surfacePattern [
	<sampleInstance>
	"The pattern a context builds when a surface is the source. Its extend mode is none, as Cairo's
	 is, and its filter is good."

	^ VGCairoSurfacePattern surface: self tile
]

{ #category : 'fixtures' }
VGPaintExamples class >> tile [
	"A small two colour tile: big enough for an extend mode to act on, small enough to read pixel
	 by pixel. The right half is opaque orange over a translucent blue ground, so a sample tells
	 which half of the tile it came from."

	| surface context |
	surface := VGCairoImageSurface extent: 8 @ 8.
	context := surface newContext.
	context clearColor: (Color r: 0.1 g: 0.6 b: 0.8 alpha: 0.5).
	context sourceColor: (Color r: 1.0 g: 0.5 b: 0.0).
	context rectangleX: 4 y: 0 width: 4 height: 8.
	context fill.
	^ surface
]
