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
		'state'
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
	"The two numbers that were all a stroke needed before the caps, joins and dashes of unit 1.4,
	 as a state of their own. Every other parameter keeps its Cairo default."

	^ self path: aPath state: (VGCairoState new
			   matrix: aMatrix;
			   lineWidth: aNumber;
			   yourself)
]

{ #category : 'instance creation' }
VGStroker class >> path: aPath state: aState [
	^ self new setPath: aPath state: aState
]

{ #category : 'accessing' }
VGStroker class >> polygonWindingSign [
	"The sign of the signed area every polygon of an outline is handed to the rasteriser with.
	 The winding rule sees a union of overlapping polygons only while they all turn the same way,
	 so the stroker normalises each one to this sign; the value itself is arbitrary, and a
	 mirroring matrix or a wedge taken the other way round cannot punch a hole in a stroke."

	^ -1
]

{ #category : 'private' }
VGStroker >> appendPolygon: userPoints into: aStream [
	"The polygon's edges, closed, mapped to device space. A polygon whose device winding came
	 out the other way round — a mirroring matrix, or a wedge built on the far side of a vertex
	 — is reversed, so every polygon of one outline winds the same way and the winding rule sees
	 their union rather than holes where they overlap."

	| devicePoints |
	devicePoints := userPoints collect: [ :each | self matrix value: each ].
	devicePoints size < 3 ifTrue: [ ^ self ].
	(self signedAreaOf: devicePoints) sign = self class polygonWindingSign ifFalse: [
		devicePoints := devicePoints reversed ].
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
VGStroker >> capAt: aVertex along: anOutwardDirection into: aStream [
	"The cap Cairo draws past the end of a run: a butt cap adds nothing at all, a round cap the
	 disc, and a square cap an extension of half the line width along the outward direction."

	self style lineCap == #butt ifTrue: [ ^ self ].
	self style lineCap == #round ifTrue: [ ^ self discAt: aVertex into: aStream ].
	self squareCapAt: aVertex along: anOutwardDirection into: aStream
]

{ #category : 'private' }
VGStroker >> capAt: aVertex towards: aNeighbour into: aStream [
	"The cap at an end of an open run. The outward direction points away from the neighbour the
	 run arrived from."

	| direction |
	direction := self directionFrom: aNeighbour to: aVertex.
	direction ifNil: [ ^ self ].
	self capAt: aVertex along: direction into: aStream
]

{ #category : 'private' }
VGStroker >> dashDotAt: aVertex along: aDirection into: aStream [
	"A dash run of no length carries both its caps on the one point. A butt cap paints nothing,
	 a round cap the disc, and a square cap the whole square, which is the one place a square
	 cap draws on no length at all and is what Cairo's own documentation offers for a dotted
	 line."

	self capAt: aVertex along: aDirection negated into: aStream.
	self capAt: aVertex along: aDirection into: aStream
]

{ #category : 'private - dashes' }
VGStroker >> dashEdgeFrom: from to: to walk: walk into: aStream [
	"Walk one edge of the run, spending the dash cycle entry by entry, and answer the direction
	 the edge ran in, or nil for an edge of no length. `walk` holds the index of the entry being
	 spent and the length still left of it, and is left where the next edge has to carry on from,
	 because Cairo's pattern runs along the whole path and not along each edge."

	| lengths direction length travelled |
	direction := self directionFrom: from to: to.
	direction ifNil: [ ^ nil ].
	lengths := self style dashLengths.
	length := (to - from) r.
	travelled := 0.0.
	[ travelled < length ] whileTrue: [
		| step |
		step := (walk at: 2) min: length - travelled.
		(self style paintsDashEntryAt: (walk at: 1)) ifTrue: [
			self
				strokeDashFrom: from + (direction * travelled)
				to: from + (direction * (travelled + step))
				direction: direction
				into: aStream ].
		travelled := travelled + step.
		walk at: 2 put: (walk at: 2) - step.
		(walk at: 2) <= 0.0 ifTrue: [
			walk at: 1 put: (walk at: 1) \\ lengths size + 1.
			walk at: 2 put: (lengths at: (walk at: 1)) ] ].
	^ direction
]

{ #category : 'private - dashes' }
VGStroker >> dashTailAt: aPoint along: direction walk: walk into: aStream [
	"An entry of no length that lands on the very end of the run still paints: measured in live
	 Cairo, a pattern of no length on and twelve off paints five dots along a line of forty-eight,
	 the fifth of them on the end point. A run with no direction at all never reaches here."

	direction ifNil: [ ^ self ].
	(walk at: 2) <= 0.0 ifFalse: [ ^ self ].
	(self style paintsDashEntryAt: (walk at: 1)) ifFalse: [ ^ self ].
	self dashDotAt: aPoint along: direction into: aStream
]

{ #category : 'private' }
VGStroker >> dashWalkStart [
	"Where the dash cycle stands at the beginning of a run: the index into the doubled pattern,
	 and the length left in that entry. This is Cairo's own search, which stops as soon as the
	 offset reaches zero so that a first entry of no length is not stepped over."

	| lengths offset index |
	lengths := self style dashLengths.
	offset := self style dashOffset \\ self style dashPeriod.
	index := 1.
	[ offset > 0.0 and: [ offset >= (lengths at: index) ] ] whileTrue: [
		offset := offset - (lengths at: index).
		index := index \\ lengths size + 1 ].
	^ {
		  index.
		  ((lengths at: index) - offset) }
]

{ #category : 'private' }
VGStroker >> degenerateCapAt: aVertex into: aStream [
	"A sub-path with no length has no direction at all, so only a round cap has a shape to draw
	 there. Measured in live Cairo, a butt cap and a square cap paint nothing on it."

	self style lineCap == #round ifTrue: [ self discAt: aVertex into: aStream ]
]

{ #category : 'private' }
VGStroker >> directionFrom: aStartPoint to: anEndPoint [
	"The unit vector along the segment, or nil when the two points are the same one and the
	 segment has no direction at all."

	| direction length |
	direction := anEndPoint - aStartPoint.
	length := direction r.
	length isZero ifTrue: [ ^ nil ].
	^ direction / length
]

{ #category : 'private' }
VGStroker >> discAt: aPoint into: aStream [
	"A polygon inscribed in the circle of half the line width around aPoint, which is the shape
	 of a round cap and of a round join."

	| count radius |
	radius := self radius.
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

	| deviceRadius tolerance |
	deviceRadius := self radius * self matrix scaleFactors r.
	tolerance := self tolerance.
	deviceRadius <= tolerance ifTrue: [ ^ self class minimumDiscPointCount ].
	^ (Float pi / (1.0 - (tolerance / deviceRadius)) arcCos) ceiling
		  max: self class minimumDiscPointCount
]

{ #category : 'private' }
VGStroker >> edgeCoordinates [
	"The edges of the outline, four floats to an edge. A line width of nothing has no outline at
	 all: Cairo draws no hairline, and half of nothing is nothing on each side of the path."
	| stream inverse |
	self lineWidth <= 0 ifTrue: [ ^ #(  ) ].
	inverse := self matrix inverted.
	stream := WriteStream on: (Array new: path pointCount * 16).
	path subPaths do: [ :subPath |
		self
			strokeRun: (subPath points collect: [ :each | inverse value: each ])
			closed: subPath isClosed
			smoothSeam: subPath comesBackToItsStartSmoothly
			into: stream ].
	^ stream contents
]

{ #category : 'private' }
VGStroker >> edgesOf: vertices closed: aBoolean do: aBlock [
	"Every segment of the run in order, the closing one included when the run is closed."

	1 to: vertices size - 1 do: [ :index |
		aBlock value: (vertices at: index) value: (vertices at: index + 1) ].
	(aBoolean and: [ vertices size > 1 ]) ifTrue: [
		aBlock value: vertices last value: vertices first ]
]

{ #category : 'inspector' }
VGStroker >> inspectorOutline: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Outline'>
	"The outline I turn the path into, with the numbers that decide its shape. The vertex count
	 of a disc and the verdict on the first corner are asked of the real methods, so an
	 anisotropic matrix shows the count it really buys and a miter limit shows the join it
	 really draws."

	^ aBuilder newTable
		  items: {
				  ('Line width in user space' -> self lineWidth).
				  ('Cap' -> self style lineCap).
				  ('Join' -> self style lineJoin).
				  ('Miter limit' -> self style miterLimit).
				  ('First corner is mitered' -> self isFirstCornerMitered).
				  ('Dash pattern' -> self style dashPattern).
				  ('Dash period' -> self style dashPeriod).
				  ('Dash offset' -> self style dashOffset).
				  ('Flattening tolerance' -> self tolerance).
				  ('Antialiasing mode' -> self state antialias).
				  ('Scale factors of the matrix' -> self matrix scaleFactors).
				  ('Vertices a disc gets' -> self discPointCount).
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
	aContext active: (path notNil and: [ state notNil ])
]

{ #category : 'testing' }
VGStroker >> isFirstCornerMitered [
	"Whether the join at the first corner of the path runs out to its miter tip, asked of the
	 very predicate the outline is built with, so the answer cannot drift from the drawing.
	 Answers nil when the path holds no corner to join at all."

	| inverse |
	inverse := self matrix inverted.
	path subPaths do: [ :subPath |
		| vertices |
		vertices := self
			            verticesOf:
			            (subPath points collect: [ :each | inverse value: each ])
			            closed: subPath isClosed.
		vertices size > 2 ifTrue: [
			^ self
				  isMiteredBetween:
					  (self directionFrom: (vertices at: 1) to: (vertices at: 2))
				  and: (self directionFrom: (vertices at: 2) to: (vertices at: 3)) ] ].
	^ nil
]

{ #category : 'private' }
VGStroker >> isMiteredBetween: incoming and: outgoing [
	"Cairo's own rule: the miter is drawn when the distance from the vertex out to the tip,
	 divided by half the line width, is within the miter limit, and the bevel is drawn instead
	 once it is not. That ratio is one over the sine of half the angle the two segments make,
	 which the dot product answers without a trigonometric call."

	| dot |
	self style lineJoin == #miter ifFalse: [ ^ false ].
	dot := (incoming x * outgoing x) + (incoming y * outgoing y).
	(1.0 + dot) isZero ifTrue: [ ^ false ].
	^ (2.0 / (1.0 + dot)) sqrt <= self style miterLimit
]

{ #category : 'private' }
VGStroker >> joinAt: aVertex from: aPreviousPoint to: aNextPoint into: aStream [
	"The wedge between the two segment quadrilaterals, on the outer side of the turn: a round
	 join fills it with the disc, a bevel join closes the two outer corners with one straight
	 edge, and a miter join runs out to the tip. Two collinear segments leave no wedge at all."

	| incoming outgoing cross sign outer |
	self style lineJoin == #round ifTrue: [ ^ self discAt: aVertex into: aStream ].
	incoming := self directionFrom: aPreviousPoint to: aVertex.
	outgoing := self directionFrom: aVertex to: aNextPoint.
	(incoming isNil or: [ outgoing isNil ]) ifTrue: [ ^ self ].
	cross := (incoming x * outgoing y) - (incoming y * outgoing x).
	cross isZero ifTrue: [ ^ self ].
	sign := cross > 0
		        ifTrue: [ -1 ]
		        ifFalse: [ 1 ].
	outer := { incoming. outgoing } collect: [ :direction |
		         aVertex + ((self perpendicularOf: direction) * (sign * self radius)) ].
	self
		appendPolygon: ((self isMiteredBetween: incoming and: outgoing)
				 ifTrue: [
						 {
							 aVertex.
							 outer first.
							 (self
								  miterTipAt: aVertex
								  between: incoming
								  and: outgoing
								  side: sign).
							 outer second } ]
				 ifFalse: [
						 {
							 aVertex.
							 outer first.
							 outer second } ])
		into: aStream
]

{ #category : 'private' }
VGStroker >> joinsOf: vertices closed: aBoolean into: aStream [
	"One join at every vertex two segments meet at. A closed run meets at its own starting point
	 as well, which is why a closed stroke carries no cap and one join more than an open one.
	 A closed run of two vertices doubles back on itself: the two segments are collinear, so
	 there is no wedge to fill and no join to draw."

	2 to: vertices size - 1 do: [ :index |
		self
			joinAt: (vertices at: index)
			from: (vertices at: index - 1)
			to: (vertices at: index + 1)
			into: aStream ].
	(aBoolean and: [ vertices size > 2 ]) ifTrue: [
		self
			joinAt: vertices last
			from: (vertices at: vertices size - 1)
			to: vertices first
			into: aStream.
		self
			joinAt: vertices first
			from: vertices last
			to: (vertices at: 2)
			into: aStream ]
]

{ #category : 'accessing' }
VGStroker >> lineWidth [
	^ state lineWidth
]

{ #category : 'accessing' }
VGStroker >> matrix [
	^ state matrix
]

{ #category : 'private' }
VGStroker >> miterTipAt: aVertex between: incoming and: outgoing side: aSign [
	"The point the two outer edges of the join meet at: the vertex plus the sum of the two outer
	 offsets, scaled by one over one plus the dot product of the two directions."

	| dot sum |
	dot := (incoming x * outgoing x) + (incoming y * outgoing y).
	sum := (self perpendicularOf: incoming) + (self perpendicularOf: outgoing).
	^ aVertex + (sum * (aSign * self radius / (1.0 + dot)))
]

{ #category : 'accessing' }
VGStroker >> path [
	^ path
]

{ #category : 'private' }
VGStroker >> perpendicularOf: aPoint [
	"The point turned a quarter turn, which is the side a stroke is offset to."

	^ aPoint y negated @ aPoint x
]

{ #category : 'printing' }
VGStroker >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: '(';
		print: self style;
		nextPutAll: ' path: ';
		print: path;
		nextPut: $)
]

{ #category : 'private' }
VGStroker >> quadFrom: aStartPoint to: anEndPoint into: aStream [
	"The segment widened by half the line width on each side."

	| direction offset |
	direction := self directionFrom: aStartPoint to: anEndPoint.
	direction ifNil: [ ^ self ].
	offset := (self perpendicularOf: direction) * self radius.
	self
		appendPolygon: {
				aStartPoint + offset.
				anEndPoint + offset.
				anEndPoint - offset.
				aStartPoint - offset }
		into: aStream
]

{ #category : 'accessing' }
VGStroker >> radius [
	"Half the line width, which is how far the outline sits from the path on each side."

	^ self lineWidth / 2.0
]

{ #category : 'private' }
VGStroker >> seamJoinOf: vertices into: aStream [
	"The wedge between the last chord of a run and its first, filled for a run that comes back to
	 its own start in the direction it left in. Cairo strokes such a run as one smooth curve, so
	 its stroke has nothing missing there; ours strokes the chords, and the two end chords meet at
	 the angle the flattening left between them. The caps stay where they are: Cairo caps both
	 ends of the run as well, and a round or a square cap paints past the seam as it does at the
	 end of any other run."
	vertices size > 2 ifFalse: [ ^ self ].
	self
		joinAt: vertices first
		from: (vertices at: vertices size - 1)
		to: (vertices at: 2)
		into: aStream
]

{ #category : 'accessing' }
VGStroker >> segments [
	"My path widened into an area to fill. The width is a user-space length, so the outline is
	 built in user space and mapped to device space afterwards: that is why a stroke under an
	 anisotropic scale comes out thicker along one axis, as Cairo's does. The antialiasing mode
	 of the state rides along, because the backend takes no mode of its own."

	^ VGSegments
		  coordinates: self edgeCoordinates
		  fillRule: #winding
		  antialias: state antialias
]

{ #category : 'private' }
VGStroker >> setPath: aPath state: aState [
	path := aPath.
	state := aState
]

{ #category : 'private' }
VGStroker >> signedAreaOf: devicePoints [
	"Twice the signed area of the closed polygon, by the shoelace sum. Only the sign of the
	 answer is read, so the factor of two is left where it is."

	^ (1 to: devicePoints size) inject: 0.0 into: [ :sum :index |
		  | from to |
		  from := devicePoints at: index.
		  to := devicePoints at: index \\ devicePoints size + 1.
		  sum + (from x * to y) - (to x * from y) ]
]

{ #category : 'private' }
VGStroker >> squareCapAt: aVertex along: aDirection into: aStream [
	"The square a square cap adds: half the line width further along the direction, and half the
	 line width to each side of it."

	| offset extent |
	offset := (self perpendicularOf: aDirection) * self radius.
	extent := aDirection * self radius.
	self
		appendPolygon: {
				aVertex + offset.
				aVertex + offset + extent.
				aVertex - offset + extent.
				aVertex - offset }
		into: aStream
]

{ #category : 'accessing' }
VGStroker >> state [
	^ state
]

{ #category : 'private' }
VGStroker >> strokeDashFrom: aStartPoint to: anEndPoint direction: aDirection into: aStream [
	"One painted dash run, with a cap at each of its two ends. A run cut to no length still lies
	 along the edge it came from, so it keeps that direction for its caps to sit on."

	aStartPoint = anEndPoint ifTrue: [
		^ self dashDotAt: aStartPoint along: aDirection into: aStream ].
	self quadFrom: aStartPoint to: anEndPoint into: aStream.
	self capAt: aStartPoint along: aDirection negated into: aStream.
	self capAt: anEndPoint along: aDirection into: aStream
]

{ #category : 'private - dashes' }
VGStroker >> strokeDashedRun: vertices closed: aBoolean into: aStream [
	"Cairo treats every painted dash run as a sub-path of its own, so each run carries its own
	 pair of caps and no join is drawn where one run meets the next."

	| walk direction |
	vertices size = 1 ifTrue: [ ^ self degenerateCapAt: vertices first into: aStream ].
	walk := self dashWalkStart.
	direction := nil.
	self edgesOf: vertices closed: aBoolean do: [ :from :to |
		"An edge of no length answers no direction, and the direction of the last edge that had
		 one is the direction the tail of the run points in."
		direction := (self
			              dashEdgeFrom: from
			              to: to
			              walk: walk
			              into: aStream) ifNil: [ direction ] ].
	self
		dashTailAt: (aBoolean
				 ifTrue: [ vertices first ]
				 ifFalse: [ vertices last ])
		along: direction
		walk: walk
		into: aStream
]

{ #category : 'private' }
VGStroker >> strokeRun: userPoints closed: aBoolean smoothSeam: anotherBoolean into: aStream [
	"One run of the path, dashed or whole. A smooth seam is the join that stands for a curve
	 passing through its own first point; a dashed run is cut into runs of its own, and whether a
	 dash covers the seam at all is a question this does not ask, so the seam of a dashed run is
	 left to the dashes."
	| vertices |
	vertices := self verticesOf: userPoints closed: aBoolean.
	vertices isEmpty ifTrue: [ ^ self ].
	self style hasDashPattern ifTrue: [
		^ self strokeDashedRun: vertices closed: aBoolean into: aStream ].
	self strokeWholeRun: vertices closed: aBoolean into: aStream.
	(anotherBoolean and: [ aBoolean not ]) ifTrue: [
		self seamJoinOf: vertices into: aStream ]
]

{ #category : 'private' }
VGStroker >> strokeWholeRun: vertices closed: aBoolean into: aStream [
	"One quadrilateral per segment, a join at every turn, and a cap at each end of an open run.
	 A run of one point has no direction at all, which is the degenerate case Cairo draws only
	 under a round cap."

	vertices size = 1 ifTrue: [
		^ self degenerateCapAt: vertices first into: aStream ].
	1 to: vertices size - 1 do: [ :index |
		self
			quadFrom: (vertices at: index)
			to: (vertices at: index + 1)
			into: aStream ].
	aBoolean ifTrue: [
		self quadFrom: vertices last to: vertices first into: aStream ].
	self joinsOf: vertices closed: aBoolean into: aStream.
	aBoolean ifFalse: [
		self capAt: vertices first towards: (vertices at: 2) into: aStream.
		self
			capAt: vertices last
			towards: (vertices at: vertices size - 1)
			into: aStream ]
]

{ #category : 'accessing' }
VGStroker >> style [
	^ state strokeStyle
]

{ #category : 'accessing' }
VGStroker >> tolerance [
	"The device-space tolerance the round shapes of the outline are polygonised to."

	^ state tolerance
]

{ #category : 'private' }
VGStroker >> verticesOf: userPoints closed: aBoolean [
	"The points of a run with the repetitions dropped: two points at the same place give a
	 segment with no direction, and Cairo ignores it. A closed run also drops a last point equal
	 to its first, because the closing edge already joins the two."

	| vertices |
	vertices := OrderedCollection new.
	userPoints do: [ :each |
		(vertices notEmpty and: [ vertices last = each ]) ifFalse: [
			vertices add: each ] ].
	(aBoolean and: [
		 vertices size > 1 and: [ vertices first = vertices last ] ]) ifTrue: [
		vertices removeLast ].
	^ vertices asArray
]
