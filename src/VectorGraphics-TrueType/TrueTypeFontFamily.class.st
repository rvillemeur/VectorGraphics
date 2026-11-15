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

{ #category : 'instance creation' }
TrueTypeFontFamily class >> fromCatalogue: aFontCatalogue familyNamed: aString [
	"The family a catalogue holds under a name: its plainest face as the base, every other face
	 of the name filed by the emphasis its style key states. Nothing is parsed here — a face is
	 read when a reader first asks for a font of its emphasis."

	| family |
	family := self baseCatalogueEntry:
		          (aFontCatalogue entryOfFamilyNamed: aString).
	(aFontCatalogue entriesByFamilyName at: aString asLowercase) do: [
		:entry | family addCatalogueEntry: entry ].
	^ family
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
	catalogueEntriesByEmphasis ifNil: [
		catalogueEntriesByEmphasis := Dictionary new ].
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
	"Throw away the fonts I built, at every size and every emphasis, and keep what I know of my
	 faces: the catalogue entries, and whatever of them has already been parsed. A reader that
	 asks again gets fresh fonts, and pays no parse for the faces already read.

	TrueTypeFontFamily allInstancesDo: [ :each | each clearCache ].
	"

	baseFontBySizes := Dictionary new
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
TrueTypeFontFamily >> hasParsedEmphasis: anInteger [
	"Have the outlines of the face I hold for this emphasis been read? Asking never reads them."

	anInteger = 0 ifTrue: [ ^ baseTTFontDescription notNil ].
	^ ttFontDescriptionsByEmphasis includesKey: anInteger
]

{ #category : 'testing' }
TrueTypeFontFamily >> includesAscii [
	"Answer true if we include the basic ASCII characters.
	If not, we are not suitable for displaying Smalltalk code."

	^ self baseTTFontDescription includesAscii
]

{ #category : 'inspecting' }
TrueTypeFontFamily >> inspectorFaces: aBuilder [
	"The faces I know of and what has been read of each. One row per emphasis, the base face
	 first; the Style column names the face a catalogue met, the Read column says whether its
	 outlines have been parsed — which happens when a reader first asks me for a font of that
	 emphasis. Building this view reads no bytes, so a family inspected before anything asked
	 it says 'pending' on every row."

	<inspectorPresentationOrder: 10 title: 'Faces'>
	| emphases |
	emphases := (catalogueEntriesByEmphasis keys
	             , ttFontDescriptionsByEmphasis keys asArray , #( 0 )) asSet
		            asSortedCollection asArray.
	^ aBuilder newTable
		  addColumn: ((SpStringTableColumn
				    title: 'Emphasis'
				    evaluated: [ :each | each printString ])
				   width: 80);
		  addColumn: ((SpStringTableColumn
				    title: 'Style'
				    evaluated: [ :each | self styleNameOfEmphasis: each ])
				   width: 200);
		  addColumn: (SpStringTableColumn
				   title: 'Read'
				   evaluated: [ :each |
					   (self hasParsedEmphasis: each)
						   ifTrue: [ 'parsed' ]
						   ifFalse: [ 'pending' ] ]);
		  items: emphases;
		  yourself
]

{ #category : 'testing' }
TrueTypeFontFamily >> isTrueTypeFontFamily [

	^ true
]

{ #category : 'accessing' }
TrueTypeFontFamily >> pointSizes [

	^ #( 6 7 8 9 10 11 12 13 14 15 18 22 26 36 48 72 96 144 )
]

{ #category : 'accessing' }
TrueTypeFontFamily >> styleNameOfEmphasis: anInteger [
	"What the face I hold for this emphasis calls its style — 'Regular', 'Bold', 'Italic'. Read
	 from the catalogue entry when there is one, from the parsed description otherwise, and
	 nil when I hold neither. Asking parses nothing."

	| entry |
	entry := anInteger = 0
		         ifTrue: [ baseCatalogueEntry ]
		         ifFalse: [ self catalogueEntryForEmphasis: anInteger ].
	entry ifNotNil: [ ^ entry metadata styleName ].
	anInteger = 0 ifTrue: [ ^ baseTTFontDescription ifNotNil: [ :each | each fullName ] ].
	^ (ttFontDescriptionsByEmphasis at: anInteger ifAbsent: [ nil ])
		  ifNotNil: [ :each | each fullName ]
]
