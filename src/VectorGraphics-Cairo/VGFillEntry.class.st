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
	"What I can touch: where my edges are, cut down to my clip."
	| box |
	box := segments boundingBox.
	^ box ifNotNil: [ box intersect: clip ]
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
