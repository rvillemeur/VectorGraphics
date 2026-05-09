Class {
	#name : 'PathCommandDispatchTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Tests',
	#package : 'VectorGraphics',
	#tag : 'Tests'
}

{ #category : 'tests' }
PathCommandDispatchTest >> testClassForArc [
	self assert: (PathCommand classFor: $A) equals: PathArcCommand
]

{ #category : 'tests' }
PathCommandDispatchTest >> testClassForCaseInsensitive [
	self assert: (PathCommand classFor: $m) equals: PathMoveToCommand.
	self assert: (PathCommand classFor: $l) equals: PathLineToCommand.
	self assert: (PathCommand classFor: $z) equals: PathCloseCommand
]

{ #category : 'tests' }
PathCommandDispatchTest >> testClassForClose [
	self assert: (PathCommand classFor: $Z) equals: PathCloseCommand
]

{ #category : 'tests' }
PathCommandDispatchTest >> testClassForCubicBezier [
	self assert: (PathCommand classFor: $C) equals: PathCurveToCommand
]

{ #category : 'tests' }
PathCommandDispatchTest >> testClassForHorizontalLine [
	self assert: (PathCommand classFor: $H) equals: PathLineToHCommand
]

{ #category : 'tests' }
PathCommandDispatchTest >> testClassForLine [
	self assert: (PathCommand classFor: $L) equals: PathLineToCommand
]

{ #category : 'tests' }
PathCommandDispatchTest >> testClassForMoveTo [
	self assert: (PathCommand classFor: $M) equals: PathMoveToCommand
]

{ #category : 'tests' }
PathCommandDispatchTest >> testClassForQuadraticBezier [
	self assert: (PathCommand classFor: $Q) equals: PathQuadraticCurveToCommand
]

{ #category : 'tests' }
PathCommandDispatchTest >> testClassForSmoothCubicBezier [
	self assert: (PathCommand classFor: $S) equals: PathCurveToSmoothCommand
]

{ #category : 'tests' }
PathCommandDispatchTest >> testClassForSmoothQuadraticBezier [
	self assert: (PathCommand classFor: $T) equals: PathQuadraticCurveToSmoothCommand
]

{ #category : 'tests' }
PathCommandDispatchTest >> testClassForUnknownReturnsNil [
	self assert: (PathCommand classFor: $X) isNil
]

{ #category : 'tests' }
PathCommandDispatchTest >> testClassForVerticalLine [
	self assert: (PathCommand classFor: $V) equals: PathLineToVCommand
]

{ #category : 'tests' }
PathCommandDispatchTest >> testLowercaseCommandIsRelative [
	| cmd |
	cmd := PathCloseCommand new buildFrom: $z stream: (ReadStream on: #()).
	self assert: cmd coordinatesAreRelative
]

{ #category : 'tests' }
PathCommandDispatchTest >> testSvgNames [
	self assert: PathMoveToCommand svgName equals: $M.
	self assert: PathLineToCommand svgName equals: $L.
	self assert: PathLineToHCommand svgName equals: $H.
	self assert: PathLineToVCommand svgName equals: $V.
	self assert: PathCurveToCommand svgName equals: $C.
	self assert: PathCurveToSmoothCommand svgName equals: $S.
	self assert: PathQuadraticCurveToCommand svgName equals: $Q.
	self assert: PathQuadraticCurveToSmoothCommand svgName equals: $T.
	self assert: PathArcCommand svgName equals: $A.
	self assert: PathCloseCommand svgName equals: $Z
]

{ #category : 'tests' }
PathCommandDispatchTest >> testSvgNamesAreUnique [
	| names |
	names := PathCommand allSubclasses collect: [ :cls | cls svgName ].
	self assert: names size equals: names asSet size
]

{ #category : 'tests' }
PathCommandDispatchTest >> testUppercaseCommandIsAbsolute [
	| cmd |
	cmd := PathCloseCommand new buildFrom: $Z stream: (ReadStream on: #()).
	self deny: cmd coordinatesAreRelative
]
