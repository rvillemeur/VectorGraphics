"
Tests of `VGFrameRecordComparison`, the parity floor of unit 3.13. A test measures two passes of the cheapest variants rather than the twenty passes of the budget: what it holds is the shape of the comparison — a row a variant an extent, a floor a kit, and the ratio read off the two — and not any figure a machine answers.
"
Class {
	#name : 'VGFrameRecordComparisonTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Vulkan-Tests-Tests',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
VGFrameRecordComparisonTest >> testAComparisonThatHasNotRunReportsNoRowAndNoVerdict [
	"A comparison is built before it is run, and a reader can open it in between. The gate of
	 its views and its report read the same fact."
	| comparison |
	comparison := VGFrameRecordComparison new.
	self deny: comparison hasRun.
	self assert: comparison rows isEmpty.
	self assert: comparison reportRows isEmpty
]

{ #category : 'tests' }
VGFrameRecordComparisonTest >> testARowPrintsItsVariantItsExtentAndBothFloors [
	"What a reader sees of a row in a list, without opening it."
	| printed row |
	row := self twoPassComparison rows first.
	printed := row printString.
	self assert: (printed includesSubstring: row variant asString).
	self assert: (printed includesSubstring: row extent x printString).
	self assert: (printed includesSubstring: 'ms')
]

{ #category : 'tests' }
VGFrameRecordComparisonTest >> testEveryRowIsSubtractedFromTheWholeRowOfItsOwnExtent [
	"A variant measured on a screen must not be priced against a whole frame measured on a
	 smaller surface, which is the one way this subtraction can be wrong by a factor."
	| comparison |
	comparison := VGFrameRecordComparison
		              overVariants: #( #whole #cards )
		              extents: VGFrameDeviceBenchmark extentsOfItsCensus
		              passes: 2.
	self
		assert: comparison wholeRows size
		equals: VGFrameDeviceBenchmark extentsOfItsCensus size.
	comparison rows do: [ :each |
		each partLeftOut
			ifNil: [ self assert: each wholeRow isNil ]
			ifNotNil: [
				self assert: each wholeRow extent equals: each extent.
				self assert: each wholeRow partLeftOut isNil ] ]
]

{ #category : 'tests' }
VGFrameRecordComparisonTest >> testEveryVariantIsMeasuredOnBothKitsAtEveryExtentItIsAskedFor [
	"One row a variant an extent, and every row holds a floor for each kit. A variant measured
	 on one kit alone would have no parity to report."
	| comparison |
	comparison := self twoPassComparison.
	self
		assert: comparison rows size
		equals: VGFrameRecordComparison variantNames size.
	self
		assert: (comparison rows collect: [ :each | each variant ]) asArray
		equals: VGFrameRecordComparison variantNames.
	comparison rows do: [ :each |
		self assert: each ourRecordFloor > 0.
		self assert: each cairoRecordFloor > 0 ]
]

{ #category : 'tests' }
VGFrameRecordComparisonTest >> testThePartCostOfARowIsTheWholeFrameLessItself [
	"The subtraction unit 3.13 is built on. The whole row has nothing to be subtracted from, so
	 it reports no part cost at all."
	| comparison whole variants |
	comparison := self twoPassComparison.
	whole := comparison wholeRows first.
	variants := comparison rows reject: [ :each | each partLeftOut isNil ].
	self assert: whole ourPartCost isNil.
	self assert: whole cairoPartCost isNil.
	self assert: variants isNotEmpty.
	variants do: [ :each |
		self
			assert: each ourPartCost
			equals: whole ourRecordFloor - each ourRecordFloor.
		self
			assert: each cairoPartCost
			equals: whole cairoRecordFloor - each cairoRecordFloor ]
]

{ #category : 'tests' }
VGFrameRecordComparisonTest >> testTheRatioOfARowIsItsOwnFloorOverCairos [
	"The one figure the verdict of unit 3.13 is read off: how many times the recording of a
	 variant costs what Cairo pays to draw the same picture."
	| row |
	row := self twoPassComparison rows first.
	self
		assert: row ratio
		equals: row ourRecordFloor / row cairoRecordFloor
]

{ #category : 'tests' }
VGFrameRecordComparisonTest >> testTheWholeVariantLeavesNothingOutAndEveryOtherNamesItsPart [
	"The name #whole is this class's own and no part of a frame answers it: it has to reach the
	 drawing as nil, or the whole frame would be drawn without a part called #whole, which is
	 an error."
	self assert:
		(VGFrameRecordComparisonRow variant: #whole extent: 8 @ 8) partLeftOut
			isNil.
	self
		assert:
		(VGFrameRecordComparisonRow variant: #labels extent: 8 @ 8) partLeftOut
		equals: #labels.
	self assert:
		(VGFrameRecordComparison variantNames includes: #whole)
]

{ #category : 'building' }
VGFrameRecordComparisonTest >> twoPassComparison [
	"The comparison of every variant at the smaller extent over two passes, which is the fewest
	 a floor can be read off."
	^ VGFrameRecordComparison
		  overVariants: VGFrameRecordComparison variantNames
		  extents: { VGFrameDeviceBenchmark extentOfItsFrames }
		  passes: 2
]
