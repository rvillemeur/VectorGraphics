"
I hold `TrueTypeFontFamily`, the family built from one parsed description that answers a `TrueTypeFont` at any point size.

The family takes its name and its ASCII coverage from the description it was built with, and answers `isTrueTypeFontFamily` where `FontFamily` does not — the one place in the font code where the kind is asked rather than the behaviour. Asking for a point size builds a `TrueTypeFont` and remembers it, so the same size asked twice answers the same object and the point sizes asked for are the sizes the family lists.

`folderName` is held here too, although nothing in the image sets it: it is what remains of loading a family from a directory, which was removed in the review of 2026-11. The fixture sets the instance variable directly for that reason.
"
Class {
	#name : 'TrueTypeFontFamilyTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-TrueType-Tests-Tests',
	#package : 'VectorGraphics-TrueType-Tests',
	#tag : 'Tests'
}

{ #category : 'private' }
TrueTypeFontFamilyTest >> catalogueOfThreeFacesInOneFamily [
	"A family of three faces nobody wrote to disk: the plain face, a bold one and an italic one.
	 The bytes carry a name table and an OS/2 table, which is all a scan reads, and no glyph
	 tables at all — so a parse of one of them raises, which is how a test states which face a
	 reader reached for and when."

	| catalogue |
	catalogue := TTFontCatalogue new.
	{
		{ 'Regular'. 400. false }.
		{ 'Bold'. 700. false }.
		{ 'Italic'. 400. true } } do: [ :style |
		catalogue addBytes: (TTFontFixtures
				 renderableFontBytesWithFamilyName: 'Fixture Sans'
				 styleName: style first
				 weightClass: style second
				 italic: style third) ].
	^ catalogue
]

{ #category : 'helpers' }
TrueTypeFontFamilyTest >> makeFamily [

	^ TrueTypeFontFamily baseTTFontDescription: self makeFontDescription
]

{ #category : 'helpers' }
TrueTypeFontFamilyTest >> makeFontDescription [

	"Regular font: familyName = fullName → emphasis 0."

	| fd |
	fd := TTFontDescription new.
	fd setStrings: #( 'CR' 'TestFamily' 'Regular' 'Uniq' 'TestFamily' 'v1' 'TestFamily-Regular' 'TM' ).
	fd setAscent: 800 descent: -200 lineGap: 50.
	fd instVarNamed: 'folderName' put: 'TestFonts'.
	fd instVarNamed: 'letterMTopSideBearing' put: 800.
	fd instVarNamed: 'contourDataIndexesByUtf8' put: (IntegerArray new: 256).
	fd instVarNamed: 'contourDataForUtf8' put: (Float32Array new: 10).
	^ fd
]

{ #category : 'tests' }
TrueTypeFontFamilyTest >> testACatalogueFaceIsFiledUnderTheEmphasisItsStyleKeyStates [
	"The emphasis of a face is read from the triple the catalogue already keys it by — slant,
	 weight class, width class — because reading it from the description would mean parsing the
	 font at the moment it is registered. Three facts: an upright face of normal weight is the
	 plain one, a face of weight 600 or more is bold, a slanted face is italic. The encoding is
	 StrikeFont's, which is what TrueTypeFont >> emphasis answers."

	| catalogue faces emphases |
	catalogue := self catalogueOfThreeFacesInOneFamily.
	faces := catalogue entriesByFamilyName at: 'fixture sans'.
	emphases := faces values
		            collect: [ :each |
		            each metadata styleName
		            -> (TrueTypeFontFamily emphasisOfCatalogueEntry: each) ]
		            as: Set.
	self assert: emphases equals: {
			('Regular' -> 0).
			('Bold' -> 1).
			('Italic' -> 2) } asSet
]

{ #category : 'tests' }
TrueTypeFontFamilyTest >> testAFamilyKeepsTheCatalogueFacesItWasGivenAndParsesNoneOfThem [
	"A family takes the faces of its catalogue family: the plainest one as its base, the others
	 filed by emphasis. Two facts: it answers the entry of an emphasis it holds and nil for one
	 it does not, and it parsed nothing on the way in — these fixtures carry no glyph tables, so
	 any parse raises."

	| catalogue family |
	catalogue := self catalogueOfThreeFacesInOneFamily.
	family := TrueTypeFontFamily baseCatalogueEntry:
		          (catalogue entryOfFamilyNamed: 'Fixture Sans').
	(catalogue entriesByFamilyName at: 'fixture sans') do: [ :entry |
		family addCatalogueEntry: entry ].
	self assert: family familyName equals: 'Fixture Sans'.
	self
		assert: (family catalogueEntryForEmphasis: 1) metadata styleName
		equals: 'Bold'.
	self
		assert: (family catalogueEntryForEmphasis: 2) metadata styleName
		equals: 'Italic'.
	self assert: (family catalogueEntryForEmphasis: 3) equals: nil.
	self assert: (family catalogueEntryForEmphasis: 0) equals: nil
]

{ #category : 'tests' }
TrueTypeFontFamilyTest >> testAtPointSizeCachesResult [

	| family |
	family := self makeFamily.
	self assert: (family atPointSize: 12) == (family atPointSize: 12)
]

{ #category : 'tests' }
TrueTypeFontFamilyTest >> testAtPointSizeCreatesTrueTypeFont [

	| family font |
	family := self makeFamily.
	font := family atPointSize: 12.
	self assert: font class equals: TrueTypeFont.
	self assert: font pointSize equals: 12
]

{ #category : 'tests' }
TrueTypeFontFamilyTest >> testFamilyName [

	self assert: self makeFamily familyName equals: 'TestFamily'
]

{ #category : 'tests' }
TrueTypeFontFamilyTest >> testFolderName [

	self assert: self makeFamily folderName equals: 'TestFonts'
]

{ #category : 'tests' }
TrueTypeFontFamilyTest >> testIncludesAscii [

	"Mock description has all indexes=0 → includesAscii is false."

	self deny: self makeFamily includesAscii
]

{ #category : 'tests' }
TrueTypeFontFamilyTest >> testIsTrueTypeFontFamily [

	self assert: self makeFamily isTrueTypeFontFamily
]

{ #category : 'tests' }
TrueTypeFontFamilyTest >> testPointSizes [

	| sizes |
	sizes := self makeFamily pointSizes.
	self assert: (sizes includes: 12).
	self assert: (sizes includes: 6).
	self assert: (sizes includes: 144).
	self assert: sizes size equals: 18
]
