"
I am one frame, at one extent, on one of the two paths of unit 7.6, measured over several rounds of timed draws. minimumMicroseconds is the verdict figure: the fastest draw I ever paid, which is the closest this machine comes to the cost of the work with nothing else of the system in it. medianMicroseconds and firstDrawMicroseconds stand beside it, because a first draw against a minimum says how much of a figure is the work and how much is the state the image was in. stagesOfRound: holds what the mean draw of a round was made of, stage by stage, the host's own copies among them where the path pays any. My Stages view reads those tables, one column a round. VGPresentPathBenchmark builds me and holds the pair I belong to.
"
Class {
	#name : 'VGPresentPathComparison',
	#superclass : 'Object',
	#instVars : [
		'frameName',
		'extent',
		'pathName',
		'roundDraws',
		'roundStages'
	],
	#category : 'VectorGraphics-Benchmarks-Present',
	#package : 'VectorGraphics-Benchmarks',
	#tag : 'Present'
}

{ #category : 'instance creation' }
VGPresentPathComparison class >> frameName: aName extent: anExtent path: aPathName [
	^ self new setFrameName: aName extent: anExtent path: aPathName
]

{ #category : 'measuring' }
VGPresentPathComparison >> addRound: aCollectionOfMicroseconds stages: aDictionary [
	"One round of timed draws, and what the mean draw of that round was made of stage by stage.
	 The table is copied, because the dispatch that built it writes its own stage times again on
	 the next round and a round that held a live dictionary would read as the round after it."
	roundDraws add: aCollectionOfMicroseconds asArray.
	roundStages add: aDictionary copy
]

{ #category : 'accessing' }
VGPresentPathComparison >> allDraws [
	"Every timed draw of every round, in the order they were drawn."
	^ roundDraws inject: OrderedCollection new into: [ :all :each |
		  all
			  addAll: each;
			  yourself ]
]

{ #category : 'accessing' }
VGPresentPathComparison >> drawsOfRound: anIndex [
	"The timed draws of that round, in the order they were drawn."
	^ roundDraws at: anIndex
]

{ #category : 'accessing' }
VGPresentPathComparison >> extent [
	^ extent
]

{ #category : 'printing' }
VGPresentPathComparison >> fastestMillisecondString [
	"My verdict figure, printed: the fastest draw I ever held."
	^ self millisecondStringOf: self minimumMicroseconds
]

{ #category : 'accessing' }
VGPresentPathComparison >> firstDrawMicroseconds [
	"The first timed draw of the first round, kept because the stages of a dispatch grow frame
	 over frame: a first draw beside a minimum says how much of a figure is the work and how
	 much is the age of the image it was measured in."
	^ roundDraws
		  ifEmpty: [ nil ]
		  ifNotEmpty: [ :rounds | rounds first ifEmpty: [ nil ] ifNotEmpty: [ :draws | draws first ] ]
]

{ #category : 'printing' }
VGPresentPathComparison >> firstDrawMillisecondString [
	"My first timed draw, printed, which is the one that followed the other path."
	^ self millisecondStringOf: self firstDrawMicroseconds
]

{ #category : 'accessing' }
VGPresentPathComparison >> frameName [
	^ frameName
]

{ #category : 'inspector' }
VGPresentPathComparison >> inspectorStages: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Stages'>
	"What one draw of this path is made of, one column a round, so that a stage which grows from
	 round to round is visible as such. Every figure is the mean draw of its round. The rows are
	 the stages this comparison really recorded and not a list written here, so a path that
	 stops paying a stage stops showing it."
	| table |
	table := aBuilder newTable
		         items: self stageNames;
		         addColumn:
			         (SpStringTableColumn title: 'Stage' evaluated: [ :each |
					          each ]);
		         yourself.
	1 to: self roundCount do: [ :round |
		table addColumn: (SpStringTableColumn
				 title: 'Round ' , round printString , ' us a draw'
				 evaluated: [ :each |
					 ((self stagesOfRound: round) at: each ifAbsent: [ nil ])
						 ifNil: [ '-' ]
						 ifNotNil: [ :microseconds | microseconds printString ] ]) ].
	^ table
]

{ #category : 'inspector' }
VGPresentPathComparison >> inspectorStagesContext: aContext [
	"A comparison of no rounds has no stages to show."
	aContext active: roundDraws isNotEmpty
]

{ #category : 'accessing' }
VGPresentPathComparison >> medianMicroseconds [
	"The middle draw of all rounds. An even count takes the lower of the two middles rather
	 than their mean, so every figure a report shows is a draw that really happened."
	| sorted |
	sorted := self allDraws asSortedCollection asArray.
	^ sorted ifEmpty: [ nil ] ifNotEmpty: [ sorted at: (sorted size + 1) // 2 ]
]

{ #category : 'printing' }
VGPresentPathComparison >> medianMillisecondString [
	"My middle draw, printed, which says how much of the fastest one was the state of the
	 image rather than the work."
	^ self millisecondStringOf: self medianMicroseconds
]

{ #category : 'printing' }
VGPresentPathComparison >> millisecondStringOf: microsecondsOrNil [
	"Microseconds of mine printed as milliseconds, because every other report of this project is
	 in milliseconds. A figure that was never measured prints as a dash and not as a zero."
	^ microsecondsOrNil
		  ifNil: [ '-' ]
		  ifNotNil: [ :microseconds |
		  (microseconds / 1000.0) printShowingDecimalPlaces: 3 ]
]

{ #category : 'accessing' }
VGPresentPathComparison >> minimumMicroseconds [
	"The fastest draw this path ever paid for this frame, which is the verdict figure: the
	 closest this machine comes to the cost of the work with nothing else of the system in it."
	^ self allDraws ifEmpty: [ nil ] ifNotEmpty: [ :draws | draws min ]
]

{ #category : 'accessing' }
VGPresentPathComparison >> pathName [
	^ pathName
]

{ #category : 'printing' }
VGPresentPathComparison >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: ' ';
		nextPutAll: frameName;
		nextPutAll: ' ';
		print: extent;
		nextPutAll: ' ';
		nextPutAll: pathName.
	self minimumMicroseconds ifNotNil: [ :microseconds |
		aStream
			nextPutAll: ' min ';
			print: microseconds;
			nextPutAll: ' us' ]
]

{ #category : 'accessing' }
VGPresentPathComparison >> roundCount [
	^ roundDraws size
]

{ #category : 'initialization' }
VGPresentPathComparison >> setFrameName: aName extent: anExtent path: aPathName [
	frameName := aName.
	extent := anExtent.
	pathName := aPathName.
	roundDraws := OrderedCollection new.
	roundStages := OrderedCollection new
]

{ #category : 'accessing' }
VGPresentPathComparison >> stageNames [
	"Every stage any round of mine recorded, sorted, so a table has one column order whatever
	 a given round happened to pay."
	^ (roundStages inject: Set new into: [ :all :each |
		   all
			   addAll: each keys;
			   yourself ]) asSortedCollection asArray
]

{ #category : 'accessing' }
VGPresentPathComparison >> stagesOfRound: anIndex [
	"What the mean draw of that round was made of, stage by stage, in microseconds, the host's
	 own copies among them."
	^ roundStages at: anIndex
]
