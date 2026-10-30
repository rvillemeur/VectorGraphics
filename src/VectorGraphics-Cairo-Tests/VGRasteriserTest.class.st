"
I test the software scan converter: how much of each pixel a set of edges covers.

Coverage is what a fill rule and an antialiased edge both come down to, so the facts here are about
numbers rather than pixels: an aligned rectangle covers whole pixels, a half-pixel column covers
half of one, the coverage of a circle sums to its area, and a self-crossing path is hollow under the
even-odd rule and solid under the winding rule.
The rasteriser is exact across a pixel and samples down the pixel, which is where its stated
accuracy comes from.
"
Class {
	#name : 'VGRasteriserTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Cairo-Tests-Tests',
	#package : 'VectorGraphics-Cairo-Tests',
	#tag : 'Tests'
}

{ #category : 'support' }
VGRasteriserTest >> circleOfRadius: aNumber center: aPoint [
	^ (0 to: 719) collect: [ :index |
		  | angle |
		  angle := index * 2 * Float pi / 720.
		  aPoint + (angle cos * aNumber @ (angle sin * aNumber)) ]
]

{ #category : 'support' }
VGRasteriserTest >> coverageOf: aPointArray rule: aSymbol [
	"The whole coverage grid as a Dictionary from point to coverage, which is what makes a fact
	 about one pixel readable in a test."
	^ self coverageOfAll: { aPointArray } rule: aSymbol
]

{ #category : 'helpers' }
VGRasteriserTest >> coverageOfAll: aCollectionOfPointArrays rule: aSymbol [
	| grid rasteriser |
	grid := Dictionary new.
	rasteriser := VGRasteriser
		              segments: (self segmentsOfAll: aCollectionOfPointArrays)
		              fillRule: aSymbol
		              clip: (VGClip bounds: (0 @ 0 corner: 64 @ 64)).
	rasteriser coverageRowsDo: [ :y :coverage :left |
		1 to: coverage size do: [ :index |
			| value |
			value := coverage at: index.
			value isZero ifFalse: [ grid at: left + index - 1 @ y put: value ] ] ].
	^ grid
]

{ #category : 'fixtures' }
VGRasteriserTest >> edgeIndexShapes [
	"Three shapes whose edges are spread over their own bounding box, which is what an index over
	 bands has to get right: a self-crossing star, two nested squares, which leave the middle of
	 the box empty of edges, and a circle of many short edges."

	^ {
		  (self segmentsOfAll: { (self fivePointedStarOfRadius: 24 center: 32 @ 32) }).
		  (self segmentsOfAll: {
				   { 8 @ 8. 40 @ 8. 40 @ 40. 8 @ 40 }.
				   { 16 @ 16. 32 @ 16. 32 @ 32. 16 @ 32 } }).
		  (self segmentsOfAll: { (self circleOfRadius: 28 center: 32 @ 32) }) }
]

{ #category : 'helpers' }
VGRasteriserTest >> edgeReachOfBandsOf: coordinates bandHeight: aHeight [
	"No edge may sit in a band whose rows it does not reach, which is the whole point of the
	 index. The box is asked of the edges themselves, because an edge outside the box clamps into
	 the nearest band and would reach nothing."

	| scanner index |
	scanner := VGSpanScanner
		           segments: coordinates
		           fillRule: #nonZero
		           antialias: #default.
	index := VGEdgeIndex
		         coordinates: coordinates
		         bounds: scanner exactBoundingBox
		         bandHeight: aHeight.
	1 to: index bandCount do: [ :band |
		| rows |
		rows := index boundsOfBandAt: band.
		(index edgeIndexesInBandAt: band) do: [ :offset |
			| edge |
			edge := index boxOfEdgeAt: offset.
			self assert: edge top <= rows bottom.
			self assert: edge bottom >= rows top ] ]
]

{ #category : 'fixtures' }
VGRasteriserTest >> enclosureCorpus [
	"Shapes that between them hold every case the fast enclosure path may meet: a plain
	 rectangle, whose every edge lies on the border of its own box; two nested squares, whose
	 inner edges lie inside it; a triangle, whose slanted edge crosses it; a rectangle on
	 fractional coordinates; a rectangle traced twice, once each way, which is empty under the
	 winding rule though its edges still lie on the border; and a shape of no height at all."

	^ {
		  (VGSegments
			   coordinates:
			   (self segmentsOfAll: { { 8 @ 8. 40 @ 8. 40 @ 40. 8 @ 40 } })
			   fillRule: #winding).
		  (VGSegments
			   coordinates: (self segmentsOfAll: {
						    { 8 @ 8. 40 @ 8. 40 @ 40. 8 @ 40 }.
						    { 16 @ 16. 32 @ 16. 32 @ 32. 16 @ 32 } })
			   fillRule: #winding).
		  (VGSegments
			   coordinates: (self segmentsOfAll: {
						    { 8 @ 8. 40 @ 8. 40 @ 40. 8 @ 40 }.
						    { 16 @ 16. 32 @ 16. 32 @ 32. 16 @ 32 } })
			   fillRule: #evenOdd).
		  (VGSegments
			   coordinates:
			   (self segmentsOfAll: { { 4 @ 4. 44 @ 20. 8 @ 44 } })
			   fillRule: #winding).
		  (VGSegments
			   coordinates: (self segmentsOfAll:
					    { { 7.5 @ 7.5. 40.25 @ 7.5. 40.25 @ 40.25. 7.5 @ 40.25 } })
			   fillRule: #winding).
		  (VGSegments
			   coordinates: (self segmentsOfAll: {
						    { 8 @ 8. 40 @ 8. 40 @ 40. 8 @ 40 }.
						    { 8 @ 8. 8 @ 40. 40 @ 40. 40 @ 8 } })
			   fillRule: #winding).
		  (VGSegments
			   coordinates: (self segmentsOfAll: { { 8 @ 8. 40 @ 8 } })
			   fillRule: #winding) }
]

{ #category : 'support' }
VGRasteriserTest >> fivePointedStarOfRadius: aNumber center: aPoint [
	"The points taken two apart, which is what makes the star one self-crossing path with a
	 pentagon inside it rather than five triangles."
	^ (0 to: 4) collect: [ :index |
		  | angle |
		  angle := index * 4 * Float pi / 5 - (Float pi / 2).
		  aPoint + (angle cos * aNumber @ (angle sin * aNumber)) ]
]

{ #category : 'support' }
VGRasteriserTest >> segmentsOfAll: aCollectionOfPointArrays [
	| stream |
	stream := WriteStream on: (Array new: 64).
	aCollectionOfPointArrays do: [ :points |
		1 to: points size do: [ :index |
			| from to |
			from := points at: index.
			to := points at: (index \\ points size) + 1.
			stream
				nextPut: from x asFloat;
				nextPut: from y asFloat;
				nextPut: to x asFloat;
				nextPut: to y asFloat ] ].
	^ stream contents
]

{ #category : 'tests - coverage' }
VGRasteriserTest >> testAHalfPixelColumnIsCoveredExactlyInHalf [
	"Coverage across a pixel is exact, because a span contributes the part of the pixel it really
	 covers rather than a sample of it."
	| grid |
	grid := self coverageOf: { 4 @ 4. 4.5 @ 4. 4.5 @ 6. 4 @ 6 } rule: #winding.
	self assert: ((grid at: 4 @ 4) - 0.5) abs < 1.0e-9.
	self assert: ((grid at: 4 @ 5) - 0.5) abs < 1.0e-9
]

{ #category : 'tests - coverage' }
VGRasteriserTest >> testAHalfPixelRowIsCoveredWithinOneSubRow [
	"Coverage down a pixel is sampled, one sample per sub-row, so a horizontal edge inside a row is
	 placed to within one sub-row and no closer. That is the rasteriser's stated accuracy."
	| grid error |
	grid := self coverageOf: { 4 @ 4. 6 @ 4. 6 @ 4.5. 4 @ 4.5 } rule: #winding.
	error := 1 / VGRasteriser samplesPerPixelRow.
	self assert: ((grid at: 4 @ 4) - 0.5) abs <= error.
	self assert: ((grid at: 5 @ 4) - 0.5) abs <= error
]

{ #category : 'tests - fill rules' }
VGRasteriserTest >> testASelfCrossingStarIsSolidUnderWindingAndHollowUnderEvenOdd [
	| star winding evenOdd |
	star := self fivePointedStarOfRadius: 24 center: 32 @ 32.
	winding := self coverageOf: star rule: #winding.
	evenOdd := self coverageOf: star rule: #evenOdd.
	self assert: (winding at: 32 @ 32) equals: 1.
	self assert: (evenOdd at: 32 @ 32 ifAbsent: [ 0 ]) equals: 0.
	self assert: (winding at: 32 @ 20) equals: 1.
	self assert: (evenOdd at: 32 @ 20) equals: 1
]

{ #category : 'tests' }
VGRasteriserTest >> testASquareEnclosesARectangleInsideItAndNotOneThatCrossesItsEdge [
	"What a tiled rasteriser asks before it walks a tile: a rectangle every point of which is
	 inside the shape has coverage one at every pixel, so the walk can be skipped there. A
	 rectangle the shape cuts cannot be answered that way."

	| square |
	square := VGSegments
		          coordinates:
		          (self segmentsOfAll: { { 8 @ 8. 40 @ 8. 40 @ 40. 8 @ 40 } })
		          fillRule: #winding.
	self assert: (square enclosesWholly: (16 @ 16 corner: 32 @ 32)).
	self deny: (square enclosesWholly: (32 @ 32 corner: 48 @ 48)).
	self deny: (square enclosesWholly: (0 @ 0 corner: 48 @ 48))
]

{ #category : 'tests' }
VGRasteriserTest >> testASquareEnclosesNoRectangleItsOwnEdgeTouchesAndNoneOutsideIt [
	"The answer is conservative, because a yes paints a pixel whole that the walk would have
	 painted in part: a rectangle whose side lies exactly on an edge of the shape answers no,
	 and so does one the shape never reaches."

	| square |
	square := VGSegments
		          coordinates:
		          (self segmentsOfAll: { { 8 @ 8. 40 @ 8. 40 @ 40. 8 @ 40 } })
		          fillRule: #winding.
	self deny: (square enclosesWholly: (8 @ 16 corner: 24 @ 32)).
	self deny: (square enclosesWholly: (64 @ 64 corner: 72 @ 72)).
	self deny: (VGSegments empty enclosesWholly: (16 @ 16 corner: 32 @ 32))
]

{ #category : 'tests - coverage' }
VGRasteriserTest >> testAnAlignedRectangleCoversWholePixelsAndNothingOutside [
	| grid |
	grid := self coverageOf: { 4 @ 4. 12 @ 4. 12 @ 9. 4 @ 9 } rule: #winding.
	self assert: (grid at: 4 @ 4) equals: 1.
	self assert: (grid at: 11 @ 8) equals: 1.
	self assert: (grid at: 12 @ 4 ifAbsent: [ 0 ]) equals: 0.
	self assert: (grid at: 3 @ 4 ifAbsent: [ 0 ]) equals: 0.
	self assert: grid size equals: 8 * 5
]

{ #category : 'tests - edge index' }
VGRasteriserTest >> testAnEdgeIndexAnswersNoEdgeForRowsItsShapeDoesNotReach [
	"A run of rows the box of the shape does not reach holds no edge of it, rather than the
	 edges of the nearest band: an edge that cannot cross a row cannot wind it, so a caller
	 reading those rows owes a winding of nought and the edges would only cost it the reading.
	 The rows asked for are the rows of one band, which is how the tiled encoding asks."

	| height |
	height := 16.
	self edgeIndexShapes do: [ :coordinates |
		| scanner index box |
		scanner := VGSpanScanner
			           segments: coordinates
			           fillRule: #nonZero
			           antialias: #default.
		box := scanner exactBoundingBox.
		index := VGEdgeIndex
			         coordinates: coordinates
			         bounds: box
			         bandHeight: height.
		self
			assertEmpty:
			(index edgeIndexesMeetingRowsFrom: box top - 1000 to: box top - 984).
		self
			assertEmpty:
			(index
				 edgeIndexesMeetingRowsFrom: box bottom + 1000
				 to: box bottom + 1016).
		1 to: index bandCount do: [ :band |
			| rows found |
			rows := index boundsOfBandAt: band.
			found := index
				         edgeIndexesMeetingRowsFrom: rows top
				         to: rows bottom.
			self assert: found equals: (index edgeIndexesInBandAt: band).
			found do: [ :offset |
				| edge |
				edge := index boxOfEdgeAt: offset.
				self assert: edge top <= rows bottom.
				self assert: edge bottom >= rows top ] ] ]
]

{ #category : 'tests - edge index' }
VGRasteriserTest >> testAnEdgeIndexAnswersWhatAScanOverEveryEdgeAnswers [
	"The index may not change an answer: an index of one band is the scan over every edge, and an
	 index of as many bands as it chooses for itself has to agree with it at every rectangle and
	 at every point. The rectangles here walk the whole box of each shape, eight pixels at a
	 time, so they fall inside the shape, across its edges and outside it. The shapes are not all
	 cut into bands — eight edges fit in one — so the count is read afterwards and one shape at
	 least has to be cut, or the test would prove nothing about reading a band."

	| bounds counts |
	bounds := 0 @ 0 corner: 64 @ 64.
	counts := OrderedCollection new.
	self edgeIndexShapes do: [ :coordinates |
		| flat indexed |
		flat := VGEdgeIndex
			        coordinates: coordinates
			        bounds: bounds
			        bands: 1.
		indexed := VGEdgeIndex coordinates: coordinates bounds: bounds.
		counts add: indexed bandCount.
		0 to: 64 by: 8 do: [ :x |
			0 to: 64 by: 8 do: [ :y |
				| rectangle |
				rectangle := x @ y corner: x + 8 @ (y + 8).
				self
					assert: (indexed anEdgeMeets: rectangle)
					equals: (flat anEdgeMeets: rectangle).
				self
					assert: (indexed windingAt: x @ y)
					equals: (flat windingAt: x @ y) ] ] ].
	self assert: (counts anySatisfy: [ :each | each > 1 ])
]

{ #category : 'tests - edge index' }
VGRasteriserTest >> testAnEdgeIndexHoldsEveryEdgeOfItsShapeAndOnlyInBandsTheEdgeReaches [
	"Every edge is in the index, or a rectangle could miss it, and no edge is in a band its own
	 rows do not reach, or the index would be the scan it replaces. The reach is read closed, as
	 an edge lying exactly on the floor of a band is in the bands on both sides of it."

	| index coordinates seen |
	coordinates := self edgeIndexShapes first.
	index := VGEdgeIndex coordinates: coordinates bounds: (0 @ 0 corner: 64 @ 64).
	seen := Set new.
	1 to: index bandCount do: [ :band |
		| bandBox |
		bandBox := index boundsOfBandAt: band.
		(index edgeIndexesInBandAt: band) do: [ :each |
			| box |
			box := index boxOfEdgeAt: each.
			seen add: each.
			self assert: box bottom >= bandBox top.
			self assert: box top <= bandBox bottom ] ].
	self assert: seen size equals: index edgeCount
]

{ #category : 'tests - edge index' }
VGRasteriserTest >> testAnEdgeIndexOfADegenerateShapeAnswersWithoutDividingByNought [
	"The degenerate shapes: no edge at all meets nothing and winds nowhere, and a shape whose
	 edges all lie on one row has a box of no height, which may not be cut into bands."

	| empty flat row |
	empty := VGEdgeIndex coordinates: #(  ) bounds: (0 @ 0 corner: 64 @ 64).
	self deny: (empty anEdgeMeets: (0 @ 0 corner: 64 @ 64)).
	self assert: (empty windingAt: 32 @ 32) equals: 0.
	self assert: empty bandCount equals: 1.
	row := #( 8.0 20.0 40.0 20.0 40.0 20.0 8.0 20.0 ).
	flat := VGEdgeIndex coordinates: row bounds: (8 @ 20 corner: 40 @ 20).
	self assert: flat bandCount equals: 1.
	self assert: (flat anEdgeMeets: (16 @ 16 corner: 24 @ 24)).
	self deny: (flat anEdgeMeets: (16 @ 24 corner: 24 @ 32)).
	self assert: (flat windingAt: 24 @ 20) equals: 0
]

{ #category : 'tests - edge index' }
VGRasteriserTest >> testAnEdgeIndexOfBandsOfAGivenHeightAlignsThemToThatHeight [
	"The bands the tiled encoding needs are the rows of its tiles, so a band of a given height
	 starts at a multiple of that height whatever the box of the shape is, and the band of a row
	 is the band that row falls in. A row outside the box answers the nearest band, as it does
	 for bands chosen by edge count."

	| height boxes |
	height := 16.
	boxes := {
		          (0 @ 0 corner: 64 @ 64).
		          (5 @ 5 corner: 60 @ 63).
		          (5 @ 20 corner: 60 @ 63).
		          (7 @ 20 corner: 9 @ 20) }.
	self edgeIndexShapes do: [ :coordinates |
		boxes do: [ :box |
			| index |
			index := VGEdgeIndex
				         coordinates: coordinates
				         bounds: box
				         bandHeight: height.
			self
				assert: index bandCount
				equals: ((box bottom / height) ceiling - (box top / height) floor max: 1).
			1 to: index bandCount do: [ :band |
				| rows |
				rows := index boundsOfBandAt: band.
				self assert: rows height equals: height.
				self assert: (rows top / height) fractionPart equals: 0.
				self assert: (index bandOf: rows top) equals: band.
				self assert: (index bandOf: rows bottom - 0.5) equals: band ].
			self assert: (index bandOf: box top - 1000) equals: 1.
			self assert: (index bandOf: box bottom + 1000) equals: index bandCount ].
		self edgeReachOfBandsOf: coordinates bandHeight: height ]
]

{ #category : 'tests - enclosure' }
VGRasteriserTest >> testEveryEnclosureAnswerIsTheAnswerOfTheScanOverTheCorpus [
	"The predicate a tiled binning asks of a shape once a tile is answered by a fast path where
	 the shape holds no edge inside its own box: a rectangle strictly inside such a box meets no
	 edge, and the insideness of one point of that interior is the insideness of all of it. The
	 fast answer has to be the scanning answer for every shape of the corpus and every tile of a
	 grid laid over it, tiles that lie on the box's own border included, or the path is wrong."

	| answered |
	answered := 0.
	self enclosureCorpus do: [ :shape |
		0 to: 40 by: 8 do: [ :x |
			0 to: 40 by: 8 do: [ :y |
				| rectangle |
				rectangle := x @ y corner: x + 8 @ (y + 8).
				answered := answered + 1.
				self
					assert: (shape enclosesWholly: rectangle)
						= (shape scanner enclosesWhollyByScan: rectangle)
					description:
						shape printString , ' at ' , rectangle printString ] ] ].
	self assert: answered equals: self enclosureCorpus size * 36
]

{ #category : 'tests' }
VGRasteriserTest >> testNothingOutsideTheClipIsEverVisited [
	| rasteriser rows |
	rasteriser := VGRasteriser
		              segments: (self segmentsOfAll: { { 0 @ 0. 64 @ 0. 64 @ 64. 0 @ 64 } })
		              fillRule: #winding
		              clip: (VGClip bounds: (10 @ 20 corner: 14 @ 23)).
	rows := OrderedCollection new.
	rasteriser coverageRowsDo: [ :y :coverage :left |
		rows add: y.
		self assert: left equals: 10.
		self assert: coverage size equals: 4 ].
	self assert: rows asArray equals: #( 20 21 22 )
]

{ #category : 'tests - coverage' }
VGRasteriserTest >> testTheCoverageOfACircleSumsToItsArea [
	| grid total expected |
	grid := self coverageOf: (self circleOfRadius: 20 center: 32 @ 32) rule: #winding.
	total := grid values inject: 0 into: [ :sum :each | sum + each ].
	expected := Float pi * 20 * 20.
	self assert: (total - expected) abs / expected < 0.01
]

{ #category : 'tests' }
VGRasteriserTest >> testTheHoleOfANestedSquareIsEnclosedUnderWindingAndNotUnderEvenOdd [
	"The question is asked under the fill rule the shape carries, and not of its outline: the
	 middle of two nested squares wound the same way is solid under the winding rule and hollow
	 under the even-odd rule, which is what the coverage of that very pixel says above."

	| coordinates winding evenOdd hole |
	coordinates := self segmentsOfAll: {
			               { 8 @ 8. 40 @ 8. 40 @ 40. 8 @ 40 }.
			               { 16 @ 16. 32 @ 16. 32 @ 32. 16 @ 32 } }.
	winding := VGSegments coordinates: coordinates fillRule: #winding.
	evenOdd := VGSegments coordinates: coordinates fillRule: #evenOdd.
	hole := 20 @ 20 corner: 28 @ 28.
	self assert: (winding enclosesWholly: hole).
	self deny: (evenOdd enclosesWholly: hole)
]

{ #category : 'tests - fill rules' }
VGRasteriserTest >> testTheWindingRuleFillsANestedSquareAndTheEvenOddRuleLeavesItHollow [
	| outer inner winding evenOdd |
	outer := { 8 @ 8. 40 @ 8. 40 @ 40. 8 @ 40 }.
	inner := { 16 @ 16. 32 @ 16. 32 @ 32. 16 @ 32 }.
	winding := self coverageOfAll: { outer. inner } rule: #winding.
	evenOdd := self coverageOfAll: { outer. inner } rule: #evenOdd.
	self assert: (winding at: 24 @ 24) equals: 1.
	self assert: (evenOdd at: 24 @ 24 ifAbsent: [ 0 ]) equals: 0.
	self assert: (winding at: 12 @ 24) equals: 1.
	self assert: (evenOdd at: 12 @ 24) equals: 1
]
