"
What a frame's recording counts. The census of unit 3.13 counts the entries a frame records, the geometry and the pixels they carry, and the paints and clips built for them, so the verdict on where the recording time goes names a count and not a guess. The counts of a hand-built frame are exact here; the counts of the project's reference scene are held to their shape only, because that scene belongs to VGFrameProfile and changes with it.
"
Class {
	#name : 'VGFrameRecordCensusTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Vulkan-Tests-Tests',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Tests'
}

{ #category : 'building' }
VGFrameRecordCensusTest >> censusOfExtent: aPoint drawnWith: aBlock [
	"The census of the frame that block draws on a surface of that extent. A census reads the
	 display list and nothing else, so no device and no kit are involved."
	| surface |
	surface := VGCairoImageSurface extent: aPoint.
	aBlock value: surface newContext.
	^ VGFrameRecordCensus
		  overTheDisplayList: surface displayList
		  named: #hand
		  extent: aPoint
]

{ #category : 'building' }
VGFrameRecordCensusTest >> censusOfTheReferenceFrameWithout: aSymbolOrNil [
	"The census of the reference frame drawn with one of its parts left out, which is the
	 variant unit 3.13 subtracts."
	| kit surface |
	kit := VGFrameDrawingKit ours.
	surface := kit surfaceOfExtent: VGFrameDeviceBenchmark extentOfItsFrames.
	VGFrameDeviceBenchmark
		drawReferenceOn: surface newContext
		using: kit
		recordingInto: nil
		without: aSymbolOrNil.
	^ VGFrameRecordCensus
		  overTheDisplayList: surface displayList
		  named: #reference
		  extent: VGFrameDeviceBenchmark extentOfItsFrames
]

{ #category : 'building' }
VGFrameRecordCensusTest >> maskSurfaceOfExtent: aPoint [
	"A small mask surface, which is the shape a glyph arrives in. Its content does not matter
	 to a census: what is counted is that it exists and how many pixels it carries."
	| mask context |
	mask := VGCairoImageSurface extent: aPoint.
	context := mask newContext.
	context clearTransparent.
	context sourceColorR: 1.0 g: 1.0 b: 1.0 a: 1.0.
	context rectangleX: 0 y: 0 width: aPoint x height: aPoint y.
	context fill.
	mask flush.
	^ mask
]

{ #category : 'tests' }
VGFrameRecordCensusTest >> testAFrameThatRecordsNothingIsCountedAsNoughtAndNotNil [
	"The degenerate frame. A context asked to draw nothing records no entry, so every count of
	 the census is nought rather than nil: a census of such a frame is a report and not a
	 failure, and its rows still print."
	| row |
	row := (self censusOfExtent: 64 @ 64 drawnWith: [ :context | ]) rows first.
	self assert: row fills equals: 0.
	self assert: row blits equals: 0.
	self assert: row segments equals: 0.
	self assert: row coordinates equals: 0.
	self assert: row blitPixels equals: 0.
	self assert: row distinctBlitSurfaces equals: 0.
	self assert: row distinctPaints equals: 0.
	self assert: row distinctClips equals: 0.
	self assert: row name equals: #hand.
	self assert: row extent equals: 64 @ 64
]

{ #category : 'tests' }
VGFrameRecordCensusTest >> testARowPrintsItsFrameItsExtentAndWhatItRecorded [
	"A row read in an inspector or a debugger says which frame it is and what it counted,
	 since a census of six rows is read as a list of them."
	| row printed |
	row := (self
		        censusOfExtent: 64 @ 64
		        drawnWith: [ :context |
			        context
				        sourceColor: Color red;
				        rectangleX: 4 y: 4 width: 20 height: 10;
				        fill ]) rows first.
	printed := row printString.
	self assert: (printed includesSubstring: 'hand').
	self assert: (printed includesSubstring: '64').
	self assert: (printed includesSubstring: '1 entries' )
]

{ #category : 'tests' }
VGFrameRecordCensusTest >> testEveryRowCountsAsManyEntriesAsItsKindsTogether [
	"The counts of a row cannot drift from the frame they were read off: the entries of a row
	 are its fills and its blits and nothing else, and a frame of the budget records some."
	| census |
	census := VGFrameRecordCensus overItsFrames.
	census rows do: [ :row |
		self assert: row entries equals: row fills + row blits.
		self assert: row entries > 0 ]
]

{ #category : 'tests' }
VGFrameRecordCensusTest >> testTheBusiestRowIsTheFrameThatRecordsTheMostEntries [
	"The report speaks about one row above the others: the frame that records most, which is
	 the frame the verdict of unit 3.13 is about. It is found by counting and not named, so a
	 budget whose frames change still reports the right one."
	| census busiest |
	census := VGFrameRecordCensus overItsFrames.
	busiest := census busiestRow.
	census rows do: [ :row | self assert: busiest entries >= row entries ].
	self deny: census reportRows isEmpty
]

{ #category : 'tests' }
VGFrameRecordCensusTest >> testTheCensusCoversEveryFrameOfTheBudgetAtEveryExtentItIsMeasuredAt [
	"One row per frame and extent, and the frames and the extents are the budget's own lists
	 rather than lists of mine: a frame added to the budget is censused without this class
	 being touched."
	| census names extents |
	census := VGFrameRecordCensus overItsFrames.
	names := VGFrameDeviceBenchmark frameNames.
	extents := VGFrameDeviceBenchmark extentsOfItsCensus.
	self assert: census rows size equals: names size * extents size.
	names do: [ :each |
		extents do: [ :extent |
			self assert: (census rows anySatisfy: [ :row |
					 row name = each and: [ row extent = extent ] ]) ] ]
]

{ #category : 'tests' }
VGFrameRecordCensusTest >> testTheCensusOfOneBlittedMaskCountsItsSurfaceAndItsPixels [
	"A blit is not geometry: it carries a mask surface and that surface's pixels, and no edge
	 and no coordinate at all. The same mask blitted twice is one distinct surface, which is
	 what the glyph atlas is for."
	| mask row |
	mask := self maskSurfaceOfExtent: 21 @ 18.
	row := (self
		        censusOfExtent: 64 @ 64
		        drawnWith: [ :context |
			        context
				        sourceColorR: 0.2
				        g: 0.4
				        b: 0.9
				        a: 1.0.
			        context recordBlitOf: mask at: 7 @ 5.
			        context recordBlitOf: mask at: 30 @ 5 ]) rows first.
	self assert: row blits equals: 2.
	self assert: row fills equals: 0.
	self assert: row segments equals: 0.
	self assert: row coordinates equals: 0.
	self assert: row blitPixels equals: 756.
	self assert: row distinctBlitSurfaces equals: 1
]

{ #category : 'tests' }
VGFrameRecordCensusTest >> testTheCensusOfOneFilledRectangleCountsOneFillAndItsCoordinates [
	"The smallest frame that records anything. One filled rectangle is one fill entry of four
	 edges and sixteen coordinates, with one paint and one clip built for it, and no blit at
	 all."
	| row |
	row := (self
		        censusOfExtent: 64 @ 64
		        drawnWith: [ :context |
			        context
				        sourceColor: Color red;
				        rectangleX: 4 y: 4 width: 20 height: 10;
				        fill ]) rows first.
	self assert: row fills equals: 1.
	self assert: row blits equals: 0.
	self assert: row segments equals: 4.
	self assert: row coordinates equals: 16.
	self assert: row distinctPaints equals: 1.
	self assert: row distinctClips equals: 1
]

{ #category : 'tests' }
VGFrameRecordCensusTest >> testTheReferenceFrameWithoutItsBorderLosesAlmostEveryEdge [
	"Where the geometry of the frame is. Twelve of the twenty-five fills are the stroked
	 borders of the cards, and they carry all but a handful of the edges: the fills that remain
	 are rectangles of four edges each. The strokes, not the rounded corners and not the
	 glyphs, are what the recording of this frame is mostly made of."
	| whole stripped |
	whole := (self censusOfTheReferenceFrameWithout: nil) rows first.
	stripped := (self censusOfTheReferenceFrameWithout: #border) rows first.
	self assert: stripped blits equals: whole blits.
	self assert: stripped fills < whole fills.
	self assert: stripped segments * 10 < whole segments.
	self
		assert: stripped segments
		equals: stripped fills * VGFrameRecordCensusRow edgesOfARectangle
]

{ #category : 'tests' }
VGFrameRecordCensusTest >> testTheReferenceFrameWithoutItsCardsRecordsTheBackgroundAlone [
	"The floor of the variants, and the one that prices everything the cards bring together:
	 one fill of four edges, no blit, one paint and one clip."
	| stripped |
	stripped := (self censusOfTheReferenceFrameWithout: #cards) rows first.
	self assert: stripped entries equals: 1.
	self assert: stripped fills equals: 1.
	self assert: stripped blits equals: 0.
	self
		assert: stripped segments
		equals: VGFrameRecordCensusRow edgesOfARectangle.
	self assert: stripped distinctPaints equals: 1.
	self assert: stripped distinctClips equals: 1
]

{ #category : 'tests' }
VGFrameRecordCensusTest >> testTheReferenceFrameWithoutItsGradientRecordsTheSameGeometry [
	"A gradient is a paint and not a shape, so leaving it out changes nothing that is counted.
	 The variant is measured all the same: what it prices is the per-pixel cost of reading a
	 gradient, which no census can see."
	| whole stripped |
	whole := (self censusOfTheReferenceFrameWithout: nil) rows first.
	stripped := (self censusOfTheReferenceFrameWithout: #gradient) rows first.
	self assert: stripped entries equals: whole entries.
	self assert: stripped segments equals: whole segments.
	self assert: stripped blitPixels equals: whole blitPixels
]

{ #category : 'tests' }
VGFrameRecordCensusTest >> testTheReferenceFrameWithoutItsLabelsRecordsItsFillsAndNoBlit [
	"The variant subtracted to price the glyphs records the same fills as the whole frame and
	 not one blit. It does not record the same geometry: a card clips its children, so a card
	 with no label pushes no clip, and its rounded rectangle is then recorded whole instead of
	 trimmed. The subtraction therefore prices the glyphs together with the clips they bring,
	 which is what the verdict of unit 3.13 has to say rather than hide."
	| whole stripped |
	whole := (self censusOfTheReferenceFrameWithout: nil) rows first.
	stripped := (self censusOfTheReferenceFrameWithout: #labels) rows first.
	self assert: whole blits > 0.
	self assert: stripped blits equals: 0.
	self assert: stripped fills equals: whole fills.
	self assert: stripped distinctClips equals: 1.
	self assert: stripped segments > whole segments
]
