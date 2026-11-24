"
I am one frame of VGInteriorQuestionBudget: a census row, which says which questions reach which
stage, and the microseconds of every loop over every pass.

#floorOf: answers the fastest pass of one stage, #wholeFloor the fastest pass of the whole
predicate, and #loopFloor the fastest pass of the bare loop. A stage's own cost is its figure
less the loop's, and how far the whole predicate sits over the sum of its stages is what the
sends and the descent around them cost.
"
Class {
	#name : 'VGInteriorQuestionBudgetRow',
	#superclass : 'Object',
	#instVars : [
		'census',
		'microseconds',
		'tests'
	],
	#category : 'VectorGraphics-Benchmarks-Tiles',
	#package : 'VectorGraphics-Benchmarks',
	#tag : 'Tiles'
}

{ #category : 'instance creation' }
VGInteriorQuestionBudgetRow class >> frameNamed: aSymbol extent: anExtent [
	"A row over that frame, counted before anything is timed: the census says which questions
	 reach which stage, and a pass of mine times each stage over exactly those."
	^ self new
		  setCensus:
			  (VGInteriorQuestionCensusRow frameNamed: aSymbol extent: anExtent);
		  yourself
]

{ #category : 'stages' }
VGInteriorQuestionBudgetRow class >> loopStage [
	"The loop and nothing else: the same pairs walked, each asked for its entry and its
	 rectangle, with no test of the predicate run. Every other figure of a row stands over this
	 one, because every other figure pays it too."
	^ #loop
]

{ #category : 'stages' }
VGInteriorQuestionBudgetRow class >> measuredStages [
	"Every loop a pass times: the stages of the predicate, the whole predicate, and the loop
	 that runs no test at all."
	^ self timedStages , { self wholeStage . self loopStage }
]

{ #category : 'stages' }
VGInteriorQuestionBudgetRow class >> timedStages [
	"Every stage the census counts except covered, which is where a question comes out rather
	 than a test it pays for."
	^ VGInteriorQuestionCensusRow stageNames copyWithout:
		  VGInteriorQuestionCensusRow coveredStage
]

{ #category : 'stages' }
VGInteriorQuestionBudgetRow class >> wholeStage [
	"The whole predicate over every question asked, which is the figure unit 3.12 measured at
	 4.313 ms on the reference frame."
	^ #whole
]

{ #category : 'accessing' }
VGInteriorQuestionBudgetRow >> census [
	"The counts my figures are read against: a stage's microseconds say nothing without the number of questions behind them."
	^ census
]

{ #category : 'measuring' }
VGInteriorQuestionBudgetRow >> clipBoundsTest [
	"The first test of the predicate: whether the clip's own bounding rectangle holds the asked one."
	^ [ :pair | pair key clip bounds containsRect: pair value ]
]

{ #category : 'measuring' }
VGInteriorQuestionBudgetRow >> clipShapeTest [
	"The same predicate again, on every shape the clip was cut out by: a rectangular clip is folded into the clip's bounds by VGClip >> clippedBy:, so a shape here is a real outline."
	^ [ :pair | pair key clip shapes allSatisfy: [ :shape | shape enclosesWholly: pair value ] ]
]

{ #category : 'accessing' }
VGInteriorQuestionBudgetRow >> extent [
	"The extent the frame was binned at, which sets the grid and so the number of questions."
	^ census extent
]

{ #category : 'accessing' }
VGInteriorQuestionBudgetRow >> floorOf: aStage [
	"The fastest pass of that loop, in microseconds. A floor and never a mean: every other
	 reading of the same loop holds work the machine was doing for someone else."
	^ (microseconds at: aStage) detectMin: [ :each | each ]
]

{ #category : 'accessing' }
VGInteriorQuestionBudgetRow >> frame [
	"Which frame of VGFrameDeviceBenchmark I time."
	^ census frame
]

{ #category : 'inspector' }
VGInteriorQuestionBudgetRow >> inspectorFloors: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Floors'>
	"What each loop of my frame walked and the fastest pass of it, every line read from the
	 report so the tab cannot show a figure I did not measure."
	^ aBuilder newTable
		  items: self reportRows;
		  addColumn:
			  (SpStringTableColumn title: 'Loop' evaluated: [ :each | each key ]);
		  addColumn:
			  (SpStringTableColumn title: 'Floor' evaluated: [ :each |
					   each value ]);
		  yourself
]

{ #category : 'inspector' }
VGInteriorQuestionBudgetRow >> inspectorFloorsContext: aContext [
	"A row no pass has walked has no floor to show."
	aContext active:
		(census notNil and: [
			 (microseconds at: self class wholeStage) notEmpty ])
]

{ #category : 'accessing' }
VGInteriorQuestionBudgetRow >> loopFloor [
	"The fastest pass of the loop that runs no test, which every other figure here stands over."
	^ self floorOf: self class loopStage
]

{ #category : 'measuring' }
VGInteriorQuestionBudgetRow >> loopTest [
	"No test at all: the pair is asked for its two halves, which every other loop here pays too."
	^ [ :pair | pair key. pair value ]
]

{ #category : 'measuring' }
VGInteriorQuestionBudgetRow >> measurePass: anIndex [
	"Every loop once, in an order that turns over with the pass, so no stage is always the one
	 measured on the heap the stage before it had just grown."
	| order |
	order := anIndex odd
		         ifTrue: [ self class measuredStages ]
		         ifFalse: [ self class measuredStages reversed ].
	order do: [ :stage |
		| pairs test start |
		pairs := self pairsOf: stage.
		test := self testsByStage at: stage.
		start := Time microsecondClockValue.
		pairs do: [ :pair | test value: pair ].
		(microseconds at: stage) add: Time microsecondClockValue - start ]
]

{ #category : 'measuring' }
VGInteriorQuestionBudgetRow >> noShapeTest [
	"The flat refusal of an entry that is not a fill, which is one send and reads no geometry."
	^ [ :pair | pair key coversEveryPixelOf: pair value ]
]

{ #category : 'accessing' }
VGInteriorQuestionBudgetRow >> pairCountOf: aStage [
	"How many questions one loop of mine walks."
	^ (self pairsOf: aStage) size
]

{ #category : 'measuring' }
VGInteriorQuestionBudgetRow >> pairsOf: aStage [
	"The pairs one loop walks: for a stage of the predicate, the questions the census says
	 reach it; for the whole predicate and for the bare loop, every question asked."
	^ (self class timedStages includes: aStage)
		  ifTrue: [ census pairsReaching: aStage ]
		  ifFalse: [ census askedPairs ]
]

{ #category : 'accessing' }
VGInteriorQuestionBudgetRow >> reportRows [
	"My figures as lines of a two-column table: how many questions each loop walked and the
	 fastest pass of it, in microseconds, the bare loop last so a reader can take it off every
	 line above."
	^ (self class measuredStages collect: [ :stage |
		   stage
		   ->
		   ((self pairCountOf: stage) printString , ' questions, '
		    , (self floorOf: stage) printString , ' us') ])
		  asOrderedCollection
		  addFirst:
			  'frame' -> (self frame asString , ' at ' , self extent printString);
		  yourself
]

{ #category : 'initialization' }
VGInteriorQuestionBudgetRow >> setCensus: aCensusRow [
	census := aCensusRow.
	microseconds := Dictionary new.
	self class measuredStages do: [ :stage |
		microseconds at: stage put: OrderedCollection new ]
]

{ #category : 'measuring' }
VGInteriorQuestionBudgetRow >> shapeBoxTest [
	"Whether the exact bounding box of the fill's edges holds the asked rectangle. The box is remembered by the scanner, so what is timed here is the test and not the box."
	^ [ :pair | | box | box := pair key segments scanner exactBoundingBox. box notNil and: [ box containsRect: pair value ] ]
]

{ #category : 'measuring' }
VGInteriorQuestionBudgetRow >> shapeEdgeTest [
	"Whether an edge of the fill meets the asked rectangle, which reads the cells of the edge index the rectangle covers."
	^ [ :pair | pair key segments scanner anEdgeMeets: pair value ]
]

{ #category : 'measuring' }
VGInteriorQuestionBudgetRow >> shapeWalkTest [
	"The fill rule at the centre of the asked rectangle, which is the one point left to ask once no edge meets it."
	^ [ :pair | pair key segments scanner isInsideAt: pair value center ]
]

{ #category : 'measuring' }
VGInteriorQuestionBudgetRow >> testsByStage [
	"The one test of each loop, each over a pair the census handed me. Built once: a pass looks up a test before it starts the clock, so the lookup is not in the figure."
	^ tests ifNil: [ tests := Dictionary newFrom: {
		(VGInteriorQuestionCensusRow noShapeStage -> self noShapeTest).
		(VGInteriorQuestionCensusRow clipBoundsStage -> self clipBoundsTest).
		(VGInteriorQuestionCensusRow shapeBoxStage -> self shapeBoxTest).
		(VGInteriorQuestionCensusRow shapeEdgeStage -> self shapeEdgeTest).
		(VGInteriorQuestionCensusRow shapeWalkStage -> self shapeWalkTest).
		(VGInteriorQuestionCensusRow clipShapeStage -> self clipShapeTest).
		(self class wholeStage -> self wholeTest).
		(self class loopStage -> self loopTest) } ]
]

{ #category : 'accessing' }
VGInteriorQuestionBudgetRow >> wholeFloor [
	"The fastest pass of the whole predicate over every question asked, which is the figure a binning really pays."
	^ self floorOf: self class wholeStage
]

{ #category : 'measuring' }
VGInteriorQuestionBudgetRow >> wholeTest [
	"The predicate a binning really sends, every stage a question reaches included."
	^ [ :pair | pair key coversEveryPixelOf: pair value ]
]
