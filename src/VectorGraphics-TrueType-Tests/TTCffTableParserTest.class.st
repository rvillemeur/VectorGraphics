"
I test the reading of a whole `CFF ` table: its header, the four INDEXes it begins with, the top dictionary and the private dictionary the top dictionary points at, and the subroutines both of them carry.

I read tables TTCffBytesFixture writes, so a table here holds the smallest thing that answers the question: one charstring, no string, no subroutine. What a charstring draws is not my subject.
"
Class {
	#name : 'TTCffTableParserTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-TrueType-Tests-Tests',
	#package : 'VectorGraphics-TrueType-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
TTCffTableParserTest >> testAFontKeyedByCharacterIdentifiersIsRefusedAndTheErrorSaysWhy [
	"A CID-keyed font carries ROS in its top dictionary, and its glyphs are reached through an
	 FDArray and an FDSelect instead of one private dictionary. This reader does not draw one, so
	 it says so rather than reading the font as if it were any other."

	| cursor error |
	cursor := (TTCffBytesFixture new
		           topEntries: { (1230 -> #( 391 392 0 )) };
		           yourself) tableCursor.
	error := [
	         (TTCffTableParser on: cursor) process.
	         nil ]
		         on: TTCffError
		         do: [ :each | each ].
	self assert: error notNil description: 'a CID-keyed font was read as if it were not'.
	self assert: (error messageText includesSubstring: 'CID')
]

{ #category : 'tests' }
TTCffTableParserTest >> testAPrivateDictionaryThatStatesNoWidthMeansZeroForBoth [
	"A private dictionary leaving out defaultWidthX and nominalWidthX says both are zero. The
	 widths of every glyph of such a font are read against those two numbers."

	| parser |
	parser := (TTCffTableParser on: TTCffBytesFixture new tableCursor) process.
	self assert: parser defaultWidthX equals: 0.
	self assert: parser nominalWidthX equals: 0
]

{ #category : 'tests' }
TTCffTableParserTest >> testATableIsReadWhateverSizeItsHeaderClaims [
	"The header states its own size. A font is free to leave room after the four bytes it needs,
	 and what follows starts where the header says it does."

	#( 4 8 32 ) do: [ :headerSize |
		| parser |
		parser := (TTCffTableParser on: (TTCffBytesFixture new
			            headerSize: headerSize;
			            yourself) tableCursor) process.
		self assert: parser glyphCount equals: 1.
		self assert: (parser charstringAt: 1) equals: #[ 14 ] asByteArray ]
]

{ #category : 'tests' }
TTCffTableParserTest >> testATableWhoseTopDictionaryNamesNoCharstringsIsRefused [
	"CharStrings and Private are the two entries a font cannot leave out: without them there is
	 no glyph to draw and no width to draw it by. The byte 17 is that operator here, and the
	 count is asserted so that this stays the only byte the table changes."

	| bytes error |
	bytes := TTCffBytesFixture new tableBytes.
	self assert: (bytes occurrencesOf: 17) equals: 1.
	error := [
	         (TTCffTableParser on: (TTFontTableDirEntry onBytes:
			           (bytes copyReplaceAll: #[ 17 ] asByteArray with: #[ 16 ] asByteArray))) process.
	         nil ]
		         on: TTCffError
		         do: [ :each | each ].
	self assert: error notNil description: 'a table with no CharStrings entry was read'.
	self assert: (error messageText includesSubstring: '17')
]

{ #category : 'tests' }
TTCffTableParserTest >> testTheCharstringsAreFoundWhereTheTopDictionarySaysTheyAre [
	"The offset of the charstrings is counted from the first byte of the table, not from the
	 cursor and not from the end of the header."

	| parser |
	parser := (TTCffTableParser on: (TTCffBytesFixture new
		            charstrings: {
				            #[ 14 ] asByteArray.
				            #[ 139 139 14 ] asByteArray.
				            #[ 255 ] asByteArray };
		            yourself) tableCursor) process.
	self assert: parser glyphCount equals: 3.
	self assert: (parser charstringAt: 1) equals: #[ 14 ] asByteArray.
	self assert: (parser charstringAt: 2) equals: #[ 139 139 14 ] asByteArray.
	self assert: (parser charstringAt: 3) equals: #[ 255 ] asByteArray
]

{ #category : 'tests' }
TTCffTableParserTest >> testThePrivateDictionaryIsReadWhereAndAsLongAsTheTopDictionarySays [
	"The private dictionary is the only structure a CFF table gives both a place and a length:
	 its bytes are not an INDEX element, so the length is the only thing that ends it."

	| parser |
	parser := (TTCffTableParser on: (TTCffBytesFixture new
		            privateEntries: {
				            (20 -> #( 480 )).
				            (21 -> #( 123 )) };
		            yourself) tableCursor) process.
	self assert: parser defaultWidthX equals: 480.
	self assert: parser nominalWidthX equals: 123.
	self assert: parser localSubrs isEmpty
]

{ #category : 'tests' }
TTCffTableParserTest >> testTheSubroutinesAreReadFromBothPlacesAFontKeepsThem [
	"The global subroutines are an INDEX of the table itself; the local ones start at an offset
	 counted from the private dictionary, not from the table."

	| parser |
	parser := (TTCffTableParser on: (TTCffBytesFixture new
		            privateEntries: { (20 -> #( 480 )) };
		            localSubrs: {
				            #[ 11 ] asByteArray.
				            #[ 139 139 11 ] asByteArray };
		            globalSubrs: { #[ 10 11 ] asByteArray };
		            yourself) tableCursor) process.
	self assert: parser globalSubrs size equals: 1.
	self assert: (parser globalSubrs at: 1) equals: #[ 10 11 ] asByteArray.
	self assert: parser localSubrs size equals: 2.
	self assert: (parser localSubrs at: 2) equals: #[ 139 139 11 ] asByteArray
]
