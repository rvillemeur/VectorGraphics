"
I hold what the passes of a benchmark read for each named stage: the total of them, so that a mean over the repeats can be answered, and the fastest of them. One object rather than a table of totals beside a table of minimums, because two tables keyed by the same names fall out of step and every method that filled them carried both as arguments.

A reading is added in microseconds — `add:of:` — and answered in milliseconds — `meanOf:`, `floorOf:`, `means`, `floors` — since that is the unit a report quotes and this is the one place the conversion belongs. A stage nothing was read for answers nil.

A stage can be taken apart: `insideOf:` answers the timings of the phases that stage is made of, the same object every time, which is how the encode of a frame carries the phases of its host half under it.
"
Class {
	#name : 'VGStageTimings',
	#superclass : 'Object',
	#instVars : [
		'totals',
		'bests',
		'insides',
		'counts'
	],
	#category : 'VectorGraphics-Vulkan-Budget',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Budget'
}

{ #category : 'measuring' }
VGStageTimings >> add: aNumber of: aStage [
	"One reading of that stage, in microseconds, added to what its passes have cost, counted,
	 and compared with the fastest of them. The count is kept rather than the repeats of the
	 benchmark, because a stage measured once — a software frame, the opening of a device — is
	 in the same table as one measured over every pass."

	totals at: aStage put: (totals at: aStage ifAbsent: [ 0 ]) + aNumber.
	counts at: aStage put: (counts at: aStage ifAbsent: [ 0 ]) + 1.
	bests at: aStage put: ((bests at: aStage ifAbsent: [ aNumber ]) min: aNumber)
]

{ #category : 'reading' }
VGStageTimings >> floorOf: aStage [
	"The fastest pass of that stage in milliseconds, or nil where the stage was read once or
	 not at all. The floor is the work without the collector and the scheduler of whichever
	 pass met them, which is what a decision between two levers is read off; a stage read once
	 has no floor to report, because there is nothing for it to be the floor of."

	(counts at: aStage ifAbsent: [ 0 ]) > 1 ifFalse: [ ^ nil ].
	^ self millisecondsOfMicroseconds: (bests at: aStage)
]

{ #category : 'reading' }
VGStageTimings >> floors [
	"Every stage read more than once, with the fastest of its passes in milliseconds. A stage
	 read once is left out, for the reason floorOf: gives."

	| table |
	table := Dictionary new.
	bests keysDo: [ :each |
		(self floorOf: each) ifNotNil: [ :floor | table at: each put: floor ] ].
	^ table
]

{ #category : 'initialization' }
VGStageTimings >> initialize [
	super initialize.
	totals := Dictionary new.
	counts := Dictionary new.
	bests := Dictionary new.
	insides := Dictionary new
]

{ #category : 'reading' }
VGStageTimings >> insideOf: aStage [
	"The timings of the phases that stage is made of, created on the first ask and the same
	 object afterwards: a loop that reads a phase table into it once a pass must find the
	 readings of the pass before still there."

	^ insides at: aStage ifAbsentPut: [ self class new ]
]

{ #category : 'inspector' }
VGStageTimings >> inspectorStages: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Stages'>
	"Every stage read for, the mean of its passes and the fastest of them, the slowest first,
	 and under a stage that was taken apart the phases it is made of, labelled as what they are
	 inside of. A stage read once has no floor and shows none, which is the rule floorOf: states.
	 The rows are built from the tables themselves, so a stage no pass read for cannot appear."

	^ aBuilder newTable
		  addColumn: (SpStringTableColumn
				   title: 'Stage'
				   evaluated: [ :each | each first ]);
		  addColumn: (SpStringTableColumn
				   title: 'Mean'
				   evaluated: [ :each | self millisecondStringFor: each second ]);
		  addColumn: (SpStringTableColumn
				   title: 'Fastest'
				   evaluated: [ :each |
					   each third
						   ifNil: [ '' ]
						   ifNotNil: [ :floor | self millisecondStringFor: floor ] ]);
		  items: self stageRows;
		  yourself
]

{ #category : 'inspector' }
VGStageTimings >> inspectorStagesContext: aContext [
	aContext active: self means isNotEmpty
]

{ #category : 'reading' }
VGStageTimings >> meanOf: aStage [
	"The mean pass of that stage in milliseconds, or nil where nothing was read for it."

	^ (totals at: aStage ifAbsent: [ nil ]) ifNotNil: [ :total |
		  self millisecondsOfMicroseconds: total / (counts at: aStage) ]
]

{ #category : 'reading' }
VGStageTimings >> means [
	"Every stage read for, with the mean of its passes in milliseconds."

	| table |
	table := Dictionary new.
	totals keysDo: [ :each | table at: each put: (self meanOf: each) ].
	^ table
]

{ #category : 'reading' }
VGStageTimings >> microseconds [
	"What every stage read for has cost in all, in microseconds, keyed by stage. The unit is
	 the clock's own, for the reader that adds a reading of mine to a table of its own and
	 cannot add a figure already rounded to milliseconds."

	^ totals copy
]

{ #category : 'printing' }
VGStageTimings >> millisecondStringFor: aNumber [
	"A figure as a report and a tab read it, to the decimal places this project prints a
	 millisecond to."

	^ (aNumber asFloat printShowingDecimalPlaces:
		   VGVulkanRoundTrip millisecondDecimalPlaces) , ' ms'
]

{ #category : 'private' }
VGStageTimings >> millisecondsOfMicroseconds: aNumber [
	"The one place a reading of the clock becomes the unit a report quotes."

	^ aNumber / VGVulkanRoundTrip microsecondsPerMillisecond
]

{ #category : 'measuring' }
VGStageTimings >> remove: aStage [
	"Forget every reading of that stage, for the one caller that measures something and then
	 finds it answered nothing: the opening of a device on a machine with no driver is timed
	 before it is known to have failed."

	totals removeKey: aStage ifAbsent: [ nil ].
	counts removeKey: aStage ifAbsent: [ nil ].
	bests removeKey: aStage ifAbsent: [ nil ].
	insides removeKey: aStage ifAbsent: [ nil ]
]

{ #category : 'reading' }
VGStageTimings >> stageRows [
	"One row a stage read for — its name, its mean and its floor — the slowest first, each
	 followed by the rows of the timings it was taken apart into. A row of an inside is named
	 for the stage it is inside of, because the two sets of names are read in one table and a
	 phase of the host half and a stage of a frame can be called the same thing."

	| rows |
	rows := OrderedCollection new.
	(self means associations sorted: [ :a :b | a value >= b value ]) do: [ :each |
		rows add: {
				each key asString.
				each value.
				(self floorOf: each key) }.
		(insides at: each key ifAbsent: [ nil ]) ifNotNil: [ :inside |
			inside stageRows do: [ :row |
				rows add: {
						each key asString , ': ' , row first.
						row second.
						row third } ] ] ].
	^ rows asArray
]

{ #category : 'measuring' }
VGStageTimings >> time: aStage during: aBlock [
	"Evaluate the block and keep the microseconds it took as one reading of that stage. The
	 clock is read in microseconds because a phase of a frame can finish inside a millisecond.
	 Answers what the block answered, so a phase can be timed around the expression that
	 produces the thing the next phase needs."

	| start value |
	start := Time microsecondClockValue.
	value := aBlock value.
	self add: Time microsecondClockValue - start of: aStage.
	^ value
]
