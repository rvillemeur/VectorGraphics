"
Pure byte-parsing helpers extracted from TTFontReader.
Each class-side method takes a TTFontTableDirEntry and returns structured data
(a Dictionary) with no side effects on any font description.
This separation makes table parsing independently testable.
"
Class {
	#name : 'TTFontParser',
	#superclass : 'Object',
	#category : 'VectorGraphics-TrueType',
	#package : 'VectorGraphics',
	#tag : 'TrueType'
}

{ #category : 'parsing' }
TTFontParser class >> parseFontHeader: entry [

	"Parse the 'head' table. Returns a Dictionary with:
		#units         — unitsPerEm (UShort)
		#bounds        — Rectangle (xMin@yMin corner: xMax@yMax)
		#indexToLocFormat — SHORT (0=short offsets, 1=long offsets)"

	| units origin corner indexToLocFormat |
	entry skip: 18. "version(4) + revision(4) + checkSumAdj(4) + magic(4) + flags(2)"
	units := entry nextUShort.
	entry skip: 16. "created(8) + modified(8)"
	origin := entry nextShort @ entry nextShort.
	corner := entry nextShort @ entry nextShort.
	entry skip: 6. "macStyle(2) + lowestRecPPEM(2) + fontDirHint(2)"
	indexToLocFormat := entry nextShort.
	^ Dictionary with: #units -> units
	             with: #bounds -> (origin corner: corner)
	             with: #indexToLocFormat -> indexToLocFormat
]

{ #category : 'parsing' }
TTFontParser class >> parseHorizontalHeader: entry [

	"Parse the 'hhea' table. Returns a Dictionary with:
		#ascent        — SHORT
		#descent       — SHORT (usually negative)
		#lineGap       — SHORT
		#numHMetrics   — USHORT"

	| ascent descent lineGap numHMetrics |
	entry skip: 4. "version"
	ascent := entry nextShort.
	descent := entry nextShort.
	lineGap := entry nextShort.
	entry skip: 24.
	"advanceWidthMax(2) + minLSB(2) + minRSB(2) + xMaxExtent(2)
	 + caretSlopeRise(2) + caretSlopeRun(2) + reserved×5(10) + metricDataFormat(2)"
	numHMetrics := entry nextUShort.
	^ Dictionary
		  with: #ascent -> ascent
		  with: #descent -> descent
		  with: #lineGap -> lineGap
		  with: #numHMetrics -> numHMetrics
]

{ #category : 'parsing' }
TTFontParser class >> parseMaximumProfile: entry [

	"Parse the 'maxp' table. Returns the glyph count (UShort)."

	entry skip: 4. "version"
	^ entry nextUShort
]
