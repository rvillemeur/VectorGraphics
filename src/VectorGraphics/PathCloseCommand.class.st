"
SVG path command Z/z — close path.

Reads no coordinates from the stream. When run on a canvas, draws a straight line from
the current point back to the most recent move-to point, closing the open subpath.

## Canvas message
`runOn:` sends `closePath` to the canvas with no arguments.
VectorEngineAbstract >> do_ClosePath implements this as basicLineToX: pathFirstX y: pathFirstY.

## Direct construction
`PathCloseCommand new` — no arguments needed.
"
Class {
	#name : 'PathCloseCommand',
	#superclass : 'PathCommand',
	#category : 'VectorGraphics-PathCommands',
	#package : 'VectorGraphics',
	#tag : 'PathCommands'
}

{ #category : 'instance creation' }
PathCloseCommand class >> new [

	^ super new init
]

{ #category : 'instance creation' }
PathCloseCommand class >> svgName [

	^ $Z
]

{ #category : 'building' }
PathCloseCommand >> buildFrom: commandChar stream: aStream [

	super buildFrom: commandChar stream: aStream
]

{ #category : 'initialization' }
PathCloseCommand >> init [

	coordinatesAreRelative := false
]

{ #category : 'private' }
PathCloseCommand >> privatePointsDo: aBlock [

	"evaluate aBlock with the x and y coordinates for our defining points."

	
]

{ #category : 'drawing' }
PathCloseCommand >> runOn: aCanvas [

	aCanvas closePath
]
