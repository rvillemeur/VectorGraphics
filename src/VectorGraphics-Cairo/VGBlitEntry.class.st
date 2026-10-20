"
I am one recorded mask operation on a display list: a surface whose alpha channel is the mask, the device point its top left corner sits at, and the paint, clip and operator every entry carries.

Cairo's cairo_mask and cairo_mask_surface arrive here. The surface supplies alpha only — its colours are never read — and the paint supplies the colour, which is why the backend's blit message carries both. A mask pattern that is not already a surface is rendered into one by the context before the entry is made, so that the backend is handed pixels in device space and a Vulkan backend can bind the same thing as a texture.

My replay sends blitSurface:at:paint:clip:operator: to the backend. VGFillEntry is my sibling for a fill.
"
Class {
	#name : 'VGBlitEntry',
	#superclass : 'VGDisplayListEntry',
	#instVars : [
		'surface',
		'origin'
	],
	#category : 'VectorGraphics-Cairo-Display list',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Display list'
}

{ #category : 'instance creation' }
VGBlitEntry class >> surface: aSurface at: aPoint paint: aPaint clip: aClip operator: anOperator [
	^ (self new setPaint: aPaint clip: aClip operator: anOperator)
		  setSurface: aSurface origin: aPoint;
		  yourself
]

{ #category : 'draining' }
VGBlitEntry >> boundingBox [
	"What I can touch: my mask's own rectangle cut down to my clip, and the whole clip under an
	 unbounded operator, because those write where the mask covers nothing at all."
	operator isUnbounded ifTrue: [ ^ clip boundsNarrowedTo: clip extents ].
	^ clip boundsNarrowedTo: (origin extent: surface extent)
]

{ #category : 'inspector' }
VGBlitEntry >> inspectorBlit: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Blit'>
	"What a replay hands the backend, and what my own bounding box makes of it: an unbounded
	 operator writes over the whole clip, because it writes where the mask covers nothing, so the
	 box is asked for rather than restated here."
	^ aBuilder newTable
		  items: {
				  ('Mask extent' -> surface extent).
				  ('Origin' -> origin).
				  ('Paint' -> paint).
				  ('Clip' -> clip).
				  ('Operator' -> operator).
				  ('Operator is unbounded' -> operator isUnbounded).
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
VGBlitEntry >> inspectorBlitContext: aContext [
	aContext active: surface notNil
]

{ #category : 'accessing' }
VGBlitEntry >> origin [
	"The device point my mask's top left corner sits at."
	^ origin
]

{ #category : 'printing' }
VGBlitEntry >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPutAll: '(';
		print: surface extent;
		nextPutAll: ' at ';
		print: origin;
		nextPutAll: ', ';
		print: paint;
		nextPut: $)
]

{ #category : 'draining' }
VGBlitEntry >> replayOn: aBackend [
	aBackend
		blitSurface: surface
		at: origin
		paint: paint
		clip: clip
		operator: operator
]

{ #category : 'initialization' }
VGBlitEntry >> setSurface: aSurface origin: aPoint [
	surface := aSurface.
	origin := aPoint
]

{ #category : 'accessing' }
VGBlitEntry >> surface [
	"The surface whose alpha channel is the mask. Its colours are never read."
	^ surface
]
