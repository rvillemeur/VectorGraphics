"
I build the bytes of synthetic sfnt fonts, on my class side, for the tests that read fonts without a file on disk.

A font I build is the smallest file that still answers the question being asked: an offset table, one directory record per table, and the table data. Nothing checks a checksum, so the records carry zero where a real font carries one.

I exist because two test classes read the same fixtures: TTFontMetadataReaderTest reads one font at a time, and TTFontCatalogueTest writes several of my fonts into a FileSystem memory directory and scans it. I hold no state and nobody instantiates me.
"
Class {
	#name : 'TTFontFixtures',
	#superclass : 'Object',
	#category : 'VectorGraphics-TrueType-Tests-Fixtures',
	#package : 'VectorGraphics-TrueType-Tests',
	#tag : 'Fixtures'
}

{ #category : 'fixtures' }
TTFontFixtures class >> colourFontBytes [
	"A font with glyph outlines and a CBDT table of colour bitmaps beside them. The outlines are
	 there, so nothing but the colour table tells this face apart from a renderable one."

	^ self fontBytesWithTables: {
			  ('CBDT' -> (ByteArray new: 32)).
			  ('glyf' -> (ByteArray new: 32)).
			  (TTFontMetadataReader nameTableTag
			   -> (self nameTableWithFamilyName: 'Noto Color Emoji' styleName: 'Regular')) }
]

{ #category : 'fixtures' }
TTFontFixtures class >> fontBytesWithFamilyName: aFamilyName styleName: aStyleName [
	"An sfnt file holding a name table and nothing else: the names are readable from a font that
	 carries no glyph data at all."

	^ self fontBytesWithTables: { (TTFontMetadataReader nameTableTag
		    -> (self nameTableWithFamilyName: aFamilyName styleName: aStyleName)) }
]

{ #category : 'fixtures' }
TTFontFixtures class >> fontBytesWithFamilyName: aFamilyName styleName: aStyleName fillerSize: anInteger [
	"An sfnt file holding a glyf table of anInteger bytes of nothing, which stands for the bulk of
	 a real font, and the name table after it. A reader that pulls the whole file to read the
	 names pulls the filler with it, which is what the counting stream measures."

	^ self fontBytesWithTables: {
			  ('glyf' -> (ByteArray new: anInteger)).
			  (TTFontMetadataReader nameTableTag
			   -> (self nameTableWithFamilyName: aFamilyName styleName: aStyleName)) }
]

{ #category : 'fixtures' }
TTFontFixtures class >> fontBytesWithOS2Table: aByteArrayOrNil macStyle: anIntegerOrNil [
	"An sfnt file carrying a name table, plus an OS/2 table and a head table when each is asked
	 for. Nil stands for a font that does not carry that table: fonts with no OS/2 table exist
	 and are classified from head alone, and a font with neither says nothing about its style."

	| tables |
	tables := OrderedCollection new.
	aByteArrayOrNil ifNotNil: [ :bytes |
		tables add: TTFontMetadataReader os2TableTag -> bytes ].
	anIntegerOrNil ifNotNil: [ :macStyle |
		tables add: TTFontMetadataReader headTableTag
			-> (self headTableWithMacStyle: macStyle) ].
	tables add: TTFontMetadataReader nameTableTag
		-> (self nameTableWithFamilyName: 'Source Sans Pro' styleName: 'Regular').
	^ self fontBytesWithTables: tables asArray
]

{ #category : 'fixtures' }
TTFontFixtures class >> fontBytesWithTables: anArray [
	"A minimal sfnt file holding the tables given as tag to bytes: the twelve-byte offset table,
	 one sixteen-byte directory record per table, then the table data. The records are written in
	 tag order, as the spec asks, while the data stays in the order given, so a fixture can put
	 the name table at the far end of the file the way a real font does.
	 A font with no glyf, no loca, no cmap and no hmtx is what tells a metadata reader apart from
	 TTFontReader, which refuses a font missing any of the eight tables it needs."

	^ self fontBytesWithVersion: #[ 0 1 0 0 ] tables: anArray
]

{ #category : 'fixtures' }
TTFontFixtures class >> fontBytesWithVersion: aByteArray tables: anArray [
	"A minimal sfnt file whose version word is given: #[0 1 0 0] for TrueType outlines, 'OTTO'
	 for the CFF outlines of an OpenType font, and anything else for a file this reader knows
	 nothing of."

	| offsets |
	offsets := self offsetsOfTables: anArray.
	^ ByteArray streamContents: [ :stream |
		  self putOffsetTableFor: anArray version: aByteArray on: stream.
		  (anArray asSortedCollection: [ :a :b | a key <= b key ]) do: [ :each |
			  self
				  putDirectoryRecordFor: each
				  at: (offsets at: each key)
				  on: stream ].
		  anArray do: [ :each | stream nextPutAll: each value ] ]
]

{ #category : 'fixtures' }
TTFontFixtures class >> fontCollectionBytes [
	"A ttcf header: the tag, a version, the number of fonts it holds and one offset per font. A
	 collection has no table directory of its own at byte twelve, which is why reading one as a
	 font raises KeyNotFound today."

	^ ByteArray streamContents: [ :stream |
		  stream nextPutAll: 'ttcf' asByteArray.
		  self putLong: 16r00010000 on: stream.
		  self putLong: 2 on: stream.
		  self putLong: 24 on: stream.
		  self putLong: 1024 on: stream ]
]

{ #category : 'fixtures' }
TTFontFixtures class >> headTableWithMacStyle: anInteger [
	"The bytes of a head table. Only macStyle matters to a reader that classifies a face, and it
	 is all a font with no OS/2 table says about itself: bit 0 bold, bit 1 italic, bit 5
	 condensed. The units per em, the bounding box and the index-to-location format are read when
	 a glyph is parsed, which is what this reader never does."

	^ ByteArray streamContents: [ :stream |
		  self putLong: 16r00010000 on: stream. "version"
		  self putLong: 0 on: stream. "fontRevision"
		  self putLong: 0 on: stream. "checkSumAdjustment"
		  self putLong: 16r5F0F3CF5 on: stream. "magicNumber"
		  self putShort: 0 on: stream. "flags"
		  self putShort: 1000 on: stream. "unitsPerEm"
		  8 timesRepeat: [ self putShort: 0 on: stream ]. "created(8) + modified(8)"
		  4 timesRepeat: [ self putShort: 0 on: stream ]. "xMin yMin xMax yMax"
		  self putShort: anInteger on: stream. "macStyle"
		  self putShort: 8 on: stream. "lowestRecPPEM"
		  self putShort: 2 on: stream. "fontDirectionHint"
		  self putShort: 0 on: stream. "indexToLocFormat"
		  self putShort: 0 on: stream "glyphDataFormat" ]
]

{ #category : 'fixtures' }
TTFontFixtures class >> nameTableWithFamilyName: aFamilyName styleName: aStyleName [
	"The bytes of a name table holding two records: name identifier 1, the family, and name
	 identifier 2, the subfamily, which is the style. Both are written in the Macintosh
	 encoding — platform 1, Roman, English — so the strings are one byte a character.
	 The record offsets are relative to the string storage, and the storage follows the records."

	| records storageOffset position |
	records := {
		           (1 -> aFamilyName).
		           (2 -> aStyleName) }.
	storageOffset := 6 + (records size * 12).
	position := 0.
	^ ByteArray streamContents: [ :stream |
		  self putShort: 0 on: stream.
		  self putShort: records size on: stream.
		  self putShort: storageOffset on: stream.
		  records do: [ :each |
			  self putShort: 1 on: stream.
			  self putShort: 0 on: stream.
			  self putShort: 0 on: stream.
			  self putShort: each key on: stream.
			  self putShort: each value size on: stream.
			  self putShort: position on: stream.
			  position := position + each value size ].
		  records do: [ :each | stream nextPutAll: each value asByteArray ] ]
]

{ #category : 'fixtures' }
TTFontFixtures class >> namelessFontBytes [
	"A font carrying outlines and no name table. A face with no name cannot be matched by family,
	 which is the one thing a font manager asks of it."

	^ self fontBytesWithTables: { ('glyf' -> (ByteArray new: 32)) }
]

{ #category : 'fixtures' }
TTFontFixtures class >> offsetsOfTables: anArray [
	"Where the data of each table lands: after the offset table and one record per table, then in
	 the order the tables were given."

	| position offsets |
	position := 12 + (anArray size * 16).
	offsets := Dictionary new.
	anArray do: [ :each |
		offsets at: each key put: position.
		position := position + each value size ].
	^ offsets
]

{ #category : 'fixtures' }
TTFontFixtures class >> os2TableWithWeightClass: aWeightClass widthClass: aWidthClass fsSelection: anInteger [
	"The bytes of a version 0 OS/2 table. Three fields classify the face: usWeightClass on the
	 100 to 1000 scale, usWidthClass on the 1 to 9 scale that starts at ultra-condensed, and the
	 fsSelection bits, of which bit 0 is italic and bit 9 oblique. Everything between them — the
	 subscript, superscript and strikeout metrics, the family class, PANOSE, the Unicode ranges
	 and the vendor id — is written so the offsets are real and read by nobody here."

	^ ByteArray streamContents: [ :stream |
		  self putShort: 0 on: stream. "version"
		  self putShort: 500 on: stream. "xAvgCharWidth"
		  self putShort: aWeightClass on: stream.
		  self putShort: aWidthClass on: stream.
		  self putShort: 0 on: stream. "fsType"
		  10 timesRepeat: [ self putShort: 0 on: stream ]. "subscript, superscript, strikeout"
		  self putShort: 0 on: stream. "sFamilyClass"
		  10 timesRepeat: [ stream nextPut: 0 ]. "panose"
		  4 timesRepeat: [ self putLong: 0 on: stream ]. "ulUnicodeRange1 to 4"
		  stream nextPutAll: 'NONE' asByteArray. "achVendID"
		  self putShort: anInteger on: stream.
		  7 timesRepeat: [ self putShort: 0 on: stream ] "char indexes and the four metrics" ]
]

{ #category : 'fixtures' }
TTFontFixtures class >> otfFontBytes [
	"An OTTO file: a valid sfnt wrapper whose outlines are CFF, so it carries a CFF table and no
	 glyf. Its name table is ordinary, which is why the reader can name a face it cannot render."

	^ self
		  fontBytesWithVersion: 'OTTO' asByteArray
		  tables: {
				  ('CFF ' -> (ByteArray new: 64)).
				  (TTFontMetadataReader nameTableTag
				   -> (self nameTableWithFamilyName: 'Waree' styleName: 'Oblique')) }
]

{ #category : 'fixtures' }
TTFontFixtures class >> putDirectoryRecordFor: anAssociation at: anInteger on: aStream [
	"One sixteen-byte directory record: the four-character tag, a checksum nothing here verifies,
	 the offset of the table's data in the file and its length."

	aStream nextPutAll: anAssociation key asByteArray.
	self putLong: 0 on: aStream.
	self putLong: anInteger on: aStream.
	self putLong: anAssociation value size on: aStream
]

{ #category : 'fixtures' }
TTFontFixtures class >> putLong: anInteger on: aStream [
	"A big-endian uint32: the sfnt version, a checksum, a table offset and a table length."

	self putShort: (anInteger >> 16 bitAnd: 16rFFFF) on: aStream.
	self putShort: (anInteger bitAnd: 16rFFFF) on: aStream
]

{ #category : 'fixtures' }
TTFontFixtures class >> putOffsetTableFor: anArray version: aByteArray on: aStream [
	"The twelve-byte offset table. The search range, the entry selector and the range shift are
	 the fields a binary search over the directory would read; nothing in this project reads them,
	 so they are written and not computed."

	aStream nextPutAll: aByteArray.
	self putShort: anArray size on: aStream.
	self putShort: 16 on: aStream.
	self putShort: 0 on: aStream.
	self putShort: 0 on: aStream
]

{ #category : 'fixtures' }
TTFontFixtures class >> putShort: anInteger on: aStream [
	"A big-endian uint16, which is how every number in an sfnt file is written."

	aStream
		nextPut: (anInteger >> 8 bitAnd: 16rFF);
		nextPut: (anInteger bitAnd: 16rFF)
]

{ #category : 'fixtures' }
TTFontFixtures class >> renderableFontBytes [
	"The shape of a font this reader accepts: glyph outlines, and a name table to name them by."

	^ self fontBytesWithTables: {
			  ('glyf' -> (ByteArray new: 32)).
			  (TTFontMetadataReader nameTableTag
			   -> (self nameTableWithFamilyName: 'Source Sans Pro' styleName: 'Regular')) }
]

{ #category : 'fixtures' }
TTFontFixtures class >> renderableFontBytesWithFamilyName: aFamilyName styleName: aStyleName weightClass: anInteger italic: aBoolean [
	"A font a catalogue keeps: glyph outlines, a name table to match the face by, and an OS/2
	 table stating the weight, the width and the slant. Six of these over two families are what
	 a scan is counted on, and the three fields are what tells two faces of one family apart."

	^ self fontBytesWithTables: {
			  ('glyf' -> (ByteArray new: 32)).
			  (TTFontMetadataReader os2TableTag -> (self
				    os2TableWithWeightClass: anInteger
				    widthClass: 5
				    fsSelection: (aBoolean
						     ifTrue: [ 1 ]
						     ifFalse: [ 0 ]))).
			  (TTFontMetadataReader nameTableTag
			   -> (self nameTableWithFamilyName: aFamilyName styleName: aStyleName)) }
]
