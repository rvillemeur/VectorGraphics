"
SVG path command H/h — horizontal line to.

Parses a sequence of single x values; the y coordinate is implicitly the current point's y.

## Key instVar
- `xs`  Array of Number

## Canvas message
`runOn:` sends `multiLineTo: coordinatesAreRelative xs: xs`.
"
Class {
	#name : 'PathLineToHCommand',
	#superclass : 'PathCommand',
	#instVars : [
		'xs'
	],
	#category : 'VectorGraphics-Paths-Commands',
	#package : 'VectorGraphics-Paths',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
PathLineToHCommand class >> svgName [

	^ $H
]

{ #category : 'building' }
PathLineToHCommand >> buildFrom: commandChar stream: aStream [

	| px |
	super buildFrom: commandChar stream: aStream.
	xs := Array streamContents: [ :strm | 
		      [ 
		      px := aStream nextNumber.
		      px notNil ] whileTrue: [ strm nextPut: px ] ]
]

{ #category : 'drawing' }
PathLineToHCommand >> runOn: aCanvas [

	aCanvas multiLineTo: coordinatesAreRelative xs: xs
]
