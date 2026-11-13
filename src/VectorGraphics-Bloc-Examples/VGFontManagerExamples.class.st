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
VGFontManagerExamples class >> managerBlocAsksToday [
	<sampleInstance>
	"The font manager every consumer of a face reaches in this image right now. Bloc asks for
	 it through BlFont >> asAeFTFace, which goes to BAFontConverter >> faceFor:, which sends
	 AeFontManager globalInstance — so this one click answers which reader of fonts the image
	 draws with. An AeFontManager, and the faces are FreeType handles; a VGFontManager, and
	 unit 3.5 of the font plan has installed ours, which reads fonts in Pharo.
	 Builds Alexandrie's own manager if nobody has asked yet, which is what Bloc would do on
	 the first text it drew."

	^ AeFontManager globalInstance
]

{ #category : 'examples' }
VGFontManagerExamples class >> managerReadyToDrawDefaultText [
	<sampleInstance>
	"A font manager that can draw before anything registers anything. Six faces from the fonts
	 a package carries with it, and the two faces a text falls back on: Source Sans Pro for
	 text, Source Code Pro for code. Open the State tab, where the Default face and Default
	 code face rows name them — the same manager as
	 managerWithTheEmbeddedFontsRegistered shows those two rows as nil."

	^ VGFontManager newWithDefaultFaces
]

{ #category : 'examples' }
VGFontManagerExamples class >> managerThatScannedTheInstalledFonts [
	<sampleInstance>
	"A font manager that met every font file this machine has installed, read by the catalogue
	 and not by FreeType. Open the State tab: the files met split into the entries registered,
	 which are the faces with a glyf table we can draw, and the files refused, which are the
	 OpenType CFF fonts, the Type 1 fonts and the collections this project does not read yet.
	 Dive into the catalogue for the Refusals tab, which groups those files by the reason they
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
