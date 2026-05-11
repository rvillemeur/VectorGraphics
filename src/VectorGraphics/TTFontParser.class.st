"
Abstract base class for TrueType table parsers.

Each concrete subclass parses one named TrueType table from a TTFontTableDirEntry cursor and
returns structured data via a single `process` method. TTFontReader creates the appropriate
subclass for each table, passes it the entry (and any inter-stage inputs), and calls `process`.

## Protocol
  `TTXxxTableParser on: entry` — factory constructor (shared by most subclasses)
  `process` — parse the table; return type is subclass-specific

## Subclasses
  TTHeadTableParser  — 'head': bounds, unitsPerEm, indexToLocFormat
  TTMaxpTableParser  — 'maxp': glyph count
  TTHheaTableParser  — 'hhea': ascent, descent, lineGap, numHMetrics
  TTNameTableParser  — 'name': font name strings
  TTCmapTableParser  — 'cmap': Unicode character map (subtable selection + format parsing)
  TTLocaTableParser  — 'loca': glyph offset array (needs indexToLocFormat + nGlyphs)
  TTGlyfTableParser  — 'glyf': TTGlyph array (needs nGlyphs + loca offsets)
  TTHmtxTableParser  — 'hmtx': advance widths + side bearings (mutates glyphs array)
  TTKernTableParser  — 'kern': kern pairs (handles both Windows and OSX table variants)

## Utility (class-side)
  `selectGlyphFor:from:glyphs:unknownGlyph:` — Unicode glyph substitution for dash/star;
  not table-specific, kept here for discoverability.
"
Class {
	#name : 'TTFontParser',
	#superclass : 'Object',
	#instVars : [
		'entry'
	],
	#category : 'VectorGraphics-TrueType',
	#package : 'VectorGraphics',
	#tag : 'TrueType'
}

{ #category : 'instance creation' }
TTFontParser class >> on: anEntry [

	^ self new initWithEntry: anEntry
]

{ #category : 'utility' }
TTFontParser class >> selectGlyphFor: codePoint from: characterMap glyphs: glyphs unknownGlyph: unknownGlyph [

	"Select the best glyph for codePoint. Substitutes wide minus and centered asterisk
	Unicode code points for the ASCII dash and star. Falls back to the original codePoint
	if the preferred substitute is absent from the font."

	| preferredCodePoint g |
	preferredCodePoint := codePoint.
	codePoint = $- codePoint ifTrue: [ preferredCodePoint := 16r2212 ].
	codePoint = $* codePoint ifTrue: [ preferredCodePoint := 16r2217 ].
	g := glyphs at: (characterMap at: preferredCodePoint + 1) + 1 ifAbsent: [ unknownGlyph ].
	g == unknownGlyph ifTrue: [
		g := glyphs at: (characterMap at: codePoint + 1) + 1 ifAbsent: [ unknownGlyph ] ].
	^ g
]

{ #category : 'initialization' }
TTFontParser >> initWithEntry: anEntry [

	entry := anEntry
]

{ #category : 'parsing' }
TTFontParser >> process [

	^ self subclassResponsibility
]
