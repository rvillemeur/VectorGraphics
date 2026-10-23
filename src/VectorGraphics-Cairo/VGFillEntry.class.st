"
I am a recorded fill: a set of edges to be filled with a paint under a clip and an operator.

My edges are a flat array of x0, y0, x1, y1 quadruples in device space, already flattened and
already transformed, because that is all the backend boundary is allowed to know. A stroke reaches
me as well, as the edges of its outline, and so does the paint verb, as the edges of the clip
rectangle.
"
Class {
	#name : 'VGFillEntry',
	#superclass : 'VGDisplayListEntry',
	#instVars : [
		'segments'
	],
	#category : 'VectorGraphics-Cairo-Display list',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Display list'
}

{ #category : 'instance creation' }
VGFillEntry class >> segments: aSegments paint: aPaint clip: aRectangle operator: aSymbol [
	^ (self new setPaint: aPaint clip: aRectangle operator: aSymbol)
		  setSegments: aSegments;
		  yourself
]

{ #category : 'draining' }
VGFillEntry >> boundingBox [
	"What I can touch: where my edges are, cut down to my clip. The clip answers the narrowed
	 rectangle itself, because a clip that does not meet the edges has to read as plainly empty.
	 Under an unbounded operator it is the whole clip instead, as it is for a blit: in, out,
	 dest-in and dest-atop take the destination away where my shape covers nothing, so the pixels
	 they write reach to the edge of the clip and not to the edge of my edges."

	| box |
	operator isUnbounded ifTrue: [ ^ clip boundsNarrowedTo: clip extents ].
	box := segments boundingBox.
	^ box ifNotNil: [ clip boundsNarrowedTo: box ]
]

{ #category : 'testing' }
VGFillEntry >> coversEveryPixelOf: aRectangle [
	"Every pixel of that rectangle takes my paint at full coverage when my edges enclose the
	 rectangle and my clip allows the whole of it. A clip cut out by a shape allows a pixel only
	 as far as that shape covers it, so it answers no here however wide its bounds are."

	clip isRectangular ifFalse: [ ^ false ].
	(clip bounds containsRect: aRectangle) ifFalse: [ ^ false ].
	^ segments enclosesWholly: aRectangle
]

{ #category : 'accessing' }
VGFillEntry >> fillRule [
	^ segments fillRule
]

{ #category : 'inspector' }
VGFillEntry >> inspectorFill: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Fill'>
	"What a replay hands the backend. The fill rule is read from the segments, because the rule
	 travels inside them over the backend boundary and not as a fourth argument."

	^ aBuilder newTable
		  items: {
				  ('Edges' -> segments size).
				  ('Fill rule' -> self fillRule).
				  ('Paint' -> paint).
				  ('Clip' -> clip).
				  ('Operator' -> operator).
				  ('Edge bounding box' -> segments boundingBox).
				  ('Bounding box' -> self boundingBox) };
		  addColumn: (SpStringTableColumn
				   title: 'Property'
				   evaluated: [ :each | each key ]);
		  addColumn: (SpStringTableColumn
				   title: 'Value'
				   evaluated: [ :each | each value printString ]);
		  yourself
]

{ #category : 'inspector' }
VGFillEntry >> inspectorFillContext: aContext [
	aContext active: segments notNil
]

{ #category : 'printing' }
VGFillEntry >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPutAll: '(';
		print: segments;
		nextPutAll: ', ';
		print: paint;
		nextPut: $)
]

{ #category : 'draining' }
VGFillEntry >> replayOn: aBackend [
	aBackend
		fillSegments: segments
		paint: paint
		clip: clip
		operator: operator
]

{ #category : 'accessing' }
VGFillEntry >> segments [
	^ segments
]

{ #category : 'initialization' }
VGFillEntry >> setSegments: aSegments [
	segments := aSegments
]
