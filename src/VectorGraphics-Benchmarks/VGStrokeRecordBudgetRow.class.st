"
I am one subject of VGStrokeRecordBudget: a stroke, a surface to record it on, and the readings of every loop timed over it.
My subject is a symbol, and my shapes are the blocks my class answers for it. I hold one context for the whole run and reset its display list before a pass starts the clock, because a recording appends to that list and building a surface again would cost more than the stroke I am timing. Everything a loop needs that is not the part itself — the paths, the strokers, the outline coordinates — is built before the clock starts.
floorOf: answers the fastest pass of a loop, netOf: that figure less the empty loop, and shareOf: what per cent of the whole recording a part is.
"
Class {
	#name : 'VGStrokeRecordBudgetRow',
	#superclass : 'Object',
	#instVars : [
		'subject',
		'extent',
		'context',
		'shapeBlocks',
		'microseconds'
	],
	#category : 'VectorGraphics-Benchmarks-Strokes',
	#package : 'VectorGraphics-Benchmarks',
	#tag : 'Strokes'
}

{ #category : 'accessing' }
VGStrokeRecordBudgetRow class >> borderSubject [
	"One card border alone: the shape the reference frame records twelve of."

	^ #border
]

{ #category : 'subjects' }
VGStrokeRecordBudgetRow class >> cardBorderBlockAt: anIndex [
	"The border of the card of this index, as the reference frame records it: a rounded
	 rectangle of VGFrameProfile's own corner radius at the box VGFrameDeviceBenchmark lays
	 that card out in. The path is begun inside the block, because beginning it is part of what
	 the path phase of a recording pays."

	| box radius |
	box := VGFrameDeviceBenchmark cardBoxAt: anIndex.
	radius := VGFrameProfile cardCornerRadius.
	^ [ :aContext |
	  aContext newPath.
	  aContext
		  roundedRectangleLeft: box left
		  top: box top
		  right: box right
		  bottom: box bottom
		  tl: radius
		  tr: radius
		  br: radius
		  bl: radius ]
]

{ #category : 'accessing' }
VGStrokeRecordBudgetRow class >> frameSubject [
	"Every card border of the reference frame, which is where unit 3.13 found 2688 of the
	 frame's 2740 edges."

	^ #frame
]

{ #category : 'accessing' }
VGStrokeRecordBudgetRow class >> lineSubject [
	"One straight stroked segment: the cheapest stroke there is, so that a lever which only
	 pays on a dense outline cannot read as a lever that pays everywhere."

	^ #line
]

{ #category : 'accessing' }
VGStrokeRecordBudgetRow class >> loopPart [
	"The same shapes walked with nothing done to them, which every other figure of a row pays
	 too."

	^ #loop
]

{ #category : 'accessing' }
VGStrokeRecordBudgetRow class >> measuredParts [
	"Every loop a pass times: the three parts of a recording, the whole recording, and the loop
	 that does nothing at all."

	^ self timedParts , { self wholePart. self loopPart }
]

{ #category : 'accessing' }
VGStrokeRecordBudgetRow class >> outlinePart [
	"VGStroker >> edgeCoordinates on a path already built: the map into user space, the stroke
	 walk over the runs, and the map of every outline vertex back into device space."

	^ #outline
]

{ #category : 'accessing' }
VGStrokeRecordBudgetRow class >> pathPart [
	"The context calls that build the path, where every snap of a coordinate onto Cairo's grid
	 is paid."

	^ #path
]

{ #category : 'accessing' }
VGStrokeRecordBudgetRow class >> segmentsPart [
	"The segments built around coordinates already computed, and the display list entry that
	 carries them, which is where the paint and the clip of the entry are built."

	^ #segments
]

{ #category : 'subjects' }
VGStrokeRecordBudgetRow class >> shapeBlocksNamed: aSymbol [
	"One block a shape of that subject, each of them building its own path on the context it is
	 given. A symbol and not a class a subject, as VGFrameDeviceBenchmark names its own three
	 frames: three shapes of one geometry do not earn three classes."

	aSymbol == self borderSubject ifTrue: [ ^ { (self cardBorderBlockAt: 1) } ].
	aSymbol == self frameSubject ifTrue: [
		^ (1 to: VGFrameProfile referenceCards) collect: [ :index |
			  self cardBorderBlockAt: index ] ].
	aSymbol == self lineSubject ifTrue: [ ^ { self straightLineBlock } ].
	^ self error: 'no subject named ' , aSymbol printString
]

{ #category : 'subjects' }
VGStrokeRecordBudgetRow class >> straightLineBlock [
	"A horizontal line across the first card's box, which is one segment, two caps and no join
	 at all."

	| box |
	box := VGFrameDeviceBenchmark cardBoxAt: 1.
	^ [ :aContext |
	  aContext newPath.
	  aContext lineFrom: box leftCenter to: box rightCenter ]
]

{ #category : 'instance creation' }
VGStrokeRecordBudgetRow class >> subjectNamed: aSymbol extent: anExtent [
	"A row over that subject, drawn on a surface of that extent. Nothing is timed until a pass
	 asks for it."

	^ self new
		  setSubject: aSymbol extent: anExtent;
		  yourself
]

{ #category : 'accessing' }
VGStrokeRecordBudgetRow class >> subjectNames [
	"The subjects a budget holds a row for, cheapest last so a reader meets the dense outline
	 first."

	^ { self borderSubject. self frameSubject. self lineSubject }
]

{ #category : 'accessing' }
VGStrokeRecordBudgetRow class >> timedParts [
	"The parts of a recording, in the order a stroke pays them."

	^ { self pathPart. self outlinePart. self segmentsPart }
]

{ #category : 'accessing' }
VGStrokeRecordBudgetRow class >> wholePart [
	"The whole recording of the stroke, path building included: what a frame actually pays, and
	 the figure the three parts inside it stand under."

	^ #whole
]

{ #category : 'accessing' }
VGStrokeRecordBudgetRow >> context [
	"The one context every pass of mine records on, built the first time anything asks for it.
	 A recording appends to the display list of its surface, so a pass resets that list before
	 it starts the clock rather than building a surface again: the reset is what a kept surface
	 needs, and building a surface of this extent would allocate nearly two megabytes a pass."

	^ context ifNil: [ context := self newContext ]
]

{ #category : 'accessing' }
VGStrokeRecordBudgetRow >> edgeCount [
	"The outline edges of all my shapes together, which is the size of the work every figure of
	 mine is a time for."

	^ self outlines inject: 0 into: [ :sum :each | sum + each size ]
]

{ #category : 'accessing' }
VGStrokeRecordBudgetRow >> extent [
	"The extent of the surface my stroke is recorded on."

	^ extent
]

{ #category : 'accessing' }
VGStrokeRecordBudgetRow >> floorOf: aPart [
	"The fastest pass of that loop, in microseconds. A floor and never a mean: every other
	 reading of the same loop holds work the machine was doing for someone else."

	^ (microseconds at: aPart) detectMin: [ :each | each ]
]

{ #category : 'inspector' }
VGStrokeRecordBudgetRow >> inspectorPasses: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Passes'>
	"Every reading of every loop, in the order they were taken, so a reader sees how far the
	 passes are apart and whether the floor is one lucky pass or the shape of the whole run."

	| table |
	table := aBuilder newTable
		         items: (1 to: (self readingsOf: self class wholePart) size);
		         addColumn:
			         (SpStringTableColumn title: 'Pass' evaluated: [ :each | each ]);
		         yourself.
	self class measuredParts do: [ :part |
		table addColumn:
			(SpStringTableColumn title: part evaluated: [ :each |
				 (self readingsOf: part) at: each ]) ].
	^ table
]

{ #category : 'inspector' }
VGStrokeRecordBudgetRow >> inspectorPassesContext: aContext [
	"A row no pass has reached shows nothing."

	aContext active: (self readingsOf: self class wholePart) isNotEmpty
]

{ #category : 'measuring' }
VGStrokeRecordBudgetRow >> measureLoopPass [
	"The same shapes walked with nothing done to them, which every other figure of mine pays
	 too."

	| blocks |
	blocks := shapeBlocks.
	self recordPart: self class loopPart during: [
		blocks do: [ :each | each ] ]
]

{ #category : 'measuring' }
VGStrokeRecordBudgetRow >> measureOutlinePass [
	"The outline coordinates of every shape, over strokers built outside the clock."

	| strokers |
	strokers := self strokersOn: self context.
	self recordPart: self class outlinePart during: [
		strokers do: [ :each | each edgeCoordinates ] ]
]

{ #category : 'measuring' }
VGStrokeRecordBudgetRow >> measurePass: anIndex [
	"Every loop once, in an order that turns over with the pass, so no part is always the one
	 measured on the heap the part before it had just grown."

	| order |
	order := anIndex odd
		         ifTrue: [ self class measuredParts ]
		         ifFalse: [ self class measuredParts reversed ].
	order do: [ :part | (self passesByPart at: part) value ]
]

{ #category : 'measuring' }
VGStrokeRecordBudgetRow >> measurePathPass [
	"The context calls of every shape, which is where the coordinates reach Cairo's grid."

	| blocks aContext |
	blocks := shapeBlocks.
	aContext := self context.
	self recordPart: self class pathPart during: [
		blocks do: [ :each | each value: aContext ] ]
]

{ #category : 'measuring' }
VGStrokeRecordBudgetRow >> measureSegmentsPass [
	"The segments built around coordinates computed outside the clock, and the display list
	 entry each of them goes into, which is where the paint and the clip of an entry are built."

	| outlines aContext |
	aContext := self context.
	outlines := self outlinesOn: aContext.
	self resetRecording.
	self recordPart: self class segmentsPart during: [
		outlines do: [ :each |
			aContext recordFillOf: (VGSegments
					 coordinates: each coordinates
					 fillRule: each fillRule
					 antialias: each antialias) ] ]
]

{ #category : 'measuring' }
VGStrokeRecordBudgetRow >> measureWholePass [
	"Every shape built and stroked as a frame does it, which is the figure the three parts
	 stand under."

	| blocks aContext |
	blocks := shapeBlocks.
	aContext := self context.
	self resetRecording.
	self recordPart: self class wholePart during: [
		blocks do: [ :each |
			each value: aContext.
			aContext stroke ] ]
]

{ #category : 'accessing' }
VGStrokeRecordBudgetRow >> netOf: aPart [
	"The floor of that loop less the floor of the loop that does nothing, which is the figure
	 to compare against another part. Never below zero: a loop cheaper than the empty loop is a
	 reading the machine disturbed, not a part that gives time back."

	^ ((self floorOf: aPart) - (self floorOf: self class loopPart)) max: 0
]

{ #category : 'private' }
VGStrokeRecordBudgetRow >> newContext [
	"A context on a surface of my extent, with the line width the reference frame strokes its
	 card borders at. The width is set here and not inside a shape block, because a shape block
	 is what the path phase times and setting a state field is not path building."

	^ (VGFrameDrawingKit ours surfaceOfExtent: extent) newContext
		  strokeSize: VGFrameProfile cardBorderWidth;
		  yourself
]

{ #category : 'accessing' }
VGStrokeRecordBudgetRow >> outlines [
	"The stroke outline of every shape of my subject. This is what the counting half of the
	 budget reads: 224 edges a card border, which is what unit 3.13's census counted for one of
	 the twelve. A context of its own is built for it, so a reader of the counts leaves the
	 context my passes record on as the last pass left it."

	^ self outlinesOn: self newContext
]

{ #category : 'accessing' }
VGStrokeRecordBudgetRow >> outlinesOn: aContext [
	"The stroke outline of every shape of my subject, as the segments a recording fills, built
	 over paths that context holds."

	^ (self strokersOn: aContext) collect: [ :each | each segments ]
]

{ #category : 'measuring' }
VGStrokeRecordBudgetRow >> passesByPart [
	"One pass of each part, each of them preparing its own input before it starts the clock."

	^ Dictionary newFrom: {
			  (self class pathPart -> [ self measurePathPass ]).
			  (self class outlinePart -> [ self measureOutlinePass ]).
			  (self class segmentsPart -> [ self measureSegmentsPass ]).
			  (self class wholePart -> [ self measureWholePass ]).
			  (self class loopPart -> [ self measureLoopPass ]) }
]

{ #category : 'printing' }
VGStrokeRecordBudgetRow >> printOn: aStream [
	"The subject and the shape count, so a collection of rows reads without opening one."

	super printOn: aStream.
	aStream
		nextPutAll: '(';
		nextPutAll: subject;
		nextPutAll: ', ';
		print: shapeBlocks size;
		nextPutAll: ' shapes)'
]

{ #category : 'accessing' }
VGStrokeRecordBudgetRow >> readingsOf: aPart [
	"Every pass of that loop, in microseconds and in the order they were taken. A reader of the
	 floors needs them to see how far apart the passes were."

	^ (microseconds at: aPart) asArray
]

{ #category : 'private' }
VGStrokeRecordBudgetRow >> recordPart: aPart during: aBlock [
	"The block timed and the reading kept under that part. The clock is read twice and nothing
	 else is done between the readings."

	| start |
	start := Time microsecondClockValue.
	aBlock value.
	(microseconds at: aPart) add: Time microsecondClockValue - start
]

{ #category : 'private' }
VGStrokeRecordBudgetRow >> resetRecording [
	"The display list emptied, so a pass records against the list the pass before it recorded
	 against. Outside every clock."

	self context surface displayList reset
]

{ #category : 'initialization' }
VGStrokeRecordBudgetRow >> setSubject: aSymbol extent: anExtent [
	"Which stroke I time and how large the surface it is recorded on is. The shape blocks are
	 built now, because building them reads the card grid and a pass must find them ready."

	subject := aSymbol.
	extent := anExtent.
	shapeBlocks := self class shapeBlocksNamed: aSymbol.
	microseconds := Dictionary new.
	self class measuredParts do: [ :part |
		microseconds at: part put: OrderedCollection new ]
]

{ #category : 'accessing' }
VGStrokeRecordBudgetRow >> shapeBlocks [
	"One block a shape of my subject, each building its own path on the context it is given."

	^ shapeBlocks
]

{ #category : 'accessing' }
VGStrokeRecordBudgetRow >> shareOf: aPart [
	"What per cent of the whole recording that part is, net of the empty loop. The three parts
	 are cut at seams, so their shares do not have to add to a hundred: what they leave is the
	 recording's own work around them."

	| whole |
	whole := self netOf: self class wholePart.
	whole isZero ifTrue: [ ^ 0 ].
	^ (self netOf: aPart) * 100 / whole
]

{ #category : 'private' }
VGStrokeRecordBudgetRow >> strokersOn: aContext [
	"One stroker a shape of my subject, each over the path its own shape block builds on that
	 context. Built outside every clock, because a stroker holds a path and building the path
	 is a part of its own."

	^ shapeBlocks collect: [ :each |
		  each value: aContext.
		  VGStroker path: aContext pathBuilder path state: aContext state ]
]

{ #category : 'accessing' }
VGStrokeRecordBudgetRow >> subject [
	"Which stroke of the budget I time."

	^ subject
]
