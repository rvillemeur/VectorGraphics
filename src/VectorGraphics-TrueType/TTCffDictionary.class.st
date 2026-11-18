"
I am one CFF dictionary, read from the bytes that hold it.

A CFF table says everything about a font that is not a glyph in a dictionary: the top dictionary says where the charstrings and the charset are and what the font matrix is, the private dictionary says the default widths and where the local subroutines are. Entries are written as operands first and the operator last, which is the opposite of what a reader expects, so the operands are collected until an operator ends the entry.

An operator is one byte from 0 to 21, or the escape byte 12 and a byte after it. I key an escaped operator as 1200 plus that second byte, so that one integer names any operator.

Operands are integers in four widths and real numbers written in nibbles. I answer them as they were written: an operand that says 0.001 answers a Fraction or a Float, never the bytes.
"
Class {
	#name : 'TTCffDictionary',
	#superclass : 'Object',
	#instVars : [
		'entries'
	],
	#category : 'VectorGraphics-TrueType-CFF',
	#package : 'VectorGraphics-TrueType',
	#tag : 'CFF'
}

{ #category : 'operators' }
TTCffDictionary class >> nameOfOperator: anOperator [
	"What the specification calls that operator, or how it is written when it has no name here."

	^ self operatorNames
		  at: anOperator
		  ifAbsent: [ anOperator < 1200
				  ifTrue: [ 'operator ' , anOperator printString ]
				  ifFalse: [ 'operator 12 ' , (anOperator - 1200) printString ] ]
]

{ #category : 'operators' }
TTCffDictionary class >> operatorNames [
	"The names the CFF specification gives the operators this reader reads, keyed the way I key
	 an operator: the byte itself, or 1200 plus the second byte of an escaped one. An operator
	 absent here is still read and kept; only its name is unknown."

	^ Dictionary newFrom: {
			  (0 -> 'version'). (1 -> 'Notice'). (2 -> 'FullName'). (3 -> 'FamilyName').
			  (4 -> 'Weight'). (5 -> 'FontBBox'). (6 -> 'BlueValues'). (7 -> 'OtherBlues').
			  (10 -> 'StdHW'). (11 -> 'StdVW'). (13 -> 'UniqueID'). (14 -> 'XUID').
			  (15 -> 'charset'). (16 -> 'Encoding'). (17 -> 'CharStrings'). (18 -> 'Private').
			  (19 -> 'Subrs'). (20 -> 'defaultWidthX'). (21 -> 'nominalWidthX').
			  (1200 -> 'Copyright'). (1207 -> 'FontMatrix'). (1230 -> 'ROS').
			  (1234 -> 'CIDCount'). (1236 -> 'FDArray'). (1237 -> 'FDSelect') }
]

{ #category : 'instance creation' }
TTCffDictionary class >> readFrom: aByteArray [
	"Read the dictionary those bytes hold."

	^ self new readFrom: aByteArray
]

{ #category : 'accessing' }
TTCffDictionary >> at: anOperator [
	"The operands of one entry. A dictionary is asked for what it was read for, so an operator
	 it does not hold is a defect of the font, not a shape to carry on with."

	^ entries at: anOperator ifAbsent: [
		  TTCffError signal:
			  'the dictionary holds no operator ' , anOperator printString ]
]

{ #category : 'accessing' }
TTCffDictionary >> at: anOperator ifAbsent: aBlock [
	^ entries at: anOperator ifAbsent: aBlock
]

{ #category : 'accessing' }
TTCffDictionary >> includesOperator: anOperator [
	^ entries includesKey: anOperator
]

{ #category : 'inspector' }
TTCffDictionary >> inspectorEntries: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Entries'>
	"One row per entry, named as the specification names it. The operands are shown as they
	were read, so a real number shows as a number and not as the nibbles that spelled it."

	^ aBuilder newTable
		  addColumn: ((SpStringTableColumn title: 'Operator' evaluated: [ :each | self class nameOfOperator: each ]) width: 160);
		  addColumn: ((SpStringTableColumn title: 'Key' evaluated: [ :each | each printString ]) width: 80);
		  addColumn: (SpStringTableColumn title: 'Operands' evaluated: [ :each | (self at: each) printString ]);
		  items: entries keys asSortedCollection asArray;
		  yourself
]

{ #category : 'reading' }
TTCffDictionary >> numberFrom: aString [
	"The characters the nibbles spelled, read as one number. CFF spells only the nibbles it
	 needs, so .001 carries no zero in front of its point and -.5 none after its sign, while
	 Pharo's number reader wants a digit there and raises without one."

	| spelling |
	spelling := (aString beginsWith: '.')
		            ifTrue: [ '0' , aString ]
		            ifFalse: [
			            (aString beginsWith: '-.')
				            ifTrue: [ '-0' , (aString allButFirst: 1) ]
				            ifFalse: [ aString ] ].
	^ spelling asNumber
]

{ #category : 'reading' }
TTCffDictionary >> operandFrom: aStream firstByte: aByte [
	"One operand. The first byte says both which encoding it is and, for the two short ones,
	 part of the number itself. The bytes 22 to 27, 31 and 255 say no operand at all."

	aByte = 28 ifTrue: [ ^ self signed: (aStream next bitShift: 8) + aStream next bits: 16 ].
	aByte = 29 ifTrue: [ | value |
		value := 0.
		4 timesRepeat: [ value := (value bitShift: 8) + aStream next ].
		^ self signed: value bits: 32 ].
	aByte = 30 ifTrue: [ ^ self realFrom: aStream ].
	(aByte between: 32 and: 246) ifTrue: [ ^ aByte - 139 ].
	(aByte between: 247 and: 250) ifTrue: [ ^ (aByte - 247 * 256) + aStream next + 108 ].
	(aByte between: 251 and: 254) ifTrue: [ ^ (aByte - 251 * 256) negated - aStream next - 108 ].
	^ TTCffError signal: 'byte ' , aByte printString , ' says no operand a dictionary can hold'
]

{ #category : 'reading' }
TTCffDictionary >> operatorFrom: aStream firstByte: aByte [
	"An operator, keyed as the byte itself, or as 1200 plus the second byte when the first is
	 the escape 12."

	^ aByte = 12
		  ifTrue: [ 1200 + aStream next ]
		  ifFalse: [ aByte ]
]

{ #category : 'reading' }
TTCffDictionary >> readFrom: aByteArray [
	| stream operands |
	entries := Dictionary new.
	stream := ReadStream on: aByteArray.
	operands := OrderedCollection new.
	[ stream atEnd ] whileFalse: [ | byte |
		byte := stream next.
		byte <= 21
			ifTrue: [
				entries at: (self operatorFrom: stream firstByte: byte) put: operands asArray.
				operands := OrderedCollection new ]
			ifFalse: [ operands add: (self operandFrom: stream firstByte: byte) ] ]
]

{ #category : 'reading' }
TTCffDictionary >> realFrom: aStream [
	"A real number, written one nibble at a time: digits, then a point, an exponent, a minus
	 sign or the marker that ends it. The nibbles spell the number, so they are spelled back
	 out and read as one."

	| digits |
	digits := WriteStream on: String new.
	[ aStream atEnd ] whileFalse: [
		| byte |
		byte := aStream next.
		((self spellNibble: (byte bitShift: -4) on: digits) and: [
			 self spellNibble: (byte bitAnd: 15) on: digits ]) ifFalse: [
			^ self numberFrom: digits contents ] ].
	^ self numberFrom: digits contents
]

{ #category : 'reading' }
TTCffDictionary >> signed: anInteger bits: aBitCount [
	"The number those bits say, read as two's complement."

	^ anInteger >= (1 bitShift: aBitCount - 1)
		  ifTrue: [ anInteger - (1 bitShift: aBitCount) ]
		  ifFalse: [ anInteger ]
]

{ #category : 'accessing' }
TTCffDictionary >> size [
	^ entries size
]

{ #category : 'reading' }
TTCffDictionary >> spellNibble: aNibble on: aStream [
	"Spell one nibble into the characters it stands for, and answer whether the number goes on."

	aNibble <= 9 ifTrue: [
		aStream nextPut: (Character digitValue: aNibble).
		^ true ].
	aNibble = 10 ifTrue: [
		aStream nextPut: $..
		^ true ].
	aNibble = 11 ifTrue: [
		aStream nextPut: $e.
		^ true ].
	aNibble = 12 ifTrue: [
		aStream nextPutAll: 'e-'.
		^ true ].
	aNibble = 14 ifTrue: [
		aStream nextPut: $-.
		^ true ].
	aNibble = 15 ifTrue: [ ^ false ].
	^ TTCffError signal: 'a real number holds the nibble ' , aNibble printString , ', which says nothing'
]
