"
SVG path command T/t — smooth quadratic Bézier curve.

Like PathQuadraticCurveToCommand but omits the control point; the canvas derives it by
mirroring the previous quadratic command's control point across the current point.
Parses pairs of numbers (x y) per segment.

## Key instVar
- `toPoints`  OrderedCollection of Point

## Canvas message
`runOn:` sends `multiQuadraticCurveToSmooth: coordinatesAreRelative toPoints: toPoints`.
"
Class {
	#name : 'PathQuadraticCurveToSmoothCommand',
	#superclass : 'PathCommand',
	#instVars : [
		'toPoints'
	],
	#category : 'VectorGraphics-PathCommands',
	#package : 'VectorGraphics',
	#tag : 'PathCommands'
}

{ #category : 'instance creation' }
PathQuadraticCurveToSmoothCommand class >> svgName [

	^ $T
]

{ #category : 'building' }
PathQuadraticCurveToSmoothCommand >> buildFrom: commandChar stream: aStream [

	| x y |
	super buildFrom: commandChar stream: aStream.
	toPoints := OrderedCollection new.
	[ 
	x := aStream nextNumber.
	y := aStream nextNumber.
	y notNil ] whileTrue: [ toPoints add: x @ y ]
]

{ #category : 'private' }
PathQuadraticCurveToSmoothCommand >> privatePointsDo: aBlock [

	"evaluate aBlock with the x and y coordinates for our defining points."

	toPoints do: aBlock
]

{ #category : 'drawing' }
PathQuadraticCurveToSmoothCommand >> runOn: aCanvas [

	aCanvas
		multiQuadraticCurveToSmooth: coordinatesAreRelative
		toPoints: toPoints
]
