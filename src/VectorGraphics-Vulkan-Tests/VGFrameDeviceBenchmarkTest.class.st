"
I hold the facts of the whole frame measurement of unit 2.4a: that every frame the benchmark measures really is inside the subset the device draws, that a run records a time and the counts of the frame it encoded, that the device draws on an eight hundred by six hundred frame what the software backend draws on it, and that the census of the reference frame agrees with the rasteriser about every entry of it.
The timings themselves are not asserted: a measurement is not a fact about the code, and a machine with no device still has to pass.
"
Class {
	#name : 'VGFrameDeviceBenchmarkTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Vulkan-Tests-Tests',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Tests'
}

{ #category : 'accessing' }
VGFrameDeviceBenchmarkTest >> defaultTimeLimit [
	"testEveryFrameOfTheBenchmarkDrawsOnTheDeviceWhatTheSoftwareBackendDraws runs every frame
	 of the benchmark on the device and then draws each one again in software to compare the
	 pixels, which is 14.1 s on this machine against the ten seconds SUnit allows a test. The
	 rest of the class stays under 5 s, but it is the class that owns the budget, so the budget
	 is declared once here. Without this a run reports TestTookTooMuchTime, with no message and
	 no stack, where it should report which frame differs."

	^ 2 minutes
]

{ #category : 'tests' }
VGFrameDeviceBenchmarkTest >> testABenchmarkThatHasNotRunCarriesNoTimeAtAll [
	"The degenerate state. A benchmark names its frame as soon as it is built, so the report has
	 rows to show, and it carries no time and no verdict about the pixels until it is run."

	| benchmark |
	benchmark := VGFrameDeviceBenchmark onTheCardsFrame.
	self deny: benchmark hasRun.
	self assert: benchmark deviceMilliseconds isNil.
	self assert: benchmark softwareMilliseconds isNil.
	self assert: benchmark pixelsEqual isNil.
	self deny: benchmark reportRows isEmpty
]

{ #category : 'tests' }
VGFrameDeviceBenchmarkTest >> testAFrameTheBenchmarkDoesNotKnowIsRefusedRatherThanMeasured [
	"A name the benchmark does not hold a frame for is an error and not an empty frame: an empty
	 frame touches no tile, dispatches nothing and would be reported as the fastest measurement
	 of the set."

	self
		should: [ VGFrameDeviceBenchmark drawBlockNamed: #noFrameOfThisName ]
		raise: Error
]

{ #category : 'tests' }
VGFrameDeviceBenchmarkTest >> testEncodingAFrameRecordsTheCountsOfTheFrameItEncoded [
	"Everything but the dispatch is measured without a device, so a machine with no driver still
	 reports what the frame weighs. The cards frame holds one entry for the background and two
	 for every card, which is its gradient fill and its stroked border, and an entry that spans a
	 tile boundary is binned into every tile it spans, so the binned count is the larger of the
	 two."

	| benchmark |
	benchmark := VGFrameDeviceBenchmark onTheCardsFrame measureEncoding.
	self
		assert: benchmark entryCount
		equals: VGFrameProfile referenceCards * 2 + 1.
	self assert: benchmark binnedEntryCount >= benchmark entryCount.
	self assert: benchmark touchedTileCount > 0.
	self assert: benchmark encodeMilliseconds > 0.
	self assert: benchmark spirvMilliseconds > 0.
	self deny: benchmark hasRun
]

{ #category : 'tests' }
VGFrameDeviceBenchmarkTest >> testEveryEntryOfTheFrameIsCountedUnderOneReasonOnly [
	"A count that loses an entry, or counts one twice, would understate what the device is
	 missing, which is the only thing this census is read for."

	| census counted |
	census := VGTiledFillSupportCensus onTheReferenceFrame.
	counted := census countByReason values inject: 0 into: [ :sum :each |
		           sum + each ].
	self assert: counted equals: census entries size.
	self
		assert: census supportedCount + census refusedCount
		equals: census entries size.
	census countByReason keysDo: [ :reason |
		self assert:
			((VGTiledFillSupportCensus refusalReasons includes: reason) or: [
				 reason = VGTiledFillSupportCensus supportedReason ]) ]
]

{ #category : 'tests' }
VGFrameDeviceBenchmarkTest >> testEveryFrameOfTheBenchmarkDrawsOnTheDeviceWhatTheSoftwareBackendDraws [
	"The gate of this measurement. A window sized frame is two hundred times the area of a
	 conformance case and its grid is nineteen hundred tiles, each dispatched as its own
	 workgroup, so an error in the tile table shows here and in nothing unit 2.3 gated.
	 The software side of each frame costs a second or two, which is the measurement itself and
	 not an overhead of the test. A machine with no device has nothing to compare and holds
	 nothing.
	 The dispatch is not held against the SPIR-V build: measureEncoding builds that module
	 outside the cache on purpose, to report what a session pays once, so the two numbers
	 compare a warm resident frame with a cold build and state the ratio of this machine's
	 device to its own compiler rather than a fact about the frame. On this machine the cheap
	 frames dispatch in less time than their module takes to build."

	VGFrameDeviceBenchmark frameNames do: [ :name |
		| benchmark |
		benchmark := (VGFrameDeviceBenchmark frameName: name) run.
		benchmark isAvailable ifTrue: [
			benchmark measureSoftwareFrame.
			self assert: benchmark hasRun description: name.
			self assert: benchmark pixelsEqual description: name.
			self assert: benchmark deviceMilliseconds > 0 description: name ] ]
]

{ #category : 'tests' }
VGFrameDeviceBenchmarkTest >> testEveryFrameTheBenchmarkMeasuresIsDrawnEntirelyByTheDeviceSubset [
	"The benchmark compares the device with the software path on the same picture, so a frame
	 holding one entry the device refuses would be measured on the software path twice over. Each
	 named frame is drawn on a recording surface and every entry of it is offered to the
	 rasteriser, which is the predicate the dispatch itself asks."

	| extent |
	extent := VGFrameDeviceBenchmark extentOfItsFrames.
	VGFrameDeviceBenchmark frameNames do: [ :name |
		| surface |
		surface := VGCairoImageSurface extent: extent.
		(VGFrameDeviceBenchmark drawBlockNamed: name) value: surface newContext.
		self deny: surface displayList entries isEmpty description: name.
		surface displayList entries do: [ :entry |
			self
				assert: (VGTiledFillRasteriser supportsEntry: entry)
				description: name ] ]
]

{ #category : 'tests' }
VGFrameDeviceBenchmarkTest >> testEveryGlyphOfTheReferenceFrameIsNowInTheSubset [
	"Sixty three of the eighty eight entries of the profiled frame are glyph blits, and each of
	 them is clipped to the rounded rectangle of its card. Unit 2.6 took the kind of an entry
	 out of the refusals and unit 2.7 took the shape of a clip out of them, so these sixty three
	 are the measure of both: a glyph of that frame is now drawn by the device through its own
	 mask inside a clip that is not a rectangle."

	| census blits |
	census := VGTiledFillSupportCensus onTheReferenceFrame.
	blits := census entries select: [ :each | each isKindOf: VGBlitEntry ].
	self deny: blits isEmpty.
	blits do: [ :each |
		self deny: each clip isRectangular.
		self
			assert: (census reasonFor: each)
			equals: VGTiledFillSupportCensus supportedReason ]
]

{ #category : 'tests' }
VGFrameDeviceBenchmarkTest >> testEveryPhaseTheDrawingTimesIsOnePhaseItNames [
	"The drawing table is the only place a phase of the drawing is named, so the names in it and
	 the names the drawing times have to be the same set. A phase timed under a name no table
	 holds would be measured and never reported; a name in the table that nothing times would be
	 reported as missing on every frame.
	 The source is read rather than a measured frame, because a phase a frame never reaches —
	 the canvas and the scene of a frame that draws on a context — is absent from that frame's
	 table and present in the code all the same."

	| timed |
	timed := Set new.
	(VGFrameDeviceBenchmark methods , VGFrameDeviceBenchmark class methods) do: [
		:method |
		method ast sendNodes do: [ :send |
			send selector = #timeDrawing:into:during: ifTrue: [
				self assert: send arguments first isLiteralNode.
				timed add: send arguments first value ] ] ].
	self assert: VGFrameDeviceBenchmark drawingStageNames asSet equals: timed
]

{ #category : 'tests' }
VGFrameDeviceBenchmarkTest >> testTheCensusAgreesWithTheRasteriserAboutEveryEntryOfTheFrame [
	"The census names a reason by walking the clauses of the rasteriser predicate in its own
	 order, so the one thing that may never differ is the verdict: an entry carries the supported
	 reason exactly when the rasteriser accepts it."

	| census |
	census := VGTiledFillSupportCensus onTheReferenceFrame.
	self deny: census entries isEmpty.
	census entries do: [ :entry |
		self
			assert: (census reasonFor: entry) = VGTiledFillSupportCensus supportedReason
			equals: (VGTiledFillRasteriser supportsEntry: entry) ]
]

{ #category : 'tests' }
VGFrameDeviceBenchmarkTest >> testTheCensusCountsThePixelsBehindEveryReasonItNames [
	"An entry count says how many things the device refuses and a pixel count says how much of
	 the frame they cover, which are different questions: sixty three glyph blits cover a
	 thousandth of what one clipped card fill covers. Every reason the census names covers
	 pixels, and no reason it does not name is counted."

	| census |
	census := VGTiledFillSupportCensus onTheReferenceFrame.
	self
		assert: census pixelsByReason keys asSet
		equals: census countByReason keys asSet.
	census pixelsByReason valuesDo: [ :pixels | self assert: pixels > 0 ]
]

{ #category : 'tests' }
VGFrameDeviceBenchmarkTest >> testTheDrawingOfEveryFrameIsMeasuredPhaseByPhase [
	"Unit 3.11 asks where the drawing of a frame goes, the pose of the font manager having left
	 4.1 ms of it on the reference frame. Every phase a frame times is one the table names, and
	 a phase the frame does not reach is absent rather than zero: only the reference frame
	 builds a canvas and a scene, the other two drawing on the context the surface answers."

	| names |
	names := VGFrameDeviceBenchmark drawingStageNames asSet.
	VGFrameDeviceBenchmark frameNames do: [ :each |
		| benchmark measured |
		benchmark := VGFrameDeviceBenchmark
			             frameName: each
			             repeats: 2
			             extent: 400 @ 300.
		benchmark measureDisplayList.
		measured := ((benchmark timings insideOf: #encode) insideOf: #displayList) means
			            keys asSet.
		self assert: (measured includesAll: #( surface record )).
		self assert: (names includesAll: measured).
		self
			assert: (measured includesAll: #( canvas scene ))
			equals: each = #reference ]
]

{ #category : 'tests' }
VGFrameDeviceBenchmarkTest >> testTheOutcomeOfADrawnFrameNamesTheDeviceAndWhetherThePixelsMatch [
	"The other outcome: a device drew, so the rows name it and say whether what came back is
	 the picture the software path draws. The comparison is the outcome's own, because the two
	 pictures are what it holds and nothing else needs the software one."

	| outcome drawn |
	drawn := Form extent: 2 @ 2 depth: 32.
	drawn fillColor: Color red.
	outcome := VGDeviceOutcome new
		           deviceName: 'llvmpipe';
		           form: drawn;
		           yourself.
	self assert: outcome isAvailable.
	self assert: (outcome rows includes: 'device' -> 'llvmpipe').
	self assert: outcome pixelsEqual isNil.
	outcome compareWith: drawn deepCopy.
	self assert: outcome pixelsEqual.
	self assert: (outcome rows includes: 'same pixels' -> 'true').
	outcome compareWith: (Form extent: 2 @ 2 depth: 32).
	self deny: outcome pixelsEqual
]

{ #category : 'tests' }
VGFrameDeviceBenchmarkTest >> testTheOutcomeOfAMachineWithNoDeviceIsTheReasonItGave [
	"What a benchmark answers about the device half when no device drew: the outcome is not
	 available, it has no picture, and its rows say none and why instead of naming a device."

	| outcome |
	outcome := VGDeviceOutcome new.
	self assert: outcome isAvailable.
	outcome unavailableReason: 'no libvulkan.so.1 on this machine'.
	self deny: outcome isAvailable.
	self assert: outcome form isNil.
	self
		assert: outcome rows
		equals: {
				'device' -> 'none'.
				'reason' -> 'no libvulkan.so.1 on this machine' }
]

{ #category : 'tests' }
VGFrameDeviceBenchmarkTest >> testThePhasesInsideAPhaseAreTimingsOfTheirOwn [
	"A stage of a frame can be taken apart, and what it is made of is timings of the same kind:
	 that is how the encode of a frame carries the eleven phases of the host half under it. The
	 inside of a phase is the same object every time it is asked for, so a loop that reads a
	 phase table into it does not throw the readings of the pass before away."

	| timings inside |
	timings := VGStageTimings new.
	timings add: 5000 of: #encode.
	inside := timings insideOf: #encode.
	inside add: 2000 of: #bin.
	(timings insideOf: #encode) add: 4000 of: #bin.
	self assert: (timings insideOf: #encode) == inside.
	self assert: inside means equals: (Dictionary newFrom: { #bin -> 3 }).
	self assert: inside floors equals: (Dictionary newFrom: { #bin -> 2 }).
	self assert: (timings meanOf: #encode) equals: 5.
	self assert: timings means equals: (Dictionary newFrom: { #encode -> 5 })
]

{ #category : 'tests' }
VGFrameDeviceBenchmarkTest >> testThePhasesOfEveryDrawnFrameAccountForItsDrawing [
	"What the phases of a drawing are read for is where its milliseconds go, so they have to be
	 most of it. Nine tenths, which leaves room for the sends between the phases and for the
	 clock itself.
	 Measured inside one pass — the phases of a drawing against the clock around that same
	 drawing — and asserted on the best of five, because the fastest pass of a phase is not the
	 fastest pass of the whole and a pass that met the garbage collector carries work no phase
	 is measuring. That is the fault unit 3.10's own accounting gate was rewritten for."

	VGFrameDeviceBenchmark frameNames do: [ :each |
		| benchmark best |
		benchmark := VGFrameDeviceBenchmark
			             frameName: each
			             repeats: 1
			             extent: 400 @ 300.
		benchmark newSurface.
		best := 0.
		5 timesRepeat: [
			| phases taken sum |
			phases := VGStageTimings new.
			taken := benchmark microsecondsDuring: [
				         benchmark newSurfaceOnBackend: nil recordingInto: phases ].
			sum := phases means values inject: 0 into: [ :total :one | total + one ].
			best := best max: sum / (phases millisecondsOfMicroseconds: taken) ].
		self
			assert: best > (9 / 10)
			description: each asString , ': ' , best printString
				, ' of the drawing is accounted for' ]
]

{ #category : 'tests' }
VGFrameDeviceBenchmarkTest >> testTheReferenceFrameIsDrawnEntirelyByTheDeviceSubset [
	"What unit 2.7 bought, and the one fact of this unit that is about a real picture rather
	 than a corpus case: every one of the eighty eight entries of the profiled frame is in the
	 subset, so the frame goes to the device whole. Failover is a whole frame at a time, and
	 until this unit one refused entry sent all of it to software: the clip of a card is a
	 rounded rectangle, and the glyphs of its label are clipped to the same shape."

	| census |
	census := VGTiledFillSupportCensus onTheReferenceFrame.
	self assert: census isFrameSupported.
	self assert: census refusedCount equals: 0.
	self assert: census supportedCount equals: census entries size
]

{ #category : 'tests' }
VGFrameDeviceBenchmarkTest >> testTimingsKeepTheMeanAndTheFloorOfEveryReadingOfAPhase [
	"The four parallel tables a benchmark kept — a total and a fastest pass, for the stages of a
	 frame and for the phases inside its encode — are one object, which is the only thing that
	 knows a reading is in microseconds and a report is in milliseconds. A stage nothing was
	 read for answers nil rather than zero, since nought milliseconds is a measurement and no
	 measurement is not, and a stage read once has no floor for the same reason."

	| timings |
	timings := VGStageTimings new.
	timings add: 1000 of: #bin.
	timings add: 3000 of: #bin.
	timings add: 4000 of: #software.
	self assert: (timings meanOf: #bin) equals: 2.
	self assert: (timings floorOf: #bin) equals: 1.
	self assert: (timings meanOf: #software) equals: 4.
	self assert: (timings floorOf: #software) equals: nil.
	self assert: (timings meanOf: #writeTiles) equals: nil.
	self assert: (timings floorOf: #writeTiles) equals: nil
]

{ #category : 'tests' }
VGFrameDeviceBenchmarkTest >> testWholeFrameMillisecondsIsEncodeAndDispatchTogether [
	"The cost a caller of this project actually pays for a frame: building the encoding and
	 then draining it. Cairo pays no separate encoding phase, so comparing its figure with the
	 dispatch alone would understate what this project costs against it, which is why unit 3.6
	 reads this number and not the dispatch figure on its own.
	 A benchmark that has not run has encoded nothing and dispatched nothing, so it answers nil
	 rather than a sum with a hole in it."
	| benchmark |
	benchmark := VGFrameDeviceBenchmark onTheCardsFrame.
	self assert: benchmark wholeFrameMilliseconds isNil.
	benchmark run.
	benchmark isAvailable ifTrue: [
		self
			assert: benchmark wholeFrameMilliseconds
			equals: benchmark encodeMilliseconds + benchmark deviceMilliseconds ]
]
