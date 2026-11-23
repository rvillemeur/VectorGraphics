"
The parity floor of unit 3.13: what recording the reference frame costs on my side and on Cairo's, with one part of the frame left out at a time. One row a variant an extent, each holding the floor of every drawing phase on both kits.

Nothing here touches a device. The question is what the display list costs to build against what Cairo costs to draw, and a GPU answers neither half of it.

The two kits alternate inside every pass and the kit that goes first alternates by pass, so neither is always measured on an allocator the other warmed. The figure read off a row is the floor — the fastest pass — because a mean measures the garbage collector and the scheduler of whichever pass met them.

`overTheReferenceVariants` runs the whole budget; `reportRows` and the inspector views read the verdict off the rows.
"
Class {
	#name : 'VGFrameRecordComparison',
	#superclass : 'Object',
	#instVars : [
		'rows',
		'passes'
	],
	#category : 'VectorGraphics-Benchmarks-Frames',
	#package : 'VectorGraphics-Benchmarks',
	#tag : 'Frames'
}

{ #category : 'constants' }
VGFrameRecordComparison class >> defaultPasses [
	"Twenty passes a variant a kit. Nothing here opens a device and a pass costs a few
	 milliseconds, so the floor can be read off many passes rather than off three: a variant
	 subtracted from another is a difference of two floors, and a difference is only worth as
	 much as the noise left in each of them."
	^ 20
]

{ #category : 'instance creation' }
VGFrameRecordComparison class >> overTheReferenceVariants [
	"The whole budget of unit 3.13: every variant at both extents a frame of this project is
	 measured at, over the default passes."
	^ self
		  overVariants: self variantNames
		  extents: VGFrameDeviceBenchmark extentsOfItsCensus
		  passes: self defaultPasses
]

{ #category : 'instance creation' }
VGFrameRecordComparison class >> overVariants: aVariantNameCollection extents: anExtentCollection passes: aCount [
	"Those variants at those extents, measured over that many passes, and run. The rows are
	 built before the first pass and every pass walks them all, so the two kits and the five
	 variants are interleaved inside the run rather than measured one after the other: a
	 variant measured alone would be measured on whatever the machine was doing at that minute."
	^ self new
		  setPasses: aCount;
		  runOverVariants: aVariantNameCollection extents: anExtentCollection;
		  yourself
]

{ #category : 'reporting' }
VGFrameRecordComparison class >> rowColumns [
	"The columns of the row table, each a title and the unary selector that answers it. The one
	 place a column of that table is named, so a view and a report cannot disagree about what
	 is in it."
	^ {
		  ('left out' -> #variant).
		  ('extent' -> #extent).
		  ('ours' -> #ourRecordFloorString).
		  ('Cairo' -> #cairoRecordFloorString).
		  ('ours / Cairo' -> #ratioString).
		  ('part costs us' -> #ourPartCostString).
		  ('part costs Cairo' -> #cairoPartCostString) }
]

{ #category : 'constants' }
VGFrameRecordComparison class >> variantNames [
	"The reference frame and the four variants of it, the whole frame first: every other row is
	 subtracted from that one. The names of the parts are the names the drawing knows, so a
	 part added to VGFrameProfile is measured by adding it here and nowhere else."
	^ #( #whole #labels #border #gradient #cards )
]

{ #category : 'accessing' }
VGFrameRecordComparison >> dearestPartRow [
	"The variant whose missing part costs my recording the most, which is where a lever would
	 go if unit 3.13 found one worth pulling."
	^ (rows reject: [ :each | each ourPartCost isNil ]) detectMax: [ :each |
		  each ourPartCost ]
]

{ #category : 'accessing' }
VGFrameRecordComparison >> hasRun [
	"A comparison built and not yet run has no row, which is what the gate of a view and the
	 report both read."
	^ rows isNotEmpty
]

{ #category : 'initialization' }
VGFrameRecordComparison >> initialize [
	super initialize.
	rows := OrderedCollection new.
	passes := self class defaultPasses
]

{ #category : 'inspecting' }
VGFrameRecordComparison >> inspectorRows: aBuilder [
	<inspectorPresentationOrder: 1 title: 'Rows'>
	| table |
	table := aBuilder newTable.
	self class rowColumns do: [ :each |
		table addColumn: (SpStringTableColumn title: each key evaluated: [ :row |
				 (row perform: each value) displayString ]) ].
	^ table
		  items: self rows;
		  yourself
]

{ #category : 'inspecting' }
VGFrameRecordComparison >> inspectorRowsContext: aContext [
	aContext active: self hasRun
]

{ #category : 'inspecting' }
VGFrameRecordComparison >> inspectorVerdict: aBuilder [
	<inspectorPresentationOrder: 2 title: 'Verdict'>
	^ aBuilder newTable
		  addColumn:
			  (SpStringTableColumn title: 'What' evaluated: [ :each | each key ]);
		  addColumn:
			  (SpStringTableColumn title: 'Value' evaluated: [ :each | each value ]);
		  items: self reportRows;
		  yourself
]

{ #category : 'inspecting' }
VGFrameRecordComparison >> inspectorVerdictContext: aContext [
	aContext active: self hasRun
]

{ #category : 'printing' }
VGFrameRecordComparison >> printOn: aStream [
	super printOn: aStream.
	self hasRun ifFalse: [ ^ aStream nextPutAll: ' not run' ].
	aStream
		nextPutAll: ' ';
		print: rows size;
		nextPutAll: ' rows over ';
		print: passes;
		nextPutAll: ' passes'
]

{ #category : 'reporting' }
VGFrameRecordComparison >> reportRows [
	"The verdict of unit 3.13: what the whole frame costs each side at each extent, the layout
	 both of them pay, and the part of the frame my recording pays the most for. Empty before
	 the comparison has run, which is what its views are gated on."
	| built |
	self hasRun ifFalse: [ ^ #(  ) ].
	built := OrderedCollection new.
	self wholeRows do: [ :each |
		| at |
		at := ' at ' , each extent x printString , 'x' , each extent y printString.
		built
			add: 'whole frame, ours' , at -> each ourRecordFloorString;
			add: 'whole frame, Cairo' , at -> each cairoRecordFloorString;
			add: 'whole frame, ours / Cairo' , at -> each ratioString;
			add: 'layout, ours' , at
				-> (each millisecondStringOf:
						 (each ourFloorOf: VGFrameRecordComparisonRow sceneStageName));
			add: 'layout, Cairo' , at
				-> (each millisecondStringOf:
						 (each cairoFloorOf: VGFrameRecordComparisonRow sceneStageName)) ].
	self dearestPartRow ifNotNil: [ :row |
		built
			add: 'dearest part of the frame' -> row variant asString;
			add: 'what it costs us' -> row ourPartCostString;
			add: 'what it costs Cairo' -> row cairoPartCostString ].
	^ built asArray
]

{ #category : 'accessing' }
VGFrameRecordComparison >> rows [
	^ rows asArray
]

{ #category : 'measuring' }
VGFrameRecordComparison >> runOverVariants: aVariantNameCollection extents: anExtentCollection [
	"One row a variant an extent, every row told which row of its own extent leaves nothing
	 out, then every pass over every row. The first pass is kept like any other: the figure a
	 row reports is the floor of its passes, and a warm-up thrown away would only remove a
	 reading that was never going to be the fastest."
	rows := OrderedCollection new.
	anExtentCollection do: [ :extent |
		| ofThisExtent |
		ofThisExtent := aVariantNameCollection collect: [ :variant |
			                VGFrameRecordComparisonRow
				                variant: variant
				                extent: extent ].
		ofThisExtent
			detect: [ :each | each partLeftOut isNil ]
			ifFound: [ :whole |
				ofThisExtent do: [ :each |
					each == whole ifFalse: [ each setWholeRow: whole ] ] ].
		rows addAll: ofThisExtent ].
	1 to: passes do: [ :pass |
		rows do: [ :each | each measurePass: pass ] ].
	^ self
]

{ #category : 'initialization' }
VGFrameRecordComparison >> setPasses: aCount [
	passes := aCount
]

{ #category : 'accessing' }
VGFrameRecordComparison >> wholeRows [
	"The row of each extent that leaves nothing out, which is what the verdict is read off."
	^ rows select: [ :each | each partLeftOut isNil ]
]
