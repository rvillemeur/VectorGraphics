"
I hold the profile of a frame of a representative Bloc scene to the facts unit 1.11 states: that the scene draws ink through this project and through Cairo, that every package and tag of this project is attributed to a named stage, and that the shares of the stages account for the whole frame. I build a small scene, because the point of the measurement is the share of each stage and not the absolute number, and a window sized frame takes seconds in a software rasteriser.
"
Class {
	#name : 'VGFrameProfileTest',
	#superclass : 'TestCase',
	#instVars : [
		'profile'
	],
	#category : 'VectorGraphics-Bloc-Tests',
	#package : 'VectorGraphics-Bloc-Tests'
}

{ #category : 'accessing' }
VGFrameProfileTest >> millisecondTolerance [
	"Two sums of the same floats differ by this much at most."

	^ 0.001
]

{ #category : 'running' }
VGFrameProfileTest >> setUp [
	"A small scene and one frame: what the tests state is the share of each stage and the shape of
	 the report, not an absolute number, and a window sized frame takes seconds in a software
	 rasteriser."

	super setUp.
	profile := VGFrameProfile new
		           extent: 160 @ 120;
		           cards: 2;
		           frames: 1;
		           run;
		           yourself
]

{ #category : 'accessing' }
VGFrameProfileTest >> shareTolerance [
	"The shares are floats summed over a few dozen stages, so they sum to one to about this much."

	^ 0.001
]

{ #category : 'tests' }
VGFrameProfileTest >> testAClassOutsideThisProjectIsAttributedToTheSceneStage [
	"Bloc walks the element tree and this project draws what it asks for, so time spent in a class
	 we did not write is the scene stage and not an unattributed remainder."

	self
		assert: (VGFrameProfile stageOfClass: BlElement)
		equals: VGFrameProfile sceneStage
]

{ #category : 'tests' }
VGFrameProfileTest >> testAProfileThatHasNotRunNamesNoStage [
	"The degenerate state: nothing was measured, so there is no slowest stage to name and no
	 shares to read."

	| fresh |
	fresh := VGFrameProfile new.
	self assert: fresh slowestStage isNil.
	self assert: fresh stageShares isEmpty
]

{ #category : 'tests' }
VGFrameProfileTest >> testBothBackendsDrawTheSameExtent [
	"Two frame times are comparable only when the two frames are the same size."

	self assert: profile ourForm extent equals: profile cairoForm extent
]

{ #category : 'tests' }
VGFrameProfileTest >> testBuildingTheSceneLeavesThePreferableRendererAsItWas [
	"The renderer class a scene is measured through is global state of Bloc, and a profile that
	 left it pointing at this project would change how the rest of the image draws."

	| before |
	before := BlHostRenderer preferableClass.
	profile sceneForRendererClass: VGRenderer.
	self assert: BlHostRenderer preferableClass equals: before
]

{ #category : 'tests' }
VGFrameProfileTest >> testEveryPackageAndTagOfThisProjectHasAStageAndNoOthers [
	"A sample is credited to the stage of the deepest class of this project on the stack, so every
	 package and tag of the project needs a stage, and a key naming a tag that is gone would
	 silently stop matching. Both sides are read from the organiser, not listed here."

	self
		assertCollection: VGFrameProfile stageByPackageAndTag keys asSet
		hasSameElements: VGFrameProfile packageAndTagKeys asSet
]

{ #category : 'tests' }
VGFrameProfileTest >> testEveryStageMeasuredIsNamedInTheReport [
	"The report is what is pasted into the plan, so it has to carry every stage the run measured."

	profile stageShares keysDo: [ :each |
		self assert: (profile report includesSubstring: each) description: each ]
]

{ #category : 'tests' }
VGFrameProfileTest >> testTheCairoFrameIsTimedForTheSameScene [
	"Without the other backend's number for the same scene there is nothing to judge phase two
	 against."

	self assert: profile cairoMilliseconds > 0
]

{ #category : 'tests' }
VGFrameProfileTest >> testTheFrameTimeIsTheBuildPlusTheDrain [
	"A frame here is two phases and nothing else: the element tree records the display list, and
	 the flush of the surface drains it. The two are timed apart because they are the two halves a
	 Vulkan backend would replace separately."

	| phases |
	phases := profile phaseMilliseconds.
	self
		assert:
		(profile ourMilliseconds
		 - ((phases at: #build) + (phases at: #drain))) abs
		< self millisecondTolerance
]

{ #category : 'tests' }
VGFrameProfileTest >> testTheSceneDrawsInkThroughCairo [
	"The comparison is only worth reading if the same scene really drew on the other backend."

	self assert: profile cairoForm bits asSet size > 1
]

{ #category : 'tests' }
VGFrameProfileTest >> testTheSceneDrawsInkThroughThisProject [
	"Ink, and no error: a scene whose text was measured through Cairo hands our canvas a Cairo
	 scaled font, and drawing it then fails with `atlas` not understood, so this test also holds
	 the rule that the scene is built under this project's renderer class."

	self assert: profile ourForm bits asSet size > 1
]

{ #category : 'tests' }
VGFrameProfileTest >> testTheSharesOfTheStagesSumToOne [
	"Every sample is credited to one stage, so the shares account for the whole frame and nothing
	 falls through the attribution."

	| sum |
	sum := profile stageShares values inject: 0 into: [ :total :each | total + each ].
	self assert: (sum - 1) abs < self shareTolerance
]

{ #category : 'tests' }
VGFrameProfileTest >> testTheSlowestStageIsTheStageWithTheLargestShare [
	"The gate of this unit is that the profile names the stage phase two must attack first, so the
	 name it answers is held to the measurement it made."

	| largest |
	largest := profile stageShares associations detectMax: [ :each | each value ].
	self assert: profile slowestStage equals: largest key
]

{ #category : 'tests' }
VGFrameProfileTest >> testTheStageMillisecondsSplitTheFrameTime [
	"The milliseconds of a stage are its share of the frame that was timed, so they add up to that
	 frame and can be read next to the Cairo number for the same scene."

	| sum |
	sum := profile stageMilliseconds values inject: 0 into: [ :total :each | total + each ].
	self assert: (sum - profile ourMilliseconds) abs < self millisecondTolerance
]

{ #category : 'tests' }
VGFrameProfileTest >> testTheStageOfTheRasteriserIsTheCoverageStage [
	"One stage read off a class of ours, so the table is held to a name and not only to its own
	 keys."

	self assert: (VGFrameProfile stageOfClass: VGRasteriser) equals: #coverage
]
