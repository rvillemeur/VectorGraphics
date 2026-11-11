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

{ #category : 'tests' }
TTFontMetadataReaderTest >> testAColourFontIsRejectedThoughItCarriesOutlines [

	| metadata |
	metadata := TTFontMetadataReader readBytes: TTFontFixtures colourFontBytes.
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
	metadata := TTFontMetadataReader readBytes: TTFontFixtures fontCollectionBytes.
	self assert: metadata rejectionReason equals: #fontCollection.
	self assert: metadata familyName isNil
]

{ #category : 'tests' }
TTFontMetadataReaderTest >> testAFontTruncatedBeforeItsDirectoryIsRejectedRatherThanRaising [
	"The offset table promises two directory records and the file stops inside the first."

	self
		assert: (TTFontMetadataReader readBytes: (TTFontFixtures renderableFontBytes first: 20))
				rejectionReason
		equals: #notAnSfntFont
]

{ #category : 'tests' }
TTFontMetadataReaderTest >> testAFontTruncatedInsideATableIsRejectedRatherThanRaising [
	"The directory is whole and points past the end of the file: a font half downloaded or half
	 copied. Reading the table it points at raises SubscriptOutOfBounds, so the reader checks
	 the records against the size of the file before following one."

	| bytes truncated |
	bytes := TTFontFixtures renderableFontBytes.
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
		            (TTFontFixtures fontBytesWithOS2Table: nil macStyle: nil).
	self assert: metadata weightClass equals: 400.
	self assert: metadata widthClass equals: 5.
	self assert: metadata slant equals: #normal
]

{ #category : 'tests' }
TTFontMetadataReaderTest >> testAFontWithNoNameTableIsRejected [
	"The name table is the only table this reader needs, and the one TTFontReader also demands.
	 Without it the reader answers a reason rather than raising KeyNotFound."

	self
		assert: (TTFontMetadataReader readBytes: TTFontFixtures namelessFontBytes) rejectionReason
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
		            (TTFontFixtures fontBytesWithOS2Table: nil macStyle: 16r23).
	self assert: metadata weightClass equals: 700.
	self assert: metadata widthClass equals: 3.
	self assert: metadata slant equals: #italic
]

{ #category : 'tests' }
TTFontMetadataReaderTest >> testAPlainFaceIsNormalInEveryRespect [
	"The common case, and the one a default must answer: weight 400, width class 5, no slant."

	| metadata |
	metadata := TTFontMetadataReader readBytes: (TTFontFixtures fontBytesWithOS2Table: (TTFontFixtures os2TableWithWeightClass: 400
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
	metadata := TTFontMetadataReader readBytes: TTFontFixtures renderableFontBytes.
	self assert: metadata rejectionReason isNil.
	self deny: metadata isRejected
]

{ #category : 'tests' }
TTFontMetadataReaderTest >> testAWeightClassOfZeroFallsBackToMacStyle [
	"Fonts in the wild leave usWeightClass at zero. Zero is outside the 100 to 1000 scale, so it
	 is not a weight but a missing field, and head's bold bit is then what the font says."

	| metadata |
	metadata := TTFontMetadataReader readBytes: (TTFontFixtures fontBytesWithOS2Table: (TTFontFixtures os2TableWithWeightClass: 0
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
	metadata := TTFontMetadataReader readBytes: TTFontFixtures otfFontBytes.
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
		bytes := TTFontFixtures perform: each.
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
		            (TTFontFixtures fontBytesWithFamilyName: 'Source Sans Pro'
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
	oblique := TTFontMetadataReader readBytes: (TTFontFixtures fontBytesWithOS2Table: (TTFontFixtures os2TableWithWeightClass: 400
					            widthClass: 5
					            fsSelection: 16r200)
			           macStyle: 0).
	both := TTFontMetadataReader readBytes: (TTFontFixtures fontBytesWithOS2Table: (TTFontFixtures os2TableWithWeightClass: 400
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
	bytes := TTFontFixtures fontBytesWithFamilyName: 'Source Sans Pro'
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
	bytes := TTFontFixtures fontBytesWithTables: {
			         ('glyf' -> (ByteArray new: 500000)).
			         (TTFontMetadataReader os2TableTag -> (TTFontFixtures os2TableWithWeightClass: 700
				           widthClass: 3
				           fsSelection: 1)).
			         (TTFontMetadataReader headTableTag
			          -> (TTFontFixtures headTableWithMacStyle: 0)).
			         (TTFontMetadataReader nameTableTag -> (TTFontFixtures nameTableWithFamilyName: 'Source Sans Pro'
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
	metadata := TTFontMetadataReader readBytes: (TTFontFixtures fontBytesWithOS2Table: (TTFontFixtures os2TableWithWeightClass: 700
					             widthClass: 3
					             fsSelection: 1)
			            macStyle: 0).
	self assert: metadata weightClass equals: 700.
	self assert: metadata widthClass equals: 3.
	self assert: metadata slant equals: #italic
]
