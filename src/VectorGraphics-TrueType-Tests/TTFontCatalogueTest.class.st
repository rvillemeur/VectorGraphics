"
I test TTFontCatalogue: what a scan of a directory makes of the files it meets, how the entries it keeps are indexed, and what it answers about the files it refuses.

My fonts are the synthetic ones of TTFontFixtures, written into a FileSystem memory directory, so a scan is measured on an exact count of files rather than on what the machine running me happens to have installed.
"
Class {
	#name : 'TTFontCatalogueTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-TrueType-Tests-Tests',
	#package : 'VectorGraphics-TrueType-Tests',
	#tag : 'Tests'
}

{ #category : 'fixtures' }
TTFontCatalogueTest >> catalogueScannedOverTheFixtureDirectory [
	"A catalogue that has met the eight files of the fixture directory, which is what most of
	 my tests start from."

	| catalogue |
	catalogue := TTFontCatalogue new.
	catalogue scanDirectory: self directoryOfSixFacesTwoFamiliesAndTwoRefusals.
	^ catalogue
]

{ #category : 'fixtures' }
TTFontCatalogueTest >> directoryOfSixFacesTwoFamiliesAndTwoRefusals [
	"A font directory in memory: three styles each of two families, one file that is not a font
	 at all, and one font cut short inside a table. That is what a real font directory holds —
	 on this machine 544 files of which 362 are faces this project draws — at a size a test can
	 state exact counts about."

	| directory |
	directory := FileSystem memory root / 'fonts'.
	directory ensureCreateDirectory.
	#( 'Source Sans Pro' 'Source Code Pro' ) do: [ :familyName |
		{
			{ 'Regular'. 400. false }.
			{ 'Bold'. 700. false }.
			{ 'Italic'. 400. true } } do: [ :style |
			self
				write: (TTFontFixtures
						 renderableFontBytesWithFamilyName: familyName
						 styleName: style first
						 weightClass: style second
						 italic: style third)
				as: familyName , '-' , style first , '.ttf'
				in: directory ] ].
	self write: 'StartFontMetrics 2.0' asByteArray as: 'Waree.afm' in: directory.
	self
		write: (TTFontFixtures renderableFontBytes allButLast: 20)
		as: 'Truncated.ttf'
		in: directory.
	^ directory
]

{ #category : 'tests' }
TTFontCatalogueTest >> testAFaceIsFoundByItsStyleKeyAndBothMissesAnswerTheAbsentBlock [
	"A consumer that knows which face it wants names the family and the style key. A family I
	 never met and a style that family does not hold are both misses, and a miss answers the
	 block rather than raising."

	| catalogue |
	catalogue := self catalogueScannedOverTheFixtureDirectory.
	self
		assert: ((catalogue
				  entryOfFamilyNamed: 'source SANS pro'
				  styleKey: #( #normal 700 5 )
				  ifNone: [ nil ]) metadata styleName)
		equals: 'Bold'.
	self
		assert: (catalogue
				 entryOfFamilyNamed: 'Helvetica'
				 styleKey: #( #normal 700 5 )
				 ifNone: [ #noSuchFamily ])
		equals: #noSuchFamily.
	self
		assert: (catalogue
				 entryOfFamilyNamed: 'Source Sans Pro'
				 styleKey: #( #normal 900 5 )
				 ifNone: [ #noSuchStyle ])
		equals: #noSuchStyle
]

{ #category : 'tests' }
TTFontCatalogueTest >> testAFamilyIsFoundByTheNameItStatesWhateverTheCaseAndAnswersItsPlainestFace [
	"A consumer names a family the way a reader spells it, not the way I key it. It means the
	 plain face of that family when it does not say which one: upright, normal weight, normal
	 width. A family I never met answers nothing rather than raising."

	| catalogue entry |
	catalogue := self catalogueScannedOverTheFixtureDirectory.
	entry := catalogue entryOfFamilyNamed: 'source SANS pro'.
	self assert: entry familyName equals: 'Source Sans Pro'.
	self assert: entry styleKey equals: {
			#normal.
			TTFontMetadataReader normalWeightClass.
			TTFontMetadataReader normalWidthClass }.
	self assert: (catalogue entryOfFamilyNamed: 'Helvetica') isNil
]

{ #category : 'tests' }
TTFontCatalogueTest >> testAFamilyIsRecognisedByTheNameItStatesWhateverTheCase [
	"A consumer asks whether I hold a family before asking for one of its faces, and spells it
	 the way a reader spells it. The lower-case key is mine alone, so the question is mine to
	 answer."

	| catalogue |
	catalogue := self catalogueScannedOverTheFixtureDirectory.
	self assert: (catalogue includesFamilyNamed: 'Source Sans Pro').
	self assert: (catalogue includesFamilyNamed: 'source SANS pro').
	self deny: (catalogue includesFamilyNamed: 'Helvetica').
	self deny: (TTFontCatalogue new includesFamilyNamed: 'Source Sans Pro')
]

{ #category : 'tests' }
TTFontCatalogueTest >> testAFontHeldInMemoryIsCatalogued [
	"The second door: a font nobody wrote to disk. The entry answers the very bytes it was given
	 for its whole font, so a consumer cannot tell where the face came from."

	| catalogue bytes entry |
	bytes := TTFontFixtures renderableFontBytes.
	catalogue := TTFontCatalogue new.
	entry := catalogue addBytes: bytes.
	self assert: catalogue entries asArray equals: { entry }.
	self assert: entry bytes identicalTo: bytes.
	self assert: entry metadata familyName equals: 'Source Sans Pro'.
	self
		assert: catalogue familyNames asArray
		equals: #( 'Source Sans Pro' )
]

{ #category : 'tests' }
TTFontCatalogueTest >> testAFreshCatalogueAndAnEmptyDirectoryBothAnswerNothing [
	"The degenerate states: nothing scanned, and a directory with nothing in it. Neither raises
	 and neither answers nil, because a consumer asks the same questions of both."

	| catalogue directory |
	catalogue := TTFontCatalogue new.
	self assert: catalogue entries isEmpty.
	self assert: catalogue familyNames isEmpty.
	self assert: catalogue refusedEntries isEmpty.
	directory := FileSystem memory root / 'empty'.
	directory ensureCreateDirectory.
	catalogue scanDirectory: directory.
	self assert: catalogue entries isEmpty.
	self assert: catalogue entriesByFamilyName isEmpty
]

{ #category : 'tests' }
TTFontCatalogueTest >> testARefusedFileIsKeptWithItsReasonAndIsNotIndexed [
	"A font directory holds more files that are not drawable fonts than files that are. Each one
	 is an entry carrying the reason it was passed over, and none of them reaches the index a
	 consumer looks a family up in."

	| catalogue entry |
	catalogue := TTFontCatalogue new.
	entry := catalogue addBytes: TTFontFixtures otfFontBytes.
	self assert: catalogue entries asArray equals: { entry }.
	self assert: catalogue refusedEntries asArray equals: { entry }.
	self assert: entry metadata rejectionReason equals: #noGlyfTable.
	self assert: entry metadata familyName equals: 'Waree'.
	self assert: catalogue entriesByFamilyName isEmpty.
	self assert: catalogue familyNames isEmpty
]

{ #category : 'tests' }
TTFontCatalogueTest >> testAnEntryAnswersTheFamilyAndTheStyleItsFontStates [
	"The two names a reader sorts and groups a catalogue by. An entry answers both itself, so a
	 table of faces does not reach through it into the metadata for one of the pair and not the
	 other."

	| entry |
	entry := (self catalogueScannedOverTheFixtureDirectory
		          entryOfFamilyNamed: 'Source Sans Pro'
		          styleKey: #( #normal 700 5 )
		          ifNone: [ nil ]).
	self assert: entry familyName equals: 'Source Sans Pro'.
	self assert: entry styleName equals: 'Bold'.
	self assert: entry styleName equals: entry metadata styleName
]

{ #category : 'tests' }
TTFontCatalogueTest >> testAnEntryNamesItsFaceAndItsSourceWhenPrinted [
	"A catalogue is read as a list of hundreds of lines, so a line says which face it is and
	 where that face came from: a base name for a file, a byte count for a font in memory."

	| catalogue fileEntry memoryEntry |
	catalogue := self catalogueScannedOverTheFixtureDirectory.
	fileEntry := catalogue entries
		             detect: [ :each |
		             each source basename = 'Source Sans Pro-Bold.ttf' ].
	self
		assert: fileEntry printString
		equals:
		'a TTFontCatalogueEntry a TTFontMetadata ''Source Sans Pro'' ''Bold'' from Source Sans Pro-Bold.ttf'.
	memoryEntry := catalogue addBytes: TTFontFixtures otfFontBytes.
	self
		assert: memoryEntry printString
		equals:
		'a TTFontCatalogueEntry a TTFontMetadata ''Waree'' ''Oblique'' #noGlyfTable from 150 bytes'
]

{ #category : 'tests' }
TTFontCatalogueTest >> testAnEntryOnAFileReadsTheWholeFontOnlyWhenAskedForItsBytes [
	"The catalogue stays at the cheap end: the scan read a few hundred bytes a file, and the
	 whole font comes back only when a consumer asks the entry for it."

	| catalogue entry |
	catalogue := self catalogueScannedOverTheFixtureDirectory.
	entry := catalogue entries
		         detect: [ :each |
		         each source basename = 'Source Code Pro-Italic.ttf' ].
	self
		assert: entry bytes
		equals: (TTFontFixtures
				 renderableFontBytesWithFamilyName: 'Source Code Pro'
				 styleName: 'Italic'
				 weightClass: 400
				 italic: true).
	self assert: entry metadata slant equals: #italic
]

{ #category : 'tests' }
TTFontCatalogueTest >> testFacesOfOneFamilyAreKeyedBySlantWeightAndWidth [
	"How a font manager finds the face a text asks for: the family in lower case, then the
	 triple that tells the faces of that family apart."

	| catalogue faces |
	catalogue := self catalogueScannedOverTheFixtureDirectory.
	faces := catalogue entriesByFamilyName at: 'source sans pro'.
	self assert: faces keys asSet equals: {
			#( #italic 400 5 ).
			#( #normal 400 5 ).
			#( #normal 700 5 ) } asSet.
	self
		assert: (faces at: #( #normal 700 5 )) metadata styleName
		equals: 'Bold'
]

{ #category : 'tests' }
TTFontCatalogueTest >> testScanningADirectoryAnswersAFamilyPerNameAndAnEntryPerFile [
	"The one fact of the catalogue: a scan meets every file under a directory, keeps one entry
	 for each, names the families of those it can draw, and says of the others why not."

	| catalogue |
	catalogue := self catalogueScannedOverTheFixtureDirectory.
	self assert: catalogue entries size equals: 8.
	self
		assert: catalogue familyNames asArray
		equals: #( 'Source Code Pro' 'Source Sans Pro' ).
	self
		assert: (catalogue refusedEntries collect: [ :each |
				 each metadata rejectionReason ]) asArray asSet
		equals: #( #notAnSfntFont ) asSet
]

{ #category : 'tests' }
TTFontCatalogueTest >> testTheDrawableEntriesAreTheOnesLeftWhenTheRefusalsAreTakenAway [
	"The other side of refusedEntries, and the question a consumer asks to pick a face to draw
	 with. Six of the eight files of the fixture directory carry outlines and a name; the two
	 refusals are not among them, and an empty catalogue answers nothing."

	| catalogue |
	catalogue := self catalogueScannedOverTheFixtureDirectory.
	self assert: catalogue drawableEntries size equals: 6.
	self
		assert: catalogue drawableEntries size + catalogue refusedEntries size
		equals: catalogue entries size.
	self deny: (catalogue drawableEntries anySatisfy: [ :each | each isRejected ]).
	self assert: TTFontCatalogue new drawableEntries isEmpty
]

{ #category : 'tests' }
TTFontCatalogueTest >> testTheFamiliesViewCountsTheFacesIndexedAndNamesTheirStyles [
	"The view the way the inspector builds it, through StInspectionContext, which refuses a view
	 that does not take a presenter builder. A table's column blocks run per drawn row only, so
	 each is run over each row here. One row a family, and the Faces column counts what the
	 index holds rather than the files that were met."

	| builder presenter rows |
	builder := SpPresenterBuilder newApplication: SpApplication new.
	presenter := (StInspectionContext new
		              inspectedObject: self catalogueScannedOverTheFixtureDirectory;
		              methodSelector: #inspectorFamilies:;
		              yourself) basicNewInspectionPresenter: builder.
	rows := presenter items collect: [ :item |
		        presenter columns collect: [ :column |
			        column evaluation value: item ] ].
	self assert: rows asArray equals: {
			{ 'Source Code Pro'. '3'. 'Bold, Italic, Regular' }.
			{ 'Source Sans Pro'. '3'. 'Bold, Italic, Regular' } }
]

{ #category : 'tests' }
TTFontCatalogueTest >> testTheFirstSourceOfAFaceWinsAndTheSecondIsStillKept [
	"The same face installed twice — a user font and a system font of the same name — is one
	 face to a consumer, and the scan order decides which copy answers. The second copy is
	 still an entry of mine, so a reader can see that it exists."

	| catalogue bytes first second |
	bytes := TTFontFixtures renderableFontBytes.
	catalogue := TTFontCatalogue new.
	first := catalogue addBytes: bytes.
	second := catalogue addBytes: bytes copy.
	self assert: catalogue entries asArray equals: {
			first.
			second }.
	self
		assert: ((catalogue entriesByFamilyName at: 'source sans pro') at: first styleKey)
		identicalTo: first
]

{ #category : 'tests' }
TTFontCatalogueTest >> testTheRefusalsViewGroupsTheFilesByTheReasonTheyGave [
	"One row a reason, collected from the entries rather than listed in the view: the fixture
	 directory holds a file that is not a font and a font cut short inside a table, and both
	 give the same reason, so one row of two files is right."

	| builder presenter rows |
	builder := SpPresenterBuilder newApplication: SpApplication new.
	presenter := (StInspectionContext new
		              inspectedObject: self catalogueScannedOverTheFixtureDirectory;
		              methodSelector: #inspectorRefusals:;
		              yourself) basicNewInspectionPresenter: builder.
	rows := presenter items collect: [ :item |
		        presenter columns collect: [ :column |
			        column evaluation value: item ] ].
	self assert: rows asArray equals: {
			{ 'notAnSfntFont'. '2'. 'Truncated.ttf' } }
]

{ #category : 'tests' }
TTFontCatalogueTest >> testTheSourceViewOfAnEntrySaysHowFewBytesTheScanRead [
	"The claim the catalogue rests on, shown on the entry itself: the scan read the offset
	 table, one record per table and the three tables it classifies from — 190 bytes of this
	 222-byte fixture, and a few hundred of a real font of megabytes. The figure is computed
	 from the reader's constants, so the view cannot overstate what the reader did."

	| builder entry presenter rows |
	entry := self catalogueScannedOverTheFixtureDirectory entries
		         detect: [ :each |
		         each source basename = 'Source Sans Pro-Regular.ttf' ].
	builder := SpPresenterBuilder newApplication: SpApplication new.
	presenter := (StInspectionContext new
		              inspectedObject: entry;
		              methodSelector: #inspectorSource:;
		              yourself) basicNewInspectionPresenter: builder.
	rows := Dictionary new.
	presenter items do: [ :item | rows at: item key put: item value ].
	self assert: (rows at: 'source') equals: 'Source Sans Pro-Regular.ttf'.
	self assert: (rows at: 'bytes') equals: '222'.
	self assert: (rows at: 'read by the scan') equals: '190'.
	self assert: (rows at: 'read by the scan') asInteger < entry source size
]

{ #category : 'fixtures' }
TTFontCatalogueTest >> write: aByteArray as: aString in: aDirectory [
	"One file of the fixture directory. The bytes are written binary, because a font is read
	 back through a binary stream and a memory file remembers which it was written as."

	(aDirectory / aString) binaryWriteStreamDo: [ :stream |
		stream nextPutAll: aByteArray ]
]
