"
I hold the facts of unit 3.0's stage measurement: that the stages the dispatch times are the stages it names, that a dispatch records nothing until it is asked to, that the stages of a frame add up to the frame it measured, and that the Cairo figure the report carries is measured on this machine on the same picture.
The timings themselves are not asserted, as in VGFrameDeviceBenchmarkTest: a measurement is not a fact about the code, and a machine with no device has to pass.
"
Class {
	#name : 'VGFrameStageBenchmarkTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Vulkan-Tests-Tests',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Tests'
}

{ #category : 'reading' }
VGFrameStageBenchmarkTest >> collectTimedStagesOf: aSelector into: aCollection seen: aSet [
	"The stages of that method of the dispatch added to the collection in the order its source
	 pays them, then the stages of every method of the dispatch it sends. A method already
	 walked is not walked again."

	(aSet includes: aSelector) ifTrue: [ ^ self ].
	aSet add: aSelector.
	(VGTiledFillDispatch >> aSelector) ast sendNodes do: [ :each |
		each selector = #timeStage:during:
			ifTrue: [ aCollection add: each arguments first value ]
			ifFalse: [
				(VGTiledFillDispatch includesSelector: each selector) ifTrue: [
					self
						collectTimedStagesOf: each selector
						into: aCollection
						seen: aSet ] ] ]
]

{ #category : 'accessing' }
VGFrameStageBenchmarkTest >> defaultTimeLimit [
	"Every test here measures a frame, and a measured frame is drawn: the stage census draws
	 one software frame a frame name and the two comparisons draw two, at the frame's own
	 extent. On this machine that is 12.2 s for testEveryFrameOfTheBudgetIsDrawnByEitherKit,
	 11.4 s for testEveryFrameOfTheBudgetCarriesACairoFigureMeasuredHere and 9.4 s for
	 testTheCairoKitDrawsThePictureOursDraws, against the ten seconds SUnit allows a test.
	 Without this a run reports TestTookTooMuchTime, with no message and no stack, where it
	 should report which kit draws the wrong picture — and it reports it only under the managed
	 runner, so the same test passes when replayed with runCase and the red looks transient."

	^ 2 minutes
]

{ #category : 'tests' }
VGFrameStageBenchmarkTest >> testABenchmarkThatHasNotRunCarriesNoStageAtAll [
	"The degenerate state. A stage benchmark names its frame when it is built, as its superclass
	 does, and carries no stage, no Cairo figure and no verdict about the pixels until it is
	 run."

	| benchmark |
	benchmark := VGFrameStageBenchmark onTheBackgroundFrame.
	self deny: benchmark hasRun.
	self assert: benchmark stageMilliseconds isEmpty.
	self assert: benchmark cairoMilliseconds isNil.
	self assert: benchmark stageRows isEmpty.
	self deny: benchmark reportRows isEmpty
]

{ #category : 'tests' }
VGFrameStageBenchmarkTest >> testADispatchRecordsNoStageUntilItIsAskedTo [
	"The clock is read twice a stage, and a frame of a running tool pays for nothing it does not
	 ask for. So a dispatch records no stage until a caller asks it to, and the stages of one
	 that was not asked are empty rather than nought: nought would read as a stage that cost
	 nothing."

	| dispatch |
	dispatch := VGTiledFillDispatch new.
	self assert: dispatch stageMicroseconds isEmpty.
	self deny: dispatch isRecordingStages.
	self assert: dispatch recordStages isRecordingStages
]

{ #category : 'tests' }
VGFrameStageBenchmarkTest >> testARecordingDispatchOfAFrameWithNoTileTimesItsEncodeAndNothingElse [
	"The degenerate frame, which asks nothing of a device: the encode is paid and timed, and
	 every later stage is not reached and therefore not named. A stage that was reached and
	 cost less than a microsecond is still named, with nought beside it, which is why the
	 absence of a name and a time of nought say different things here."

	| extent surface encoding target dispatch |
	extent := 32 @ 32.
	surface := VGCairoImageSurface extent: extent.
	surface newContext
		rectangleX: extent x + 10 y: extent y + 10 width: 10 height: 10;
		fill.
	encoding := VGTiledFillEncoding of: surface displayList extent: extent.
	target := ByteArray new:
		          extent x * extent y * VGTiledFillEncoding targetFormat bytesPerPixel.
	dispatch := VGTiledFillDispatch new recordStages.
	self assert: encoding touchedTileCount equals: 0.
	dispatch draw: encoding into: target.
	self
		assert: dispatch stageMicroseconds keys asArray
		equals: { VGTiledFillDispatch stageNames first }.
	self assert: (dispatch microsecondsOfStage: VGTiledFillDispatch stageNames first) >= 0
]

{ #category : 'tests' }
VGFrameStageBenchmarkTest >> testEveryClassOfAKitIsNamedByTheRoleItPlays [
	"A kit answers its classes in the order a frame meets them, and the inspector labels them
	 with that order. The labels are the slots the classes are held in, with the word Class taken
	 off, so a slot renamed or a fifth class added relabels the view and cannot leave it naming
	 the wrong class."

	VGFrameDrawingKit slotNames
		with: VGFrameDrawingKit ours classesByRole
		do: [ :slot :pair |
			self assert: pair key equals: (slot copyReplaceAll: 'Class' with: '') ].
	self
		assert: (VGFrameDrawingKit ours classesByRole collect: [ :each | each value ])
		equals: VGFrameDrawingKit ours classes.
	self
		assert: (VGFrameDrawingKit ours classesByRole collect: [ :each | each key ])
		equals: (VGFrameDrawingKit alexandrie classesByRole collect: [ :each |
				 each key ])
]

{ #category : 'tests' }
VGFrameStageBenchmarkTest >> testEveryEncodePhaseOfEveryFrameIsMeasuredAtBothExtentsAsAMeanAndAMinimum [
	"The census of unit 3.10: every frame of the budget, at the extent phase 3 quotes and at the
	 extent of a full screen, with every phase of its host half measured. A phase is reported as
	 a mean and as a minimum, because the means of the earlier units are what the plan quotes and
	 the floor is what a decision about a lever is read off: a mean carries the garbage collector
	 and the scheduler of whichever pass met them, and the minimum is the work itself.
	 Only the encode is measured here, so the gate needs no device, no Cairo frame and no
	 software frame. Three repeats, because a minimum needs more than one pass and the encode of
	 a full screen is tens of milliseconds."

	| extents |
	extents := VGFrameStageBenchmark extentsOfItsCensus.
	self assert: extents size equals: 2.
	VGFrameStageBenchmark frameNames do: [ :name |
		extents do: [ :extent |
			| benchmark means minimums |
			benchmark := (VGFrameStageBenchmark
				              frameName: name
				              repeats: 3
				              extent: extent) measureEncoding.
			means := benchmark encodePhaseRows.
			minimums := benchmark minimumEncodePhaseMilliseconds.
			self
				assert: (means collect: [ :each | each key ]) asArray
				equals: VGTiledFillEncoding stageNames.
			means do: [ :each |
				self
					assert: (minimums at: each key) <= each value
					description: name asString , ' at ' , extent printString , ': '
						, each key asString ] ] ]
]

{ #category : 'tests' }
VGFrameStageBenchmarkTest >> testEveryFrameOfTheBudgetCarriesACairoFigureMeasuredHere [
	"The number phase 3 is held to. Cairo draws every frame of the budget on this machine in
	 this session, so the gap the plan quotes is a measurement and not a figure carried over
	 from unit 1.11, and it is measured on the picture the other backends drew."

	VGFrameStageBenchmark onTheThreeFrames do: [ :benchmark |
		self assert: benchmark cairoMilliseconds > 0 description: benchmark frameName.
		self
			assert: benchmark cairoMilliseconds < benchmark softwareMilliseconds
			description: benchmark frameName.
		self
			assert: benchmark cairoForm extent
			equals: VGFrameDeviceBenchmark extentOfItsFrames ]
]

{ #category : 'tests' }
VGFrameStageBenchmarkTest >> testEveryFrameOfTheBudgetIsDrawnByEitherKit [
	"One draw method a frame, two kits, three frames. The frames are drawn here on small
	 surfaces rather than measured, because what is asserted is that the Cairo side draws at all
	 and draws something: a frame of the report that came back blank would otherwise read as
	 Cairo drawing the picture in no time."

	{
		VGFrameDrawingKit ours.
		VGFrameDrawingKit alexandrie } do: [ :kit |
		VGFrameDeviceBenchmark frameNames do: [ :name |
			| surface |
			surface := kit surfaceOfExtent:
				           VGFrameDeviceBenchmark extentOfItsFrames.
			(VGFrameDeviceBenchmark drawBlockNamed: name using: kit) value:
				surface newContext.
			surface flush.
			self
				assert: surface asForm extent
				equals: VGFrameDeviceBenchmark extentOfItsFrames.
			self
				deny: (surface asForm bits allSatisfy: [ :each | each = 0 ])
				description: name ] ]
]

{ #category : 'tests' }
VGFrameStageBenchmarkTest >> testEveryPairOfTheTwoKitsIsHeldByTheNameMapOrByTheHierarchy [
	"How a pair is held is what the inspector shows and what the pairing test asks, so the kit
	 answers it once and both read it. Every pair of the two kits is held one way or the other,
	 and two classes that are not a pair are held by neither."

	VGFrameDrawingKit ours classes
		with: VGFrameDrawingKit alexandrie classes
		do: [ :our :their |
			self
				deny: (VGFrameDrawingKit ours pairingOf: our with: their) isNil
				description: our name , ' is not paired with ' , their name ].
	self
		assert: (VGFrameDrawingKit ours
				 pairingOf: VGCairoImageSurface
				 with: AeCanvas)
		equals: nil
]

{ #category : 'tests' }
VGFrameStageBenchmarkTest >> testEveryPhaseTheEncodingTimesIsOnePhaseItNames [
	"The phase table is the only place a phase of the host half is named, so the names in it and
	 the names the encoding times have to be the same set. A phase timed under a name no table
	 holds would be measured and never reported; a name in the table that nothing times would be
	 reported as missing on every frame.
	 The source is read rather than a measured frame, because a phase a frame never reaches —
	 the pixels of a frame that paints out of nothing — is absent from that frame's table and
	 present in the code all the same.
	 displayList is timed by the benchmark and not by the encoding, since the list is drawn
	 before an encoding holds anything, so it is expected in the table, and in the benchmark's
	 source, and not in the encoding's."

	| timed |
	timed := Set new.
	VGTiledFillEncoding selectorsAndMethodsDo: [ :selector :method |
		method ast sendNodes do: [ :send |
			send selector = #timeStage:during: ifTrue: [
				self assert: send arguments first isLiteralNode.
				timed add: send arguments first value ] ] ].
	self
		assert: (VGTiledFillEncoding stageNames copyWithout: #displayList) asSet
		equals: timed.
	self assert: (VGFrameDeviceBenchmark methods anySatisfy: [ :each |
			 each ast allChildren anySatisfy: [ :node |
				 node isLiteralNode and: [ node value = #displayList ] ] ])
]

{ #category : 'tests' }
VGFrameStageBenchmarkTest >> testEveryStageTheDispatchTimesIsOneItNames [
	"The table of stage names and the dispatch cannot drift: every stage the dispatch wraps a
	 block in is read out of its own source here, in the order a frame pays them, and a stage
	 named in the table and timed nowhere would be a row of the report that no code fills.
	 A stage is timed either in the frame method itself or in the one method of the dispatch
	 that it sends for that step, so the order is the order of the steps and not of the method
	 dictionary.
	 The last two stages belong to one kind of frame each, which is why two frames are walked:
	 the frame whose pixels the host reads pays every stage but the copy, and the frame that
	 ends on the device is the only one that pays it."

	| readBack onDevice |
	readBack := self timedStagesOf: #draw:into:readBack:.
	onDevice := self timedStagesOf: #draw:endingIn:.
	self
		assert: readBack
		equals: (VGTiledFillDispatch stageNames reject: [ :each | each = #copy ]).
	self assert: (onDevice includes: #copy).
	self deny: (readBack includes: #copy).
	self
		assert: (readBack , onDevice) asSet
		equals: VGTiledFillDispatch stageNames asSet.
	self assert: readBack asSet size equals: readBack size
]

{ #category : 'tests' }
VGFrameStageBenchmarkTest >> testNeitherKitNamesAClassOfTheOtherSide [
	"Which side a kit draws with has to be visible in the kit and nowhere else, because the
	 Cairo figure of the report is only worth reading if the Cairo frame was drawn by
	 Alexandrie throughout. A class of ours in the Cairo kit would measure this project and
	 call it Cairo."

	VGFrameDrawingKit ours classes do: [ :each |
		self
			assert: (each package name beginsWith: 'VectorGraphics')
			description: each name ].
	VGFrameDrawingKit alexandrie classes do: [ :each |
		self
			deny: (each package name beginsWith: 'VectorGraphics')
			description: each name ]
]

{ #category : 'tests' }
VGFrameStageBenchmarkTest >> testSlowerThanCairoByIsTheWholeFrameOverCairo [
	"The one ratio unit 3.6 is read for: how many times the whole frame this project pays costs
	 what the same picture costs Cairo, measured here and not quoted from an earlier unit.
	 Nil while either side is unmeasured, so a report never divides by nothing."
	| benchmark |
	benchmark := VGFrameStageBenchmark onTheCardsFrame.
	self assert: benchmark slowerThanCairoBy isNil.
	benchmark run.
	benchmark isAvailable ifTrue: [
		self
			assert: benchmark slowerThanCairoBy
			equals: benchmark wholeFrameMilliseconds / benchmark cairoMilliseconds.
		self assert: ((benchmark reportRows collect: [ :each | each key ]) asArray
			includes: 'slower than Cairo by') ]
]

{ #category : 'tests' }
VGFrameStageBenchmarkTest >> testTheCairoKitDrawsThePictureOursDraws [
	"The Cairo figure of the report is only a comparison if both sides drew one picture. The
	 background and the cards frames come out byte for byte the same on either side, which is
	 the strict form of that. The reference frame differs on 5175 pixels, just over one in a
	 hundred: 3975 of them in the three label bands, where a glyph is rasterised by the backend
	 that draws it and the two atlases are not the same bytes, and 1200 on the rounded corners
	 of the cards, which no other frame draws and which differ by no more than 52 of 255. Every
	 pixel farther than 200 is a glyph stem. So the budget is two in a hundred, which still
	 holds the frame to its picture: a label measured on the wrong backend, or missing, differs
	 by far more than that.
	 The frames are drawn at their own extent, so this test costs two software frames a frame
	 name and is the slowest of this class."

	| extent allowed |
	extent := VGFrameDeviceBenchmark extentOfItsFrames.
	allowed := Dictionary newFrom: {
			           (#background -> 0).
			           (#cards -> 0).
			           (#reference -> (extent x * extent y * 2 / 100)) }.
	VGFrameDeviceBenchmark frameNames do: [ :name |
		| ours theirs comparison |
		ours := VGFrameDrawingKit ours surfaceOfExtent: extent.
		ours backend: VGBackend failover.
		(VGFrameDeviceBenchmark drawBlockNamed: name using: VGFrameDrawingKit ours)
			value: ours newContext.
		ours flush.
		theirs := VGFrameDrawingKit alexandrie surfaceOfExtent: extent.
		(VGFrameDeviceBenchmark
			 drawBlockNamed: name
			 using: VGFrameDrawingKit alexandrie) value: theirs newContext.
		theirs flush.
		comparison := VGFormComparison between: ours asForm and: theirs asForm.
		self assert: comparison isComparable description: name.
		self assert: comparison maximumStrayAlpha equals: 0.
		self
			assert: (comparison pixelsFartherThan: 1) <= (allowed at: name)
			description: name , ' differs on '
				, (comparison pixelsFartherThan: 1) printString , ' pixels' ]
]

{ #category : 'tests' }
VGFrameStageBenchmarkTest >> testTheCounterpartOfEitherKitIsTheOtherKit [
	"A kit knows which side it draws with, and it knows it by where its classes come from rather
	 than by which class message built it: that is the one rule the inspector and the test share.
	 So the counterpart of ours is the Cairo kit, the counterpart of the Cairo kit is ours, and
	 asking twice comes back where it started."

	self assert: VGFrameDrawingKit ours isOurs.
	self deny: VGFrameDrawingKit alexandrie isOurs.
	self deny: VGFrameDrawingKit ours counterpart isOurs.
	self assert: VGFrameDrawingKit alexandrie counterpart isOurs.
	self
		assert: VGFrameDrawingKit ours counterpart counterpart classes
		equals: VGFrameDrawingKit ours classes
]

{ #category : 'tests' }
VGFrameStageBenchmarkTest >> testTheKitOfThisProjectNamesTheCounterpartOfEveryClassTheCairoKitNames [
	"The two kits are what lets one draw method draw the frame twice, once with our classes and
	 once with Alexandrie's. They are held to each other by the corpus's own name map and by the
	 hierarchy rather than by a list written here: a Cairo class of ours is the corpus's
	 counterpart of theirs, and a canvas or a renderer of ours is a subclass of theirs."

	| map ours theirs |
	map := Dictionary newFrom: VGAlexandrieCorpus classNameMap.
	ours := VGFrameDrawingKit ours classes.
	theirs := VGFrameDrawingKit alexandrie classes.
	self assert: ours size equals: theirs size.
	ours with: theirs do: [ :our :their |
		self
			assert: ((map at: their name ifAbsent: [ nil ]) = our name or: [
					 our inheritsFrom: their ])
			description: their name , ' is not the counterpart of ' , our name ]
]

{ #category : 'tests' }
VGFrameStageBenchmarkTest >> testThePhasesOfEveryMeasuredFrameAccountForItsEncode [
	"The census is read as a breakdown of the encode figure the plan quotes, so the phases have
	 to add up to that figure and not to some other frame. Within a tenth of it: the clock is
	 read twice a phase, eleven phases deep, and those readings are inside the carrier encode
	 and outside every row.
	 The floors are compared and not the means. A mean over a handful of passes carries whichever
	 pass met the garbage collector, and such a pass has been ten times the others on a frame of
	 a full screen; the fastest pass of a phase and the fastest encode are both the work itself.
	 Five passes and not the three a report takes: the floor is itself an estimate, and at three
	 passes eighteen measurements of this ratio ran from 0.84 to 1.03, where at five passes they
	 ran from 0.95 to 1.01.
	 The display list is left out of the sum, because the encode figure is measured over a list
	 already drawn and drawing it is a phase of the frame and not of the encoding.
	 No device is asked for anything here: a display list, a binning and a buffer are all built
	 on the host."

	VGFrameStageBenchmark frameNames do: [ :name |
		VGFrameStageBenchmark extentsOfItsCensus do: [ :extent |
			| benchmark whole sum floors |
			benchmark := (VGFrameStageBenchmark
				              frameName: name
				              repeats: 5
				              extent: extent) measureEncoding.
			whole := benchmark minimumMillisecondsOf: #encode.
			floors := benchmark minimumEncodePhaseMilliseconds.
			sum := (floors keys reject: [ :each | each = #displayList ]) inject: 0
				       into: [ :total :each | total + (floors at: each) ].
			self
				assert: (sum - whole) abs < (whole / 10)
				description: name asString , ' at ' , extent printString , ': '
					, sum printString , ' of phases against ' , whole printString
					, ' of encode' ] ]
]

{ #category : 'tests' }
VGFrameStageBenchmarkTest >> testTheReportOfAFrameNamesEveryStageAndEveryCountOfItsCensus [
	"One frame's whole report, which is a third of what the class answers in one call: every
	 stage the frame reached, the Cairo figure, and the counts of the census beneath them. A
	 machine with no device reports no stage and still reports the census, which is counted
	 without a device.
	 Every stage the frame reached is named, and not every stage the dispatch can name: unit 3.1
	 made the kernel and the buffers of a tile extent last a session, so the pass these stages
	 are read from is a warm one and pays no prepare at all. The rows are still the rows of the
	 stage table in the order a frame pays them, which is what the table is for."
	| benchmark rows labels |
	benchmark := VGFrameStageBenchmark onTheBackgroundFrame run.
	rows := benchmark reportRows , benchmark census reportRows.
	labels := rows collect: [ :each | each key ].
	self assert: (labels includes: 'Cairo frame').
	self assert: (labels includes: 'sub-row sweeps').
	self assert: (labels includes: 'record reads over').
	benchmark isAvailable ifTrue: [
		benchmark stageRows do: [ :each |
			self
				assert: (labels includes: 'stage ' , each key asString)
				description: each key ].
		self
			assert: (benchmark stageRows collect: [ :each | each key ]) asArray
			equals: (VGTiledFillDispatch stageNames select: [ :each |
					 benchmark stageMilliseconds includesKey: each ]).
		self assert: (benchmark stageRows anySatisfy: [ :each | each key = #dispatch ]) ]
]

{ #category : 'tests' }
VGFrameStageBenchmarkTest >> testTheStagesOfAMeasuredFrameAreTheStagesTheDispatchRanAndAddUpToIt [
	"What the stage table is read for: where the milliseconds of a frame go. So every stage the
	 dispatch reached is a row of the table, the rows are in the order a frame pays them, and
	 they add up to the frame they were measured in, within a twentieth of it — the rest is the
	 clock readings themselves and the loop around them.
	 They are compared with the frame of their own pass and not with the dispatch figure above,
	 because one dispatch of a frame is not the next to a decimal place on this device. A
	 machine with no device has no stage and holds nothing."

	| benchmark names total |
	benchmark := VGFrameStageBenchmark onTheBackgroundFrame run.
	benchmark isAvailable ifFalse: [
		^ self assert: benchmark stageMilliseconds isEmpty ].
	names := benchmark stageRows collect: [ :each | each key ].
	self
		assert: names asArray
		equals: (VGTiledFillDispatch stageNames select: [ :each |
				 benchmark stageMilliseconds includesKey: each ]).
	self assert: (names includes: #dispatch).
	self assert: (names includes: #upload).
	total := benchmark stageMilliseconds values inject: 0 into: [ :sum :each |
		         sum + each ].
	self
		assert: (total - benchmark stagedFrameMilliseconds) abs < (total / 20)
		description: total printString , ' against '
			, benchmark stagedFrameMilliseconds printString
]

{ #category : 'tests' }
VGFrameStageBenchmarkTest >> testTheStagesOfAnEncodeAccountForTheWholeOfIt [
	"Unit 3.10 reads the host half of a frame the way unit 3.0 read the device half, so the
	 encode's own phases have to add up to the encode they were measured in. Within a tenth of
	 it: the clock is read twice a phase, eleven phases deep, and those readings are inside the
	 whole and outside every row.
	 Nothing here needs a device. The display list, the binning and the buffers are all built on
	 the host, so this test runs in an image with no driver, unlike the dispatch's own stage
	 test above.
	 One encode is thrown away before the clock starts, because the first one of an image pays
	 for the first touch of its pages and that cost would land in whichever phase ran first."

	| benchmark list encoding started whole total |
	benchmark := VGFrameStageBenchmark onTheBackgroundFrame.
	list := benchmark newSurface displayList.
	VGTiledFillEncoding of: list extent: benchmark extent.
	encoding := VGTiledFillEncoding new recordStages.
	started := Time microsecondClockValue.
	encoding encode: list extent: benchmark extent.
	whole := Time microsecondClockValue - started.
	total := encoding stageMicroseconds values inject: 0 into: [ :sum :each |
		         sum + each ].
	self
		assert: total <= whole
		description: total printString , ' us of phases against '
			, whole printString , ' us of encode'.
	self
		assert: total * 10 >= (whole * 9)
		description: total printString , ' us of phases accounts for less than nine tenths of '
			, whole printString , ' us of encode'
]

{ #category : 'tests' }
VGFrameStageBenchmarkTest >> testTheViewsOfTheBudgetAreCheckedLikeAnyOther [
	"The budget — the two benchmarks and the drawing kit — lives in the test package, because
	 measuring against Cairo means naming Alexandrie's classes and a package the failover loads
	 may name none. Its views are still views an example opens with one click, so the five rules
	 VGVulkanExamplesTest holds every view to have to reach a class defined there, and this is
	 the test that says they do.
	 It is asked here and not of that class, because a concrete TestCase that defines a test of
	 its own stops inheriting its superclass's: one test added there would silence the five."

	| guard |
	guard := VGVulkanExamplesTest new.
	self assert: (guard viewMethodsTheProjectWroteOf: VGFrameDrawingKit ours) notEmpty.
	self
		assert:
		(guard viewMethodsTheProjectWroteOf: VGFrameStageBenchmark onTheBackgroundFrame) notEmpty
]

{ #category : 'reading' }
VGFrameStageBenchmarkTest >> timedStagesOf: aSelector [
	"The stages that method of a dispatch wraps a block in, in the order it pays them, read out
	 of its own source and out of the source of every method of the dispatch it reaches. The
	 walk is recursive because the steps of a frame live one send below the two drawing methods
	 since unit 7.5, and it visits a method once, so a step sent from two places is named once
	 and the walk cannot turn on itself."

	| timed seen |
	timed := OrderedCollection new.
	seen := Set new.
	self
		collectTimedStagesOf: aSelector
		into: timed
		seen: seen.
	^ timed asArray
]
