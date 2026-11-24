"
I hold VGStrokeRecordBudget and its rows to what they measure: the subject of a row is the stroke the reference frame records, every part of a recording is timed over the same subject, and the whole recording costs at least as much as the dearest part inside it.
I pass two passes where a reading of the real figures passes forty: the facts here are about what is timed, not about how long it takes.
"
Class {
	#name : 'VGStrokeRecordBudgetTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Vulkan-Tests-Tests',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
VGStrokeRecordBudgetTest >> testAPassRecordsOneEntryAShapeHoweverManyPassesHaveRun [
	"A recording appends to the display list of its surface, so a row that kept both the
	 surface and the list would make every pass record against a longer list than the pass
	 before it. The list is reset before the clock starts, which this holds to by counting the
	 entries after two passes: one a shape, not two."

	| row |
	row := VGStrokeRecordBudgetRow
		       subjectNamed: #border
		       extent: VGFrameDeviceBenchmark extentOfItsFrames.
	row
		measurePass: 1;
		measurePass: 2.
	self
		assert: row context surface displayList size
		equals: row shapeBlocks size
]

{ #category : 'tests' }
VGStrokeRecordBudgetTest >> testEveryPartIsTimedOncePerPassOnEveryRow [
	"A pass times every part of every row, so a figure missing from the table is a part that
	 was never measured and not a part that cost nothing. The reading count is the link between
	 the passes asked for and the floors reported."

	| budget |
	budget := VGStrokeRecordBudget
		          overSubjects: { #border. #line }
		          extent: VGFrameDeviceBenchmark extentOfItsFrames
		          passes: 3.
	budget rows do: [ :row |
		VGStrokeRecordBudgetRow measuredParts do: [ :part |
			self assert: (row readingsOf: part) size equals: budget passes ] ]
]

{ #category : 'tests' }
VGStrokeRecordBudgetTest >> testTheBorderRowStrokesTheOutlineTheReferenceCardRecords [
	"The row named for a border strokes the card the reference frame draws twelve of: a rounded
	 rectangle of VGFrameProfile's own extent, corner radius and border width, whose outline is
	 the 224 edges unit 3.13's census counted for one of them. The count is the link between
	 this budget and that census, and it is asked before any figure is timed."

	| row outlines |
	row := VGStrokeRecordBudgetRow
		       subjectNamed: #border
		       extent: VGFrameDeviceBenchmark extentOfItsFrames.
	outlines := row outlines.
	self assert: outlines size equals: 1.
	self assert: (outlines collect: [ :each | each size ]) asArray equals: #( 224 ).
	self
		assert: (outlines collect: [ :each | each fillRule ]) asArray
		equals: #( #winding )
]

{ #category : 'tests' }
VGStrokeRecordBudgetTest >> testTheFrameRowStrokesTheTwelveBordersOfTheReferenceGrid [
	"Twelve borders of 224 edges are the 2688 edges unit 3.13's census found in the reference
	 frame, of the 2740 that frame records in all. The row is the strokes of that frame and
	 nothing else of it, which is why its figure can only move when stroke code moves."

	| row outlines |
	row := VGStrokeRecordBudgetRow
		       subjectNamed: #frame
		       extent: VGFrameDeviceBenchmark extentOfItsFrames.
	outlines := row outlines.
	self assert: outlines size equals: VGFrameProfile referenceCards.
	self
		assert: (outlines inject: 0 into: [ :sum :each | sum + each size ])
		equals: 2688.
	self assert: (outlines allSatisfy: [ :each | each size = 224 ])
]

{ #category : 'tests' }
VGStrokeRecordBudgetTest >> testTheWholeRecordingCostsAtLeastItsDearestPart [
	"The three parts are cut out of the whole recording, so the whole cannot be cheaper than
	 any one of them. Two passes are enough for that: the fact is about what is timed, not
	 about how long it takes."

	| budget |
	budget := VGStrokeRecordBudget
		          overSubjects: { #border }
		          extent: VGFrameDeviceBenchmark extentOfItsFrames
		          passes: 2.
	budget rows do: [ :row |
		VGStrokeRecordBudgetRow timedParts do: [ :part |
			self
				assert: (row floorOf: VGStrokeRecordBudgetRow wholePart)
						>= (row floorOf: part)
				description: part printString , ' read dearer than the whole' ] ]
]
