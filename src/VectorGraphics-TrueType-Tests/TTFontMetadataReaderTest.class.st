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
TTFontMetadataReaderTest >> colourFontBytes [
	"A font with glyph outlines and a CBDT table of colour bitmaps beside them. The outlines are
	 there, so nothing but the colour table tells this face apart from a renderable one."

	^ self fontBytesWithTables: {
			  ('CBDT' -> (ByteArray new: 32)).
			  ('glyf' -> (ByteArray new: 32)).
			  (TTFontMetadataReader nameTableTag
			   -> (self nameTableWithFamilyName: 'Noto Color Emoji' styleName: 'Regular')) }
]

{ #category : 'fixtures' }
TTFontMetadataReaderTest >> fontBytesWithFamilyName: aFamilyName styleName: aStyleName [
	"An sfnt file holding a name table and nothing else: the names are readable from a font that
	 carries no glyph data at all."

	^ self fontBytesWithTables: { (TTFontMetadataReader nameTableTag
		    -> (self nameTableWithFamilyName: aFamilyName styleName: aStyleName)) }
]

{ #category : 'fixtures' }
TTFontMetadataReaderTest >> fontBytesWithFamilyName: aFamilyName styleName: aStyleName fillerSize: anInteger [
	"An sfnt file holding a glyf table of anInteger bytes of nothing, which stands for the bulk of
	 a real font, and the name table after it. A reader that pulls the whole file to read the
	 names pulls the filler with it, which is what the counting stream measures."

	^ self fontBytesWithTables: {
			  ('glyf' -> (ByteArray new: anInteger)).
			  (TTFontMetadataReader nameTableTag
			   -> (self nameTableWithFamilyName: aFamilyName styleName: aStyleName)) }
]

{ #category : 'fixtures' }
TTFontMetadataReaderTest >> fontBytesWithOS2Table: aByteArrayOrNil macStyle: anIntegerOrNil [
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
TTFontMetadataReaderTest >> fontBytesWithTables: anArray [
	"A minimal sfnt file holding the tables given as tag to bytes: the twelve-byte offset table,
	 one sixteen-byte directory record per table, then the table data. The records are written in
	 tag order, as the spec asks, while the data stays in the order given, so a fixture can put
	 the name table at the far end of the file the way a real font does.
	 A font with no glyf, no loca, no cmap and no hmtx is what tells a metadata reader apart from
	 TTFontReader, which refuses a font missing any of the eight tables it needs."

	^ self fontBytesWithVersion: #[ 0 1 0 0 ] tables: anArray
]

{ #category : 'fixtures' }
TTFontMetadataReaderTest >> fontBytesWithVersion: aByteArray tables: anArray [
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
TTFontMetadataReaderTest >> fontCollectionBytes [
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
TTFontMetadataReaderTest >> headTableWithMacStyle: anInteger [
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
TTFontMetadataReaderTest >> namelessFontBytes [
	"A font carrying outlines and no name table. A face with no name cannot be matched by family,
	 which is the one thing a font manager asks of it."

	^ self fontBytesWithTables: { ('glyf' -> (ByteArray new: 32)) }
]

{ #category : 'fixtures' }
TTFontMetadataReaderTest >> offsetsOfTables: anArray [
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
TTFontMetadataReaderTest >> os2TableWithWeightClass: aWeightClass widthClass: aWidthClass fsSelection: anInteger [
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
TTFontMetadataReaderTest >> otfFontBytes [
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
TTFontMetadataReaderTest >> putDirectoryRecordFor: anAssociation at: anInteger on: aStream [
	"One sixteen-byte directory record: the four-character tag, a checksum nothing here verifies,
	 the offset of the table's data in the file and its length."

	aStream nextPutAll: anAssociation key asByteArray.
	self putLong: 0 on: aStream.
	self putLong: anInteger on: aStream.
	self putLong: anAssociation value size on: aStream
]

{ #category : 'fixtures' }
TTFontMetadataReaderTest >> putLong: anInteger on: aStream [
	"A big-endian uint32: the sfnt version, a checksum, a table offset and a table length."

	self putShort: (anInteger >> 16 bitAnd: 16rFFFF) on: aStream.
	self putShort: (anInteger bitAnd: 16rFFFF) on: aStream
]

{ #category : 'fixtures' }
TTFontMetadataReaderTest >> putOffsetTableFor: anArray version: aByteArray on: aStream [
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
TTFontMetadataReaderTest >> putShort: anInteger on: aStream [
	"A big-endian uint16, which is how every number in an sfnt file is written."

	aStream
		nextPut: (anInteger >> 8 bitAnd: 16rFF);
		nextPut: (anInteger bitAnd: 16rFF)
]

{ #category : 'fixtures' }
TTFontMetadataReaderTest >> renderableFontBytes [
	"The shape of a font this reader accepts: glyph outlines, and a name table to name them by."

	^ self fontBytesWithTables: {
			  ('glyf' -> (ByteArray new: 32)).
			  (TTFontMetadataReader nameTableTag
			   -> (self nameTableWithFamilyName: 'Source Sans Pro' styleName: 'Regular')) }
]

{ #category : 'tests' }
TTFontMetadataReaderTest >> testAColourFontIsRejectedThoughItCarriesOutlines [

	| metadata |
	metadata := TTFontMetadataReader readBytes: self colourFontBytes.
	self assert: metadata rejectionReason equals: #colourFont.
	self assert: metadata familyName equals: 'Noto Color Emoji'
]

{ #category : 'tests' }
TTFontMetadataReaderTest >> testAFileThatIsNotAFontIsRejected [
	"The catalogue of unit 1.4 walks every file in the font directories, as AeFontScanner does,
	 which skips only dotfiles and names ending .gz. /home/renaud/.fonts/.uuid is 36 bytes of
	 text and raises SubscriptOutOfBounds today."

	self
		assert: (TTFontMetadataReader readBytes:
				 'ff50d0e4-b750-484f-9f92-c029839b4076' asByteArray) rejectionReason
		equals: #notAnSfntFont.
	self
		assert: (TTFontMetadataReader readBytes: #[ 0 1 0 0 ]) rejectionReason
		equals: #notAnSfntFont
]

{ #category : 'tests' }
TTFontMetadataReaderTest >> testAFontCollectionIsRejectedAndNotRead [
	"A ttcf file holds several fonts behind offsets. Its header carries no table directory, so
	 there is nothing to name the face from: the reason is all the reader answers."

	| metadata |
	metadata := TTFontMetadataReader readBytes: self fontCollectionBytes.
	self assert: metadata rejectionReason equals: #fontCollection.
	self assert: metadata familyName isNil
]

{ #category : 'tests' }
TTFontMetadataReaderTest >> testAFontTruncatedBeforeItsDirectoryIsRejectedRatherThanRaising [
	"The offset table promises two directory records and the file stops inside the first."

	self
		assert: (TTFontMetadataReader readBytes: (self renderableFontBytes first: 20))
				rejectionReason
		equals: #notAnSfntFont
]

{ #category : 'tests' }
TTFontMetadataReaderTest >> testAFontTruncatedInsideATableIsRejectedRatherThanRaising [
	"The directory is whole and points past the end of the file: a font half downloaded or half
	 copied. Reading the table it points at raises SubscriptOutOfBounds, so the reader checks
	 the records against the size of the file before following one."

	| bytes truncated |
	bytes := self renderableFontBytes.
	truncated := bytes first: bytes size - 20.
	self
		assert: (TTFontMetadataReader readBytes: truncated) rejectionReason
		equals: #notAnSfntFont.
	self
		assert: (TTFontMetadataReader readStream: truncated readStream) rejectionReason
		equals: #notAnSfntFont
]

{ #category : 'tests' }
TTFontMetadataReaderTest >> testAFontWithNeitherOS2NorHeadIsNormalRatherThanNil [
	"The degenerate state: a font that says nothing about its style. A scan classifies every
	 file on the machine and a nil weight would reach the font manager as a face that matches
	 nothing, so the reader answers the normal face instead."

	| metadata |
	metadata := TTFontMetadataReader readBytes:
		            (self fontBytesWithOS2Table: nil macStyle: nil).
	self assert: metadata weightClass equals: 400.
	self assert: metadata widthClass equals: 5.
	self assert: metadata slant equals: #normal
]

{ #category : 'tests' }
TTFontMetadataReaderTest >> testAFontWithNoNameTableIsRejected [
	"The name table is the only table this reader needs, and the one TTFontReader also demands.
	 Without it the reader answers a reason rather than raising KeyNotFound."

	self
		assert: (TTFontMetadataReader readBytes: self namelessFontBytes) rejectionReason
		equals: #noNameTable
]

{ #category : 'tests' }
TTFontMetadataReaderTest >> testAFontWithNoOS2TableIsClassifiedFromMacStyle [
	"OS/2 was added to the format after head, so fonts without it exist and must still be
	 classified. head's macStyle carries three of the facts in one word: bit 0 bold, bit 1
	 italic, bit 5 condensed. Bold means weight 700 and condensed means width class 3, which are
	 the only two values those bits can state."

	| metadata |
	metadata := TTFontMetadataReader readBytes:
		            (self fontBytesWithOS2Table: nil macStyle: 16r23).
	self assert: metadata weightClass equals: 700.
	self assert: metadata widthClass equals: 3.
	self assert: metadata slant equals: #italic
]

{ #category : 'tests' }
TTFontMetadataReaderTest >> testAPlainFaceIsNormalInEveryRespect [
	"The common case, and the one a default must answer: weight 400, width class 5, no slant."

	| metadata |
	metadata := TTFontMetadataReader readBytes: (self
			            fontBytesWithOS2Table: (self
					             os2TableWithWeightClass: 400
					             widthClass: 5
					             fsSelection: 0)
			            macStyle: 0).
	self assert: metadata weightClass equals: 400.
	self assert: metadata widthClass equals: 5.
	self assert: metadata slant equals: #normal
]

{ #category : 'tests' }
TTFontMetadataReaderTest >> testARenderableFontIsNotRejected [

	| metadata |
	metadata := TTFontMetadataReader readBytes: self renderableFontBytes.
	self assert: metadata rejectionReason isNil.
	self deny: metadata isRejected
]

{ #category : 'tests' }
TTFontMetadataReaderTest >> testAWeightClassOfZeroFallsBackToMacStyle [
	"Fonts in the wild leave usWeightClass at zero. Zero is outside the 100 to 1000 scale, so it
	 is not a weight but a missing field, and head's bold bit is then what the font says."

	| metadata |
	metadata := TTFontMetadataReader readBytes: (self
			            fontBytesWithOS2Table: (self
					             os2TableWithWeightClass: 0
					             widthClass: 0
					             fsSelection: 0)
			            macStyle: 16r21).
	self assert: metadata weightClass equals: 700.
	self assert: metadata widthClass equals: 3
]

{ #category : 'tests' }
TTFontMetadataReaderTest >> testAnOtfFontIsRejectedForHavingNoGlyfTable [
	"101 of the 466 font files on this machine are OTTO: readable names, CFF outlines this
	 project cannot draw. The reader names the face and says why it is not renderable, and
	 raises nothing."

	| metadata |
	metadata := TTFontMetadataReader readBytes: self otfFontBytes.
	self assert: metadata rejectionReason equals: #noGlyfTable.
	self assert: metadata isRejected.
	self assert: metadata familyName equals: 'Waree'.
	self assert: metadata styleName equals: 'Oblique'
]

{ #category : 'tests' }
TTFontMetadataReaderTest >> testBothDoorsRejectTheSameFontsForTheSameReason [
	"The stream door and the bytes door answer the same reason about the same bytes, which is
	 what lets the catalogue read from disk and a test read from memory."

	#( #otfFontBytes #fontCollectionBytes #colourFontBytes #namelessFontBytes
	   #renderableFontBytes ) do: [ :each |
		| bytes |
		bytes := self perform: each.
		self
			assert: (TTFontMetadataReader readStream: bytes readStream) rejectionReason
			equals: (TTFontMetadataReader readBytes: bytes) rejectionReason ]
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
TTFontMetadataReaderTest >> testObliqueIsToldApartFromItalic [
	"A slanted face is drawn either as a true italic or as a sheared roman, and Bloc's own
	 AeFontSlant keeps the two apart. fsSelection bit 9 says oblique, bit 0 says italic, and a
	 font that sets both is oblique: the narrower claim wins because bit 0 is set for the benefit
	 of readers that know nothing of bit 9."

	| oblique both |
	oblique := TTFontMetadataReader readBytes: (self
			           fontBytesWithOS2Table: (self
					            os2TableWithWeightClass: 400
					            widthClass: 5
					            fsSelection: 16r200)
			           macStyle: 0).
	both := TTFontMetadataReader readBytes: (self
			        fontBytesWithOS2Table: (self
					         os2TableWithWeightClass: 400
					         widthClass: 5
					         fsSelection: 16r201)
			        macStyle: 0).
	self assert: oblique slant equals: #oblique.
	self assert: both slant equals: #oblique
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

{ #category : 'tests' }
TTFontMetadataReaderTest >> testTheStreamDoorPullsTheThreeTablesItClassifiesFrom [
	"The stream door now needs three tables, not one, and all three are small: a name table is a
	 few hundred bytes, head is 54 and OS/2 is 78. So classifying a face off a stream still costs
	 a fraction of the file, which is the whole point of the door."

	| bytes counting metadata |
	bytes := self fontBytesWithTables: {
			         ('glyf' -> (ByteArray new: 500000)).
			         (TTFontMetadataReader os2TableTag -> (self
				           os2TableWithWeightClass: 700
				           widthClass: 3
				           fsSelection: 1)).
			         (TTFontMetadataReader headTableTag
			          -> (self headTableWithMacStyle: 0)).
			         (TTFontMetadataReader nameTableTag -> (self
				           nameTableWithFamilyName: 'Source Sans Pro'
				           styleName: 'Regular')) }.
	counting := TTCountingReadStream on: bytes readStream.
	metadata := TTFontMetadataReader readStream: counting.
	self assert: metadata weightClass equals: 700.
	self assert: metadata widthClass equals: 3.
	self assert: metadata slant equals: #italic.
	self
		assert: counting bytesPulled < 1024
		description: 'pulled ' , counting bytesPulled printString , ' bytes'
]

{ #category : 'tests' }
TTFontMetadataReaderTest >> testWeightWidthAndSlantComeFromTheFontsOwnTables [
	"What this replaces is a guess. Upstream, AeFaceEntry >> ensureAnalysedAttributes splits the
	 style name on spaces and readStyleFrom: matches the tokens against word lists, with special
	 cases for 'boldoblique' and 'bold.1.1'. OS/2 states the same three facts outright, so a face
	 whose style name says 'Regular' is still read as bold, condensed and italic."

	| metadata |
	metadata := TTFontMetadataReader readBytes: (self
			            fontBytesWithOS2Table: (self
					             os2TableWithWeightClass: 700
					             widthClass: 3
					             fsSelection: 1)
			            macStyle: 0).
	self assert: metadata weightClass equals: 700.
	self assert: metadata widthClass equals: 3.
	self assert: metadata slant equals: #italic
]
