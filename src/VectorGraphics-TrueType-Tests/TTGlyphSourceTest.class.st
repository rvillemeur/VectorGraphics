"
The facts every glyph source answers, whichever outline table it reads. I am abstract: my subclasses give me the bytes of a font in their own format, and I state what both routes must agree on — the number of glyph records, the outline of a glyph in font units with its own box and its advance, and that a source draws the same square from `glyf` as from `CFF `.

A test of mine builds a source the way `VGFontFace >> readBytes:` does: the table directory of the bytes, the glyph count of `maxp`, the `loca` format of `head`, then the advances of `hmtx` filled in.
"
Class {
	#name : 'TTGlyphSourceTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-TrueType-Tests-Tests',
	#package : 'VectorGraphics-TrueType-Tests',
	#tag : 'Tests'
}

{ #category : 'testing' }
TTGlyphSourceTest class >> isAbstract [
	"The facts below are true of both routes, so they are written once and run once per
	 route: only my subclasses, each of which names a format, have a suite."

	^ self = TTGlyphSourceTest
]

{ #category : 'support' }
TTGlyphSourceTest >> sourceForFontBytes: aByteArray [
	"The source of the glyphs of a font assembled byte by byte, built through the same door as
	 the examples so a test and an example cannot read a font two different ways."

	^ TrueTypeExamples glyphSourceForFontBytes: aByteArray
]

{ #category : 'fixtures' }
TTGlyphSourceTest >> squareOfTheFixture [
	"The one contour of glyph 1 of the fonts my subclasses build, as a source answers it: four
	 straight segments, so the control point of each is its own end point, and the first point
	 is stated once at the start and once at the close."

	^ {
		  (50 @ 100).
		  (450 @ 100).
		  (450 @ 100).
		  (450 @ 400).
		  (450 @ 400).
		  (50 @ 400).
		  (50 @ 400).
		  (50 @ 100).
		  (50 @ 100) }
]

{ #category : 'fixtures' }
TTGlyphSourceTest >> subjectFontBytes [
	"The bytes of a font whose outlines are in the format my subclass is about. Its glyph 1 is
	 the square the tests below read, and it carries the seven tables a face requires."

	^ self subclassResponsibility
]

{ #category : 'tests' }
TTGlyphSourceTest >> testASourceAnswersOneRecordPerGlyphOfTheFont [
	"The count is the one maxp states, .notdef at glyph 0 included, whichever table the
	 outlines are drawn in."

	self
		assert: (self sourceForFontBytes: self subjectFontBytes) glyphCount
		equals: 2
]

{ #category : 'tests' }
TTGlyphSourceTest >> testTheOutlineOfAGlyphIsItsContoursItsBoxAndItsAdvanceInFontUnits [
	"One square, read as the same outline from either format: the same points in font units,
	 the same box, and the advance hmtx states rather than anything the outline table says."

	| outline |
	outline := (self sourceForFontBytes: self subjectFontBytes)
		           outlineOfGlyphAt: 1.
	self
		assert: (outline contours collect: [ :each | each asArray ]) asArray
		equals: { self squareOfTheFixture }.
	self assert: outline boundsRectangle equals: (50 @ 100 corner: 450 @ 400).
	self assert: outline advance equals: VGFontBytesFixture advanceWidth
]
