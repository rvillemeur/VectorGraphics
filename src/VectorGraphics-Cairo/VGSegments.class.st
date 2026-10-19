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
		'fillRule'
	],
	#category : 'VectorGraphics-Cairo-Path',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Path'
}

{ #category : 'instance creation' }
VGSegments class >> coordinates: anArray fillRule: aSymbol [
	^ self new setCoordinates: anArray fillRule: aSymbol
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

{ #category : 'geometry' }
VGSegments >> boundingBox [
	"The whole-pixel device rectangle my edges live in, or nil when I hold none."
	| left top right bottom |
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
	^ left floor @ top floor corner: right ceiling @ bottom ceiling
]

{ #category : 'accessing' }
VGSegments >> coordinates [
	^ coordinates
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

{ #category : 'initialization' }
VGSegments >> setCoordinates: anArray fillRule: aSymbol [
	coordinates := anArray.
	fillRule := aSymbol
]

{ #category : 'accessing' }
VGSegments >> size [
	"How many edges I hold."
	^ coordinates size // 4
]
