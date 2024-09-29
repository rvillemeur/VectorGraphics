"
This class represents a temporary contour structure during the construction of a TTGlyph from a TrueType file.

Instance variables:
	points				<ShortPointArray>	The points defining this contour
	controlPointFlags	<BitArray (ByteArray with bit content)> Flags for each point
"
Class {
	#name : #TTContourConstruction,
	#superclass : #Object,
	#instVars : [
		'points',
		'controlPointFlags'
	],
	#category : #'VectorGraphics-TrueType'
}

{ #category : #'instance creation' }
TTContourConstruction class >> on: points [

	^ self new points: points
]

{ #category : #'primitive format' }
TTContourConstruction >> addContourDataTo: stream tx: aGeometryTransformationOrNil [

	| bezierCount firstPoint cp ep prevEndPoint cpr epr |
	self isEmpty ifTrue: [ ^ self ].

	bezierCount := 0.
	self quadraticBeziersDo: [ :endPoint :controlPoint | 
		bezierCount := bezierCount + 1 ].
	stream nextPut: bezierCount.

	firstPoint := points first.
	aGeometryTransformationOrNil ifNotNil: [ 
		firstPoint := aGeometryTransformationOrNil transform: firstPoint ].
	stream
		nextPut: firstPoint x;
		nextPut: firstPoint y.


	prevEndPoint := firstPoint.
	self quadraticBeziersDo: [ :endPoint :controlPoint | 
		ep := endPoint.
		cp := controlPoint.
		aGeometryTransformationOrNil notNil ifTrue: [ 
			ep := aGeometryTransformationOrNil transform: ep.
			cp := aGeometryTransformationOrNil transform: cp ].
		epr := ep - prevEndPoint.
		cpr := cp - prevEndPoint.
		stream
			nextPut: epr x;
			nextPut: epr y.
		stream
			nextPut: cpr x;
			nextPut: cpr y.
		prevEndPoint := ep ]
]

{ #category : #accessing }
TTContourConstruction >> controlPointFlags [

	^ controlPointFlags
]

{ #category : #enumerating }
TTContourConstruction >> initialMoveToCommand: anAffineTransformationOrNil [

	"TrueType reasonably assumes Y coordinates increase upwards."

	| p |
	p := points first.
	anAffineTransformationOrNil notNil ifTrue: [ 
		p := anAffineTransformationOrNil transform: p ].
	^ PathMoveToCommand new toRelativePoint: p
]

{ #category : #enumerating }
TTContourConstruction >> isEmpty [

	^ points size < 2
]

{ #category : #converting }
TTContourConstruction >> makePointsAbsolute: aPoint [

	| t |
	t := aPoint.
	1 to: points size do: [ :i | 
		t := t + (points at: i).
		points at: i put: t ].
	^ t
]

{ #category : #enumerating }
TTContourConstruction >> pathCommand: anAffineTransformationOrNil [

	"TrueType reasonably assumes Y coordinates increase upwards."

	| prevEndPoint endPoints controlPoints cp ep |
	prevEndPoint := points first.
	anAffineTransformationOrNil notNil ifTrue: [ 
		prevEndPoint := anAffineTransformationOrNil transform: prevEndPoint ].
	endPoints := OrderedCollection new.
	controlPoints := OrderedCollection new.
	self quadraticBeziersDo: [ :endPoint :controlPoint | 
		ep := endPoint.
		cp := controlPoint.
		anAffineTransformationOrNil notNil ifTrue: [ 
			ep := anAffineTransformationOrNil transform: ep.
			cp := anAffineTransformationOrNil transform: cp ].
		endPoints add: ep - prevEndPoint.
		controlPoints add: cp - prevEndPoint.
		prevEndPoint := ep ].
	^ PathQuadraticCurveToCommand new
		  toRelativePoints: endPoints
		  controlPoints: controlPoints
]

{ #category : #accessing }
TTContourConstruction >> points [

	^ points
]

{ #category : #accessing }
TTContourConstruction >> points: aShortPointArray [

	points := aShortPointArray.
	controlPointFlags := ByteArray newBits: aShortPointArray size
]

{ #category : #printing }
TTContourConstruction >> printOn: aStream [

	aStream
		nextPutAll: self class name;
		nextPut: $(;
		print: points size;
		"space; 		print: self type;"nextPut: $)
]

{ #category : #enumerating }
TTContourConstruction >> quadraticBeziersDo: aBlock [

	"Iterate over Bezier curves of the receiver.	
		aBlock has two arguments: endPoint and controlPoint. 	
		StartPoint is assumed to be previous endPoint, or points first for the first curve.	
		Contour parts may either be straight line segments or quadratic bezier curves.	
		The decision is made upon the type flags in controlPointFlags as follows:	
			a) Two subsequent #isEndPoint points define a straight segment 	
			b) An #isEndPoint point followed by an #isControlPoint point followed 		
					by an #isEndPoint point defines a quadratic bezier segment	
			c)Two subsequent #isControlPoint points have an implicitely defined  		
					#isEndPoint point at half the distance between them"
	| firstEndPoint pointIsControlPoint previousPoint previousPointWasControlPoint |
	firstEndPoint := points at: 1.
	previousPoint := firstEndPoint.
	previousPointWasControlPoint := controlPointFlags bitBooleanAt: 1.
	2 to: points size do: [ :i | 
		| point |
		point := points at: i.
		pointIsControlPoint := controlPointFlags bitBooleanAt: i.
		pointIsControlPoint
			ifTrue: [ 
				previousPointWasControlPoint ifTrue: [ "Quadratic Bezier" 
					aBlock value: point + previousPoint / 2.0 value: previousPoint ] ]
			ifFalse: [ 
				previousPointWasControlPoint
					ifTrue: [ "Quadratic Bezier" 
					aBlock value: point value: previousPoint ]
					ifFalse: [ "Line segment" aBlock value: point value: point ] ].
		previousPoint := point.
		previousPointWasControlPoint := pointIsControlPoint ].
	previousPoint = firstEndPoint ifFalse: [ 
		previousPointWasControlPoint
			ifTrue: [ aBlock value: firstEndPoint value: previousPoint ]
			ifFalse: [ aBlock value: firstEndPoint value: firstEndPoint ] ]
]
