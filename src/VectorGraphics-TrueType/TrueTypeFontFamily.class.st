"
A FontFamily backed by one or more TrueType font files, grouped by emphasis (regular/bold/italic/...).

TrueTypeFontFamily holds the TTFontDescription objects for all emphasis variants of a single
typeface. The regular (emphasis=0) variant is the `baseTTFontDescription`; others are stored
in `ttFontDescriptionsByEmphasis`.

An instance is built from one description with `baseTTFontDescription:` and learns its other
faces through `addTTFontDescription:`; `FontFamily class >> addFamily:` registers it under its
family name. Reading a whole directory of .ttf files was a Cuis entry point that went with the
`DirectoryEntry` protocol Pharo does not have, so a caller reads a file with `TTFontReader` and
registers the family itself.

## Key instVars
- `baseTTFontDescription`        TTFontDescription — the regular (emphasis 0) variant
- `ttFontDescriptionsByEmphasis` Dictionary — emphasis code → TTFontDescription

## Key methods
- `baseTTFontDescription: aTTFontDescription` — initialiser
- `addTTFontDescription: aTTFontDescription`  — registers a variant by its emphasis code
- `ttFontDescriptionForEmphasis: anEmphasis`  — retrieves the appropriate variant
"
Class {
	#name : 'TrueTypeFontFamily',
	#superclass : 'FontFamily',
	#instVars : [
		'baseTTFontDescription',
		'ttFontDescriptionsByEmphasis',
		'baseCatalogueEntry',
		'catalogueEntriesByEmphasis'
	],
	#category : 'VectorGraphics-TrueType-Fonts',
	#package : 'VectorGraphics-TrueType',
	#tag : 'Fonts'
}

{ #category : 'instance creation' }
TrueTypeFontFamily class >> baseCatalogueEntry: aCatalogueEntry [
	^ self new baseCatalogueEntry: aCatalogueEntry
]

{ #category : 'instance creation' }
TrueTypeFontFamily class >> baseTTFontDescription: aTTFontDescription [

	^ self new baseTTFontDescription: aTTFontDescription
]

{ #category : 'accessing' }
TrueTypeFontFamily class >> emphasisOfCatalogueEntry: aCatalogueEntry [
	"Which of my faces a catalogue entry is, in the encoding StrikeFont uses and TrueTypeFont
	 answers: 1 bold, 2 italic, 3 both, 0 the plain face. It is read from the triple the
	 catalogue keys the face by — slant, weight class, width class — and not from the
	 description, which would have to be parsed first. A weight class of 600 is Semibold, the
	 lightest weight a reader is meant to see as bold."

	| metadata emphasis |
	metadata := aCatalogueEntry metadata.
	emphasis := 0.
	metadata weightClass >= 600 ifTrue: [ emphasis := emphasis bitOr: 1 ].
	metadata slant = #normal ifFalse: [ emphasis := emphasis bitOr: 2 ].
	^ emphasis
]

{ #category : 'accessing' }
TrueTypeFontFamily >> addCatalogueEntry: aCatalogueEntry [
	"File one more face of mine, under the emphasis its style key states. The plain face is my
	 base and is not filed again, and the first face to claim an emphasis keeps it — a family
	 with two faces of one emphasis, say Semibold and Black, draws with the one met first.
	 Nothing is parsed: the outlines behind the face are read when a reader first asks for it."

	| emphasis |
	emphasis := self class emphasisOfCatalogueEntry: aCatalogueEntry.
	emphasis = 0 ifTrue: [ ^ self ].
	catalogueEntriesByEmphasis at: emphasis ifAbsentPut: [ aCatalogueEntry ]
]

{ #category : 'initialization' }
TrueTypeFontFamily >> addTTFontDescription: aTTFontDescription [

	ttFontDescriptionsByEmphasis
		at: aTTFontDescription emphasis
		put: aTTFontDescription
]

{ #category : 'accessing' }
TrueTypeFontFamily >> atPointSize: aNumber [
	| baseFont |
	baseFontBySizes at: aNumber ifPresent: [ :existingBaseFont | ^ existingBaseFont ].
	baseFont := TrueTypeFont
		            family: self
		            ttFontDescription: self baseTTFontDescription
		            pointSize: aNumber.
	baseFontBySizes at: aNumber put: baseFont.
	ttFontDescriptionsByEmphasis do: [ :emphasizedTTFontDescription |
		| emphasizedFont |
		emphasizedFont := TrueTypeFont
			                  family: self
			                  ttFontDescription: emphasizedTTFontDescription
			                  pointSize: aNumber.
		emphasizedFont baseFont: baseFont.
		baseFont addDerivativeFont: emphasizedFont ].
	^ baseFont
]

{ #category : 'initialization' }
TrueTypeFontFamily >> baseCatalogueEntry: aCatalogueEntry [
	"Build me from a face a catalogue met, rather than from a parsed description. The name is
	 the one the font states, which the scan read from the name table, so I can be registered
	 without the 80 ms my outlines cost to parse."

	familyName := aCatalogueEntry familyName.
	baseFontBySizes := Dictionary new.
	baseCatalogueEntry := aCatalogueEntry.
	catalogueEntriesByEmphasis ifNil: [
		catalogueEntriesByEmphasis := Dictionary new ].
	ttFontDescriptionsByEmphasis ifNil: [
		ttFontDescriptionsByEmphasis := Dictionary new ]
]

{ #category : 'accessing' }
TrueTypeFontFamily >> baseTTFontDescription [
	"My plainest face, parsed. A family built from a catalogue entry parses it here, at the
	 first point size, the first measure or the first question about my coverage — the 80 ms a
	 font costs is paid by the first reader that needs an outline, not by the scan that met the
	 file. A family built from a description already has it."

	^ baseTTFontDescription ifNil: [
		  baseTTFontDescription := TTFontReader readTTFFrom:
			                           baseCatalogueEntry bytes ]
]

{ #category : 'initialization' }
TrueTypeFontFamily >> baseTTFontDescription: aTTFontDescription [

	self assert: aTTFontDescription emphasis = 0.
	familyName := aTTFontDescription familyName.
	baseFontBySizes := Dictionary new.
	baseTTFontDescription := aTTFontDescription.
	ttFontDescriptionsByEmphasis ifNil: [
		ttFontDescriptionsByEmphasis := Dictionary new ]
]

{ #category : 'accessing' }
TrueTypeFontFamily >> catalogueEntryForEmphasis: anInteger [
	"The face of mine a reader asking for that emphasis would draw with, or nil when I hold no
	 such face and the caller must fall back. Reading it parses nothing."

	^ catalogueEntriesByEmphasis at: anInteger ifAbsent: [ nil ]
]

{ #category : 'initialization' }
TrueTypeFontFamily >> clearCache [

	"
	TrueTypeFontFamily allInstancesDo: [ :each | each clearCache ].
	"

	| emphasized |
	emphasized := ttFontDescriptionsByEmphasis values.
	self baseTTFontDescription: baseTTFontDescription.
	emphasized do: [ :each | self addTTFontDescription: each ]
]

{ #category : 'accessing' }
TrueTypeFontFamily >> folderName [
	^ self baseTTFontDescription folderName
]

{ #category : 'accessing' }
TrueTypeFontFamily >> fontForEmphasis: anInteger pointSize: aNumber [
	"The font of this family for an emphasis, built from the catalogue face filed under that
	 emphasis and parsed here, at the first ask — registration parses nothing. Answers nil when
	 no face of this family carries the emphasis, which leaves the caller its own fallbacks."

	| description baseFontOfSize font |
	description := ttFontDescriptionsByEmphasis
		               at: anInteger
		               ifAbsent: [
			               | entry parsed |
			               entry := self catalogueEntryForEmphasis: anInteger.
			               entry ifNil: [ ^ nil ].
			               parsed := TTFontReader readTTFFrom: entry bytes.
			               self addTTFontDescription: parsed.
			               parsed ].
	baseFontOfSize := self atPointSize: aNumber.
	font := TrueTypeFont
		        family: self
		        ttFontDescription: description
		        pointSize: aNumber.
	font baseFont: baseFontOfSize.
	baseFontOfSize addDerivativeFont: font.
	^ font
]

{ #category : 'testing' }
TrueTypeFontFamily >> includesAscii [
	"Answer true if we include the basic ASCII characters.
	If not, we are not suitable for displaying Smalltalk code."

	^ self baseTTFontDescription includesAscii
]

{ #category : 'testing' }
TrueTypeFontFamily >> isTrueTypeFontFamily [

	^ true
]

{ #category : 'accessing' }
TrueTypeFontFamily >> pointSizes [

	^ #( 6 7 8 9 10 11 12 13 14 15 18 22 26 36 48 72 96 144 )
]
