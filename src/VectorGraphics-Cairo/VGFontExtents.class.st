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

{ #category : 'inspecting' }
VGFontExtents >> drawLinesOn: aForm placing: aBlock [
	"The lines my five numbers stand for, drawn across the image: the bottom of the line box in
	 green one line height under the ascent, then the ascent and the descent in blue over it,
	 then the baseline in grey, and the widest advance the face allows as a red segment running
	 from the origin along the baseline. A face with no line gap puts the bottom of its line box
	 exactly on its descent, so the blue lines are drawn short and over the green one: where the
	 two meet, the green line is the part still showing to the right."

	| baseline |
	baseline := aBlock value: 0 @ 0.
	{
		(height - ascent -> (Color green darker -> 1)).
		(ascent negated -> (Color blue -> 0.6)).
		(descent -> (Color blue -> 0.6)).
		(0 -> (Color lightGray -> 1)) } do: [ :each |
		aForm
			fill: (0 @ (aBlock value: 0 @ each key) y
					 extent: (aForm width * each value value) rounded @ 1)
			fillColor: each value key ].
	aForm
		fill:
			(baseline x @ (baseline y + 2)
				 extent: (aBlock value: maxAdvanceX @ 0) x - baseline x @ 1)
		fillColor: Color red
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

{ #category : 'converting' }
VGFontExtents >> writeInto: aFontExtents [
	"Copy my five numbers into the extents record a caller handed over. Cairo's font extents call
	 writes into a record its caller owns and answers nothing, so both contexts fill one rather
	 than return one. I name no class: anything that answers the five setters serves."

	aFontExtents
		ascent: ascent;
		descent: descent;
		height: height;
		maxAdvanceX: maxAdvanceX;
		maxAdvanceY: maxAdvanceY.
	^ aFontExtents
]
