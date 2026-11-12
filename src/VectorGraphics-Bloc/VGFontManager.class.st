"
I am the font registry Bloc asks for its faces, and I hold no FreeType library.

Upstream `AeFontManager` keeps an `AeFTLibrary`, reads every font through it, and caches the `AeFTFace` handles it builds in an `LRUCache` capped at twenty. I keep the same registry of entries by family name, so what Bloc asks of me it would ask of upstream, and I answer it from `VGFontFace`, which reads a font's own bytes in Pharo and owns no handle at all. That is why my face cache is a plain `Dictionary`: what it holds costs to parse again and nothing to release, so a face lives for the session rather than being evicted.

What I register is still ahead of me. The three inherited ways into the registry — `registerFacesOnFile:`, `registerFacesOnMemory:` and, through the second of them, `scanEmbeddedFonts` — all read a font through the library I do not have, and `scanDefaultDirectories` drives a scanner that does the same. Each refuses by name until `TTFontCatalogue` takes that job over, which is unit 3.2 of the font plan. `faceAt:` is likewise still the inherited one, which answers from my cache and raises on a miss, until unit 3.4 builds the face.
"
Class {
	#name : 'VGFontManager',
	#superclass : 'AeFontManager',
	#category : 'VectorGraphics-Bloc-Fonts',
	#package : 'VectorGraphics-Bloc',
	#tag : 'Fonts'
}

{ #category : 'inspector' }
VGFontManager >> inspectorState: aBuilder [
	<inspectorPresentationOrder: 10 title: 'State'>
	"What a session of mine holds. Every row asks the real object rather than restating what reset
	 writes, so a row cannot drift from the code: the library row prints the slot, the cache rows
	 print its class and its size, and the family row counts the registry. A fresh manager shows
	 nil, a Dictionary, and three zeroes, which is the whole of what this unit claims."

	^ aBuilder newTable
		  items: {
				  ('Session' -> session).
				  ('FreeType library' -> freetypeLibrary).
				  ('Face cache' -> faceByEntryCache class).
				  ('Faces kept' -> faceByEntryCache size).
				  ('Families registered' -> entriesByFamilyName size).
				  ('Entries registered' -> self faceEntries size).
				  ('Default face' -> defaultFace).
				  ('Default code face' -> defaultCodeFace) };
		  addColumn: (SpStringTableColumn title: 'Property' evaluated: [ :each | each key ]);
		  addColumn: (SpStringTableColumn
				   title: 'Value'
				   evaluated: [ :each | each value printString ]);
		  yourself
]

{ #category : 'inspector' }
VGFontManager >> inspectorStateContext: aContext [
	"Always on: every row reads a slot that reset writes, so there is no half built manager for
	 this view to show nils for."

	aContext active: true
]

{ #category : 'registering' }
VGFontManager >> refuseUntilTheCatalogueRegisters [
	"The one refusal the three inherited ways into the registry share, and the one place the plan
	 is named: it is this whole method that unit 3.2 of the font plan deletes. The message says
	 only what holds for a reader of this manager, so it names the catalogue, which is what will
	 do the reading, and no unit of a plan that reader has never seen."

	^ Error signal:
		  'this manager registers no font yet: the font catalogue reads the fonts, and this '
		  , 'manager does not read it yet'
]

{ #category : 'registering' }
VGFontManager >> registerFacesOnFile: aFileReference [
	"Refused: the inherited method reads the faces of the file through the FreeType library this
	 manager does not have. The catalogue reads them instead."

	^ self refuseUntilTheCatalogueRegisters
]

{ #category : 'registering' }
VGFontManager >> registerFacesOnMemory: aByteArray [
	"Refused, like registerFacesOnFile:, and for the same reason. scanEmbeddedFonts reaches the
	 registry through this method, so it refuses with it and needs no override of its own."

	^ self refuseUntilTheCatalogueRegisters
]

{ #category : 'initialization' }
VGFontManager >> reset [
	"The state a session owns, built without a foreign library. Two slots differ from upstream.

	 freetypeLibrary stays nil: there is no FreeType to initialise, and nothing here owns a
	 handle that would have to be released.

	 faceByEntryCache is a plain Dictionary where upstream keeps an LRUCache capped at twenty
	 faces. Upstream has to cap, because what it caches is an AeFTFace, a handle; what is cached
	 here is a VGFontFace, parsed tables and a glyph memo in object memory, which costs to read
	 again and nothing to let go of. So a face is kept for the session rather than evicted.

	 session is set because checkSession resets whenever it differs, and would reset forever if
	 this method left it alone."

	session := Smalltalk session.
	entriesByFamilyName := Dictionary new.
	defaultFace := nil.
	defaultCodeFace := nil.
	freetypeLibrary := nil.
	faceByEntryCache := Dictionary new
]

{ #category : 'scanning' }
VGFontManager >> scanDefaultDirectories [
	"Refused: the inherited method drives an AeFontScanner, which registers every file it meets
	 through the library this manager does not have. TTFontCatalogue already scans those same
	 directories."

	^ self refuseUntilTheCatalogueRegisters
]
