"
I build the bytes of CFF structures for the tests that read a CFF table without a font file on disk.

On my class side I write one structure at a time: an INDEX of given elements, a dictionary of given operands and operators. On my instance side I write a whole `CFF ` table around what a test sets: its charstrings, the extra entries of its two dictionaries, its subroutines and the size it claims for its header. Everything a test does not set is as small as a table can be.

What I write is the smallest run of bytes that still answers the question being asked, which is why an offset width a real font would never choose can be asked for here.

I exist beside TTFontFixtures, which builds whole sfnt fonts: the structures inside a CFF table are a subject of their own.
"
Class {
	#name : 'TTCffBytesFixture',
	#superclass : 'Object',
	#instVars : [
		'charstrings',
		'topEntries',
		'privateEntries',
		'localSubrs',
		'globalSubrs',
		'headerSize',
		'charsetIdentifiers',
		'charsetFormat'
	],
	#category : 'VectorGraphics-TrueType-Tests-Fixtures',
	#package : 'VectorGraphics-TrueType-Tests',
	#tag : 'Fixtures'
}

{ #category : 'building' }
TTCffBytesFixture class >> charstringBytesWith: aCollection [
	"The bytes of a Type 2 charstring, written from operands and operator names in the order a
	 charstring holds them: #( 100 0 #rmoveto 50 #hlineto #endchar ). A byte array among them
	 is written as it stands, which is how the bytes of a hint mask are given."

	^ ByteArray streamContents: [ :stream |
		  aCollection do: [ :each |
			  each isSymbol
				  ifTrue: [ self putCharstringOperator: each on: stream ]
				  ifFalse: [ each isNumber
						  ifTrue: [ self putCharstringNumber: each on: stream ]
						  ifFalse: [ stream nextPutAll: each ] ] ] ]
]

{ #category : 'building' }
TTCffBytesFixture class >> dictBytesWithEntries: aCollectionOfAssociations [
	"The bytes of a CFF dictionary: for each entry, its operands and then its operator. The key
	 of an association is the operator, its value the operands. An operand given as a string is
	 written as a real number spelled that way, an integer as an integer."

	^ ByteArray streamContents: [ :stream |
		  aCollectionOfAssociations do: [ :each |
			  each value do: [ :operand |
				  operand isString
					  ifTrue: [ self putDictReal: operand on: stream ]
					  ifFalse: [ self putDictInteger: operand on: stream ] ].
			  self putDictOperator: each key on: stream ] ]
]

{ #category : 'building' }
TTCffBytesFixture class >> indexBytesWithElements: aCollectionOfByteArrays [
	"An INDEX whose offsets are as narrow as its data allows, which is what a real font writes."

	| lastOffset |
	lastOffset := 1 + (aCollectionOfByteArrays inject: 0 into: [ :sum :each | sum + each size ]).
	^ self
		  indexBytesWithElements: aCollectionOfByteArrays
		  offSize: (lastOffset log: 256) floor + 1
]

{ #category : 'building' }
TTCffBytesFixture class >> indexBytesWithElements: aCollectionOfByteArrays offSize: aByteCount [
	"The bytes of one CFF INDEX: the element count, the offSize, one offset per element plus a
	 last one past the data, then the data itself. Offsets count from 1 at the first element."

	^ ByteArray streamContents: [ :stream |
		  | offset |
		  self putCard16: aCollectionOfByteArrays size on: stream.
		  aCollectionOfByteArrays ifEmpty: [ ^ stream contents ].
		  stream nextPut: aByteCount.
		  offset := 1.
		  aCollectionOfByteArrays do: [ :each |
			  self putOffset: offset size: aByteCount on: stream.
			  offset := offset + each size ].
		  self putOffset: offset size: aByteCount on: stream.
		  aCollectionOfByteArrays do: [ :each | stream nextPutAll: each ] ]
]

{ #category : 'building' }
TTCffBytesFixture class >> nibbleFor: aCharacter in: aStream [
	"The nibble that spells one character of a real operand: a digit, 10 for the point, 14 for
	 a minus sign, and 11 or 12 for an exponent, which eats the minus sign that follows it."

	aCharacter isDigit ifTrue: [ ^ aCharacter digitValue ].
	aCharacter = $. ifTrue: [ ^ 10 ].
	aCharacter = $- ifTrue: [ ^ 14 ].
	aCharacter = $e ifTrue: [
		aStream peek = $- ifFalse: [ ^ 11 ].
		aStream next.
		^ 12 ].
	^ self error: aCharacter printString , ' spells no part of a real number'
]

{ #category : 'building' }
TTCffBytesFixture class >> nibblesOf: aString [
	"The nibbles that spell a real operand, ended by 15 and padded to a whole number of bytes."

	| nibbles |
	nibbles := OrderedCollection new.
	aString readStreamDo: [ :stream |
		[ stream atEnd ] whileFalse: [
			nibbles add: (self nibbleFor: stream next in: stream) ] ].
	nibbles add: 15.
	nibbles size odd ifTrue: [ nibbles add: 15 ].
	^ nibbles
]

{ #category : 'building' }
TTCffBytesFixture class >> privateDictBytesWithEntries: aCollectionOfAssociations localSubrs: aBoolean [
	"A private dictionary. The offset of the local subroutines is counted from the start of the
	 dictionary itself, and the subroutines follow it, so the offset is the dictionary's own
	 size: writing it changes that size, and the two are settled by writing it again."

	| bytes size |
	size := 0.
	bytes := nil.
	3 timesRepeat: [
		bytes := self dictBytesWithEntries: (aCollectionOfAssociations ,
				         (aBoolean
					          ifTrue: [ { (19 -> { size }) } ]
					          ifFalse: [ #(  ) ])).
		size := bytes size ].
	^ bytes
]

{ #category : 'building' }
TTCffBytesFixture class >> putCard16: anInteger on: aStream [
	aStream
		nextPut: (anInteger bitShift: -8) \\ 256;
		nextPut: anInteger \\ 256
]

{ #category : 'building' }
TTCffBytesFixture class >> putCharstringNumber: aNumber on: aStream [
	"An operand of a Type 2 charstring. The integer encodings are the dictionary's own, bar the
	 32-bit one, which a charstring spells as a 16.16 fixed-point number behind the byte 255."

	aNumber isInteger ifFalse: [ | fixed |
		fixed := (aNumber * 65536) rounded \\ 4294967296.
		aStream nextPut: 255.
		self putCard16: fixed // 65536 on: aStream.
		^ self putCard16: fixed \\ 65536 on: aStream ].
	(aNumber between: -1131 and: 1131) ifTrue: [
		^ self putDictInteger: aNumber on: aStream ].
	aStream nextPut: 28.
	self putCard16: aNumber \\ 65536 on: aStream
]

{ #category : 'building' }
TTCffBytesFixture class >> putCharstringOperator: aSymbol on: aStream [
	"An operator, named as the specification names it. The escaped ones are keyed as 1200 plus
	 the second byte, which is how the interpreter keys them."

	self putDictOperator: (TTCffCharstringInterpreter codeOfOperatorNamed: aSymbol) on: aStream
]

{ #category : 'building' }
TTCffBytesFixture class >> putDictInteger: anInteger on: aStream [
	"An operand of a CFF dictionary, in the narrowest of the four encodings that can say it:
	 one byte from -107 to 107, two bytes to 1131 either way, then the 16-bit and 32-bit forms."

	(anInteger between: -107 and: 107) ifTrue: [ ^ aStream nextPut: anInteger + 139 ].
	(anInteger between: 108 and: 1131) ifTrue: [ | value |
		value := anInteger - 108.
		^ aStream
			  nextPut: (value bitShift: -8) + 247;
			  nextPut: value \\ 256 ].
	(anInteger between: -1131 and: -108) ifTrue: [ | value |
		value := anInteger negated - 108.
		^ aStream
			  nextPut: (value bitShift: -8) + 251;
			  nextPut: value \\ 256 ].
	(anInteger between: -32768 and: 32767) ifTrue: [
		aStream nextPut: 28.
		^ self putCard16: anInteger \\ 65536 on: aStream ].
	aStream nextPut: 29.
	self putCard16: (anInteger \\ 4294967296) // 65536 on: aStream.
	self putCard16: anInteger \\ 65536 on: aStream
]

{ #category : 'building' }
TTCffBytesFixture class >> putDictOperator: anInteger on: aStream [
	"An operator, one byte from 0 to 21, or the escape byte 12 and a second byte. The escaped
	 operators are written here as 1200 plus the second byte, which is how a dictionary keys them."

	anInteger < 1200
		ifTrue: [ aStream nextPut: anInteger ]
		ifFalse: [ aStream
				nextPut: 12;
				nextPut: anInteger - 1200 ]
]

{ #category : 'building' }
TTCffBytesFixture class >> putDictReal: aString on: aStream [
	"A real operand, spelled as a font spells it: the characters of the number, one nibble each.
	 The spelling is the test's, because a font chooses its own."

	aStream nextPut: 30.
	(self nibblesOf: aString) pairsDo: [ :high :low |
		aStream nextPut: (high bitShift: 4) + low ]
]

{ #category : 'building' }
TTCffBytesFixture class >> putOffset: anInteger size: aByteCount on: aStream [
	"An INDEX offset, big-endian, in as many bytes as the INDEX's own offSize says."

	aByteCount to: 1 by: -1 do: [ :each |
		aStream nextPut: (anInteger bitShift: 8 - (each * 8)) \\ 256 ]
]

{ #category : 'building' }
TTCffBytesFixture >> charsetBytes [
	"The charset, in the format asked for. A run of format 1 holds the identifier it starts at
	 and how many follow it, so a list of consecutive identifiers is one run."

	^ ByteArray streamContents: [ :stream |
		  stream nextPut: charsetFormat.
		  charsetFormat = 0
			  ifTrue: [ charsetIdentifiers do: [ :each |
					   self class putCard16: each on: stream ] ]
			  ifFalse: [
				  self class putCard16: charsetIdentifiers first on: stream.
				  stream nextPut: charsetIdentifiers size - 1 ] ]
]

{ #category : 'building' }
TTCffBytesFixture >> charsetFormat: anInteger [
	"How the charset lists its identifiers: 0 one by one, 1 as runs of consecutive ones."

	charsetFormat := anInteger
]

{ #category : 'building' }
TTCffBytesFixture >> charsetIdentifiers: aCollection [
	"The string identifier of every glyph but the first, which is .notdef and named by none."

	charsetIdentifiers := aCollection
]

{ #category : 'building' }
TTCffBytesFixture >> charstrings: aCollectionOfByteArrays [
	charstrings := aCollectionOfByteArrays
]

{ #category : 'building' }
TTCffBytesFixture >> globalSubrs: aCollectionOfByteArrays [
	globalSubrs := aCollectionOfByteArrays
]

{ #category : 'building' }
TTCffBytesFixture >> headerBytes [
	^ ByteArray streamContents: [ :stream |
		  stream
			  nextPut: 1;
			  nextPut: 0;
			  nextPut: headerSize;
			  nextPut: 2.
		  headerSize - 4 timesRepeat: [ stream nextPut: 0 ] ]
]

{ #category : 'building' }
TTCffBytesFixture >> headerSize: anInteger [
	"What the header claims its own size is. A font may leave room after the four bytes it needs."

	headerSize := anInteger
]

{ #category : 'initialization' }
TTCffBytesFixture >> initialize [
	"The smallest table there is: one charstring that draws nothing, no extra entry in either
	 dictionary, no subroutine, no charset of its own, and a header of the four bytes it needs."

	super initialize.
	charstrings := { #[ 14 ] asByteArray }.
	topEntries := #(  ).
	privateEntries := #(  ).
	localSubrs := #(  ).
	globalSubrs := #(  ).
	charsetIdentifiers := nil.
	charsetFormat := 0.
	headerSize := 4
]

{ #category : 'building' }
TTCffBytesFixture >> localSubrs: aCollectionOfByteArrays [
	localSubrs := aCollectionOfByteArrays
]

{ #category : 'building' }
TTCffBytesFixture >> privateEntries: aCollectionOfAssociations [
	privateEntries := aCollectionOfAssociations
]

{ #category : 'building' }
TTCffBytesFixture >> tableBytes [
	"The bytes of a whole CFF table, laid out the way a font writes one: the header, the four
	 INDEXes, then the charstrings, the charset, the private dictionary and the local
	 subroutines. The offsets the top dictionary carries point at what follows it, and
	 writing them changes its size, so they are settled by writing it again."

	| header nameIndex stringIndex globalIndex charstringsIndex localIndex private charset top prefixSize charstringsOffset charsetOffset privateOffset |
	header := self headerBytes.
	nameIndex := self class indexBytesWithElements: { 'Fixture' asByteArray }.
	stringIndex := self class indexBytesWithElements: #(  ).
	globalIndex := self class indexBytesWithElements: globalSubrs.
	charstringsIndex := self class indexBytesWithElements: charstrings.
	localIndex := self class indexBytesWithElements: localSubrs.
	charset := charsetIdentifiers
		           ifNil: [ #[  ] asByteArray ]
		           ifNotNil: [ self charsetBytes ].
	private := self class
		           privateDictBytesWithEntries: privateEntries
		           localSubrs: localSubrs notEmpty.
	charstringsOffset := 0.
	charsetOffset := 0.
	privateOffset := 0.
	top := nil.
	3 timesRepeat: [
		top := self class dictBytesWithEntries: (topEntries
				        , (charsetIdentifiers
						         ifNil: [ #(  ) ]
						         ifNotNil: [ { (15 -> { charsetOffset }) } ]) , {
				        (17 -> { charstringsOffset }).
				        (18 -> {
					         private size.
					         privateOffset }) }).
		prefixSize := header size + nameIndex size
		              + (self class indexBytesWithElements: { top }) size + stringIndex size
		              + globalIndex size.
		charstringsOffset := prefixSize.
		charsetOffset := prefixSize + charstringsIndex size.
		privateOffset := charsetOffset + charset size ].
	^ header , nameIndex , (self class indexBytesWithElements: { top }) , stringIndex
	  , globalIndex , charstringsIndex , charset , private , localIndex
]

{ #category : 'building' }
TTCffBytesFixture >> tableCursor [
	"A cursor over the table I build, as a font reader hands one to a parser."

	^ TTFontTableDirEntry onBytes: self tableBytes
]

{ #category : 'building' }
TTCffBytesFixture >> topEntries: aCollectionOfAssociations [
	"Entries of the top dictionary beyond the two it must carry, CharStrings and Private."

	topEntries := aCollectionOfAssociations
]
