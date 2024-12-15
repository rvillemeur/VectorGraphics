Class {
	#name : 'PathLineToVCommand',
	#superclass : 'PathCommand',
	#instVars : [
		'ys'
	],
	#category : 'VectorGraphics-PathCommands',
	#package : 'VectorGraphics',
	#tag : 'PathCommands'
}

{ #category : 'instance creation' }
PathLineToVCommand class >> svgName [

	^ $V
]

{ #category : 'building' }
PathLineToVCommand >> buildFrom: commandChar stream: aStream [

	| py |
	super buildFrom: commandChar stream: aStream.
	ys := Array streamContents: [ :strm | 
		      [ 
		      py := aStream nextNumber.
		      py notNil ] whileTrue: [ strm nextPut: py ] ]
]

{ #category : 'drawing' }
PathLineToVCommand >> runOn: aCanvas [

	aCanvas multiLineTo: coordinatesAreRelative ys: ys
]
