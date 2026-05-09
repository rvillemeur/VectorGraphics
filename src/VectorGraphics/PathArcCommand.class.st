"
SVG path command A/a — elliptical arc.

Parses groups of 7 numbers per arc segment: rx ry xAxisRotation largeArcFlag sweepFlag x y.
Multiple arc segments can be chained in one command (the loop reads until the stream
returns nil).

## Key instVars
- `rs`                  OrderedCollection of Point (rx @ ry per arc)
- `xAxisRotations`      OrderedCollection of Float (angle in radians, converted from degrees during parse)
- `toPoints`            OrderedCollection of Point (destination x @ y per arc)
- `doLargerArcs`        OrderedCollection of Boolean
- `useIncreasingAngless` OrderedCollection of Boolean (flag controls sweep direction)

## Canvas message
`runOn:` sends:
  multiArc: coordinatesAreRelative
  rs: rs xAxisRotations: xAxisRotations toPoints: toPoints
  doLargerArcs: doLargerArcs useIncreasingAngless: useIncreasingAngless
"
Class {
	#name : 'PathArcCommand',
	#superclass : 'PathCommand',
	#instVars : [
		'rs',
		'xAxisRotations',
		'toPoints',
		'doLargerArcs',
		'useIncreasingAngless'
	],
	#category : 'VectorGraphics-PathCommands',
	#package : 'VectorGraphics',
	#tag : 'PathCommands'
}

{ #category : 'instance creation' }
PathArcCommand class >> svgName [

	^ $A
]

{ #category : 'building' }
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

{ #category : 'private' }
PathArcCommand >> privatePointsDo: aBlock [
	"evaluate aBlock with the x and y coordinates for our defining points."
	
"si los puntos son relativos, tirar una excepcion...
Y completar los que falten!"
	toPoints do: aBlock
]

{ #category : 'drawing' }
PathArcCommand >> runOn: aCanvas [
	aCanvas multiArc: coordinatesAreRelative rs: rs xAxisRotations: xAxisRotations toPoints: toPoints doLargerArcs: doLargerArcs useIncreasingAngless: useIncreasingAngless
]
