"
I am the font registry Bloc asks for its faces, and I hold no FreeType library.

Upstream `AeFontManager` keeps an `AeFTLibrary`, reads every font through it, and caches the `AeFTFace` handles it builds in an `LRUCache` capped at twenty. I answer the same questions, so what Bloc asks of me it would ask of upstream, and I answer them from `VGFontFace`, which reads a font's own bytes in Pharo and owns no handle at all. That is why my face cache is a plain `Dictionary`: what it holds costs to parse again and nothing to release, so a face lives for the session rather than being evicted.

What I register, I register through `TTFontCatalogue`, which I own for the session. Every inherited way into the registry delegates to it — `registerFacesOnFile:` to `addFile:`, `registerFacesOnMemory:` to `addBytes:`, `scanDirectory:` and `scanDefaultDirectories` to its own, and `scanEmbeddedFonts` through the second of those without an override. The catalogue reads a few hundred bytes of each file, never the whole face, and judges a file by its content rather than by its name, so a font under an unexpected name is registered and a file that is not a font is a rejection it keeps.

The catalogue is my only index, which is why the four inherited readers of `entriesByFamilyName` are overridden: each one reads that instance variable directly, and mine stays empty. It keys a family by name in lower case and then by what the font states of itself — its slant, its OS/2 weight class, its width class. Alexandrie keys by `AeFontSlant`, `AeFontWeight` and `AeFontStretch` read off the style name instead, and `entryForFamilyName:slant:weight:stretch:ifNone:` is the one place the two vocabularies meet.

`faceAt:` builds the face from the entry's own bytes and keeps it, so a font is read once a session draws with it and never again; a file the reader rejected is named in an error rather than parsed a second time. Every reader of mine asks through an accessor that checks the session first, so a manager left over from a dead session rebuilds its catalogue before it answers.

Nothing of mine is posed anywhere until `installGlobally` is sent. It is my class that keeps what was posed, writes it into the slot `AeFontManager` answers `globalInstance` from, and puts it back from `startUp:` after upstream nils that slot at every image start. An image that installed nothing keeps the manager Alexandrie built for itself.
"
Class {
	#name : 'VGFontManager',
	#superclass : 'AeFontManager',
	#instVars : [
		'catalogue',
		'rebuildsFromDefaultDirectories'
	],
	#classInstVars : [
		'installedInstance',
		'sharedInstance'
	],
	#category : 'VectorGraphics-Bloc-Text-Fonts',
	#package : 'VectorGraphics-Bloc-Text',
	#tag : 'Fonts'
}

{ #category : 'architecture' }
VGFontManager class >> archClassRelations [
	"What I hold myself, in two class-side slots. installedInstance is the manager posed in the
	 image, kept so that startUp: can put it back after upstream nils the slot it was written
	 into; sharedInstance is the manager built from this machine's fonts, kept because building
	 one meets every installed font and that scan was 86 per cent of what drawing a frame cost.
	 Both are caches: an image that installed nothing and asked for nothing has neither."

	^ #(
		#( #installedInstance #cacheOne #VGFontManager nil )
		#( #sharedInstance #cacheOne #VGFontManager nil ) )
]

{ #category : 'architecture' }
VGFontManager class >> archRelations [
	"What an instance of me holds in a slot of upstream's, which no accessor of mine exposes and
	 no pragma of mine may claim: AeFontManager declares those slots and this project must not
	 edit that package. Each row is the role, the multiplicity, the target and the opposite; nil
	 names no opposite.
	 All three are caches. faceByEntryCache holds the face of every entry a session has drawn
	 with, parsed once out of the entry's own bytes; the two defaults are the faces the scan
	 chose, and a manager nobody scanned for has neither."

	^ #(
		#( #faceByEntryCache #cacheMany #VGFontFace nil )
		#( #defaultFace #cacheOne #VGFontFace nil )
		#( #defaultCodeFace #cacheOne #VGFontFace nil ) )
]

{ #category : 'installation' }
VGFontManager class >> ensureUpstreamHoldsMine [
	"Put my manager back in the slot every consumer of a face reaches, if it is not there
	 already. Upstream nils that slot at every image start and anyone may nil it by hand with
	 resetGlobalInstance; the next reader of it then gets a stock manager of FreeType faces,
	 and a scaled font of this project dies on one with 'AeFTFace >> #unitsPerEm'. The
	 manager posed is the one already built, never a new one: building scans every font
	 directory of the machine, which is seconds, and this runs before every measurement.
	 A nil slot of mine means hands off: an image that never installed the route keeps
	 whatever manager upstream built for itself."

	installedInstance ifNil: [ ^ self ].
	self managerUpstreamHolds == installedInstance ifTrue: [ ^ self ].
	AeFontManager globalInstance: installedInstance
]

{ #category : 'instance creation' }
VGFontManager class >> forgetDefaultFaces [
	"Drop the shared manager, so the next reader meets the machine's fonts again. A font
	 installed on the machine since this image started is invisible until then: a scan per
	 frame was 116 ms and is not the price of noticing it.
	 The installed manager is left alone. It may be this same object, and uninstalling is about
	 the slot every consumer of a face reaches, not about what the machine holds."

	sharedInstance := nil
]

{ #category : 'testing' }
VGFontManager class >> hasDefaultFaces [
	"Whether the shared manager is built. Reads the slot rather than sending withDefaultFaces,
	 which would build one at the moment a reader asks the question — an inspector tab asks it."

	^ sharedInstance isNotNil
]

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
	"Whether this project has posed a font manager as the one Bloc asks for its faces, and
	 which one. Says that and nothing else: what the manager knows — its families, its entries,
	 the faces it has built — is what its own State view says, so a reader dives into the row
	 rather than reading a second copy of those counts that could disagree with the first.
	 Reads my own slots only, through the accessors: sending AeFontManager globalInstance would
	 build a complete FreeType manager at the moment a reader opens an inspector, which is the
	 opposite of what this unit is for. A reader who wants the real route asks
	 AeFontManager globalInstance in a playground and accepts that it builds one.
	 The second row is the fact #ensureUpstreamHoldsMine keeps true: a reader who emptied
	 upstream's slot sees it false here until the next measurement or drawing poses the
	 route again.
	 The third row is the cache of unit 3.11, asked through #hasDefaultFaces so that reading it
	 builds nothing: a manager of the machine's fonts costs a scan of every font installed,
	 116 ms here, and a reader who opens this view has not asked for one."

	^ aBuilder newTable
		  items: {
				  ('Installed manager' -> self installedInstance).
				  ('Upstream slot holds it'
				   -> (self managerUpstreamHolds == self installedInstance)).
				  ('Default faces scanned' -> self hasDefaultFaces) };
		  addColumn:
			  (SpStringTableColumn title: 'Property' evaluated: [ :each | each key ]);
		  addColumn: (SpStringTableColumn
				   title: 'Value'
				   evaluated: [ :each | each value printString ]);
		  yourself
]

{ #category : 'inspector' }
VGFontManager class >> inspectorInstallationContext: aContext [

	"The Installation view reads installedInstance, a class-instance variable: every subclass
	 would get its own copy, always nil, and the tab would say nothing true of it. So the tab
	 belongs to the class that installs, and the rule is asked rather than restated — the view
	 is offered where installGlobally is defined."

	aContext active: (self includesSelector: #installGlobally)
]

{ #category : 'installing' }
VGFontManager class >> installGlobally [
	"Make a manager of mine the one every consumer of a face reaches through
	 AeFontManager globalInstance. It is the shared manager of this machine's fonts, so it can
	 draw the moment it is posed and an image that has already measured a frame pays nothing
	 to install: BAFontConverter >> faceFor: falls back on the default face for every family a
	 text names and nobody holds, and a nil there would break in the drawing.
	 Kept here as well as written upstream, so that startUp: can put the same object back after
	 upstream nils its slot at every image start, and so that nothing of mine has to read a
	 slot of Alexandrie's to know what it posed.
	 The same faces are registered with FontFamily, which is the other door onto them — the one
	 the text classes ask. Nothing is parsed on the way: each family reads the outlines behind a
	 face when a reader first asks for it. A default family or point size the image has not
	 chosen is given the one this manager can draw with — the family of the face it chose for
	 itself, so the two doors name the same font; a choice already made is left alone."

	installedInstance := self withDefaultFaces.
	AeFontManager globalInstance: installedInstance.
	FontFamily addFamiliesFrom: installedInstance catalogue.
	FontFamily defaultFamilyName ifNil: [
		FontFamily defaultFamilyName: installedInstance defaultFace familyName ].
	FontFamily defaultPointSize ifNil: [ FontFamily defaultPointSize: 12 ].
	^ installedInstance
]

{ #category : 'accessing' }
VGFontManager class >> installedInstance [
	"The manager I posed as the one Bloc asks for its faces, or nil if I posed none. One slot
	 rather than a flag beside a manager: two pieces of state could fall out of step, and the
	 question 'is our manager installed' is answered by whether this is nil."

	^ installedInstance
]

{ #category : 'installing' }
VGFontManager class >> managerUpstreamHolds [
	"What `AeFontManager` holds in its own class slot right now, nil included. The slot is read
	 by reflection rather than by sending `AeFontManager globalInstance`, which builds a whole
	 manager, FreeType and all, when the slot is nil — a test or an example that only wants to
	 put the image back as it found it must not create one on the way."

	^ (AeFontManager class slotNamed: #globalInstance) read: AeFontManager
]

{ #category : 'instance creation' }
VGFontManager class >> newWithDefaultFaces [
	"A manager that can draw before anything registers anything: every font this machine has
	 installed, and the two faces Bloc falls back on when a text names a family nobody holds —
	 one for text, one for code. Upstream builds that pair from the font bytes its own package
	 carries; here they are faces of the machine read from a file, so a consumer of mine draws
	 with Alexandrie's FreeType packages out of the image.
	 Each default is the first family of a preference list that the machine holds, and a
	 machine that holds none of them is an error rather than a nil default: a nil comes back
	 from BAFontConverter >> faceFor: and breaks in the drawing instead of here.
	 The scan and the pair are one send of the manager's own, because it must do them again
	 whenever a new session resets it."

	^ self new
		  scanDefaultDirectoriesAndChooseDefaultFaces;
		  yourself
]

{ #category : 'defaults' }
VGFontManager class >> preferredCodeFamilyNames [
	"The families a manager of mine takes its default code face from, best first. Monospacing
	 is asked for by name and not detected: the metadata this project reads carries no
	 fixed-pitch flag, and the families named here are monospaced by their own definition."
	^ #( 'DejaVu Sans Mono' 'Liberation Mono' 'Noto Sans Mono' 'FreeMono'
	     'Menlo' 'Monaco' 'Consolas' 'Courier New' )
]

{ #category : 'defaults' }
VGFontManager class >> preferredTextFamilyNames [
	"The families a manager of mine takes its default text face from, best first. A default is
	 a fallback for every family a text names and nobody holds, so what matters is that it is
	 an ordinary sans face present on the machine rather than which one it is. The list runs
	 from the faces a Linux image almost always has to the ones a macOS or a Windows image
	 carries, so an image on any of the three finds one."
	^ #( 'DejaVu Sans' 'Liberation Sans' 'Noto Sans' 'FreeSans'
	     'Helvetica Neue' 'Helvetica' 'Arial' 'Segoe UI' )
]

{ #category : 'installing' }
VGFontManager class >> restoreUpstreamManager: aFontManagerOrNil [
	"Put back in `AeFontManager`'s class slot whatever `managerUpstreamHolds` answered before
	 this project posed its own. Takes nil, because an image that had never asked for a face
	 holds nil there, and `uninstallGlobally` would leave it nil whatever was there before."

	(AeFontManager class slotNamed: #globalInstance)
		write: aFontManagerOrNil
		to: AeFontManager
]

{ #category : 'system startup' }
VGFontManager class >> startUp: isResuming [
	"Put my manager back after upstream nils its slot. I am registered at GUI priority 115 and
	 upstream at 110, and a category starts its handlers by rising priority, so this runs after
	 its reset and before AeCanvas initialises its font options at 120.
	 The manager kept here is the one the dead session held. It answers nothing of that session:
	 every reader of it checks the session first and rebuilds its catalogue, which is what unit
	 3.4 is for."

	isResuming ifFalse: [ ^ self ].
	self ensureUpstreamHoldsMine
]

{ #category : 'installing' }
VGFontManager class >> uninstallGlobally [
	"Stop being the manager Bloc asks, and leave upstream to rebuild its own. Upstream's slot
	 goes to nil rather than back to whatever was there: its globalInstance builds a manager
	 lazily, which is the state an image that never met this project is in."

	installedInstance := nil.
	AeFontManager globalInstance: nil
]

{ #category : 'instance creation' }
VGFontManager class >> withDefaultFaces [
	"The one manager of this machine's fonts the image shares, built the first time anybody asks
	 for it. Building one meets every font the machine has installed, which is 116 ms here and
	 was paid once a frame before unit 3.11: posing the faces of this project built a manager
	 every time, and that scan was 86 per cent of what drawing the reference frame cost.
	 Shared rather than built per reader, and safe to share across sessions: a manager built
	 this way rebuilds its catalogue when the session changes, which every reader of it asks
	 through. A reader that wants a manager of its own asks newWithDefaultFaces, which is what
	 a test of the scan itself does."

	^ sharedInstance ifNil: [ sharedInstance := self newWithDefaultFaces ]
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
	 through this accessor rather than the slot, so the check cannot be walked around.
	 A structural holding and not a cache: reset builds one, so a live manager always has it."

	<archRelation: #one to: #TTFontCatalogue>
	self checkSession.
	^ catalogue
]

{ #category : 'accessing - faces' }
VGFontManager >> defaultFaceOfFirstFamilyNamedIn: familyNames [
	"The face of the first family of an ordered preference list that this machine holds, for a
	 caller that wants a default to fall back on and does not care which family answers. The
	 catalogue walks the list; the face is built here, out of the bytes the entry names. A
	 machine that holds none of them is a refusal naming the list, not a nil face."
	^ self faceAt: (self catalogue
			   entryOfFirstFamilyNamedIn: familyNames
			   ifNone: [
				   VGFontManagerHasNoUsableFamily
					   signalForFamilyNames: familyNames
					   outOf: self familyNames size ])
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

{ #category : 'accessing - faces' }
VGFontManager >> entriesByFamilyName [
	"The faces I answer for, keyed as the catalogue keys them: family name in lower case, then
	 the TTFontStyle the face states. Not upstream's key, which is a triple of AeFontSlant,
	 AeFontWeight and AeFontStretch read off the style name; the translation between the two
	 lives in styleForSlant:weight:stretch:, and entryForFamilyName:slant:weight:stretch:
	 ifNone: is the one place a consumer asks in Alexandrie's vocabulary."
	^ self catalogue entriesByFamilyName
]

{ #category : 'accessing - faces' }
VGFontManager >> entryForFamilyName: aFamilyName slant: aSlant weight: aWeight stretch: aStretch ifNone: absentBlock [
	"One face of a family, asked for the way Alexandrie asks: a family name and three of its
	 font category objects. This is the one place the two vocabularies meet, which is why the
	 translation lives here and the five arguments are upstream's own — detectFamilyName:
	 slant:weight:stretch:ifNone: is an AeFontManager selector and I cannot shorten it. The
	 catalogue does the looking up: how it keys a family and a style is its own."
	^ self catalogue
		  entryOfFamilyNamed: aFamilyName
		  style: (self
				   styleForSlant: aSlant
				   weight: aWeight
				   stretch: aStretch)
		  ifNone: absentBlock
]

{ #category : 'accessing' }
VGFontManager >> faceAt: anEntry [
	"The face of one entry, parsed once and then kept. Upstream's answers whatever its LRU
	 cache holds and builds nothing, since its cache was given a factory that calls FreeType;
	 mine builds the face here, out of the bytes the entry names.
	 The bytes are read at this point and not before: a catalogue that scanned this machine
	 knows 544 files and 262 MB in all, and a session draws with a handful of them.
	 A rejected entry is named rather than parsed. The entry says the rejection itself, since the
	 sentence is about the file it names and not about me.
	 The cache is asked through its accessor, which checks the session first, as upstream's
	 does."

	anEntry isRejected ifTrue: [
		^ anEntry signalRejection: 'No face can be built for it.' ].
	^ self faceByEntryCache
		  at: anEntry
		  ifAbsentPut: [ VGFontFace newForBytes: anEntry bytes ]
]

{ #category : 'accessing' }
VGFontManager >> faceEntries [
	"Every face I answer for, rejections left out. Upstream collects these out of its own index;
	 the catalogue selects them out of everything it met, so a rejected file is still there to
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

{ #category : 'initialization' }
VGFontManager >> initialize [
	"A manager filled by hand until somebody says otherwise: a new session then resets me to
	 nothing, which is what a registered face deserves, nobody here knowing how to register it
	 again. The slot is written after super initialize because that is what runs reset, and
	 reset reads this policy before this line could have set it — which is why the reader
	 answers false for nil."

	super initialize.
	rebuildsFromDefaultDirectories := false
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
	 reconcile: every file met is either an entry registered or a file rejected.
	 Every row asks through an accessor, so a manager left over from a dead session shows what
	 it would answer now, rebuilt, rather than what it held then. The row beside the session
	 says which rebuilding that is: a manager built from the machine's fonts meets them again,
	 one filled by hand comes back empty, and a reader looking at an empty table wants to know
	 which of the two he has."

	| cache |
	cache := self faceByEntryCache.
	^ aBuilder newTable
		  items: {
				  ('Session' -> session).
				  ('Rebuilds from default directories'
				   -> self rebuildsFromDefaultDirectories).
				  ('FreeType library' -> self freetypeLibrary).
				  ('Face cache' -> cache class).
				  ('Faces kept' -> cache size).
				  ('Families registered' -> self entriesByFamilyName size).
				  ('Files met' -> self catalogue entries size).
				  ('Entries registered' -> self faceEntries size).
				  ('Files rejected' -> self rejectedFiles size).
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
VGFontManager >> rebuildsFromDefaultDirectories [
	"Whether I was built from the fonts this machine has installed, and so must meet them
	 again when a new session resets me. Read through here rather than from the slot because
	 reset runs from initialize, before any writer of mine could have set it."

	^ rebuildsFromDefaultDirectories ifNil: [ false ]
]

{ #category : 'registering' }
VGFontManager >> registerFacesOnFile: aFileReference [
	"Meet the face of one file. The catalogue reads its metadata off the stream, a few hundred
	 bytes of a file that may be megabytes, where upstream read the whole face through FreeType.
	 One face per file, never several: 1.3 of the font plan rejects a ttcf collection, so the
	 index upstream iterates is always zero. Answers the entry, rejected or not, which upstream
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
	 this project cannot read is rejected by name rather than passed over in silence, so a
	 reader who cannot find a family can ask why. The catalogue derives the list from the
	 entries it kept, so this is not a second collection that could fall out of step."

	^ self catalogue rejectedEntries
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
	 this method left it alone. It is set first, before the scan below reads an accessor that
	 checks it again.
	 A manager built from the machine's fonts meets them again here. The catalogue a reset
	 builds is empty and both defaults are nil, and nothing else ever scans: without this an
	 image restart hands back a manager that answers no family at all, and the drawing breaks
	 on a nil default in BAFontConverter >> faceFor: rather than here. The scan is roughly half
	 a second, paid once a session by the first reader."

	session := Smalltalk session.
	entriesByFamilyName := Dictionary new.
	defaultFace := nil.
	defaultCodeFace := nil.
	freetypeLibrary := nil.
	faceByEntryCache := Dictionary new.
	catalogue := TTFontCatalogue new.
	self rebuildsFromDefaultDirectories ifTrue: [
		self scanDefaultDirectoriesAndChooseDefaultFaces ]
]

{ #category : 'scanning' }
VGFontManager >> scanDefaultDirectories [
	"Meet every font this machine has installed, through the catalogue's own list of the places
	 a platform keeps them. A directory that does not exist is passed over."

	^ self catalogue scanDefaultDirectories
]

{ #category : 'scanning' }
VGFontManager >> scanDefaultDirectoriesAndChooseDefaultFaces [
	"Meet every font this machine has installed and pick the two faces Bloc falls back on when
	 a text names a family nobody holds, one for text and one for code. The pair is what makes
	 a manager ready to draw, which is why one send does both.
	 Remembered as the way I was built, so a new session can do it again: reset drops the
	 catalogue and both defaults, and a manager that answered for the machine before an image
	 restart must answer for it after. A manager somebody filled by hand is not rebuilt, since
	 nothing here knows what was registered into it."

	rebuildsFromDefaultDirectories := true.
	self scanDefaultDirectories.
	self defaultFace:
		(self defaultFaceOfFirstFamilyNamedIn: self class preferredTextFamilyNames).
	self defaultCodeFace:
		(self defaultFaceOfFirstFamilyNamedIn: self class preferredCodeFamilyNames)
]

{ #category : 'scanning' }
VGFontManager >> scanDirectory: aFileReference [
	"Meet every file under this directory. The catalogue hands each one to its reader and reads
	 no file name, where upstream drives an AeFontScanner whose shouldIgnoreFile: decides from
	 the name and the extension. Decision 6 of unit 1.4 of the font plan: one rule is enough,
	 and it is the rejection by content, so a font with an unexpected name is read and a file
	 that is not a font becomes a rejected entry rather than a file silently passed over."

	^ self catalogue scanDirectory: aFileReference
]

{ #category : 'accessing - faces' }
VGFontManager >> styleForSlant: aSlant weight: aWeight stretch: aStretch [
	"The style of a face, out of Alexandrie's three font category objects. The three
	 translations are exact rather than approximate, which is why they run in this direction
	 only. A slant answers its name, the same symbol the metadata reader states. An AeFontWeight
	 answers the OS/2 weight class itself — normal is 400, bold is 700. An AeFontStretch answers
	 the OS/2 width class less one, since it counts ultraCondensed from zero where OS/2 counts
	 it from one."
	^ TTFontStyle
		  slant: aSlant name
		  weightClass: aWeight value
		  widthClass: aStretch value + 1
]
