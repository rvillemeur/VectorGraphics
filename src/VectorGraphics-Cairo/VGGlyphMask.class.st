"
I am one glyph already rasterised: a small surface whose alpha channel is the coverage of the glyph, and the whole pixel offset from the glyph's origin to my top left corner.

A context blits me with the paint in force, which lays the paint down through my alpha. That is the same arithmetic the rasteriser does for a filled path, so the two routes draw the same pixels.

My surface is never drawn for its colours. It is opaque white everywhere the glyph inks, so that the alpha a mask is read for is the coverage and nothing else.
"
Class {
	#name : 'VGGlyphMask',
	#superclass : 'Object',
	#instVars : [
		'surface',
		'offset'
	],
	#category : 'VectorGraphics-Cairo-Text',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Text'
}

{ #category : 'instance creation' }
VGGlyphMask class >> surface: aSurface offset: aPoint [
	^ self new
		  setSurface: aSurface offset: aPoint;
		  yourself
]

{ #category : 'accessing' }
VGGlyphMask >> extent [
	^ surface extent
]

{ #category : 'inspector' }
VGGlyphMask >> inspectorPicture: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Picture'>
	"The rasterised glyph itself. #asForm answers a fresh Form every call, so showing the mask
	 cannot change it."

	^ aBuilder newImage
		  image: self surface asForm;
		  yourself
]

{ #category : 'inspector' }
VGGlyphMask >> inspectorPictureContext: aContext [
	aContext active: self surface notNil
]

{ #category : 'inspector' }
VGGlyphMask >> inspectorPlacement: aBuilder [
	<inspectorPresentationOrder: 11 title: 'Placement'>
	"Where a draw puts me: the offset is added to the whole pixel the glyph origin falls on, so it
	 is negative above the baseline. The sub-pixel part of that origin is already baked into my
	 coverage, which is why one mask serves only one phase."

	^ aBuilder newTable
		  items: {
				  ('Extent' -> self extent).
				  ('Offset from the glyph origin' -> self offset).
				  ('Surface format' -> self surface format) };
		  addColumn: (SpStringTableColumn title: 'Property' evaluated: [ :each | each key ]);
		  addColumn: (SpStringTableColumn
				   title: 'Value'
				   evaluated: [ :each | each value printString ]);
		  yourself
]

{ #category : 'inspector' }
VGGlyphMask >> inspectorPlacementContext: aContext [
	aContext active: self surface notNil
]

{ #category : 'accessing' }
VGGlyphMask >> offset [
	^ offset
]

{ #category : 'printing' }
VGGlyphMask >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPutAll: '(';
		print: surface extent;
		nextPutAll: ' at ';
		print: offset;
		nextPut: $)
]

{ #category : 'initialization' }
VGGlyphMask >> setSurface: aSurface offset: aPoint [
	surface := aSurface.
	offset := aPoint
]

{ #category : 'accessing' }
VGGlyphMask >> surface [
	^ surface
]
