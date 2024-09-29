Class {
	#name : #PathLineToCommand,
	#superclass : #PathCommand,
	#instVars : [
		'points'
	],
	#category : #'VectorGraphics-PathCommands'
}

{ #category : #'instance creation' }
PathLineToCommand class >> svgName [

	^ $L
]

{ #category : #building }
PathLineToCommand >> buildFrom: commandChar stream: aStream [

	| px py |
	super buildFrom: commandChar stream: aStream.
	points := Array streamContents: [ :strm | 
		          [ 
		          px := aStream nextNumber.
		          py := aStream nextNumber.
		          py notNil ] whileTrue: [ strm nextPut: px @ py ] ]
]

{ #category : #private }
PathLineToCommand >> privatePointsDo: aBlock [

	"evaluate aBlock with the x and y coordinates for our defining points."

	"Atencion: Si son relativas todo esto esta mal... Igual, lo que quiero es reimplementar todo"

	points do: aBlock
]

{ #category : #drawing }
PathLineToCommand >> runOn: aCanvas [

	aCanvas multiLineTo: coordinatesAreRelative points: points
]
