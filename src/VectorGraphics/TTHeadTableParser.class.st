"
Parser for the TrueType 'head' (Font Header) table.

Returns a Dictionary with three keys:
  #units           — unitsPerEm (UShort)
  #bounds          — Rectangle (xMin@yMin corner: xMax@yMax) in design units
  #indexToLocFormat — Short (0 = short offsets in loca, 1 = long offsets)

TTFontReader uses #indexToLocFormat to construct TTLocaTableParser, and #bounds + #units
to initialize TTFontDescription.
"
Class {
	#name : 'TTHeadTableParser',
	#superclass : 'TTFontParser',
	#category : 'VectorGraphics-TrueType',
	#package : 'VectorGraphics',
	#tag : 'TrueType'
}

{ #category : 'parsing' }
TTHeadTableParser >> process [

	| units origin corner indexToLocFormat |
	entry skip: 18. "version(4) + revision(4) + checkSumAdj(4) + magic(4) + flags(2)"
	units := entry nextUShort.
	entry skip: 16. "created(8) + modified(8)"
	origin := entry nextShort @ entry nextShort.
	corner := entry nextShort @ entry nextShort.
	entry skip: 6. "macStyle(2) + lowestRecPPEM(2) + fontDirHint(2)"
	indexToLocFormat := entry nextShort.
	^ Dictionary
		  with: #units -> units
		  with: #bounds -> (origin corner: corner)
		  with: #indexToLocFormat -> indexToLocFormat
]
