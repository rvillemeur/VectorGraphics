"
I hold the tests of unit 2.0: which backend draws a frame, and what happens when the one chosen fails.

Two facts are mine. The first is selection: VGBackend class >> preferred probes the candidate backends in rank order, caches what it finds, and answers a forced choice unchanged, because a parity test that silently falls back proves nothing. The second is recovery: a backend that raises VGBackendFailure while a frame is drawn is replaced by the software backend, the same display list is replayed there, and the failed class is not asked again. My fixtures are VGBrokenBackendStub, which raises while the frame is recorded, and VGFailingDrainBackendStub, which raises while it is drained.
"
Class {
	#name : 'VGBackendSelectionTest',
	#superclass : 'TestCase',
	#instVars : [
		'savedPreference',
		'savedRejections'
	],
	#category : 'VectorGraphics-Cairo-Tests-Tests',
	#package : 'VectorGraphics-Cairo-Tests',
	#tag : 'Tests'
}

{ #category : 'running' }
VGBackendSelectionTest >> frame [
	"The frame these tests draw. It is a fixture of its own, because the backend tests of the
	 Vulkan package draw the same frame and a picture held against another picture has to be the
	 same picture."

	^ VGBackendFrameFixture new
]

{ #category : 'running' }
VGBackendSelectionTest >> setUp [
	"The preference and the rejections are class-side state of VGBackend, so a test that forces a
	 backend or fails one would leak into the next. Keep both and put them back."

	super setUp.
	savedPreference := VGBackend preferredClassOrNil.
	savedRejections := VGBackend rejectedClasses
]

{ #category : 'running' }
VGBackendSelectionTest >> tearDown [
	VGBackend restorePreference: savedPreference rejections: savedRejections.
	super tearDown
]

{ #category : 'tests' }
VGBackendSelectionTest >> testAFailedBackendIsNotChosenForTheNextFrame [
	"A backend that failed once is rejected by class, because the fault is the device or the
	 driver and not the instance, and the preference it held is forgotten, so the next frame
	 chooses again among whatever is left."

	VGBackend clearPreference.
	VGBackend prefer: VGBrokenBackendStub.
	self frame drawnBy: VGBackend preferred.
	self assert: (VGBackend rejectedClasses includes: VGBrokenBackendStub).
	self deny: (VGBackend candidateClasses includes: VGBrokenBackendStub).
	self assert: VGBackend preferredClassOrNil isNil
]

{ #category : 'tests' }
VGBackendSelectionTest >> testAForcedBackendIsAnsweredWithoutAProbe [
	"A parity test that silently falls back proves nothing, so a forced choice stands even when
	 the probe would have answered something else."

	VGBackend prefer: VGBrokenBackendStub.
	self assert: VGBackend preferredClass identicalTo: VGBrokenBackendStub.
	self assert: VGBackend preferred class identicalTo: VGBrokenBackendStub
]

{ #category : 'tests - recovery' }
VGBackendSelectionTest >> testAFrameRecordedOnABrokenBackendIsDrawnBySoftwareAnyway [
	"The gate of unit 2.0: a deliberately broken backend produces a correct frame through the
	 fallback. Correct means the pixels the software backend draws, which phase 1 held against
	 Cairo, so this compares the two frames rather than describing one."

	| broken fallback expected |
	broken := VGBrokenBackendStub new.
	fallback := self frame drawnBy: broken.
	expected := self frame drawnBy: VGSoftwareBackend new.
	self assert: broken recorded equals: 1.
	self assert: fallback bits equals: expected bits
]

{ #category : 'tests - recovery' }
VGBackendSelectionTest >> testAFrameThatFailsWhenItIsDrainedIsDrawnBySoftwareAnyway [
	"The other half of the gate: a backend that records the whole frame and then fails to draw it
	 must be recovered from as well, and it must be asked once and not twice."

	| failing fallback expected |
	failing := VGFailingDrainBackendStub new.
	fallback := self frame drawnBy: failing.
	expected := self frame drawnBy: VGSoftwareBackend new.
	self assert: failing drainAttempts equals: 1.
	self assert: fallback bits equals: expected bits
]

{ #category : 'tests' }
VGBackendSelectionTest >> testAFrameThatReadsAnotherSurfaceDrainsThatSurfaceOnceAndFinishes [
	"A surface paint reads the pixels of its own surface, and reading a pixel drains that
	 surface's frame, so draining one frame starts another. The two drains have to be independent:
	 when they share the collection of recorded commands, each drain replays the other's and the
	 frame never ends."

	| source target |
	source := VGCairoImageSurface extent: 4 @ 4.
	source newContext
		sourceColor: Color red;
		paint.
	target := VGCairoImageSurface extent: 4 @ 4.
	target newContext
		sourcePattern: (VGCairoSurfacePattern surface: source);
		paint.
	target flush.
	self assert: (target pixelAtX: 0 y: 0) equals: (source pixelAtX: 0 y: 0)
]

{ #category : 'tests' }
VGBackendSelectionTest >> testASurfaceWithNoBackendOfItsOwnDrawsThroughThePreferredOne [
	"The surface is where the choice reaches the drawing, and it must not name a backend class of
	 its own, or forcing one would not reach a frame. The instance is the surface's own; the class
	 is what selection decided."

	| surface |
	VGBackend prefer: VGSoftwareBackend.
	surface := VGCairoImageSurface extent: self frame extent.
	self assert: surface backend class identicalTo: VGBackend preferredClass
]

{ #category : 'tests' }
VGBackendSelectionTest >> testEachSurfaceWithNoBackendOfItsOwnDrawsOnAnInstanceOfItsOwn [
	"A backend records the frame it is draining, so two surfaces may not hold one instance: the
	 pixel read of a surface paint drains the surface it reads, and that drain would run through
	 the instance the first drain is in the middle of. The class is the decision selection makes,
	 and the instance is the surface's own."

	| one two |
	one := VGCairoImageSurface extent: 4 @ 4.
	two := VGCairoImageSurface extent: 4 @ 4.
	self deny: one backend == two backend.
	self assert: one backend class identicalTo: two backend class
]

{ #category : 'tests - selection' }
VGBackendSelectionTest >> testEveryCandidateIsABackendThatAnswersWhetherItIsAvailable [
	"Selection reads the hierarchy rather than a list of class names, which is how a backend
	 added later is found without this method or VGBackend being edited."

	self deny: VGBackend candidateClasses isEmpty.
	VGBackend candidateClasses do: [ :each |
		self assert: (each inheritsFrom: VGBackend).
		self assert: (each respondsTo: #probe).
		self assert: each preferenceRank isNumber ]
]

{ #category : 'tests - architecture' }
VGBackendSelectionTest >> testEveryPackageOfTheProjectIsNamedInTheBaseline [
	"A package the baseline does not name is a package nobody loads, which is how a split into
	 packages goes wrong. The names are looked for in the baseline's own source, because a
	 Metacello spec is built by sending messages and reading it back is more machinery than the
	 fact deserves."

	| source missing |
	source := (BaselineOfVectorGraphics >> #baseline:) sourceCode.
	missing := (PackageOrganizer default packages select: [ :each |
		            each name beginsWith:
			            VGCairoReferenceScanner projectPackagePrefix ]) reject: [
		           :each | source includesSubstring: each name ].
	self
		assert: missing isEmpty
		description: 'these packages are in no baseline group: '
			, (missing collect: [ :each | each name ]) asArray printString
]

{ #category : 'tests - architecture' }
VGBackendSelectionTest >> testOnlyTheVulkanPackageNamesAVulkanClass [
	"The engine must load on a machine with no Vulkan driver, so no package of it but the Vulkan
	 backend itself may name a class of that backend or of PharoVulkan. Selection reaches the
	 backend by reflection over the subclasses of VGBackend, which names nothing."

	| scanner forbidden offenders |
	scanner := VGCairoReferenceScanner default.
	forbidden := VGCairoReferenceScanner vulkanPackageNames.
	offenders := (VGCairoReferenceScanner projectPackageNames reject: [ :each |
		              forbidden includes: each ]) flatCollect: [ :each |
		             scanner offendersIn: each naming: forbidden ].
	self assertEmpty: offenders
]

{ #category : 'tests' }
VGBackendSelectionTest >> testThePreferredBackendIsProbedOnceAndThenCached [
	"The probe runs a real dispatch, which costs a device and a queue, so it may not run per
	 frame. What is cached is the class, and the instance is new on every send."

	VGBackend clearPreference.
	self assert: VGBackend preferredClass identicalTo: VGBackend preferredClass.
	self deny: VGBackend preferred == VGBackend preferred
]

{ #category : 'tests - selection' }
VGBackendSelectionTest >> testTheSoftwareBackendIsTheLastCandidateAndIsAlwaysAvailable [
	"It is the failover, so it may never be the one that fails to answer and it may never be
	 asked before a backend that might be faster."

	self assert: VGBackend candidateClasses last equals: VGSoftwareBackend.
	self assert: VGSoftwareBackend probe class equals: VGSoftwareBackend.
	self
		assert: (VGBackend candidateClasses allSatisfy: [ :each |
				 each preferenceRank <= VGSoftwareBackend preferenceRank ])
		description: 'nothing may rank behind the failover'
]

{ #category : 'tests - recovery' }
VGBackendSelectionTest >> testTheSurfaceKeepsNoFrameAfterARecoveredFailure [
	"A display list replayed twice must be reset once, or the next frame draws this one again.
	 The failure happens while the list is replayed, so the reset cannot come before the
	 fallback."

	| surface |
	surface := VGCairoImageSurface extent: self frame extent.
	surface backend: VGBrokenBackendStub new.
	self frame drawOn: surface.
	surface flush.
	self assert: surface displayList isEmpty.
	self assert: surface backend class equals: VGSoftwareBackend
]
