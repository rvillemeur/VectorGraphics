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

{ #category : 'constants' }
VGCairoExamplesTest >> exampleHolders [
	^ {
		  VGCairoContextExamples.
		  VGCairoImageSurfaceExamples.
		  VGCairoInventoryExamples.
		  VGConformanceCorpusExamples }
]

{ #category : 'accessing' }
VGCairoExamplesTest >> exampleMethods [
	"Every class-side method tagged <sampleInstance>, found by the pragma rather than by a list."

	^ self exampleHolders flatCollect: [ :each |
		  each class methods select: [ :method | method hasPragmaNamed: #sampleInstance ] ]
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
