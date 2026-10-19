"
I hold the Alexandrie experiment corpus to three promises.

The derived copies in VGAlexandriePortedExperiments are faithful: one per experiment, each exactly
what the substitution writes today, so an edit on either side is a failure here rather than a
silently stale oracle.
Every Alexandrie class the experiments need that we have no counterpart for is filed under the unit
that owes it, so a gap cannot hide.
Every case either draws and matches Cairo within its stated tolerance, or stops on a selector a unit
still owes.

All of it skips when the experiment class or libcairo is absent, because the corpus is an oracle
read from the user's own image rather than something the replacement owns.
"
Class {
	#name : 'VGAlexandrieCorpusTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Cairo-Tests-Tests',
	#package : 'VectorGraphics-Cairo-Tests',
	#tag : 'Tests'
}

{ #category : 'support' }
VGAlexandrieCorpusTest >> skipWithoutTheExperiments [
	^ VGAlexandrieCorpus isAvailable not
]

{ #category : 'tests - coverage' }
VGAlexandrieCorpusTest >> testEveryCaseEitherDrawsOrNamesTheUnitThatUnblocksIt [
	| unexplained |
	self skipWithoutTheExperiments ifTrue: [ ^ self skip ].
	unexplained := VGAlexandrieCorpus cases
		               reject: [ :each | each blockingUnit notNil or: [ each isPortable ] ]
		               thenCollect: [ :each | each name ].
	self assert: unexplained asArray isEmpty description: unexplained asArray printString
]

{ #category : 'tests' }
VGAlexandrieCorpusTest >> testEveryCaseThatDrawsMatchesCairo [
	"The oracle itself. A case that runs end to end on the replacement must produce the same
	 picture as Alexandrie, within the tolerance the corpus states for it."

	| failures |
	self skipWithoutTheExperiments ifTrue: [ ^ self skip ].
	failures := OrderedCollection new.
	VGAlexandrieCorpus cases do: [ :case |
		(case isPortable and: [ case blockingFailure isNil ]) ifTrue: [
			| comparison |
			comparison := case comparisonWithCairo.
			comparison isComparable
				ifFalse: [ failures add: case name , ' differs in extent' ]
				ifTrue: [
					comparison maximumChannelDistance > case tolerance ifTrue: [
						failures add: case name , ' ' , comparison printString ] ] ] ].
	self assert: failures asArray isEmpty description: failures asArray printString
]

{ #category : 'tests - copies' }
VGAlexandrieCorpusTest >> testEveryDerivedCopyIsWhatTheSubstitutionWritesNow [
	"The gate that keeps the oracle honest: the copies are generated from the experiments, so a
	 change to an experiment, or a hand edit of a copy, must fail here."
	| drifting |
	self skipWithoutTheExperiments ifTrue: [ ^ self skip ].
	drifting := VGAlexandrieCorpus driftingCases collect: [ :each | each name ].
	self
		assert: drifting asArray isEmpty
		description: 'send VGAlexandrieCorpus regenerate: ' , drifting asArray printString
]

{ #category : 'tests - copies' }
VGAlexandrieCorpusTest >> testEveryExperimentHasOneDerivedCopyAndNoMore [
	| ported wanted |
	self skipWithoutTheExperiments ifTrue: [ ^ self skip ].
	ported := VGAlexandrieCorpus portedClass class selectors asSortedCollection asArray.
	wanted := VGAlexandrieCorpus experimentSelectors.
	self assertCollection: ported hasSameElements: wanted
]

{ #category : 'tests - coverage' }
VGAlexandrieCorpusTest >> testEveryFiledMissingClassIsReallyMissing [
	"A class that now exists must leave the table, or the corpus would keep reporting a gap that
	 is closed."
	| stale |
	self skipWithoutTheExperiments ifTrue: [ ^ self skip ].
	stale := VGAlexandrieCorpus missingClassUnitTable
		         select: [ :each |
			         (VGAlexandrieCorpus ourNameFor: each key) ifNil: [ false ] ifNotNil: [ :ours |
				         Smalltalk includesKey: ours ] ]
		         thenCollect: [ :each | each key ].
	self assert: stale asArray isEmpty description: stale asArray printString
]

{ #category : 'tests - coverage' }
VGAlexandrieCorpusTest >> testEveryMissingClassIsFiledUnderAUnitThePlanDeclares [
	| unfiled |
	self skipWithoutTheExperiments ifTrue: [ ^ self skip ].
	unfiled := OrderedCollection new.
	VGAlexandrieCorpus cases do: [ :case |
		case missingClassNames do: [ :each |
			| unit |
			unit := VGAlexandrieCorpus unitForMissingClass: each.
			(unit notNil and: [ VGCairoInventory planUnits includes: unit ]) ifFalse: [
				unfiled add: each ] ] ].
	self assert: unfiled asSet asSortedCollection asArray isEmpty
		description: unfiled asSet asSortedCollection asArray printString
]

{ #category : 'tests - copies' }
VGAlexandrieCorpusTest >> testNoDerivedCopyStillNamesAClassWeHave [
	"A substitution that missed an occurrence would quietly measure Alexandrie against itself."
	| leaking |
	self skipWithoutTheExperiments ifTrue: [ ^ self skip ].
	leaking := OrderedCollection new.
	VGAlexandrieCorpus cases do: [ :case |
		VGAlexandrieCorpus classNameMap do: [ :each |
			(case portedSource includesSubstring: each key) ifTrue: [
				leaking add: case name , ' names ' , each key ] ] ].
	self assert: leaking asArray isEmpty description: leaking asArray printString
]

{ #category : 'tests - copies' }
VGAlexandrieCorpusTest >> testTheNonPictureExperimentsStillExist [
	"They are named one by one, so a rename upstream has to be noticed rather than silently
	 dropping a case from the corpus."
	| missing |
	self skipWithoutTheExperiments ifTrue: [ ^ self skip ].
	missing := VGAlexandrieCorpus nonPictureSelectors reject: [ :each |
		           VGAlexandrieCorpus experimentClass class includesSelector: each ].
	self assert: missing asArray isEmpty description: missing asArray printString
]

{ #category : 'tests - coverage' }
VGAlexandrieCorpusTest >> testToleranceTableNamesCasesTheCorpusHas [
	| unknown |
	self skipWithoutTheExperiments ifTrue: [ ^ self skip ].
	unknown := VGAlexandrieCorpus toleranceTable
		           reject: [ :each | VGAlexandrieCorpus experimentSelectors includes: each key ]
		           thenCollect: [ :each | each key ].
	self assert: unknown asArray isEmpty description: unknown asArray printString
]
