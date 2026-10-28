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

{ #category : 'testing' }
VGSegments >> enclosesWholly: aRectangle [
	"Whether every point of that rectangle, its boundary included, is inside me under my own
	 fill rule. A tiled rasteriser asks this of a tile before it walks it, and it asks the same
	 of every shape of the clip, which is why the predicate lives on the scanner the clip holds
	 its shapes as."

	^ self scanner enclosesWholly: aRectangle
]

{ #category : 'accessing' }
VGSegments >> exactBoundingBox [
	"The device rectangle my edges live in, fractions kept, or nil when I hold none. The scanner
	 of my own edges answers it, and it is the scanner a clip holds for a shape of its own, so
	 one bounding box serves a fill and a clip shape alike."

	^ self scanner exactBoundingBox
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
