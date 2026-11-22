Extension { #name : 'AeFontManager' }

{ #category : '*vectorgraphics-bloc-fontengine' }
AeFontManager >> buildsFacesOfThisProject [
	"Extension on AeFontManager, in this package because the two kits are told apart by the
	 face a manager builds and upstream has no word for it. Upstream builds an AeFTFace,
	 whose glyphs are read through FreeType."

	^ false
]
