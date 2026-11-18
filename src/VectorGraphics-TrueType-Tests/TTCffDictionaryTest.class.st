"
I test the reading of a CFF dictionary: the four integer encodings and their boundaries, the real numbers written in nibbles, the operators of one byte and of two, and a dictionary of several entries.

A dictionary is where a CFF table says everything about a font that is not a glyph: where the charstrings are, what the private dictionary holds, what the font matrix is. Reading an operand one byte wide where it is two leaves the reader inside the next number, so the boundaries of each encoding are tested from both sides.
"
Class {
	#name : 'TTCffDictionaryTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-TrueType-Tests-Tests',
	#package : 'VectorGraphics-TrueType-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
TTCffDictionaryTest >> testAByteThatSaysNoOperandIsRefusedAndTheErrorNamesIt [
	"The bytes 22 to 27, 31 and 255 say nothing a dictionary can hold. A reader that walks past
	 one reads the rest of the table at the wrong place, so it stops here instead."

	#( 22 27 31 255 ) do: [ :byte |
		| error |
		error := [
		         TTCffDictionary readFrom: (ByteArray with: byte with: 5).
		         nil ]
			         on: TTCffError
			         do: [ :each | each ].
		self assert: error notNil description: byte printString , ' was read as an operand'.
		self assert: (error messageText includesSubstring: byte printString) ]
]

{ #category : 'tests' }
TTCffDictionaryTest >> testARealOperandIsReadFromTheNibblesThatSpellIt [
	"A real operand is the characters of the number, one nibble each: the digits, the point, the
	 exponent, the minus sign, and a nibble that says the number has ended."

	{
		('0.001' -> 0.001).
		('-2.25' -> -2.25).
		('1e-3' -> 0.001).
		('12e3' -> 12000).
		('-0.5' -> -0.5) } do: [ :each |
		| dictionary |
		dictionary := TTCffDictionary readFrom:
			              (TTCffBytesFixture dictBytesWithEntries: { (1207 -> { each key }) }).
		self
			assert: (dictionary at: 1207) first
			closeTo: each value
			precision: 1.0e-9 ]
]

{ #category : 'tests' }
TTCffDictionaryTest >> testAnEscapedOperatorIsOneOperatorAndNotTwo [
	"The byte 12 is an escape: it and the byte after it are one operator. A reader that takes
	 them for two operators files the operands under the wrong one and loses the rest."

	| dictionary |
	dictionary := TTCffDictionary readFrom:
		              (TTCffBytesFixture dictBytesWithEntries: { (1207 -> #( 1 0 0 1 0 0 )) }).
	self assert: dictionary size equals: 1.
	self assert: (dictionary at: 1207) equals: #( 1 0 0 1 0 0 ).
	self assert: (dictionary at: 12 ifAbsent: [ #none ]) equals: #none
]

{ #category : 'tests' }
TTCffDictionaryTest >> testAnIntegerOperandIsReadBackWhateverTheWidthItWasWrittenIn [
	"The four integer encodings meet at -107, 107, -1131, 1131 and the 16-bit bounds. Each
	 number here is written in the narrowest form that can say it and must come back as itself."

	#( 0 1 -1 107 -107 108 -108 1131 -1131 1132 -1132 32767 -32768 32768 -32769 65536 -70000 )
		do: [ :each |
			| dictionary |
			dictionary := TTCffDictionary readFrom:
				              (TTCffBytesFixture dictBytesWithEntries: { (5 -> { each }) }).
			self assert: (dictionary at: 5) equals: { each } ]
]

{ #category : 'tests' }
TTCffDictionaryTest >> testAskingForAnOperatorTheDictionaryDoesNotHoldIsRefused [
	"Every operator a reader asks for is one the font must carry. Answering nil instead would
	 push the defect into the arithmetic that follows."

	| dictionary error |
	dictionary := TTCffDictionary readFrom:
		              (TTCffBytesFixture dictBytesWithEntries: { (17 -> #( 1234 )) }).
	self assert: (dictionary at: 17 ifAbsent: [ #none ]) equals: #( 1234 ).
	self assert: (dictionary at: 18 ifAbsent: [ #none ]) equals: #none.
	error := [
	         dictionary at: 18.
	         nil ]
		         on: TTCffError
		         do: [ :each | each ].
	self assert: error notNil.
	self assert: (error messageText includesSubstring: '18')
]

{ #category : 'tests' }
TTCffDictionaryTest >> testEveryOperandOfAnEntryIsKeptInTheOrderItWasWritten [
	"FontBBox carries four operands and FontMatrix six. An entry is the operands before its
	 operator, in order, and the next entry starts with an empty hand."

	| dictionary |
	dictionary := TTCffDictionary readFrom: (TTCffBytesFixture dictBytesWithEntries: {
			               (5 -> #( -200 -200 1000 900 )).
			               (15 -> #( 391 )).
			               (17 -> #( 1234 )) }).
	self assert: dictionary size equals: 3.
	self assert: (dictionary at: 5) equals: #( -200 -200 1000 900 ).
	self assert: (dictionary at: 15) equals: #( 391 ).
	self assert: (dictionary at: 17) equals: #( 1234 ).
	self assert: (dictionary includesOperator: 17).
	self deny: (dictionary includesOperator: 16)
]
