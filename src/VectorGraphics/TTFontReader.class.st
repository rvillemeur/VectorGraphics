"
Orchestrates TrueType font parsing: locates all tables in the binary font data, creates
the appropriate TTFontParser subclass for each table, runs them in dependency order, and
assembles the results into a TTFontDescription.

## Entry point
  `TTFontReader class >> readTTFFrom: aByteArray`

## Pipeline (readFrom:fromOffset:)
1.  `buildTableDirectory:offset:` — scan the font's table directory into a tag→entry Dictionary
2.  TTHeadTableParser     → bounds, unitsPerEm, indexToLocFormat
3.  TTMaxpTableParser     → nGlyphs
4.  TTNameTableParser     → font name strings
5.  TTHheaTableParser     → ascent, descent, lineGap, numHMetrics
6.  TTLocaTableParser     → glyph byte-offset array (needs indexToLocFormat + nGlyphs)
7.  TTCmapTableParser     → Unicode character map (nil → error)
8.  TTGlyfTableParser     → Array of TTGlyph (needs nGlyphs + loca offsets)
9.  TTHmtxTableParser     → mutates glyphs with advance widths (needs numHMetrics)
10. TTKernTableParser     → kern pairs (optional table; absent → empty array)
11. `mapAndStoreGlyphsUsing:glyphs:` → UTF-8 glyph map stored in TTFontDescription

## Key instVar
- `fontDescription`  TTFontDescription being assembled
"
Class {
	#name : 'TTFontReader',
	#superclass : 'Object',
	#instVars : [
		'fontDescription'
	],
	#category : 'VectorGraphics-TrueType',
	#package : 'VectorGraphics',
	#tag : 'TrueType'
}

{ #category : 'instance creation' }
TTFontReader class >> readTTFFrom: aByteArray [

	^ self new readTTFFrom: aByteArray
]

{ #category : 'private' }
TTFontReader >> buildTableDirectory: fontData offset: anOffset [

	"Scan the font's table directory and return a Dictionary mapping 4-char tag strings
	to TTFontTableDirEntry instances. Each entry in the directory is 16 bytes."

	| numTables pos directory tagStr |
	numTables := fontData shortAt: 5 + anOffset bigEndian: true.
	directory := Dictionary new: numTables.
	pos := 13 + anOffset.
	1 to: numTables do: [ :i |
		tagStr := String new: 4.
		1 to: 4 do: [ :j | tagStr at: j put: (Character value: (fontData byteAt: pos + j - 1)) ].
		directory at: tagStr put: (TTFontTableDirEntry on: fontData at: pos).
		pos := pos + 16 ].
	^ directory
]

{ #category : 'private' }
TTFontReader >> codePointsToMapIn: characterMap [
	"The code points worth asking a glyph for: the ones with an entry of their own, plus the
	 substitution sources, which reach a glyph through another code point and so hold zero in
	 the map. Everything else resolves to the unknown glyph, and storing it would copy that
	 glyph's contour data once per unmapped code point."

	| codePoints |
	codePoints := OrderedCollection new.
	1 to: characterMap size do: [ :index |
		(characterMap at: index) = 0 ifFalse: [ codePoints add: index - 1 ] ].
	codePoints addAll: TTFontParser glyphSubstitutions keys.
	^ codePoints
]

{ #category : 'private' }
TTFontReader >> mapAndStoreGlyphsUsing: characterMap glyphs: glyphs [
	"Build the UTF-8 to glyph map and store it in fontDescription.
	 Only the code points the font really maps get a slot. Storing the unknown glyph for the
	 rest would write a copy of its contour data for every code point of the character map:
	 65536 copies for a font of a hundred glyphs. A code point with no slot is answered the
	 unknown glyph's position by
	 TTFontDescription >> contourDataPositionForByte1:byte2:byte3:byte4: instead."

	| glyphsByUtf8 unknownGlyph spaceGlyph |
	unknownGlyph := glyphs first.
	glyphsByUtf8 := Array new: 256.
	spaceGlyph := nil.
	(self codePointsToMapIn: characterMap) do: [ :codePoint |
		| glyph |
		glyph := TTFontParser
			         selectGlyphFor: codePoint
			         from: characterMap
			         glyphs: glyphs
			         unknownGlyph: unknownGlyph.
		glyph == unknownGlyph ifFalse: [
			self store: glyph for: codePoint in: glyphsByUtf8.
			codePoint = Character space codePoint ifTrue: [ spaceGlyph := glyph ] ] ].
	spaceGlyph ifNotNil: [
		self whitespaceCodePoints do: [ :codePoint |
			glyphsByUtf8 at: codePoint + 1 put: spaceGlyph ] ].
	fontDescription
		glyphsByUtf8Bytes: glyphsByUtf8
		unknownGlyph: unknownGlyph
]

{ #category : 'private' }
TTFontReader >> readFrom: fontData fromOffset: offset [

	| tables headData nGlyphs hheaData glyphOffsets glyphs characterMap |
	tables := self buildTableDirectory: fontData offset: offset.

	"Validate required tables are present"
	#( 'head' 'maxp' 'name' 'hhea' 'loca' 'cmap' 'glyf' 'hmtx' ) do: [ :tag |
		(tables includesKey: tag) ifFalse: [
			self error: 'Missing required TrueType table: ' , tag ] ].

	headData := (TTHeadTableParser on: (tables at: 'head')) process.
	fontDescription
		setBounds: (headData at: #bounds)
		unitsPerEm: (headData at: #units).

	nGlyphs := (TTMaxpTableParser on: (tables at: 'maxp')) process.

	fontDescription setStrings: ((TTNameTableParser on: (tables at: 'name')) process).

	hheaData := (TTHheaTableParser on: (tables at: 'hhea')) process.
	fontDescription
		setAscent: (hheaData at: #ascent)
		descent: (hheaData at: #descent)
		lineGap: (hheaData at: #lineGap).

	glyphOffsets := (TTLocaTableParser
		                 on: (tables at: 'loca')
		                 format: (headData at: #indexToLocFormat)
		                 nGlyphs: nGlyphs) process.

	characterMap := (TTCmapTableParser on: (tables at: 'cmap')) process.
	characterMap ifNil: [
		^ self error: 'This font has no Unicode character mappings' ].

	glyphs := (TTGlyfTableParser
		           on: (tables at: 'glyf')
		           nGlyphs: nGlyphs
		           offsets: glyphOffsets) process.

	(TTHmtxTableParser
		 on: (tables at: 'hmtx')
		 glyphs: glyphs
		 numHMetrics: (hheaData at: #numHMetrics)) process.

	"kern is optional — absent in many fonts"
	(tables at: 'kern' ifAbsent: [ nil ])
		ifNotNil: [ :e | (TTKernTableParser on: e) process ].
	"kern pairs refer to glyph indices not Unicode code points; remapping not yet implemented."

	self mapAndStoreGlyphsUsing: characterMap glyphs: glyphs
]

{ #category : 'public' }
TTFontReader >> readTTFFrom: aByteArray [

	fontDescription := TTFontDescription new.
	self readFrom: aByteArray fromOffset: 0.
	^ fontDescription
]

{ #category : 'private' }
TTFontReader >> store: aGlyph for: aCodePoint in: glyphsByUtf8 [
	"Put aGlyph in the slot of aCodePoint's last UTF-8 byte, building the 256 slot arrays the
	 earlier bytes are descended through.
	 https://developer.apple.com/fonts/TrueType-Reference-Manual/RM07/appendixB.html"

	| array prevByte |
	array := glyphsByUtf8.
	prevByte := nil.
	Character
		evaluate: [ :byte |
			prevByte notNil ifTrue: [
				array := (array at: prevByte + 1) ifNil: [
					         array at: prevByte + 1 put: (Array new: 256) ] ].
			prevByte := byte ]
		withUtf8BytesOf: aCodePoint.
	array at: prevByte + 1 put: aGlyph
]

{ #category : 'constants' }
TTFontReader >> whitespaceCodePoints [
	"The separators that carry no glyph of their own — tab, line feed, vertical tab, form feed
	 and carriage return — and are drawn as a space so that a line advances across them."

	^ #( 9 10 11 12 13 )
]
