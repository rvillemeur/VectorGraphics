"
I hold the runnable examples of `VGFontManager`. Each one rebuilds its manager, so clicking an example twice shows the same thing twice, and none of them registers a font while registration is still the catalogue's job to come.
"
Class {
	#name : 'VGFontManagerExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Bloc-Examples',
	#package : 'VectorGraphics-Bloc-Examples'
}

{ #category : 'examples' }
VGFontManagerExamples class >> managerReadyToDrawDefaultText [
	<sampleInstance>
	"A font manager that can draw before anything registers anything: every font this machine
	 has installed, and the two faces a text falls back on, one for text and one for code,
	 chosen as the first family of each preference list the machine holds. Open the State tab,
	 where the Default face and Default code face rows name them — the same manager as
	 managerThatScannedTheInstalledFonts shows those two rows as nil. The families named are
	 this machine's, so they differ from one reader to the next."
	^ VGFontManager newWithDefaultFaces
]

{ #category : 'examples' }
VGFontManagerExamples class >> managerThatScannedTheInstalledFonts [
	<sampleInstance>
	"A font manager that met every font file this machine has installed, read by the catalogue
	 and not by FreeType. Open the State tab: the files met split into the entries registered,
	 which are the faces with a glyf table we can draw, and the files rejected, which are the
	 OpenType CFF fonts, the Type 1 fonts and the collections this project does not read yet.
	 Dive into the catalogue for the Rejections tab, which groups those files by the reason they
	 gave. The numbers are this machine's, so they differ from one reader to the next."

	^ VGFontManager new
		  scanDefaultDirectories;
		  yourself
]

{ #category : 'examples' }
VGFontManagerExamples class >> managerWithAFaceBuiltForEveryEmbeddedFont [
	<sampleInstance>
	"A font manager that has drawn with every font a package carries with it: the six faces are
	 parsed out of their own bytes, by our reader and not by FreeType, and kept for the session.
	 Open the Cache tab for what each face read out of its font, and the Faces tab, where the
	 last column now says yes on every row. The manager of managerWithTheEmbeddedFontsRegistered
	 is the same one before anything drew with it: entries registered, no face built."

	| manager |
	manager := self managerWithTheEmbeddedFontsRegistered.
	manager faceEntries do: [ :each | manager faceAt: each ].
	^ manager
]

{ #category : 'examples' }
VGFontManagerExamples class >> managerWithTheEmbeddedFontsRegistered [
	<sampleInstance>
	"A font manager holding the six faces a package carries with it, read by the catalogue and
	 not by FreeType. Open the Faces tab to read what the font itself states of each one — its
	 style name, its slant, its OS/2 weight class and width class — and the State tab to see the
	 same six counted, with the FreeType slot still nil."

	| manager |
	manager := VGFontManager new.
	AeEmbeddedFontFile allSubclassesDo: [ :each |
		manager registerFacesOnMemory: each fontContentsData ].
	^ manager
]

{ #category : 'examples' }
VGFontManagerExamples class >> managerWithoutALibrary [
	<sampleInstance>
	"A font manager that owns no FreeType library. Open the State tab: the library slot is
	 nil where upstream holds an AeFTLibrary, and the face cache is a Dictionary where
	 upstream holds an LRUCache capped at twenty faces."

	^ VGFontManager new
]

{ #category : 'examples' }
VGFontManagerExamples class >> refusalOfAMachineHoldingNoPreferredFamily [
	<sampleInstance>
	"The refusal a manager raises when none of the families it would take a default face from
	 is installed. Raised here against two names no machine has, so the example reads the same
	 everywhere. Open the Families tab: the two names are listed in the order they were
	 preferred, and the last column says absent for both — a name a reader installs meanwhile
	 would read installed, because the column asks the machine and not the refusal."
	^ [
	  VGFontManager new defaultFaceOfFirstFamilyNamedIn:
		  #( 'No Font Like This' 'Nor This One Either' ) ]
		  on: VGFontManagerHasNoUsableFamily
		  do: [ :each | each ]
]
