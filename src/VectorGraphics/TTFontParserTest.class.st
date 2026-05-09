Class {
	#name : 'TTFontParserTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-tests',
	#package : 'VectorGraphics',
	#tag : 'tests'
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
TTFontParserTest >> putUShort: value at: pos in: bytes [

	"Write an unsigned 16-bit big-endian integer."

	bytes at: pos put: ((value bitShift: -8) bitAnd: 255).
	bytes at: pos + 1 put: (value bitAnd: 255)
]

{ #category : 'tests' }
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
	cmap := TTFontParser parseCmap: entry.
	self assert: cmap size equals: 256.
	self assert: (cmap at: 66) equals: 5
]

{ #category : 'tests' }
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
	cmap := TTFontParser parseCmap: entry.
	self assert: cmap size equals: 35.
	self assert: (cmap at: 33) equals: 10.
	self assert: (cmap at: 34) equals: 20.
	self assert: (cmap at: 35) equals: 30
]

{ #category : 'tests' }
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
	data := TTFontParser parseFontHeader: entry.
	self assert: (data at: #bounds) equals: (0 @ 0 corner: 100 @ 200)
]

{ #category : 'tests' }
TTFontParserTest >> testParseFontHeaderIndexToLocFormat [

	| bytes entry data |
	bytes := ByteArray new: 52.
	self putUShort: 2048 at: 19 in: bytes.
	self putShort: 1 at: 51 in: bytes. "indexToLocFormat=1 (long offsets)"
	entry := TTFontTableDirEntry onBytes: bytes.
	data := TTFontParser parseFontHeader: entry.
	self assert: (data at: #indexToLocFormat) equals: 1
]

{ #category : 'tests' }
TTFontParserTest >> testParseFontHeaderUnitsPerEm [

	| bytes entry data |
	bytes := ByteArray new: 52.
	self putUShort: 2048 at: 19 in: bytes.
	entry := TTFontTableDirEntry onBytes: bytes.
	data := TTFontParser parseFontHeader: entry.
	self assert: (data at: #units) equals: 2048
]

{ #category : 'tests' }
TTFontParserTest >> testParseGlyphFlagsNoRepeat [

	"3 flags, no repeat bit set."

	| bytes entry flags |
	bytes := ByteArray with: 1 with: 2 with: 4.
	entry := TTFontTableDirEntry onBytes: bytes.
	flags := TTFontParser parseGlyphFlags: entry size: 3.
	self assert: flags size equals: 3.
	self assert: (flags at: 1) equals: 1.
	self assert: (flags at: 2) equals: 2.
	self assert: (flags at: 3) equals: 4
]

{ #category : 'tests' }
TTFontParserTest >> testParseGlyphFlagsWithRepeat [

	"Flag 0x09 (repeat bit set) with repCount=1 → two entries of 0x09, then 0x06."

	| bytes entry flags |
	bytes := ByteArray with: 9 with: 1 with: 6.
	entry := TTFontTableDirEntry onBytes: bytes.
	flags := TTFontParser parseGlyphFlags: entry size: 3.
	self assert: flags size equals: 3.
	self assert: (flags at: 1) equals: 9.
	self assert: (flags at: 2) equals: 9.
	self assert: (flags at: 3) equals: 6
]

{ #category : 'tests' }
TTFontParserTest >> testParseHorizontalHeaderAscent [

	"hhea table: ascent at bytes 5-6."

	| bytes entry data |
	bytes := ByteArray new: 36.
	self putShort: 800 at: 5 in: bytes.
	self putShort: 0 at: 7 in: bytes.
	self putShort: 50 at: 9 in: bytes.
	self putUShort: 100 at: 35 in: bytes.
	entry := TTFontTableDirEntry onBytes: bytes.
	data := TTFontParser parseHorizontalHeader: entry.
	self assert: (data at: #ascent) equals: 800
]

{ #category : 'tests' }
TTFontParserTest >> testParseHorizontalHeaderDescent [

	| bytes entry data |
	bytes := ByteArray new: 36.
	self putShort: 0 at: 5 in: bytes.
	self putShort: -200 at: 7 in: bytes.
	self putShort: 0 at: 9 in: bytes.
	self putUShort: 1 at: 35 in: bytes.
	entry := TTFontTableDirEntry onBytes: bytes.
	data := TTFontParser parseHorizontalHeader: entry.
	self assert: (data at: #descent) equals: -200
]

{ #category : 'tests' }
TTFontParserTest >> testParseHorizontalHeaderLineGapAndNumHMetrics [

	| bytes entry data |
	bytes := ByteArray new: 36.
	self putShort: 0 at: 5 in: bytes.
	self putShort: 0 at: 7 in: bytes.
	self putShort: 33 at: 9 in: bytes.    "lineGap"
	self putUShort: 512 at: 35 in: bytes. "numHMetrics"
	entry := TTFontTableDirEntry onBytes: bytes.
	data := TTFontParser parseHorizontalHeader: entry.
	self assert: (data at: #lineGap) equals: 33.
	self assert: (data at: #numHMetrics) equals: 512
]

{ #category : 'tests' }
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
	pairs := TTFontParser parseKernPairsType0: entry.
	self assert: pairs size equals: 2.
	self assert: (pairs at: 1) left equals: 10.
	self assert: (pairs at: 1) right equals: 20.
	self assert: (pairs at: 1) value equals: -5.
	self assert: (pairs at: 2) left equals: 3.
	self assert: (pairs at: 2) value equals: 15
]

{ #category : 'tests' }
TTFontParserTest >> testParseMaximumProfileReturnsGlyphCount [

	"maxp table: 4-byte version (skipped) + 2-byte numGlyphs."

	| bytes entry |
	bytes := ByteArray new: 6.
	self putUShort: 300 at: 5 in: bytes. "numGlyphs = 300"
	entry := TTFontTableDirEntry onBytes: bytes.
	self assert: (TTFontParser parseMaximumProfile: entry) equals: 300
]

{ #category : 'tests' }
TTFontParserTest >> testParseMaximumProfileSmallValue [

	| bytes entry |
	bytes := ByteArray new: 6.
	self putUShort: 1 at: 5 in: bytes.
	entry := TTFontTableDirEntry onBytes: bytes.
	self assert: (TTFontParser parseMaximumProfile: entry) equals: 1
]

{ #category : 'tests' }
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
	strings := TTFontParser parseNamingTable: entry.
	self assert: strings size equals: 8.
	self assert: (strings at: 2) equals: 'Test'
]
