"
I widen a path into an area to fill, which is how a stroke is drawn: the backend knows how to fill segments and nothing else, so a stroke must become a fill before it crosses the boundary.

My path is in device space, as every built path is, and the line width is a user-space length, so I map the path back to user space with my matrix, widen it there, and map the outline forward again. That is why a stroke under an anisotropic scale is thicker along one axis, exactly as Cairo's is.

I emit one quadrilateral per segment and a disc at every vertex where two segments meet, all wound the same way so the winding rule sees their union. Cairo's real caps, joins and miter limit arrive in unit 1.4; a disc is the join that needs no orientation and never leaves the stroke.

`VGStroker path: aPath matrix: aMatrix lineWidth: aNumber` then `segments` is the whole of my protocol.
"
Class {
	#name : 'VGStroker',
	#superclass : 'Object',
	#instVars : [
		'path',
		'matrix',
		'lineWidth'
	],
	#category : 'VectorGraphics-Cairo-Path',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Path'
}

{ #category : 'constants' }
VGStroker class >> minimumDiscPointCount [
	"A join disc is never coarser than an octagon, however small the line width: below the
	 tolerance the shape stops mattering, but a triangle would still look like a triangle."

	^ 8
]

{ #category : 'instance creation' }
VGStroker class >> path: aPath matrix: aMatrix lineWidth: aNumber [
	^ self new setPath: aPath matrix: aMatrix lineWidth: aNumber
]

{ #category : 'private' }
VGStroker >> appendPolygon: userPoints into: aStream [
	"The polygon's edges, closed, mapped to device space. The mapping may mirror the polygon, but
	 it mirrors every polygon alike, so the winding stays consistent."

	| devicePoints |
	devicePoints := userPoints collect: [ :each | matrix value: each ].
	1 to: devicePoints size do: [ :index |
		| from to |
		from := devicePoints at: index.
		to := devicePoints at: index \\ devicePoints size + 1.
		aStream
			nextPut: from x asFloat;
			nextPut: from y asFloat;
			nextPut: to x asFloat;
			nextPut: to y asFloat ]
]

{ #category : 'private' }
VGStroker >> discAt: aPoint into: aStream [
	"A polygon inscribed in the circle of half the line width around aPoint, wound the same way
	 as a segment quadrilateral: the angles decrease, which turns the same way as a direction
	 turned a quarter turn."

	| radius count |
	radius := lineWidth / 2.0.
	radius isZero ifTrue: [ ^ self ].
	count := self discPointCount.
	self
		appendPolygon: ((0 to: count - 1) collect: [ :index |
				 | angle |
				 angle := index * -2.0 * Float pi / count.
				 aPoint + (radius * angle cos @ (radius * angle sin)) ])
		into: aStream
]

{ #category : 'private' }
VGStroker >> discPointCount [
	"Enough vertices that the polygon stays within the flattening tolerance of the circle it
	 approximates, measured in device space. The scale factors are read as a length, which
	 overstates the scale of an anisotropic matrix and so only ever buys extra vertices."

	| radius tolerance |
	radius := lineWidth / 2.0 * matrix scaleFactors r.
	tolerance := VGPathBuilder defaultFlatteningTolerance.
	radius <= tolerance ifTrue: [ ^ self class minimumDiscPointCount ].
	^ (Float pi / (1.0 - (tolerance / radius)) arcCos) ceiling
		  max: self class minimumDiscPointCount
]

{ #category : 'converting' }
VGStroker >> edgeCoordinates [
	| stream inverse |
	inverse := matrix inverted.
	stream := WriteStream on: (Array new: path pointCount * 16).
	path subPaths do: [ :subPath |
		self
			outlineOf: (subPath points collect: [ :each | inverse value: each ])
			closed: subPath isClosed
			into: stream ].
	^ stream contents
]

{ #category : 'inspector' }
VGStroker >> inspectorOutline: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Outline'>
	"The outline I turn the path into, with the numbers that decide its shape. The vertex count
	 of a join disc is asked of the real method, so an anisotropic matrix shows the count it
	 really buys."

	^ aBuilder newTable
		  items: {
				  ('Line width in user space' -> lineWidth).
				  ('Scale factors of the matrix' -> matrix scaleFactors).
				  ('Vertices a join disc gets' -> self discPointCount).
				  ('Runs in the path' -> path subPaths size).
				  ('Points in the path' -> path pointCount).
				  ('Edges in the outline' -> self segments size).
				  ('Fill rule of the outline' -> self segments fillRule).
				  ('Bounding box of the outline' -> self segments boundingBox) };
		  addColumn: (SpStringTableColumn
				   title: 'Property'
				   evaluated: [ :each | each key ]);
		  addColumn: (SpStringTableColumn
				   title: 'Value'
				   evaluated: [ :each | each value printString ]);
		  yourself
]

{ #category : 'inspector' }
VGStroker >> inspectorOutlineContext: aContext [
	aContext active: (path notNil and: [ matrix notNil ])
]

{ #category : 'accessing' }
VGStroker >> lineWidth [
	^ lineWidth
]

{ #category : 'accessing' }
VGStroker >> matrix [
	^ matrix
]

{ #category : 'private' }
VGStroker >> outlineOf: userPoints closed: aBoolean into: aStream [
	"One quadrilateral per segment, plus a disc at every vertex where two segments meet. A disc
	 is the join that needs no orientation and never leaves the stroke; Cairo's real caps and
	 joins, which this one approximates, arrive in unit 1.4."

	| vertices |
	userPoints size < 2 ifTrue: [ ^ self ].
	vertices := (aBoolean and: [ userPoints first ~= userPoints last ])
		            ifTrue: [ userPoints , { userPoints first } ]
		            ifFalse: [ userPoints ].
	1 to: vertices size - 1 do: [ :index |
		self quadFrom: (vertices at: index) to: (vertices at: index + 1) into: aStream ].
	2 to: vertices size - 1 do: [ :index |
		self discAt: (vertices at: index) into: aStream ].
	aBoolean ifTrue: [ self discAt: vertices first into: aStream ]
]

{ #category : 'accessing' }
VGStroker >> path [
	^ path
]

{ #category : 'printing' }
VGStroker >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: '(width: ';
		print: lineWidth;
		nextPutAll: ' path: ';
		print: path;
		nextPut: $)
]

{ #category : 'private' }
VGStroker >> quadFrom: aStartPoint to: anEndPoint into: aStream [
	"The segment widened by half the line width on each side. The offset is the direction turned
	 a quarter turn, which always turns the same way, so every quadrilateral I emit is wound the
	 same way and the winding rule sees their union rather than holes where they overlap."

	| direction length offset |
	direction := anEndPoint - aStartPoint.
	length := direction r.
	length isZero ifTrue: [ ^ self ].
	offset := direction y negated @ direction x / length * (lineWidth / 2.0).
	self
		appendPolygon: {
				aStartPoint + offset.
				anEndPoint + offset.
				anEndPoint - offset.
				aStartPoint - offset }
		into: aStream
]

{ #category : 'converting' }
VGStroker >> segments [
	"My path widened into an area to fill. The width is a user-space length, so the outline is
	 built in user space and mapped to device space afterwards: that is why a stroke under an
	 anisotropic scale comes out thicker along one axis, as Cairo's does."

	^ VGSegments coordinates: self edgeCoordinates fillRule: #winding
]

{ #category : 'initialization' }
VGStroker >> setPath: aPath matrix: aMatrix lineWidth: aNumber [
	path := aPath.
	matrix := aMatrix.
	lineWidth := aNumber
]
