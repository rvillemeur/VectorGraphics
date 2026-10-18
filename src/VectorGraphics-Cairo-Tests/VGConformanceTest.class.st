"
I check the conformance harness itself, not the engine. I state four facts about VGConformanceCorpus: every case has a unique name, every case names a unit that VECTORCANVAS-PLAN.md declares, every unit that owes painting selectors has at least one case, and every case stops on a selector whose unit is no later than the unit the case is filed under. The last fact is the gate for unit 1.0: a case must fail by raising VGNotYetImplemented and naming the unit that owes the selector, never with a doesNotUnderstand or any other error. As the units land, the same test keeps the corpus honest, because a case that suddenly draws to the end reports no blocking failure and a case that blocks later than it should names the selector it tripped on.
"
Class {
	#name : 'VGConformanceTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Cairo-Tests-Conformance',
	#package : 'VectorGraphics-Cairo-Tests',
	#tag : 'Conformance'
}

{ #category : 'tests' }
VGConformanceTest >> testEveryCaseBlocksOnASelectorNoLaterThanItsOwnUnit [
	"The gate for unit 1.0. A case must stop by raising VGNotYetImplemented, and the unit named by
	 the selector it stopped on must be the case's own unit or an earlier one; a later unit means the
	 case was filed too early, and no failure at all means the case now draws and owes a reference
	 picture instead."

	| misfiled |
	misfiled := OrderedCollection new.
	VGConformanceCorpus cases do: [ :each |
		| failure |
		failure := each blockingFailure.
		(failure notNil and: [ failure unit > each unit ]) ifTrue: [
			misfiled add: each name -> (failure selectorName -> failure unit) ] ].
	self
		assert: misfiled isEmpty
		description: 'these cases stop on a selector owed by a later unit: ' , misfiled asArray printString
]

{ #category : 'tests' }
VGConformanceTest >> testEveryCaseGroupIsNamedByTheCorpusList [
	"A group method that nobody lists would never run, so the two views of the corpus must agree."

	| listed found disagreement |
	listed := VGConformanceCorpus caseMethodSelectors asSet.
	found := (VGConformanceCorpus class methods
		          select: [ :each | each protocolName = #cases ]
		          thenCollect: [ :each | each selector ]) asSet.
	found remove: #cases ifAbsent: [ self fail: 'VGConformanceCorpus class >> #cases is not in the cases protocol' ].
	disagreement := (found difference: listed) , (listed difference: found).
	self
		assert: disagreement isEmpty
		description: 'the cases protocol and #caseMethodSelectors disagree about '
			, disagreement asSortedCollection asArray printString
]

{ #category : 'tests' }
VGConformanceTest >> testEveryCaseHasAUniqueName [
	| names duplicated |
	names := VGConformanceCorpus cases collect: [ :each | each name ].
	duplicated := names asBag sortedCounts
		              select: [ :each | each key > 1 ]
		              thenCollect: [ :each | each value ].
	self
		assert: duplicated isEmpty
		description: 'two conformance cases share a name: ' , duplicated asArray printString.
	self deny: names isEmpty description: 'the conformance corpus is empty'
]

{ #category : 'tests' }
VGConformanceTest >> testEveryCaseNamesAUnitThePlanDeclares [
	| declared unknown |
	declared := VGCairoInventory planUnits.
	unknown := (VGConformanceCorpus cases
		            reject: [ :each | declared includes: each unit ])
		           collect: [ :each | each name -> each unit ].
	self
		assert: unknown isEmpty
		description: 'these cases name a unit the plan does not declare: ' , unknown printString
]

{ #category : 'tests' }
VGConformanceTest >> testEveryUnitThatOwesPaintingSelectorsHasACase [
	"Unit 1.0 owes only lifecycle selectors and unit 1.9 owes none at all, so neither can be drawn.
	 Every other unit in the table must be visible in at least one picture."

	| covered uncovered |
	covered := (VGConformanceCorpus cases collect: [ :each | each unit ]) asSet.
	uncovered := (VGCairoInventory planUnits
		              reject: [ :each | (self unitsWithoutAPicture includes: each) or: [ covered includes: each ] ])
		             asSortedCollection asArray.
	self
		assert: uncovered isEmpty
		description: 'no conformance case is filed under ' , uncovered printString
]

{ #category : 'constants' }
VGConformanceTest >> unitsWithoutAPicture [
	"Unit 1.0 builds the harness and unit 1.9 wires the AeCanvas subclass, so neither owes a case.
	 Unit 1.2 owns the matrix, which changes nothing visible on its own: a transformation shows up
	 only through a shape, so its three cases are filed under unit 1.3 with the shape verbs they
	 need."
	^ #( '1.0' '1.2' '1.9' )
]
