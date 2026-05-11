Class {
	#name : 'TTFontParserTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Tests',
	#package : 'VectorGraphics',
	#tag : 'Tests'
}

{ #category : 'helpers' }
TTFontParserTest >> putShort: value at: pos in: bytes [

	"Write a signed 16-bit big-endian integer."

	| v |
	v := value < 0
		     ifTrue: [ value + 65536 ]
		     ifFalse: [ value ].
	bytes at: pos put: ((v bitShift: -8) bitAnd: 255).
	bytes at: pos + 1 put: (v bitAnd: 255)
]

{ #category : 'helpers' }
TTFontParserTest >> putULong: value at: pos in: bytes [

	"Write an unsigned 32-bit big-endian integer."

	bytes at: pos     put: ((value bitShift: -24) bitAnd: 255).
	bytes at: pos + 1 put: ((value bitShift: -16) bitAnd: 255).
	bytes at: pos + 2 put: ((value bitShift: -8)  bitAnd: 255).
	bytes at: pos + 3 put: (value bitAnd: 255)
]

{ #category : 'helpers' }
TTFontParserTest >> putUShort: value at: pos in: bytes [

	"Write an unsigned 16-bit big-endian integer."

	bytes at: pos put: ((value bitShift: -8) bitAnd: 255).
	bytes at: pos + 1 put: (value bitAnd: 255)
]

{ #category : 'tests - cmap' }
TTFontParserTest >> testCmapProcessFindsUnicodePlatformSubtable [

	"2 subtables: platformID=3 (Windows) first, platformID=0 (Unicode) second.
	process seeks to the Unicode subtable and parses its format (format 6, 1 entry)."

	| bytes entry cmap |
	"Header: version(2) + nSubTables(2) = 4 bytes"
	"Subtable 1 record: pID=3, sID=1, offset=100 = 8 bytes → bytes 5-12"
	"Subtable 2 record: pID=0, sID=3, offset=20 = 8 bytes → bytes 13-20"
	"Format 6 data at byte 21 (offset 20 from initialOffset=1): format=6, length, version, firstCode=0, entryCount=1, glyph=42"
	bytes := ByteArray new: 32.
	self putUShort: 0   at: 1 in: bytes. "cmap version"
	self putUShort: 2   at: 3 in: bytes. "nSubTables"
	self putUShort: 3   at: 5 in: bytes. "subtable 1: pID=3"
	self putUShort: 1   at: 7 in: bytes. "subtable 1: sID=1"
	self putULong:  100 at: 9 in: bytes. "subtable 1: offset (won't be read)"
	self putUShort: 0   at: 13 in: bytes. "subtable 2: pID=0 (Unicode)"
	self putUShort: 3   at: 15 in: bytes. "subtable 2: sID=3"
	self putULong:  20  at: 17 in: bytes. "subtable 2: offset → byte 21 = 1+20"
	"Format 6 at bytes 21-32:"
	self putUShort: 6  at: 21 in: bytes. "format=6"
	self putUShort: 12 at: 23 in: bytes. "length (not used after reading)"
	self putUShort: 0  at: 25 in: bytes. "version (skip: 2)"
	self putUShort: 0  at: 27 in: bytes. "firstCode=0"
	self putUShort: 1  at: 29 in: bytes. "entryCount=1"
	self putUShort: 42 at: 31 in: bytes. "glyph index for code 1"
	entry := TTFontTableDirEntry onBytes: bytes.
	cmap := (TTCmapTableParser on: entry) process.
	self assert: cmap isNil not.
	self assert: cmap size equals: 1.
	self assert: (cmap at: 1) equals: 42
]

{ #category : 'tests - cmap' }
TTFontParserTest >> testCmapProcessReturnsNilWhenNoPlatformZero [

	"1 subtable with platformID=3 (Windows) only. No Unicode platform → nil."

	| bytes entry |
	bytes := ByteArray new: 12.
	self putUShort: 0   at: 1 in: bytes. "cmap version"
	self putUShort: 1   at: 3 in: bytes. "nSubTables=1"
	self putUShort: 3   at: 5 in: bytes. "pID=3 (Windows, not Unicode)"
	self putUShort: 1   at: 7 in: bytes. "sID=1"
	self putULong:  100 at: 9 in: bytes. "offset (never used)"
	entry := TTFontTableDirEntry onBytes: bytes.
	self assert: ((TTCmapTableParser on: entry) process) isNil
]

{ #category : 'tests - hmtx' }
TTFontParserTest >> testHmtxReusesLastAdvanceWidthForTrailingGlyphs [

	"numHMetrics = 1 < nGlyphs = 3: glyph 1 has a full record; glyphs 2 and 3
	inherit glyph 1's advance width and each have their own leftSideBearing only."

	| bytes entry glyphs |
	bytes := ByteArray new: 8.
	self putUShort: 400 at: 1 in: bytes. "glyph 1 advanceWidth"
	self putShort:    5 at: 3 in: bytes. "glyph 1 leftSideBearing"
	self putShort:   15 at: 5 in: bytes. "glyph 2 leftSideBearing (no advance width stored)"
	self putShort:   25 at: 7 in: bytes. "glyph 3 leftSideBearing (no advance width stored)"
	entry := TTFontTableDirEntry onBytes: bytes.
	glyphs := (1 to: 3) collect: [ :_ |
		TTGlyph new boundsLeft: 0 boundsRight: 0 boundsTop: 0 boundsBottom: 0; yourself ].
	(TTHmtxTableParser on: entry glyphs: glyphs numHMetrics: 1) process.
	self assert: (glyphs at: 1) advanceWidth equals: 400.
	self assert: (glyphs at: 2) advanceWidth equals: 400.
	self assert: (glyphs at: 3) advanceWidth equals: 400.
	self assert: (glyphs at: 2) leftSideBearing equals: 15.
	self assert: (glyphs at: 3) leftSideBearing equals: 25
]

{ #category : 'tests - hmtx' }
TTFontParserTest >> testHmtxSetsAllGlyphMetrics [

	"numHMetrics = nGlyphs = 3: every glyph gets a full advanceWidth + leftSideBearing record."

	| bytes entry glyphs |
	bytes := ByteArray new: 12.
	self putUShort: 500 at: 1 in: bytes.  "glyph 1 advanceWidth"
	self putShort:   10 at: 3 in: bytes.  "glyph 1 leftSideBearing"
	self putUShort: 600 at: 5 in: bytes.  "glyph 2 advanceWidth"
	self putShort:   20 at: 7 in: bytes.  "glyph 2 leftSideBearing"
	self putUShort: 700 at: 9 in: bytes.  "glyph 3 advanceWidth"
	self putShort:   30 at: 11 in: bytes. "glyph 3 leftSideBearing"
	entry := TTFontTableDirEntry onBytes: bytes.
	glyphs := (1 to: 3) collect: [ :_ |
		TTGlyph new boundsLeft: 0 boundsRight: 0 boundsTop: 0 boundsBottom: 0; yourself ].
	(TTHmtxTableParser on: entry glyphs: glyphs numHMetrics: 3) process.
	self assert: (glyphs at: 1) advanceWidth equals: 500.
	self assert: (glyphs at: 2) advanceWidth equals: 600.
	self assert: (glyphs at: 3) advanceWidth equals: 700.
	self assert: (glyphs at: 1) leftSideBearing equals: 10.
	self assert: (glyphs at: 3) leftSideBearing equals: 30
]

{ #category : 'tests - kern' }
TTFontParserTest >> testKernProcessOSXFormat [

	"OS X kern table: version is ULong so its high UShort = 1 and low UShort = 0.
	Reading as 2×UShort gives nTables=0 → triggers OSX rewind path.
	1 kern pair via the type-0 subtable after OSX header."

	| bytes entry pairs |
	bytes := ByteArray new: 30.
	"Bytes 1-4: version ULong = 0x00010000; read as UShort version=1, UShort nTables=0 → OSX"
	self putULong: 16r00010000 at: 1 in: bytes.
	"Bytes 5-8: nTables ULong = 1"
	self putULong: 1 at: 5 in: bytes.
	"Bytes 9-12: subtable length ULong (any)"
	self putULong: 0 at: 9 in: bytes.
	"Bytes 13-14: coverage = 0 (type 0, horizontal)"
	self putUShort: 0 at: 13 in: bytes.
	"Bytes 15-16: tupleIndex = 0"
	self putUShort: 0 at: 15 in: bytes.
	"type-0 subtable at byte 17:"
	self putUShort: 1  at: 17 in: bytes. "nKernPairs=1"
	"skip 6: bytes 19-24"
	self putUShort: 10 at: 25 in: bytes. "pair.left"
	self putUShort: 20 at: 27 in: bytes. "pair.right"
	self putShort:   5 at: 29 in: bytes. "pair.value"
	entry := TTFontTableDirEntry onBytes: bytes.
	pairs := (TTKernTableParser on: entry) process.
	self assert: pairs size equals: 1.
	self assert: (pairs at: 1) left equals: 10.
	self assert: (pairs at: 1) right equals: 20.
	self assert: (pairs at: 1) value equals: 5
]

{ #category : 'tests - kern' }
TTFontParserTest >> testKernProcessWindowsFormat [

	"Windows kern table (version + nTables as UShort, nTables > 0).
	1 kern pair via the standard type-0 subtable path."

	| bytes entry pairs |
	bytes := ByteArray new: 24.
	self putUShort: 0 at: 1 in: bytes. "version"
	self putUShort: 1 at: 3 in: bytes. "nTables=1 → Windows format"
	self putUShort: 0 at: 5 in: bytes. "subtable number (skip)"
	self putUShort: 0 at: 7 in: bytes. "subtable length (skip)"
	bytes at: 9  put: 0. "covHigh=0 (format 0)"
	bytes at: 10 put: 0. "covLow=0 (horizontal, no cross-stream)"
	self putUShort: 1 at: 11 in: bytes. "nKernPairs=1"
	"skip 6: searchRange(2)+entrySelector(2)+rangeShift(2) = bytes 13-18"
	self putUShort: 3  at: 19 in: bytes. "pair.left"
	self putUShort: 4  at: 21 in: bytes. "pair.right"
	self putShort:  -2 at: 23 in: bytes. "pair.value"
	entry := TTFontTableDirEntry onBytes: bytes.
	pairs := (TTKernTableParser on: entry) process.
	self assert: pairs size equals: 1.
	self assert: (pairs at: 1) left equals: 3.
	self assert: (pairs at: 1) right equals: 4.
	self assert: (pairs at: 1) value equals: -2
]

{ #category : 'tests - loca' }
TTFontParserTest >> testLocaFormat0DoublesStoredOffsets [

	"format 0: each UShort is stored as offset/2; parser multiplies by 2.
	2 glyphs → 3 offsets stored as [0, 50, 100] → actual [0, 100, 200]."

	| bytes entry offsets |
	bytes := ByteArray new: 6.
	self putUShort: 0   at: 1 in: bytes.
	self putUShort: 50  at: 3 in: bytes.
	self putUShort: 100 at: 5 in: bytes.
	entry := TTFontTableDirEntry onBytes: bytes.
	offsets := (TTLocaTableParser on: entry format: 0 nGlyphs: 2) process.
	self assert: offsets size equals: 3.
	self assert: (offsets at: 1) equals: 0.
	self assert: (offsets at: 2) equals: 100.
	self assert: (offsets at: 3) equals: 200
]

{ #category : 'tests - loca' }
TTFontParserTest >> testLocaFormat1ReturnsLongOffsets [

	"format 1: each ULong is the actual byte offset; no scaling applied.
	2 glyphs → 3 offsets [0, 1000, 2000]."

	| bytes entry offsets |
	bytes := ByteArray new: 12.
	self putULong: 0    at: 1 in: bytes.
	self putULong: 1000 at: 5 in: bytes.
	self putULong: 2000 at: 9 in: bytes.
	entry := TTFontTableDirEntry onBytes: bytes.
	offsets := (TTLocaTableParser on: entry format: 1 nGlyphs: 2) process.
	self assert: offsets size equals: 3.
	self assert: (offsets at: 1) equals: 0.
	self assert: (offsets at: 2) equals: 1000.
	self assert: (offsets at: 3) equals: 2000
]

{ #category : 'tests - cmap' }
TTFontParserTest >> testParseCmapFormat0Returns256Elements [

	"cmap format 0: 6-byte header + 256 glyph-index bytes."

	| bytes entry cmap |
	bytes := ByteArray new: 262.
	self putUShort: 0 at: 1 in: bytes.   "format = 0"
	self putUShort: 262 at: 3 in: bytes. "length = 262"
	"bytes 5-6 = version (skipped)"
	"bytes 7..262 = glyph indices (all zero by default)"
	bytes at: 72 put: 5. "ASCII 'A' (codePoint 65) → glyph 5 at index 65+7=72"
	entry := TTFontTableDirEntry onBytes: bytes.
	cmap := (TTCmapTableParser on: entry) parseFormat.
	self assert: cmap size equals: 256.
	self assert: (cmap at: 66) equals: 5
]

{ #category : 'tests - cmap' }
TTFontParserTest >> testParseCmapFormat6ReturnsTrimmedArray [

	"cmap format 6: firstCode=32, entryCount=3 → array size = 32+3 = 35."

	| bytes entry cmap |
	bytes := ByteArray new: 16.
	self putUShort: 6 at: 1 in: bytes.  "format = 6"
	self putUShort: 16 at: 3 in: bytes. "length"
	"version at 5-6 (skipped)"
	self putUShort: 32 at: 7 in: bytes. "firstCode = 32"
	self putUShort: 3 at: 9 in: bytes.  "entryCount = 3"
	self putUShort: 10 at: 11 in: bytes. "glyph 10 for codePoint 33"
	self putUShort: 20 at: 13 in: bytes. "glyph 20 for codePoint 34"
	self putUShort: 30 at: 15 in: bytes. "glyph 30 for codePoint 35"
	entry := TTFontTableDirEntry onBytes: bytes.
	cmap := (TTCmapTableParser on: entry) parseFormat.
	self assert: cmap size equals: 35.
	self assert: (cmap at: 33) equals: 10.
	self assert: (cmap at: 34) equals: 20.
	self assert: (cmap at: 35) equals: 30
]

{ #category : 'tests - head' }
TTFontParserTest >> testParseFontHeaderBounds [

	"head table: xMin=0, yMin=0, xMax=100, yMax=200 at bytes 37-44."

	| bytes entry data |
	bytes := ByteArray new: 52.
	self putUShort: 1000 at: 19 in: bytes. "unitsPerEm"
	self putShort: 0 at: 37 in: bytes.   "xMin"
	self putShort: 0 at: 39 in: bytes.   "yMin"
	self putShort: 100 at: 41 in: bytes. "xMax"
	self putShort: 200 at: 43 in: bytes. "yMax"
	self putShort: 0 at: 51 in: bytes.   "indexToLocFormat"
	entry := TTFontTableDirEntry onBytes: bytes.
	data := (TTHeadTableParser on: entry) process.
	self assert: (data at: #bounds) equals: (0 @ 0 corner: 100 @ 200)
]

{ #category : 'tests - head' }
TTFontParserTest >> testParseFontHeaderIndexToLocFormat [

	| bytes entry data |
	bytes := ByteArray new: 52.
	self putUShort: 2048 at: 19 in: bytes.
	self putShort: 1 at: 51 in: bytes. "indexToLocFormat=1 (long offsets)"
	entry := TTFontTableDirEntry onBytes: bytes.
	data := (TTHeadTableParser on: entry) process.
	self assert: (data at: #indexToLocFormat) equals: 1
]

{ #category : 'tests - head' }
TTFontParserTest >> testParseFontHeaderUnitsPerEm [

	| bytes entry data |
	bytes := ByteArray new: 52.
	self putUShort: 2048 at: 19 in: bytes.
	entry := TTFontTableDirEntry onBytes: bytes.
	data := (TTHeadTableParser on: entry) process.
	self assert: (data at: #units) equals: 2048
]

{ #category : 'tests - glyf' }
TTFontParserTest >> testParseGlyphFlagsNoRepeat [

	"3 flags, no repeat bit set."

	| bytes entry flags |
	bytes := ByteArray with: 1 with: 2 with: 4.
	entry := TTFontTableDirEntry onBytes: bytes.
	flags := (TTGlyfTableParser on: entry nGlyphs: 0 offsets: #()) parseGlyphFlags: 3.
	self assert: flags size equals: 3.
	self assert: (flags at: 1) equals: 1.
	self assert: (flags at: 2) equals: 2.
	self assert: (flags at: 3) equals: 4
]

{ #category : 'tests - glyf' }
TTFontParserTest >> testParseGlyphFlagsWithRepeat [

	"Flag 0x09 (repeat bit set) with repCount=1 → two entries of 0x09, then 0x06."

	| bytes entry flags |
	bytes := ByteArray with: 9 with: 1 with: 6.
	entry := TTFontTableDirEntry onBytes: bytes.
	flags := (TTGlyfTableParser on: entry nGlyphs: 0 offsets: #()) parseGlyphFlags: 3.
	self assert: flags size equals: 3.
	self assert: (flags at: 1) equals: 9.
	self assert: (flags at: 2) equals: 9.
	self assert: (flags at: 3) equals: 6
]

{ #category : 'tests - hhea' }
TTFontParserTest >> testParseHorizontalHeaderAscent [

	"hhea table: ascent at bytes 5-6."

	| bytes entry data |
	bytes := ByteArray new: 36.
	self putShort: 800 at: 5 in: bytes.
	self putShort: 0 at: 7 in: bytes.
	self putShort: 50 at: 9 in: bytes.
	self putUShort: 100 at: 35 in: bytes.
	entry := TTFontTableDirEntry onBytes: bytes.
	data := (TTHheaTableParser on: entry) process.
	self assert: (data at: #ascent) equals: 800
]

{ #category : 'tests - hhea' }
TTFontParserTest >> testParseHorizontalHeaderDescent [

	| bytes entry data |
	bytes := ByteArray new: 36.
	self putShort: 0 at: 5 in: bytes.
	self putShort: -200 at: 7 in: bytes.
	self putShort: 0 at: 9 in: bytes.
	self putUShort: 1 at: 35 in: bytes.
	entry := TTFontTableDirEntry onBytes: bytes.
	data := (TTHheaTableParser on: entry) process.
	self assert: (data at: #descent) equals: -200
]

{ #category : 'tests - hhea' }
TTFontParserTest >> testParseHorizontalHeaderLineGapAndNumHMetrics [

	| bytes entry data |
	bytes := ByteArray new: 36.
	self putShort: 0 at: 5 in: bytes.
	self putShort: 0 at: 7 in: bytes.
	self putShort: 33 at: 9 in: bytes.    "lineGap"
	self putUShort: 512 at: 35 in: bytes. "numHMetrics"
	entry := TTFontTableDirEntry onBytes: bytes.
	data := (TTHheaTableParser on: entry) process.
	self assert: (data at: #lineGap) equals: 33.
	self assert: (data at: #numHMetrics) equals: 512
]

{ #category : 'tests - kern' }
TTFontParserTest >> testParseKernPairsType0ReturnsPairs [

	"2 kern pairs: (10,20,-5) and (3,7,15)."

	| bytes entry pairs |
	bytes := ByteArray new: 20.
	self putUShort: 2 at: 1 in: bytes.   "nKernPairs"
	"skip 6 bytes (searchRange+entrySelector+rangeShift)"
	self putUShort: 10 at: 9 in: bytes.  "pair1.left"
	self putUShort: 20 at: 11 in: bytes. "pair1.right"
	self putShort: -5 at: 13 in: bytes.  "pair1.value"
	self putUShort: 3 at: 15 in: bytes.  "pair2.left"
	self putUShort: 7 at: 17 in: bytes.  "pair2.right"
	self putShort: 15 at: 19 in: bytes.  "pair2.value"
	entry := TTFontTableDirEntry onBytes: bytes.
	pairs := (TTKernTableParser on: entry) parseSubTableType0.
	self assert: pairs size equals: 2.
	self assert: (pairs at: 1) left equals: 10.
	self assert: (pairs at: 1) right equals: 20.
	self assert: (pairs at: 1) value equals: -5.
	self assert: (pairs at: 2) left equals: 3.
	self assert: (pairs at: 2) value equals: 15
]

{ #category : 'tests - maxp' }
TTFontParserTest >> testParseMaximumProfileReturnsGlyphCount [

	"maxp table: 4-byte version (skipped) + 2-byte numGlyphs."

	| bytes entry |
	bytes := ByteArray new: 6.
	self putUShort: 300 at: 5 in: bytes. "numGlyphs = 300"
	entry := TTFontTableDirEntry onBytes: bytes.
	self assert: ((TTMaxpTableParser on: entry) process) equals: 300
]

{ #category : 'tests - maxp' }
TTFontParserTest >> testParseMaximumProfileSmallValue [

	| bytes entry |
	bytes := ByteArray new: 6.
	self putUShort: 1 at: 5 in: bytes.
	entry := TTFontTableDirEntry onBytes: bytes.
	self assert: ((TTMaxpTableParser on: entry) process) equals: 1
]

{ #category : 'tests - name' }
TTFontParserTest >> testParseNamingTableFamilyName [

	"One Macintosh record: pID=1, sID=0, lID=0, nID=1 (familyName), 'Test'."

	| bytes entry strings |
	bytes := ByteArray new: 22.
	self putUShort: 0 at: 1 in: bytes.  "format = 0"
	self putUShort: 1 at: 3 in: bytes.  "nRecords = 1"
	self putUShort: 18 at: 5 in: bytes. "storageOffset (from table start = offset 1)"
	self putUShort: 1 at: 7 in: bytes.  "pID = 1 (Macintosh)"
	self putUShort: 0 at: 9 in: bytes.  "sID = 0"
	self putUShort: 0 at: 11 in: bytes. "lID = 0 (English)"
	self putUShort: 1 at: 13 in: bytes. "nID = 1 (familyName)"
	self putUShort: 4 at: 15 in: bytes. "length = 4"
	self putUShort: 0 at: 17 in: bytes. "offset = 0"
	"string data at storageOffset+initialOffset = 18+1 = 19"
	bytes at: 19 put: 84. "T"
	bytes at: 20 put: 101. "e"
	bytes at: 21 put: 115. "s"
	bytes at: 22 put: 116. "t"
	entry := TTFontTableDirEntry onBytes: bytes.
	strings := (TTNameTableParser on: entry) process.
	self assert: strings size equals: 8.
	self assert: (strings at: 2) equals: 'Test'
]

{ #category : 'tests - selectGlyph' }
TTFontParserTest >> testSelectGlyphDashFallsBackWhenWideMinusAbsent [

	"codePoint 45 ($-). Preferred 16r2212 maps to unknownGlyph, so fallback to index 45."

	| characterMap glyphs unknownGlyph dashGlyph result |
	unknownGlyph := 'unknown'.
	dashGlyph := 'dash'.
	glyphs := Array new: 5 withAll: unknownGlyph.
	glyphs at: 2 put: dashGlyph.
	characterMap := Array new: 16r2213 withAll: 0. "0 → glyphs at: 1 = unknownGlyph"
	characterMap at: 46 put: 1. "codePoint 45 + 1 → glyphIndex 1 → glyphs at: 2 = dashGlyph"
	result := TTFontParser
		          selectGlyphFor: 45
		          from: characterMap
		          glyphs: glyphs
		          unknownGlyph: unknownGlyph.
	self assert: result equals: dashGlyph
]

{ #category : 'tests - selectGlyph' }
TTFontParserTest >> testSelectGlyphDashPrefersWideMinus [

	"codePoint 45 ($-). Preferred 16r2212 maps to a real glyph."

	| characterMap glyphs unknownGlyph wideMinus result |
	unknownGlyph := 'unknown'.
	wideMinus := 'wide-minus'.
	glyphs := Array new: 5 withAll: unknownGlyph.
	glyphs at: 3 put: wideMinus.
	characterMap := Array new: 16r2213 withAll: 0.
	characterMap at: 46 put: 0. "codePoint 45 → unknownGlyph"
	characterMap at: 16r2213 put: 2. "16r2212+1 → glyphIndex 2 → glyphs at: 3 = wideMinus"
	result := TTFontParser
		          selectGlyphFor: 45
		          from: characterMap
		          glyphs: glyphs
		          unknownGlyph: unknownGlyph.
	self assert: result equals: wideMinus
]
