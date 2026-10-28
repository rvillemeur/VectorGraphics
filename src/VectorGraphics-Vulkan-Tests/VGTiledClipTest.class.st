"
The shaped clip on the device: the frames whose clip is not a rectangle, which unit 2.7 added to the
subset the tiles draw.
A clip is a geometric intersection of spans and never a product of coverages, so every test here
has an oracle that performs that intersection: VGRasteriser for the walk of a pixel and the software
backend for a frame.
The degenerate clips no corpus case holds live here as frames of my own - two shapes at once, an
even-odd shape, a shape that misses the fill and a shape whose edges fall between pixels.
"
Class {
	#name : 'VGTiledClipTest',
	#superclass : 'VGTiledFrameTestCase',
	#category : 'VectorGraphics-Vulkan-Tests-Tests',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Tests'
}

{ #category : 'constants' }
VGTiledClipTest class >> clipCaseCount [
	"The cases of the conformance corpus that clip to a shape and that the subset draws: the
	 circle a fill is clipped to, and figure-outskirts-outside-translucent-background, whose
	 second entry fills through a surface paint and so joined the subset at unit 2.9. The number
	 is asserted wherever the corpus is walked, so a capability lost by a later change cannot pass
	 as a case quietly skipped."

	^ 2
]

{ #category : 'constants' }
VGTiledClipTest class >> clipFrameNames [
	"Every frame of my own, by the name of the method that answers it, so that a test holds all
	 of them and a frame added here is gated without the test being edited."

	^ #( #clippedFrame #clippedFrameOfTwoShapes #clippedFrameInAnEvenOddShape
	     #clippedFrameInAnAliasedShape #clippedFrameMissingItsFill
	     #clippedFrameUnderSourceAndClear )
]

{ #category : 'running' }
VGTiledClipTest >> clipCasesDo: aBlock [
	"Every case the subset draws that clips to a shape, with the block that draws it. The shape
	 is read off the entries of the case and not from a list of names, so a case the corpus
	 gains is found here on the day it is added. The count is asserted here, so that a subset
	 quietly narrowed by a later change fails in every test that walks the corpus."

	| drawn |
	drawn := 0.
	self supportedCasesDo: [ :case :draw :entries |
		(entries anySatisfy: [ :each | each clip isRectangular not ]) ifTrue: [
			drawn := drawn + 1.
			aBlock value: case value: draw ] ].
	self assert: drawn equals: self class clipCaseCount
]

{ #category : 'frames' }
VGTiledClipTest >> clippedFrame [
	"The clip the corpus holds and the profiled frame holds: one shape, wound by the winding rule,
	 antialiased, with a fill that reaches outside it."

	^ [ :context |
	  context
		  sourceColorR: 0.2 g: 0.4 b: 0.9 a: 1.0;
		  circleCenterX: 32 y: 32 radius: 18;
		  clip;
		  rectangleX: 0 y: 0 width: 64 height: 40;
		  fill ]
]

{ #category : 'frames' }
VGTiledClipTest >> clippedFrameInAnAliasedShape [
	"Antialiasing off makes a shape answer whole pixels and the same ones on every sub-row, so an
	 aliased clip shape is asked about the centre of a pixel and then leaves that pixel alone.
	 The fill stays antialiased, so the two modes meet in one walk, and the shape falls between
	 pixels so that the snapping shows."

	^ [ :context |
	  context
		  sourceColorR: 0.8 g: 0.6 b: 0.1 a: 1.0;
		  antialias: #none;
		  circleCenterX: 32.25 y: 31.75 radius: 17.5;
		  clip;
		  antialias: #default;
		  rectangleX: 0 y: 0 width: 64 height: 40;
		  fill ]
]

{ #category : 'frames' }
VGTiledClipTest >> clippedFrameInAnEvenOddShape [
	"A clip whose shape is wound by the even-odd rule, so the lens where the two circles overlap
	 is outside it. The rule rides inside the shape and not inside the fill, and the fill here is
	 wound by the other rule so that one cannot stand in for the other."

	^ [ :context |
	  context
		  sourceColorR: 0.1 g: 0.7 b: 0.4 a: 1.0;
		  useFillRuleEvenOdd;
		  circleCenterX: 26 y: 32 radius: 18;
		  circleCenterX: 38 y: 32 radius: 18;
		  clip;
		  useFillRuleWinding;
		  rectangleX: 0 y: 0 width: 64 height: 64;
		  fill ]
]

{ #category : 'frames' }
VGTiledClipTest >> clippedFrameMissingItsFill [
	"A clip shape whose bounds hold the whole fill and whose spans never meet it, so the frame
	 writes no pixel at all. A walk that fell back on the bounds of the clip would paint the fill
	 whole."

	^ [ :context |
	  context
		  sourceColorR: 0.3 g: 0.3 b: 0.9 a: 1.0;
		  moveToX: 0 y: 0;
		  lineToX: 64 y: 0;
		  lineToX: 0 y: 64;
		  clip;
		  rectangleX: 40 y: 40 width: 24 height: 24;
		  fill ]
]

{ #category : 'frames' }
VGTiledClipTest >> clippedFrameOfTwoShapes [
	"Two shapes at once, which no case of the corpus and no entry of the profiled frame holds. A
	 piece of a span survives where every shape lets it through, so the second shape meets what
	 the first left of it and no coverage is multiplied by another."

	^ [ :context |
	  context
		  sourceColorR: 0.9 g: 0.3 b: 0.2 a: 1.0;
		  circleCenterX: 28 y: 32 radius: 18;
		  clip;
		  circleCenterX: 40 y: 32 radius: 18;
		  clip;
		  rectangleX: 0 y: 0 width: 64 height: 64;
		  fill ]
]

{ #category : 'frames' }
VGTiledClipTest >> clippedFrameUnderSourceAndClear [
	"Three entries: a background, a fill through a shaped clip under source and another under
	 clear. Both of those operators are bounded, and a clip that is not a rectangle has to bound
	 them by its spans and not by its bounds, or source would blank the pixels its bounds hold
	 and its shape does not."

	^ [ :context |
	  context
		  sourceColorR: 0.2 g: 0.2 b: 0.2 a: 1.0;
		  rectangleX: 0 y: 0 width: 64 height: 64;
		  fill.
	  context
		  saveState;
		  circleCenterX: 24 y: 24 radius: 16;
		  clip;
		  sourceColorR: 1.0 g: 0.5 b: 0.0 a: 0.6;
		  operator: VGCairoOperator source;
		  rectangleX: 0 y: 0 width: 64 height: 64;
		  fill;
		  restoreState.
	  context
		  saveState;
		  circleCenterX: 42 y: 42 radius: 14;
		  clip;
		  operator: VGCairoOperator clear;
		  rectangleX: 0 y: 0 width: 64 height: 64;
		  fill;
		  restoreState ]
]

{ #category : 'asserting' }
VGTiledClipTest >> entryClippedBy: aBlock [
	"The one fill a frame of mine records: the block narrows the clip and then fills, and the
	 entry is read before anything drains the list."

	| list |
	list := self displayListOfExtent: self caseExtent drawnWith: aBlock.
	self assert: list entries size equals: 1.
	^ list entries first
]

{ #category : 'asserting' }
VGTiledClipTest >> largestCoverageComparedWithTheRasteriserFor: anEntry [
	"The walk of every pixel of one recorded fill against VGRasteriser, which performs the same
	 intersection a row at a time and is the oracle of the walk. Compared as floats and not as
	 quantised bytes: the two add the same terms in the same order, so they are equal exactly.
	 I answer the largest coverage seen, so that a test can say whether its frame covers anything
	 at all."

	| coverage rasteriser rows largest |
	coverage := VGTileCoverage of: anEntry.
	rasteriser := VGRasteriser
		              segments: anEntry segments coordinates
		              fillRule: anEntry segments fillRule
		              antialias: anEntry segments antialias
		              clip: anEntry clip.
	rows := 0.
	largest := 0.0.
	rasteriser coverageRowsDo: [ :y :row :left |
		rows := rows + 1.
		1 to: row size do: [ :index |
			self
				assert: (coverage atX: left + index - 1 row: y)
				equals: (row at: index).
			largest := largest max: (row at: index) ] ].
	self deny: rows isZero.
	^ largest
]

{ #category : 'tests - walking' }
VGTiledClipTest >> testAClipShapeThatMissesTheFillCoversNoPixel [
	"The degenerate clip: a shape whose bounds hold the whole fill and whose spans never meet it.
	 Every pixel the rasteriser visits is covered by nothing, and the walk has to agree rather
	 than fall back on the bounds of the clip."

	| entry |
	entry := self entryClippedBy: self clippedFrameMissingItsFill.
	self deny: entry clip isRectangular.
	self
		assert: (self largestCoverageComparedWithTheRasteriserFor: entry)
		equals: 0.0
]

{ #category : 'tests - encoding' }
VGTiledClipTest >> testAnEncodedClipCarriesEveryShapeItWasCutOutWith [
	"What the buffers hold of a clip that is not a rectangle: its bounds, and a record a shape
	 carrying that shape's own edges, fill rule and antialiasing mode. The coordinates narrow to
	 single floats on the way, which is the only thing the buffers may change about a shape."

	| encoding entry decoded |
	entry := self entryClippedBy: self clippedFrameOfTwoShapes.
	encoding := self
		            encodingOfExtent: self caseExtent
		            drawnWith: self clippedFrameOfTwoShapes.
	decoded := encoding entryAt: 1.
	self assert: decoded clip bounds equals: entry clip bounds.
	self assert: decoded clip shapes size equals: 2.
	decoded clip shapes with: entry clip shapes do: [ :read :written |
		self
			assert: read segments
			equals: (written segments collect: [ :each |
					 self roundedToSingleFloat: each ]).
		self assert: read fillRule equals: written fillRule.
		self assert: read isAliased equals: written isAliased ]
]

{ #category : 'tests' }
VGTiledClipTest >> testEveryClippedFrameOfMineDrawsOnTheDeviceWhatTheSoftwareBackendDraws [
	"The gate of unit 2.7 over the frames of my own, which is where the degenerate clips are:
	 two shapes at once, an even-odd shape, an aliased shape, a clip no fill reaches and the
	 other two operators of the subset. One context draws all of them. A machine with no device
	 holds nothing."

	| context |
	context := [ VkContext computeContext ]
		           on: Error
		           do: [ :failure | nil ].
	context ifNil: [ ^ self ].
	[
	self class clipFrameNames do: [ :name |
		| draw comparison |
		draw := self perform: name.
		comparison := VGFormComparison
			              between: (self
					               deviceFormOfExtent: self caseExtent
					               drawnWith: draw
					               on: context)
			              and: (self
					               softwareFormOfExtent: self caseExtent
					               drawnWith: draw).
		self
			assert:
			(comparison pixelsFartherThan: self class deviceChannelTolerance) = 0
			description: name.
		self
			assert: comparison differingPixelCount
				      <= self class devicePixelsAllowedToDifferPerCase
			description: name ] ] ensure: [ context destroy ]
]

{ #category : 'tests' }
VGTiledClipTest >> testEveryClippedFrameOfMineDrawsTheSameBytesFromTheBuffersAsFromItsOwnEntries [
	"The gate of the encoding over a clip that is not a rectangle: the rasteriser reads the
	 buffers and never the display list they came from, and the oracle is the same frame with
	 every coordinate of the fill and of every clip shape narrowed to single floats, which is
	 all a buffer can hold. A shape left unwritten draws the whole of its clip rectangle and
	 shows here."

	self class clipFrameNames do: [ :name |
		| draw |
		draw := self perform: name.
		self
			assert: (self encodedFormOfExtent: self caseExtent drawnWith: draw) bits
			= (self singleFloatFormOfExtent: self caseExtent drawnWith: draw) bits
			description: name printString , ' draws other bytes from the buffers' ]
]

{ #category : 'tests' }
VGTiledClipTest >> testEveryClippedFrameOfMineDrawsTheSameBytesThroughTheTilesAsTheSoftwareBackendDraws [
	"The gate of the tiled rasteriser over a clip that is not a rectangle, on the processor and
	 before any device: the same bytes as the software backend draws, and not merely bytes
	 within a tolerance of them, because both walks are the same arithmetic in the same float.
	 A sweep that cuts a piece in two where a crossing leaves the verdict alone shows here, in
	 the last bit of a channel."

	self class clipFrameNames do: [ :name |
		| draw |
		draw := self perform: name.
		self
			assert: (self tiledFormOfExtent: self caseExtent drawnWith: draw) bits
			= (self softwareFormOfExtent: self caseExtent drawnWith: draw) bits
			description: name printString , ' draws other bytes through the tiles' ]
]

{ #category : 'tests' }
VGTiledClipTest >> testEveryShapedClipCaseOfTheCorpusDrawsOnTheDeviceWhatTheSoftwareBackendDraws [
	"The gate of unit 2.7 over the corpus: every case the subset draws that clips to a shape,
	 drawn on the device and by the software backend on the same frame, holds to the tolerance
	 the fill cases of unit 2.4 set. One context draws all of them. A machine with no device
	 holds nothing."

	| context |
	context := [ VkContext computeContext ]
		           on: Error
		           do: [ :failure | nil ].
	context ifNil: [ ^ self ].
	[
	self clipCasesDo: [ :case :draw |
		self assertDeviceDrawsCase: case with: draw on: context ] ]
		ensure: [ context destroy ]
]

{ #category : 'tests - views' }
VGTiledClipTest >> testTheShapesTabOfACoverageListsTheFillAndEveryShapeOfItsClip [
	"The tab reads the walks the coverage built, so it names the shapes a sweep really runs over
	 and cannot drift from setEntry:. A column block only runs when a row is drawn, so every cell
	 is asked for here."

	| surface coverage builder presenter titles |
	surface := VGCairoImageSurface extent: self caseExtent.
	surface newContext
		circleCenterX: 28 y: 32 radius: 18;
		clip;
		circleCenterX: 40 y: 32 radius: 18;
		clip;
		rectangleX: 0 y: 0 width: 64 height: 64;
		fill.
	coverage := VGTileCoverage of: surface displayList entries first.
	builder := SpPresenterBuilder newApplication: SpApplication new.
	presenter := coverage inspectorShapes: builder.
	self assert: presenter items size equals: coverage clip shapes size + 1.
	titles := presenter columns collect: [ :each | each title ].
	#( 'Of' 'Edges' 'Aliased' 'Swept' 'Centre inside' ) do: [ :each |
		self assert: (titles includes: each) ].
	presenter items do: [ :item |
		presenter columns do: [ :column | column evaluation value: item ] ].
	self assert: (presenter items first at: 2) equals: 'Fill'.
	self
		assert: (presenter items select: [ :each | each at: 5 ]) size
		equals: presenter items size
]

{ #category : 'tests - walking' }
VGTiledClipTest >> testTheWalkOfAPixelMatchesTheRasteriserInsideAnAliasedClipShape [
	"An aliased clip shape answers whole pixels and the same ones on every sub-row, so it is
	 asked about the centre of a pixel and then leaves the window of that pixel alone. The fill
	 stays antialiased, so the two modes meet in one walk."

	| entry |
	entry := self entryClippedBy: self clippedFrameInAnAliasedShape.
	self assert: entry clip shapes first isAliased.
	self deny: entry segments isAliased.
	self
		assert: (self largestCoverageComparedWithTheRasteriserFor: entry)
		equals: 1.0
]

{ #category : 'tests - walking' }
VGTiledClipTest >> testTheWalkOfAPixelMatchesTheRasteriserInsideAnEvenOddClipShape [
	"Each shape is walked by its own fill rule: the clip here is even-odd and the fill is wound,
	 so a walk that read one rule for both would paint the lens the clip excludes."

	| entry |
	entry := self entryClippedBy: self clippedFrameInAnEvenOddShape.
	self assert: entry clip shapes first fillRule equals: #evenOdd.
	self assert: entry segments fillRule equals: #winding.
	self
		assert: (self largestCoverageComparedWithTheRasteriserFor: entry)
		equals: 1.0
]

{ #category : 'tests - walking' }
VGTiledClipTest >> testTheWalkOfAPixelMatchesTheRasteriserInsideOneClipShape [
	"The clip the corpus holds: a fill that reaches outside a circular clip. The walk has to meet
	 the spans of the clip shape on the same sub-row it samples the fill on."

	| entry |
	entry := self entryClippedBy: self clippedFrame.
	self deny: entry clip isRectangular.
	self
		assert: (self largestCoverageComparedWithTheRasteriserFor: entry)
		equals: 1.0
]

{ #category : 'tests - walking' }
VGTiledClipTest >> testTheWalkOfAPixelMatchesTheRasteriserInsideTwoClipShapes [
	"Two shapes at once. A piece of a span survives where every shape lets it through, so the walk
	 meets the second shape with what the first left of it and never multiplies one coverage by
	 another."

	| entry |
	entry := self entryClippedBy: self clippedFrameOfTwoShapes.
	self assert: entry clip shapes size equals: 2.
	self
		assert: (self largestCoverageComparedWithTheRasteriserFor: entry)
		equals: 1.0
]
