"
A minimal stream returning pre-set numbers, used to test PathCommand >> buildFrom:commandChar stream:.
Returns nil when exhausted, which signals end of coordinates to all buildFrom: loops.
"
Class {
	#name : 'MockNumberStream',
	#superclass : 'Object',
	#instVars : [
		'numbers',
		'pos'
	],
	#category : 'VectorGraphics-Tests',
	#package : 'VectorGraphics',
	#tag : 'Tests'
}

{ #category : 'instance creation' }
MockNumberStream class >> on: anArray [

	^ self new initWith: anArray
]

{ #category : 'initialization' }
MockNumberStream >> initWith: anArray [

	numbers := anArray.
	pos := 0
]

{ #category : 'accessing' }
MockNumberStream >> nextNumber [

	pos := pos + 1.
	pos > numbers size ifTrue: [ ^ nil ].
	^ numbers at: pos
]
