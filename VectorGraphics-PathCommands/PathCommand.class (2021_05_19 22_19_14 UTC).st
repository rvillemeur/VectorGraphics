Class {
	#name : #PathCommand,
	#superclass : #Object,
	#instVars : [
		'coordinatesAreRelative'
	],
	#category : #'VectorGraphics-PathCommands'
}

{ #category : #'instance creation' }
PathCommand class >> classFor: anSVGPathCommandName [

	self allSubclassesDo: [ :cls | 
		cls svgName = anSVGPathCommandName asUppercase ifTrue: [ ^ cls ] ].
	^ nil
]

{ #category : #'instance creation' }
PathCommand class >> from: commandChar stream: aStream [

	| cls |
	cls := self classFor: commandChar.
	cls ifNil: [ 
		PathCommandError signal:
			('Unhandled path command: ' copyWith: commandChar).
		^ nil ].
	^ cls new buildFrom: commandChar stream: aStream
]

{ #category : #'instance creation' }
PathCommand class >> svgName [

	"Answer the name of the svg elements we can represent"

	^ self subclassResponsibility
]

{ #category : #building }
PathCommand >> buildFrom: commandChar stream: aStream [

	coordinatesAreRelative := commandChar isLowercase
]

{ #category : #building }
PathCommand >> buildFromStream: aStream in: parentToBe [

	coordinatesAreRelative := aStream next isLowercase
]

{ #category : #'as yet unclassified' }
PathCommand >> coordinatesAreRelative [

	^ coordinatesAreRelative
]

{ #category : #private }
PathCommand >> privatePointsDo: aBlock [

	"evaluate aBlock with the x and y coordinates for our defining points."

	self subclassResponsibility
]

{ #category : #drawing }
PathCommand >> runOn: aCanvas [

	self subclassResponsibility
]
