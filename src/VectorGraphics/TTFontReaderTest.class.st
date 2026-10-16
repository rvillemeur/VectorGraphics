"
Tests how TTFontReader turns a parsed character map and glyph list into the flattened lookup tables a TTFontDescription draws from.

The fixtures build a character map and glyphs directly, so no .ttf file is needed: characterMapMapping: answers a Basic Multilingual Plane map that is zero everywhere but the given code points, and glyphWithAdvanceWidth: answers a glyph with no contours, whose contour data is therefore exactly contourDataFloatsPerGlyph floats and whose advance width identifies it in the flattened data.

Key methods: testFlattenedContourDataHoldsTheUnknownGlyphAndTheMappedGlyphsOnly states that the data grows with the font's glyph count rather than with the size of the character map; testDashResolvesToTheWideMinusWhenTheFontDoesNotMapTheDash guards the substitution rules that TTFontParser class >> glyphSubstitutions declares.
"
Class {
	#name : 'TTFontReaderTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Tests',
	#package : 'VectorGraphics',
	#tag : 'Tests'
}

{ #category : 'fixtures' }
TTFontReaderTest >> advanceWidthForCodePoint: aCodePoint in: aFontDescription [
	"The advance width stored at the contour data position aCodePoint resolves to. It names
	 the glyph the code point reached, including the unknown glyph."

	| bytes position |
	bytes := OrderedCollection new.
	Character evaluate: [ :byte | bytes add: byte ] withUtf8BytesOf: aCodePoint.
	position := aFontDescription
		            contourDataPositionForByte1: (bytes at: 1)
		            byte2: (bytes at: 2 ifAbsent: [ nil ])
		            byte3: (bytes at: 3 ifAbsent: [ nil ])
		            byte4: (bytes at: 4 ifAbsent: [ nil ]).
	^ aFontDescription contourDataForUtf8 at: position
]

{ #category : 'fixtures' }
TTFontReaderTest >> characterMapMapping: aCollectionOfAssociations [
	"A character map of the shape TTCmapTableParser answers, holding zero — no glyph of its
	 own — for every code point but the ones named, which map to the given glyph indices."

	| map |
	map := Array new: self characterMapSize withAll: 0.
	aCollectionOfAssociations do: [ :each | map at: each key + 1 put: each value ].
	^ map
]

{ #category : 'fixtures' }
TTFontReaderTest >> characterMapSize [
	"The size of the array TTCmapTableParser answers: one slot per code point of the Basic
	 Multilingual Plane, whether the font maps it or not."

	^ 65536
]

{ #category : 'fixtures' }
TTFontReaderTest >> contourDataFloatsPerGlyph [
	"What a glyph with no contours writes through addContourDataTo:: the advance width, the
	 four bounds and the contour count."

	^ 6
]

{ #category : 'fixtures' }
TTFontReaderTest >> descriptionFromCharacterMap: aCharacterMap glyphs: aGlyphCollection [
	"Answer the TTFontDescription that mapAndStoreGlyphsUsing:glyphs: builds. The first glyph
	 is the unknown glyph, as in readFrom:fromOffset:, and a code point mapping to index n
	 reaches aGlyphCollection at n + 1."

	| reader |
	reader := TTFontReader new.
	reader instVarNamed: 'fontDescription' put: TTFontDescription new.
	reader mapAndStoreGlyphsUsing: aCharacterMap glyphs: aGlyphCollection.
	^ reader instVarNamed: 'fontDescription'
]

{ #category : 'fixtures' }
TTFontReaderTest >> fixtureEmBox [
	"The em box the fixture glyphs are built in. Any non-zero value will do; a real font's
	 unitsPerEm is usually this."

	^ 1000
]

{ #category : 'fixtures' }
TTFontReaderTest >> glyphWithAdvanceWidth: aNumber [
	"A glyph with no contours, so that it writes exactly contourDataFloatsPerGlyph floats and
	 its advance width is the first of them: that is how a test says which glyph a code point
	 resolved to. The bounds are set because topSideBearing answers the bottom bound and a
	 zero there would divide by zero in the engine."

	| glyph |
	glyph := TTGlyph new.
	glyph advanceWidth: aNumber.
	glyph
		boundsLeft: 0
		boundsRight: aNumber
		boundsTop: self fixtureEmBox
		boundsBottom: self fixtureEmBox negated.
	^ glyph
]

{ #category : 'fixtures' }
TTFontReaderTest >> glyphWithOneContourAndAdvanceWidth: aNumber [
	"A glyph like glyphWithAdvanceWidth:, with one straight-sided contour added. A test that reads
	 the flattened data as a run of records needs the unknown glyph to carry a contour: a glyph with
	 none writes a header alone, and a writer that drops the header then writes nothing at all,
	 which leaves the data still readable and hides the fault. points: leaves every control point
	 flag clear, so each segment is a straight line."

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
	glyph := self glyphWithAdvanceWidth: aNumber.
	glyph contours: (Array with: contour).
	^ glyph
]

{ #category : 'tests' }
TTFontReaderTest >> testAMappedCodePointResolvesToItsOwnGlyph [
	"Both a one byte and a three byte code point reach the glyph their character map entry
	 names, so building the table sparsely must still walk the UTF-8 bytes."

	| description |
	description := self
		               descriptionFromCharacterMap: (self characterMapMapping: {
								                (65 -> 1).
								                (16r4E2D -> 2) })
		               glyphs: {
				               (self glyphWithAdvanceWidth: 100).
				               (self glyphWithAdvanceWidth: 500).
				               (self glyphWithAdvanceWidth: 900) }.
	self assert: (self advanceWidthForCodePoint: 65 in: description) equals: 500.
	self
		assert: (self advanceWidthForCodePoint: 16r4E2D in: description)
		equals: 900
]

{ #category : 'tests' }
TTFontReaderTest >> testAnUnmappedCodePointHasNoEntryOfItsOwn [
	"A code point the font does not map gets no slot in the index table, so it resolves to the
	 unknown glyph through the fallback in contourDataPositionForByte1:byte2:byte3:byte4:
	 rather than through a copy of the unknown glyph's data of its own."

	| description |
	description := self
		               descriptionFromCharacterMap:
		               (self characterMapMapping: { (65 -> 1) })
		               glyphs: {
				               (self glyphWithAdvanceWidth: 100).
				               (self glyphWithAdvanceWidth: 500) }.
	self assert: (description contourDataIndexesByUtf8 at: 66 + 1) equals: 0.
	self
		assert: (self advanceWidthForCodePoint: 66 in: description)
		equals: 100
]

{ #category : 'tests' }
TTFontReaderTest >> testDashResolvesToTheWideMinusWhenTheFontDoesNotMapTheDash [
	"A substitution source has no entry in the character map of its own, so a table built from
	 the mapped code points alone would lose it. The dash must still reach the wide minus."

	| description |
	description := self
		               descriptionFromCharacterMap:
		               (self characterMapMapping: { (16r2212 -> 1) })
		               glyphs: {
				               (self glyphWithAdvanceWidth: 100).
				               (self glyphWithAdvanceWidth: 900) }.
	self
		assert: (self advanceWidthForCodePoint: $- codePoint in: description)
		equals: 900
]

{ #category : 'tests' }
TTFontReaderTest >> testEveryGlyphRecordIsReachedOnceAndTheDataHasNoGap [
	"Each position in the index map starts a record of a known length: an advance width, four
	 bounds, a contour count, then that many contours. Read as a run of records, the flattened data
	 has to come out exactly: every float belongs to one record and no float is left over. A writer
	 that skips a record's header still answers a float for every position, so only this check
	 catches the data sliding out of step with the positions."

	| description data leaves covered |
	description := self
		               descriptionFromCharacterMap: (self characterMapMapping: {
						                (65 -> 1).
						                (16r4E2D -> 2) })
		               glyphs: {
				               (self glyphWithOneContourAndAdvanceWidth: 100).
				               (self glyphWithAdvanceWidth: 500).
				               (self glyphWithAdvanceWidth: 900) }.
	data := description contourDataForUtf8.
	leaves := Set with: TTFontDescription unknownGlyphContourDataPosition.
	description contourDataIndexesByUtf8 do: [ :each |
		each > 0 ifTrue: [ leaves add: each ] ].
	covered := Array new: data size withAll: 0.
	leaves do: [ :position |
		| index |
		index := position + 6.
		(data at: position + 5) asInteger timesRepeat: [
			index := index + 1 + 2 + ((data at: index) asInteger * 4) ].
		position to: index - 1 do: [ :each | covered at: each put: (covered at: each) + 1 ] ].
	self assert: (covered allSatisfy: [ :each | each = 1 ])
]

{ #category : 'tests' }
TTFontReaderTest >> testFlattenedContourDataHoldsTheUnknownGlyphAndTheMappedGlyphsOnly [
	"The flattened data grows with the number of glyphs the font maps, not with the size of
	 the character map. A font mapping two code points writes the unknown glyph and those two,
	 whatever the 65536 slots of the map hold."

	| description |
	description := self
		               descriptionFromCharacterMap: (self characterMapMapping: {
								                (65 -> 1).
								                (16r4E2D -> 2) })
		               glyphs: {
				               (self glyphWithAdvanceWidth: 100).
				               (self glyphWithAdvanceWidth: 500).
				               (self glyphWithAdvanceWidth: 900) }.
	self
		assert: description contourDataForUtf8 size
		equals: self contourDataFloatsPerGlyph * 3
]

{ #category : 'tests' }
TTFontReaderTest >> testWhitespaceResolvesToTheSpaceGlyph [
	"Tab, newline and the other separators carry no glyph of their own in a font; they are
	 mapped to the space glyph so that a line of text advances across them."

	| description |
	description := self
		               descriptionFromCharacterMap:
		               (self characterMapMapping: { (Character space codePoint -> 1) })
		               glyphs: {
				               (self glyphWithAdvanceWidth: 100).
				               (self glyphWithAdvanceWidth: 300) }.
	#( 9 10 11 12 13 ) do: [ :codePoint |
		self
			assert: (self advanceWidthForCodePoint: codePoint in: description)
			equals: 300 ]
]
