"
I test `VGFontManager`: that it owns no FreeType library, that it keeps a face for the session rather than evicting it, and that every inherited route into the registry refuses by name while the catalogue route is still being built.
"
Class {
	#name : 'VGFontManagerTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Bloc-Text-Tests-Tests',
	#package : 'VectorGraphics-Bloc-Text-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
VGFontManagerTest >> testADirectoryScanReadsEveryFileAndJudgesItByItsContent [
	"The scanning door, and the rule it carries: a file is read because it is there, not because
	 its name looks like a font. Upstream drives an AeFontScanner, whose shouldIgnoreFile: skips
	 a file whose extension it does not know; a font saved under a name nobody expects is
	 registered here, and a file that is not a font is a rejection the catalogue keeps rather than
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
		assert: (manager catalogue rejectedEntries collect: [ :each |
				 each metadata rejectionReason ]) asArray
		equals: #( #notAnSfntFont )
]

{ #category : 'tests' }
VGFontManagerTest >> testAFaceIsBuiltOnceForAnEntryAndNoFreeTypeFaceIsBuiltAtAll [
	"The face a consumer draws with is ours, read from the entry's own bytes, and kept for the
	 session: asking twice answers the same object rather than parsing the font again. No
	 FreeType face is built on the way, which is the whole point of this plan."

	| manager entry first second faceCount |
	manager := VGFontManager new.
	entry := manager registerFacesOnMemory:
		         AeSourceSansPro_Regular fontContentsData.
	faceCount := AeFTFace allInstances size.
	first := manager faceAt: entry.
	second := manager faceAt: entry.
	self assert: first class equals: VGFontFace.
	self assert: first identicalTo: second.
	self assert: first familyName equals: 'Source Sans Pro'.
	self assert: AeFTFace allInstances size equals: faceCount
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
VGFontManagerTest >> testAManagerBuiltWithDefaultFacesScansAgainWhenTheSessionChanges [
	"Reproduces a defect. reset builds an empty catalogue and nils both defaults, and nothing
	 ever scans again, so the manager an image restart hands back has met no font at all. The
	 drawing then breaks in BAFontConverter >> faceFor: on a nil default rather than here.
	 A manager built by hand keeps answering empty, which the test above this one states: what
	 is rebuilt is the scan the manager was built with, not faces somebody registered."

	| manager |
	manager := VGFontManager newWithDefaultFaces.
	manager instVarNamed: 'session' put: Object new.
	self deny: manager familyNames isEmpty.
	self assert: manager defaultFace notNil.
	self assert: manager defaultCodeFace notNil
]

{ #category : 'tests' }
VGFontManagerTest >> testAManagerBuiltWithTheDefaultFacesDrawsTheMachineFamiliesWithoutFreeType [
	"The manager a consumer can draw with straight away: every family this machine has
	 installed, and a face for text and a face for code chosen among them. Upstream builds the
	 same pair lazily in its globalInstance, from the font bytes its own package carries and
	 through FreeType; these two are files of the machine read in Pharo, which is what the
	 count of AeFTFace instances states."
	| before manager |
	before := AeFTFace allInstances size.
	manager := VGFontManager newWithDefaultFaces.
	self
		assert: manager familyNames asArray
		equals: manager catalogue familyNames asArray.
	self assert: (manager includesFamilyName: manager defaultFace familyName).
	self assert:
		(manager includesFamilyName: manager defaultCodeFace familyName).
	self assert: manager defaultFace class equals: VGFontFace.
	self assert: manager defaultCodeFace class equals: VGFontFace.
	self assert: AeFTFace allInstances size equals: before
]

{ #category : 'tests' }
VGFontManagerTest >> testAManagerLeftOverFromAnotherSessionRebuildsItselfBeforeAnsweringAnything [
	"Upstream resets a manager whose session is not this one, because the faces of a dead
	 session are handles into a library that is gone. Mine holds no handle, but the rule is the
	 same and checkSession is what keeps it. So every reader of mine asks through an accessor
	 that checks, the catalogue included, and so does every row of my views. The cache is asked
	 last here on purpose: asking it first would reset the manager and the other readers would
	 then answer empty whether they check or not."

	| manager entry rows |
	manager := VGFontManager new.
	entry := manager registerFacesOnMemory:
		         AeSourceSansPro_Regular fontContentsData.
	manager faceAt: entry.
	manager instVarNamed: 'session' put: Object new.
	self assert: manager faceEntries isEmpty.
	self assert: manager familyNames isEmpty.
	self assert: manager rejectedFiles isEmpty.
	rows := (manager inspectorState:
		         (SpPresenterBuilder newApplication: SpApplication new)) items.
	self
		assert: (rows detect: [ :each | each key = 'Files met' ]) value
		equals: 0.
	self
		assert: (rows detect: [ :each | each key = 'Faces kept' ]) value
		equals: 0.
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
VGFontManagerTest >> testAskingForADefaultFaceNoFamilyOfTheListCanGiveRefusesByName [
	"The degenerate machine: none of the families a preference list names is installed. The
	 refusal is a class of its own, so a test and a caller can tell it from any other error,
	 and it says both what was looked for and how many families there were to look through —
	 an empty manager and a manager full of other families are different mistakes."
	| manager error |
	manager := VGFontManager new.
	error := nil.
	[
	manager defaultFaceOfFirstFamilyNamedIn:
		#( 'No Such Family' 'Nor This One' ) ]
		on: VGFontManagerHasNoUsableFamily
		do: [ :each | error := each ].
	self assert: error notNil.
	self
		assert: error familyNames asArray
		equals: #( 'No Such Family' 'Nor This One' ).
	self assert: error familyCount equals: 0.
	self assert: (error messageText includesSubstring: 'No Such Family').
	self assert: (error messageText includesSubstring: 'Nor This One').
	self assert: (error messageText includesSubstring: '0 families')
]

{ #category : 'tests' }
VGFontManagerTest >> testAskingForTheFaceOfARejectedFileSaysWhichFileAndWhy [
	"A reader holds my rejected files since unit 3.3, so one of them can be handed back to me.
	 The reader of 1.3 has already said no to those bytes, so I say so by name rather than
	 letting the font parser run off the end of them, and rather than the cache's own
	 KeyNotFound, which says nothing of the rejection."

	| directory manager error |
	directory := FileSystem memory root / 'fonts'.
	directory ensureCreateDirectory.
	(directory / 'readme.txt') writeStreamDo: [ :stream |
		stream nextPutAll: 'not a font' ].
	manager := VGFontManager new.
	manager scanDirectory: directory.
	error := [
	         manager faceAt: manager rejectedFiles anyOne.
	         nil ]
		         on: Error
		         do: [ :each | each ].
	self assert: error notNil.
	self deny: (error isKindOf: KeyNotFound).
	self assert: (error messageText includesSubstring: 'rejected').
	self assert: (error messageText includesSubstring: 'readme.txt').
	self assert: (error messageText includesSubstring: 'notAnSfntFont').
	self assert: manager faceByEntryCache isEmpty
]

{ #category : 'tests' }
VGFontManagerTest >> testTheCacheViewListsWhatAFaceReadAndTheFacesViewSaysWhichAreBuilt [
	"The two tables that show the laziness of unit 3.4: the Faces tab marks the one entry
	 something has drawn with, and the Cache tab lists the face itself, asking the face for what
	 it parsed. A manager that has drawn with nothing offers no Cache tab at all."

	| manager builder faceTable built cacheRows context |
	manager := VGFontManager new.
	AeEmbeddedFontFile allSubclassesDo: [ :each |
		manager registerFacesOnMemory: each fontContentsData ].
	context := StInspectionContext new.
	manager inspectorCacheContext: context.
	self deny: context isActive.
	manager
		detectFamilyName: 'Source Sans Pro'
		slant: AeFontSlant normal
		weight: AeFontWeight normal
		stretch: AeFontStretch normal
		ifNone: [ self fail: 'the entry is there to be found' ].
	builder := SpPresenterBuilder newApplication: SpApplication new.
	faceTable := manager inspectionFaces: builder.
	built := faceTable items select: [ :each |
		         (faceTable columns last evaluation value: each) = 'yes' ].
	self assert: faceTable items size equals: 6.
	self assert: (built collect: [ :each | each styleName ]) asArray equals: #( 'Regular' ).
	self assert: built first familyName equals: 'Source Sans Pro'.
	cacheRows := (manager inspectorCache: builder) items.
	self assert: cacheRows size equals: 1.
	self assert: cacheRows first familyName equals: 'Source Sans Pro'.
	self assert: cacheRows first unitsPerEm equals: 1000.
	context := StInspectionContext new.
	manager inspectorCacheContext: context.
	self assert: context isActive
]

{ #category : 'tests' }
VGFontManagerTest >> testTheDefaultFacesComeFromTheMachineAndNotFromEmbeddedBytes [
	"The two faces Bloc falls back on, for text and for code, are faces of this machine read
	 from a file on disk. Nothing of the manager names a font another package carries in its
	 image, which is what lets a consumer draw with Alexandrie-FreeType out of the image.
	 Each default is the first family of its preference list that the machine holds, so the
	 test states the rule rather than the name this machine happens to answer."
	| manager textEntry codeEntry |
	manager := VGFontManager newWithDefaultFaces.
	self
		assert: manager defaultFace familyName
		equals: (VGFontManager preferredTextFamilyNames detect: [ :each |
				 manager includesFamilyName: each ]).
	self
		assert: manager defaultCodeFace familyName
		equals: (VGFontManager preferredCodeFamilyNames detect: [ :each |
				 manager includesFamilyName: each ]).
	textEntry := manager catalogue entryOfFamilyNamed:
		             manager defaultFace familyName.
	codeEntry := manager catalogue entryOfFamilyNamed:
		             manager defaultCodeFace familyName.
	self assert: (textEntry source isKindOf: AbstractFileReference).
	self assert: (codeEntry source isKindOf: AbstractFileReference).
	self deny: (manager faceEntries anySatisfy: [ :each |
			 each source isKindOf: ByteArray ])
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
	"The whole route a consumer takes: a family and Alexandrie's three category objects in, the
	 face out. It reaches the catalogue's index and then my cache, not the slot upstream keeps
	 its index in, which stays empty — a lookup through that slot would answer the absent block
	 for every family I hold. Until unit 3.4 it stopped at the cache and signalled KeyNotFound."

	| manager entry face |
	manager := VGFontManager new.
	entry := manager registerFacesOnMemory:
		         AeSourceSansPro_Regular fontContentsData.
	face := manager
		        detectFamilyName: 'Source Sans Pro'
		        slant: AeFontSlant normal
		        weight: AeFontWeight normal
		        stretch: AeFontStretch normal
		        ifNone: [ self fail: 'the entry is there to be found' ].
	self assert: face identicalTo: (manager faceAt: entry).
	self assert: face styleName equals: 'Regular'
]

{ #category : 'tests' }
VGFontManagerTest >> testTheFilesRejectedAreKeptWithTheirReasonAndAFreshManagerRejectedNone [
	"A file I met and will not draw with is not dropped: I answer for it, with the reason the
	 reader gave, so a reader asking why a family is missing has somewhere to look. A manager
	 that has met nothing rejects nothing."

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
VGFontManagerTest >> testTheRefusalViewListsTheFamiliesLookedForAndWhetherTheMachineHasThem [
	"The Families view of the refusal: one row per family looked for, in the order it was
	 preferred, and a last column that asks this machine rather than the refusal. Two names no
	 machine has are absent on any reader's machine, and the family the manager chose off this
	 machine reads installed."
	| refusal table rows manager |
	refusal := nil.
	[
	VGFontManager new defaultFaceOfFirstFamilyNamedIn:
		#( 'No Font Like This' 'Nor This One Either' ) ]
		on: VGFontManagerHasNoUsableFamily
		do: [ :each | refusal := each ].
	table := refusal inspectorFamilies:
		         (SpPresenterBuilder newApplication: SpApplication new).
	rows := table items asArray.
	self assert: (rows collect: [ :each | each value ]) equals:
		#( 'No Font Like This' 'Nor This One Either' ).
	self assert: (rows collect: [ :each | each key ]) equals: #( 1 2 ).
	self
		assert: (table columns last evaluation value: rows first)
		equals: 'absent'.
	manager := VGFontManager newWithDefaultFaces.
	self
		assert:
		(table columns last evaluation value: 1 -> manager defaultFace familyName)
		equals: 'installed'
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
