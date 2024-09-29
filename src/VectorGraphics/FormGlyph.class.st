"
Needed only for BitBltCanvasEngine

https://www.freetype.org/freetype2/docs/glyphs/glyphs-3.html

leftSideBearing, topSideBearing, advanceWidth are in (possibly fractional) pixels.
"
Class {
	#name : #FormGlyph,
	#superclass : #Object,
	#instVars : [
		'form',
		'leftOffset',
		'topOffset',
		'advanceWidth'
	],
	#category : #'VectorGraphics-TrueType'
}

{ #category : #'instance creation' }
FormGlyph class >> form: aForm leftOffset: aNumber topOffset: otherNumber advanceWidth: deltaX [

	^ self new
		  form: aForm
		  leftOffset: aNumber
		  topOffset: otherNumber
		  advanceWidth: deltaX
]

{ #category : #accessing }
FormGlyph >> advanceWidth [

	^ advanceWidth
]

{ #category : #accessing }
FormGlyph >> form [

	^ form
]

{ #category : #initialization }
FormGlyph >> form: aForm [

	form := aForm
]

{ #category : #initialization }
FormGlyph >> form: aForm leftOffset: aNumber topOffset: otherNumber advanceWidth: deltaX [

	form := aForm.
	leftOffset := aNumber.
	topOffset := otherNumber.
	advanceWidth := deltaX
]

{ #category : #accessing }
FormGlyph >> leftOffset [

	^ leftOffset
]

{ #category : #copying }
FormGlyph >> postCopy [

	form := form copy
]

{ #category : #accessing }
FormGlyph >> rightOffset [

	^ form width + leftOffset - advanceWidth
]

{ #category : #accessing }
FormGlyph >> topOffset [

	^ topOffset
]
