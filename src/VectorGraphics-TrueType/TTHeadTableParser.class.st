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
	#category : 'VectorGraphics-TrueType-Reading',
	#package : 'VectorGraphics-TrueType',
	#tag : 'Reading'
}

{ #category : 'parsing' }
TTHeadTableParser >> process [
	| units origin corner indexToLocFormat macStyle |
	entry skip: 18. "version(4) + revision(4) + checkSumAdj(4) + magic(4) + flags(2)"
	units := entry nextUShort.
	entry skip: 16. "created(8) + modified(8)"
	origin := entry nextShort @ entry nextShort.
	corner := entry nextShort @ entry nextShort.
	macStyle := entry nextUShort.
	entry skip: 4. "lowestRecPPEM(2) + fontDirHint(2)"
	indexToLocFormat := entry nextShort.
	^ Dictionary newFrom: {
			  (#units -> units).
			  (#bounds -> (origin corner: corner)).
			  (#indexToLocFormat -> indexToLocFormat).
			  (#macStyle -> macStyle) }
]
