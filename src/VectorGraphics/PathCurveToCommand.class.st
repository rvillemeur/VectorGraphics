"
SVG path command C/c — cubic Bézier curve.

Parses groups of 6 numbers per segment: x1 y1 x2 y2 x y, where (x1,y1) is control point 1,
(x2,y2) is control point 2, and (x,y) is the destination. Multiple segments are chained.

## Key instVars
- `toPoints`       OrderedCollection of Point (destination per segment)
- `control1Points` OrderedCollection of Point
- `control2Points` OrderedCollection of Point

## Canvas message
`runOn:` sends:
  multiCurveTo: coordinatesAreRelative
  toPoints: toPoints control1Points: control1Points control2Points: control2Points

## Direct construction
- `PathCurveToCommand to: endPt control1: cp1 control2: cp2`
- `PathCurveToCommand toRelative: endPt control1: cp1 control2: cp2`
"
Class {
	#name : 'PathCurveToCommand',
	#superclass : 'PathCommand',
	#instVars : [
		'toPoints',
		'control1Points',
		'control2Points'
	],
	#category : 'VectorGraphics-PathCommands',
	#package : 'VectorGraphics',
	#tag : 'PathCommands'
}

{ #category : 'instance creation' }
PathCurveToCommand class >> svgName [

	^ $C
]

{ #category : 'instance creation' }
PathCurveToCommand class >> to: endPoint control1: cp1 control2: cp2 [

	^ self new to: endPoint control1: cp1 control2: cp2
]

{ #category : 'instance creation' }
PathCurveToCommand class >> toRelative: endPoint control1: cp1 control2: cp2 [

	^ self new toRelative: endPoint control1: cp1 control2: cp2
]

{ #category : 'building' }
PathCurveToCommand >> buildFrom: commandChar stream: aStream [

	| x1 y1 x2 y2 x y |
	super buildFrom: commandChar stream: aStream.
	toPoints := OrderedCollection new.
	control1Points := OrderedCollection new.
	control2Points := OrderedCollection new.
	[ 
	x1 := aStream nextNumber.
	y1 := aStream nextNumber.
	x2 := aStream nextNumber.
	y2 := aStream nextNumber.
	x := aStream nextNumber.
	y := aStream nextNumber.
	y notNil ] whileTrue: [ 
		toPoints add: x @ y.
		control1Points add: x1 @ y1.
		control2Points add: x2 @ y2 ]
]

{ #category : 'private' }
PathCurveToCommand >> privatePointsDo: aBlock [

	"evaluate aBlock with the x and y coordinates for our defining points."

	toPoints do: aBlock
]

{ #category : 'drawing' }
PathCurveToCommand >> runOn: aCanvas [

	aCanvas
		multiCurveTo: coordinatesAreRelative
		toPoints: toPoints
		control1Points: control1Points
		control2Points: control2Points
]

{ #category : 'building' }
PathCurveToCommand >> to: endPoint control1: cp1 control2: cp2 [

	coordinatesAreRelative := false.
	toPoints := OrderedCollection with: endPoint.
	control1Points := OrderedCollection with: cp1.
	control2Points := OrderedCollection with: cp2
]

{ #category : 'building' }
PathCurveToCommand >> toRelative: endPoint control1: cp1 control2: cp2 [

	coordinatesAreRelative := true.
	toPoints := OrderedCollection with: endPoint.
	control1Points := OrderedCollection with: cp1.
	control2Points := OrderedCollection with: cp2
]
