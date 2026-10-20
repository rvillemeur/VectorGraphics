"
I am the vertical geometry of one scaled font, in user space: the ascent, the descent, the line height, and the widest advance the font holds. I am the record Cairo fills in cairo_font_extents, and I answer the selectors Alexandrie's AeCairoFontExtents answers, so a caller cannot tell us apart.

A line of text is `height` apart from the next one, the baseline sits `ascent` below the top of the line, and `descent` is a positive number of pixels below the baseline.
"
Class {
	#name : 'VGFontExtents',
	#superclass : 'Object',
	#instVars : [
		'ascent',
		'descent',
		'height',
		'maxAdvanceX',
		'maxAdvanceY'
	],
	#category : 'VectorGraphics-Cairo-Text',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Text'
}

{ #category : 'accessing' }
VGFontExtents >> ascent [
	^ ascent
]

{ #category : 'accessing' }
VGFontExtents >> ascent: aNumber [
	ascent := aNumber
]

{ #category : 'accessing' }
VGFontExtents >> descent [
	^ descent
]

{ #category : 'accessing' }
VGFontExtents >> descent: aNumber [
	descent := aNumber
]

{ #category : 'accessing' }
VGFontExtents >> height [
	^ height
]

{ #category : 'accessing' }
VGFontExtents >> height: aNumber [
	height := aNumber
]

{ #category : 'accessing' }
VGFontExtents >> maxAdvance [
	^ self maxAdvanceX @ self maxAdvanceY
]

{ #category : 'accessing' }
VGFontExtents >> maxAdvanceX [
	^ maxAdvanceX
]

{ #category : 'accessing' }
VGFontExtents >> maxAdvanceX: aNumber [
	maxAdvanceX := aNumber
]

{ #category : 'accessing' }
VGFontExtents >> maxAdvanceY [
	^ maxAdvanceY
]

{ #category : 'accessing' }
VGFontExtents >> maxAdvanceY: aNumber [
	maxAdvanceY := aNumber
]

{ #category : 'printing' }
VGFontExtents >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPutAll: '(ascent: ';
		print: ascent;
		nextPutAll: ' descent: ';
		print: descent;
		nextPutAll: ' height: ';
		print: height;
		nextPutAll: ' maxAdvance: ';
		print: self maxAdvance;
		nextPut: $)
]
