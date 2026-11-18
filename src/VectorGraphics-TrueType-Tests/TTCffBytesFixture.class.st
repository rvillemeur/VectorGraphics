"
I build the bytes of CFF structures, on my class side, for the tests that read a CFF table without a font file on disk.

What I build is the smallest run of bytes that still answers the question being asked: an INDEX of given elements, a DICT of given operands and operators, a charstring of given operators. I hold no state and nobody instantiates me.

I exist beside TTFontFixtures, which builds whole sfnt fonts: the structures inside a CFF table are a subject of their own, and the tests of the CFF reader ask about them one at a time.
"
Class {
	#name : 'TTCffBytesFixture',
	#superclass : 'Object',
	#category : 'VectorGraphics-TrueType-Tests-Fixtures',
	#package : 'VectorGraphics-TrueType-Tests',
	#tag : 'Fixtures'
}

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
TTCffBytesFixture class >> putCard16: anInteger on: aStream [
	aStream
		nextPut: (anInteger bitShift: -8) \\ 256;
		nextPut: anInteger \\ 256
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
	"A real operand, spelled as a font spells it: the characters of the number, one nibble each,
	 then the end marker. The spelling is the test's, because a font chooses its own."

	| nibbles |
	nibbles := OrderedCollection new.
	aString readStreamDo: [ :stream |
		[ stream atEnd ] whileFalse: [ | character |
			character := stream next.
			character isDigit ifTrue: [ nibbles add: character digitValue ].
			character = $. ifTrue: [ nibbles add: 10 ].
			character = $- ifTrue: [ nibbles add: 14 ].
			character = $e ifTrue: [
				stream peek = $-
					ifTrue: [
						stream next.
						nibbles add: 12 ]
					ifFalse: [ nibbles add: 11 ] ] ] ].
	nibbles add: 15.
	nibbles size odd ifTrue: [ nibbles add: 15 ].
	aStream nextPut: 30.
	nibbles pairsDo: [ :high :low | aStream nextPut: (high bitShift: 4) + low ]
]

{ #category : 'building' }
TTCffBytesFixture class >> putOffset: anInteger size: aByteCount on: aStream [
	"An INDEX offset, big-endian, in as many bytes as the INDEX's own offSize says."

	aByteCount to: 1 by: -1 do: [ :each |
		aStream nextPut: (anInteger bitShift: 8 - (each * 8)) \\ 256 ]
]
