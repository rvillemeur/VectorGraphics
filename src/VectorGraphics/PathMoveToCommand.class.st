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
