"
What a frame records, counted rather than timed. One row per frame and surface extent, built by overItsFrames, holding the entries by kind, the geometry and the pixels those entries carry, and how many distinct paints and clips were built for them. Unit 3.13 reads it to say what the recording half of a frame buys for its milliseconds: sixty-three blits taken from the glyph atlas are a different verdict from sixty-three rasterised anew, and only a count tells them apart. I never read a clock — VGFrameRecordComparison times the same frames.
"
Class {
	#name : 'VGFrameRecordCensus',
	#superclass : 'Object',
	#instVars : [
		'rows'
	],
	#category : 'VectorGraphics-Benchmarks-Frames',
	#package : 'VectorGraphics-Benchmarks',
	#tag : 'Frames'
}

{ #category : 'instance creation' }
VGFrameRecordCensus class >> overItsFrames [
	"The census of every frame of the budget, at every extent the budget is measured at. The
	 frames and the extents are asked of VGFrameDeviceBenchmark rather than listed here, so a
	 frame added to the budget is censused with no change to this class.
	 The kit is ours: what is counted is what our own context records, and Cairo records
	 nothing at all."
	| kit built |
	kit := VGFrameDrawingKit ours.
	built := OrderedCollection new.
	VGFrameDeviceBenchmark extentsOfItsCensus do: [ :extent |
		VGFrameDeviceBenchmark frameNames do: [ :each |
			| surface |
			surface := kit surfaceOfExtent: extent.
			(VGFrameDeviceBenchmark drawBlockNamed: each using: kit) value:
				surface newContext.
			built add: (VGFrameRecordCensusRow
					 name: each
					 extent: extent
					 displayList: surface displayList) ] ].
	^ self new
		  setRows: built;
		  yourself
]

{ #category : 'instance creation' }
VGFrameRecordCensus class >> overTheDisplayList: aDisplayList named: aSymbol extent: aPoint [
	"The census of one display list already recorded, which is what a test of the counting
	 builds. The frames of the budget are drawn by overItsFrames instead."
	^ self new
		  setRows: { (VGFrameRecordCensusRow
				   name: aSymbol
				   extent: aPoint
				   displayList: aDisplayList) };
		  yourself
]

{ #category : 'reporting' }
VGFrameRecordCensus class >> rowColumns [
	"The columns a table of my rows shows, as a title and the message that answers it. Written
	 as a table rather than as eleven column expressions, so the view is one loop and the
	 order of the counts is stated once."
	^ {
		  ('Frame' -> #name).
		  ('Extent' -> #extent).
		  ('Entries' -> #entries).
		  ('Fills' -> #fills).
		  ('Blits' -> #blits).
		  ('Masks' -> #distinctBlitSurfaces).
		  ('Edges' -> #segments).
		  ('Coordinates' -> #coordinates).
		  ('Mask pixels' -> #blitPixels).
		  ('Paints' -> #distinctPaints).
		  ('Clips' -> #distinctClips) }
]

{ #category : 'accessing' }
VGFrameRecordCensus >> busiestRow [
	"The row of the frame that records the most entries, which is the one the verdict is about."
	^ rows detectMax: [ :each | each entries ]
]

{ #category : 'inspector' }
VGFrameRecordCensus >> inspectorCensus: aBuilder [
	<inspectorPresentationOrder: 2 title: 'Census'>
	^ aBuilder newTable
		  addColumn:
			  (SpStringTableColumn title: 'What' evaluated: [ :each | each key ]);
		  addColumn:
			  (SpStringTableColumn title: 'Value' evaluated: [ :each | each value ]);
		  items: self reportRows;
		  yourself
]

{ #category : 'inspector' }
VGFrameRecordCensus >> inspectorCensusContext: aContext [
	aContext active: rows isNotNil
]

{ #category : 'inspector' }
VGFrameRecordCensus >> inspectorRows: aBuilder [
	<inspectorPresentationOrder: 1 title: 'Rows'>
	| table |
	table := aBuilder newTable.
	self class rowColumns do: [ :each |
		table addColumn: (SpStringTableColumn title: each key evaluated: [ :row |
				 (row perform: each value) displayString ]) ].
	^ table
		  items: rows;
		  yourself
]

{ #category : 'inspector' }
VGFrameRecordCensus >> inspectorRowsContext: aContext [
	aContext active: rows isNotNil
]

{ #category : 'printing' }
VGFrameRecordCensus >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPut: $(;
		print: rows size;
		nextPutAll: ' rows, busiest ';
		print: self busiestRow;
		nextPut: $)
]

{ #category : 'reporting' }
VGFrameRecordCensus >> reportRows [
	"The census as rows, read off the frame that records the most. The paints and the clips are
	 given against the entries that carry them, because what costs is how many were built and
	 not how many exist: a paint an entry means one was built per entry, and a mask surface
	 blitted several times means the atlas answered."
	| busiest |
	busiest := self busiestRow.
	^ {
		  ('frames' -> rows size printString).
		  ('busiest' -> busiest name).
		  ('entries' -> busiest entries printString).
		  ('fills and blits'
		   -> (busiest fills printString , ' and ' , busiest blits printString)).
		  ('edges' -> busiest segments printString).
		  ('coordinates' -> busiest coordinates printString).
		  ('mask pixels' -> busiest blitPixels printString).
		  ('distinct masks' -> busiest distinctBlitSurfaces printString).
		  ('distinct paints' -> busiest distinctPaints printString).
		  ('distinct clips' -> busiest distinctClips printString) }
]

{ #category : 'accessing' }
VGFrameRecordCensus >> rows [
	^ rows
]

{ #category : 'private' }
VGFrameRecordCensus >> setRows: aCollection [
	rows := aCollection asArray
]
