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
VGFontManagerTest >> testRegistrationRefusesByNameRatherThanFailingOnTheMissingLibrary [
	"Every inherited way into the registry reads the font through the FreeType library this
	 manager does not have. Until the catalogue takes that job over, each one says so, because a
	 reader who calls it should read the reason and not `UndefinedObject >> fastReadFacesOn:do:`."

	| manager calls |
	manager := VGFontManager new.
	calls := {
		         [ manager registerFacesOnFile: Smalltalk imageDirectory / 'absent.ttf' ].
		         [ manager registerFacesOnMemory: #[ 0 0 0 0 ] ].
		         [ manager scanDefaultDirectories ].
		         [ manager scanEmbeddedFonts ] }.
	calls do: [ :each |
		| raised |
		raised := each on: Error do: [ :error | error ].
		self deny: (raised isKindOf: MessageNotUnderstood).
		self assert: (raised messageText includesSubstring: 'catalogue') ]
]
