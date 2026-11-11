"
I read the name table of a font file and answer a TTFontMetadata. I am the cheap end of the TrueType parser: I walk the table directory, read the one table I need and stop.

TTFontReader is the other end. Its readFrom:fromOffset: demands eight tables and parses loca, cmap, glyf and hmtx, which is the whole cost a scan exists to avoid.

I exist so that a font manager can name every face on the machine without FreeType. Alexandrie's AeFontManager does that through AeFTLibrary >> fastReadFacesOn:do:, one of the two places the native library enters Bloc's text route.
"
Class {
	#name : 'TTFontMetadataReader',
	#superclass : 'Object',
	#category : 'VectorGraphics-TrueType-Reading',
	#package : 'VectorGraphics-TrueType',
	#tag : 'Reading'
}

{ #category : 'constants' }
TTFontMetadataReader class >> boldWeightClass [
	^ 700
]

{ #category : 'constants' }
TTFontMetadataReader class >> classifiedTableTags [
	"The three tables a face is named and classified from. Together they are under a kilobyte of
	 a file that is megabytes, which is what makes the stream door worth having."

	^ { self nameTableTag. self headTableTag. self os2TableTag }
]

{ #category : 'constants' }
TTFontMetadataReader class >> collectionVersion [
	"The tag of a font collection, a file holding several fonts behind offsets. It is not a font
	 and has no table directory of its own."

	^ 'ttcf' asByteArray
]

{ #category : 'constants' }
TTFontMetadataReader class >> colourTableTags [
	"The tables a colour font carries its glyphs in: embedded bitmaps, Apple's bitmaps, and SVG
	 documents. The tag of the last is three letters and a space, as every sfnt tag is four
	 bytes."

	^ #( 'CBDT' 'sbix' 'SVG ' )
]

{ #category : 'constants' }
TTFontMetadataReader class >> condensedWidthClass [
	^ 3
]

{ #category : 'constants' }
TTFontMetadataReader class >> directoryRecordSize [
	"One table directory record: tag, checksum, offset, length, four bytes each."

	^ 16
]

{ #category : 'reading' }
TTFontMetadataReader class >> directoryRejectionFor: aDirectory inFileOfSize: anInteger [
	"Why the tables a directory points at cannot be read in a file of anInteger bytes, or nil
	 when they can. A font cut short — half downloaded, half copied — points past its own end,
	 and the parser that followed such a record would raise rather than answer."

	^ (aDirectory allSatisfy: [ :entry |
		   entry offset + entry length - 1 <= anInteger ])
		  ifTrue: [ nil ]
		  ifFalse: [ #notAnSfntFont ]
]

{ #category : 'reading' }
TTFontMetadataReader class >> directorySizeOf: anOffsetTable [
	"How many bytes of directory records the offset table promises, one per table."

	^ (anOffsetTable shortAt: self tableCountOffset bigEndian: true)
	  * self directoryRecordSize
]

{ #category : 'reading' }
TTFontMetadataReader class >> entriesFrom: aStream directory: aDirectory [
	"The tables of classifiedTableTags, pulled off the stream one seek at a time and wrapped as
	 entries over their own bytes rather than over the whole font. A table the font does not
	 carry is left out, which is how a missing head or OS/2 reaches the classifying step."

	| entries |
	entries := Dictionary new.
	self classifiedTableTags do: [ :tag |
		(aDirectory at: tag ifAbsent: [ nil ]) ifNotNil: [ :entry |
			aStream position: entry offset - 1.
			entries
				at: tag
				put: (TTFontTableDirEntry onBytes: (aStream next: entry length)) ] ].
	^ entries
]

{ #category : 'constants' }
TTFontMetadataReader class >> fsSelectionItalicMask [
	^ 2r1
]

{ #category : 'constants' }
TTFontMetadataReader class >> fsSelectionObliqueMask [
	^ 2r1000000000
]

{ #category : 'constants' }
TTFontMetadataReader class >> glyfTableTag [
	"The table holding TrueType outlines. A font without it has CFF outlines, which this project
	 cannot draw."

	^ 'glyf'
]

{ #category : 'constants' }
TTFontMetadataReader class >> headTableTag [
	"head carries macStyle, which is all a font with no OS/2 table says about its style."

	^ 'head'
]

{ #category : 'private' }
TTFontMetadataReader class >> lengthsFrom: aDirectory [
	"What the directory records about every table, by tag, so the metadata can show which
	 tables were passed over and which one was read. The entries themselves hold the font's
	 bytes, and the stream door never has them all."

	^ aDirectory collect: [ :entry | entry length ]
]

{ #category : 'constants' }
TTFontMetadataReader class >> macStyleBoldMask [
	^ 2r1
]

{ #category : 'constants' }
TTFontMetadataReader class >> macStyleCondensedMask [
	^ 2r100000
]

{ #category : 'reading' }
TTFontMetadataReader class >> macStyleFrom: anEntryByTag [
	"The macStyle word of the head table, or zero — every bit clear, the normal face — when the
	 font carries no head table."

	^ (anEntryByTag at: self headTableTag ifAbsent: [ nil ])
		  ifNil: [ 0 ]
		  ifNotNil: [ :entry | (TTHeadTableParser on: entry) process at: #macStyle ]
]

{ #category : 'constants' }
TTFontMetadataReader class >> macStyleItalicMask [
	^ 2r10
]

{ #category : 'reading' }
TTFontMetadataReader class >> metadataFromEntries: anEntryByTag lengths: aDictionary [
	"My one answer: a TTFontMetadata named from the name table, classified from OS/2 and head,
	 and carrying the first reason the directory gives not to draw the face."

	| metadata |
	metadata := TTFontMetadata new.
	metadata tableLengthsByTag: aDictionary.
	metadata rejectionReason: (self rejectionFromTags: aDictionary keys).
	(anEntryByTag includesKey: self nameTableTag) ifTrue: [
		self readNamesInto: metadata fromEntries: anEntryByTag ].
	self readStyleInto: metadata fromEntries: anEntryByTag.
	^ metadata
]

{ #category : 'constants' }
TTFontMetadataReader class >> nameTableTag [
	"The one table I read. Both readBytes: and the Tables view ask me, so the view cannot say I
	 read a table I do not."

	^ 'name'
]

{ #category : 'constants' }
TTFontMetadataReader class >> normalWeightClass [
	^ 400
]

{ #category : 'constants' }
TTFontMetadataReader class >> normalWidthClass [
	^ 5
]

{ #category : 'reading' }
TTFontMetadataReader class >> offsetTableRejection: anOffsetTable inFileOfSize: anInteger [
	"What the twelve-byte offset table says before a single table is read, in a file of anInteger
	 bytes: too short to hold an offset table, a version word this reader does not know, a
	 collection, or too short to hold the directory the offset table promises. Nil when the
	 directory can be read."

	| version |
	anOffsetTable size < self offsetTableSize ifTrue: [ ^ #notAnSfntFont ].
	version := anOffsetTable first: 4.
	version = self collectionVersion ifTrue: [ ^ #fontCollection ].
	(self sfntVersions includes: version) ifFalse: [ ^ #notAnSfntFont ].
	anInteger < (self offsetTableSize + (self directorySizeOf: anOffsetTable)) ifTrue: [
		^ #notAnSfntFont ].
	^ nil
]

{ #category : 'constants' }
TTFontMetadataReader class >> offsetTableSize [
	"The sfnt offset table: version, table count, and three fields a reader that only names a
	 font does not use."

	^ 12
]

{ #category : 'reading' }
TTFontMetadataReader class >> os2FieldsFrom: anEntryByTag [
	"The three fields of the OS/2 table, or nil when the font carries no OS/2 table."

	^ (anEntryByTag at: self os2TableTag ifAbsent: [ nil ]) ifNotNil: [ :entry |
		  (TTOS2TableParser on: entry) process ]
]

{ #category : 'constants' }
TTFontMetadataReader class >> os2TableTag [
	"The tag is written with the solidus: four characters, O, S, slash, 2."

	^ 'OS/2'
]

{ #category : 'reading' }
TTFontMetadataReader class >> readBytes: aByteArray [
	"Read a whole font's bytes: walk the table directory, read the tables that name and classify
	 the face, and stop. Prefer readStream: when the font is a file on disk — reading the file
	 whole is the cost. Answers a rejected metadata rather than raising for a file this reader
	 cannot walk."

	| rejection directory |
	rejection := self offsetTableRejection: aByteArray inFileOfSize: aByteArray size.
	rejection ifNotNil: [ ^ self rejectedMetadata: rejection ].
	directory := TTFontReader buildTableDirectory: aByteArray offset: 0.
	rejection := self directoryRejectionFor: directory inFileOfSize: aByteArray size.
	rejection ifNotNil: [ ^ self rejectedMetadata: rejection ].
	^ self metadataFromEntries: directory lengths: (self lengthsFrom: directory)
]

{ #category : 'private' }
TTFontMetadataReader class >> readNamesInto: aMetadata fromEntries: anEntryByTag [
	"The eight strings TTNameTableParser answers are indexed by name identifier plus one, so the
	 family is the second and the subfamily — which every font manager calls the style — is the
	 third."

	| strings |
	strings := (TTNameTableParser on: (anEntryByTag at: self nameTableTag))
		           process.
	aMetadata familyName: (strings at: 2).
	aMetadata styleName: (strings at: 3)
]

{ #category : 'reading' }
TTFontMetadataReader class >> readStream: aStream [
	"Pull the offset table, the table directory and the three tables of classifiedTableTags, and
	 nothing else. A font file is megabytes and those three tables are under a kilobyte: the 362
	 fonts installed on this machine are 262 MB and 4.6 s of disk, against 14 ms to parse all
	 their name tables. A file this reader cannot walk answers a rejected metadata, since the
	 catalogue meets every file a font directory holds."

	| offsetTable directory rejection |
	offsetTable := aStream next: self offsetTableSize.
	rejection := self offsetTableRejection: offsetTable inFileOfSize: aStream size.
	rejection ifNotNil: [ ^ self rejectedMetadata: rejection ].
	directory := TTFontReader
		             buildTableDirectory:
			             offsetTable , (aStream next: (self directorySizeOf: offsetTable))
		             offset: 0.
	rejection := self directoryRejectionFor: directory inFileOfSize: aStream size.
	rejection ifNotNil: [ ^ self rejectedMetadata: rejection ].
	^ self
		  metadataFromEntries: (self entriesFrom: aStream directory: directory)
		  lengths: (self lengthsFrom: directory)
]

{ #category : 'reading' }
TTFontMetadataReader class >> readStyleInto: aMetadata fromEntries: anEntryByTag [
	"Weight, width and slant from the font's own tables and not from the words of its style name,
	 which is how AeFaceEntry guesses them. OS/2 is the authority; head's macStyle answers for a
	 font that carries no OS/2 table, and for the fields OS/2 left at zero."

	| macStyle os2 |
	macStyle := self macStyleFrom: anEntryByTag.
	os2 := self os2FieldsFrom: anEntryByTag.
	aMetadata weightClass: (self weightClassFrom: os2 macStyle: macStyle).
	aMetadata widthClass: (self widthClassFrom: os2 macStyle: macStyle).
	aMetadata slant: (self slantFrom: os2 macStyle: macStyle)
]

{ #category : 'reading' }
TTFontMetadataReader class >> rejectedMetadata: aSymbol [
	"A face read no further than its reason: a collection and a file that is not a font state
	 nothing a reader could name them by."

	^ TTFontMetadata new
		  rejectionReason: aSymbol;
		  yourself
]

{ #category : 'reading' }
TTFontMetadataReader class >> rejectionFromTags: aCollection [
	"Why a font whose directory was read cannot be drawn, or nil when it can: no name to match
	 the face by, no outlines to draw, or glyphs that are colour bitmaps or SVG documents rather
	 than outlines. The first cause answers; the others are not looked for."

	(aCollection includes: self nameTableTag) ifFalse: [ ^ #noNameTable ].
	(aCollection includes: self glyfTableTag) ifFalse: [ ^ #noGlyfTable ].
	(self colourTableTags anySatisfy: [ :tag | aCollection includes: tag ]) ifTrue: [
		^ #colourFont ].
	^ nil
]

{ #category : 'constants' }
TTFontMetadataReader class >> sfntVersions [
	"The version words of an sfnt file this reader can walk: 0x00010000 for TrueType outlines,
	 Apple's 'true', and 'OTTO' for CFF outlines, whose directory is ordinary even though its
	 glyphs are not."

	^ { #[ 0 1 0 0 ]. 'true' asByteArray. 'OTTO' asByteArray }
]

{ #category : 'private' }
TTFontMetadataReader class >> slantFrom: aDictionaryOrNil macStyle: anInteger [
	"A font that sets both bits is oblique: bit 0 is set for the benefit of readers that know
	 nothing of bit 9, so the narrower claim wins."

	| selection |
	selection := self statedIn: aDictionaryOrNil at: #fsSelection.
	(selection anyMask: self fsSelectionObliqueMask) ifTrue: [ ^ #oblique ].
	((selection anyMask: self fsSelectionItalicMask) or: [
		 anInteger anyMask: self macStyleItalicMask ]) ifTrue: [ ^ #italic ].
	^ #normal
]

{ #category : 'private' }
TTFontMetadataReader class >> statedIn: aDictionaryOrNil at: aSymbol [
	"What OS/2 says about one of its three fields, or zero when there is no OS/2 table. Zero is
	 outside every one of the three scales, so a field left at zero and a missing table are the
	 same thing: the font has not stated it."

	^ aDictionaryOrNil
		  ifNil: [ 0 ]
		  ifNotNil: [ :os2Fields | os2Fields at: aSymbol ]
]

{ #category : 'constants' }
TTFontMetadataReader class >> tableCountOffset [
	"Where the table count sits in the offset table, one-based: after the four-byte version."

	^ 5
]

{ #category : 'private' }
TTFontMetadataReader class >> weightClassFrom: aDictionaryOrNil macStyle: anInteger [
	"The 100 to 1000 scale OS/2 states outright. Without it, macStyle's bold bit leaves a choice
	 of two."

	| stated |
	stated := self statedIn: aDictionaryOrNil at: #usWeightClass.
	stated = 0 ifFalse: [ ^ stated ].
	^ (anInteger anyMask: self macStyleBoldMask)
		  ifTrue: [ self boldWeightClass ]
		  ifFalse: [ self normalWeightClass ]
]

{ #category : 'private' }
TTFontMetadataReader class >> widthClassFrom: aDictionaryOrNil macStyle: anInteger [
	"macStyle holds one condensed bit against the nine steps of usWidthClass, so without OS/2 a
	 face is condensed or it is normal."

	| stated |
	stated := self statedIn: aDictionaryOrNil at: #usWidthClass.
	stated = 0 ifFalse: [ ^ stated ].
	^ (anInteger anyMask: self macStyleCondensedMask)
		  ifTrue: [ self condensedWidthClass ]
		  ifFalse: [ self normalWidthClass ]
]
