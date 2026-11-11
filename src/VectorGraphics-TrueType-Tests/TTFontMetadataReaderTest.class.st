"
I test TTFontMetadataReader, which answers the family name and the style name of a font without parsing a single glyph.

My fixtures are minimal sfnt byte arrays I build myself: an offset table, one 16-byte table record and a name table. Nothing else of a real font is written, so a reader that needs glyf, loca, cmap or hmtx cannot pass me. That is the fact under test — a font scan must cost a name read, not a full parse, and a full parse of a 2.2 MB face costs 200 ms against under 1 ms for the names.

The reader is held against a real font elsewhere, where the layering allows it: VectorGraphics-TrueType names no font provider and no Alexandrie class, so the embedded bytes of Source Sans Pro are read in the Cairo layer, through VGFontFace class >> defaultBytes.
"
Class {
	#name : 'TTFontMetadataReaderTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-TrueType-Tests-Tests',
	#package : 'VectorGraphics-TrueType-Tests',
	#tag : 'Tests'
}

{ #category : 'fixtures' }
TTFontMetadataReaderTest >> fontBytesWithFamilyName: aFamilyName styleName: aStyleName [
	"A minimal sfnt file: the twelve-byte offset table, one sixteen-byte table record for the
	 name table, and the name table itself. The search range, the entry selector and the range
	 shift are the fields a binary search over the directory would read; nothing in this project
	 reads them, so they are written and not computed.
	 A font with no glyf, no loca, no cmap and no hmtx is what tells a metadata reader apart from
	 TTFontReader, which refuses a font missing any of the eight tables it needs."

	| nameTable |
	nameTable := self nameTableWithFamilyName: aFamilyName styleName: aStyleName.
	^ ByteArray streamContents: [ :stream |
		  self putLong: 16r00010000 on: stream.
		  self putShort: 1 on: stream.
		  self putShort: 16 on: stream.
		  self putShort: 0 on: stream.
		  self putShort: 0 on: stream.
		  stream nextPutAll: 'name' asByteArray.
		  self putLong: 0 on: stream.
		  self putLong: 28 on: stream.
		  self putLong: nameTable size on: stream.
		  stream nextPutAll: nameTable ]
]

{ #category : 'fixtures' }
TTFontMetadataReaderTest >> fontBytesWithFamilyName: aFamilyName styleName: aStyleName fillerSize: anInteger [
	"A minimal sfnt file holding two tables: a glyf table of anInteger bytes of nothing, which
	 stands for the bulk of a real font, and the name table after it. A reader that pulls the
	 whole file to read the names pulls the filler with it, which is what the counting stream
	 measures. The tables are written in the order the directory names them, as a real font
	 does, so the name table is at the far end of the file."

	| nameTable |
	nameTable := self nameTableWithFamilyName: aFamilyName styleName: aStyleName.
	^ ByteArray streamContents: [ :stream |
		  self putLong: 16r00010000 on: stream.
		  self putShort: 2 on: stream.
		  self putShort: 16 on: stream.
		  self putShort: 1 on: stream.
		  self putShort: 0 on: stream.
		  stream nextPutAll: 'glyf' asByteArray.
		  self putLong: 0 on: stream.
		  self putLong: 44 on: stream.
		  self putLong: anInteger on: stream.
		  stream nextPutAll: 'name' asByteArray.
		  self putLong: 0 on: stream.
		  self putLong: 44 + anInteger on: stream.
		  self putLong: nameTable size on: stream.
		  anInteger timesRepeat: [ stream nextPut: 0 ].
		  stream nextPutAll: nameTable ]
]

{ #category : 'fixtures' }
TTFontMetadataReaderTest >> nameTableWithFamilyName: aFamilyName styleName: aStyleName [
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
TTFontMetadataReaderTest >> putLong: anInteger on: aStream [
	"A big-endian uint32: the sfnt version, a checksum, a table offset and a table length."

	self putShort: (anInteger >> 16 bitAnd: 16rFFFF) on: aStream.
	self putShort: (anInteger bitAnd: 16rFFFF) on: aStream
]

{ #category : 'fixtures' }
TTFontMetadataReaderTest >> putShort: anInteger on: aStream [
	"A big-endian uint16, which is how every number in an sfnt file is written."

	aStream
		nextPut: (anInteger >> 8 bitAnd: 16rFF);
		nextPut: (anInteger bitAnd: 16rFF)
]

{ #category : 'tests' }
TTFontMetadataReaderTest >> testFamilyAndStyleOfAFont [
	"The fact the whole plan rests on: the family name and the style name of a font are readable
	 from the font's own name table, with no FreeType and no glyph parsed. Upstream reads them
	 through AeFTLibrary >> fastReadFacesOn:do:, which is one of the two places FreeType enters
	 the Bloc text route."

	| metadata |
	metadata := TTFontMetadataReader readBytes:
		            (self
			             fontBytesWithFamilyName: 'Source Sans Pro'
			             styleName: 'Regular').
	self assert: metadata familyName equals: 'Source Sans Pro'.
	self assert: metadata styleName equals: 'Regular'
]

{ #category : 'tests' }
TTFontMetadataReaderTest >> testReadingAStreamPullsTheHeaderTheDirectoryAndTheNameTableOnly [
	"A scan reads every font file on the machine, so what it costs is what it pulls off the
	 disk. Measured here: the 362 TrueType files of this machine hold 262 MB and take 4.6 s to
	 read whole, against 14 ms to parse their name tables once the bytes are in memory. So the
	 reader must pull the offset table, the table directory and the one table it needs, and
	 nothing else — which is what FreeType's own fast read does."

	| bytes counting metadata |
	bytes := self
		         fontBytesWithFamilyName: 'Source Sans Pro'
		         styleName: 'Regular'
		         fillerSize: 500000.
	counting := TTCountingReadStream on: bytes readStream.
	metadata := TTFontMetadataReader readStream: counting.
	self assert: metadata familyName equals: 'Source Sans Pro'.
	self assert: metadata styleName equals: 'Regular'.
	self
		assert: counting bytesPulled < 1024
		description: 'pulled ' , counting bytesPulled printString
			, ' bytes of a ' , bytes size printString , ' byte font'
]

{ #category : 'tests' }
TTFontMetadataReaderTest >> testTheReaderParsesNoGlyphData [
	"The reader exists to be cheap, so being cheap is a structural fact and not a timing: no
	 method of the reader or of the metadata object may name a glyph, a glyph table parser, a
	 font description or a face, and none may send the two selectors that parse a whole font.
	 A full parse of a 2.2 MB face costs 200 ms against under 1 ms for the names, and a scan
	 reads every font file on the machine."

	| forbiddenClassNames forbiddenSelectors offenders |
	forbiddenClassNames := #( #TTGlyph #TTCompositeGlyph #TTFontDescription
	                          #TTGlyfTableParser #TTLocaTableParser
	                          #TTCmapTableParser #TTHmtxTableParser #VGFontFace ).
	forbiddenSelectors := #( #readFrom:fromOffset: #readTTFFrom: ).
	offenders := OrderedCollection new.
	{
		TTFontMetadataReader.
		TTFontMetadataReader class.
		TTFontMetadata.
		TTFontMetadata class } do: [ :each |
		each methods do: [ :method |
			method literals do: [ :literal |
				(literal isVariableBinding and: [
					 forbiddenClassNames includes: literal key ]) ifTrue: [
					offenders add: method printString , ' names ' , literal key ] ].
			(method messages includesAny: forbiddenSelectors) ifTrue: [
				offenders add: method printString , ' parses the whole font' ] ] ].
	self assertEmpty: offenders
]
