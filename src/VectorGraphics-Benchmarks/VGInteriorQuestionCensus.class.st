"
I count the interior question of a tile binning: of every (entry, super tile) and (entry, tile)
pair of the three frames of VGFrameDeviceBenchmark, where the question stopped inside
VGFillEntry >> coversEveryPixelOf:. I hold no clock. Unit 3.12 measured 4.313 ms of the
reference frame's binning in that predicate, seven tenths of it, and unit 3.12 also learned that
a profiler misattributes it; so the stages are counted before anything is timed, and
VGInteriorQuestionBudget times apart only the stages this table says are paid for.

Read me through #rows, one VGInteriorQuestionCensusRow per frame per extent, and ask a row
#stageCount: one of #stageNames. My rows ask the real predicate's own tests in the real
predicate's order, and an agreement test holds every verdict I read to the marks VGTileBinning
writes, so I cannot drift into being a second rule.
"
Class {
	#name : 'VGInteriorQuestionCensus',
	#superclass : 'Object',
	#instVars : [
		'rows'
	],
	#category : 'VectorGraphics-Benchmarks-Tiles',
	#package : 'VectorGraphics-Benchmarks',
	#tag : 'Tiles'
}

{ #category : 'instance creation' }
VGInteriorQuestionCensus class >> overFrameNamed: aSymbol extent: anExtent [
	"The counts of one frame at one extent, which is one row of my report."
	^ VGInteriorQuestionCensusRow frameNamed: aSymbol extent: anExtent
]

{ #category : 'inspector' }
VGInteriorQuestionCensus >> inspectorStages: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Stages'>
	"One line per frame and extent, one column per stage of the predicate. The columns are built
	 from VGInteriorQuestionCensusRow class >> stageNames, so a stage added to the predicate
	 appears here with no edit of this method."
	| table |
	table := aBuilder newTable
		         items: self rows;
		         addColumn:
			         (SpStringTableColumn title: 'Frame' evaluated: [ :each |
					          each frame ]);
		         addColumn:
			         (SpStringTableColumn title: 'Extent' evaluated: [ :each |
					          each extent printString ]);
		         addColumn:
			         (SpStringTableColumn title: 'Asked' evaluated: [ :each |
					          each superTileQuestions + each tileQuestions ]);
		         yourself.
	VGInteriorQuestionCensusRow stageNames do: [ :stage |
		table addColumn:
			(SpStringTableColumn title: stage evaluated: [ :each |
				 each stageCount: stage ]) ].
	^ table
]

{ #category : 'inspector' }
VGInteriorQuestionCensus >> inspectorStagesContext: aContext [
	"A census that has not counted yet shows nothing: counting draws six frames and walks six
	 grids, which is not work to start because a reader opened an inspector."
	aContext active: rows isNotNil
]

{ #category : 'accessing' }
VGInteriorQuestionCensus >> rows [
	"One row per frame of the budget per extent it is counted at, counted the first time they
	 are asked for: counting the six rows draws six frames and walks six grids, which is a
	 second of work a reader should pay once."
	^ rows ifNil: [
		  rows := VGFrameDeviceBenchmark frameNames flatCollect: [ :name |
			          VGFrameDeviceBenchmark extentsOfItsCensus collect: [ :extent |
				          VGInteriorQuestionCensusRow
					          frameNamed: name
					          extent: extent ] ] ]
]
