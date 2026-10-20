"
I am one component of a composite glyph: the index of the glyph that draws me, the offset that places me, and the two by two matrix that transforms me. The letter i of a typical font is a composite of two components, a stem and a dot.

My matrix is the identity for almost every component a real font holds, and I keep it as whole numbers in that case, so a point of mine stays a point with whole font coordinates.

I exist because VectorGraphics' own TTGlyfTableParser reads the component records and keeps only the component glyphs: it discards the offsets and the matrices, which would draw every component at the origin of the composite. VGFontFace reads the records itself and builds me.
"
Class {
	#name : 'VGGlyphComponent',
	#superclass : 'Object',
	#instVars : [
		'glyphIndex',
		'offset',
		'xx',
		'xy',
		'yx',
		'yy'
	],
	#category : 'VectorGraphics-Cairo-Text',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Text'
}

{ #category : 'instance creation' }
VGGlyphComponent class >> glyphIndex: anInteger [
	"A component with no transformation of its own, which is what almost every component is."

	^ self new
		  setGlyphIndex: anInteger;
		  yourself
]

{ #category : 'accessing' }
VGGlyphComponent >> glyphIndex [
	^ glyphIndex
]

{ #category : 'initialization' }
VGGlyphComponent >> initialize [
	"A component starts where the composite glyph's own origin is, with the transformation the
	 TrueType record calls identity, because the overwhelming majority of components carry neither
	 an offset nor a transformation."

	super initialize.
	offset := 0 @ 0.
	xx := 1.
	xy := 0.
	yx := 0.
	yy := 1
]

{ #category : 'testing' }
VGGlyphComponent >> isTransformed [
	^ xx ~= 1 or: [ xy ~= 0 or: [ yx ~= 0 or: [ yy ~= 1 ] ] ]
]

{ #category : 'accessing' }
VGGlyphComponent >> offset [
	^ offset
]

{ #category : 'accessing' }
VGGlyphComponent >> offset: aPoint [
	offset := aPoint
]

{ #category : 'printing' }
VGGlyphComponent >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPutAll: '(glyph ';
		print: glyphIndex;
		nextPutAll: ' at ';
		print: offset.
	self isTransformed ifTrue: [
		aStream nextPutAll: ' transformed by '; print: { xx. xy. yx. yy } ].
	aStream nextPut: $)
]

{ #category : 'initialization' }
VGGlyphComponent >> setGlyphIndex: anInteger [

	glyphIndex := anInteger
]

{ #category : 'transforming' }
VGGlyphComponent >> transformedPoint: aPoint [
	"The TrueType composite record transforms a component point by newX = xx * x + yx * y and
	 newY = xy * x + yy * y, and then adds the offset."

	^ xx * aPoint x + (yx * aPoint y) + offset x
	  @ (xy * aPoint x + (yy * aPoint y) + offset y)
]

{ #category : 'accessing' }
VGGlyphComponent >> xx: aNumber xy: anotherNumber yx: aThirdNumber yy: aFourthNumber [
	xx := aNumber.
	xy := anotherNumber.
	yx := aThirdNumber.
	yy := aFourthNumber
]
