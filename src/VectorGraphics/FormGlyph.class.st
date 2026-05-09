"
A pre-rendered glyph Form with its layout metrics, used when drawing text via BitBltCanvasEngine.

TrueTypeFont renders each glyph on demand into a Form (via TTFontDescription >> formGlyphForUtf8Byte1:...)
and wraps it in a FormGlyph together with the pixel-space metrics needed to position and
advance the text cursor. FormGlyph instances are cached in TrueTypeFont >> glyphFormsByUtf8.

See: https://www.freetype.org/freetype2/docs/glyphs/glyphs-3.html

## Key instVars (all in pixels, possibly fractional)
- `form`           Form — the pre-rendered glyph image (RGBA, depth 32)
- `leftOffset`     horizontal distance from cursor origin to left edge of the form
- `topOffset`      vertical distance from baseline to top edge of the form
- `advanceWidth`   how far to advance the cursor after drawing this glyph
- `deltaXToCenter` used for centering in certain layout contexts

## Key methods
- `displayOn: aCanvas at: aPoint` — blits the form at the correct offset from the cursor
- `advanceWidth` — queried by TrueTypeFont >> widthOf: for string measurement
"
Class {
	#name : 'FormGlyph',
	#superclass : 'Object',
	#instVars : [
		'form',
		'leftOffset',
		'topOffset',
		'advanceWidth',
		'deltaXToCenter'
	],
	#category : 'VectorGraphics-TrueType',
	#package : 'VectorGraphics',
	#tag : 'TrueType'
}

{ #category : 'instance creation' }
FormGlyph class >> form: aForm leftOffset: aNumber topOffset: otherNumber advanceWidth: deltaX [

	^ self new
		  form: aForm
		  leftOffset: aNumber
		  topOffset: otherNumber
		  advanceWidth: deltaX
]

{ #category : 'accessing' }
FormGlyph >> advanceWidth [

	^ advanceWidth
]

{ #category : 'accessing' }
FormGlyph >> deltaXToCenter [

	^ deltaXToCenter
]

{ #category : 'accessing' }
FormGlyph >> deltaXToCenter: aNumber [

	deltaXToCenter := aNumber
]

{ #category : 'accessing' }
FormGlyph >> form [

	^ form
]

{ #category : 'initialization' }
FormGlyph >> form: aForm [

	form := aForm
]

{ #category : 'initialization' }
FormGlyph >> form: aForm leftOffset: aNumber topOffset: otherNumber advanceWidth: deltaX [

	form := aForm.
	leftOffset := aNumber.
	topOffset := otherNumber.
	advanceWidth := deltaX
]

{ #category : 'accessing' }
FormGlyph >> leftOffset [

	^ leftOffset
]

{ #category : 'copying' }
FormGlyph >> postCopy [

	form := form copy
]

{ #category : 'accessing' }
FormGlyph >> rightOffset [

	^ form width + leftOffset - advanceWidth
]

{ #category : 'accessing' }
FormGlyph >> topOffset [

	^ topOffset
]
