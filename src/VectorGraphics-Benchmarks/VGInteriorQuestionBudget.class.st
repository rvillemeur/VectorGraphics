"
I time the stages of the interior question apart. A row of mine times each stage of
VGFillEntry >> coversEveryPixelOf: over the questions VGInteriorQuestionCensus says reach that
stage, the whole predicate over every question asked, and a loop that runs no test at all, which
every other figure stands over.

Twenty passes a loop and the figure is the floor, never a mean. The order of the loops turns over
with the pass, so no stage is always the one measured on the heap the stage before it had just
grown.

Read me through #rows after VGInteriorQuestionBudget overTheThreeFrames. No device is opened: the
frames are drawn on the processor and the grids walked.
"
Class {
	#name : 'VGInteriorQuestionBudget',
	#superclass : 'Object',
	#instVars : [
		'passes',
		'rows'
	],
	#category : 'VectorGraphics-Benchmarks-Tiles',
	#package : 'VectorGraphics-Benchmarks',
	#tag : 'Tiles'
}

{ #category : 'accessing' }
VGInteriorQuestionBudget class >> defaultPasses [
	"Twenty passes a loop, as unit 3.13's comparison takes: nothing here opens a device, a pass
	 of one loop costs under a millisecond, and the figures are read as differences of floors,
	 which are only worth as much as the noise left in each of them."
	^ 20
]

{ #category : 'instance creation' }
VGInteriorQuestionBudget class >> overFrames: aFrameNameCollection extent: anExtent passes: aCount [
	"Those frames at that extent, over that many passes, and run. The rows are built before the
	 first pass and every pass walks them all, so the frames are interleaved inside the run
	 rather than measured one after the other."
	^ self new
		  setPasses: aCount;
		  runOverFrames: aFrameNameCollection extent: anExtent;
		  yourself
]

{ #category : 'instance creation' }
VGInteriorQuestionBudget class >> overTheThreeFrames [
	"Every frame of the budget at the extent they are drawn for, over the default passes. This
	 is the reading unit 3.14 is decided on."
	^ self
		  overFrames: VGFrameDeviceBenchmark frameNames
		  extent: VGFrameDeviceBenchmark extentOfItsFrames
		  passes: self defaultPasses
]

{ #category : 'inspector' }
VGInteriorQuestionBudget >> inspectorFloors: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Floors'>
	"One line per frame, one column per loop, the columns built from
	 VGInteriorQuestionBudgetRow class >> measuredStages so a stage added to the predicate
	 appears here with no edit of this method. Every figure is the floor of the passes, in
	 microseconds."
	| table |
	table := aBuilder newTable
		         items: self rows;
		         addColumn:
			         (SpStringTableColumn title: 'Frame' evaluated: [ :each |
					          each frame ]);
		         addColumn:
			         (SpStringTableColumn title: 'Asked' evaluated: [ :each |
					          each pairCountOf:
						          VGInteriorQuestionBudgetRow wholeStage ]);
		         yourself.
	VGInteriorQuestionBudgetRow measuredStages do: [ :stage |
		table addColumn:
			(SpStringTableColumn title: stage evaluated: [ :each |
				 each floorOf: stage ]) ].
	^ table
]

{ #category : 'inspector' }
VGInteriorQuestionBudget >> inspectorFloorsContext: aContext [
	"A budget that has not run shows nothing."
	aContext active: rows isNotNil
]

{ #category : 'accessing' }
VGInteriorQuestionBudget >> passes [
	"How many times each loop of each row was timed."
	^ passes
]

{ #category : 'accessing' }
VGInteriorQuestionBudget >> rows [
	"One row a frame, in the order the frames were given."
	^ rows asArray
]

{ #category : 'running' }
VGInteriorQuestionBudget >> runOverFrames: aFrameNameCollection extent: anExtent [
	"One row a frame, then every pass over every row. The first pass is kept like any other:
	 the figure a row reports is the floor of its passes, and a warm-up thrown away would only
	 remove a reading that was never going to be the fastest.
	 The heap is collected before the first pass. Building the rows draws the frames and keeps a
	 pair for every question of every stage, which is tens of thousands of objects, and a run
	 made on that heap read the whole predicate of the reference frame at 4096 us where three
	 runs made on a collected heap agree within five per cent at 2975, 3122 and 3100."
	rows := aFrameNameCollection collect: [ :name |
		        VGInteriorQuestionBudgetRow frameNamed: name extent: anExtent ].
	Smalltalk garbageCollect.
	1 to: passes do: [ :pass |
		rows do: [ :each | each measurePass: pass ] ].
	^ self
]

{ #category : 'initialization' }
VGInteriorQuestionBudget >> setPasses: aCount [
	"How many times each loop is timed. A floor is read off them all."
	passes := aCount
]
