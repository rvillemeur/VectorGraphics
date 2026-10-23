"
I am the edges of an area to be filled, and the rule that says which side is inside.

I am what crosses the backend boundary: a flat array of x0, y0, x1, y1 quadruples in device space
and a fill rule, either #winding or #evenOdd. The fill rule travels with the edges rather than as a
fourth argument because the boundary's three messages are frozen, and because an edge array without
its rule does not describe an area.
I say nothing about paths, curves, strokes or text: a stroke reaches a backend as the edges of its
outline, and so does a glyph.
"
Class {
	#name : 'VGSegments',
	#superclass : 'Object',
	#instVars : [
		'coordinates',
		'fillRule',
		'antialias',
		'alpha',
		'exactBounds',
		'spanScanner'
	],
	#category : 'VectorGraphics-Cairo-Path',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Path'
}

{ #category : 'instance creation' }
VGSegments class >> coordinates: anArray fillRule: aSymbol [
	^ self
		  coordinates: anArray
		  fillRule: aSymbol
		  antialias: VGCairoState antialiasNames first
]

{ #category : 'instance creation' }
VGSegments class >> coordinates: anArray fillRule: aSymbol antialias: anotherSymbol [
	^ self new
		  setCoordinates: anArray
		  fillRule: aSymbol
		  antialias: anotherSymbol
]

{ #category : 'instance creation' }
VGSegments class >> empty [
	^ self coordinates: #() fillRule: #winding
]

{ #category : 'instance creation' }
VGSegments class >> rectangle: aRectangle [
	"The four edges of aRectangle, closed and wound one way, which is what a paint of the whole
	 clip is: Cairo's cairo_paint fills the clip extents and nothing else."

	| left right top bottom |
	left := aRectangle left asFloat.
	right := aRectangle right asFloat.
	top := aRectangle top asFloat.
	bottom := aRectangle bottom asFloat.
	^ self
		  coordinates: {
				  left. top. right. top.
				  right. top. right. bottom.
				  right. bottom. left. bottom.
				  left. bottom. left. top }
		  fillRule: #winding
]

{ #category : 'accessing' }
VGSegments >> alpha [
	"The constant alpha the fill is drawn through, one for an ordinary fill. It rides here, next
	 to the fill rule and the antialiasing mode, because the backend's fill message carries the
	 segments, the paint, the clip and the operator and nothing else."
	^ alpha
]

{ #category : 'private' }
VGSegments >> anEdgeMeets: aRectangle [
	"Whether any of my edges touches that closed rectangle. The two axes of the rectangle answer
	 most edges on their own, so they are asked first, and the line of the edge only for what is
	 left. Nothing is allocated here, because a binning asks this of one entry once a tile."

	| left right top bottom |
	left := aRectangle left.
	right := aRectangle right.
	top := aRectangle top.
	bottom := aRectangle bottom.
	1 to: coordinates size by: 4 do: [ :index |
		| x0 y0 x1 y1 |
		x0 := coordinates at: index.
		y0 := coordinates at: index + 1.
		x1 := coordinates at: index + 2.
		y1 := coordinates at: index + 3.
		((x0 max: x1) < left or: [ (x0 min: x1) > right ]) ifFalse: [
			((y0 max: y1) < top or: [ (y0 min: y1) > bottom ]) ifFalse: [
				(self edgeAt: index hasEveryCornerOnOneSideOf: aRectangle)
					ifFalse: [ ^ true ] ] ] ].
	^ false
]

{ #category : 'accessing' }
VGSegments >> antialias [
	"The antialiasing mode the fill I describe is sampled with. The backend answers three frozen
	 messages and none of them carries a mode, so the mode rides here, as the fill rule does."

	^ antialias
]

{ #category : 'testing' }
VGSegments >> asDeviceRectangle [
	"The device-space rectangle my edges are, or nil when they are anything else. Four edges, each
	 one horizontal or vertical, whose corners are the four corners of my bounding box: that is
	 the clip a Bloc element with a rectangular geometry builds, and a clip of one needs no scan
	 conversion at all."

	| box corners |
	self size = 4 ifFalse: [ ^ nil ].
	box := self exactBoundingBox.
	corners := box corners asSet.
	1 to: coordinates size by: 4 do: [ :index |
		| from to |
		from := (coordinates at: index) @ (coordinates at: index + 1).
		to := (coordinates at: index + 2) @ (coordinates at: index + 3).
		(from x = to x or: [ from y = to y ]) ifFalse: [ ^ nil ].
		((corners includes: from) and: [ corners includes: to ]) ifFalse: [ ^ nil ] ].
	^ box
]

{ #category : 'accessing' }
VGSegments >> boundingBox [
	"The whole-pixel device rectangle my edges live in, or nil when I hold none."

	| exact |
	exact := self exactBoundingBox.
	exact ifNil: [ ^ nil ].
	^ exact left floor @ exact top floor
	  corner: exact right ceiling @ exact bottom ceiling
]

{ #category : 'accessing' }
VGSegments >> coordinates [
	^ coordinates
]

{ #category : 'drawing' }
VGSegments >> drawOn: aBackend paint: aPaint clip: aClip operator: anOperator into: aTarget [
	"A recorded command names what it is by answering this: I am the shape of a fill, so the
	 backend rasterises me."
	aBackend
		rasterise: self
		paint: aPaint
		clip: aClip
		operator: anOperator
		into: aTarget
]

{ #category : 'private' }
VGSegments >> edgeAt: anIndex hasEveryCornerOnOneSideOf: aRectangle [
	"Whether every corner of the rectangle lies strictly on one side of the line the edge at that
	 coordinate runs along. The edge then cannot touch the rectangle, whatever the two axes of
	 the rectangle say, and those three tests together are exact for a segment against a
	 rectangle. An edge of no length puts every corner at distance nought on its own line and so
	 answers false, which is the conservative way round."

	| x0 y0 normalX normalY at topLeft topRight bottomRight bottomLeft |
	x0 := coordinates at: anIndex.
	y0 := coordinates at: anIndex + 1.
	normalX := (coordinates at: anIndex + 3) - y0.
	normalY := x0 - (coordinates at: anIndex + 2).
	at := normalX * x0 + (normalY * y0).
	topLeft := normalX * aRectangle left + (normalY * aRectangle top) - at.
	topRight := normalX * aRectangle right + (normalY * aRectangle top) - at.
	bottomRight := normalX * aRectangle right
	               + (normalY * aRectangle bottom) - at.
	bottomLeft := normalX * aRectangle left
	              + (normalY * aRectangle bottom) - at.
	(topLeft > 0 and: [
		 topRight > 0 and: [ bottomRight > 0 and: [ bottomLeft > 0 ] ] ])
		ifTrue: [ ^ true ].
	^ topLeft < 0 and: [
		  topRight < 0 and: [ bottomRight < 0 and: [ bottomLeft < 0 ] ] ]
]

{ #category : 'testing' }
VGSegments >> enclosesWholly: aRectangle [
	"Whether every point of that rectangle, its boundary included, is inside me under my own
	 fill rule. A tiled rasteriser asks this of a tile before it walks it, because the coverage
	 of every pixel of a rectangle I enclose is one and the walk has nothing to find there.
	 The answer is conservative, since a yes paints whole a pixel the walk would have painted in
	 part: an edge that so much as touches the rectangle answers no, and that leaves one point to
	 ask of the fill rule, the centre."

	| box |
	box := self exactBoundingBox.
	box ifNil: [ ^ false ].
	(box containsRect: aRectangle) ifFalse: [ ^ false ].
	(self anEdgeMeets: aRectangle) ifTrue: [ ^ false ].
	^ self isInsideAt: aRectangle center
]

{ #category : 'accessing' }
VGSegments >> exactBoundingBox [
	"The device rectangle my edges live in, fractions kept, or nil when I hold none. A clip needs
	 the fraction: it is what pays for half of the pixel its edge runs through.
	 The answer is remembered, because a binning asks it of one entry once a tile and my
	 coordinates never change after I am built."

	| left top right bottom |
	exactBounds ifNotNil: [ ^ exactBounds ].
	self isEmpty ifTrue: [ ^ nil ].
	left := Float infinity.
	top := Float infinity.
	right := Float infinity negated.
	bottom := Float infinity negated.
	1 to: coordinates size by: 2 do: [ :index |
		| x y |
		x := coordinates at: index.
		y := coordinates at: index + 1.
		left := left min: x.
		right := right max: x.
		top := top min: y.
		bottom := bottom max: y ].
	^ exactBounds := left @ top corner: right @ bottom
]

{ #category : 'accessing' }
VGSegments >> fillRule [
	^ fillRule
]

{ #category : 'inspector' }
VGSegments >> inspectorEdges: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Edges'>
	"My edges as the backend reads them, four floats at a time, with the direction the winding
	 rule counts. The direction is asked of the rule's own arithmetic: downwards is plus one,
	 upwards is minus one, and a horizontal edge crosses no scan line at all."

	^ aBuilder newTable
		  items: (1 to: self size) asArray;
		  addColumn: (SpStringTableColumn
				   title: 'Edge'
				   evaluated: [ :index | index printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'From'
				   evaluated: [ :index |
					   (coordinates at: index * 4 - 3) printString , ' @ '
					   , (coordinates at: index * 4 - 2) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'To'
				   evaluated: [ :index |
					   (coordinates at: index * 4 - 1) printString , ' @ '
					   , (coordinates at: index * 4) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Winding'
				   evaluated: [ :index |
					   | y0 y1 |
					   y0 := coordinates at: index * 4 - 2.
					   y1 := coordinates at: index * 4.
					   y0 = y1
						   ifTrue: [ 'none' ]
						   ifFalse: [ (y1 > y0 ifTrue: [ 1 ] ifFalse: [ -1 ]) printString ] ]);
		  yourself
]

{ #category : 'inspector' }
VGSegments >> inspectorEdgesContext: aContext [
	aContext active: coordinates notNil
]

{ #category : 'testing' }
VGSegments >> isAliased [
	"Only Cairo's #none mode changes what the rasteriser does; the other six ask for antialiasing
	 of one quality or another and we sample them all the same way."

	^ antialias == #none
]

{ #category : 'accessing' }
VGSegments >> isEmpty [
	^ coordinates isEmpty
]

{ #category : 'private' }
VGSegments >> isInsideAt: aPoint [
	"Whether that point is inside me under my own fill rule. The winding is one pass over my
	 coordinates, counting the edges that cross the point's row at or to the left of it, and the
	 rule itself is asked of the scanner rather than restated. Nothing is allocated here, because
	 a binning asks this of one entry once a tile."

	| x y winding |
	x := aPoint x.
	y := aPoint y.
	winding := 0.
	1 to: coordinates size by: 4 do: [ :index |
		| y0 y1 |
		y0 := coordinates at: index + 1.
		y1 := coordinates at: index + 3.
		(y0 ~= y1 and: [
			 y >= (y0 min: y1) and: [ y < (y0 max: y1) ] ]) ifTrue: [
			| x0 x1 |
			x0 := coordinates at: index.
			x1 := coordinates at: index + 2.
			x0 + ((x1 - x0) * (y - y0) / (y1 - y0)) <= x ifTrue: [
				winding := winding + (y1 > y0
					            ifTrue: [ 1 ]
					            ifFalse: [ -1 ]) ] ] ].
	^ self scanner isInside: winding
]

{ #category : 'accessing' }
VGSegments >> notEmpty [
	^ coordinates notEmpty
]

{ #category : 'printing' }
VGSegments >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPutAll: '(';
		print: self size;
		nextPutAll: ' edges, ';
		nextPutAll: fillRule;
		nextPut: $)
]

{ #category : 'accessing' }
VGSegments >> scanner [
	"The span scanner of my own edges, remembered: a binning asks the fill rule of one entry once
	 a tile, and a scanner of mine holds nothing that changes."

	^ spanScanner ifNil: [ spanScanner := VGSpanScanner of: self ]
]

{ #category : 'private' }
VGSegments >> setAlpha: aNumber [
	alpha := aNumber asFloat
]

{ #category : 'private' }
VGSegments >> setCoordinates: anArray fillRule: aSymbol antialias: anotherSymbol [
	coordinates := anArray.
	fillRule := aSymbol.
	antialias := anotherSymbol.
	alpha := 1.0
]

{ #category : 'accessing' }
VGSegments >> size [
	"How many edges I hold."
	^ coordinates size // 4
]

{ #category : 'copying' }
VGSegments >> withAlpha: aNumber [
	"A copy of these segments drawn through aNumber, which Cairo rasterises as a mask of one
	 constant byte. A copy and not a mutation: a display list entry may hold the original
	 already, and the entries are replayed as recorded."
	| faded |
	faded := self copy.
	faded setAlpha: aNumber.
	^ faded
]
