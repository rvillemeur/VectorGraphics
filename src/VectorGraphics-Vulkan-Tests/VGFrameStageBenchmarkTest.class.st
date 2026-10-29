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
VGFrameStageBenchmarkTest >> testEveryStageTheDispatchTimesIsOneItNames [
	"The table of stage names and the dispatch cannot drift: every stage the dispatch wraps a
	 block in is read out of its own source here, in the order a frame pays them, and a stage
	 named in the table and timed nowhere would be a row of the report that no code fills.
	 A stage is timed either in `draw:into:readBack:` itself or in the one method of the dispatch
	 that it sends for that step, so the order is the order of the steps and not of the method
	 dictionary. The frame walked is the one that takes the readback as a request, because
	 `draw:into:` is that frame with the request answered yes."

	| timed |
	timed := OrderedCollection new.
	(VGTiledFillDispatch >> #draw:into:readBack:) ast sendNodes do: [ :each |
		each selector = #timeStage:during:
			ifTrue: [ timed add: each arguments first value ]
			ifFalse: [
				(VGTiledFillDispatch includesSelector: each selector) ifTrue: [
					((VGTiledFillDispatch >> each selector) ast sendNodes select: [
						 :send | send selector = #timeStage:during: ]) do: [ :send |
						timed add: send arguments first value ] ] ] ].
	self assert: timed asArray equals: VGTiledFillDispatch stageNames.
	self assert: timed asSet size equals: timed size
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
VGFrameStageBenchmarkTest >> testTheCairoKitDrawsThePictureOursDraws [
	"The Cairo figure of the report is only a comparison if both sides drew one picture. The
	 background and the cards frames come out byte for byte the same on either side, which is
	 the strict form of that; the reference frame differs on under one pixel in a hundred, all
	 of them in the glyphs, because a glyph is rasterised by the backend that draws it and the
	 two atlases are not the same bytes.
	 The frames are drawn at their own extent, so this test costs two software frames a frame
	 name and is the slowest of this class."

	| extent allowed |
	extent := VGFrameDeviceBenchmark extentOfItsFrames.
	allowed := Dictionary newFrom: {
			           (#background -> 0).
			           (#cards -> 0).
			           (#reference -> (extent x * extent y / 100)) }.
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
	self assert: (guard viewMethodsOf: VGFrameDrawingKit ours) notEmpty.
	self
		assert:
		(guard viewMethodsOf: VGFrameStageBenchmark onTheBackgroundFrame) notEmpty
]
