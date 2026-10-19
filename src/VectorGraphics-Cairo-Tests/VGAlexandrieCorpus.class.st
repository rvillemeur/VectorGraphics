"
I am the second conformance corpus: the Cairo drawings that live as class-side
<sampleInstance> methods on AlexandrieCairoExperiment, used as an oracle for the replacement.

I do not copy those drawings by hand. VGAlexandriePortedExperiments holds one derived copy of each,
in which every Alexandrie class name that has a counterpart of ours is substituted for it and
nothing else changes, so the original stays the single source and VGAlexandrieCorpusTest fails when
a derived copy drifts from it. A case therefore runs the same script twice, once on Cairo and once
on us, and compares the two Forms.

My cases answer, through VGAlexandrieCase, which selector or which class still blocks them, so the
corpus reports how much of the real Cairo surface the engine covers, unit by unit.
"
Class {
	#name : 'VGAlexandrieCorpus',
	#superclass : 'Object',
	#category : 'VectorGraphics-Cairo-Tests-Conformance',
	#package : 'VectorGraphics-Cairo-Tests',
	#tag : 'Conformance'
}

{ #category : 'accessing' }
VGAlexandrieCorpus class >> allExperimentSelectors [
	"Every drawing the experiment class offers, found by its pragma rather than by a kept list."
	self experimentClass ifNil: [ ^ #(  ) ].
	^ (self experimentClass class selectors select: [ :each |
		   (self experimentClass class >> each) pragmas anySatisfy: [ :one |
			   one selector = #sampleInstance ] ]) asSortedCollection asArray
]

{ #category : 'substitution' }
VGAlexandrieCorpus class >> cairoClassNamesUsed [
	"Every Alexandrie Cairo class the experiments name, read from their literals."
	| names |
	names := Set new.
	self experimentSelectors do: [ :each |
		names addAll: (VGAlexandrieCase for: each) referencedCairoClassNames ].
	^ names asSortedCollection asArray
]

{ #category : 'accessing' }
VGAlexandrieCorpus class >> cases [
	^ self experimentSelectors collect: [ :each | VGAlexandrieCase for: each ]
]

{ #category : 'substitution' }
VGAlexandrieCorpus class >> classNameMap [
	"Alexandrie class name to ours, for the classes the experiments name and we have a counterpart
	 for. Longest first, so that substituting AeCairoSurface cannot eat AeCairoSurfaceFormat."
	| map |
	map := Dictionary new.
	self cairoClassNamesUsed do: [ :each |
		| ours |
		ours := self ourNameFor: each.
		(ours notNil and: [ Smalltalk includesKey: ours ]) ifTrue: [ map at: each put: ours ] ].
	^ (map associations asSortedCollection: [ :a :b | a key size >= b key size ]) asArray
]

{ #category : 'generating' }
VGAlexandrieCorpus class >> driftingCases [
	"Every case whose compiled copy is not what the substitution would write now, which is how an
	 edit to an experiment, or to a copy, is caught."
	^ self cases reject: [ :each | each portedCopyIsCurrent ]
]

{ #category : 'accessing' }
VGAlexandrieCorpus class >> experimentClass [
	"The class that holds the Alexandrie drawings. It belongs to the user's own BookletGraphics
	 package, so it may be absent from an image that only loaded the replacement."
	^ Smalltalk at: #AlexandrieCairoExperiment ifAbsent: [ nil ]
]

{ #category : 'accessing' }
VGAlexandrieCorpus class >> experimentSelectors [
	^ self allExperimentSelectors
		  reject: [ :each | self nonPictureSelectors includes: each ]
]

{ #category : 'inspecting' }
VGAlexandrieCorpus class >> inspectorProgress: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Waiting on'>
	^ aBuilder newTable
		  items: self progressDescription;
		  addColumn: (SpStringTableColumn
				   title: 'Unit'
				   evaluated: [ :each | each first ]);
		  addColumn: (SpStringTableColumn
				   title: 'Cases'
				   evaluated: [ :each | each second ]);
		  yourself
]

{ #category : 'inspecting' }
VGAlexandrieCorpus class >> inspectorProgressContext: aContext [
	"The corpus holds class-side behaviour only, so the view belongs to the class itself: a
	 subclass would have no experiments of its own, and the gate reads its position in the
	 hierarchy rather than naming me."
	aContext active: (self superclass == Object and: [ self isAvailable ])
]

{ #category : 'accessing' }
VGAlexandrieCorpus class >> isAvailable [
	^ self experimentClass notNil and: [ VGCairoInventory isLiveCairoAvailable ]
]

{ #category : 'substitution' }
VGAlexandrieCorpus class >> missingClassUnitTable [
	"The Alexandrie Cairo classes the experiments name that the replacement has no counterpart for,
	 each against the unit of VECTORCANVAS-PLAN.md that owes it. The corpus reads this to say why a
	 case cannot run yet, so a class missing from the table is a gap the test reports."
	^ {
		  (#AeCairoAntialias -> '1.4').
		  (#AeCairoOperator -> '1.7').
		  (#AeCairoFontOptions -> '1.8').
		  (#AeCairoFreetypeFontFace -> '1.8').
		  (#AeCairoHintMetrics -> '1.8').
		  (#AeCairoHintStyle -> '1.8').
		  (#AeCairoScaledFont -> '1.8').
		  (#AeCairoSubpixelOrder -> '1.8').
		  (#AeCairoMeshPattern -> '1.12') }
]

{ #category : 'accessing' }
VGAlexandrieCorpus class >> nonPictureSelectors [
	"The experiments that answer something other than a picture, so there is nothing to compare.
	 #getNumberOfGlyph answers a glyph count, and it asks the global font manager rather than a
	 Cairo surface."
	^ #( #getNumberOfGlyph )
]

{ #category : 'substitution' }
VGAlexandrieCorpus class >> ourNameFor: anAlexandrieClassName [
	"Our name for an Alexandrie Cairo class, which differs only in the prefix, or nil for a class
	 that is not part of the Cairo engine at all."
	^ (anAlexandrieClassName beginsWith: 'AeCairo')
		  ifTrue: [ ('VGCairo' , (anAlexandrieClassName allButFirst: 7)) asSymbol ]
		  ifFalse: [ nil ]
]

{ #category : 'accessing' }
VGAlexandrieCorpus class >> portedClass [
	^ VGAlexandriePortedExperiments
]

{ #category : 'inspecting' }
VGAlexandrieCorpus class >> progressDescription [
	"One row for every unit of the plan that the corpus is waiting on, with the number of cases it
	 unblocks. The counts are asked of the cases themselves, so the view states what the corpus
	 measures now rather than a number written down here."
	| counts |
	counts := self cases
		          inject: Bag new
		          into: [ :bag :each |
			          bag add: (each blockingUnit ifNil: [ 'draws already' ]).
			          bag ].
	^ (counts asSet asSortedCollection: [ :a :b |
		   (VGCairoInventory planUnits indexOf: a) <= (VGCairoInventory planUnits indexOf: b) ])
		  asArray collect: [ :each |
		  {
			  each.
			  (counts occurrencesOf: each) printString } ]
]

{ #category : 'generating' }
VGAlexandrieCorpus class >> regenerate [
	"Compile a derived copy of every experiment onto the ported class and remove the copies whose
	 original is gone. The copies are generated, never edited: VGAlexandrieCorpusTest compares each
	 one against what this would write."
	| wanted |
	wanted := self experimentSelectors asSet.
	self portedClass class selectors do: [ :each |
		(wanted includes: each) ifFalse: [ self portedClass class removeSelector: each ] ].
	self cases do: [ :each | each compilePortedCopy ].
	^ self portedClass class selectors size
]

{ #category : 'accessing' }
VGAlexandrieCorpus class >> toleranceFor: aSelector [
	^ (self toleranceTable detect: [ :each | each key = aSelector ] ifNone: [ nil ])
		  ifNil: [ 0 ]
		  ifNotNil: [ :each | each value ]
]

{ #category : 'accessing' }
VGAlexandrieCorpus class >> toleranceTable [
	"The cases that may not match Cairo exactly, each with how far one channel may differ and why.
	 It is empty while no case renders; a case added here has to carry its reason, so that a
	 tolerance is never a quiet way of passing."
	^ {  }
]

{ #category : 'substitution' }
VGAlexandrieCorpus class >> unitForMissingClass: aClassName [
	^ (self missingClassUnitTable detect: [ :each | each key = aClassName ] ifNone: [ nil ])
		  ifNotNil: [ :each | each value ]
]
