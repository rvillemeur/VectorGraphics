"
I am the one discovery of fonts this project makes: which families exist, where the bytes of each face are, and the weight, width and slant each face states.

Two registries read me and neither knows the other: a font manager for the Bloc and Cairo route, and FontFamily for the VectorCanvas route. Both ask me for a face's bytes and build their own kind of face from them, which is why I build none myself.

Three doors fill me. `scanDefaultDirectories` walks the places this platform keeps fonts, `scanDirectory:` walks one directory and its subdirectories, and `addBytes:` takes a font nobody wrote to disk. Every file under a directory I am given reaches `addFile:`: I read no file name, because the metadata reader says what a file is from its content, and one rule for that is enough.

I keep every file I met in `entries`, in the order I met it, and index only the faces that can be drawn in `entriesByFamilyName`: the family name in lower case, then the slant, weight class and width class, then the entry. The first source of a given face wins, as AeFontManager does. The files I refused are still mine — `refusedEntries` answers them, with the reason each one gave — so a reader can see what the scan passed over rather than guessing.

A scan is cheap: reading the metadata of the 362 faces installed on this machine costs 14 ms, against 4.6 s to read all their bytes.
"
Class {
	#name : 'TTFontCatalogue',
	#superclass : 'Object',
	#instVars : [
		'entries',
		'entriesByFamilyName'
	],
	#category : 'VectorGraphics-TrueType-Reading',
	#package : 'VectorGraphics-TrueType',
	#tag : 'Reading'
}

{ #category : 'constants' }
TTFontCatalogue class >> defaultFontDirectories [
	"Where this platform keeps fonts: the two places a user installs their own, the two a system
	 installs for everyone, and the Fonts directory beside the image, which is how a font travels
	 with a project. A scan passes over whichever of them does not exist."

	^ {
		  (FileLocator home / '.fonts').
		  (FileLocator home / '.local/share/fonts').
		  '/usr/share/fonts' asFileReference.
		  '/usr/local/share/fonts' asFileReference.
		  (FileLocator imageDirectory / 'Fonts') }
]

{ #category : 'adding' }
TTFontCatalogue >> addBytes: aByteArray [
	"Meet a font nobody wrote to disk: the embedded faces of a package, a font pulled over the
	 network, a font built in a test. Answers the entry, refused or not."

	^ self
		  addSource: aByteArray
		  metadata: (TTFontMetadataReader readBytes: aByteArray)
]

{ #category : 'adding' }
TTFontCatalogue >> addFile: aFileReference [
	"Meet one file on disk. Its metadata is read off the stream, which pulls the offset table,
	 the directory and three small tables — a few hundred bytes of a file that may be megabytes.
	 Answers the entry, refused or not."

	^ self
		  addSource: aFileReference
		  metadata: (aFileReference binaryReadStreamDo: [ :stream |
				   TTFontMetadataReader readStream: stream ])
]

{ #category : 'adding' }
TTFontCatalogue >> addSource: anObject metadata: aFontMetadata [
	"Keep one entry for a source whose metadata has been read, and index it by family when the
	 face can be drawn. The first source of a given family and style wins, as AeFontManager
	 does: a face installed in two directories is one face, and the scan order decides which
	 copy of it answers."

	| entry |
	entry := TTFontCatalogueEntry new
		         source: anObject;
		         metadata: aFontMetadata;
		         yourself.
	entries add: entry.
	aFontMetadata isRejected ifFalse: [
		(entriesByFamilyName
			 at: aFontMetadata familyName asLowercase
			 ifAbsentPut: [ Dictionary new ])
			at: entry styleKey
			ifAbsentPut: [ entry ] ].
	^ entry
]

{ #category : 'accessing' }
TTFontCatalogue >> entries [
	"Every file I have met, in the order I met it, each one an entry carrying its source and its
	 metadata. The ones I refused are among them."

	^ entries
]

{ #category : 'accessing' }
TTFontCatalogue >> entriesByFamilyName [
	"The faces I can answer for, keyed by family name in lower case, then by the slant, weight
	 class and width class that tell two faces of one family apart. Refused files are not here."

	^ entriesByFamilyName
]

{ #category : 'accessing' }
TTFontCatalogue >> familyNames [
	"The families I hold, as their own fonts spell them rather than as I key them, sorted. A
	 consumer shows these to a reader; the lower-case keys are mine alone."

	| result |
	result := SortedCollection new.
	entriesByFamilyName valuesDo: [ :each |
		result add: each anyOne metadata familyName ].
	^ result
]

{ #category : 'initialization' }
TTFontCatalogue >> initialize [
	"Empty: a catalogue knows nothing until a scan tells it something."

	super initialize.
	entries := OrderedCollection new.
	entriesByFamilyName := Dictionary new
]

{ #category : 'inspecting' }
TTFontCatalogue >> inspectorFamilies: aBuilder [
	"The families I hold and the faces of each, which is the question both registries ask me.
	 The Faces column counts the entries I indexed, not the files I met, so a family whose
	 second copy was dropped reads one here; the Styles column spells the triple each of those
	 faces is keyed by, so a reader sees what distinguishes them."

	<inspectorPresentationOrder: 10 title: 'Families'>
	^ aBuilder newTable
		  addColumn: ((SpStringTableColumn
				    title: 'Family'
				    evaluated: [ :each | each value anyOne metadata familyName ])
				   width: 220);
		  addColumn: ((SpStringTableColumn
				    title: 'Faces'
				    evaluated: [ :each | each value size printString ])
				   width: 70);
		  addColumn: (SpStringTableColumn
				   title: 'Styles'
				   evaluated: [ :each |
					   ', ' join: ((each value values collect: [ :entry |
							     entry metadata styleName ]) asSortedCollection) ]);
		  items: (entriesByFamilyName associations asSortedCollection: [ :a :b |
					   a key <= b key ]) asArray;
		  yourself
]

{ #category : 'inspecting' }
TTFontCatalogue >> inspectorRefusals: aBuilder [
	"What I passed over, grouped by the reason the file gave. The reasons are not listed here:
	 they are collected from the entries themselves, so a cause added to the reader shows up
	 without this view being touched. A font directory holds more files that are not drawable
	 fonts than files that are — on this machine 182 of 544 — and this is where that shows."

	<inspectorPresentationOrder: 20 title: 'Refusals'>
	| byReason |
	byReason := self refusedEntries groupedBy: [ :each |
		            each metadata rejectionReason ].
	^ aBuilder newTable
		  addColumn: ((SpStringTableColumn
				    title: 'Reason'
				    evaluated: [ :each | each key asString ])
				   width: 160);
		  addColumn: ((SpStringTableColumn
				    title: 'Files'
				    evaluated: [ :each | each value size printString ])
				   width: 70);
		  addColumn: (SpStringTableColumn
				   title: 'First one'
				   evaluated: [ :each | each value first source fontSourceName ]);
		  items: (byReason associations asSortedCollection: [ :a :b |
					   a key <= b key ]) asArray;
		  yourself
]

{ #category : 'accessing' }
TTFontCatalogue >> refusedEntries [
	"The files I met and will not answer for, each carrying the reason it gave. Derived from my
	 entries rather than kept beside them, so no second collection can fall out of step."

	^ entries select: [ :each | each metadata isRejected ]
]

{ #category : 'scanning' }
TTFontCatalogue >> scanDefaultDirectories [
	"Meet every font this machine has installed. A directory that does not exist is passed over,
	 since the list names the places a platform may keep fonts, not the places it does."

	self class defaultFontDirectories do: [ :each |
		each exists ifTrue: [ self scanDirectory: each ] ]
]

{ #category : 'scanning' }
TTFontCatalogue >> scanDirectory: aFileReference [
	"Meet every file under this directory and its subdirectories. No file name is read: the
	 reader says what a file is from its content, and a file that is not a font this project
	 draws becomes a refused entry rather than an exception."

	aFileReference allChildren do: [ :each |
		each isFile ifTrue: [ self addFile: each ] ]
]
