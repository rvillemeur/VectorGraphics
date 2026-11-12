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
