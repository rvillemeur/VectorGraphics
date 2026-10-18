"
I am the abstract root of the Cairo replacement classes, and I exist for one reason: to give both the instance side and the class side of my subclasses the notYetImplementedInUnit: hook that a skeleton method sends.

My subclasses are VGCairoContext, VGCairoImageSurface and VGCairoPattern. I hold no state and I know nothing about Cairo.
"
Class {
	#name : 'VGCairoObject',
	#superclass : 'Object',
	#category : 'VectorGraphics-Cairo-Skeleton',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Skeleton'
}

{ #category : 'inspecting' }
VGCairoObject class >> inspectorClassSideSkeletons: aBuilder [
	<inspectorPresentationOrder: 20 title: 'Skeletons'>
	"The same question asked of my class side, where the constructors live."

	^ aBuilder newTable
		  items: self skeletonSelectorsWithUnit asArray;
		  addColumn: (SpStringTableColumn title: 'Selector' evaluated: [ :each | each key ]);
		  addColumn: (SpStringTableColumn title: 'Owed by unit' evaluated: [ :each | each value ]);
		  yourself
]

{ #category : 'inspecting' }
VGCairoObject class >> inspectorClassSideSkeletonsContext: aContext [
	"Gated on there being something left to implement, so a finished class shows no tab."

	aContext active: self skeletonSelectorsWithUnit notEmpty
]

{ #category : 'skeleton' }
VGCairoObject class >> notYetImplementedIn: aUnitString selector: aSymbol [
	"The class-side twin of the instance-side hook: several inventory selectors are constructors."

	^ VGNotYetImplemented signalForSelector: aSymbol unit: aUnitString
]

{ #category : 'reflecting' }
VGCairoObject class >> skeletonSelectorsWithUnit [
	"Which of my class-side selectors are still skeletons, each with the unit that owes it."

	| pairs |
	pairs := OrderedCollection new.
	self class withAllSuperclasses do: [ :each |
		each methods do: [ :method |
			(method sendsSelector: #notYetImplementedIn:selector:) ifTrue: [
				pairs add: method selector -> (self unitOfSkeletonMethod: method) ] ] ].
	^ pairs asSortedCollection: [ :one :other | one key <= other key ]
]

{ #category : 'reflecting' }
VGCairoObject class >> unitOfSkeletonMethod: aCompiledMethod [
	"The unit a skeleton names, taken from the only literal string in it: the selector it reports is
	 a symbol and the unit is a string, so the two cannot be confused."

	^ aCompiledMethod literals
		  detect: [ :each | each isString and: [ each isSymbol not ] ]
		  ifNone: [ nil ]
]

{ #category : 'resources' }
VGCairoObject >> autoRelease [
	"A no-op: I hold no external resource, so there is nothing for the finalisation registry to
	 free. The selector exists because a caller written against Cairo sends it."

	^ self
]

{ #category : 'resources' }
VGCairoObject >> externallyFree [
	"A no-op, for the same reason as autoRelease: my pixels are Pharo objects, or they belong to the
	 host window that lent them to me."

	^ self
]

{ #category : 'inspecting' }
VGCairoObject >> inspectorSkeletons: aBuilder [
	<inspectorPresentationOrder: 20 title: 'Skeletons'>
	"What I still owe, asked of my own compiled methods rather than restated here."

	^ aBuilder newTable
		  items: self skeletonSelectorsWithUnit asArray;
		  addColumn: (SpStringTableColumn title: 'Selector' evaluated: [ :each | each key ]);
		  addColumn: (SpStringTableColumn title: 'Owed by unit' evaluated: [ :each | each value ]);
		  yourself
]

{ #category : 'inspecting' }
VGCairoObject >> inspectorSkeletonsContext: aContext [
	"The tab is offered only while something is missing, so it disappears by itself as the units
	 land."

	aContext active: self skeletonSelectorsWithUnit notEmpty
]

{ #category : 'skeleton' }
VGCairoObject >> notYetImplementedIn: aUnitString selector: aSymbol [
	"A skeleton: the selector is here so that the calling surface is complete and so that a
	 conformance case names the unit that owes it, rather than failing with a doesNotUnderstand."

	^ VGNotYetImplemented signalForSelector: aSymbol unit: aUnitString
]

{ #category : 'reflecting' }
VGCairoObject >> skeletonSelectorsWithUnit [
	"Which of my selectors are still skeletons, each with the unit that owes it. The answer is read
	 from the methods themselves, by the send every skeleton makes, so it cannot drift from the code
	 the way a hand-kept list would. The whole superclass chain is scanned, because only this
	 hierarchy makes that send."

	| pairs |
	pairs := OrderedCollection new.
	self class withAllSuperclasses do: [ :each |
		each methods do: [ :method |
			(method sendsSelector: #notYetImplementedIn:selector:) ifTrue: [
				pairs add: method selector -> (self class unitOfSkeletonMethod: method) ] ] ].
	^ pairs asSortedCollection: [ :one :other | one key <= other key ]
]

{ #category : 'accessing' }
VGCairoObject >> status [
	"Cairo puts a status on every context and surface, and AeCanvas sends ensureIsSuccess to it. A
	 pure Pharo target has no C error code to report, so the answer is success."

	^ VGCairoStatus success
]
