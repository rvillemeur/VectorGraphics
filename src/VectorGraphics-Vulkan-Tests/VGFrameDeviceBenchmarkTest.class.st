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
	 nothing."

	VGFrameDeviceBenchmark frameNames do: [ :name |
		| benchmark |
		benchmark := (VGFrameDeviceBenchmark frameName: name) run.
		benchmark isAvailable ifTrue: [
			benchmark measureSoftwareFrame.
			self assert: benchmark hasRun description: name.
			self assert: benchmark pixelsEqual description: name.
			self assert: benchmark deviceMilliseconds > 0 description: name.
			self
				assert: benchmark deviceMilliseconds >= benchmark spirvMilliseconds
				description: name ] ]
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
