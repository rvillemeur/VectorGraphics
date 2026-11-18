"
I test the cubic curve a Type 2 charstring draws, and the quadratic curves a TrueType glyph has to hold it in.

A cubic is given four points: where it starts, two control points and where it ends. A quadratic has one control point, so a cubic becomes a chain of quadratics, and the chain is only ever an approximation. I state how close it has to be, in font units, and measure the chain against the cubic itself rather than against the way it was built.
"
Class {
	#name : 'TTCffCubicTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-TrueType-Tests-Tests',
	#package : 'VectorGraphics-TrueType-Tests',
	#tag : 'Tests'
}

{ #category : 'running' }
TTCffCubicTest >> distanceOf: aPoint fromChainOf: aCollection startingAt: aStartPoint [
	"How far a point lies from the chain of quadratics, measured against the segments
	 between points sampled along the chain. Fifty samples a curve leave segments of a
	 couple of font units, which a perpendicular distance measures finely enough for a
	 tolerance of a tenth."

	| distances from |
	distances := OrderedCollection new.
	from := aStartPoint.
	aCollection do: [ :each |
		| samples |
		samples := (0 to: 50) collect: [ :step |
			           | time rest |
			           time := step / 50.
			           rest := 1 - time.
			           from * rest * rest + (each first * 2 * rest * time)
			           + (each second * time * time) ].
		samples allButFirst doWithIndex: [ :sample :index |
			distances add: (
				 self
					 distanceOf: aPoint
					 fromSegmentFrom: (samples at: index)
					 to: sample) ].
		from := each second ].
	^ distances min
]

{ #category : 'running' }
TTCffCubicTest >> distanceOf: aPoint fromSegmentFrom: aStartPoint to: anEndPoint [
	"How far a point lies from a straight segment, which is the distance to the nearest
	 point of it and not to its ends."

	| along length time nearest |
	along := anEndPoint - aStartPoint.
	length := along x squared + along y squared.
	length = 0 ifTrue: [ ^ (aPoint - aStartPoint) r ].
	time := (aPoint - aStartPoint) x * along x
	        + ((aPoint - aStartPoint) y * along y) / length.
	time := (time max: 0) min: 1.
	nearest := aStartPoint + (along * time).
	^ (aPoint - nearest) r
]

{ #category : 'tests' }
TTCffCubicTest >> testACubicThatIsAQuadraticInDisguiseIsAnsweredAsOneQuadratic [
	"Every quadratic can be written as a cubic, by pulling its control point two thirds of the
	 way towards each end. Such a cubic needs no splitting and no approximation: the one
	 quadratic it came from is exact."

	| cubic quadratics |
	cubic := TTCffCubic
		         from: 0 @ 0
		         via: 200 / 3 @ (400 / 3)
		         and: 400 / 3 @ (400 / 3)
		         to: 200 @ 0.
	quadratics := cubic quadraticsWithinTolerance: 0.1.
	self assert: quadratics size equals: 1.
	self assert: quadratics first first equals: 100 @ 200.
	self assert: quadratics first second equals: 200 @ 0
]

{ #category : 'tests' }
TTCffCubicTest >> testTheChainOfQuadraticsStaysWithinTheToleranceOfTheCubic [
	"A curve too deep for one quadratic is split until it is held. The chain is measured
	 against the cubic itself, point by point, and not against the way it was built."

	| cubic quadratics worst |
	cubic := TTCffCubic
		         from: 0 @ 0
		         via: 0 @ 300
		         and: 300 @ 300
		         to: 300 @ 0.
	quadratics := cubic quadraticsWithinTolerance: 0.1.
	self assert: quadratics size > 1.
	worst := ((0 to: 100) collect: [ :step |
		          self
			          distanceOf: (cubic pointAt: step / 100)
			          fromChainOf: quadratics
			          startingAt: cubic start ]) max.
	self assert: worst <= 0.1 description: 'the chain strays ' , worst printString
]

{ #category : 'tests' }
TTCffCubicTest >> testTheChainStartsAndEndsWhereTheCubicDoesAndJoinsEndToEnd [
	"Whatever the splitting, the chain draws one connected curve: the first quadratic starts at
	 the start of the cubic, each one ends where the next starts, and the last ends at the end
	 of the cubic."

	| cubic quadratics |
	cubic := TTCffCubic
		         from: 10 @ 20
		         via: 10 @ 400
		         and: 500 @ 400
		         to: 500 @ 20.
	quadratics := cubic quadraticsWithinTolerance: 0.1.
	self assert: quadratics last second equals: cubic end.
	self
		assert: (self
				 distanceOf: cubic start
				 fromChainOf: quadratics
				 startingAt: cubic start)
		equals: 0.
	quadratics allButFirst doWithIndex: [ :each :index |
		self
			assert: (self
					 distanceOf: (quadratics at: index) second
					 fromChainOf: { each }
					 startingAt: (quadratics at: index) second)
			equals: 0 ]
]
