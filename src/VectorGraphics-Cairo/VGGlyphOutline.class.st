"
I am one glyph as its font draws it: the advance the pen moves by, the box the ink sits in, and the contours of the shape, all in font units.

A contour of mine is an odd-sized array of points: the start point, then a control point and an end point for every quadratic segment, all absolute. A straight edge is a quadratic whose control point is its end point, which is how a TrueType font states it. A contour is closed, so the last end point joins the start point again, and a glyph with no ink, a space, has no contour at all but still has an advance.

Nothing of mine is scaled. VGScaledFont applies the font matrix, and VGFontFace caches me so that a repeated draw parses no glyph twice.
"
Class {
	#name : 'VGGlyphOutline',
	#superclass : 'Object',
	#instVars : [
		'advance',
		'boundsRectangle',
		'contours'
	],
	#category : 'VectorGraphics-Cairo-Text',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Text'
}

{ #category : 'instance creation' }
VGGlyphOutline class >> advance: aNumber boundsRectangle: aRectangle contours: anArray [
	^ self new
		  setAdvance: aNumber boundsRectangle: aRectangle contours: anArray;
		  yourself
]

{ #category : 'accessing' }
VGGlyphOutline >> advance [
	"How far the pen moves after drawing me, in font units."

	^ advance
]

{ #category : 'accessing' }
VGGlyphOutline >> boundsRectangle [
	"The box my ink sits in, in font units. Font coordinates grow upwards, so the smaller y is
	 the one the font calls the top."

	^ boundsRectangle
]

{ #category : 'accessing' }
VGGlyphOutline >> contours [
	"My contours, each an odd-sized array of absolute points: a start point, then a control
	 point and an end point for every quadratic segment."

	^ contours
]

{ #category : 'accessing' }
VGGlyphOutline >> isEmpty [
	"True when I have no ink at all, which is what a space is."

	^ contours isEmpty
]

{ #category : 'printing' }
VGGlyphOutline >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: '(';
		print: contours size;
		nextPutAll: ' contours, advance ';
		print: advance;
		nextPutAll: ')'
]

{ #category : 'accessing' }
VGGlyphOutline >> setAdvance: aNumber boundsRectangle: aRectangle contours: anArray [
	advance := aNumber.
	boundsRectangle := aRectangle.
	contours := anArray
]
