"
I count the interior questions one frame of the budget asks, at one extent.

A binning asks of every (entry, tile) pair whether the entry covers every pixel of the tile, and
since unit 3.12 it asks that of a super tile of sixteen tiles before it asks the tiles inside it.
I walk the same descent from outside the binning and count the questions it asks, so that unit
3.14 knows how many there are before it tries to make them cheaper. I read no clock:
VGInteriorQuestionBudget is what times the stages of one question apart.
"
Class {
	#name : 'VGInteriorQuestionCensusRow',
	#superclass : 'Object',
	#instVars : [
		'frame',
		'extent',
		'grid',
		'superTileQuestions',
		'superTileRefusals',
		'tileQuestions',
		'interiorMarks',
		'stages',
		'pairsReaching'
	],
	#category : 'VectorGraphics-Benchmarks-Tiles',
	#package : 'VectorGraphics-Benchmarks',
	#tag : 'Tiles'
}

{ #category : 'stages' }
VGInteriorQuestionCensusRow class >> clipBoundsStage [
	"Stopped at the clip's own bounding rectangle, the first and cheapest refusal of the predicate."
	^ #clipBounds
]

{ #category : 'stages' }
VGInteriorQuestionCensusRow class >> clipShapeStage [
	"The fill encloses the rectangle whole but a shape the clip was cut out by does not, so the whole predicate was paid twice over."
	^ #clipShape
]

{ #category : 'stages' }
VGInteriorQuestionCensusRow class >> coveredStage [
	"Every test passed: the rectangle is covered whole, which is the mark a binning writes and the walk the device is spared."
	^ #covered
]

{ #category : 'frames' }
VGInteriorQuestionCensusRow class >> displayListOfFrameNamed: aSymbol extent: anExtent [
	"The display list of that frame of the budget at that extent, recorded through this
	 project's own classes, which is what a binning of a running tool is handed. It is on the
	 class side because a test binning the same frame has to be handed the same list."
	| kit surface |
	kit := VGFrameDrawingKit ours.
	surface := kit surfaceOfExtent: anExtent.
	(VGFrameDeviceBenchmark drawBlockNamed: aSymbol using: kit) value:
		surface newContext.
	^ surface displayList
]

{ #category : 'instance creation' }
VGInteriorQuestionCensusRow class >> frameNamed: aSymbol extent: anExtent [
	"The counts of that frame of the budget, drawn and binned at that extent."
	^ self new
		  setFrame: aSymbol extent: anExtent;
		  count;
		  yourself
]

{ #category : 'stages' }
VGInteriorQuestionCensusRow class >> noShapeStage [
	"The question an entry with no geometry is asked: a blit answers no to every rectangle without looking at it, so its questions cost one send each and no lever can touch them."
	^ #noShape
]

{ #category : 'stages' }
VGInteriorQuestionCensusRow class >> shapeBoxStage [
	"Stopped at the exact bounding box of the fill's edges, which is remembered per scanner."
	^ #shapeBox
]

{ #category : 'stages' }
VGInteriorQuestionCensusRow class >> shapeEdgeStage [
	"Stopped because an edge of the fill meets the rectangle, which is the conservative answer and the test that reads every edge of the index the rectangle reaches."
	^ #shapeEdge
]

{ #category : 'stages' }
VGInteriorQuestionCensusRow class >> shapeWalkStage [
	"Walked to the fill rule at the rectangle's centre and was answered no: the rectangle lies in a hole of the shape."
	^ #shapeWalk
]

{ #category : 'stages' }
VGInteriorQuestionCensusRow class >> stageNames [
	"Every stage a question can stop at, in the order the predicate reaches them. They partition the questions asked, which is what VGInteriorQuestionCensusTest holds them to."
	^ { self noShapeStage . self clipBoundsStage . self shapeBoxStage . self shapeEdgeStage . self shapeWalkStage . self clipShapeStage . self coveredStage }
]

{ #category : 'accessing' }
VGInteriorQuestionCensusRow >> askedPairs [
	"Every (entry, rectangle) pair the binning of my frame asks about. A question of a blit
	 pays the flat refusal and nothing else, and a question of a fill pays the clip's bounding
	 rectangle first, so those two stages together hold each question exactly once."
	^ (self pairsReaching: self class noShapeStage)
	  , (self pairsReaching: self class clipBoundsStage)
]

{ #category : 'counting' }
VGInteriorQuestionCensusRow >> count [
	"Walk the descent VGTileBinning walks, over every entry of my frame. Which kind of entry it
	 is comes back by double dispatch, as it does for the recording census, so no test of a
	 class is written here."
	self displayList entries do: [ :entry | entry countedBy: self ]
]

{ #category : 'counting' }
VGInteriorQuestionCensusRow >> countBlit: anEntry [
	"A blit is pixels: VGDisplayListEntry >> coversEveryPixelOf: answers no flat, whatever the
	 rectangle, so a question it is asked pays one stage and reaches no geometry."
	self
		countEntry: anEntry
		stagedBy: [ :rectangle |
			Array with: self class noShapeStage ]
]

{ #category : 'counting' }
VGInteriorQuestionCensusRow >> countEntry: anEntry stagedBy: aBlock [
	"The descent of VGTileBinning >> bin:at:inSuperTileAt:of:, with that block asked for the
	 stages each question paid, the one it stopped at last. A super tile covered whole marks
	 every tile of it with no question of its own, which is the gain unit 3.12 built and the
	 reason a tile question is counted apart from a super tile one."
	| box |
	box := anEntry boundingBox.
	(grid superTileIndexesIntersecting: box) do: [ :superIndex |
		| superBounds tileIndexes |
		superBounds := grid boundsOfSuperTileAt: superIndex.
		tileIndexes := grid indexesIntersecting: (box intersect: superBounds).
		superTileQuestions := superTileQuestions + 1.
		(self tally: (aBlock value: superBounds) of: anEntry -> superBounds)
			ifTrue: [ interiorMarks := interiorMarks + tileIndexes size ]
			ifFalse: [
				superTileRefusals := superTileRefusals + 1.
				tileIndexes do: [ :index |
					| tileBounds |
					tileBounds := grid boundsOfTileAt: index.
					tileQuestions := tileQuestions + 1.
					(self
						 tally: (aBlock value: tileBounds)
						 of: anEntry -> tileBounds) ifTrue: [
						interiorMarks := interiorMarks + 1 ] ] ] ]
]

{ #category : 'counting' }
VGInteriorQuestionCensusRow >> countFill: anEntry [
	"A fill is geometry, so every question it is asked walks the predicate and stops somewhere
	 inside it."
	self
		countEntry: anEntry
		stagedBy: [ :rectangle | self stagesOfFill: anEntry over: rectangle ]
]

{ #category : 'counting' }
VGInteriorQuestionCensusRow >> displayList [
	"The display list of my frame at my extent."
	^ self class displayListOfFrameNamed: frame extent: extent
]

{ #category : 'accessing' }
VGInteriorQuestionCensusRow >> extent [
	"The surface extent my frame was drawn and binned at."
	^ extent
]

{ #category : 'accessing' }
VGInteriorQuestionCensusRow >> frame [
	"The name of the frame I counted."
	^ frame
]

{ #category : 'inspector' }
VGInteriorQuestionCensusRow >> inspectorCounts: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Counts'>
	"What the binning of my frame asks and marks, and where each question stopped, every line
	 read from the report so the tab cannot show a count I did not take."
	^ aBuilder newTable
		  items: self reportRows;
		  addColumn:
			  (SpStringTableColumn title: 'Count' evaluated: [ :each | each key ]);
		  addColumn:
			  (SpStringTableColumn title: 'Value' evaluated: [ :each |
					   each value ]);
		  yourself
]

{ #category : 'inspector' }
VGInteriorQuestionCensusRow >> inspectorCountsContext: aContext [
	"A row built on no frame has counted nothing."
	aContext active: frame isNotNil
]

{ #category : 'accessing' }
VGInteriorQuestionCensusRow >> interiorMarks [
	"How many (entry, tile) pairs of my frame were read as covered whole, which is what a
	 binning writes beside the ordinal so the device walks no coverage there."
	^ interiorMarks
]

{ #category : 'accessing' }
VGInteriorQuestionCensusRow >> pairsReaching: aStage [
	"The (entry, rectangle) pairs of my frame that paid the test of that stage, which is what
	 VGInteriorQuestionBudget times: a stage is paid by every question that gets to it, not
	 only by the ones it refuses."
	^ (pairsReaching at: aStage) asArray
]

{ #category : 'inspector' }
VGInteriorQuestionCensusRow >> reportRows [
	"My counts as lines of a two-column table: what was asked, what was marked, and then one
	 line per stage, read from the predicate's own order."
	^ (OrderedCollection new
		   add: 'super tiles asked' -> superTileQuestions;
		   add: 'super tiles refused' -> superTileRefusals;
		   add: 'tiles asked' -> tileQuestions;
		   add: 'tiles marked interior' -> interiorMarks;
		   yourself)
		  addAll: (self class stageNames collect: [ :stage |
					   stage -> (self stageCount: stage) ]);
		  yourself
]

{ #category : 'initialization' }
VGInteriorQuestionCensusRow >> setFrame: aSymbol extent: anExtent [
	frame := aSymbol.
	extent := anExtent.
	grid := VGTileGrid extent: anExtent.
	superTileQuestions := 0.
	superTileRefusals := 0.
	tileQuestions := 0.
	interiorMarks := 0.
	stages := Dictionary new.
	pairsReaching := Dictionary new.
	self class stageNames do: [ :stage |
		stages at: stage put: 0.
		pairsReaching at: stage put: OrderedCollection new ]
]

{ #category : 'accessing' }
VGInteriorQuestionCensusRow >> stageCount: aStage [
	"How many questions of my frame stopped at that stage of the predicate."
	^ stages at: aStage
]

{ #category : 'counting' }
VGInteriorQuestionCensusRow >> stagesOfFill: anEntry over: aRectangle [
	"The stages the predicate of that fill pays on that rectangle, the one it stops at last.
	 Every test here is the one VGFillEntry >> coversEveryPixelOf: and
	 VGSpanScanner >> enclosesWholly: send, in their order, so the census stays an account of
	 the real descent and not a second rule: an agreement test holds the verdict it reads to
	 coversEveryPixelOf: itself."
	| paid scanner box |
	paid := OrderedCollection with: self class clipBoundsStage.
	(anEntry clip bounds containsRect: aRectangle) ifFalse: [ ^ paid ].
	paid add: self class shapeBoxStage.
	scanner := anEntry segments scanner.
	box := scanner exactBoundingBox.
	(box notNil and: [ box containsRect: aRectangle ]) ifFalse: [ ^ paid ].
	paid add: self class shapeEdgeStage.
	(scanner anEdgeMeets: aRectangle) ifTrue: [ ^ paid ].
	paid add: self class shapeWalkStage.
	(scanner isInsideAt: aRectangle center) ifFalse: [ ^ paid ].
	paid add: self class clipShapeStage.
	anEntry clip shapes do: [ :shape |
		(shape enclosesWholly: aRectangle) ifFalse: [ ^ paid ] ].
	^ paid
		  add: self class coveredStage;
		  yourself
]

{ #category : 'accessing' }
VGInteriorQuestionCensusRow >> superTileQuestions [
	"How often an entry of my frame was asked whether it covers a whole super tile."
	^ superTileQuestions
]

{ #category : 'accessing' }
VGInteriorQuestionCensusRow >> superTileRefusals [
	"How often a super tile answered that the entry does not cover it whole, which is what
	 sends the question down to the tiles inside it."
	^ superTileRefusals
]

{ #category : 'counting' }
VGInteriorQuestionCensusRow >> tally: aStageSequence of: aPair [
	"Count one question, which stopped at the last stage of that sequence and paid the test of
	 every stage in it. Answer whether it got as far as covered, which is the verdict the
	 binning writes."
	| stop |
	stop := aStageSequence last.
	stages at: stop put: (stages at: stop) + 1.
	aStageSequence do: [ :stage | (pairsReaching at: stage) add: aPair ].
	^ stop = self class coveredStage
]

{ #category : 'accessing' }
VGInteriorQuestionCensusRow >> tileQuestions [
	"How often an entry of my frame was asked about one tile on its own, which only happens
	 where the super tile holding it answered no."
	^ tileQuestions
]
