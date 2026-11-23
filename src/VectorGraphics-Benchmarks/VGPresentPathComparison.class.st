"
I am one frame measured at one extent on one of the two paths unit 7.6 compares: the presented path, which ends on the device, and the readBack path, which ends in the host's own pixels. I hold the microseconds of every timed draw of every round, and the stage table the dispatch recorded for the last draw of each round, the host's own copies among them. minimumMicroseconds is the figure the verdict is read from, because it is the closest this machine comes to the cost of the work itself; medianMicroseconds and firstDrawMicroseconds are kept beside it, since the stages of a long-lived dispatch grow frame over frame and a verdict that hid that would be read as something it is not.
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
	#category : 'VectorGraphics-Benchmarks',
	#package : 'VectorGraphics-Benchmarks'
}

{ #category : 'instance creation' }
VGPresentPathComparison class >> frameName: aName extent: anExtent path: aPathName [
	^ self new setFrameName: aName extent: anExtent path: aPathName
]

{ #category : 'measuring' }
VGPresentPathComparison >> addRound: aCollectionOfMicroseconds stages: aDictionary [
	"One round of timed draws and the stage table the dispatch recorded for the last of them.
	 The table is copied, because a dispatch overwrites its own stage times on the next draw and
	 a round that handed out a live dictionary would read as the round after it."
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
VGPresentPathComparison >> extent [
	^ extent
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

{ #category : 'accessing' }
VGPresentPathComparison >> frameName [
	^ frameName
]

{ #category : 'inspector' }
VGPresentPathComparison >> inspectorStages: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Stages'>
	"What one draw of this path is made of, one column a round, so that a stage which grows from
	 round to round is visible as such. The rows are the stages this comparison really recorded
	 and not a list written here, so a path that stops paying a stage stops showing it."
	| table |
	table := aBuilder newTable
		         items: self stageNames;
		         addColumn:
			         (SpStringTableColumn title: 'Stage' evaluated: [ :each |
					          each ]);
		         yourself.
	1 to: self roundCount do: [ :round |
		table addColumn: (SpStringTableColumn
				 title: 'Round ' , round printString , ' us'
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
	"The stage table the dispatch recorded for the last draw of that round, the host's own
	 copies among them."
	^ roundStages at: anIndex
]
