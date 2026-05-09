"
SVG path command V/v — vertical line to.

Parses a sequence of single y values; the x coordinate is implicitly the current point's x.

## Key instVar
- `ys`  Array of Number

## Canvas message
`runOn:` sends `multiLineTo: coordinatesAreRelative ys: ys`.
"
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
