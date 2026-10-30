"
I hold the examples of unit 2.2: a tile grid, a frame binned into it, and the census of the
reference frame.

Each is one click from the browser and each rebuilds its object, so a change to the binning shows up
the next time an example is opened. `censusOfTheReferenceFrame` is the frame the tile size was
chosen for and draws on the software path, so it takes a second or two. The census over the
conformance corpus, which is the gate of the unit, is in `VGTileBinningTest` instead, because the
corpus lives in a test package and this one may not name it.

See `VGTileGrid`, `VGTileBinning` and `VGTileBinningCensus`.
"
Class {
	#name : 'VGTileBinningExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Vulkan-Examples-Examples',
	#package : 'VectorGraphics-Vulkan-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGTileBinningExamples class >> binningOfTwoDistantShapes [
	<sampleInstance>
	"Two small fills far apart in one frame, binned. The Binning tab counts the tiles they touch
	 between them and the Busiest tiles tab names them: this is what binning buys, two handfuls of
	 tiles instead of the whole frame."

	| surface context |
	surface := VGCairoImageSurface extent: 128 @ 128.
	context := surface newContext.
	context sourceColorR: 1.0 g: 0.2 b: 0.2 a: 1.0.
	context rectangleX: 4 y: 4 width: 20 height: 20.
	context fill.
	context sourceColorR: 0.2 g: 0.4 b: 1.0 a: 1.0.
	context circleCenterX: 100 y: 100 radius: 12.
	context fill.
	^ VGTileBinning of: surface displayList extent: surface extent
]

{ #category : 'examples' }
VGTileBinningExamples class >> binningWithInteriorTilesMarked [
	<sampleInstance>
	"One large fill in a frame of sixty-four tiles, binned. The Binning tab names how many of the
	 binned pairs are interior: a tile wholly inside the shape and its clip needs no coverage
	 walked, and here the tiles along the edge of the square are the only ones that do."

	| surface context |
	surface := VGCairoImageSurface extent: 128 @ 128.
	context := surface newContext.
	context sourceColorR: 0.1 g: 0.6 b: 0.4 a: 1.0.
	context rectangleX: 20 y: 20 width: 88 height: 88.
	context fill.
	^ VGTileBinning of: surface displayList extent: surface extent
]

{ #category : 'examples' }
VGTileBinningExamples class >> censusOfTheReferenceFrame [
	<sampleInstance>
	"The frame the tile size is chosen for, binned at the default size: eight hundred by six
	 hundred, drawn through the Bloc renderer, with gradients, strokes, glyphs and blits in it.
	 The Cases tab is the count of tiles touched, and its stray pixel column has to be zero.
	 VGTileBinningCensus class >> referenceOccupancyByTileExtent runs the same frame at eight,
	 sixteen and thirty-two, which is the measurement VGTileGrid class >> defaultTileExtent quotes;
	 it is three frames of the software path and is left to a caller who wants to wait. The census
	 over the conformance corpus is in VGTileBinningTest, because the corpus is a test package and
	 this one may not name it."

	^ VGTileBinningCensus overTheReferenceFrame
]

{ #category : 'examples' }
VGTileBinningExamples class >> tileGridOfTheReferenceFrame [
	<sampleInstance>
	"The grid the reference frame of unit 1.11 is cut into at the default tile size: fifty columns
	 by thirty-eight rows, the last row short because six hundred does not divide by sixteen. The
	 Tiles tab lists every tile with the bounds it really answers."

	^ VGTileGrid extent: VGFrameProfile referenceExtent
]
