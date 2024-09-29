Class {
	#name : #PathCloseCommand,
	#superclass : #PathCommand,
	#category : #'VectorGraphics-PathCommands'
}

{ #category : #'instance creation' }
PathCloseCommand class >> svgName [

	^ $Z
]

{ #category : #building }
PathCloseCommand >> buildFrom: commandChar stream: aStream [

	super buildFrom: commandChar stream: aStream
]

{ #category : #private }
PathCloseCommand >> privatePointsDo: aBlock [

	"evaluate aBlock with the x and y coordinates for our defining points."

	
]

{ #category : #drawing }
PathCloseCommand >> runOn: aCanvas [

	aCanvas closePath
]
