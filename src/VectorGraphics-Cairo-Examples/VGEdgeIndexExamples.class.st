"
I hold the one-click examples for the edge index, the row bands a span scanner reads its edges
through when it is asked whether a shape encloses a rectangle wholly.
My examples rebuild their object on every call and assert nothing.
The Bands tab asks the index itself what each band holds and what it answers, so a band that holds
an edge it does not reach, or answers a winding of its own, shows there.
"
Class {
	#name : 'VGEdgeIndexExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Cairo-Examples-Examples',
	#package : 'VectorGraphics-Cairo-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGEdgeIndexExamples class >> indexOfAShapeOfOneRow [
	<sampleInstance>
	"The degenerate shape: a path that goes out along one row and back, so its box has no height
	 at all. The index is one band, which is why the band of a row is answered without dividing by
	 the height of a band."

	| builder scanner |
	builder := VGPathBuilder new.
	builder
		moveTo: 8 @ 20;
		lineTo: 40 @ 20;
		closePath.
	scanner := VGSpanScanner of: (builder path segmentsWithFillRule: #winding).
	^ VGEdgeIndex coordinates: scanner segments bounds: scanner exactBoundingBox
]

{ #category : 'examples' }
VGEdgeIndexExamples class >> indexOfAStar [
	<sampleInstance>
	"The edges of a self-crossing shape indexed by row band. A star of ten edges is cut into two
	 bands, so a band holds the edges whose own rows reach it and nothing else, and the winding at
	 a point is counted from one band rather than from every edge of the shape."

	| builder centre scanner |
	builder := VGPathBuilder new.
	centre := 32 @ 32.
	builder moveTo: centre + (0 @ -26).
	1 to: 9 do: [ :index |
		| angle radius |
		angle := index * Float pi / 5.0.
		radius := index odd
			          ifTrue: [ 11 ]
			          ifFalse: [ 26 ].
		builder lineTo: centre + (angle sin * radius @ (angle cos * radius) negated) ].
	builder closePath.
	scanner := VGSpanScanner of: (builder path segmentsWithFillRule: #evenOdd).
	^ VGEdgeIndex coordinates: scanner segments bounds: scanner exactBoundingBox
]
