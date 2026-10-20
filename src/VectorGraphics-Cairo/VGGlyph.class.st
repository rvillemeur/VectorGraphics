"
I am one glyph placed at one point: the index of a glyph in its font face, and the user space position of its origin. I am the record Cairo calls a cairo_glyph_t, and I answer the selectors Alexandrie's AeCairoGlyph answers, so a caller cannot tell us apart.

I carry no font. The scaled font that laid me out knows which face my index belongs to, and a drawing verb is given both.
"
Class {
	#name : 'VGGlyph',
	#superclass : 'Object',
	#instVars : [
		'index',
		'x',
		'y'
	],
	#category : 'VectorGraphics-Cairo-Text',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Text'
}

{ #category : 'instance creation' }
VGGlyph class >> index: anInteger x: aNumber y: anotherNumber [
	^ self new
		  index: anInteger;
		  x: aNumber;
		  y: anotherNumber;
		  yourself
]

{ #category : 'accessing' }
VGGlyph >> index [
	^ index
]

{ #category : 'accessing' }
VGGlyph >> index: aValue [
	index := aValue
]

{ #category : 'accessing' }
VGGlyph >> position [
	^ x @ y
]

{ #category : 'printing' }
VGGlyph >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPutAll: '(index: ';
		print: index;
		nextPutAll: ' at: ';
		print: self position;
		nextPut: $)
]

{ #category : 'accessing' }
VGGlyph >> x [
	^ x
]

{ #category : 'accessing' }
VGGlyph >> x: aValue [
	x := aValue
]

{ #category : 'accessing' }
VGGlyph >> y [
	^ y
]

{ #category : 'accessing' }
VGGlyph >> y: aValue [
	y := aValue
]
