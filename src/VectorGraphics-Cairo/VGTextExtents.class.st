"
I am the geometry of one run of glyphs, in user space: the inked box, where that box sits relative to the origin of the run, and how far the origin moves afterwards. I am the record Cairo fills in cairo_text_extents, and I answer the selectors Alexandrie's AeCairoTextExtents answers, so a caller cannot tell us apart.

`bearingY` is negative for text that sits above its baseline, because y grows downwards in user space while a font's own coordinates grow upwards.
"
Class {
	#name : 'VGTextExtents',
	#superclass : 'Object',
	#instVars : [
		'bearingX',
		'bearingY',
		'width',
		'height',
		'advanceX',
		'advanceY'
	],
	#category : 'VectorGraphics-Cairo-Text',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Text'
}

{ #category : 'accessing' }
VGTextExtents >> advance [
	^ self advanceX @ self advanceY
]

{ #category : 'accessing' }
VGTextExtents >> advanceX [
	^ advanceX
]

{ #category : 'accessing' }
VGTextExtents >> advanceX: aNumber [
	advanceX := aNumber
]

{ #category : 'accessing' }
VGTextExtents >> advanceY [
	^ advanceY
]

{ #category : 'accessing' }
VGTextExtents >> advanceY: aNumber [
	advanceY := aNumber
]

{ #category : 'accessing' }
VGTextExtents >> bearing [
	^ self bearingX @ self bearingY
]

{ #category : 'accessing' }
VGTextExtents >> bearingX [
	^ bearingX
]

{ #category : 'accessing' }
VGTextExtents >> bearingX: aNumber [
	bearingX := aNumber
]

{ #category : 'accessing' }
VGTextExtents >> bearingY [
	^ bearingY
]

{ #category : 'accessing' }
VGTextExtents >> bearingY: aNumber [
	bearingY := aNumber
]

{ #category : 'accessing' }
VGTextExtents >> extent [
	^ self width @ self height
]

{ #category : 'accessing' }
VGTextExtents >> height [
	^ height
]

{ #category : 'accessing' }
VGTextExtents >> height: aNumber [
	height := aNumber
]

{ #category : 'printing' }
VGTextExtents >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPutAll: '(extent: ';
		print: self extent;
		nextPutAll: ' bearing: ';
		print: self bearing;
		nextPutAll: ' advance: ';
		print: self advance;
		nextPut: $)
]

{ #category : 'accessing' }
VGTextExtents >> width [
	^ width
]

{ #category : 'accessing' }
VGTextExtents >> width: aNumber [
	width := aNumber
]
