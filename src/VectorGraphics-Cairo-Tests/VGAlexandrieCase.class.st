"
I am one Alexandrie experiment read as a conformance case.

I render my experiment twice, once through Alexandrie and once through the derived copy that runs on
the replacement, and answer how far the two pictures differ. Before that is possible I answer what
blocks me: an Alexandrie class the replacement has no counterpart for, or the first selector a unit
still owes.
"
Class {
	#name : 'VGAlexandrieCase',
	#superclass : 'Object',
	#instVars : [
		'experimentSelector'
	],
	#category : 'VectorGraphics-Cairo-Tests-Conformance',
	#package : 'VectorGraphics-Cairo-Tests',
	#tag : 'Conformance'
}

{ #category : 'instance creation' }
VGAlexandrieCase class >> for: aSelector [
	^ self new setExperimentSelector: aSelector
]

{ #category : 'inspecting' }
VGAlexandrieCase >> blockingDescription [
	"What stops me, asked rather than restated: the unit that unblocks me and the selector my own
	 render stops on first, or a statement that I draw."
	| failure |
	failure := self blockingFailure.
	^ {
		  { 'portable'. self isPortable printString }.
		  { 'blocking unit'. (self blockingUnit ifNil: [ 'none' ]) }.
		  { 'missing classes'.
		  (self missingClassNames asSortedCollection asArray
			   ifEmpty: [ 'none' ]
			   ifNotEmpty: [ :names | ' ' join: names ]) }.
		  { 'stops on'.
		  (failure
			   ifNil: [ self isPortable ifTrue: [ 'nothing, it draws' ] ifFalse: [ 'not asked' ] ]
			   ifNotNil: [ :each | each messageText ]) } }
]

{ #category : 'rendering' }
VGAlexandrieCase >> blockingFailure [
	"The VGNotYetImplemented my own render stops on, or nil when it draws from end to end. Only
	 that one error is caught: any other error is a real defect and must reach the caller."
	self isPortable ifFalse: [ ^ nil ].
	^ [ self ourForm.
	  nil ]
		  on: VGNotYetImplemented
		  do: [ :error | error return: error ]
]

{ #category : 'accessing' }
VGAlexandrieCase >> blockingUnit [
	"The unit that unblocks me: the latest unit owing a class I am missing, since I need all of
	 them, or the unit owing the selector my own render stops on first, or nil once I draw. The
	 units are ordered by VGCairoInventory planUnits, not alphabetically, because 1.12 comes after
	 1.4."
	| units failure |
	units := self missingClassNames
		         collect: [ :each | VGAlexandrieCorpus unitForMissingClass: each ]
		         thenSelect: [ :each | each notNil ].
	units notEmpty ifTrue: [
		^ (units asSortedCollection: [ :a :b |
			   (VGCairoInventory planUnits indexOf: a) <= (VGCairoInventory planUnits indexOf: b) ])
			  last ].
	failure := self blockingFailure.
	^ failure ifNotNil: [ failure unit ]
]

{ #category : 'comparing' }
VGAlexandrieCase >> boundaryPixelAllowance [
	"How many pixels of mine may be further from Alexandrie than my tolerance allows. None,
	 unless I paint a mesh, whose edge is a step the two rasterisers place differently: see
	 VGAlexandrieCorpus class >> meshBoundaryPixelTable."
	^ VGAlexandrieCorpus boundaryPixelAllowanceFor: experimentSelector
]

{ #category : 'rendering' }
VGAlexandrieCase >> cairoForm [
	"The reference picture, drawn by Alexandrie itself."
	^ VGAlexandrieCorpus experimentClass perform: experimentSelector
]

{ #category : 'inspecting' }
VGAlexandrieCase >> classDescription [
	"One row for every Alexandrie class my experiment names: the name it uses, the counterpart the
	 substitution writes, and the unit that owes that counterpart. The rows are read from the
	 corpus tables, so the view cannot drift from what the corpus really knows."
	^ self referencedCairoClassNames asSortedCollection asArray collect: [ :each |
		  {
			  each.
			  (VGAlexandrieCorpus ourNameFor: each).
			  (VGAlexandrieCorpus unitForMissingClass: each) } ]
]

{ #category : 'comparing' }
VGAlexandrieCase >> comparisonWithCairo [
	"How far my picture is from Alexandrie's. Both pictures are drawn afresh, so asking changes
	 nothing."

	^ VGFormComparison between: self ourForm and: self cairoForm
]

{ #category : 'generating' }
VGAlexandrieCase >> compilePortedCopy [
	^ VGAlexandrieCorpus portedClass class
		  compile: self portedSource
		  classified: 'generated - do not edit'
]

{ #category : 'accessing' }
VGAlexandrieCase >> experimentMethod [
	^ VGAlexandrieCorpus experimentClass class >> experimentSelector
]

{ #category : 'accessing' }
VGAlexandrieCase >> experimentSelector [
	^ experimentSelector
]

{ #category : 'inspecting' }
VGAlexandrieCase >> inspectorBlocking: aBuilder [
	<inspectorPresentationOrder: 11 title: 'Blocking'>
	^ aBuilder newTable
		  items: self blockingDescription;
		  addColumn: (SpStringTableColumn
				   title: 'Question'
				   evaluated: [ :each | each first ]);
		  addColumn: (SpStringTableColumn
				   title: 'Answer'
				   evaluated: [ :each | each second ]);
		  yourself
]

{ #category : 'inspecting' }
VGAlexandrieCase >> inspectorBlockingContext: aContext [
	aContext active: experimentSelector notNil
]

{ #category : 'inspecting' }
VGAlexandrieCase >> inspectorClasses: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Classes'>
	^ aBuilder newTable
		  items: self classDescription;
		  addColumn: (SpStringTableColumn
				   title: 'Alexandrie'
				   evaluated: [ :each | each first ]);
		  addColumn: (SpStringTableColumn
				   title: 'Ours'
				   evaluated: [ :each | each second ifNil: [ 'none yet' ] ]);
		  addColumn: (SpStringTableColumn
				   title: 'Owed by'
				   evaluated: [ :each | each third ifNil: [ '' ] ]);
		  yourself
]

{ #category : 'inspecting' }
VGAlexandrieCase >> inspectorClassesContext: aContext [
	aContext active: experimentSelector notNil
]

{ #category : 'accessing' }
VGAlexandrieCase >> isPortable [
	^ self missingClassNames isEmpty
]

{ #category : 'comparing' }
VGAlexandrieCase >> matchesCairo [
	"Three conditions, and the first is the strict one: no pixel of ours outside Alexandrie's
	 shape beyond the residue a rounded edge leaves, no channel further from it than my tolerance
	 allows, and no more pixels beyond that tolerance than my boundary allowance, which is none
	 unless I paint a mesh."
	| comparison |
	comparison := self comparisonWithCairo.
	^ comparison isComparable and: [
		  comparison maximumStrayAlpha <= self strayAlphaAllowance and: [
			  (comparison pixelsFartherThan: self tolerance)
			  <= self boundaryPixelAllowance ] ]
]

{ #category : 'accessing' }
VGAlexandrieCase >> missingClassNames [
	"The Alexandrie classes my experiment needs that the replacement has no counterpart for. While
	 one of these is missing the script cannot even be substituted, let alone run."
	| map |
	map := VGAlexandrieCorpus classNameMap.
	^ self referencedCairoClassNames reject: [ :each |
		  map anySatisfy: [ :one | one key = each ] ]
]

{ #category : 'accessing' }
VGAlexandrieCase >> name [
	^ experimentSelector
]

{ #category : 'rendering' }
VGAlexandrieCase >> ourForm [
	"The same script, drawn by the replacement."
	^ VGAlexandrieCorpus portedClass perform: experimentSelector
]

{ #category : 'generating' }
VGAlexandrieCase >> portedCopyIsCurrent [
	| method |
	method := VGAlexandrieCorpus portedClass class
		          compiledMethodAt: experimentSelector
		          ifAbsent: [ ^ false ].
	^ (method sourceCode trimRight: [ :each | each isSeparator ]) = self portedSource
]

{ #category : 'generating' }
VGAlexandrieCase >> portedSource [
	"My experiment's own source with every Alexandrie class name that has a counterpart of ours
	 substituted for it, and the example pragma dropped, because a derived copy in a test package
	 is not an example. Nothing else changes, which is what makes the copy a faithful script."
	| source |
	source := self experimentMethod sourceCode.
	VGAlexandrieCorpus classNameMap do: [ :each |
		source := source copyReplaceAll: each key with: each value ].
	^ (source copyReplaceAll: '<sampleInstance>' with: '') trimRight: [ :each | each isSeparator ]
]

{ #category : 'printing' }
VGAlexandrieCase >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: ' ';
		nextPutAll: experimentSelector
]

{ #category : 'accessing' }
VGAlexandrieCase >> referencedCairoClassNames [
	"The Alexandrie Cairo classes my experiment names, read from its literals."
	^ (self experimentMethod literals
		   select: [ :each |
			   each isVariableBinding and: [
				   each key isSymbol and: [ each key beginsWith: 'AeCairo' ] ] ]
		   thenCollect: [ :each | each key ]) asSortedCollection asArray
]

{ #category : 'initialization' }
VGAlexandrieCase >> setExperimentSelector: aSelector [
	experimentSelector := aSelector
]

{ #category : 'comparing' }
VGAlexandrieCase >> strayAlphaAllowance [
	"How heavy a pixel I may paint outside Alexandrie's shape. The corpus's own allowance of one
	 step of coverage, unless I paint a mesh: see VGAlexandrieCorpus class >>
	 strayAlphaAllowanceFor:."
	^ VGAlexandrieCorpus strayAlphaAllowanceFor: experimentSelector
]

{ #category : 'comparing' }
VGAlexandrieCase >> tolerance [
	"How far a channel of mine may differ from Alexandrie before I count as a mismatch. Zero is
	 the default, because a rasteriser that matches Cairo exactly is the goal."
	^ VGAlexandrieCorpus toleranceFor: experimentSelector
]
