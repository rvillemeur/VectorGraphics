"
I hold the documents of this package to the code they describe.

The package comment is the map a reader sees first in the browser, so I check that it names every tag the package has and no tag it does not have: a renamed tag fails here instead of sending a reader to a part of the package that is not there. I read only the list under the `Tags:` heading, since the comment holds other lists; `tagNamesNamedBy:` is that reader and is tested on its own degenerate states.

`doc/ARCHITECTURE.md` is the second document, and I hold every name it writes in backticks to the image: a capitalised word must be a class, a class variable of this package or a package; a `Class >> selector` form must be answered by that class; a keyword selector on its own must be implemented somewhere. I read nothing inside a fenced code block, because the diagram in one is a drawing rather than a claim, and I say nothing about a unary token, which cannot be told from an instance variable name. The document is a file of the repository and not of the image, so I skip when there is no checkout to read.

I grow with the third documentation artefact of this package, the inspector views of the engine, whose examples I build. `VGCairoExamplesTest` does the same work for the layers above, but I cannot subclass it: `VGArchitectureTest class >> allowedDependencies` gives this package no outgoing edge, so no class here may name one of `VectorGraphics-Cairo-Tests`.
"
Class {
	#name : 'VectorGraphicsDocumentationTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Tests',
	#package : 'VectorGraphics',
	#tag : 'Tests'
}

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

{ #category : 'testing' }
VectorGraphicsDocumentationTest >> architectureDocumentMayName: aToken [
	"A capitalised name of the document is held to one of three things that really exist: a class
	of the image, a class variable of a class of this package, or a package."

	(Smalltalk includesKey: aToken asSymbol) ifTrue: [ ^ true ].
	(self classVariableNamesOfThePackage includes: aToken) ifTrue: [ ^ true ].
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
	"Build one inspector view and draw what it would show. A table's column blocks run per drawn
	row only, so this test runs each of them over each item itself; otherwise a broken column
	would pass."

	| presenter |
	presenter := anObject perform: aSelector.
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
VectorGraphicsDocumentationTest >> classVariableNamesOfThePackage [
	"Answer the names of every class variable declared by a class of this package, so the
	document may name one — the font caches are class variables, not classes."

	| names |
	names := Set new.
	self packageUnderTest definedClasses do: [ :each |
		names addAll: (each classVariables collect: [ :variable | variable name asString ]) ].
	^ names
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
	"The package these tests document: the engine, the path commands and the TrueType code."

	^ PackageOrganizer default packageNamed: 'VectorGraphics'
]

{ #category : 'parsing' }
VectorGraphicsDocumentationTest >> qualifiedSelectorSeparator [
	^ ' >> '
]

{ #category : 'accessing' }
VectorGraphicsDocumentationTest >> repositoryName [
	^ 'VectorGraphics'
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
	holders := self packageUnderTest definedClasses select: [ :each |
		           each class selectors anySatisfy: [ :selector |
			           (each class >> selector) pragmas anySatisfy: [ :pragma |
				           pragma selector = #sampleInstance ] ] ].
	self assert: holders notEmpty description: 'This package holds no example'.
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

	^ {
		VectorEnginePixel -> (VectorCanvasExample -> #exampleEngineDuringAFillPath) .
		VectorEngineAbstract -> (VectorCanvasExample -> #exampleEngineDuringAFillPath) .
		VectorEngineBoundsFinder
		-> (VectorCanvasExample -> #exampleBoundsFinderAfterMeasuringATriangle) .
		VectorCanvas -> (VectorCanvasExample -> #exampleCanvasAfterADrawing) .
		TTGlyph -> (TrueTypeExample -> #exampleGlyphWithContours) .
		TTFontDescription -> (TrueTypeExample -> #exampleGlyphMap) }
]
