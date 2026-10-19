"
I run every example in VectorGraphics-Cairo-Examples. An example asserts nothing itself, so this is what keeps them working: each one must rebuild its object on every call, answer something, and stay free of the error a skeleton raises, because an example whose own construction is not implemented yet would be useless from the browser. I find the examples by their <sampleInstance> pragma rather than by a list, so a new example is covered the moment it is written.
"
Class {
	#name : 'VGCairoExamplesTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Cairo-Tests-Tests',
	#package : 'VectorGraphics-Cairo-Tests',
	#tag : 'Tests'
}

{ #category : 'accessing' }
VGCairoExamplesTest >> exampleHolders [
	^ {
		  VGAlexandrieCorpusExamples.
		  VGBackendExamples.
		  VGCairoContextExamples.
		  VGCairoImageSurfaceExamples.
		  VGCairoInventoryExamples.
		  VGCairoMatrixExamples.
		  VGConformanceCorpusExamples.
		  VGDisplayListExamples.
		  VGFormComparisonExamples.
		  VGPathExamples.
		  VGRasteriserExamples.
		  VGStrokerExamples }
]

{ #category : 'accessing' }
VGCairoExamplesTest >> exampleMethods [
	"Every class-side method tagged <sampleInstance>, found by the pragma rather than by a list."

	^ self exampleHolders flatCollect: [ :each |
		  each class methods select: [ :method | method hasPragmaNamed: #sampleInstance ] ]
]

{ #category : 'accessing' }
VGCairoExamplesTest >> exampleSubjects [
	"Every object the examples build. One click in the browser shows each of them, so these are
	 the objects whose inspector views have to work."

	^ self exampleMethods collect: [ :each |
		  each methodClass instanceSide perform: each selector ]
]

{ #category : 'tests' }
VGCairoExamplesTest >> testEveryExampleHolderHasAComment [
	| silent |
	silent := self exampleHolders reject: [ :each | each hasComment ].
	self
		assert: silent isEmpty
		description: 'these example classes have no class comment: ' , silent printString
]

{ #category : 'tests' }
VGCairoExamplesTest >> testEveryExampleRebuildsItsObject [
	"An example must answer a fresh object each call, or inspecting one would show state another
	 inspection left behind. A class is its own single instance, so an example that answers a class
	 is exempt."

	| shared |
	shared := OrderedCollection new.
	self exampleMethods do: [ :each |
		| holder first second |
		holder := each methodClass instanceSide.
		first := holder perform: each selector.
		second := holder perform: each selector.
		(first isClass not and: [ first == second ]) ifTrue: [ shared add: each selector ] ].
	self
		assert: shared isEmpty
		description: 'these examples answer the same object twice: ' , shared asArray printString
]

{ #category : 'tests' }
VGCairoExamplesTest >> testEveryExampleRunsAndAnswersSomething [
	| broken |
	broken := OrderedCollection new.
	self exampleMethods do: [ :each |
		[
		(each methodClass instanceSide perform: each selector)
			ifNil: [ broken add: each selector -> 'answered nil' ] ]
			on: Error
			do: [ :error | broken add: each selector -> (error class name , ': ' , error messageText printString) ] ].
	self
		assert: broken isEmpty
		description: 'these examples do not run: ' , broken asArray printString
]

{ #category : 'tests' }
VGCairoExamplesTest >> testEveryViewHasAGate [
	"A view must say when it applies, or it shows a tab full of nils on a half built object. The
	 gate is the view's own selector with Context: in place of the colon."

	| ungated |
	ungated := OrderedCollection new.
	self exampleSubjects do: [ :subject |
		(self viewMethodsOf: subject) do: [ :each |
			| gate |
			gate := ((each value selector allButLast: 1) , 'Context:') asSymbol.
			(each key class canUnderstand: gate) ifFalse: [
				ungated add: each value printString ] ] ].
	self
		assert: ungated asSet isEmpty
		description: 'these views have no gate: ' , ungated asSet asSortedCollection asArray printString
]

{ #category : 'tests' }
VGCairoExamplesTest >> testEveryViewOfAnExampleBuildsAndFillsItsCells [
	"A view that raises when the inspector opens it is worse than no view. Every example is asked
	 for its presenters, and a table is asked for every cell it would show, because a column
	 block only runs when a row is drawn."

	| broken builder |
	builder := SpPresenterBuilder newApplication: SpApplication new.
	broken := OrderedCollection new.
	self exampleSubjects do: [ :subject |
		(self viewMethodsOf: subject) do: [ :each |
			| presenter |
			presenter := nil.
			[ presenter := each key perform: each value selector with: builder ]
				on: Error
				do: [ :error |
					broken add: each value printString -> (error class name , ': ' , error messageText printString) ].
			(presenter isKindOf: SpAbstractListPresenter) ifTrue: [
				presenter items do: [ :item |
					presenter columns do: [ :column |
						[ column evaluation value: item ]
							on: Error
							do: [ :error |
								broken add: each value printString -> (column title , ': ' , error class name) ] ] ] ] ] ].
	self
		assert: broken isEmpty
		description: 'these views do not build: ' , broken asArray printString
]

{ #category : 'accessing' }
VGCairoExamplesTest >> viewMethodsOf: anObject [
	"The inspector views that would show for this object, found by the pragma on both sides, as
	 receiver to method associations: a class-side view is sent to the class."

	| class |
	class := anObject class.
	^ (class methods collect: [ :each | anObject -> each ])
	  , (class class methods collect: [ :each | class -> each ]) select: [ :each |
		  each value hasPragmaNamed: #inspectorPresentationOrder:title: ]
]
