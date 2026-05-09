"
A number stream backed by an array of pre-parsed numbers.

Consumed by SVGPathParser to feed coordinates into PathCommand >> buildFrom:commandChar stream:.
Responds to nextNumber, returning nil when exhausted — the termination signal expected by all
PathCommand parsing loops.

## Usage
  stream := SVGNumberStream on: #(10 20 30 40).
  stream nextNumber  → 10
  stream nextNumber  → 20
  ...
  stream nextNumber  → nil   (after all numbers consumed)

## Relationship
  SVGPathParser creates one SVGNumberStream per command token and passes it to
  PathCommand class >> from:commandChar stream:.
"
Class {
	#name : 'SVGNumberStream',
	#superclass : 'Object',
	#instVars : [
		'numbers',
		'pos'
	],
	#category : 'VectorGraphics-SVG',
	#package : 'VectorGraphics',
	#tag : 'SVG'
}

{ #category : 'instance creation' }
SVGNumberStream class >> on: anArray [

	^ self new initWith: anArray
]

{ #category : 'initialization' }
SVGNumberStream >> initWith: anArray [

	numbers := anArray.
	pos := 0
]

{ #category : 'accessing' }
SVGNumberStream >> nextNumber [

	pos := pos + 1.
	pos > numbers size ifTrue: [ ^ nil ].
	^ numbers at: pos
]
