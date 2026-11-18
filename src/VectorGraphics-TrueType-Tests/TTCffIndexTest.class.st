"
I test the reading of a CFF INDEX: the count, the offset size, where one element ends and the next begins, and the degenerate INDEX that holds nothing.

My fixtures are the bytes TTCffBytesFixture writes, so an offset size a real font would never choose can still be read here.
"
Class {
	#name : 'TTCffIndexTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-TrueType-Tests-Tests',
	#package : 'VectorGraphics-TrueType-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
TTCffIndexTest >> testAnElementOfNoByteIsReadAsAnEmptyByteArray [
	"Two equal offsets say an element of no byte. The charstring of a blank glyph is written
	 that way, so it is a shape to read, not a malformed font."

	| index |
	index := TTCffIndex readFrom: (TTFontTableDirEntry onBytes: (TTCffBytesFixture
			          indexBytesWithElements: {
					          #[ 9 ] asByteArray.
					          ByteArray new.
					          #[ 8 ] asByteArray })).
	self assert: index size equals: 3.
	self assert: (index at: 2) equals: ByteArray new.
	self assert: (index at: 3) equals: #[ 8 ] asByteArray
]

{ #category : 'tests' }
TTCffIndexTest >> testAnEmptyIndexHoldsNoElementAndIsTwoBytesLong [
	"A CFF INDEX of no element is written as a count of zero and nothing else: no offSize byte
	 and no offset. A reader that expects them reads the bytes of whatever follows."

	| bytes index entry |
	bytes := TTCffBytesFixture indexBytesWithElements: #( ).
	self assert: bytes size equals: 2.
	entry := TTFontTableDirEntry onBytes: bytes.
	index := TTCffIndex readFrom: entry.
	self assert: index size equals: 0.
	self assert: index isEmpty.
	self assert: entry offset equals: 3
]

{ #category : 'tests' }
TTCffIndexTest >> testAnIndexAnswersEachElementWhateverTheWidthOfItsOffsets [
	"The offSize byte says how many bytes each offset takes. A font writes the narrowest width
	 its data allows, but all four widths say the same thing and all four must be read."

	| elements |
	elements := { #[ 1 2 3 ] asByteArray. #[ 4 ] asByteArray. #[ 5 6 ] asByteArray }.
	1 to: 4 do: [ :offSize |
		| index |
		index := TTCffIndex readFrom: (TTFontTableDirEntry onBytes:
				          (TTCffBytesFixture indexBytesWithElements: elements offSize: offSize)).
		self assert: index size equals: 3.
		self deny: index isEmpty.
		1 to: 3 do: [ :each |
			self assert: (index at: each) equals: (elements at: each) ] ]
]

{ #category : 'tests' }
TTCffIndexTest >> testAnIndexLeavesTheCursorOnTheByteAfterItsData [
	"A CFF table is read in order: the INDEX of names, then the INDEX of top dictionaries, and
	 so on. Each one must leave the cursor where the next one begins."

	| bytes entry |
	bytes := (TTCffBytesFixture indexBytesWithElements: { #[ 7 7 7 ] asByteArray })
		         , #[ 42 ] asByteArray.
	entry := TTFontTableDirEntry onBytes: bytes.
	TTCffIndex readFrom: entry.
	self assert: entry nextByte equals: 42
]

{ #category : 'tests' }
TTCffIndexTest >> testAskingAnIndexForAnElementDoesNotMoveTheCursor [
	"Charstrings are read one glyph at a time, long after the table was parsed. Reading one
	 element must not disturb whoever else holds the cursor."

	| bytes entry index |
	bytes := (TTCffBytesFixture indexBytesWithElements: {
			          #[ 1 2 ] asByteArray.
			          #[ 3 4 ] asByteArray }) , #[ 42 ] asByteArray.
	entry := TTFontTableDirEntry onBytes: bytes.
	index := TTCffIndex readFrom: entry.
	self assert: (index at: 1) equals: #[ 1 2 ] asByteArray.
	self assert: (index at: 2) equals: #[ 3 4 ] asByteArray.
	self assert: entry nextByte equals: 42
]
