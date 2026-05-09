"
SVG path command M/m — move to.

Starts a new subpath at the given coordinates without drawing anything. Multiple points
can be listed; each after the first is treated as an implicit L (line-to) in SVG spec,
though VectorEngineAbstract handles this inside `multiMoveTo:points:`.

## Key instVar
- `points`  Array of Point

## Canvas message
`runOn:` sends `multiMoveTo: coordinatesAreRelative points: points`.

## Direct construction (without stream parsing)
- `PathMoveToCommand to: aPoint`       — absolute destination (class-side factory)
- `PathMoveToCommand toRelative: aPoint` — relative offset (class-side factory)
- `toPoint: endPoint`                  — instance-side absolute setter
- `toRelativePoint: endPoint`          — instance-side relative setter
"
Class {
	#name : 'PathMoveToCommand',
	#superclass : 'PathCommand',
	#instVars : [
		'points'
	],
	#category : 'VectorGraphics-PathCommands',
	#package : 'VectorGraphics',
	#tag : 'PathCommands'
}

{ #category : 'instance creation' }
PathMoveToCommand class >> svgName [

	^ $M
]

{ #category : 'instance creation' }
PathMoveToCommand class >> to: aPoint [

	^ self new toPoint: aPoint
]

{ #category : 'instance creation' }
PathMoveToCommand class >> toRelative: aPoint [

	^ self new toRelativePoint: aPoint
]

{ #category : 'building' }
PathMoveToCommand >> buildFrom: commandChar stream: aStream [

	| px py |
	super buildFrom: commandChar stream: aStream.
	points := Array streamContents: [ :strm | 
		          [ 
		          px := aStream nextNumber.
		          py := aStream nextNumber.
		          py notNil ] whileTrue: [ strm nextPut: px @ py ] ]
]

{ #category : 'private' }
PathMoveToCommand >> privatePointsDo: aBlock [

	"evaluate aBlock with the x and y coordinates for our defining points."

	points do: aBlock
]

{ #category : 'drawing' }
PathMoveToCommand >> runOn: aCanvas [

	aCanvas multiMoveTo: coordinatesAreRelative points: points
]

{ #category : 'building' }
PathMoveToCommand >> toPoint: endPoint [

	coordinatesAreRelative := false.
	points := { endPoint }
]

{ #category : 'building' }
PathMoveToCommand >> toRelativePoint: endPoint [

	coordinatesAreRelative := true.
	points := { endPoint }
]
