"
The tests of the text drawing glue: the two cases that drive VectorEngineAbstract >> displayUtf8:at:trueTypeFont:color:scaleX:scaleY: and the fixture font they need.

That method is an extension method of VectorGraphics-Text rather than a method of the engine package, so its tests belong here and not in VectorGraphics-Engine-Tests. Both cases are about a code point the font does not map: a sparse font description, with a slot for $M and nothing else, is what makes the unknown-glyph fallback visible.

## Key methods

- `formAfterDrawingUtf8:` — draws the bytes through a sparse description and answers the form
- `paintedPixelCountIn:` — counts the pixels the drawing changed, the fixture form starting white
- `sparseFontDescription` — the description a font mapping few code points builds
"
Class {
	#name : 'VGTextDrawingTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Text-Tests-Tests',
	#package : 'VectorGraphics-Text-Tests',
	#tag : 'Tests'
}

{ #category : 'fixtures' }
VGTextDrawingTest >> fixtureEmBox [
	"The em box the fixture glyphs are built in. displayUtf8:at:trueTypeFont:color:scaleX:scaleY:
	 divides by the M glyph's top side bearing, so it must not be zero."

	^ 1000
]

{ #category : 'fixtures' }
VGTextDrawingTest >> fixturePointSize [
	"A point size that puts the fixture glyph's em box inside the 50 by 50 fixture form."

	^ 28
]

{ #category : 'fixtures' }
VGTextDrawingTest >> formAfterDrawingUtf8: aByteArray [
	"Answer the form left by drawing aByteArray through a sparse font description, at a
	 baseline and a scale that put a fixture glyph inside the form."

	| form engine |
	form := Form extent: 50 @ 50 depth: 32.
	form fillColor: Color white.
	engine := VectorEngineWholePixel onForm: form.
	engine
		displayUtf8: aByteArray
		at: 5 @ 45
		trueTypeFont: self sparseFontDescription
		color: Color black
		scaleX: 1.0 * self fixturePointSize
		scaleY: -1.0 * self fixturePointSize.
	^ form
]

{ #category : 'fixtures' }
VGTextDrawingTest >> glyphWithTriangleContour [
	"A glyph with one straight-sided contour, so that drawing it paints pixels a test can
	 compare. points: leaves every control point flag clear, which makes each segment a
	 straight line rather than a Bezier."

	| points contour glyph |
	points := Int16PointArray new: 3.
	points at: 1 putX: 0.
	points at: 1 putY: 0.
	points at: 2 putX: 600.
	points at: 2 putY: 0.
	points at: 3 putX: 300.
	points at: 3 putY: 700.
	contour := TTContourConstruction new.
	contour points: points.
	glyph := TTGlyph new.
	glyph contours: (Array with: contour).
	glyph advanceWidth: 700.
	glyph
		boundsLeft: 0
		boundsRight: 600
		boundsTop: 0
		boundsBottom: self fixtureEmBox.
	^ glyph
]

{ #category : 'fixtures' }
VGTextDrawingTest >> paintedPixelCountIn: aForm [
	"How many pixels of aForm the drawing changed, the fixture form starting out white."

	| count |
	count := 0.
	0 to: aForm height - 1 do: [ :y |
		0 to: aForm width - 1 do: [ :x |
			(aForm colorAt: x @ y) = Color white ifFalse: [ count := count + 1 ] ] ].
	^ count
]

{ #category : 'fixtures' }
VGTextDrawingTest >> sparseFontDescription [
	"A description built the way a font that maps few code points builds one: a slot for $M,
	 which is where letterMTopSideBearing is read from, and nothing else. Every other code
	 point has to reach the unknown glyph through the index table's fallback."

	| glyphsByUtf8 unknown description |
	unknown := self glyphWithTriangleContour.
	glyphsByUtf8 := Array new: 256.
	glyphsByUtf8 at: $M codePoint + 1 put: self glyphWithTriangleContour.
	description := TTFontDescription new.
	description glyphsByUtf8Bytes: glyphsByUtf8 unknownGlyph: unknown.
	^ description
]

{ #category : 'tests - text' }
VGTextDrawingTest >> testAByteWithNoIndexEntryDrawsTheUnknownGlyph [
	"A font that maps few code points leaves most slots of the index table empty, and nothing
	 stops a string from naming one of them. The draw loop must read the unknown glyph's data
	 there rather than index the flattened data at zero."

	self
		assert: (self paintedPixelCountIn: (self formAfterDrawingUtf8: #[ 65 ])) > 0
		description: 'a byte with no index entry should paint the unknown glyph'
]

{ #category : 'tests - text' }
VGTextDrawingTest >> testAnUnmappedMultiByteCharacterDrawsOneUnknownGlyph [
	"U+4E2D is three UTF-8 bytes. With no index entry for its lead byte there is no table to
	 descend, so the continuation bytes must be skipped rather than read as characters of
	 their own: one unmapped character is one unknown glyph, exactly as a single unmapped byte
	 is."

	self
		assert: (self formAfterDrawingUtf8: #[ 16rE4 16rB8 16rAD ]) bits
		equals: (self formAfterDrawingUtf8: #[ 65 ]) bits
]
