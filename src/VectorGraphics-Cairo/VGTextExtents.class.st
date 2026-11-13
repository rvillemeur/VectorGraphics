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

{ #category : 'inspector' }
VGTextExtents >> drawGeometryOn: aForm placing: aBlock [
	"The baseline across the image, the origin of the first glyph as a black tick, the inked box
	 in blue, and the advance to where the next run starts as a red line under the baseline."

	| origin advanceEnd |
	origin := aBlock value: 0 @ 0.
	advanceEnd := aBlock value: self advance.
	aForm
		fill: (0 @ origin y extent: aForm width @ 1)
		fillColor: Color lightGray.
	self
		outline:
			((aBlock value: self inkedBox origin) corner:
				 (aBlock value: self inkedBox corner))
		on: aForm
		color: Color blue.
	aForm
		fill: (origin x @ (origin y - 4) extent: 1 @ 9)
		fillColor: Color black.
	aForm
		fill: (origin x @ (origin y + 4) corner: advanceEnd x + 1 @ (origin y + 5))
		fillColor: Color red.
	aForm
		fill: (advanceEnd x @ (origin y + 1) extent: 1 @ 7)
		fillColor: Color red
]

{ #category : 'accessing' }
VGTextExtents >> extent [
	^ self width @ self height
]

{ #category : 'inspector' }
VGTextExtents >> geometryForm [
	"A picture of what my six numbers mean, drawn on a white image of a fixed size: the placer
	 scales whatever I hold into it, and the drawing puts down the baseline, the origin, the
	 inked box and the advance."

	| form |
	form := Form extent: 240 @ 140 depth: 32.
	form fillColor: Color white.
	self drawGeometryOn: form placing: (self geometryPlacerInto: form extent).
	^ form
]

{ #category : 'inspector' }
VGTextExtents >> geometryPlacerInto: anExtent [
	"A block that maps a point of my own space into an image of that extent: everything I hold,
	 scaled to fit inside a margin, so a run of any size reads the same way. Text coordinates
	 grow downwards, as a form's do, so nothing is flipped."

	| content margin scale |
	content := Rectangle encompassing: {
			           0 @ 0.
			           self advance.
			           self inkedBox origin.
			           self inkedBox corner }.
	margin := 10 @ 15.
	scale := (anExtent x - (2 * margin x) / (content width max: 1)
		          min: anExtent y - (2 * margin y) / (content height max: 1))
		         asFloat.
	^ [ :point | (point - content origin * scale + margin) rounded ]
]

{ #category : 'accessing' }
VGTextExtents >> height [
	^ height
]

{ #category : 'accessing' }
VGTextExtents >> height: aNumber [
	height := aNumber
]

{ #category : 'accessing' }
VGTextExtents >> inkedBox [
	"The box my glyphs ink, placed against the origin of the first one: my bearing is where it
	 starts and my extent is how big it is."

	^ self bearing extent: self extent
]

{ #category : 'inspector' }
VGTextExtents >> inspectorGeometry: aBuilder [
	<inspectorPresentationOrder: 20 title: 'Geometry'>
	"Six numbers say nothing on their own: the picture places the inked box against the baseline
	 and the origin, and draws the advance to where the next run would start. An empty run has
	 no picture, and says so: the gate hides the tab, and a reader who reaches the view anyway
	 reads the sentence."

	self isEmpty ifTrue: [
		^ aBuilder newText
			  text: 'This run inks nothing and advances nowhere';
			  beNotEditable;
			  yourself ].
	^ aBuilder newImage
		  image: self geometryForm;
		  yourself
]

{ #category : 'inspector' }
VGTextExtents >> inspectorGeometryContext: aContext [
	"Nothing to draw for an empty run, so the tab stays shut on one."

	aContext active: self isEmpty not
]

{ #category : 'testing' }
VGTextExtents >> isEmpty [
	"A run that inks nothing and advances nowhere: all six numbers zero, which is what Cairo
	 answers for an empty run and what we answer for one made only of glyphs with no outline."

	^ self extent isZero and: [ self advance isZero ]
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
