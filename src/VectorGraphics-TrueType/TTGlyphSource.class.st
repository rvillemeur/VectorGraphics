"
The glyph records of one font face, and the outlines they draw. I am abstract: a font says its outlines either in the `glyf` and `loca` tables or in one `CFF ` table, and `TTGlyfGlyphSource` and `TTCffGlyphSource` are those two routes. `TTGlyphSource class >> on:count:indexToLocFormat:` reads a table directory and answers whichever of them the font needs, so my sender never asks which format it holds.

I answer the count of records, the outline of a glyph by index counted from zero, and I let `hmtx` fill the advances of my records. The outline is a `VGGlyphOutline`: contours in font units, the box of the glyph and its advance.

I hold the records themselves; what a record is differs between my subclasses, and that is the point of the split. A `glyf` record carries its contours already, and a `CFF ` record draws itself the first time somebody asks for its shape.
"
Class {
	#name : 'TTGlyphSource',
	#superclass : 'Object',
	#instVars : [
		'glyphs'
	],
	#category : 'VectorGraphics-TrueType-Reading',
	#package : 'VectorGraphics-TrueType',
	#tag : 'Reading'
}

{ #category : 'instance creation' }
TTGlyphSource class >> on: aTableDictionary count: aGlyphCount indexToLocFormat: anInteger [
	"The source for whichever outline table this font carries. The rule that decides is
	 TTFontReader's, so a reader and a face cannot disagree about the format of a file."

	^ ((TTFontReader holdsTrueTypeOutlines: aTableDictionary)
		   ifTrue: [ TTGlyfGlyphSource ]
		   ifFalse: [ TTCffGlyphSource ]) new
		  readFrom: aTableDictionary
		  count: aGlyphCount
		  indexToLocFormat: anInteger
]

{ #category : 'accessing' }
TTGlyphSource >> contoursOfGlyphAt: aGlyphIndex [
	"The contours of one glyph in font units. Mine are drawn by the glyph itself; a format whose
	 glyphs are built from other glyphs says so by overriding me."

	^ self contoursOfSimpleGlyph: (self glyphAt: aGlyphIndex)
]

{ #category : 'accessing' }
TTGlyphSource >> contoursOfSimpleGlyph: aGlyph [
	"Walk the glyph's contours once. TTContourConstruction answers a quadratic's end point and
	 its control point, in that order, and both absolute, so the odd-sized array of points I
	 build is the contour as it is drawn."

	^ (aGlyph contours reject: [ :each | each isEmpty ]) collect: [ :each |
		  Array streamContents: [ :stream |
			  stream nextPut: each points first.
			  each quadraticBeziersDo: [ :endPoint :controlPoint |
				  stream
					  nextPut: controlPoint;
					  nextPut: endPoint ] ] ]
]

{ #category : 'reading' }
TTGlyphSource >> fillAdvancesFrom: aTableDictionary numHMetrics: anInteger [
	"The advances the hmtx table states, written into the records I read. The records have to be
	 read first: hmtx fills them rather than answering anything of its own."

	(TTHmtxTableParser
		 on: (aTableDictionary at: 'hmtx')
		 glyphs: glyphs
		 numHMetrics: anInteger) process
]

{ #category : 'accessing' }
TTGlyphSource >> glyphAt: aGlyphIndex [
	"The record of one glyph, by an index counted from zero as a character map states it."

	^ glyphs at: aGlyphIndex + 1
]

{ #category : 'accessing' }
TTGlyphSource >> glyphCount [
	"How many glyphs the font holds, index zero included: that one is the glyph a code point the
	 font does not map is drawn with."

	^ glyphs size
]

{ #category : 'accessing' }
TTGlyphSource >> glyphEntries [
	"My glyphs, each paired with the index a font asks for it by. The views list these rather
	 than the records alone, because a record does not know its own index."

	^ (0 to: self glyphCount - 1) collect: [ :index |
		  index -> (self glyphAt: index) ]
]

{ #category : 'inspector' }
TTGlyphSource >> inspectorGlyphs: aBuilder [
	"The glyphs of the font, one row each, built through the presenter builder. Every source
	 states its own columns, because the facts a reader can be shown for free differ by
	 format: a glyf glyph already holds its points and says whether it is a composite, while a
	 CFF glyph holds a charstring that reading would interpret, so it states instead whether
	 it has been interpreted yet."

	^ self subclassResponsibility
]

{ #category : 'accessing' }
TTGlyphSource >> outlineOfGlyphAt: aGlyphIndex [
	"The advance and the box come from the glyph's own record; the contours come from the glyph
	 itself, or from its components when it is a composite."

	| glyph |
	glyph := self glyphAt: aGlyphIndex.
	^ VGGlyphOutline
		  advance: glyph advanceWidth
		  boundsRectangle:
		  (glyph boundsLeft @ glyph boundsTop
		   corner: glyph boundsRight @ glyph boundsBottom)
		  contours: (self contoursOfGlyphAt: aGlyphIndex)
]

{ #category : 'reading' }
TTGlyphSource >> readFrom: aTableDictionary count: aGlyphCount indexToLocFormat: anInteger [
	"Read my records from the tables of a font that holds its outlines in my format, and answer
	 myself. The loca format matters to the glyf route alone, and the other route ignores it."

	^ self subclassResponsibility
]
