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
VGTiledFillExamples class >> blitRewrittenAsAFill [
	"The fill the tiled rasteriser draws a blit as, which is what unit 2.6 added: a blit of a
	 mask at an offset, asked for the fill it becomes. Its segments are the rectangle of its own
	 narrowed clip and its Mask tab holds the alpha of every pixel of that rectangle, flattened
	 once here rather than sampled once a tile."

	<sampleInstance>
	| surface |
	surface := VGCairoImageSurface extent: self frameExtent.
	surface newContext
		sourceColorR: 0.2 g: 0.4 b: 0.9 a: 1.0;
		recordBlitOf: self maskTileOfTheFrame at: 7 @ 5.
	^ surface displayList entries first asTiledFill
]

{ #category : 'examples' }
VGTiledFillExamples class >> buffersOfAFrameOfTwoEntries [
	<sampleInstance>
	"The buffers one frame rides to the device in, sized for two entries with eight edges, three
	 gradient stops and a mask of 1024 bytes between them, and for the six tiles those entries
	 touch. Nothing is written into them here: the point of the set is the sizes, which the
	 Buffers tab reads off the live arrays."

	^ VGTiledFillBuffers new
		  allocateForEntries: 2 edges: 8 stops: 3 masks: 1024;
		  allocateForTiles: 6 references: 9;
		  yourself
]

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
VGTiledFillExamples class >> coverageOfAFillCutOutByTwoCircles [
	"The coverage of a fill of the whole tile inside a clip of two overlapping circles, which is
	 the shaped clip unit 2.7 draws on the device. The Shapes tab names the three walks the
	 coverage sweeps together, and the Coverage tab shows the lens the three of them leave."
	<sampleInstance>
	| surface |
	surface := VGCairoImageSurface extent: self frameExtent.
	surface newContext
		circleCenterX: 27.75 y: 32.25 radius: 18.5;
		clip;
		circleCenterX: 40.25 y: 32.25 radius: 18.5;
		clip;
		rectangleX: 0 y: 0 width: 64 height: 64;
		fill.
	^ VGTileCoverage of: surface displayList entries first
]

{ #category : 'examples' }
VGTiledFillExamples class >> decoderOfAFillInTwoClipShapes [
	"A fill cut out by two overlapping circles, read back out of the buffers a dispatch uploads.
	 The Shapes tab lists the fill and both shapes of its clip as the one kind of record they
	 are written as, which is what lets the kernel walk a clip shape with the code that walks a
	 fill."
	<sampleInstance>

	| surface |
	surface := VGCairoImageSurface extent: self frameExtent.
	surface newContext
		sourceColorR: 0.9 g: 0.3 b: 0.2 a: 1.0;
		circleCenterX: 28 y: 32 radius: 18;
		clip;
		circleCenterX: 40 y: 32 radius: 18;
		clip;
		rectangleX: 0 y: 0 width: 64 height: 64;
		fill.
	^ (VGTiledFillEncoding of: surface displayList extent: self frameExtent) decoder
]

{ #category : 'examples' }
VGTiledFillExamples class >> dispatchOfThreeShapesOnThisMachine [
	<sampleInstance>
	"One click: the three shapes of the frame above sent to a device, with the Buffers tab
	 holding what went out, binding by binding, and the target holding what came back.
	 Where no device computes, the frame is encoded and nothing is dispatched: an example may not
	 raise on a machine with no driver, and the bytes it would have uploaded are worth reading
	 there too.
	 The context is destroyed before the dispatch is answered, because the bytes a dispatch keeps
	 are in object memory and a device held open by an example would outlive the click."

	| encoding target context dispatch |
	encoding := self encodingOfThreeShapes.
	target := ByteArray new:
		          self frameExtent x * self frameExtent y
		          * VGTiledFillEncoding targetFormat bytesPerPixel.
	context := [ VkContext computeContext ]
		           on: Error
		           do: [ :failure | nil ].
	context ifNil: [
		dispatch := VGTiledFillDispatch new.
		dispatch encode: encoding target: target.
		^ dispatch ].
	dispatch := VGTiledFillDispatch on: context.
	^ [
	  dispatch draw: encoding into: target.
	  dispatch ] ensure: [ context destroy ]
]

{ #category : 'examples' }
VGTiledFillExamples class >> encodingOfABlitAndASolidFill [
	"A blit of a mask at an offset and a solid rectangle beside it, written out as the buffers a
	 dispatch uploads. The Masks tab reads the rectangle and the alphas of the blit back out of
	 the mask buffers and shows the solid fill carrying an empty rectangle and no bytes, which is
	 how one kind of entry reaches the device for both of them."

	<sampleInstance>
	| surface |
	surface := VGCairoImageSurface extent: self frameExtent.
	surface newContext
		sourceColorR: 0.2 g: 0.4 b: 0.9 a: 1.0;
		recordBlitOf: self maskTileOfTheFrame at: 7 @ 5;
		sourceColorR: 0.1 g: 0.1 b: 0.1 a: 1.0;
		rectangleX: 40 y: 40 width: 20 height: 20;
		fill.
	^ VGTiledFillEncoding of: surface displayList extent: self frameExtent
]

{ #category : 'examples' }
VGTiledFillExamples class >> encodingOfAGradientAndASolidFill [
	"A linear gradient of three uneven stops over the whole frame and a solid rectangle on top
	 of it, written out as the buffers a dispatch uploads. The Paints tab reads the gradient back
	 out of the paint buffer and the Stops tab reads its three stops, which is what unit 2.4
	 added to the encoding; the solid fill is there so that both kinds of paint are in one frame,
	 as a real one has them."
	<sampleInstance>
	| surface pattern |
	pattern := VGCairoLinearGradientPattern
		           from: 4 @ 4
		           to: 60 @ 44
		           addStopsFrom: {
				           (0.0 -> (Color r: 1.0 g: 0.1 b: 0.0)).
				           (0.35 -> (Color r: 0.0 g: 0.9 b: 0.3)).
				           (1.0 -> (Color r: 0.0 g: 0.2 b: 1.0 alpha: 0.4)) }.
	surface := VGCairoImageSurface extent: self frameExtent.
	surface newContext
		sourcePattern: pattern;
		rectangleX: 0 y: 0 width: self frameExtent x height: self frameExtent y;
		fill;
		sourceColorR: 0.1 g: 0.1 b: 0.1 a: 1.0;
		rectangleX: 20 y: 20 width: 24 height: 24;
		fill.
	^ VGTiledFillEncoding of: surface displayList extent: self frameExtent
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
VGTiledFillExamples class >> kernelModuleCacheOfTwoTileExtents [
	<sampleInstance>
	"The kernel class with its module cache primed for two tile extents. The class-side Module
	 cache tab shows what a session holds: a module depends on the tile extent alone, so a frame
	 reads one from here instead of building one of its own."

	VGTiledFillKernel clearSpirvCache.
	VGTiledFillKernel spirvOnTileExtent: VGTileGrid defaultTileExtent.
	VGTiledFillKernel spirvOnTileExtent: 8 @ 8.
	^ VGTiledFillKernel
]

{ #category : 'examples' }
VGTiledFillExamples class >> kernelOfTheDefaultGrid [
	"The tiled fill kernel of the tile size every frame of this engine is binned over, built so
	 that its module and the bytes of it are there to be read."

	<sampleInstance>
	| kernel |
	kernel := VGTiledFillKernel default.
	kernel spirv.
	^ kernel
]

{ #category : 'examples' }
VGTiledFillExamples class >> layoutOfTheBuffers [
	"The layout of the buffers one frame rides to the device in. A class holding no state is its
	 own single instance, so the example answers the class and its Records tab explains it."

	<sampleInstance>
	^ VGTiledFillLayout
]

{ #category : 'examples' }
VGTiledFillExamples class >> maskTileOfTheFrame [
	"A mask surface carrying all three alphas a mask can carry: transparent at the top, half
	 opaque over a band and opaque under a disc, so that a blit through it shows more than a copy
	 of one byte. It is half the frame wide, so that a blit of it sits at an offset inside the
	 frame rather than over the whole of it."

	| extent tile |
	extent := self frameExtent // 2.
	tile := VGCairoImageSurface extent: extent.
	tile newContext
		clearTransparent;
		sourceColorR: 1.0 g: 1.0 b: 1.0 a: 0.5;
		rectangleX: 0 y: extent y / 2 width: extent x height: extent y / 2;
		fill;
		sourceColorR: 1.0 g: 1.0 b: 1.0 a: 1.0;
		circleCenterX: extent x / 2 y: extent y / 2 radius: extent x / 4;
		fill.
	tile flush.
	^ tile
]

{ #category : 'examples' }
VGTiledFillExamples class >> pixelEmitterOfTheDefaultKernel [
	"The emitter of a kernel that has already built its module, which is the only state it has:
	 the builder, the GLSL set and the value table of that module. The Composition tab reads the
	 arithmetic it holds for each operator of the subset."
	<sampleInstance>
	| kernel |
	kernel := VGTiledFillKernel default.
	kernel spirv.
	^ VGTiledFillPixelEmitter on: kernel
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
