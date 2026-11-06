"
I hold the documents of this package to the code they describe.

The package comment is the map a reader sees first in the browser, so I check that it names every tag the package has and no tag it does not have: a renamed tag fails here instead of sending a reader to a part of the package that is not there. I read only the list under the `Tags:` heading, since the comment holds other lists; `tagNamesNamedBy:` is that reader and is tested on its own degenerate states.

`doc/ARCHITECTURE.md` is the second document, and I hold every name it writes in backticks to the image: a capitalised word must be a class, a class variable of this package or a package; a `Class >> selector` form must be answered by that class; a keyword selector on its own must be implemented somewhere. I read nothing inside a fenced code block, because the diagram in one is a drawing rather than a claim, and I say nothing about a unary token, which cannot be told from an instance variable name. The document is a file of the repository and not of the image, so I skip when there is no checkout to read.

I grow with the third documentation artefact of this package, the inspector views of the engine, whose examples I build. `VGCairoExamplesTest` does the same work for the layers above, but I cannot subclass it: `VGArchitectureTest class >> allowedDependencies` gives this package no outgoing edge, so no class here may name one of `VectorGraphics-Cairo-Tests`.
"
Class {
	#name : 'VectorGraphicsDocumentationTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Tests-Tests',
	#package : 'VectorGraphics-Tests',
	#tag : 'Tests'
}

{ #category : 'accessing' }
VectorGraphicsDocumentationTest class >> concreteGates [
	"Every gate that names a package, found by walking up to the abstract root of the hierarchy
	and back down. Walked rather than listed so that a gate added for a new package is seen by
	the gates already here, and so that no method names this class."

	| root |
	root := self.
	[ root isAbstract ] whileFalse: [ root := root superclass ].
	^ root withAllSubclasses reject: [ :each | each isAbstract ]
]

{ #category : 'accessing' }
VectorGraphicsDocumentationTest class >> documentedPackages [
	"Every code package this hierarchy documents. The architecture document covers the whole
	project, so the name gates are read against all of them, whichever subclass runs."

	^ self concreteGates collect: [ :each | each packageUnderTest ]
]

{ #category : 'testing' }
VectorGraphicsDocumentationTest class >> isAbstract [
	"The documentation gates are written once and run once per code package, so only the
	subclasses, each of which names a package, have a suite. Each subclass answers false."

	^ true
]

{ #category : 'accessing' }
VectorGraphicsDocumentationTest class >> packageUnderTest [
	"The code package a concrete subclass documents. On the class side so that the whole
	hierarchy can be asked which packages are documented without building an instance."

	^ self subclassResponsibility
]

{ #category : 'accessing' }
VectorGraphicsDocumentationTest >> architectureDocumentContents [
	"Answer the text of the architecture document, or nil when there is none to read."

	| file |
	file := self architectureDocumentFile ifNil: [ ^ nil ].
	^ file exists ifTrue: [ file contents ] ifFalse: [ nil ]
]

{ #category : 'accessing' }
VectorGraphicsDocumentationTest >> architectureDocumentFile [
	"Answer the architecture document, or nil when this image has no checkout of the project.
	The document is a file of the repository, not of the image, so an image that loaded the
	package from Metacello has no copy of it and the gates below skip rather than fail."

	| repository |
	repository := IceRepository registry
		detect: [ :each | each name = self repositoryName ]
		ifNone: [ ^ nil ].
	^ repository location / 'doc' / self architectureDocumentName
]

{ #category : 'accessing' }
VectorGraphicsDocumentationTest >> architectureDocumentMayName: aToken [
	"A capitalised name of the document is held to one of three things that really exist: a class
	of the image, a class variable of a class of a documented package, or a package."

	(Smalltalk includesKey: aToken asSymbol) ifTrue: [ ^ true ].
	(self classVariableNamesOfTheDocumentedPackages includes: aToken) ifTrue: [ ^ true ].
	^ (PackageOrganizer default packageNamed: aToken ifAbsent: [ nil ]) notNil
]

{ #category : 'accessing' }
VectorGraphicsDocumentationTest >> architectureDocumentName [
	^ 'ARCHITECTURE.md'
]

{ #category : 'parsing' }
VectorGraphicsDocumentationTest >> backtickedTokensOf: aString [
	"Answer every piece of aString written between two backticks, outside a fenced code block.
	A fence is skipped because the diagram inside it is a drawing, not a claim about a name."

	| tokens insideAFence |
	tokens := OrderedCollection new.
	insideAFence := false.
	aString lines do: [ :line |
		(line beginsWith: '```')
			ifTrue: [ insideAFence := insideAFence not ]
			ifFalse: [ insideAFence ifFalse: [ self backtickedTokensOf: line into: tokens ] ] ].
	^ tokens
]

{ #category : 'parsing' }
VectorGraphicsDocumentationTest >> backtickedTokensOf: aLine into: aCollection [
	"Add every backticked piece of one line to aCollection. An unclosed backtick ends the line."

	| index |
	index := 1.
	[ (index := aLine indexOf: $` startingAt: index) > 0 ] whileTrue: [
		| closing |
		closing := aLine indexOf: $` startingAt: index + 1.
		closing = 0
			ifTrue: [ index := aLine size + 1 ]
			ifFalse: [
				aCollection add: (aLine copyFrom: index + 1 to: closing - 1).
				index := closing + 1 ] ]
]

{ #category : 'parsing' }
VectorGraphicsDocumentationTest >> behaviourNamedBy: aString [
	"Answer the class or metaclass aString names, or nil. 'Foo class' names the metaclass."

	| isClassSide name class |
	isClassSide := aString endsWith: self classSideSuffix.
	name := isClassSide
		ifTrue: [ (aString allButLast: self classSideSuffix size) trimmed ]
		ifFalse: [ aString trimmed ].
	class := Smalltalk at: name asSymbol ifAbsent: [ ^ nil ].
	(class isBehavior) ifFalse: [ ^ nil ].
	^ isClassSide ifTrue: [ class class ] ifFalse: [ class ]
]

{ #category : 'running' }
VectorGraphicsDocumentationTest >> buildView: aSelector of: anObject [
	"Build one inspector view the way the inspector really builds it, through
	StInspectionContext, so that a view this gate passes is a view a reader can open:
	basicNewInspectionPresenter: hands the method a presenter builder, which is the only
	supported way since Pharo 13, and refuses a view that does not take one.
	newInspectionPresenterOnApplication: is not used here because it answers a debug presenter
	instead of failing. A table's column blocks run per drawn row only, so this runs each of them
	over each item itself; otherwise a broken column would pass."

	| context presenter |
	context := StInspectionContext new
		           inspectedObject: anObject;
		           methodSelector: aSelector;
		           yourself.
	presenter := context basicNewInspectionPresenter:
		             (SpPresenterBuilder newApplication: SpApplication new).
	self
		assert: presenter notNil
		description: anObject class name , ' >> ' , aSelector , ' builds nothing'.
	(presenter isKindOf: SpTablePresenter) ifTrue: [
		presenter columns do: [ :column |
			presenter items do: [ :item | column evaluation value: item ] ] ].
	^ presenter
]

{ #category : 'parsing' }
VectorGraphicsDocumentationTest >> classSideSuffix [
	^ ' class'
]

{ #category : 'accessing' }
VectorGraphicsDocumentationTest >> classVariableNamesOfTheDocumentedPackages [
	"Answer the names of every class variable declared by a class of the documented packages, so
	the document may name one — the font caches are class variables, not classes."

	| names |
	names := Set new.
	self documentedPackages do: [ :package |
		package definedClasses do: [ :each |
			names addAll: (each classVariables collect: [ :variable | variable name asString ]) ] ].
	^ names
]

{ #category : 'accessing' }
VectorGraphicsDocumentationTest >> documentedPackages [
	"Every code package this hierarchy documents; the class side walks the hierarchy for them."

	^ self class documentedPackages
]

{ #category : 'accessing' }
VectorGraphicsDocumentationTest >> examplesPackageUnderTest [
	"The sibling package holding this package's examples. The examples live in their own package
	since the split, so the examples gate below reads that one, not the code package. Strict on
	purpose: a code package with no examples package is a hole the gate must report."

	^ PackageOrganizer default packageNamed: self packageUnderTest name , '-Examples'
]

{ #category : 'accessing' }
VectorGraphicsDocumentationTest >> inspectorViewSelectorsOf: aClass [
	"Answer the selectors of aClass that are inspector views, read from the pragma rather than
	from a naming convention, so a renamed method cannot slip out of the gates below."

	^ (aClass selectors select: [ :each |
		   (aClass >> each) pragmas anySatisfy: [ :pragma |
			   pragma selector = #inspectorPresentationOrder:title: ] ]) asSortedCollection asArray
]

{ #category : 'parsing' }
VectorGraphicsDocumentationTest >> isClassNameToken: aToken [
	"A backticked token is read as a name of the image when it is one word beginning with a
	capital. An expression, an instance variable, a selector, a file extension and a hexadecimal
	literal are all claims this test cannot check, and it leaves them alone."

	^ aToken notEmpty
		and: [ aToken first isUppercase
		and: [ aToken allSatisfy: [ :each | each isAlphaNumeric ] ] ]
]

{ #category : 'testing' }
VectorGraphicsDocumentationTest >> isImplementedMethodToken: aToken [
	"The named class must answer the named selector. Inherited counts: the document speaks of
	what a class does, not of which class in the hierarchy holds the method. The separator is
	found as a substring rather than with substrings:, which would also split on each $> alone."

	| separator index behaviour selector |
	separator := self qualifiedSelectorSeparator.
	index := aToken indexOfSubCollection: separator.
	index = 0 ifTrue: [ ^ false ].
	behaviour := self behaviourNamedBy: (aToken first: index - 1).
	behaviour ifNil: [ ^ false ].
	selector := (aToken allButFirst: index - 1 + separator size) trimmed.
	^ behaviour canUnderstand: selector asSymbol
]

{ #category : 'parsing' }
VectorGraphicsDocumentationTest >> isKeywordSelectorToken: aToken [
	"A token holding a colon and no space is read as a keyword selector on its own. A unary
	selector cannot be told from an instance variable name, so this test says nothing about one."

	^ (aToken includes: $:)
		and: [ (aToken includes: Character space) not ]
]

{ #category : 'parsing' }
VectorGraphicsDocumentationTest >> isQualifiedSelectorToken: aToken [
	"A token of the form Class >> selector, or Class class >> selector, names one method."

	^ aToken includesSubstring: self qualifiedSelectorSeparator
]

{ #category : 'accessing' }
VectorGraphicsDocumentationTest >> packageComment [
	"What a reader sees first when the package is selected in the browser. Pharo keeps it as the
	 comment of the package manifest class."

	^ self packageUnderTest packageComment ifNil: [ '' ]
]

{ #category : 'accessing' }
VectorGraphicsDocumentationTest >> packageUnderTest [
	"The package these tests document. The subclass names it on the class side."

	^ self class packageUnderTest
]

{ #category : 'parsing' }
VectorGraphicsDocumentationTest >> qualifiedSelectorSeparator [
	^ ' >> '
]

{ #category : 'accessing' }
VectorGraphicsDocumentationTest >> repositoryName [
	^ 'VectorGraphics'
]

{ #category : 'accessing' }
VectorGraphicsDocumentationTest >> siblingTestsPackage [
	"The sibling package holding this package's tests — the package this gate itself lives in.
	Read by name rather than from `self class package` so that the answer is the same whichever
	subclass runs, and so that a gate misplaced into another package fails the gate below.
	Not named for the package the way `examplesPackageUnderTest` is: a selector beginning with
	`test` is built into the suite by SUnit and would run as a test of its own."

	^ PackageOrganizer default packageNamed: self packageUnderTest name , '-Tests'
]

{ #category : 'running' }
VectorGraphicsDocumentationTest >> skipTheDocumentIsAbsent [
	"The document is a file of the repository; an image that loaded the package from Metacello
	has none, and these gates say nothing there."

	^ self skip: 'There is no checkout of ' , self repositoryName , ' in this image'
]

{ #category : 'running' }
VectorGraphicsDocumentationTest >> stateSnapshotOf: anObject [
	"Answer what every instance variable of anObject holds, with a copy of each collection, so a
	view that moved a point or inserted an element is caught rather than described."

	^ (1 to: anObject class instSize) collect: [ :index |
		   | value |
		   value := anObject instVarAt: index.
		   (value isCollection and: [ value isString not ])
			   ifTrue: [ value copy ]
			   ifFalse: [ value ] ]
]

{ #category : 'accessing' }
VectorGraphicsDocumentationTest >> tagHeadingOfThePackageComment [
	"The line the tag list follows. Changing it means changing the comment and this constant
	 together, which is why it is named once here."

	^ 'Tags:'
]

{ #category : 'accessing' }
VectorGraphicsDocumentationTest >> tagNamesNamedBy: aComment [
	"Every name aComment lists as a tag. The list is the one under the Tags: heading, one line a
	 tag, beginning with a dash and the name in backquotes, and it ends at the first line after it
	 that is neither such a line nor blank. A comment holds other lists, so the heading and the end
	 are both needed to tell them apart."

	| lines start names |
	lines := aComment lines.
	start := lines indexOf: self tagHeadingOfThePackageComment.
	start = 0 ifTrue: [ ^ Set new ].
	names := Set new.
	(lines allButFirst: start) do: [ :each |
		(each beginsWith: '- `')
			ifTrue: [
				| rest |
				rest := each allButFirst: 3.
				names add: (rest first: (rest indexOf: $`) - 1) ]
			ifFalse: [ (each trimmed isEmpty and: [ names isEmpty ]) ifFalse: [ ^ names ] ] ].
	^ names
]

{ #category : 'accessing' }
VectorGraphicsDocumentationTest >> tagNamesNamedByThePackageComment [
	"The tags the package comment lists, as strings."

	^ self tagNamesNamedBy: self packageComment
]

{ #category : 'accessing' }
VectorGraphicsDocumentationTest >> tagNamesOfThePackage [
	"The tags the package really has, as strings, so that a comparison with what a document says
	 does not depend on symbols."

	^ (self packageUnderTest tags collect: [ :each | each name asString ]) asSet
]

{ #category : 'tests' }
VectorGraphicsDocumentationTest >> testEveryClassWithAViewIsFedByAnExampleOfItsOwnKind [
	self viewSubjects do: [ :pair |
		| subject holder selector instance |
		subject := pair key.
		holder := pair value key.
		selector := pair value value.
		self
			assert: (holder class includesSelector: selector)
			description: holder name , ' does not hold the example ' , selector.
		self
			assert: ((holder class >> selector) pragmas anySatisfy: [ :each | each selector = #sampleInstance ])
			description: holder name , ' >> ' , selector , ' is not a sample instance'.
		instance := holder perform: selector.
		self
			assert: (instance isKindOf: subject)
			description: holder name , ' >> ' , selector , ' does not answer a ' , subject name.
		self
			assert: (self inspectorViewSelectorsOf: subject) notEmpty
			description: subject name , ' has no inspector view' ]
]

{ #category : 'tests' }
VectorGraphicsDocumentationTest >> testEveryInspectorViewOfThisPackageBuildsFromItsExample [
	self viewSubjects do: [ :pair |
		| instance |
		instance := pair value key perform: pair value value.
		(self inspectorViewSelectorsOf: pair key) do: [ :selector |
			self buildView: selector of: instance ] ]
]

{ #category : 'tests' }
VectorGraphicsDocumentationTest >> testEveryInspectorViewOfThisPackageTakesAPresenterBuilder [
	"Pharo hands an inspector view the presenter builder it must build with. A view that
	instantiates a presenter itself is refused — 'Inspections made without presenter builder are
	no longer supported' — when a reader opens the object. The rule is read from
	StInspectionContext rather than restated here, so it cannot drift from the inspector, and the
	package's own methods are read, so an extension method on a class of another package is too."

	| wrong |
	wrong := OrderedCollection new.
	self packageUnderTest methods do: [ :method |
		method pragmas do: [ :pragma |
			(pragma selector = #inspectorPresentationOrder:title: and: [
				 (StInspectionContext new
					  methodSelector: method selector;
					  yourself) methodSelectorNeedsBuilder not ]) ifTrue: [
				wrong add: method methodClass name , ' >> ' , method selector ] ] ].
	self
		assert: wrong isEmpty
		description: 'these views take no presenter builder: ' , wrong asArray printString
]

{ #category : 'tests' }
VectorGraphicsDocumentationTest >> testEveryMethodTheArchitectureDocumentNamesIsImplementedByThatClass [
	| contents missing |
	contents := self architectureDocumentContents ifNil: [ ^ self skipTheDocumentIsAbsent ].
	missing := ((self backtickedTokensOf: contents)
		select: [ :each | self isQualifiedSelectorToken: each ])
			reject: [ :each | self isImplementedMethodToken: each ].
	self
		assert: missing isEmpty
		description: 'Named by the document, not answered by that class: '
			, missing asSet asSortedCollection asArray printString
]

{ #category : 'tests' }
VectorGraphicsDocumentationTest >> testEveryNameTheArchitectureDocumentBackticksExists [
	| contents unknown |
	contents := self architectureDocumentContents ifNil: [ ^ self skipTheDocumentIsAbsent ].
	unknown := ((self backtickedTokensOf: contents)
		select: [ :each | self isClassNameToken: each ])
			reject: [ :each | self architectureDocumentMayName: each ].
	self
		assert: unknown isEmpty
		description: 'Named by the document, absent from the image: '
			, unknown asSet asSortedCollection asArray printString
]

{ #category : 'tests' }
VectorGraphicsDocumentationTest >> testEverySampleInstanceOfThisPackageRuns [
	"Each example of this package rebuilds its subject on every call and must run with one click.
	A failure here is a broken example, which a reader meets before any test."

	| holders broken |
	holders := self examplesPackageUnderTest definedClasses select: [ :each |
		           each class selectors anySatisfy: [ :selector |
			           (each class >> selector) pragmas anySatisfy: [ :pragma |
				           pragma selector = #sampleInstance ] ] ].
	self
		assert: holders notEmpty
		description: self examplesPackageUnderTest name , ' holds no example'.
	broken := OrderedCollection new.
	holders do: [ :holder |
		(holder class selectors select: [ :selector |
			 (holder class >> selector) pragmas anySatisfy: [ :pragma |
				 pragma selector = #sampleInstance ] ]) do: [ :selector |
			[ (holder perform: selector) ifNil: [ broken add: holder name , ' >> ' , selector , ' answers nil' ] ]
				on: Error
				do: [ :error | broken add: holder name , ' >> ' , selector , ' ' , error messageText printString ] ] ].
	self assert: broken isEmpty description: broken asArray printString
]

{ #category : 'tests' }
VectorGraphicsDocumentationTest >> testEverySelectorTheArchitectureDocumentNamesOnItsOwnIsImplemented [
	| contents missing |
	contents := self architectureDocumentContents ifNil: [ ^ self skipTheDocumentIsAbsent ].
	missing := ((self backtickedTokensOf: contents)
		select: [ :each |
			(self isKeywordSelectorToken: each)
				and: [ (self isQualifiedSelectorToken: each) not ] ])
			reject: [ :each | (SystemNavigation default allImplementorsOf: each asSymbol) notEmpty ].
	self
		assert: missing isEmpty
		description: 'Named by the document, implemented nowhere: '
			, missing asSet asSortedCollection asArray printString
]

{ #category : 'tests' }
VectorGraphicsDocumentationTest >> testEveryTestClassOfThisPackageHasAClassComment [
	"A test class is documentation: it says which facts about a subject are held. A reader opening
	the test package sees the class list first, so a nameless entry there costs as much as an
	undocumented class in the code package. The code packages are already held to this by the
	class-comment rule of Renraku; the test packages were not held to anything until here."

	| commentless |
	commentless := (self siblingTestsPackage definedClasses select: [ :each |
		                (each inheritsFrom: TestCase) and: [
			                (each comment ifNil: [ '' ]) trimBoth isEmpty ] ]) collect: [
		               :each | each name ].
	self
		assert: commentless isEmpty
		description: 'test classes with no class comment: '
			, commentless asSortedCollection asArray printString
]

{ #category : 'tests' }
VectorGraphicsDocumentationTest >> testNoInspectorViewOfThisPackageChangesWhatItInspects [
	"A view a reader opens to understand an object must not be what changes it. The engine
	buffers and the glyph points are both mutable in place, so this compares them element by
	element after every view of the class has been built."

	self viewSubjects do: [ :pair |
		| instance before after |
		instance := pair value key perform: pair value value.
		before := self stateSnapshotOf: instance.
		(self inspectorViewSelectorsOf: pair key) do: [ :selector |
			self buildView: selector of: instance ].
		after := self stateSnapshotOf: instance.
		before doWithIndex: [ :value :index |
			self
				assert: value = (after at: index)
				description: pair key name , ' changed instance variable '
					, (instance class allInstVarNames at: index) , ' while a view was built' ] ]
]

{ #category : 'tests - hierarchy' }
VectorGraphicsDocumentationTest >> testTheGateHierarchyFindsEveryDocumentedPackage [
	"The document covers the whole project, so a gate must see the packages the other gates name,
	whichever subclass is running. The hierarchy is walked, not listed, so adding a gate adds its
	package here.
	The count is held against the gates this image really has, not against four: a load proof
	asks for one layer's tests group on its own, which brings one gate, and that image must
	still be able to run it. What has to hold in either image is that the walk finds the gate
	that is running, that every gate names a package, and that no two name the same one."

	self assert: self class concreteGates size equals: self documentedPackages size.
	self assert: (self class concreteGates includes: self class).
	self assert: (self documentedPackages includes: self packageUnderTest).
	self deny: (self documentedPackages includes: nil).
	self
		assert: self documentedPackages asSet size
		equals: self documentedPackages size.
	self assert: (self class concreteGates noneSatisfy: [ :each | each isAbstract ])
]

{ #category : 'tests' }
VectorGraphicsDocumentationTest >> testTheGateRejectsANameAndAMethodTheImageDoesNotHave [
	"The gates above pass; this says they can fail, which is what makes them worth running."

	self deny: (self architectureDocumentMayName: 'VGNoSuchClassOfThisProject').
	self deny: (self isImplementedMethodToken: 'VectorCanvas >> noSuchSelectorHere').
	self deny: (self isImplementedMethodToken: 'VGNoSuchClassOfThisProject >> onForm:').
	self assert: (self architectureDocumentMayName: 'VectorCanvas').
	self assert: (self isImplementedMethodToken: 'VectorCanvas class >> onForm:')
]

{ #category : 'tests - package comment' }
VectorGraphicsDocumentationTest >> testThePackageCommentNamesEveryTagOfThePackage [
	"A tag nobody has written down is a part of the package a reader will not look in."

	self tagNamesOfThePackage do: [ :each |
		self
			assert: (self tagNamesNamedByThePackageComment includes: each)
			description: 'The package comment does not name the tag ' , each ]
]

{ #category : 'tests - package comment' }
VectorGraphicsDocumentationTest >> testThePackageCommentNamesNoTagThePackageDoesNotHave [
	"A renamed tag leaves the old name in the comment, where it sends a reader to a tag that is not
	 there. This test fails on the rename rather than on the reading."

	self tagNamesNamedByThePackageComment do: [ :each |
		self
			assert: (self tagNamesOfThePackage includes: each)
			description: 'The package comment names ' , each , ', which is no tag of the package' ]
]

{ #category : 'tests - package comment' }
VectorGraphicsDocumentationTest >> testTheTagListIsReadOnlyUnderItsHeadingAndStopsAtTheEndOfTheList [
	"The degenerate states of the reader itself: a comment with no heading names no tag, a list
	 before the heading is not the tag list, and the list stops where it stops, so prose written
	 after it is not read as a tag."

	| comment |
	self assert: (self tagNamesNamedBy: '') isEmpty.
	self assert: (self tagNamesNamedBy: '- `Kernel` — a list with no heading above it') isEmpty.
	comment := String cr join: #( '- `NotATag` — this list comes first' '' 'Tags:' ''
			              '- `Kernel` — the engine' '- `Tests` — the suites' ''
			              'Prose after the list, naming `Examples`, which is not read.' ).
	self
		assert: (self tagNamesNamedBy: comment)
		equals: (Set withAll: #( 'Kernel' 'Tests' ))
]

{ #category : 'tests' }
VectorGraphicsDocumentationTest >> testTheTokeniserReadsBackticksOutsideAFenceAndNothingInsideOne [
	| document |
	document := String lf join: #(
		'Text naming `VectorCanvas` and `nothing closed here'
		'```'
		'`InsideAFence` is a drawing, not a claim'
		'```'
		'and `TTGlyph` after it' ).
	self
		assert: (self backtickedTokensOf: document) asArray
		equals: #( 'VectorCanvas' 'TTGlyph' )
]

{ #category : 'accessing' }
VectorGraphicsDocumentationTest >> viewSubjects [
	"Pairs of a class with an inspector view and the example that feeds it. Empty by default: a
	package with no view declares none, and a subclass with views names them."

	^ #()
]
