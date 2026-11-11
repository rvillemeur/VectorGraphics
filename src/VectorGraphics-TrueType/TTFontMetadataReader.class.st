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
TTFontMetadataReader class >> directoryRecordSize [
	"One table directory record: tag, checksum, offset, length, four bytes each."

	^ 16
]

{ #category : 'private' }
TTFontMetadataReader class >> lengthsFrom: aDirectory [
	"What the directory records about every table, by tag, so the metadata can show which
	 tables were passed over and which one was read. The entries themselves hold the font's
	 bytes, and the stream door never has them all."

	^ aDirectory collect: [ :entry | entry length ]
]

{ #category : 'private' }
TTFontMetadataReader class >> metadataFromNameTableEntry: anEntry [
	"The eight strings TTNameTableParser answers are indexed by name identifier plus one, so
	 the family is the second and the subfamily — which every font manager calls the style —
	 is the third."

	| strings metadata |
	strings := (TTNameTableParser on: anEntry) process.
	metadata := TTFontMetadata new.
	metadata familyName: (strings at: 2).
	metadata styleName: (strings at: 3).
	^ metadata
]

{ #category : 'constants' }
TTFontMetadataReader class >> nameTableTag [
	"The one table I read. Both readBytes: and the Tables view ask me, so the view cannot say I
	 read a table I do not."

	^ 'name'
]

{ #category : 'constants' }
TTFontMetadataReader class >> offsetTableSize [
	"The sfnt offset table: version, table count, and three fields a reader that only names a
	 font does not use."

	^ 12
]

{ #category : 'reading' }
TTFontMetadataReader class >> readBytes: aByteArray [
	"Read a whole font's bytes: walk the table directory, read the name table and stop.
	 Prefer readStream: when the font is a file on disk — reading the file whole is the cost."

	| directory metadata |
	directory := TTFontReader buildTableDirectory: aByteArray offset: 0.
	metadata := self metadataFromNameTableEntry:
		            (directory at: self nameTableTag).
	metadata tableLengthsByTag: (self lengthsFrom: directory).
	^ metadata
]

{ #category : 'reading' }
TTFontMetadataReader class >> readStream: aStream [
	"Pull the offset table, the table directory and the name table, and nothing else. A font
	 file is megabytes and its name table is a few hundred bytes: the 362 fonts installed on
	 this machine are 262 MB and 4.6 s of disk, against 14 ms to parse all their name tables."

	| offsetTable directoryBytes directory nameEntry metadata |
	offsetTable := aStream next: self offsetTableSize.
	directoryBytes := aStream next:
		                  (offsetTable shortAt: self tableCountOffset bigEndian: true)
		                  * self directoryRecordSize.
	directory := TTFontReader
		             buildTableDirectory: offsetTable , directoryBytes
		             offset: 0.
	nameEntry := directory at: self nameTableTag.
	aStream position: nameEntry offset - 1.
	metadata := self metadataFromNameTableEntry:
		            (TTFontTableDirEntry onBytes: (aStream next: nameEntry length)).
	metadata tableLengthsByTag: (self lengthsFrom: directory).
	^ metadata
]

{ #category : 'constants' }
TTFontMetadataReader class >> tableCountOffset [
	"Where the table count sits in the offset table, one-based: after the four-byte version."

	^ 5
]
