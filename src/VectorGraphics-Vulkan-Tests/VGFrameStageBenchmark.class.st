"
I am the frame budget of unit 3.0: the same three frames my superclass measures, measured again with every stage of the dispatch timed apart and with Cairo drawing the same picture beside them.
The stages are the ones VGTiledFillDispatch names — the encode, the module, the buffers allocated, the pipeline prepared, the upload, the dispatch itself, the readback and the release — and they are timed inside the frame a tool really draws rather than in a copy of it: the dispatch I measure with is one that was asked to record its stages, and nothing else about the frame differs.
The Cairo figure is measured here and not quoted, through VGFrameDrawingKit's Alexandrie kit, so that one draw method a frame draws both sides. `report` answers the whole table for the three frames in one call, which is what the plan's phase 3 is written against; `stageRows` and `inspectorStages:` show one frame's stages.
"
Class {
	#name : 'VGFrameStageBenchmark',
	#superclass : 'VGFrameDeviceBenchmark',
	#instVars : [
		'dispatch',
		'cairoForm'
	],
	#category : 'VectorGraphics-Vulkan-Tests-Budget',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Budget'
}

{ #category : 'instance creation' }
VGFrameStageBenchmark class >> onTheThreeFrames [
	"Every frame of the budget, measured, cheapest first. This is the one call the gate of unit
	 3.0 asks for: three frames, each with its stages, its Cairo figure and its software figure."

	^ self frameNames collect: [ :each | (self frameName: each) run ]
]

{ #category : 'reporting' }
VGFrameStageBenchmark class >> phaseLabels [
	"My superclass's phases, with the three unit 3.0 adds: the compute context a session creates
	 once, which a frame of a running tool does not pay again, the same dispatch with the stage
	 clock on, and Cairo over the same picture, which is what the whole of phase 3 is measured
	 against. The order is the order a frame pays them, and Cairo sits beside the software path
	 because both are whole frames and neither is a phase of ours."

	^ {
		  (#encode -> 'encode').
		  (#buildSpirv -> 'build SPIR-V, once a session').
		  (#context -> 'create context, once a session').
		  (#dispatch -> 'dispatch').
		  (#stagedFrame -> 'dispatch with the stages timed').
		  (#cairo -> 'Cairo frame').
		  (#software -> 'software frame') }
]

{ #category : 'reporting' }
VGFrameStageBenchmark class >> report [
	"The whole of unit 3.0's gate in one call: the three frames measured, each with its stages
	 and its Cairo figure, and the visit census of each beneath it. The lines are joined with a
	 carriage return built at run time, because this project's source holds no line feed."

	^ String streamContents: [ :stream |
		  self onTheThreeFrames do: [ :benchmark |
			  stream
				  nextPutAll: 'frame ';
				  nextPutAll: benchmark frameName asString;
				  nextPut: Character cr.
			  benchmark reportRows , benchmark census reportRows do: [ :each |
				  stream
					  nextPutAll: '  ';
					  nextPutAll: each key;
					  nextPutAll: ': ';
					  nextPutAll: each value;
					  nextPut: Character cr ] ] ]
]

{ #category : 'accessing' }
VGFrameStageBenchmark >> cairoForm [
	"The picture Cairo drew, kept so that the two frames can be looked at side by side."

	^ cairoForm
]

{ #category : 'accessing' }
VGFrameStageBenchmark >> cairoMilliseconds [
	"What Cairo took over the same picture on this machine, or nil where the frame has not run."

	^ self millisecondsOf: #cairo
]

{ #category : 'accessing' }
VGFrameStageBenchmark >> census [
	"What the kernel would do to the frame I measured, or nil before the frame has been
	 encoded. The census dispatches nothing, so asking costs one walk of the tile table."

	^ encoding ifNotNil: [ VGKernelVisitCensus of: encoding ]
]

{ #category : 'inspector' }
VGFrameStageBenchmark >> inspectorCairoFrame: aBuilder [
	<inspectorPresentationOrder: 30 title: 'Cairo frame'>
	"The picture Cairo drew of the same frame, beside the Device frame tab the benchmark above
	 shows. The Cairo figure of the report is only worth reading if Cairo drew the same picture,
	 and the two tabs are how that is seen rather than asserted."

	^ aBuilder newImage image: cairoForm
]

{ #category : 'inspector' }
VGFrameStageBenchmark >> inspectorCairoFrameContext: aContext [
	"A benchmark whose Cairo frame was not drawn has no picture to show."

	aContext active: cairoForm isNotNil
]

{ #category : 'inspector' }
VGFrameStageBenchmark >> inspectorVisits: aBuilder [
	<inspectorPresentationOrder: 40 title: 'Visits'>
	"The reads the kernel makes of this frame's encoding, which is where the milliseconds of the
	 Benchmark tab go. The rows are the census's own, so the tab says nothing the census does not
	 count."

	^ aBuilder newTable
		  items: self census reportRows;
		  addColumn: (SpStringTableColumn title: 'Count' evaluated: [ :each |
					   each key ]);
		  addColumn:
			  (SpStringTableColumn title: 'Value' evaluated: [ :each |
					   each value ]);
		  yourself
]

{ #category : 'inspector' }
VGFrameStageBenchmark >> inspectorVisitsContext: aContext [
	"A benchmark that has not encoded its frame has nothing to count."

	aContext active: self census isNotNil
]

{ #category : 'measuring' }
VGFrameStageBenchmark >> measureCairoFrame [
	"The same picture drawn by Cairo on this machine, through the Alexandrie kit, so that the
	 gap phase 3 is written about is measured here and not quoted. The surface is built once
	 outside the clock, as our own surface is: what is compared is the drawing of a frame and
	 not the allocation of the pixels it is drawn on. Cairo draws as it is asked rather than
	 recording, so one phase is the whole frame, and the flush is inside it because that is
	 where a pending operation of theirs would be paid."

	| kit surface |
	kit := VGFrameDrawingKit alexandrie.
	surface := kit surfaceOfExtent: self extent.
	milliseconds at: #cairo put: (self millisecondsPerRepeatOf: [
			 (self class drawBlockNamed: frameName using: kit) value:
				 surface newContext.
			 surface flush ]).
	cairoForm := surface asForm.
	^ self
]

{ #category : 'running' }
VGFrameStageBenchmark >> measureStagesOn: aSession [
	"Where the milliseconds of one frame go, measured in a pass of its own: the clock is read
	 twice a stage and those readings would otherwise land inside the dispatch figure my
	 superclass reports, which is the number the plan quotes. The frame is the same one — the
	 same encoding, the same session, the same draw:into: — and only the clock differs.
	 A warm-up frame is drawn and its stages are thrown away, because the first dispatch of a
	 session pays for the first touch of the pages and the warm-up of the pipeline, and that
	 cost would be attributed to whichever stage happened to be first.
	 The pass is timed as a whole as well, because one dispatch of this frame is not the next to
	 a decimal place: the stages are to be read against the frame they were measured in, and
	 the difference between that frame and the clean one above is what the readings cost."

	| target |
	target := ByteArray new:
		          self extent x * self extent y
		          * VGTiledFillEncoding targetFormat bytesPerPixel.
	dispatch := (aSession dispatchForEncoding: encoding) recordStages.
	dispatch draw: encoding into: target.
	dispatch recordStages.
	milliseconds at: #stagedFrame put: (self millisecondsDuring: [
			 repeats timesRepeat: [ dispatch draw: encoding into: target ] ])
		/ repeats.
	^ self
]

{ #category : 'reporting' }
VGFrameStageBenchmark >> reportRows [
	"Everything my superclass reports, and then one row a stage of the dispatch. The stage rows
	 come last because they are the inside of the dispatch row above them, and their labels say
	 so, so that a reader adding the rows up does not count the dispatch twice."

	^ super reportRows , (self stageRows collect: [ :each |
		   'stage ' , each key asString -> (self millisecondStringFor: each value) ])
]

{ #category : 'running' }
VGFrameStageBenchmark >> run [
	"Everything one call of unit 3.0 measures: what the frame costs off the device, what the
	 context of a session costs, the frame on the device, its stages apart, the same frame
	 through Cairo and the same frame through the software path. The Cairo and the software
	 frames are measured whether a device answered or not, because the gap between them is the
	 reason phase 3 exists and a machine with no driver can still report it.
	 The context row is the cost of opening the device of a session, measured on a session of my
	 own: unit 3.1 made it a cost a tool pays once and not once a frame, which is only visible
	 where the opening is timed apart from the frames."

	| session |
	self measureEncoding.
	session := nil.
	milliseconds
		at: #context
		put: (self millisecondsDuring: [ session := self newSession ]).
	session
		ifNil: [ milliseconds removeKey: #context ]
		ifNotNil: [
			[
			[
			self measureOn: session.
			self measureStagesOn: session ]
				on: Error
				do: [ :each | unavailableReason := self reasonFrom: each ] ] ensure: [
				session releaseDevice ] ].
	self measureCairoFrame.
	self measureSoftwareFrame.
	^ self
]

{ #category : 'accessing' }
VGFrameStageBenchmark >> stageMilliseconds [
	"What each stage of one frame cost, in milliseconds, keyed by the stage names
	 VGTiledFillDispatch gives them. Empty until the frame has been measured on a device."

	dispatch ifNil: [ ^ Dictionary new ].
	^ dispatch stageMicroseconds collect: [ :each |
		  (each / repeats / VGVulkanRoundTrip microsecondsPerMillisecond) asFloat ]
]

{ #category : 'reporting' }
VGFrameStageBenchmark >> stageRows [
	"One row a stage the dispatch reached, in the order a frame pays them, each the stage name
	 and its milliseconds. A stage the frame never reached is left out, which is what an empty
	 frame answers for everything after the encode."

	| measured |
	measured := self stageMilliseconds.
	^ (VGTiledFillDispatch stageNames select: [ :each |
		   measured includesKey: each ]) collect: [ :each |
		  each -> (measured at: each) ]
]

{ #category : 'accessing' }
VGFrameStageBenchmark >> stagedFrameMilliseconds [
	"What one frame of the stage pass cost as a whole, which is what the stages are to add up
	 to. It is above the dispatch figure by whatever the clock readings cost."

	^ self millisecondsOf: #stagedFrame
]
