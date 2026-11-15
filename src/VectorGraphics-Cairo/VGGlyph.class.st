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

{ #category : 'accessing' }
VGGlyph class >> glyphsOf: aGlyphArray size: aNumberOfGlyphs [
	"The first aNumberOfGlyphs glyphs of an array, as a collection a caller can walk. Alexandrie
	 hands over an opaque external array that answers its size and nothing else; the indexable
	 structure behind it comes from #asExternalStructure, and asking for that selector rather
	 than for a class name is what keeps this package free of Alexandrie's names. The glyphs
	 answered are whatever the array holds, Alexandrie's or ours, and both answer index, x
	 and y."
	| indexable |
	indexable := (aGlyphArray respondsTo: #asExternalStructure)
		             ifTrue: [ aGlyphArray asExternalStructure ]
		             ifFalse: [ aGlyphArray ].
	^ (1 to: aNumberOfGlyphs) collect: [ :index | indexable at: index ]
]

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
