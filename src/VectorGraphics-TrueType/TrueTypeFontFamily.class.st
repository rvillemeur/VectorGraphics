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
		'facesByEmphasis'
	],
	#category : 'VectorGraphics-TrueType-Fonts',
	#package : 'VectorGraphics-TrueType',
	#tag : 'Fonts'
}

{ #category : 'architecture' }
TrueTypeFontFamily class >> archRelations [
	"What an instance of me holds beyond my superclass's cache of base fonts: one face per
	 emphasis — plain, bold, italic, bold italic — each one a file the scan met or a description
	 posed by hand. A scan adds them, so a family just made holds none, and an empty holding of
	 many is no fault.
	 My superclass's row is kept, because an instance of mine holds that too."

	^ super archRelations , #( #( #facesByEmphasis #many #TTFamilyFace nil ) )
]

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
	facesByEmphasis
		at: emphasis
		ifAbsentPut: [ TTFamilyFace catalogueEntry: aCatalogueEntry ]
]

{ #category : 'initialization' }
TrueTypeFontFamily >> addTTFontDescription: aTTFontDescription [
	"File a face of mine that is already parsed, under the emphasis it states."

	facesByEmphasis
		at: aTTFontDescription emphasis
		put: (TTFamilyFace ttFontDescription: aTTFontDescription)
]

{ #category : 'accessing' }
TrueTypeFontFamily >> atPointSize: aNumber [
	"My plain font at a size, with the fonts of every face I have already parsed hung off it as
	 its derivatives. The faces still pending are left alone: building them here would parse
	 every face of mine the moment a reader asks for the plain one. A reader that asks for an
	 emphasis gets it through fontForEmphasis:pointSize:, which parses that one face."

	| baseFont |
	baseFontBySizes at: aNumber ifPresent: [ :existingBaseFont | ^ existingBaseFont ].
	baseFont := TrueTypeFont
		            family: self
		            ttFontDescription: self baseTTFontDescription
		            pointSize: aNumber.
	baseFontBySizes at: aNumber put: baseFont.
	facesByEmphasis keysAndValuesDo: [ :emphasis :face |
		(emphasis ~= 0 and: [ face isParsed ]) ifTrue: [
			| emphasizedFont |
			emphasizedFont := TrueTypeFont
				                  family: self
				                  ttFontDescription: face ttFontDescription
				                  pointSize: aNumber.
			emphasizedFont baseFont: baseFont.
			baseFont addDerivativeFont: emphasizedFont ] ].
	^ baseFont
]

{ #category : 'initialization' }
TrueTypeFontFamily >> baseCatalogueEntry: aCatalogueEntry [
	"Build me from a face a catalogue met, rather than from a parsed description. The name is
	 the one the font states, which the scan read from the name table, so I can be registered
	 without the 80 ms my outlines cost to parse."

	familyName := aCatalogueEntry familyName.
	baseFontBySizes := Dictionary new.
	facesByEmphasis := Dictionary new.
	facesByEmphasis at: 0 put: (TTFamilyFace catalogueEntry: aCatalogueEntry)
]

{ #category : 'accessing' }
TrueTypeFontFamily >> baseTTFontDescription [
	"My plainest face, parsed. A family built from a catalogue entry parses it here, at the
	 first point size, the first measure or the first question about my coverage — the 80 ms a
	 font costs is paid by the first reader that needs an outline, not by the scan that met the
	 file. A family built from a description already has it."

	^ (facesByEmphasis at: 0) ttFontDescription
]

{ #category : 'initialization' }
TrueTypeFontFamily >> baseTTFontDescription: aTTFontDescription [
	self assert: aTTFontDescription emphasis = 0.
	familyName := aTTFontDescription familyName.
	baseFontBySizes := Dictionary new.
	facesByEmphasis := Dictionary new.
	facesByEmphasis
		at: 0
		put: (TTFamilyFace ttFontDescription: aTTFontDescription)
]

{ #category : 'accessing' }
TrueTypeFontFamily >> catalogueEntryForEmphasis: anInteger [
	"The catalogue entry of the face a reader asking for that emphasis would draw with, or nil
	 when I hold no such face and the caller must fall back — and nil as well for a face posed
	 as a parsed description, which no catalogue met. Reading it parses nothing."

	^ (facesByEmphasis at: anInteger ifAbsent: [ ^ nil ]) catalogueEntry
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
	"The font of this family for an emphasis, built from the face filed under that emphasis and
	 parsed here, at the first ask — registration parses nothing. Answers nil when no face of
	 this family carries the emphasis, which leaves the caller its own fallbacks."

	| face description baseFontOfSize font |
	face := facesByEmphasis at: anInteger ifAbsent: [ ^ nil ].
	anInteger = 0 ifTrue: [ ^ self atPointSize: aNumber ].
	description := face ttFontDescription.
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
	"Have the outlines of the face I hold for this emphasis been read? Asking never reads them,
	 and an emphasis I hold no face for answers false."

	^ (facesByEmphasis at: anInteger ifAbsent: [ ^ false ]) isParsed
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
		  items: facesByEmphasis keys asSortedCollection asArray;
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
	"What the face I hold for this emphasis calls its style — 'Regular', 'Bold', 'Italic' — and
	 nil for an emphasis I hold no face for. Asking parses nothing."

	^ (facesByEmphasis at: anInteger ifAbsent: [ ^ nil ]) styleName
]
