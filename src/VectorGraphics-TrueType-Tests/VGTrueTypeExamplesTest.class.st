"
The gate over the examples of VectorGraphics-TrueType. It runs every class-side `<sampleInstance>` of its example holders and checks the shape of each one: that it answers something, that it rebuilds its object every call, that it takes no argument on the class side, and that its holder carries a comment. An example whose selector begins with the class-side `windowExamplePrefix` opens a window, so no gate runs it; the gate only checks it is named for what it does.

`exampleHolders` names the holders this gate covers. Add a holder there and its examples are gated from the next run, with nothing else to write.
"
Class {
	#name : 'VGTrueTypeExamplesTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-TrueType-Tests-Tests',
	#package : 'VectorGraphics-TrueType-Tests',
	#tag : 'Tests'
}

{ #category : 'accessing' }
VGTrueTypeExamplesTest class >> windowExamplePrefix [
	"An example whose selector begins with this opens a window. The suite does not run one: see
	testAnExampleThatOpensAWindowIsNamedForItAndNoGateRunsIt for why the name carries the rule
	rather than a list of selectors."

	^ 'open'
]

{ #category : 'accessing' }
VGTrueTypeExamplesTest >> allExampleMethods [
	"Every class-side method of this layer's examples tagged <sampleInstance>, found by the
	pragma rather than by a list, so a new example is covered the moment it is written."

	^ self exampleHolders flatCollect: [ :each |
		  each class methods select: [ :method |
			  method hasPragmaNamed: #sampleInstance ] ]
]

{ #category : 'accessing' }
VGTrueTypeExamplesTest >> defaultTimeLimit [
	"Every example is built twice over by the gates below, and one that reads a .ttf file spends
	about 200 ms parsing it, which is more than the ten seconds SUnit allows a test by default
	once there are several of them."

	^ 1 minute
]

{ #category : 'accessing' }
VGTrueTypeExamplesTest >> exampleHolders [
	^ { TrueTypeExamples }
]

{ #category : 'accessing' }
VGTrueTypeExamplesTest >> exampleMethods [
	"The examples the gates below run: all of them but the ones that open a window."

	^ self allExampleMethods reject: [ :each |
		  each selector beginsWith: self class windowExamplePrefix ]
]

{ #category : 'tests' }
VGTrueTypeExamplesTest >> testAnExampleThatOpensAWindowIsNamedForItAndNoGateRunsIt [
	"An example that opens a window cannot run in a suite, so it is named for what it does and
	the gate skips it. The naming rule is read from the class, not restated here."

	| prefix |
	prefix := self class windowExamplePrefix.
	self assert: (self windowExampleMethods allSatisfy: [ :each |
			 each selector beginsWith: prefix ]).
	self assert: (self exampleMethods noneSatisfy: [ :each |
			 each selector beginsWith: prefix ]).
	self
		assert: self exampleMethods size + self windowExampleMethods size
		equals: self allExampleMethods size
]

{ #category : 'tests' }
VGTrueTypeExamplesTest >> testEveryExampleHolderHasAComment [
	"A holder is read from the browser, so it must say what its examples show."

	| silent |
	silent := self exampleHolders reject: [ :each |
		          each hasComment and: [ each comment trimBoth isNotEmpty ] ].
	self
		assert: silent isEmpty
		description: 'these example holders have no comment: '
			, (silent collect: [ :each | each name ]) asArray printString
]

{ #category : 'tests' }
VGTrueTypeExamplesTest >> testEveryExampleRebuildsItsObject [
	"An example must answer a fresh object each call, or inspecting one would show state another
	inspection left behind. A class is its own single instance, so an example that answers a
	class is exempt."

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
VGTrueTypeExamplesTest >> testEveryExampleRunsAndAnswersSomething [
	"An example asserts nothing itself, so this is what keeps them working: each one must run
	from a cold start and answer something for the browser to show."

	| broken |
	broken := OrderedCollection new.
	self exampleMethods do: [ :each |
		[
		(each methodClass instanceSide perform: each selector)
			ifNil: [ broken add: each selector -> 'answered nil' ] ]
			on: Error
			do: [ :error |
				broken add:
					each selector -> (error class name , ': ' , error messageText printString) ] ].
	self
		assert: broken isEmpty
		description: 'these examples do not run: ' , broken asArray printString
]

{ #category : 'tests' }
VGTrueTypeExamplesTest >> testEveryExampleTakesNoArgumentAndIsOnTheClassSide [
	"An example is a class-side method with no argument, so the browser can run it with one
	click. Anything else is a helper and must not carry the pragma."

	| wrong |
	wrong := self allExampleMethods reject: [ :each |
		         each numArgs = 0 and: [ each methodClass isMeta ] ].
	self
		assert: wrong isEmpty
		description: 'these are not one-click class-side examples: '
			, (wrong collect: [ :each | each methodClass name , '>>' , each selector ]) asArray
					printString
]

{ #category : 'accessing' }
VGTrueTypeExamplesTest >> windowExampleMethods [
	"The examples that open a window, which a suite must not run: an error inside one opens a
	debugger and the process serving the call answers nothing."

	^ self allExampleMethods select: [ :each |
		  each selector beginsWith: self class windowExamplePrefix ]
]
