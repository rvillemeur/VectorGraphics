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

{ #category : 'accessing' }
VGAlexandrieCorpusTest >> defaultTimeLimit [
	"Eighty-two experiments, each rendered twice, take minutes rather than the ten seconds SUnit
	 allows a test by default. Without this the oracle ended a package run as an error instead of
	 as a verdict."
	^ 10 minutes
]

{ #category : 'support' }
VGAlexandrieCorpusTest >> skipWithoutTheExperiments [
	^ VGAlexandrieCorpus isAvailable not
]

{ #category : 'tests' }
VGAlexandrieCorpusTest >> testEveryBoundaryAllowanceNamesACaseTheCorpusHasAndACaseWithATolerance [
	"A count of pixels allowed beyond a tolerance is only meaningful beside that tolerance, and
	 an allowance for a case that no longer exists would pass quietly, so both are checked here
	 as the tolerance table is checked."
	| unknown untolerated |
	self skipWithoutTheExperiments ifTrue: [ ^ self skip ].
	unknown := VGAlexandrieCorpus meshBoundaryPixelTable
		           reject: [ :each |
		           VGAlexandrieCorpus experimentSelectors includes: each key ]
		           thenCollect: [ :each | each key ].
	self assert: unknown asArray isEmpty description: unknown asArray printString.
	untolerated := VGAlexandrieCorpus meshBoundaryPixelTable
		               reject: [ :each |
			               (VGAlexandrieCorpus toleranceFor: each key)
			               = VGAlexandrieCorpus meshColourTolerance ]
		               thenCollect: [ :each | each key ].
	self
		assert: untolerated asArray isEmpty
		description: untolerated asArray printString
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
	 picture as Alexandrie, within the tolerance the corpus states for it, with nothing of ours
	 outside Cairo's shape beyond the residue a rounded edge leaves, and with no more pixels
	 beyond that tolerance than the corpus allows the case, which is none unless the case paints
	 a mesh. A case drawn in Cairo's toy default face is left out, with its reason, by
	 `casesWithCairosToyDefaultFont`."
	| failures |
	self skipWithoutTheExperiments ifTrue: [ ^ self skip ].
	failures := OrderedCollection new.
	VGAlexandrieCorpus cases do: [ :case |
		((case isPortable and: [ case blockingFailure isNil ]) and: [
			 (VGAlexandrieCorpus casesWithCairosToyDefaultFont includes:
				  case name asSymbol) not ]) ifTrue: [
			| comparison |
			comparison := case comparisonWithCairo.
			comparison isComparable
				ifFalse: [ failures add: case name , ' differs in extent' ]
				ifTrue: [
					(comparison maximumStrayAlpha <= case strayAlphaAllowance and: [
						 (comparison pixelsFartherThan: case tolerance)
						 <= case boundaryPixelAllowance ]) ifFalse: [
						failures add: case name , ' ' , comparison printString ] ] ] ].
	self assert: failures asArray isEmpty description: failures asArray printString
]

{ #category : 'tests - coverage' }
VGAlexandrieCorpusTest >> testEveryCaseThatSelectsAFontCarriesTheGlyphAllowance [
	"A case that selects a font and then draws a run has its glyphs rasterised by Cairo through
	 FreeType, which grid-fits the outline first, so the two pictures part along every stem by more
	 than an edge of a path parts. Such a case therefore carries the glyph tolerance and a count of
	 the pixels allowed past it, and a case that carries them is such a case. The rule is asked of
	 the ported source, so a case that starts or stops selecting a font fails here rather than
	 failing the oracle."

	| withAGlyphRun |
	self skipWithoutTheExperiments ifTrue: [ ^ self skip ].
	withAGlyphRun := VGAlexandrieCorpus cases
		                 select: [ :case |
			                 (case isPortable and: [ case blockingFailure isNil ]) and: [
				                 (case portedSource includesSubstring: 'scaledFont:') and: [
					                 #( 'showGlyphs:' 'showText:' 'appendGlyphsPath:' ) anySatisfy: [
						                 :verb | case portedSource includesSubstring: verb ] ] ] ]
		                 thenCollect: [ :case | case name asSymbol ].
	self
		assertCollection: withAGlyphRun asSet
		hasSameElements:
			(VGAlexandrieCorpus hintedGlyphRunPixelTable collect: [ :each | each key ])
				asSet.
	withAGlyphRun do: [ :each |
		self
			assert: (VGAlexandrieCorpus toleranceFor: each)
			equals: VGAlexandrieCorpus hintedGlyphRunTolerance ]
]

{ #category : 'tests' }
VGAlexandrieCorpusTest >> testEveryCaseWithNoSelectedFontIsFiled [
	"A case that draws text without selecting a font is drawn by Cairo in the toy default face it
	 takes from fontconfig, which this replacement does not bind, so it is filed as unmatchable
	 rather than carried by a tolerance. The rule is asked of the ported source, so a case that
	 starts or stops selecting a font fails here instead of failing the oracle."

	| withNoFont |
	self skipWithoutTheExperiments ifTrue: [ ^ self skip ].
	withNoFont := VGAlexandrieCorpus cases
		              select: [ :case |
			              (case isPortable and: [ case blockingFailure isNil ]) and: [
				              (case portedSource includesSubstring: 'showText:') and: [
					              (case portedSource includesSubstring: 'scaledFont') not ] ] ]
		              thenCollect: [ :case | case name asSymbol ].
	self
		assertCollection: withNoFont asSet
		hasSameElements: VGAlexandrieCorpus casesWithCairosToyDefaultFont asSet
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

{ #category : 'tests' }
VGAlexandrieCorpusTest >> testEveryDerivedCopyThatRunsIsASampleInstance [
	"A derived copy that runs is a one-click example of the replacement, so it carries the pragma
	 Pharo's browser reads. A copy whose script still names a class we do not have raises a
	 MessageNotUnderstood when it is clicked, so that one carries no pragma."

	| wrong |
	self skipWithoutTheExperiments ifTrue: [ ^ self skip ].
	wrong := OrderedCollection new.
	VGAlexandrieCorpus cases do: [ :each |
		VGAlexandrieCorpus portedClass class
			compiledMethodAt: each experimentSelector
			ifPresent: [ :method |
				(method hasPragmaNamed: #sampleInstance) = each isPortable ifFalse: [
					wrong add: each experimentSelector ] ]
			ifAbsent: [ wrong add: each experimentSelector ] ].
	self
		assert: wrong asArray isEmpty
		description: 'derived copies whose sampleInstance pragma does not match whether they run: '
			, wrong asArray printString
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
VGAlexandrieCorpusTest >> testEveryExperimentIsPortable [
	"Every experiment of the corpus names only classes the replacement has a counterpart for, so
	 every one of them has a derived copy that runs. The font facade of unit 1.13 closed the last
	 five; whether a copy then matches Cairo is a separate question, held by
	 #testEveryCaseThatDrawsMatchesCairo."

	| blocked |
	self skipWithoutTheExperiments ifTrue: [ ^ self skip ].
	blocked := VGAlexandrieCorpus cases
		           reject: [ :each | each isPortable ]
		           thenCollect: [ :each | each experimentSelector ].
	self
		assert: blocked asArray isEmpty
		description: 'experiments still naming a class we have no counterpart for: '
			, blocked asArray printString
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
