Class {
	#name : #PathArcCommand,
	#superclass : #PathCommand,
	#instVars : [
		'rs',
		'xAxisRotations',
		'toPoints',
		'doLargerArcs',
		'useIncreasingAngless'
	],
	#category : #'VectorGraphics-PathCommands'
}

{ #category : #'instance creation' }
PathArcCommand class >> svgName [

	^ $A
]

{ #category : #building }
PathArcCommand >> buildFrom: commandChar stream: aStream [

	| rx ry xAxisRotation doLargerArc useIncreasingAngles x y |
	super buildFrom: commandChar stream: aStream.
	rs := OrderedCollection new.
	xAxisRotations := OrderedCollection new.
	toPoints := OrderedCollection new.
	doLargerArcs := OrderedCollection new.
	useIncreasingAngless := OrderedCollection new.
	[ 
	rx := aStream nextNumber.
	ry := aStream nextNumber.
	xAxisRotation := aStream nextNumber.
	doLargerArc := aStream nextNumber ~= 0.
	useIncreasingAngles := aStream nextNumber ~= 0.
	x := aStream nextNumber.
	y := aStream nextNumber.
	y notNil ] whileTrue: [ 
		rs add: rx @ ry.
		xAxisRotations add: xAxisRotation degreesToRadians.
		doLargerArcs add: doLargerArc.
		useIncreasingAngless add: useIncreasingAngles.
		toPoints add: x @ y ]
]

{ #category : #private }
PathArcCommand >> privatePointsDo: aBlock [
	"evaluate aBlock with the x and y coordinates for our defining points."
	
"si los puntos son relativos, tirar una excepcion...
Y completar los que falten!"
	toPoints do: aBlock
]

{ #category : #drawing }
PathArcCommand >> runOn: aCanvas [
	aCanvas multiArc: coordinatesAreRelative rs: rs xAxisRotations: xAxisRotations toPoints: toPoints doLargerArcs: doLargerArcs useIncreasingAngless: useIncreasingAngless
]
