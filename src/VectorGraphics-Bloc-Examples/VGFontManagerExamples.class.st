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
