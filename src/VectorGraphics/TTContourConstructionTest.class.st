Class {
	#name : 'TTContourConstructionTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Tests',
	#package : 'VectorGraphics',
	#tag : 'Tests'
}

{ #category : 'helpers' }
TTContourConstructionTest >> makeContour: aPointArray flags: aByteArray [

	| c |
	c := TTContourConstruction new.
	c instVarNamed: 'points' put: aPointArray.
	c instVarNamed: 'controlPointFlags' put: aByteArray.
	^ c
]

{ #category : 'helpers' }
TTContourConstructionTest >> makeContourAllEndPoints: aPointArray [

	^ self makeContour: aPointArray flags: (ByteArray newBits: aPointArray size)
]

{ #category : 'tests' }
TTContourConstructionTest >> testAddContourDataToStream [

	"Two end-point contour [A, B]: bezierCount=2, then firstPoint, then two relative bezier records."

	| pts contour stream |
	pts := Int16PointArray new: 2.
	pts at: 1 put: 10 @ 20.
	pts at: 2 put: 30 @ 40.
	contour := self makeContourAllEndPoints: pts.
	stream := WriteStream on: Float32Array new.
	contour addContourDataTo: stream tx: nil.
	"Expected: bezierCount=2, 10, 20, 20, 20, 20, 20, -20, -20, -20, -20"
	self assert: (stream contents at: 1) equals: 2.
	self assert: (stream contents at: 2) equals: 10.
	self assert: (stream contents at: 3) equals: 20.
	"Bezier 1 relative end = 30-10=20, 40-20=20; control = same"
	self assert: (stream contents at: 4) equals: 20.
	self assert: (stream contents at: 5) equals: 20.
	self assert: (stream contents at: 6) equals: 20.
	self assert: (stream contents at: 7) equals: 20
]

{ #category : 'tests' }
TTContourConstructionTest >> testAddContourDataToStreamSkipsEmpty [

	| pts contour stream |
	pts := Int16PointArray new: 1.
	pts at: 1 put: 5 @ 5.
	contour := self makeContourAllEndPoints: pts.
	stream := WriteStream on: Float32Array new.
	contour addContourDataTo: stream tx: nil.
	self assert: stream contents isEmpty
]

{ #category : 'tests' }
TTContourConstructionTest >> testInitialMoveToCommandClass [

	| pts contour cmd |
	pts := Int16PointArray new: 2.
	pts at: 1 put: 3 @ 7.
	pts at: 2 put: 9 @ 5.
	contour := self makeContourAllEndPoints: pts.
	cmd := contour initialMoveToCommand: nil.
	self assert: cmd class equals: PathMoveToCommand
]

{ #category : 'tests' }
TTContourConstructionTest >> testIsEmptyOnePoint [

	| pts |
	pts := Int16PointArray new: 1.
	pts at: 1 put: 0 @ 0.
	self assert: (self makeContourAllEndPoints: pts) isEmpty
]

{ #category : 'tests' }
TTContourConstructionTest >> testIsNotEmptyTwoPoints [

	| pts |
	pts := Int16PointArray new: 2.
	pts at: 1 put: 0 @ 0.
	pts at: 2 put: 10 @ 10.
	self deny: (self makeContourAllEndPoints: pts) isEmpty
]

{ #category : 'tests' }
TTContourConstructionTest >> testMakePointsAbsoluteAccumulates [

	| pts contour |
	pts := Int16PointArray new: 3.
	pts at: 1 put: 1 @ 2.
	pts at: 2 put: 3 @ 4.
	pts at: 3 put: 5 @ 6.
	contour := self makeContourAllEndPoints: pts.
	contour makePointsAbsolute: 10 @ 20.
	"10+1=11, 11+3=14, 14+5=19; 20+2=22, 22+4=26, 26+6=32"
	self assert: (pts at: 1) equals: 11 @ 22.
	self assert: (pts at: 2) equals: 14 @ 26.
	self assert: (pts at: 3) equals: 19 @ 32
]

{ #category : 'tests' }
TTContourConstructionTest >> testMakePointsAbsoluteReturnsLastPoint [

	| pts contour result |
	pts := Int16PointArray new: 2.
	pts at: 1 put: 1 @ 1.
	pts at: 2 put: 2 @ 2.
	contour := self makeContourAllEndPoints: pts.
	result := contour makePointsAbsolute: 0 @ 0.
	self assert: result equals: 3 @ 3
]

{ #category : 'tests' }
TTContourConstructionTest >> testPathCommandClass [

	| pts contour cmd |
	pts := Int16PointArray new: 2.
	pts at: 1 put: 0 @ 0.
	pts at: 2 put: 10 @ 10.
	contour := self makeContourAllEndPoints: pts.
	cmd := contour pathCommand: nil.
	self assert: cmd class equals: PathQuadraticCurveToCommand
]

{ #category : 'tests' }
TTContourConstructionTest >> testPrintOn [

	| pts contour stream |
	pts := Int16PointArray new: 3.
	contour := self makeContourAllEndPoints: pts.
	stream := WriteStream on: String new.
	contour printOn: stream.
	self assert: (stream contents includesSubstring: 'TTContourConstruction').
	self assert: (stream contents includesSubstring: '3')
]

{ #category : 'tests' }
TTContourConstructionTest >> testQuadraticBezierWithControlPoint [

	"[A, CP, B]: CP is off-curve (bit 2=1). Generates curve A→B via CP, then line B→A."

	| pts flags contour eps cps |
	pts := Int16PointArray new: 3.
	pts at: 1 put: 0 @ 0.    "A"
	pts at: 2 put: 10 @ 10.  "CP (off-curve)"
	pts at: 3 put: 20 @ 0.   "B"
	flags := ByteArray newBits: 3.
	flags bitAt: 2 put: 1.   "bit 2 = CP is control"
	contour := self makeContour: pts flags: flags.
	eps := OrderedCollection new.
	cps := OrderedCollection new.
	contour quadraticBeziersDo: [ :ep :cp |
		eps add: ep.
		cps add: cp ].
	"First bezier: curve to B using CP"
	self assert: (eps at: 1) equals: 20 @ 0.
	self assert: (cps at: 1) equals: 10 @ 10.
	"Second bezier: line back to A"
	self assert: (eps at: 2) equals: (cps at: 2)
]

{ #category : 'tests' }
TTContourConstructionTest >> testQuadraticBeziersTwoEndPointsCount [

	"Two end-point closed contour generates 2 bezier calls: A→B and B→A."

	| pts contour count |
	pts := Int16PointArray new: 2.
	pts at: 1 put: 0 @ 0.
	pts at: 2 put: 10 @ 0.
	contour := self makeContourAllEndPoints: pts.
	count := 0.
	contour quadraticBeziersDo: [ :ep :cp | count := count + 1 ].
	self assert: count equals: 2
]

{ #category : 'tests' }
TTContourConstructionTest >> testQuadraticBeziersTwoEndPointsLineValues [

	"For a line segment, controlPoint = endPoint."

	| pts contour eps cps |
	pts := Int16PointArray new: 2.
	pts at: 1 put: 0 @ 0.
	pts at: 2 put: 10 @ 5.
	contour := self makeContourAllEndPoints: pts.
	eps := OrderedCollection new.
	cps := OrderedCollection new.
	contour quadraticBeziersDo: [ :ep :cp |
		eps add: ep.
		cps add: cp ].
	"Line: endPoint = controlPoint for both segments"
	self assert: (eps at: 1) equals: (cps at: 1).
	self assert: (eps at: 2) equals: (cps at: 2)
]
