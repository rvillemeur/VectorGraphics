"
I am the font registry Bloc asks for its faces, and I hold no FreeType library.

Upstream `AeFontManager` keeps an `AeFTLibrary`, reads every font through it, and caches the `AeFTFace` handles it builds in an `LRUCache` capped at twenty. I answer the same questions, so what Bloc asks of me it would ask of upstream, and I answer them from `VGFontFace`, which reads a font's own bytes in Pharo and owns no handle at all. That is why my face cache is a plain `Dictionary`: what it holds costs to parse again and nothing to release, so a face lives for the session rather than being evicted.

What I register, I register through `TTFontCatalogue`, which I own for the session. Every inherited way into the registry delegates to it — `registerFacesOnFile:` to `addFile:`, `registerFacesOnMemory:` to `addBytes:`, `scanDirectory:` and `scanDefaultDirectories` to its own, and `scanEmbeddedFonts` through the second of those without an override. The catalogue reads a few hundred bytes of each file, never the whole face, and judges a file by its content rather than by its name, so a font under an unexpected name is registered and a file that is not a font is a refusal it keeps.

The catalogue is my only index, which is why the four inherited readers of `entriesByFamilyName` are overridden: each one reads that instance variable directly, and mine stays empty. It keys a family by name in lower case and then by what the font states of itself — its slant, its OS/2 weight class, its width class. Alexandrie keys by `AeFontSlant`, `AeFontWeight` and `AeFontStretch` read off the style name instead, and `entryForFamilyName:slant:weight:stretch:ifNone:` is the one place the two vocabularies meet.

`faceAt:` is still the inherited one, which answers from my cache and raises on a miss, until unit 3.4 of the font plan builds the face.
"
Class {
	#name : 'VGFontManager',
	#superclass : 'AeFontManager',
	#instVars : [
		'catalogue'
	],
	#category : 'VectorGraphics-Bloc-Fonts',
	#package : 'VectorGraphics-Bloc',
	#tag : 'Fonts'
}

{ #category : 'accessing' }
VGFontManager >> catalogue [
	"The one index I answer from: which families exist, where the bytes of each face are, and
	 the slant, weight class and width class that tell two faces of one family apart. Mine for
	 the session, read-only from outside, and the reader a consumer of my own faces shares when
	 it wants the same discovery without going through me."

	^ catalogue
]

{ #category : 'accessing' }
VGFontManager >> detectFamilyName: aFamilyName slant: aSlant weight: aWeight stretch: aStretch ifNone: absentBlock [
	"The face a consumer draws with, asked for by family and by Alexandrie's three category
	 objects. Upstream's reads the instance variable this manager leaves empty, so it would
	 answer the absent block for every family the catalogue holds."

	| entry |
	entry := self
		         entryForFamilyName: aFamilyName
		         slant: aSlant
		         weight: aWeight
		         stretch: aStretch
		         ifNone: [ ^ absentBlock value ].
	^ self faceAt: entry
]

{ #category : 'accessing' }
VGFontManager >> entriesByFamilyName [
	"The faces I answer for, keyed as the catalogue keys them: family name in lower case, then
	 the slant, weight class and width class of the face. Not upstream's key, which is a triple
	 of AeFontSlant, AeFontWeight and AeFontStretch read off the style name; the translation
	 between the two lives in entryForFamilyName:slant:weight:stretch:ifNone:, the one place a
	 consumer asks in Alexandrie's vocabulary."

	^ catalogue entriesByFamilyName
]

{ #category : 'accessing' }
VGFontManager >> entryForFamilyName: aFamilyName slant: aSlant weight: aWeight stretch: aStretch ifNone: absentBlock [
	"One face of a family, asked for the way Alexandrie asks: a family name and three of its
	 font category objects. This is the one place the two vocabularies meet, and the three
	 translations are exact rather than approximate, which is why they run in this direction
	 only. A slant answers its name, the same symbol the metadata reader states. An AeFontWeight
	 answers the OS/2 weight class itself — normal is 400, bold is 700. An AeFontStretch answers
	 the OS/2 width class less one, since it counts ultraCondensed from zero where OS/2 counts
	 it from one. The catalogue does the looking up: how it keys a family and a style is its
	 own."

	^ catalogue
		  entryOfFamilyNamed: aFamilyName
		  styleKey: {
				  aSlant name.
				  aWeight value.
				  aStretch value + 1 }
		  ifNone: absentBlock
]

{ #category : 'accessing' }
VGFontManager >> faceEntries [
	"Every face I answer for, refusals left out. Upstream collects these out of its own index;
	 the catalogue selects them out of everything it met, so a refused file is still there to
	 report and is not one of these."

	^ catalogue drawableEntries
]

{ #category : 'accessing' }
VGFontManager >> familyNames [
	"The families I hold, as their own fonts spell them rather than as the catalogue keys them,
	 sorted. A consumer shows these to a reader."

	^ catalogue familyNames
]

{ #category : 'testing' }
VGFontManager >> includesFamilyName: aString [
	"Whether a family is here to be drawn with. Upstream's reads the instance variable this
	 manager leaves empty; the catalogue holds the index and answers in any case."

	^ catalogue includesFamilyNamed: aString
]

{ #category : 'inspecting' }
VGFontManager >> inspectionFaces: aBuilder [
	<inspectorPresentationOrder: 1 title: 'Faces'>
	"The faces I answer for, each row reading the entry rather than a copy of it. Upstream's
	 table of the same name shows the slant, weight and stretch its style-name parser guessed;
	 these columns show what the font itself states in its OS/2 table, which is where my key
	 comes from, so a row says why a face answers the triple it answers. Sorted the way upstream
	 sorts, family first, then by the style name the font states."

	^ aBuilder newTable
		  items: (self faceEntries asArray sorted:
					   (#familyName ascending , #styleName ascending));
		  addColumn: (SpStringTableColumn title: 'Family name' evaluated: #familyName);
		  addColumn: (SpStringTableColumn title: 'Style' evaluated: #styleName);
		  addColumn: (SpStringTableColumn
				   title: 'Slant'
				   evaluated: [ :each | each metadata slant ]);
		  addColumn: (SpStringTableColumn
				   title: 'Weight class'
				   evaluated: [ :each | each metadata weightClass ]);
		  addColumn: (SpStringTableColumn
				   title: 'Width class'
				   evaluated: [ :each | each metadata widthClass ]);
		  yourself
]

{ #category : 'inspecting' }
VGFontManager >> inspectionFacesContext: aContext [
	"Shown only when I hold a face. A fresh manager has an empty table to offer and the State
	 tab says all there is to say about it."

	aContext active: self faceEntries notEmpty
]

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
VGFontManager >> registerFacesOnFile: aFileReference [
	"Meet the face of one file. The catalogue reads its metadata off the stream, a few hundred
	 bytes of a file that may be megabytes, where upstream read the whole face through FreeType.
	 One face per file, never several: 1.3 of the font plan refuses a ttcf collection, so the
	 index upstream iterates is always zero. Answers the entry, refused or not, which upstream
	 had nothing to answer."

	^ catalogue addFile: aFileReference
]

{ #category : 'registering' }
VGFontManager >> registerFacesOnMemory: aByteArray [
	"Meet the face of a font nobody wrote to disk: the embedded faces of a package, a font built
	 in a test. scanEmbeddedFonts reaches the registry through this method, so it needs no
	 override of its own. Answers the entry, like registerFacesOnFile:."

	^ catalogue addBytes: aByteArray
]

{ #category : 'initialization' }
VGFontManager >> reset [
	"The state a session owns, built without a foreign library. Three slots differ from upstream.

	 freetypeLibrary stays nil: there is no FreeType to initialise, and nothing here owns a
	 handle that would have to be released. A catalogue reads the fonts instead, and it is mine
	 for the session, as 1.4 of the font plan decided: no singleton and no global catalogue.

	 faceByEntryCache is a plain Dictionary where upstream keeps an LRUCache capped at twenty
	 faces. Upstream has to cap, because what it caches is an AeFTFace, a handle; what is cached
	 here is a VGFontFace, parsed tables and a glyph memo in object memory, which costs to read
	 again and nothing to let go of. So a face is kept for the session rather than evicted.

	 entriesByFamilyName stays empty: the catalogue holds the only index, and the four inherited
	 readers of this slot are overridden to read it. The slot cannot be removed, since it is
	 upstream's.

	 session is set because checkSession resets whenever it differs, and would reset forever if
	 this method left it alone."

	session := Smalltalk session.
	entriesByFamilyName := Dictionary new.
	defaultFace := nil.
	defaultCodeFace := nil.
	freetypeLibrary := nil.
	faceByEntryCache := Dictionary new.
	catalogue := TTFontCatalogue new
]

{ #category : 'scanning' }
VGFontManager >> scanDefaultDirectories [
	"Meet every font this machine has installed, through the catalogue's own list of the places
	 a platform keeps them. A directory that does not exist is passed over."

	^ catalogue scanDefaultDirectories
]

{ #category : 'scanning' }
VGFontManager >> scanDirectory: aFileReference [
	"Meet every file under this directory. The catalogue hands each one to its reader and reads
	 no file name, where upstream drives an AeFontScanner whose shouldIgnoreFile: decides from
	 the name and the extension. Decision 6 of unit 1.4 of the font plan: one rule is enough,
	 and it is the refusal by content, so a font with an unexpected name is read and a file that
	 is not a font becomes a refused entry rather than a file silently passed over."

	^ catalogue scanDirectory: aFileReference
]
