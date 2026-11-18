"
I am one cubic curve of a glyph outline, the curve a Type 2 charstring draws.

I hold four points: where I start, two control points, and where I end.

A TrueType glyph holds quadratic curves, which have one control point each, so I answer a chain of quadratics that stays within a stated distance of me, in font units. I measure that distance by the standard bound on the difference between a cubic and the quadratic that shares its ends, and I halve myself until every piece is within it. Halving a cubic gives two cubics of the same shape, so no accuracy is lost in the splitting itself.
"
Class {
	#name : 'TTCffCubic',
	#superclass : 'Object',
	#instVars : [
		'start',
		'firstControl',
		'secondControl',
		'end'
	],
	#category : 'VectorGraphics-TrueType-CFF',
	#package : 'VectorGraphics-TrueType',
	#tag : 'CFF'
}

{ #category : 'instance creation' }
TTCffCubic class >> from: aStartPoint via: aFirstControlPoint and: aSecondControlPoint to: anEndPoint [
	"The curve those four points draw, in the order a charstring states them."

	^ self new
		  setStart: aStartPoint
		  firstControl: aFirstControlPoint
		  secondControl: aSecondControlPoint
		  end: anEndPoint
]

{ #category : 'geometry' }
TTCffCubic >> deviationFromQuadratic [
	"How far the one quadratic can stray from me, in font units. The difference between a
	 cubic and that quadratic is bounded by the length of the cubic's third difference,
	 times the square root of three over thirty-six."

	| difference |
	difference := end - (secondControl * 3) + (firstControl * 3) - start.
	^ 3 sqrt / 36 * (difference x squared + difference y squared) sqrt
]

{ #category : 'geometry' }
TTCffCubic >> distanceFromMe: aPoint [
	"How far a point lies from me: the shortest distance to the straight segments between a
	 hundred points sampled along my length. Measuring to the segments and not to the
	 samples themselves keeps the sampling out of the figure."

	| samples |
	samples := (0 to: 100) collect: [ :step | self pointAt: step / 100 ].
	^ ((1 to: samples size - 1) collect: [ :index |
		   self
			   distanceOf: aPoint
			   fromSegmentFrom: (samples at: index)
			   to: (samples at: index + 1) ]) min
]

{ #category : 'geometry' }
TTCffCubic >> distanceOf: aPoint fromSegmentFrom: aStartPoint to: anEndPoint [
	"How far a point lies from a straight segment: the distance to the nearest point of
	 it, which is not always one of its ends."

	| along length time |
	along := anEndPoint - aStartPoint.
	length := along x squared + along y squared.
	length = 0 ifTrue: [ ^ (aPoint - aStartPoint) r ].
	time := (aPoint - aStartPoint) x * along x
	        + ((aPoint - aStartPoint) y * along y) / length.
	time := (time max: 0) min: 1.
	^ (aPoint - (aStartPoint + (along * time))) r
]

{ #category : 'accessing' }
TTCffCubic >> end [
	"Where I end."

	^ end
]

{ #category : 'geometry' }
TTCffCubic >> halves [
	"The two cubics that draw my two halves, cut at the middle of my parameter. Each is a
	 cubic of the same shape, so cutting loses nothing."

	| firstStep secondStep thirdStep firstJoin secondJoin middle |
	firstStep := start + firstControl / 2.
	secondStep := firstControl + secondControl / 2.
	thirdStep := secondControl + end / 2.
	firstJoin := firstStep + secondStep / 2.
	secondJoin := secondStep + thirdStep / 2.
	middle := firstJoin + secondJoin / 2.
	^ {
		  (self class
			   from: start
			   via: firstStep
			   and: firstJoin
			   to: middle).
		  (self class
			   from: middle
			   via: secondJoin
			   and: thirdStep
			   to: end) }
]

{ #category : 'inspector' }
TTCffCubic >> inspectorQuadratics: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Quadratics'>
	"The chain that holds me to within a tenth of a font unit: one row a quadratic, with
	 its control point, its end point, and how far the middle of that quadratic lies from
	 me. The rows are computed by the same method a glyph is drawn with, so they cannot
	 drift from what a glyph holds."

	| quadratics |
	quadratics := self quadraticsWithinTolerance:
		              TTCffTableParser quadraticTolerance.
	^ aBuilder newTable
		  addColumn: ((SpStringTableColumn title: 'Step' evaluated: [ :each |
				    (quadratics indexOf: each) printString ]) width: 60);
		  addColumn: ((SpStringTableColumn title: 'Control' evaluated: [ :each |
				    each first asFloatPoint printString ]) width: 160);
		  addColumn: ((SpStringTableColumn title: 'Ends at' evaluated: [ :each |
				    each second asFloatPoint printString ]) width: 160);
		  addColumn: (SpStringTableColumn title: 'Middle off by' evaluated: [ :each |
			   | index from middle |
			   index := quadratics indexOf: each.
			   from := index = 1
				           ifTrue: [ start ]
				           ifFalse: [ (quadratics at: index - 1) second ].
			   middle := from + (each first * 2) + each second / 4.
			   (self distanceFromMe: middle) printString ]);
		  items: quadratics;
		  yourself
]

{ #category : 'geometry' }
TTCffCubic >> pointAt: aNumber [
	"The point I reach at that fraction of my length in the parameter, 0 at my start and 1
	 at my end."

	| rest |
	rest := 1 - aNumber.
	^ start * rest * rest * rest + (firstControl * 3 * rest * rest * aNumber)
	  + (secondControl * 3 * rest * aNumber * aNumber)
	  + (end * aNumber * aNumber * aNumber)
]

{ #category : 'printing' }
TTCffCubic >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: '(';
		print: start;
		nextPutAll: ' to ';
		print: end;
		nextPutAll: ')'
]

{ #category : 'geometry' }
TTCffCubic >> quadraticControl [
	"The control point of the one quadratic that starts and ends where I do and follows me
	 as closely as a single quadratic can. It is where my two control tangents meet when
	 they are read as a quadratic's."

	^ firstControl * 3 - start + (secondControl * 3 - end) / 4
]

{ #category : 'geometry' }
TTCffCubic >> quadraticsWithinTolerance: aNumber [
	"The chain of quadratics that holds me to within that many font units, each of them a
	 pair of a control point and an end point. I halve myself until every piece is close
	 enough, so the chain starts where I start and ends where I end."

	self deviationFromQuadratic <= aNumber ifTrue: [
		^ { {
			  self quadraticControl.
			  end } } ].
	^ (self halves collect: [ :each |
		   each quadraticsWithinTolerance: aNumber ]) inject: #(  ) into: [
		  :all :each | all , each ]
]

{ #category : 'initialization' }
TTCffCubic >> setStart: aStartPoint firstControl: aFirstControlPoint secondControl: aSecondControlPoint end: anEndPoint [
	start := aStartPoint.
	firstControl := aFirstControlPoint.
	secondControl := aSecondControlPoint.
	end := anEndPoint
]

{ #category : 'accessing' }
TTCffCubic >> start [
	"Where I start."

	^ start
]
