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
