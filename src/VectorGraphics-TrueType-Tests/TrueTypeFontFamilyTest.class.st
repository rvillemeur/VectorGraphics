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
	catalogue := TTFontFixtures catalogueOfThreeFacesInOneFamily.
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

	| family |
	family := TTFontFixtures familyOfThreeFacesInOneFamily.

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
TrueTypeFontFamilyTest >> testARealFaceIsParsedAtTheFirstAskForAFontAndNotBefore [
	"The same fact as the fixtures state, on a font of this machine, where the parse succeeds
	 instead of raising: a family registered from a catalogue holds no description until a
	 reader asks it for a font, and the font it then answers draws that face at the size asked."

	| catalogue family font |
	catalogue := TTFontCatalogue new.
	catalogue addFile: TrueTypeExamples defaultFontPath asFileReference.
	family := TrueTypeFontFamily baseCatalogueEntry:
		          (catalogue entryOfFamilyNamed: catalogue familyNames first).

	self
		assert: (family instVarNamed: 'baseTTFontDescription')
		equals: nil.

	font := family atPointSize: 12.

	self deny: (family instVarNamed: 'baseTTFontDescription') isNil.
	self assert: font pointSize equals: 12.
	self assert: font familyName equals: family familyName
]

{ #category : 'tests' }
TrueTypeFontFamilyTest >> testAnEmphasisIsParsedOnlyWhenAFontOfThatEmphasisIsAskedFor [
	"A family asked for a font of an emphasis it holds a face for parses that face, and that
	 face alone, at the moment of the ask. Two facts: asking for the bold one reaches its bytes,
	 which these fixtures prove by raising on the missing glyph tables, and asking for an
	 emphasis no face carries answers nil rather than raising, which is what leaves the old
	 fallbacks of TrueTypeFont >> emphasized: in charge."

	| family |
	family := TTFontFixtures familyOfThreeFacesInOneFamily.

	self
		should: [ family fontForEmphasis: 1 pointSize: 12 ]
		raise: Error
		withExceptionDo: [ :error |
			self
				assert: error messageText
				equals: 'Missing required TrueType table: head' ].
	self assert: (family fontForEmphasis: 3 pointSize: 12) equals: nil
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
TrueTypeFontFamilyTest >> testClearingTheCacheOfALazyFamilyThrowsAwayItsFontsAndReadsNothing [
	"Clearing the cache drops the fonts a family built and keeps what it knows of its faces.
	 Two facts: a family that has parsed nothing survives the call — it used to reach for a
	 description it does not have and fail on nil — and a family that built a font answers a
	 fresh one afterwards, while the description it parsed stays parsed."

	| lazy catalogue parsed first |
	lazy := TTFontFixtures familyOfThreeFacesInOneFamily.

	lazy clearCache.

	self deny: (lazy hasParsedEmphasis: 0).
	self
		assert: (lazy catalogueEntryForEmphasis: 1) metadata styleName
		equals: 'Bold'.

	catalogue := TTFontCatalogue new
		             addFile: TrueTypeExamples defaultFontPath asFileReference;
		             yourself.
	parsed := TrueTypeFontFamily
		          fromCatalogue: catalogue
		          familyNamed: catalogue familyNames first.
	first := parsed atPointSize: 12.

	parsed clearCache.

	self assert: (parsed hasParsedEmphasis: 0).
	self deny: (parsed atPointSize: 12) == first
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

{ #category : 'tests' }
TrueTypeFontFamilyTest >> testTheFacesViewNamesEveryEmphasisAndParsesNoneOfThem [
	"The Faces view answers the question a reader of a lazy family has: which faces are known,
	 and which of them have been read. The view is built the way the inspector builds it,
	 through StInspectionContext, and a table's column blocks run per drawn row only, so each
	 is run over each row here. Two facts: there is a row per emphasis the family holds a face
	 for, the base one included, and building it parses nothing — these fixtures raise on a
	 parse, so a row that read bytes would error."

	| builder presenter rows |
	builder := SpPresenterBuilder newApplication: SpApplication new.
	presenter := (StInspectionContext new
		              inspectedObject: TTFontFixtures familyOfThreeFacesInOneFamily;
		              methodSelector: #inspectorFaces:;
		              yourself) basicNewInspectionPresenter: builder.
	rows := presenter items collect: [ :item |
		        presenter columns collect: [ :column |
			        column evaluation value: item ] ].

	self assert: rows asArray equals: {
			{ '0'. 'Regular'. 'pending' }.
			{ '1'. 'Bold'. 'pending' }.
			{ '2'. 'Italic'. 'pending' } }
]
