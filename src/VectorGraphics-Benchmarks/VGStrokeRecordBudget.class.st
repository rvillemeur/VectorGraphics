"
I time the parts of a stroke recording over the strokes the reference frame draws, so the lever that moves unit 3.15 is chosen on figures and not on a guess.
One row a subject — one card border, the twelve of a whole frame, a straight line — and five loops a row: the path building, the outline, the segments and their display list entry, the whole recording, and an empty loop every other figure pays too. Every figure is the floor of my passes in microseconds, because a mean carries the work the machine was doing for someone else.
VGStrokeRecordBudget overTheThreeSubjects runs the reading the unit is decided on. The Floors view is the table to read; a row's Passes view says how far its readings lie apart.
"
Class {
	#name : 'VGStrokeRecordBudget',
	#superclass : 'Object',
	#instVars : [
		'passes',
		'rows'
	],
	#category : 'VectorGraphics-Benchmarks-Strokes',
	#package : 'VectorGraphics-Benchmarks',
	#tag : 'Strokes'
}

{ #category : 'accessing' }
VGStrokeRecordBudget class >> defaultPasses [
	"Forty passes a loop. A stroke of one card border is a fraction of a millisecond, so the
	 floor of twenty passes was not reliably the best this machine can do on the cheap rows;
	 forty costs seconds and tightens them."

	^ 40
]

{ #category : 'instance creation' }
VGStrokeRecordBudget class >> overSubjects: aSubjectNameCollection extent: anExtent passes: aCount [
	"Those subjects at that extent, over that many passes, and run. The rows are built before
	 the first pass and every pass walks them all, so the subjects are interleaved inside the
	 run rather than measured one after the other."

	^ self new
		  setPasses: aCount;
		  runOverSubjects: aSubjectNameCollection extent: anExtent;
		  yourself
]

{ #category : 'instance creation' }
VGStrokeRecordBudget class >> overTheThreeSubjects [
	"Every subject of the budget at the extent the reference frame is drawn for, over the
	 default passes. This is the reading unit 3.15 is decided on."

	^ self
		  overSubjects: VGStrokeRecordBudgetRow subjectNames
		  extent: VGFrameDeviceBenchmark extentOfItsFrames
		  passes: self defaultPasses
]

{ #category : 'inspector' }
VGStrokeRecordBudget >> inspectorFloors: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Floors'>
	"One line a subject, one column a loop, the columns built from
	 VGStrokeRecordBudgetRow class >> measuredParts so a part added to the budget appears here
	 with no edit of this method. Every figure is the floor of the passes, in microseconds, and
	 the share is of the whole recording net of the empty loop."

	| table |
	table := aBuilder newTable
		         items: self rows;
		         addColumn: (SpStringTableColumn title: 'Subject' evaluated: [ :each |
					          each subject ]);
		         addColumn: (SpStringTableColumn title: 'Shapes' evaluated: [ :each |
					          each shapeBlocks size ]);
		         addColumn: (SpStringTableColumn title: 'Edges' evaluated: [ :each |
					          each edgeCount ]);
		         yourself.
	VGStrokeRecordBudgetRow measuredParts do: [ :part |
		table addColumn:
			(SpStringTableColumn title: part evaluated: [ :each |
				 each floorOf: part ]) ].
	VGStrokeRecordBudgetRow timedParts do: [ :part |
		table addColumn:
			(SpStringTableColumn
				 title: part , ' %'
				 evaluated: [ :each | (each shareOf: part) rounded ]) ].
	^ table
]

{ #category : 'inspector' }
VGStrokeRecordBudget >> inspectorFloorsContext: aContext [
	"A budget that has not run shows nothing."

	aContext active: rows isNotNil
]

{ #category : 'accessing' }
VGStrokeRecordBudget >> passes [
	"How many times each loop of each row was timed."

	^ passes
]

{ #category : 'accessing' }
VGStrokeRecordBudget >> rows [
	"One row a subject, in the order the subjects were given."

	^ rows asArray
]

{ #category : 'measuring' }
VGStrokeRecordBudget >> runOverSubjects: aSubjectNameCollection extent: anExtent [
	"One row a subject, then every pass over every row. The first pass is kept like any other:
	 a row reports the floor of its passes, and a warm-up thrown away would only remove a
	 reading that was never going to be the fastest. The heap is collected before the first
	 pass, as unit 3.14's budget has to be: building the rows draws every shape once."

	rows := aSubjectNameCollection collect: [ :name |
		        VGStrokeRecordBudgetRow subjectNamed: name extent: anExtent ].
	Smalltalk garbageCollect.
	1 to: passes do: [ :pass |
		rows do: [ :each | each measurePass: pass ] ].
	^ self
]

{ #category : 'initialization' }
VGStrokeRecordBudget >> setPasses: aCount [
	"How many times each loop is timed. A floor is read off them all."

	passes := aCount
]
