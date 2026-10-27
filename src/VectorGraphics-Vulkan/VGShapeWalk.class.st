"
One shape of a recorded frame, walked the way a kernel invocation can afford to walk it: no sorted
array of crossings and no scratch buffer, one scan of the edges for the winding at a point and one
more for the next crossing to the right of it.
A fill is one of these and every shape of its clip is another, and VGTileCoverage meets their spans
to find what a pixel is covered by.
The fill rule and the antialiasing mode ride inside the VGSpanScanner I hold, which is the oracle:
windingUpTo:onSubRow: counts the crossings VGSpanScanner would have sorted, term for term, so the
two answer the same float for the same edge.
"
Class {
	#name : 'VGShapeWalk',
	#superclass : 'Object',
	#instVars : [
		'scanner'
	],
	#category : 'VectorGraphics-Vulkan-Tiles',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Tiles'
}

{ #category : 'instance creation' }
VGShapeWalk class >> of: aSpanScanner [
	"The walk of one shape. A clip holds its shapes as scanners already, and a fill carries its
	 own rule and mode inside its segments, so nothing else is needed here."

	^ self new setScanner: aSpanScanner
]

{ #category : 'walking' }
VGShapeWalk >> crossingAfter: anX onSubRow: aSubRow [
	"The nearest crossing strictly right of anX, or nil where my edges have none. One scan of the
	 edges, which is what a run costs here instead of a sorted array of every crossing."

	| coordinates nearest |
	coordinates := scanner segments.
	nearest := nil.
	1 to: coordinates size by: 4 do: [ :index |
		| crossing |
		crossing := self crossingOfEdgeAt: index onSubRow: aSubRow.
		(crossing notNil and: [
			 crossing > anX and: [ nearest isNil or: [ crossing < nearest ] ] ]) ifTrue: [
			nearest := crossing ] ].
	^ nearest
]

{ #category : 'walking' }
VGShapeWalk >> crossingOfEdgeAt: anIndex onSubRow: aSubRow [
	"Where the edge stored at anIndex crosses that sub-row, or nil where it does not reach it. The
	 edge is taken half open from its upper end, and the expression is VGSpanScanner's term for
	 term, so the two classes answer the same float for the same edge."

	| coordinates y0 y1 x0 x1 |
	coordinates := scanner segments.
	y0 := coordinates at: anIndex + 1.
	y1 := coordinates at: anIndex + 3.
	y0 = y1 ifTrue: [ ^ nil ].
	(aSubRow >= (y0 min: y1) and: [ aSubRow < (y0 max: y1) ]) ifFalse: [ ^ nil ].
	x0 := coordinates at: anIndex.
	x1 := coordinates at: anIndex + 2.
	^ x0 + ((x1 - x0) * (aSubRow - y0) / (y1 - y0))
]

{ #category : 'walking' }
VGShapeWalk >> directionOfEdgeAt: anIndex [
	"Down the page is one and up the page is minus one, as VGSpanScanner counts it."

	| coordinates |
	coordinates := scanner segments.
	^ (coordinates at: anIndex + 3) > (coordinates at: anIndex + 1)
		  ifTrue: [ 1 ]
		  ifFalse: [ -1 ]
]

{ #category : 'testing' }
VGShapeWalk >> isAliased [
	"Antialiasing off, which makes me answer whole pixels and the same ones on every sub-row of a
	 row, so VGTileCoverage asks me about the centre of a pixel instead of sweeping me."

	^ scanner isAliased
]

{ #category : 'walking' }
VGShapeWalk >> isInsideAt: anX onSubRow: aSubRow [
	"Whether the point just right of anX on that sub-row is inside me, by my own fill rule."

	^ scanner isInside: (self windingUpTo: anX onSubRow: aSubRow)
]

{ #category : 'walking' }
VGShapeWalk >> isPixelCentreInsideAtX: anX onSubRow: aSubRow [
	"Whether the centre of that pixel is inside me, sampled at the centre of its own pixel row.
	 Antialiasing off means a pixel is inside when its own centre is, so an aliased shape answers
	 whole pixels and answers the same ones on every sub-row of a row."

	^ self isInsideAt: anX + 0.5 onSubRow: aSubRow floor + 0.5
]

{ #category : 'printing' }
VGShapeWalk >> printOn: aStream [

	aStream
		nextPutAll: self class name;
		nextPut: $(;
		print: self size;
		nextPutAll: ' edges, ';
		nextPutAll: scanner fillRule;
		nextPut: $)
]

{ #category : 'accessing' }
VGShapeWalk >> scanner [

	^ scanner
]

{ #category : 'initialization' }
VGShapeWalk >> setScanner: aSpanScanner [

	scanner := aSpanScanner
]

{ #category : 'accessing' }
VGShapeWalk >> size [
	"How many edges I walk."

	^ scanner size
]

{ #category : 'walking' }
VGShapeWalk >> windingOnSubRow: aSubRow crossing: aBlock [
	"What the crossings aBlock accepts contribute to the winding. The even-odd rule counts a
	 crossing and the winding rule counts the direction the edge runs in, which is what
	 VGSpanScanner does as it walks its sorted crossings. The kernel inlines this scan at each of
	 its call sites, because it has no blocks."

	| coordinates winding evenOdd |
	coordinates := scanner segments.
	evenOdd := scanner fillRule == #evenOdd.
	winding := 0.
	1 to: coordinates size by: 4 do: [ :index |
		| crossing |
		crossing := self crossingOfEdgeAt: index onSubRow: aSubRow.
		(crossing notNil and: [ aBlock value: crossing ]) ifTrue: [
			winding := winding
			           + (evenOdd
					            ifTrue: [ 1 ]
					            ifFalse: [ self directionOfEdgeAt: index ]) ] ].
	^ winding
]

{ #category : 'walking' }
VGShapeWalk >> windingUpTo: anX onSubRow: aSubRow [
	"The winding number just right of anX, in one scan of the edges. A crossing exactly at anX
	 counts: a run that starts there is inside from there, and a run that ends there has ended."

	^ self windingOnSubRow: aSubRow crossing: [ :x | x <= anX ]
]
