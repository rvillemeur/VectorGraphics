"
I hold the census of the interior questions a binning asks.

Unit 3.14 goes after the interior phase of a binning, which unit 3.12 left at 4.313 ms and seven
tenths of the whole binning. My tests count: how many questions a frame asks, at the super tile
level and at the tile level, where each question stopped, and that what the census says of a pair
agrees with what the entry itself answers. None of them reads a clock; VGInteriorQuestionBudget is
what times the stages apart.
"
Class {
	#name : 'VGInteriorQuestionCensusTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Vulkan-Tests-Tests',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
VGInteriorQuestionCensusTest >> testEveryQuestionIsCountedAtExactlyOneStage [
	"The stages are where a question stopped, so they partition the questions: every question
	 asked, at either level, is counted at one stage and no question is counted twice."
	VGFrameDeviceBenchmark frameNames do: [ :name |
		VGFrameDeviceBenchmark extentsOfItsCensus do: [ :extent |
			| row |
			row := VGInteriorQuestionCensus overFrameNamed: name extent: extent.
			self
				assert: (VGInteriorQuestionCensusRow stageNames inject: 0 into: [
							 :sum :stage | sum + (row stageCount: stage) ])
				equals: row superTileQuestions + row tileQuestions ] ]
]

{ #category : 'tests' }
VGInteriorQuestionCensusTest >> testOnlyTheReferenceFrameAsksABlitAnything [
	"The glyphs of the labels are the blits of this project, and only the reference frame draws
	 them. Their questions are the ones no lever can make cheaper than a send, so a reading of
	 the reference frame's cost has to put them aside first."
	| rowsByFrame |
	rowsByFrame := VGInteriorQuestionCensus new rows select: [ :each |
		               each extent
		               = VGFrameDeviceBenchmark extentOfItsFrames ].
	rowsByFrame do: [ :row |
		row frame = #reference
			ifTrue: [ self assert: (row stageCount: #noShape) > 0 ]
			ifFalse: [ self assert: (row stageCount: #noShape) equals: 0 ] ]
]

{ #category : 'tests' }
VGInteriorQuestionCensusTest >> testTheBackgroundFrameLosesOnlyThePerimeterSuperTiles [
	"The background frame is one fill of the whole picture, so it is asked about every super
	 tile of the grid and covers whole every super tile that lies inside the picture. The
	 perimeter is refused: the fill's own edges run along the boundary of the picture, and an
	 edge that so much as touches a rectangle answers no, which is the conservative answer
	 VGSpanScanner >> enclosesWholly: promises. So the tiles of those super tiles, and no
	 others, are asked one by one."
	| extent grid row |
	extent := VGFrameDeviceBenchmark extentOfItsFrames.
	grid := VGTileGrid extent: extent.
	row := VGInteriorQuestionCensus overFrameNamed: #background extent: extent.
	self assert: row superTileQuestions equals: grid superTileCount.
	self
		assert: row superTileRefusals
		equals:
		grid superTileCount - (grid superTileColumns - 2 * (grid superTileRows - 2)).
	self assert: row tileQuestions > 0
]

{ #category : 'tests' }
VGInteriorQuestionCensusTest >> testTheBackgroundFrameStopsAtTwoStagesOnly [
	"One fill of the whole picture, with a rectangular clip and no clip shape: so no question
	 of that frame is refused by a clip, by a bounding box or by the fill rule. Every question
	 either meets an edge of the picture's own boundary or is covered whole, which says that a
	 lever aimed at the walk would do nothing for this frame and a lever aimed at the edge test
	 would do all of it."
	| row |
	row := VGInteriorQuestionCensus
		       overFrameNamed: #background
		       extent: VGFrameDeviceBenchmark extentOfItsFrames.
	self assert: (row stageCount: #shapeEdge) > 0.
	self assert: (row stageCount: #covered) > 0.
	#( #noShape #clipBounds #shapeBox #shapeWalk #clipShape ) do: [ :stage |
		self assert: (row stageCount: stage) equals: 0 ]
]

{ #category : 'tests' }
VGInteriorQuestionCensusTest >> testTheCensusHoldsOneRowPerFrameAndExtent [
	"The census is the whole table: every frame of the budget at every extent it is counted at,
	 in that order, so a reader compares a frame with itself at the other extent."
	| census |
	census := VGInteriorQuestionCensus new.
	self
		assert: (census rows collect: [ :each | each frame -> each extent ])
		equals: (VGFrameDeviceBenchmark frameNames flatCollect: [ :name |
				 VGFrameDeviceBenchmark extentsOfItsCensus collect: [ :extent |
					 name -> extent ] ])
]

{ #category : 'tests' }
VGInteriorQuestionCensusTest >> testTheMarksTheCensusCountsAreTheMarksTheBinningWrites [
	"The census walks the descent from outside the binning, so nothing holds it to the rule the
	 binning applies except this: every pair the census reads as covered whole is a pair the
	 binning marks interior, on every frame of the budget and at both extents. The numbers
	 themselves are unit 3.12's, 2208 on the reference and the cards frames and 1728 on the
	 background frame."
	VGFrameDeviceBenchmark frameNames do: [ :name |
		VGFrameDeviceBenchmark extentsOfItsCensus do: [ :extent |
			| row binning |
			row := VGInteriorQuestionCensus overFrameNamed: name extent: extent.
			binning := VGTileBinning
				           of: (VGInteriorQuestionCensusRow
						            displayListOfFrameNamed: name
						            extent: extent)
				           grid: (VGTileGrid extent: extent).
			self assert: row interiorMarks equals: binning interiorReferenceCount ] ]
]
