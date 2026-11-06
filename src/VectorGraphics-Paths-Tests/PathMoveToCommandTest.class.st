"
I hold the two constructors of `PathMoveToCommand` to the one thing they disagree about: `toPoint:` builds an absolute command and `toRelativePoint:` a relative one.

That flag is read by the engine much later, when the command runs, so a command built by hand — which is what the glyph and text code does, rather than parsing a letter — must set it as surely as `buildFrom:stream:` does.

The points those constructors store are held in `PathCommandRunOnTest`, where they are asserted on the far side of `runOn:`, as the canvas receives them. Nothing here reaches inside the object.
"
Class {
	#name : 'PathMoveToCommandTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Paths-Tests-Tests',
	#package : 'VectorGraphics-Paths-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
PathMoveToCommandTest >> testAbsoluteToPointIsNotRelative [
	| cmd |
	cmd := PathMoveToCommand new toPoint: 10 @ 20.
	self deny: cmd coordinatesAreRelative
]

{ #category : 'tests' }
PathMoveToCommandTest >> testRelativeToPointIsRelative [
	| cmd |
	cmd := PathMoveToCommand new toRelativePoint: 10 @ 20.
	self assert: cmd coordinatesAreRelative
]
