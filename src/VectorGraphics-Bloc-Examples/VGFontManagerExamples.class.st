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
VGFontManagerExamples class >> managerWithoutALibrary [
	<sampleInstance>
	"A font manager that owns no FreeType library. Open the State tab: the library slot is
	 nil where upstream holds an AeFTLibrary, and the face cache is a Dictionary where
	 upstream holds an LRUCache capped at twenty faces."

	^ VGFontManager new
]
