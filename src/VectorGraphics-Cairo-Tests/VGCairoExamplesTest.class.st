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
VGCairoExamplesTest class >> windowExamplePrefix [
	"An example whose selector begins with this opens a window. The suite does not run one:
	 see testAnExampleThatOpensAWindowIsNamedForItAndNoGateRunsIt for why the name carries
	 the rule rather than a list of selectors."

	^ 'open'
]

{ #category : 'accessing' }
VGCairoExamplesTest >> allExampleMethods [
	"Every class-side method tagged <sampleInstance>, found by the pragma rather than by a
	 list, window examples included."

	^ self exampleHolders flatCollect: [ :each |
		  each class methods select: [ :method |
			  method hasPragmaNamed: #sampleInstance ] ]
]

{ #category : 'accessing' }
VGCairoExamplesTest >> cellComplaintsOf: aListPresenter named: aViewName [
	"Every cell this table would draw, asked for: a column block only runs when a row is drawn, so
	 a cell that raises shows for the first time under a reader's eyes."

	| complaints |
	complaints := OrderedCollection new.
	aListPresenter items do: [ :item |
		aListPresenter columns do: [ :column |
			[ column evaluation value: item ]
				on: Error
				do: [ :error |
					complaints add:
						aViewName -> (column title , ': ' , error class name) ] ] ].
	^ complaints
]

{ #category : 'accessing' }
VGCairoExamplesTest >> complaintsAbout: aReceiverAndMethod builtWith: aBuilder [
	"What goes wrong when the inspector opens this view on this object, as view name to reason
	 associations, empty when nothing does. Building it can raise; what it answers has to be a
	 presenter, because the inspector sends `asInspection` to it, which an ordinary object such as
	 a `Form` does not understand and which is outside the handler
	 `StInspectionContext >> newInspectionPresenterOnApplication:` wraps the build in; and a table's
	 cells can raise, which `cellComplaintsOf:named:` asks for."

	| method presenter |
	method := aReceiverAndMethod value.
	presenter := [ aReceiverAndMethod key perform: method selector with: aBuilder ]
		             on: Error
		             do: [ :error |
			             ^ { (method printString
				                -> (error class name , ': '
					                 , error messageText printString)) } ].
	(presenter isKindOf: SpPresenter) ifFalse: [
		^ { (method printString
			   -> (presenter class name
				    , ' is not a presenter the inspector can show')) } ].
	(presenter isKindOf: SpAbstractListPresenter) ifFalse: [ ^ #(  ) ].
	^ self cellComplaintsOf: presenter named: method printString
]

{ #category : 'accessing' }
VGCairoExamplesTest >> defaultTimeLimit [
	"Every example of every family is rebuilt and every view of each is built and filled, which
	 takes minutes rather than the ten seconds SUnit allows a test by default. Without this a
	 package run reported a timeout where it should report which view does not build."
	^ 10 minutes
]

{ #category : 'accessing' }
VGCairoExamplesTest >> exampleHolders [
	^ {
		  VGA8GaussianBlurFilterExamples.
		  VGAlexandrieCorpusExamples.
		  VGAlexandrieFontLifetimeExamples.
		  VGArchitectureExamples.
		  VGBackendExamples.
		  VGCairoContextExamples.
		  VGCairoExportSurfaceExamples.
		  VGCairoImageSurfaceExamples.
		  VGCairoInventoryExamples.
		  VGCairoMatrixExamples.
		  VGCairoReferenceScannerExamples.
		  VGCairoStrokeStyleExamples.
		  VGClipExamples.
		  VGConformanceCorpusExamples.
		  VGDisplayListExamples.
		  VGFormComparisonExamples.
		  VGMeshExamples.
		  VGPaintExamples.
		  VGPathExamples.
		  VGRasteriserExamples.
		  VGScaledFontExamples.
		  VGSpanScannerExamples.
		  VGStrokerExamples }
]

{ #category : 'accessing' }
VGCairoExamplesTest >> exampleMethods [
	"The examples every gate below runs: all of them but the ones that open a window."

	^ self allExampleMethods reject: [ :each |
		  each selector beginsWith: self class windowExamplePrefix ]
]

{ #category : 'accessing' }
VGCairoExamplesTest >> exampleSubjects [
	"Every object the examples build. One click in the browser shows each of them, so these are
	 the objects whose inspector views have to work."

	^ self exampleMethods collect: [ :each |
		  each methodClass instanceSide perform: each selector ]
]

{ #category : 'accessing' }
VGCairoExamplesTest >> projectDefines: aCompiledMethodOrClass [
	"Whether this project wrote the method, or the class, it is asked about: both answer the
	 package they live in. An example answers an ordinary Pharo object as often as one of ours — a
	 `Form`, a `ByteArray` — and Pharo's own inspector views on those objects are not ours to gate
	 or to hold to this project's rules. Every package of the project counts, not only the ones
	 the Cairo reference scan covers: that scan skips the suites, the conformance corpus and the
	 benchmark harness because they name the alternatives on purpose, and a view written there is
	 still a view an example opens with one click."

	| package |
	package := aCompiledMethodOrClass package.
	^ package notNil and: [
		  package name beginsWith: VGCairoReferenceScanner projectPackagePrefix ]
]

{ #category : 'accessing' }
VGCairoExamplesTest >> replacedStackDefines: aCompiledMethod [
	"Whether the stack this project replaces wrote the method. A view of Alexandrie's or Bloc's
	 that a class of ours inherits shows for our object, so it is ours to keep working: when it is
	 broken there, the override goes in our own class and never in theirs."

	| package |
	package := aCompiledMethod package.
	^ package notNil and: [
		  VGArchitectureTest replacedStackPackageNamePrefixes anySatisfy: [ :prefix |
			  package name beginsWith: prefix ] ]
]

{ #category : 'tests' }
VGCairoExamplesTest >> testAnExampleThatOpensAWindowIsNamedForItAndNoGateRunsIt [
	"Three freezes on 4 November, all of them this: an example that opens a window and drives
	 the device through uFFI is run four times by one pass of these gates — once by
	 testEveryExampleRunsAndAnswersSomething, twice by testEveryExampleRebuildsItsObject, and
	 again through exampleSubjects for each view gate — and an error raised in that window
	 opens a debugger on the process serving the call, which then answers nothing at all. Such
	 an example is run by hand, alone, after a commit. So the running gates take
	 exampleMethods, which leaves those out, and this test holds what is left of the rule: a
	 window example is named for what it does, it is a class-side example of a holder like any
	 other, and it is none of the examples a gate runs."

	| windowExamples |
	windowExamples := self windowExampleMethods.
	windowExamples do: [ :each |
		self assert: each methodClass isClassSide.
		self assert: each numArgs equals: 0.
		self assert: (each hasPragmaNamed: #sampleInstance).
		self assert:
			(each selector beginsWith: self class windowExamplePrefix) ].
	self assert:
		(self exampleMethods noneSatisfy: [ :each | windowExamples includes: each ]).
	self
		assert: self allExampleMethods size
		equals: self exampleMethods size + windowExamples size
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
	"A view that raises when the inspector opens it is worse than no view. Every view a reader
	 opens on every example is built, asked for what it answered, and asked for its cells;
	 `complaintsAbout:builtWith:` says what each of those three can get wrong."

	| broken builder |
	builder := SpPresenterBuilder newApplication: SpApplication new.
	broken := OrderedCollection new.
	self exampleSubjects do: [ :subject |
		(self viewMethodsAReaderOpensOf: subject) do: [ :each |
			broken addAll: (self complaintsAbout: each builtWith: builder) ] ].
	self
		assert: broken isEmpty
		description: 'these views do not build: ' , broken asArray printString
]

{ #category : 'accessing' }
VGCairoExamplesTest >> viewMethodsAReaderOpensOf: anObject [
	"Every view a reader meets on an object of ours, which is more than the views the project
	 wrote: the selector is looked up, so a view inherited from a superclass counts, and when the
	 object's own class is one of ours a view the replaced stack wrote counts too. An Alexandrie
	 view that a class of ours inherits opens with one click on our example, so it is ours to keep
	 working, and the place to mask a break there is our own class. On an object an example merely
	 answers — a `Form`, a `BlElement` — the views of its own stack are no more ours to gate than
	 Pharo's are; see `projectDefines:`."

	| class instanceSideViews classSideViews ours |
	class := anObject class.
	ours := self projectDefines: class.
	instanceSideViews := class allSelectors asArray collect: [ :each |
		                     anObject -> (class lookupSelector: each) ].
	classSideViews := class class allSelectors asArray collect: [ :each |
		                  class -> (class class lookupSelector: each) ].
	^ instanceSideViews , classSideViews select: [ :each |
		  (each value hasPragmaNamed: #inspectorPresentationOrder:title:) and: [
			  (self projectDefines: each value) or: [
				  ours and: [ self replacedStackDefines: each value ] ] ] ]
]

{ #category : 'accessing' }
VGCairoExamplesTest >> viewMethodsOf: anObject [
	"The inspector views of this project that would show for this object, found by the pragma on
	 both sides, as receiver to method associations: a class-side view is sent to the class.
	 Pharo's own views on an object an example answers are left out; see `projectDefines:`. This
	 is the set the project's own rules apply to, so a view it inherits is not here; see
	 `viewMethodsAReaderOpensOf:` for the wider set."

	| class |
	class := anObject class.
	^ (class methods collect: [ :each | anObject -> each ])
	  , (class class methods collect: [ :each | class -> each ]) select: [ :each |
		  (each value hasPragmaNamed: #inspectorPresentationOrder:title:) and: [
			  self projectDefines: each value ] ]
]

{ #category : 'accessing' }
VGCairoExamplesTest >> windowExampleMethods [
	"The examples that open a window, which a suite must not run: an error inside one opens a
	 debugger and the process serving the call answers nothing."

	^ self allExampleMethods select: [ :each |
		  each selector beginsWith: self class windowExamplePrefix ]
]
