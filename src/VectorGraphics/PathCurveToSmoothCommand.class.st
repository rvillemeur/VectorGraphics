"
SVG path command S/s — smooth cubic Bézier curve.

Like PathCurveToCommand but omits control point 1; the canvas derives it by mirroring the
previous command's second control point across the current point. Parses groups of 4 numbers
per segment: x2 y2 x y.

## Key instVars
- `toPoints`       OrderedCollection of Point
- `control2Points` OrderedCollection of Point

## Canvas message
`runOn:` sends:
  multiCurveToSmooth: coordinatesAreRelative
  toPoints: toPoints control2Points: control2Points
"
Class {
	#name : 'PathCurveToSmoothCommand',
	#superclass : 'PathCommand',
	#instVars : [
		'toPoints',
		'control2Points'
	],
	#category : 'VectorGraphics-PathCommands',
	#package : 'VectorGraphics',
	#tag : 'PathCommands'
}

{ #category : 'instance creation' }
PathCurveToSmoothCommand class >> svgName [

	^ $S
]

{ #category : 'building' }
PathCurveToSmoothCommand >> buildFrom: commandChar stream: aStream [

	| x2 y2 x y |
	super buildFrom: commandChar stream: aStream.
	toPoints := OrderedCollection new.
	control2Points := OrderedCollection new.
	[ 
	x2 := aStream nextNumber.
	y2 := aStream nextNumber.
	x := aStream nextNumber.
	y := aStream nextNumber.
	y notNil ] whileTrue: [ 
		toPoints add: x @ y.
		control2Points add: x2 @ y2 ]
]

{ #category : 'private' }
PathCurveToSmoothCommand >> privatePointsDo: aBlock [

	"evaluate aBlock with the x and y coordinates for our defining points."

	toPoints do: aBlock
]

{ #category : 'drawing' }
PathCurveToSmoothCommand >> runOn: aCanvas [

	aCanvas
		multiCurveToSmooth: coordinatesAreRelative
		toPoints: toPoints
		control2Points: control2Points
]
