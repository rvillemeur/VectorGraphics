"
I build the bytes of synthetic TrueType fonts, on my class side, for the tests that read glyphs with `VGFontFace`.

A font I build is the smallest file that reader accepts: the seven tables of `VGFontFace class >> requiredTableTags` and nothing else. The glyph records are the test's own, so a test can state the component record it wants to see read — a matrix, two scales, a byte offset at its bounds — instead of hunting for a real font that happens to carry one. Glyph 0 is the empty .notdef every font keeps, the records given become glyphs 1 and up, and the character map sends $a to glyph 1, $b to glyph 2, and so on. Nothing checks a checksum, so the directory records carry zero where a real font carries one.

I am not `TTFontFixtures`, which builds fonts for the metadata reader and the catalogue. `VGArchitectureTest class >> allowedDependencies` lets VectorGraphics-Cairo-Tests name VectorGraphics-Cairo, VectorGraphics-Cairo-Examples and VectorGraphics-Conformance, and no test package of the font reader, so the two cannot share a builder. What we have in common is the sfnt wrapper, which is twelve bytes and one record per table.

I hold no state and nobody instantiates me.
"
Class {
	#name : 'VGFontBytesFixture',
	#superclass : 'Object',
	#category : 'VectorGraphics-TrueType-Tests-Fixtures',
	#package : 'VectorGraphics-TrueType-Tests',
	#tag : 'Fixtures'
}

{ #category : 'constants' }
VGFontBytesFixture class >> advanceWidth [
	"The advance every glyph of a font I build carries, since no test of mine asks about
	 advances."

	^ 500
]

{ #category : 'accessing' }
VGFontBytesFixture class >> cffFontBytes [
	"A two glyph OpenType font whose outlines are CFF: .notdef and the square of
	 #cffTableBytes, which the character map sends $a to."

	^ self fontBytesWithTables:
		  (self cffTablesForGlyphCount: 2 table: self cffTableBytes)
]

{ #category : 'accessing' }
VGFontBytesFixture class >> cffFontBytesWithAGlyphThatCannotBeRead [
	"The same font as #cffFontBytes, whose second glyph carries a charstring no reader knows.
	 A face reads this font: a CFF glyph is interpreted when it is asked for, not when the
	 font is read."

	^ self fontBytesWithTables:
		  (self
			   cffTablesForGlyphCount: 2
			   table: self cffTableBytesWithAGlyphThatCannotBeRead)
]

{ #category : 'accessing' }
VGFontBytesFixture class >> cffTableBytes [
	"A CFF table of two charstrings: the empty .notdef every font keeps at glyph 0, and a
	 square drawn from 50 @ 100 to 450 @ 400. These are the bytes TTCffBytesFixture writes for
	 the charstrings 14 and 50 100 rmoveto 400 hlineto 300 vlineto -400 hlineto endchar; they
	 are copied rather than built, because allowedDependencies forbids this package from naming
	 that fixture."

	^ #[ 1 0 4 2 0 1 1 1 8 70 105 120 116 117 114 101 0 1 1 1 6 169 17 139 189 18 0 0 0 0 0 2 1 1 2 15 14 189 239 21 248 36 6 247 192 7 252 36 6 14 0 0 ]
]

{ #category : 'accessing' }
VGFontBytesFixture class >> cffTableBytesWithAGlyphThatCannotBeRead [
	"The same table as #cffTableBytes, with the square replaced by the single byte 0: an
	 operator no charstring reader knows. A face built from it reads every other glyph, and
	 says why this one cannot be drawn when it is asked for."

	^ #[ 1 0 4 2 0 1 1 1 8 70 105 120 116 117 114 101 0 1 1 1 6 169 17 139 177 18 0 0 0 0 0 2 1 1 2 3 14 0 0 0 ]
]

{ #category : 'accessing' }
VGFontBytesFixture class >> cffTablesForGlyphCount: anInteger table: aByteArray [
	"The six tables of a font whose outlines are CFF charstrings, as tag to bytes, in tag
	 order: the five every font carries, and the CFF table where a TrueType font carries glyf
	 and loca."

	^ {
		  ('CFF ' -> aByteArray).
		  ('cmap' -> (self cmapTableForGlyphCount: anInteger - 1
				                    platformId: TTCmapTableParser unicodePlatformId
				                    encodingId: TTCmapTableParser bmpEncodingId)).
		  ('head' -> self headTable).
		  ('hhea' -> (self hheaTableForGlyphCount: anInteger)).
		  ('hmtx' -> (self hmtxTableForGlyphCount: anInteger)).
		  ('maxp' -> (self maxpTableForGlyphCount: anInteger)) }
]

{ #category : 'bytes' }
VGFontBytesFixture class >> cmapTableForGlyphCount: anInteger platformId: aPlatformId encodingId: anEncodingId [
	"A character map of one subtable in format 6, the trimmed format: a first code point, a
	 count, and one glyph index per code point after that. It sends $a to glyph 1 and the code
	 points after it to the glyphs after it. The platform and the encoding are the caller''s,
	 because they are what decides whether the reader takes the subtable as a Unicode map at
	 all: a test of a font that maps no code point builds a pair the reader leaves out."

	^ ByteArray streamContents: [ :stream |
		  self putShort: 0 on: stream. "version"
		  self putShort: 1 on: stream. "one subtable"
		  self putShort: aPlatformId on: stream.
		  self putShort: anEncodingId on: stream.
		  self putLong: 12 on: stream. "the subtable follows this header"
		  self putShort: 6 on: stream. "format 6"
		  self putShort: 10 + (2 * anInteger) on: stream. "length"
		  self putShort: 0 on: stream. "language"
		  self putShort: self firstMappedCodePoint on: stream.
		  self putShort: anInteger on: stream. "entryCount"
		  1 to: anInteger do: [ :each | self putShort: each on: stream ] ]
]

{ #category : 'glyph records' }
VGFontBytesFixture class >> componentRecordWithFlags: aFlagWord glyphIndex: anInteger arguments: aCollection transform: anotherCollection [
	"One component record of a composite glyph, written exactly as the flags given say to read
	 it: two arguments as 16 bit numbers when the flags hold the words flag and as bytes
	 otherwise, then as many F2Dot14 numbers as the transform given holds. The flags are the
	 test's own, so a test can also state flags that do not match what follows them and see
	 what the reader makes of it. The more components flag is not mine to set: whoever puts the
	 components together sets it on all but the last."

	^ ByteArray streamContents: [ :stream |
		  self putShort: aFlagWord on: stream.
		  self putShort: anInteger on: stream.
		  (aFlagWord allMask: TTGlyfGlyphSource argumentsAreWordsFlag)
			  ifTrue: [
				  aCollection do: [ :each | self putShort: each on: stream ] ]
			  ifFalse: [
				  aCollection do: [ :each | stream nextPut: each \\ 256 ] ].
		  anotherCollection do: [ :each | self putF2Dot14: each on: stream ] ]
]

{ #category : 'glyph records' }
VGFontBytesFixture class >> compositeGlyphRecordWithComponents: anArray [
	"A composite glyph: a count of minus one, the box of the glyph, then the component records
	 given. Every record but the last has the more components flag set in its first field, which
	 is how a reader knows where the components stop."

	^ ByteArray streamContents: [ :stream |
		  self putShort: -1 on: stream. "a composite glyph"
		  self putShort: 0 on: stream. "xMin"
		  self putShort: 0 on: stream. "yMin"
		  self putShort: self unitsPerEm on: stream. "xMax"
		  self putShort: self unitsPerEm on: stream. "yMax"
		  anArray doWithIndex: [ :each :index |
			  index = anArray size
				  ifTrue: [ stream nextPutAll: each ]
				  ifFalse: [
					  stream nextPut: (each first bitOr:
								   (TTGlyfGlyphSource moreComponentsFlag bitShift: -8)).
					  stream nextPut: (each second bitOr:
								   (TTGlyfGlyphSource moreComponentsFlag bitAnd: 255)).
					  stream nextPutAll: (each allButFirst: 2) ] ] ]
]

{ #category : 'constants' }
VGFontBytesFixture class >> firstMappedCodePoint [
	"The code point the character map sends to glyph 1. The glyphs after it follow on, so a
	 test reads the second glyph I was given as $b."

	^ $a codePoint
]

{ #category : 'building' }
VGFontBytesFixture class >> fontBytesWithGlyphRecords: anArray [
	"A font whose glyphs are the records given, plus the empty .notdef every TrueType font
	 keeps at glyph 0. It carries the seven tables VGFontFace requires and nothing else, so a
	 face built from it answers no family name and no style name."

	^ self fontBytesWithTables: (self tablesForGlyphRecords: anArray)
]

{ #category : 'building' }
VGFontBytesFixture class >> fontBytesWithTables: anArray [
	"An sfnt file holding the tables given as tag to bytes: the twelve byte offset table, one
	 sixteen byte directory record per table, then the table data in the order given. Nothing
	 reads a checksum, so each record carries zero where a real font carries one."

	| dataOffset |
	dataOffset := 12 + (16 * anArray size).
	^ ByteArray streamContents: [ :stream |
		  self putLong: 16r00010000 on: stream. "sfnt version"
		  self putShort: anArray size on: stream.
		  self putShort: 0 on: stream. "searchRange"
		  self putShort: 0 on: stream. "entrySelector"
		  self putShort: 0 on: stream. "rangeShift"
		  anArray do: [ :each |
			  each key do: [ :char | stream nextPut: char asInteger ].
			  self putLong: 0 on: stream. "checkSum"
			  self putLong: dataOffset on: stream.
			  self putLong: each value size on: stream.
			  dataOffset := dataOffset + each value size ].
		  anArray do: [ :each | stream nextPutAll: each value ] ]
]

{ #category : 'tables' }
VGFontBytesFixture class >> headTable [
	"The head table of a font whose box is the em square."

	^ self headTableWithBounds:
		  (0 @ 0 corner: self unitsPerEm @ self unitsPerEm)
]

{ #category : 'tables' }
VGFontBytesFixture class >> headTableWithBounds: aRectangle [
	"The 54 byte head table, stating the box given as the box of the font. The four numbers of
	 that box are signed, and a font reaches below the baseline and left of the origin, so a
	 test states a box with a negative corner here."

	^ ByteArray streamContents: [ :stream |
		  self putLong: 16r00010000 on: stream. "version"
		  self putLong: 0 on: stream. "fontRevision"
		  self putLong: 0 on: stream. "checkSumAdjustment"
		  self putLong: 16r5F0F3CF5 on: stream. "magicNumber"
		  self putShort: 0 on: stream. "flags"
		  self putShort: self unitsPerEm on: stream.
		  16 timesRepeat: [ stream nextPut: 0 ]. "created and modified"
		  self putShort: aRectangle left on: stream. "xMin"
		  self putShort: aRectangle top on: stream. "yMin"
		  self putShort: aRectangle right on: stream. "xMax"
		  self putShort: aRectangle bottom on: stream. "yMax"
		  self putShort: 0 on: stream. "macStyle"
		  self putShort: 8 on: stream. "lowestRecPPEM"
		  self putShort: 0 on: stream. "fontDirectionHint"
		  self putShort: 0 on: stream. "indexToLocFormat: short offsets"
		  self putShort: 0 on: stream ] "glyphDataFormat"
]

{ #category : 'tables' }
VGFontBytesFixture class >> hheaTableForGlyphCount: anInteger [
	"The 36 byte hhea table. It states the ascent, the descent and the line gap a face answers,
	 the widest advance it reads at the fourth field, and at its last field the number of
	 metrics the hmtx table holds — one per glyph here, so no glyph inherits another's advance."

	^ ByteArray streamContents: [ :stream |
		  self putLong: 16r00010000 on: stream. "version"
		  self putShort: 800 on: stream. "ascender"
		  self putShort: -200 on: stream. "descender"
		  self putShort: 0 on: stream. "lineGap"
		  self putShort: self advanceWidth on: stream. "advanceWidthMax"
		  self putShort: 0 on: stream. "minLeftSideBearing"
		  self putShort: 0 on: stream. "minRightSideBearing"
		  self putShort: self unitsPerEm on: stream. "xMaxExtent"
		  self putShort: 1 on: stream. "caretSlopeRise"
		  self putShort: 0 on: stream. "caretSlopeRun"
		  self putShort: 0 on: stream. "caretOffset"
		  8 timesRepeat: [ stream nextPut: 0 ]. "four reserved fields"
		  self putShort: 0 on: stream. "metricDataFormat"
		  self putShort: anInteger on: stream ] "numberOfHMetrics"
]

{ #category : 'tables' }
VGFontBytesFixture class >> hmtxTableForGlyphCount: anInteger [
	"One metric per glyph: the same advance for all of them and no left side bearing."

	^ ByteArray streamContents: [ :stream |
		  anInteger timesRepeat: [
			  self putShort: self advanceWidth on: stream. "advanceWidth"
			  self putShort: 0 on: stream ] ] "leftSideBearing"
]

{ #category : 'tables' }
VGFontBytesFixture class >> locaTableForGlyphRecords: anArray [
	"The short offset format: each offset is half the byte offset of a glyph record inside the
	 glyf table, which is why every record I build is of even length. Glyph 0 is the empty
	 .notdef, which an offset equal to the next one says, and a last offset closes the last
	 record."

	^ ByteArray streamContents: [ :stream |
		  | offset |
		  offset := 0.
		  self putShort: 0 on: stream. "glyph 0, empty"
		  anArray do: [ :each |
			  self putShort: offset // 2 on: stream.
			  offset := offset + each size ].
		  self putShort: offset // 2 on: stream ]
]

{ #category : 'tables' }
VGFontBytesFixture class >> maxpTableForGlyphCount: anInteger [
	"The 32 byte maxp table of a version 1.0 font. Only the glyph count is read; the limits a
	 rasteriser would size its buffers from stay zero."

	^ ByteArray streamContents: [ :stream |
		  self putLong: 16r00010000 on: stream. "version"
		  self putShort: anInteger on: stream.
		  26 timesRepeat: [ stream nextPut: 0 ] ]
]

{ #category : 'writing' }
VGFontBytesFixture class >> putF2Dot14: aNumber on: aStream [
	"An F2Dot14 number: two bits before the point and fourteen after, written as a signed 16 bit
	 number. It reaches from minus two up to, but not as far as, two, so 2 states itself as
	 minus two and a test asking for it would read a glyph mirrored rather than scaled. That is
	 the fixture lying to the test, so it is refused here."

	(aNumber between: -2 and: 2 - (1 / TTFontTableDirEntry twoDotFourteenScale)) ifFalse: [
		Error signal: aNumber printString , ' is outside what an F2Dot14 number can say' ].
	self putShort: (aNumber * TTFontTableDirEntry twoDotFourteenScale) rounded on: aStream
]

{ #category : 'writing' }
VGFontBytesFixture class >> putLong: anInteger on: aStream [
	"One 32 bit number, big endian."

	| value |
	value := anInteger \\ 16r100000000.
	#( -24 -16 -8 0 ) do: [ :shift |
		aStream nextPut: ((value bitShift: shift) bitAnd: 255) ]
]

{ #category : 'writing' }
VGFontBytesFixture class >> putShort: anInteger on: aStream [
	"One 16 bit number, big endian. A negative number is written as its two's complement, which
	 is what a reader of a signed field reads back."

	| value |
	value := anInteger \\ 65536.
	aStream
		nextPut: (value bitShift: -8);
		nextPut: (value bitAnd: 255)
]

{ #category : 'glyph records' }
VGFontBytesFixture class >> simpleGlyphRecordFrom: aPoint to: anotherPoint [
	"One glyph of one closed contour: the four corners of this rectangle, every one of them on
	 the curve, each coordinate a 16 bit step from the one before. The record states the same
	 rectangle as its own box."

	| corners |
	corners := {
		           aPoint.
		           (anotherPoint x @ aPoint y).
		           anotherPoint.
		           (aPoint x @ anotherPoint y) }.
	^ ByteArray streamContents: [ :stream |
		  | previous |
		  self putShort: 1 on: stream. "one contour"
		  self putShort: aPoint x on: stream. "xMin"
		  self putShort: aPoint y on: stream. "yMin"
		  self putShort: anotherPoint x on: stream. "xMax"
		  self putShort: anotherPoint y on: stream. "yMax"
		  self putShort: corners size - 1 on: stream. "last point of the contour"
		  self putShort: 0 on: stream. "no instructions"
		  corners do: [ :each | stream nextPut: 1 ]. "on the curve, 16 bit steps"
		  previous := 0 @ 0.
		  corners do: [ :each |
			  self putShort: each x - previous x on: stream.
			  previous := each ].
		  previous := 0 @ 0.
		  corners do: [ :each |
			  self putShort: each y - previous y on: stream.
			  previous := each ] ]
]

{ #category : 'building' }
VGFontBytesFixture class >> tablesForGlyphRecords: anArray [
	"The seven tables of a font whose glyphs are the records given, as tag to bytes, in tag
	 order. A test that wants a font missing one of them, or carrying a table of its own in
	 place of mine, takes these and hands what it wants to #fontBytesWithTables:."

	| glyphCount |
	glyphCount := anArray size + 1.
	^ {
		  ('cmap' -> (self cmapTableForGlyphCount: anArray size
				                    platformId: TTCmapTableParser unicodePlatformId
				                    encodingId: TTCmapTableParser bmpEncodingId)).
		  ('glyf' -> (ByteArray streamContents: [ :stream |
				    anArray do: [ :each | stream nextPutAll: each ] ])).
		  ('head' -> self headTable).
		  ('hhea' -> (self hheaTableForGlyphCount: glyphCount)).
		  ('hmtx' -> (self hmtxTableForGlyphCount: glyphCount)).
		  ('loca' -> (self locaTableForGlyphRecords: anArray)).
		  ('maxp' -> (self maxpTableForGlyphCount: glyphCount)) }
]

{ #category : 'constants' }
VGFontBytesFixture class >> unitsPerEm [
	"The em square of every font I build, which is also the box the head table states."

	^ 1000
]
