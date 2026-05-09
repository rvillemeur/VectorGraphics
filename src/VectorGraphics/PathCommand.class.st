"
Abstract superclass for SVG path commands (M, L, H, V, C, S, Q, T, A, Z).

Each subclass maps to one SVG path letter and holds the parsed coordinates for one segment
of an SVG path. A command is constructed by the class-side factory `from:commandChar stream:`
and executed later by `runOn: aVectorCanvas`.

## Parsing
`PathCommand class >> from: commandChar stream: aStream`
  Identifies the concrete subclass via `classFor:` (matches each subclass's `svgName`),
  instantiates it, and calls `buildFrom:commandChar stream:` on it.
  The stream must respond to `nextNumber`, returning nil when exhausted (signals end of
  coordinates to all parsing loops).

## Execution
`runOn: aCanvas`
  Sends a drawing message to aCanvas (a VectorCanvas or RecordingCanvas).
  Each subclass sends a different canvas message (e.g. `multiLineTo:points:`,
  `multiCurveTo:toPoints:control1Points:control2Points:`, `closePath`).

## Coordinate mode
`coordinatesAreRelative` (Boolean, set from commandChar case)
  true when commandChar is lowercase (relative coordinates); false when uppercase (absolute).

## Subclasses
  PathMoveToCommand (M/m), PathLineToCommand (L/l), PathLineToHCommand (H/h),
  PathLineToVCommand (V/v), PathCurveToCommand (C/c), PathCurveToSmoothCommand (S/s),
  PathQuadraticCurveToCommand (Q/q), PathQuadraticCurveToSmoothCommand (T/t),
  PathArcCommand (A/a), PathCloseCommand (Z/z).

## Error
Raises PathCommandError when `from:commandChar stream:` encounters an unknown command letter.
"
Class {
	#name : 'PathCommand',
	#superclass : 'Object',
	#instVars : [
		'coordinatesAreRelative'
	],
	#category : 'VectorGraphics-PathCommands',
	#package : 'VectorGraphics',
	#tag : 'PathCommands'
}

{ #category : 'instance creation' }
PathCommand class >> classFor: anSVGPathCommandName [

	self allSubclassesDo: [ :cls | 
		cls svgName = anSVGPathCommandName asUppercase ifTrue: [ ^ cls ] ].
	^ nil
]

{ #category : 'instance creation' }
PathCommand class >> from: commandChar stream: aStream [

	| cls |
	cls := self classFor: commandChar.
	cls ifNil: [ 
		PathCommandError signal:
			('Unhandled path command: ' copyWith: commandChar).
		^ nil ].
	^ cls new buildFrom: commandChar stream: aStream
]

{ #category : 'instance creation' }
PathCommand class >> svgName [

	"Answer the name of the svg elements we can represent"

	^ self subclassResponsibility
]

{ #category : 'building' }
PathCommand >> buildFrom: commandChar stream: aStream [

	coordinatesAreRelative := commandChar isLowercase
]

{ #category : 'building' }
PathCommand >> buildFromStream: aStream in: parentToBe [

	coordinatesAreRelative := aStream next isLowercase
]

{ #category : 'as yet unclassified' }
PathCommand >> coordinatesAreRelative [

	^ coordinatesAreRelative
]

{ #category : 'private' }
PathCommand >> privatePointsDo: aBlock [

	"evaluate aBlock with the x and y coordinates for our defining points."

	self subclassResponsibility
]

{ #category : 'drawing' }
PathCommand >> runOn: aCanvas [

	self subclassResponsibility
]
