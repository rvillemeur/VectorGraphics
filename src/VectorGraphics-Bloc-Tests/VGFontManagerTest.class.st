"
I test `VGFontManager`: that it owns no FreeType library, that it keeps a face for the session rather than evicting it, and that every inherited route into the registry refuses by name while the catalogue route is still being built.
"
Class {
	#name : 'VGFontManagerTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Bloc-Tests',
	#package : 'VectorGraphics-Bloc-Tests'
}

{ #category : 'tests' }
VGFontManagerTest >> testADirectoryScanReadsEveryFileAndJudgesItByItsContent [
	"The scanning door, and the rule it carries: a file is read because it is there, not because
	 its name looks like a font. Upstream drives an AeFontScanner, whose shouldIgnoreFile: skips
	 a file whose extension it does not know; a font saved under a name nobody expects is
	 registered here, and a file that is not a font is a refusal the catalogue keeps rather than
	 a file silently passed over."

	| directory manager |
	directory := FileSystem memory root / 'fonts'.
	directory ensureCreateDirectory.
	(directory / 'face.bin') binaryWriteStreamDo: [ :stream |
		stream nextPutAll: AeSourceSansPro_Regular fontContentsData ].
	(directory / 'readme.txt') writeStreamDo: [ :stream |
		stream nextPutAll: 'not a font' ].
	manager := VGFontManager new.
	manager scanDirectory: directory.
	self assert: manager familyNames asArray equals: #( 'Source Sans Pro' ).
	self assert: manager faceEntries size equals: 1.
	self assert: manager catalogue entries size equals: 2.
	self
		assert: (manager catalogue refusedEntries collect: [ :each |
				 each metadata rejectionReason ]) asArray
		equals: #( #notAnSfntFont )
]

{ #category : 'tests' }
VGFontManagerTest >> testAFreshManagerOwnsNoFreeTypeLibraryAndHoldsAPermanentFaceCache [
	"The point of this manager is that it owns no foreign handle and parses a face once. So the
	 FreeType slot upstream fills with an AeFTLibrary stays empty, and the LRU cache upstream
	 caps at twenty faces is a plain Dictionary with no ceiling to evict against."

	| manager |
	manager := VGFontManager new.
	self assert: manager freetypeLibrary isNil.
	self assert: manager faceByEntryCache class equals: Dictionary.
	self assert: manager faceByEntryCache isEmpty
]

{ #category : 'tests' }
VGFontManagerTest >> testAManagerThatHoldsNothingAnswersTheAbsentBlockRatherThanRaising [
	"The degenerate state, on both doors that take an absent block. A fresh manager holds no
	 family, so an entry is not found; a manager that holds the family is asked for a weight no
	 face of it has, so the style key is not found. Both answer the block, and neither raises on
	 the empty dictionary the catalogue starts with."

	| manager |
	manager := VGFontManager new.
	self assert: manager familyNames isEmpty.
	self deny: (manager includesFamilyName: 'Source Sans Pro').
	self
		assert: (manager
				 entryForFamilyName: 'Source Sans Pro'
				 slant: AeFontSlant normal
				 weight: AeFontWeight normal
				 stretch: AeFontStretch normal
				 ifNone: [ #none ])
		equals: #none.
	self
		assert: (manager
				 detectFamilyName: 'Source Sans Pro'
				 slant: AeFontSlant normal
				 weight: AeFontWeight normal
				 stretch: AeFontStretch normal
				 ifNone: [ #none ])
		equals: #none.
	manager registerFacesOnMemory: AeSourceSansPro_Regular fontContentsData.
	self assert: (manager includesFamilyName: 'source sans pro').
	self
		assert: (manager
				 entryForFamilyName: 'Source Sans Pro'
				 slant: AeFontSlant normal
				 weight: AeFontWeight black
				 stretch: AeFontStretch normal
				 ifNone: [ #none ])
		equals: #none
]

{ #category : 'tests' }
VGFontManagerTest >> testTheEmbeddedFontsRegisterAsTwoFamiliesFoundByTheirAlexandrieTriple [
	"Registration goes through the catalogue, and a consumer still asks the way Alexandrie asks:
	 a family name and a triple of AeFontSlant, AeFontWeight and AeFontStretch. The six embedded
	 faces are two families of three, and the triple each one answers to is the one upstream's
	 own style-name parser gives it, checked face by face when this unit was built."

	| manager expected |
	manager := VGFontManager new.
	AeEmbeddedFontFile allSubclassesDo: [ :each |
		manager registerFacesOnMemory: each fontContentsData ].
	self assert: manager familyNames asArray equals: #( 'Source Code Pro' 'Source Sans Pro' ).
	self assert: manager faceEntries size equals: 6.
	expected := {
		            { 'Regular'. AeFontSlant normal. AeFontWeight normal }.
		            { 'Bold'. AeFontSlant normal. AeFontWeight bold }.
		            { 'Italic'. AeFontSlant italic. AeFontWeight normal } }.
	#( 'Source Code Pro' 'Source Sans Pro' ) do: [ :family |
		expected do: [ :each |
			| entry |
			entry := manager
				         entryForFamilyName: family
				         slant: (each at: 2)
				         weight: (each at: 3)
				         stretch: AeFontStretch normal
				         ifNone: [ nil ].
			self assert: entry notNil.
			self assert: entry familyName equals: family.
			self assert: entry metadata styleName equals: (each at: 1) ] ]
]

{ #category : 'tests' }
VGFontManagerTest >> testTheFaceLookupReachesTheCacheRatherThanTheEmptyInheritedIndex [
	"detectFamilyName:slant:weight:stretch:ifNone: is the one door a consumer of faces knocks on,
	 and upstream's reads the instance variable this manager leaves empty, so it would answer the
	 absent block for a family the catalogue holds. It has to ask the catalogue and then the
	 cache. Until unit 3.4 fills the cache, reaching it is what proves the lookup found the
	 entry: a registered family raises on the cache instead of answering the block."

	| manager |
	manager := VGFontManager new.
	manager registerFacesOnMemory: AeSourceSansPro_Regular fontContentsData.
	self
		should: [
			manager
				detectFamilyName: 'Source Sans Pro'
				slant: AeFontSlant normal
				weight: AeFontWeight normal
				stretch: AeFontStretch normal
				ifNone: [ self fail: 'the entry is there to be found' ] ]
		raise: KeyNotFound
]

{ #category : 'tests' }
VGFontManagerTest >> testTheFilesRefusedAreKeptWithTheirReasonAndAFreshManagerRefusedNone [
	"A file I met and will not draw with is not dropped: I answer for it, with the reason the
	 reader gave, so a reader asking why a family is missing has somewhere to look. A manager
	 that has met nothing refuses nothing."

	| directory manager |
	self assert: VGFontManager new rejectedFiles isEmpty.
	directory := FileSystem memory root / 'fonts'.
	directory ensureCreateDirectory.
	(directory / 'face.bin') binaryWriteStreamDo: [ :stream |
		stream nextPutAll: AeSourceSansPro_Regular fontContentsData ].
	(directory / 'readme.txt') writeStreamDo: [ :stream |
		stream nextPutAll: 'not a font' ].
	manager := VGFontManager new.
	manager scanDirectory: directory.
	self assert: manager rejectedFiles size equals: 1.
	self
		assert: (manager rejectedFiles anyOne metadata rejectionReason)
		equals: #notAnSfntFont.
	self
		assert: manager rejectedFiles anyOne source basename
		equals: 'readme.txt'
]

{ #category : 'tests' }
VGFontManagerTest >> testTheStateViewCountsTheFamiliesTheCatalogueHolds [
	"The State view reads me through my own readers, not through the slot upstream keeps the
	 index in: that slot stays empty for ever, so a row that reads it directly answers zero
	 whatever I hold."

	| manager rows |
	manager := VGFontManager new.
	AeEmbeddedFontFile allSubclassesDo: [ :each |
		manager registerFacesOnMemory: each fontContentsData ].
	rows := (manager inspectorState:
		         (SpPresenterBuilder newApplication: SpApplication new)) items.
	self
		assert: (rows detect: [ :each | each key = 'Families registered' ]) value
		equals: 2.
	self
		assert: (rows detect: [ :each | each key = 'Entries registered' ]) value
		equals: 6
]
