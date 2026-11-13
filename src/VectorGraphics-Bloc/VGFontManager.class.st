"
I am the font registry Bloc asks for its faces, and I hold no FreeType library.

Upstream `AeFontManager` keeps an `AeFTLibrary`, reads every font through it, and caches the `AeFTFace` handles it builds in an `LRUCache` capped at twenty. I answer the same questions, so what Bloc asks of me it would ask of upstream, and I answer them from `VGFontFace`, which reads a font's own bytes in Pharo and owns no handle at all. That is why my face cache is a plain `Dictionary`: what it holds costs to parse again and nothing to release, so a face lives for the session rather than being evicted.

What I register, I register through `TTFontCatalogue`, which I own for the session. Every inherited way into the registry delegates to it — `registerFacesOnFile:` to `addFile:`, `registerFacesOnMemory:` to `addBytes:`, `scanDirectory:` and `scanDefaultDirectories` to its own, and `scanEmbeddedFonts` through the second of those without an override. The catalogue reads a few hundred bytes of each file, never the whole face, and judges a file by its content rather than by its name, so a font under an unexpected name is registered and a file that is not a font is a refusal it keeps.

The catalogue is my only index, which is why the four inherited readers of `entriesByFamilyName` are overridden: each one reads that instance variable directly, and mine stays empty. It keys a family by name in lower case and then by what the font states of itself — its slant, its OS/2 weight class, its width class. Alexandrie keys by `AeFontSlant`, `AeFontWeight` and `AeFontStretch` read off the style name instead, and `entryForFamilyName:slant:weight:stretch:ifNone:` is the one place the two vocabularies meet.

`faceAt:` builds the face from the entry's own bytes and keeps it, so a font is read once a session draws with it and never again; a file the reader refused is named in an error rather than parsed a second time. Every reader of mine asks through an accessor that checks the session first, so a manager left over from a dead session rebuilds its catalogue before it answers.

Nothing of mine is posed anywhere until `installGlobally` is sent. It is my class that keeps what was posed, writes it into the slot `AeFontManager` answers `globalInstance` from, and puts it back from `startUp:` after upstream nils that slot at every image start. An image that installed nothing keeps the manager Alexandrie built for itself.
"
Class {
	#name : 'VGFontManager',
	#superclass : 'AeFontManager',
	#instVars : [
		'catalogue'
	],
	#classInstVars : [
		'installedInstance'
	],
	#category : 'VectorGraphics-Bloc-Fonts',
	#package : 'VectorGraphics-Bloc',
	#tag : 'Fonts'
}

{ #category : 'class initialization' }
VGFontManager class >> initialize [
	"Register for the image start. The priority is 115: above the 110 where upstream registers
	 the reset that nils the manager, and below the 120 where AeCanvas initialises its font
	 options. Registering at 110 would work only while our package happens to load after
	 Alexandrie, since a priority list keeps the order it was registered in."

	SessionManager default
		registerGuiClassNamed: self name
		atPriority: 115
]

{ #category : 'inspector' }
VGFontManager class >> inspectorInstallation: aBuilder [

	<inspectorPresentationOrder: 1 title: 'Installation'>
	"Whether this project has posed a font manager as the one Bloc asks for its faces, and what
	 that manager knows. Reads my own slot only: sending AeFontManager globalInstance would
	 build a complete FreeType manager at the moment a reader opens an inspector, which is the
	 opposite of what this unit is for. The example managerBlocAsksToday is where one asks the
	 real route and accepts that it builds."

	| manager |
	manager := installedInstance.
	^ aBuilder newTable
		  items: {
				  ('Installed manager' -> manager).
				  ('Families' -> (manager ifNil: [ 0 ] ifNotNil: [ :each | each familyNames size ])).
				  ('Entries' -> (manager ifNil: [ 0 ] ifNotNil: [ :each | each faceEntries size ])).
				  ('Faces built' -> (manager ifNil: [ 0 ] ifNotNil: [ :each | each faceByEntryCache size ])) };
		  addColumn:
			  (SpStringTableColumn title: 'Property' evaluated: [ :each | each key ]);
		  addColumn: (SpStringTableColumn
				   title: 'Value'
				   evaluated: [ :each | each value printString ]);
		  yourself
]

{ #category : 'installing' }
VGFontManager class >> installGlobally [
	"Make a manager of mine the one every consumer of a face reaches through
	 AeFontManager globalInstance. The manager is empty: it knows no family until something
	 scans or registers, which unit 3.6 of the font plan will do for the default families.
	 Kept here as well as written upstream, so that startUp: can put the same object back after
	 upstream nils its slot at every image start, and so that nothing of mine has to read a
	 slot of Alexandrie's to know what it posed."

	installedInstance := self new.
	AeFontManager globalInstance: installedInstance.
	^ installedInstance
]

{ #category : 'accessing' }
VGFontManager class >> installedInstance [
	"The manager I posed as the one Bloc asks for its faces, or nil if I posed none. One slot
	 rather than a flag beside a manager: two pieces of state could fall out of step, and the
	 question 'is our manager installed' is answered by whether this is nil."

	^ installedInstance
]

{ #category : 'system startup' }
VGFontManager class >> startUp: isResuming [
	"Put my manager back after upstream nils its slot. I am registered at GUI priority 115 and
	 upstream at 110, and a category starts its handlers by rising priority, so this runs after
	 its reset and before AeCanvas initialises its font options at 120.
	 I run in every image this package is loaded in, installed or not, so a nil slot of mine
	 means hands off: upstream keeps whatever manager it built.
	 The manager kept here is the one the dead session held. It answers nothing of that session:
	 every reader of it checks the session first and rebuilds its catalogue, which is what unit
	 3.4 is for."

	isResuming ifFalse: [ ^ self ].
	installedInstance ifNil: [ ^ self ].
	AeFontManager globalInstance: installedInstance
]

{ #category : 'installing' }
VGFontManager class >> uninstallGlobally [
	"Stop being the manager Bloc asks, and leave upstream to rebuild its own. Upstream's slot
	 goes to nil rather than back to whatever was there: its globalInstance builds a manager
	 lazily, which is the state an image that never met this project is in."

	installedInstance := nil.
	AeFontManager globalInstance: nil
]

{ #category : 'accessing' }
VGFontManager >> catalogue [
	"The one index I answer from: which families exist, where the bytes of each face are, and
	 the slant, weight class and width class that tell two faces of one family apart. Mine for
	 the session, read-only from outside, and the reader a consumer of my own faces shares when
	 it wants the same discovery without going through me.
	 Checks the session first, as upstream's four accessors do with the slots they guard. An
	 entry met in another session names bytes nobody here has read, so a manager left over from
	 a dead session rebuilds before it answers. Every reader and every writer of mine asks
	 through this accessor rather than the slot, so the check cannot be walked around."

	self checkSession.
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

	^ self catalogue entriesByFamilyName
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

	^ self catalogue
		  entryOfFamilyNamed: aFamilyName
		  styleKey: {
				  aSlant name.
				  aWeight value.
				  aStretch value + 1 }
		  ifNone: absentBlock
]

{ #category : 'accessing' }
VGFontManager >> faceAt: anEntry [
	"The face of one entry, parsed once and then kept. Upstream's answers whatever its LRU
	 cache holds and builds nothing, since its cache was given a factory that calls FreeType;
	 mine builds the face here, out of the bytes the entry names.
	 The bytes are read at this point and not before: a catalogue that scanned this machine
	 knows 544 files and 262 MB in all, and a session draws with a handful of them.
	 A refused entry is named rather than parsed. The reader already said why it would not
	 read the file, so the error repeats that reason instead of letting a parse fail a second
	 time, deeper, on the same bytes.
	 The cache is asked through its accessor, which checks the session first, as upstream's
	 does."

	anEntry isRejected ifTrue: [ ^ self refuseFaceFor: anEntry ].
	^ self faceByEntryCache
		  at: anEntry
		  ifAbsentPut: [ VGFontFace newForBytes: anEntry bytes ]
]

{ #category : 'accessing' }
VGFontManager >> faceEntries [
	"Every face I answer for, refusals left out. Upstream collects these out of its own index;
	 the catalogue selects them out of everything it met, so a refused file is still there to
	 report and is not one of these."

	^ self catalogue drawableEntries
]

{ #category : 'accessing' }
VGFontManager >> familyNames [
	"The families I hold, as their own fonts spell them rather than as the catalogue keys them,
	 sorted. A consumer shows these to a reader."

	^ self catalogue familyNames
]

{ #category : 'testing' }
VGFontManager >> includesFamilyName: aString [
	"Whether a family is here to be drawn with. Upstream's reads the instance variable this
	 manager leaves empty; the catalogue holds the index and answers in any case."

	^ self catalogue includesFamilyNamed: aString
]

{ #category : 'inspecting' }
VGFontManager >> inspectionFaces: aBuilder [
	<inspectorPresentationOrder: 1 title: 'Faces'>
	"The faces I answer for, each row reading the entry rather than a copy of it. Upstream's
	 table of the same name shows the slant, weight and stretch its style-name parser guessed;
	 these columns show what the font itself states in its OS/2 table, which is where my key
	 comes from, so a row says why a face answers the triple it answers. The last column asks
	 the cache, so it says which of these entries something has drawn with: a face is parsed at
	 the first demand and never again. Sorted the way upstream sorts, family first, then by the
	 style name the font states."

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
		  addColumn: (SpStringTableColumn
				   title: 'Face built'
				   evaluated: [ :each |
					   (self faceByEntryCache includesKey: each)
						   ifTrue: [ 'yes' ]
						   ifFalse: [ '' ] ]);
		  yourself
]

{ #category : 'inspecting' }
VGFontManager >> inspectionFacesContext: aContext [
	"Shown only when I hold a face. A fresh manager has an empty table to offer and the State
	 tab says all there is to say about it."

	aContext active: self faceEntries notEmpty
]

{ #category : 'inspecting' }
VGFontManager >> inspectorCache: aBuilder [
	<inspectorPresentationOrder: 5 title: 'Cache'>
	"The faces something has drawn with, and what each one parsed out of its font. Every row
	 asks the face itself, so a row cannot claim a font was read that was not: a glyph count and
	 an em square come from the font's own tables. The faces are kept for the session, as unit
	 1.4 decided, so this table only grows."

	^ aBuilder newTable
		  items: (self faceByEntryCache values asArray sorted:
					   (#familyName ascending , #styleName ascending));
		  addColumn: (SpStringTableColumn title: 'Family name' evaluated: #familyName);
		  addColumn: (SpStringTableColumn title: 'Style' evaluated: #styleName);
		  addColumn: (SpStringTableColumn
				   title: 'Glyphs'
				   evaluated: [ :each | each glyphCount ]);
		  addColumn: (SpStringTableColumn
				   title: 'Units per em'
				   evaluated: [ :each | each unitsPerEm ]);
		  addColumn: (SpStringTableColumn
				   title: 'Outlines read'
				   evaluated: [ :each | each cachedGlyphCount ]);
		  yourself
]

{ #category : 'inspecting' }
VGFontManager >> inspectorCacheContext: aContext [
	"Shown only once something has drawn. A manager whose cache is empty has nothing to list,
	 and the Faces tab already says which entries are waiting to be parsed."

	aContext active: self faceByEntryCache notEmpty
]

{ #category : 'inspector' }
VGFontManager >> inspectorState: aBuilder [

	<inspectorPresentationOrder: 10 title: 'State'>
	"What I am made of, in one table. Three slots upstream fills stay nil or empty here, and
	 the registry rows go through my own readers, which read the catalogue — not through the
	 slot upstream keeps its index in, which stays empty for ever. The three file rows
	 reconcile: every file met is either an entry registered or a file refused.
	 Every row asks through an accessor, so a manager left over from a dead session shows what
	 it would answer now, rebuilt, rather than what it held then."

	| cache |
	cache := self faceByEntryCache.
	^ aBuilder newTable
		  items: {
				  ('Session' -> session).
				  ('FreeType library' -> self freetypeLibrary).
				  ('Face cache' -> cache class).
				  ('Faces kept' -> cache size).
				  ('Families registered' -> self entriesByFamilyName size).
				  ('Files met' -> self catalogue entries size).
				  ('Entries registered' -> self faceEntries size).
				  ('Files refused' -> self rejectedFiles size).
				  ('Default face' -> self defaultFace).
				  ('Default code face' -> self defaultCodeFace) };
		  addColumn:
			  (SpStringTableColumn title: 'Property' evaluated: [ :each | each key ]);
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

{ #category : 'accessing' }
VGFontManager >> refuseFaceFor: anEntry [
	"Signal that no face can be built for a file the reader refused, naming the file and the
	 reason the reader gave. Separate from faceAt: so that the one answers a face and this one
	 states the refusal."

	^ Error signal:
		  'The font reader refused ' , anEntry source fontSourceName , ': '
		  , anEntry metadata rejectionReason asString
		  , '. No face can be built for it.'
]

{ #category : 'registering' }
VGFontManager >> registerFacesOnFile: aFileReference [
	"Meet the face of one file. The catalogue reads its metadata off the stream, a few hundred
	 bytes of a file that may be megabytes, where upstream read the whole face through FreeType.
	 One face per file, never several: 1.3 of the font plan refuses a ttcf collection, so the
	 index upstream iterates is always zero. Answers the entry, refused or not, which upstream
	 had nothing to answer."

	^ self catalogue addFile: aFileReference
]

{ #category : 'registering' }
VGFontManager >> registerFacesOnMemory: aByteArray [
	"Meet the face of a font nobody wrote to disk: the embedded faces of a package, a font built
	 in a test. scanEmbeddedFonts reaches the registry through this method, so it needs no
	 override of its own. Answers the entry, like registerFacesOnFile:."

	^ self catalogue addBytes: aByteArray
]

{ #category : 'accessing' }
VGFontManager >> rejectedFiles [
	"The files I met and will not draw with, each carrying the reason the reader gave. A font
	 this project cannot read is refused by name rather than passed over in silence, so a
	 reader who cannot find a family can ask why. The catalogue derives the list from the
	 entries it kept, so this is not a second collection that could fall out of step."

	^ self catalogue refusedEntries
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

	^ self catalogue scanDefaultDirectories
]

{ #category : 'scanning' }
VGFontManager >> scanDirectory: aFileReference [
	"Meet every file under this directory. The catalogue hands each one to its reader and reads
	 no file name, where upstream drives an AeFontScanner whose shouldIgnoreFile: decides from
	 the name and the extension. Decision 6 of unit 1.4 of the font plan: one rule is enough,
	 and it is the refusal by content, so a font with an unexpected name is read and a file that
	 is not a font becomes a refused entry rather than a file silently passed over."

	^ self catalogue scanDirectory: aFileReference
]
