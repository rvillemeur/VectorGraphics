"
I hold the examples of unit 2.3: the coverage of one fill found the way the kernel finds it, and a whole frame drawn tile by tile.

Each is one click from the browser and each rebuilds its object, so a change to the walk shows up the next time an example is opened. The frames are drawn here rather than taken from the conformance corpus, because the corpus lives in a test package and this one may not name it; the gate over the corpus is in `VGTiledFillTest`.

See `VGTileCoverage` and `VGTiledFillRasteriser`.
"
Class {
	#name : 'VGTiledFillExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Vulkan-Examples-Examples',
	#package : 'VectorGraphics-Vulkan-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGTiledFillExamples class >> coverageOfACircle [
	"The coverage of one antialiased circle, on fractional coordinates so that no edge of it falls
	 on a pixel boundary."

	<sampleInstance>
	| surface |
	surface := VGCairoImageSurface extent: self frameExtent.
	surface newContext
		circleCenterX: 31.75 y: 32.25 radius: 19.5;
		fill.
	^ VGTileCoverage of: surface displayList entries first
]

{ #category : 'examples' }
VGTiledFillExamples class >> encodingOfThreeShapes [
	"The same three fills, binned and then written out as the buffers a dispatch uploads. The
	 Tile table and Entries tabs read the buffers back, and the rasteriser draws this encoding
	 as readily as it draws a binning."
	<sampleInstance>
	| surface |
	surface := VGCairoImageSurface extent: self frameExtent.
	surface newContext
		sourceColorR: 0.1 g: 0.7 b: 0.2 a: 1.0;
		rectangleX: 4 y: 4 width: 56 height: 56;
		fill;
		setOperatorSource;
		sourceColorR: 0.9 g: 0.4 b: 0.0 a: 0.6;
		circleCenterX: 26 y: 26 radius: 16.5;
		fill;
		setOperatorClear;
		circleCenterX: 42 y: 42 radius: 10.25;
		fill.
	^ VGTiledFillEncoding of: surface displayList extent: self frameExtent
]

{ #category : 'constants' }
VGTiledFillExamples class >> frameExtent [
	"The extent of the conformance cases, so that an example and a case can be read against each
	 other. The corpus itself may not be named from this package."

	^ 64 @ 64
]

{ #category : 'examples' }
VGTiledFillExamples class >> pixelPaintOfATranslucentOrange [
	"The paint a decoded entry carries: one premultiplied pixel, quantised once by the format
	 the encoding writes and answered again wherever it is asked for."
	<sampleInstance>
	| pixel |
	pixel := (VGColorPaint
		          r: 0.9
		          g: 0.4
		          b: 0.0
		          alpha: 0.6) pixelIn: VGTiledFillEncoding targetFormat atX: 0 y: 0.
	^ VGPixelPaint pixel: pixel
]

{ #category : 'examples' }
VGTiledFillExamples class >> tiledFillOfThreeShapes [
	"A frame of three fills under three operators, binned over the default grid and not yet drawn:
	 the Drawing tab draws it, on a surface of its own."

	<sampleInstance>
	| surface |
	surface := VGCairoImageSurface extent: self frameExtent.
	surface newContext
		sourceColorR: 0.1 g: 0.7 b: 0.2 a: 1.0;
		rectangleX: 4 y: 4 width: 56 height: 56;
		fill;
		setOperatorSource;
		sourceColorR: 0.9 g: 0.4 b: 0.0 a: 0.6;
		circleCenterX: 26 y: 26 radius: 16.5;
		fill;
		setOperatorClear;
		circleCenterX: 42 y: 42 radius: 10.25;
		fill.
	^ VGTiledFillRasteriser of: surface displayList extent: self frameExtent
]
