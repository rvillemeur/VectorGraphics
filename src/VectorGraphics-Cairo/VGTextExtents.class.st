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

{ #category : 'inspector' }
VGTextExtents >> geometryForm [
	"A picture of what my six numbers mean: the baseline, the origin of the first glyph, the
	 inked box placed at my bearing, and the advance to where the next run starts. Everything
	 I hold is scaled into one image, so a run of any size reads the same way. Text coordinates
	 grow downwards, as a form's do, so nothing is flipped."

	| inked content scale form place origin baselineY advanceEnd |
	inked := self bearing extent: self extent.
	content := Rectangle encompassing: {
			           0 @ 0.
			           self advance.
			           inked origin.
			           inked corner }.
	scale := (220 / (content width max: 1) min: 110 / (content height max: 1))
		         asFloat.
	form := Form extent: 240 @ 140 depth: 32.
	form fillColor: Color white.
	place := [ :point | (point - content origin * scale + (10 @ 15)) rounded ].
	origin := place value: 0 @ 0.
	baselineY := origin y.
	advanceEnd := place value: self advance.
	form
		fill: (0 @ baselineY extent: form width @ 1)
		fillColor: Color lightGray.
	self
		outline: ((place value: inked origin) corner: (place value: inked corner))
		on: form
		color: Color blue.
	form
		fill: (origin x @ (baselineY - 4) extent: 1 @ 9)
		fillColor: Color black.
	form
		fill: (origin x @ (baselineY + 4) corner: advanceEnd x + 1 @ (baselineY + 5))
		fillColor: Color red.
	form
		fill: (advanceEnd x @ (baselineY + 1) extent: 1 @ 7)
		fillColor: Color red.
	^ form
]

{ #category : 'accessing' }
VGTextExtents >> height [
	^ height
]

{ #category : 'accessing' }
VGTextExtents >> height: aNumber [
	height := aNumber
]

{ #category : 'inspector' }
VGTextExtents >> inspectorGeometry: aBuilder [
	<inspectorPresentationOrder: 20 title: 'Geometry'>
	"Six numbers say nothing on their own: the picture places the inked box against the baseline
	 and the origin, and draws the advance to where the next run would start. A run that inks
	 nothing and advances nowhere has no picture, and says so."

	(self extent isZero and: [ self advance isZero ]) ifTrue: [
		^ aBuilder newText
			  text: 'This run inks nothing and advances nowhere';
			  beNotEditable;
			  yourself ].
	^ aBuilder newImage
		  image: self geometryForm;
		  yourself
]

{ #category : 'inspector' }
VGTextExtents >> outline: aRectangle on: aForm color: aColor [
	"The four one pixel edges of a box, drawn as rectangles: a form fills rectangles and I need
	 no other drawing to show a box."

	aForm fill: (aRectangle origin extent: aRectangle width @ 1) fillColor: aColor.
	aForm
		fill: (aRectangle left @ (aRectangle bottom - 1) extent: aRectangle width @ 1)
		fillColor: aColor.
	aForm fill: (aRectangle origin extent: 1 @ aRectangle height) fillColor: aColor.
	aForm
		fill: (aRectangle right - 1 @ aRectangle top extent: 1 @ aRectangle height)
		fillColor: aColor
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

{ #category : 'converting' }
VGTextExtents >> writeInto: aTextExtents [
	"Copy my six numbers into the extents record a caller handed over. Cairo's measuring call
	 writes into a record its caller owns and answers nothing, and Alexandrie's canvas keeps one
	 such record and reuses it for every run it measures, so both contexts fill one rather than
	 return one. I name no class: anything that answers the six setters serves."

	aTextExtents
		bearingX: bearingX;
		bearingY: bearingY;
		width: width;
		height: height;
		advanceX: advanceX;
		advanceY: advanceY.
	^ aTextExtents
]
