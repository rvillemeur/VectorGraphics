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
TTFontReader >> mapAndStoreGlyphsUsing: characterMap glyphs: glyphs [

	"Build the UTF-8 → glyph map and store it in fontDescription.
	https://developer.apple.com/fonts/TrueType-Reference-Manual/RM07/appendixB.html"

	| glyphsByUTF8 unknownGlyph spaceGlyph mapSize |
	unknownGlyph := glyphs first.
	mapSize := characterMap size.
	glyphsByUTF8 := Array new: 256.
	0 to: mapSize - 1 do: [ :codePoint |
		| g array prevByte |
		g := TTFontParser
			     selectGlyphFor: codePoint
			     from: characterMap
			     glyphs: glyphs
			     unknownGlyph: unknownGlyph.
		array := glyphsByUTF8.
		prevByte := nil.
		Character
			evaluate: [ :byte |
				prevByte notNil ifTrue: [
					array := (array at: prevByte + 1) ifNil: [
						         array at: prevByte + 1 put: (Array new: 256) ] ].
				prevByte := byte ]
			withUtf8BytesOf: codePoint.
		array at: prevByte + 1 put: g.
		codePoint = 32 ifTrue: [ spaceGlyph := g ] ].

	"Map whitespace separators (tab, newline, etc.) to the space glyph"
	{ 9. 10. 11. 12. 13 } do: [ :cp |
		glyphsByUTF8 at: cp + 1 put: spaceGlyph ].

	fontDescription
		glyphsByUtf8Bytes: glyphsByUTF8
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
