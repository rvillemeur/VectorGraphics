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

{ #category : 'support' }
VGConformanceTest >> coveredUnits [
	"The units a case is filed under, from both corpora: the cases written here and the cases
	 derived from the Alexandrie experiments, which are the only ones covering the mesh patterns."
	| covered |
	covered := (VGConformanceCorpus cases collect: [ :each | each unit ]) asSet.
	VGAlexandrieCorpus isAvailable ifTrue: [
		VGAlexandrieCorpus cases do: [ :each |
			each blockingUnit ifNotNil: [ :unit | covered add: unit ] ] ].
	^ covered
]

{ #category : 'tests' }
VGConformanceTest >> testAPatternOrASurfaceInACaseIsBuiltFromTheFamilyOfTheContextItDrawsOn [
	"A shared draw block may name no class of either side: handing one of our patterns to
	 Alexandrie's context reaches a Cairo call with an object that holds no pointer."

	| ourContext cairoContext |
	ourContext := (VGCairoImageSurface extent: 4 @ 4) newContext.
	cairoContext := (AeCairoImageSurface extent: 4 @ 4) newContext.
	self
		assert: (VGConformanceCorpus classNamed: 'ColorPattern' for: ourContext)
		equals: VGCairoColorPattern.
	self
		assert: (VGConformanceCorpus classNamed: 'ColorPattern' for: cairoContext)
		equals: AeCairoColorPattern.
	self
		assert: (VGConformanceCorpus classNamed: 'ImageSurface' for: ourContext)
		equals: VGCairoImageSurface.
	self
		assert: (VGConformanceCorpus classNamed: 'ImageSurface' for: cairoContext)
		equals: AeCairoImageSurface
]

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
VGConformanceTest >> testEveryCaseOfAFinishedUnitDraws [
	"A case whose unit has no skeleton left must draw from end to end. Without this, a case could
	 stay skipped by the oracle while its unit was called done."

	| blocked |
	blocked := VGConformanceCorpus cases
		           select: [ :each |
			           (self unitsWithNoSkeletonLeft includes: each unit) and: [
				           each blockingFailure notNil ] ]
		           thenCollect: [ :each |
			           each name , ' stops on ' , each blockingFailure selectorName ].
	self assert: blocked asArray isEmpty description: blocked asArray printString
]

{ #category : 'tests' }
VGConformanceTest >> testEveryCaseThatDrawsMatchesCairo [
	"The gate. Every case the implemented units can draw is rendered twice from one script, once
	 by the replacement and once by Alexandrie, and the two pictures must agree: no pixel of ours
	 outside Cairo's shape at all, and no channel further from Cairo's than the case allows. A
	 case blocked on a later unit is skipped, which is what its blocking failure is for."

	| failures |
	failures := OrderedCollection new.
	VGConformanceCorpus cases do: [ :case |
		case blockingFailure ifNil: [
			| comparison |
			comparison := case comparisonWithCairo.
			comparison isComparable
				ifFalse: [ failures add: case name , ' differs in extent' ]
				ifTrue: [
					(comparison extraneousPixelCount isZero and: [
						 comparison maximumChannelDistance <= case tolerance ]) ifFalse: [
						failures add: case name , ' ' , comparison printString ] ] ] ].
	self assert: failures asArray isEmpty description: failures asArray printString
]

{ #category : 'tests' }
VGConformanceTest >> testEveryUnitThatOwesPaintingSelectorsHasACase [
	"Unit 1.0 owes only lifecycle selectors and unit 1.9 owes none at all, so neither can be drawn.
	 Every other unit in the table must be visible in at least one picture."
	| covered uncovered |
	covered := self coveredUnits.
	uncovered := (VGCairoInventory planUnits
		              reject: [ :each | (self unitsWithoutAPicture includes: each) or: [ covered includes: each ] ])
		             asSortedCollection asArray.
	self
		assert: uncovered isEmpty
		description: 'no conformance case is filed under ' , uncovered printString
]

{ #category : 'tests' }
VGConformanceTest >> testTheComparisonPremultipliesTheStoredBytesAndNotAFractionOfThem [
	"A bug in what the gate reads with. A Form keeps unpremultiplied bytes, so the comparison
	 premultiplies before it measures; it was handing a byte to a method that takes a fraction of
	 one, and the product ran into the neighbouring channel. Two pixels a single step of coverage
	 apart were reported as the whole range apart, which made every tolerance meaningless."

	| ours theirs comparison |
	ours := Form extent: 1 @ 1 depth: 32.
	theirs := Form extent: 1 @ 1 depth: 32.
	"Transparent white is how a Form stores a pixel nothing painted; the reference painted red at
	 one step of coverage, so the two are one apart and not two hundred and fifty-five apart."
	ours bits at: 1 put: 16r00FFFFFF.
	theirs bits at: 1 put: 16r01FF0000.
	comparison := VGFormComparison between: ours and: theirs.
	self assert: comparison maximumChannelDistance equals: 1.
	self assert: comparison differingPixelCount equals: 1.
	"Our pixel is outside the reference's shape only where the reference painted nothing at all."
	self assert: comparison extraneousPixelCount equals: 0.
	ours bits at: 1 put: 16rFFFFFFFF.
	theirs bits at: 1 put: 16r00FFFFFF.
	comparison := VGFormComparison between: ours and: theirs.
	self assert: comparison extraneousPixelCount equals: 1.
	self assert: comparison maximumChannelDistance equals: 255.
	"Two opaque pixels are measured as they are stored, so the whole range is still reachable."
	ours bits at: 1 put: 16rFFFFFFFF.
	theirs bits at: 1 put: 16rFF000000.
	self
		assert: (VGFormComparison between: ours and: theirs) maximumChannelDistance
		equals: 255
]

{ #category : 'accessing' }
VGConformanceTest >> unitsWithNoSkeletonLeft [
	"The units whose selectors are all written: no method of the replacement still raises the
	 not-yet-implemented error naming them. Asked of the code rather than kept as a list, so it
	 cannot say a unit is done while a selector of it is still a skeleton."

	| pending |
	pending := ((Smalltalk packageOrganizer packageNamed: 'VectorGraphics-Cairo') methods
		            select: [ :each |
		            each messages includes: #notYetImplementedIn:selector: ]
		            thenCollect: [ :each |
		            each literals detect: [ :one |
			            one isString and: [ one first isDigit ] ] ]) asSet.
	^ VGCairoInventory planUnits reject: [ :each | pending includes: each ]
]

{ #category : 'support' }
VGConformanceTest >> unitsWithoutAPicture [
	"Unit 1.0 builds the harness and unit 1.9 wires the AeCanvas subclass, so neither owes a case.
	 Unit 1.2 owns the matrix, which changes nothing visible on its own: a transformation shows up
	 only through a shape, so its three cases are filed under unit 1.3 with the shape verbs they
	 need.
	 Unit 1.10 wires the renderer and unit 1.11 profiles it, and neither adds a drawing verb, so
	 what they change is measured by the cases the earlier units already own."
	^ #( '1.0' '1.2' '1.9' '1.10' '1.11' )
]
