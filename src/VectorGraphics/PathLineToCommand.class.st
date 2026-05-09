"
SVG path command L/l — line to.

Parses pairs of numbers (x y) until the stream is exhausted; stores them as an Array of Points.

## Key instVar
- `points`  Array of Point (each parsed x @ y destination)

## Canvas message
`runOn:` sends `multiLineTo: coordinatesAreRelative points: points`.

## Direct construction (without stream parsing)
- `PathLineToCommand to: aPoint`           — single absolute destination
- `PathLineToCommand toPoints: anArray`    — multiple absolute destinations (polyline segment)
- `PathLineToCommand toRelativePoint: aPoint` — single relative offset from current position
"
Class {
	#name : 'PathLineToCommand',
	#superclass : 'PathCommand',
	#instVars : [
		'points'
	],
	#category : 'VectorGraphics-PathCommands',
	#package : 'VectorGraphics',
	#tag : 'PathCommands'
}

{ #category : 'instance creation' }
PathLineToCommand class >> svgName [

	^ $L
]

{ #category : 'instance creation' }
PathLineToCommand class >> toPoint: aPoint [

	^ self new toPoint: aPoint
]

{ #category : 'instance creation' }
PathLineToCommand class >> toPoints: anArray [

	^ self new toPoints: anArray
]

{ #category : 'instance creation' }
PathLineToCommand class >> toRelativePoint: aPoint [

	^ self new toRelativePoint: aPoint
]

{ #category : 'building' }
PathLineToCommand >> buildFrom: commandChar stream: aStream [

	| px py |
	super buildFrom: commandChar stream: aStream.
	points := Array streamContents: [ :strm | 
		          [ 
		          px := aStream nextNumber.
		          py := aStream nextNumber.
		          py notNil ] whileTrue: [ strm nextPut: px @ py ] ]
]

{ #category : 'private' }
PathLineToCommand >> privatePointsDo: aBlock [

	"evaluate aBlock with the x and y coordinates for our defining points."

	"Atencion: Si son relativas todo esto esta mal... Igual, lo que quiero es reimplementar todo"

	points do: aBlock
]

{ #category : 'drawing' }
PathLineToCommand >> runOn: aCanvas [

	aCanvas multiLineTo: coordinatesAreRelative points: points
]

{ #category : 'building' }
PathLineToCommand >> toPoint: aPoint [

	coordinatesAreRelative := false.
	points := { aPoint }
]

{ #category : 'building' }
PathLineToCommand >> toPoints: anArray [

	coordinatesAreRelative := false.
	points := anArray
]

{ #category : 'building' }
PathLineToCommand >> toRelativePoint: aPoint [

	coordinatesAreRelative := true.
	points := { aPoint }
]
