"
I hold `TTFontTableDirEntry`, the cursor every table reader of the parser works through: a byte array plus an offset that advances as values are read.

The facts are the primitive reads and what each does to the offset. A byte, an unsigned short and a signed short are read big-endian, as the format stores them, and a signed short must come back negative when the high bit is set — a glyph coordinate read unsigned is a glyph drawn off the page. `skip` moves the offset without reading, the offset can be set and asked for, and a string is read at a given position in its single-byte encoding.

Each test builds the bytes it needs here, so a failure names the one read that is wrong rather than the table that happened to use it.
"
Class {
	#name : 'TTFontTableDirEntryTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-TrueType-Tests-Tests',
	#package : 'VectorGraphics-TrueType-Tests',
	#tag : 'Tests'
}

{ #category : 'helpers' }
TTFontTableDirEntryTest >> putShort: value at: pos in: bytes [

	| v |
	v := value < 0
		     ifTrue: [ value + 65536 ]
		     ifFalse: [ value ].
	bytes at: pos put: ((v bitShift: -8) bitAnd: 255).
	bytes at: pos + 1 put: (v bitAnd: 255)
]

{ #category : 'helpers' }
TTFontTableDirEntryTest >> putUShort: value at: pos in: bytes [

	bytes at: pos put: ((value bitShift: -8) bitAnd: 255).
	bytes at: pos + 1 put: (value bitAnd: 255)
]

{ #category : 'tests' }
TTFontTableDirEntryTest >> testNextByteAdvancesOffset [

	| bytes entry |
	bytes := ByteArray with: 10 with: 20 with: 30.
	entry := TTFontTableDirEntry onBytes: bytes.
	entry nextByte.
	self assert: entry nextByte equals: 20
]

{ #category : 'tests' }
TTFontTableDirEntryTest >> testNextByteReadsFirstByte [

	| bytes entry |
	bytes := ByteArray with: 42 with: 0 with: 0.
	entry := TTFontTableDirEntry onBytes: bytes.
	self assert: entry nextByte equals: 42
]

{ #category : 'tests' }
TTFontTableDirEntryTest >> testNextShortNegative [

	| bytes entry |
	bytes := ByteArray new: 2.
	self putShort: -300 at: 1 in: bytes.
	entry := TTFontTableDirEntry onBytes: bytes.
	self assert: entry nextShort equals: -300
]

{ #category : 'tests' }
TTFontTableDirEntryTest >> testNextShortPositive [

	| bytes entry |
	bytes := ByteArray new: 2.
	self putShort: 500 at: 1 in: bytes.
	entry := TTFontTableDirEntry onBytes: bytes.
	self assert: entry nextShort equals: 500
]

{ #category : 'tests' }
TTFontTableDirEntryTest >> testNextSignedByteReadsTheTopHalfOfTheRangeAsNegative [
	"A byte over 127 states a negative number, and the entry advances one byte either way."

	| entry |
	entry := TTFontTableDirEntry onBytes: #[ 127 128 255 1 ].
	self assert: entry nextSignedByte equals: 127.
	self assert: entry nextSignedByte equals: -128.
	self assert: entry nextSignedByte equals: -1.
	self assert: entry nextSignedByte equals: 1
]

{ #category : 'tests' }
TTFontTableDirEntryTest >> testNextTwoDotFourteenReadsASignedFractionOfFourteenBits [
	"An F2Dot14 is the signed short it holds over 16384, so one unit of the form is 1 and
	 the number reaches the whole of [-2, 2)."

	| entry |
	entry := TTFontTableDirEntry onBytes: (ByteArray streamContents: [ :stream |
			          VGFontBytesFixture putF2Dot14: 1.5 on: stream.
			          VGFontBytesFixture putF2Dot14: -2 on: stream.
			          stream nextPutAll: #[ 0 1 ] ]).
	self assert: entry nextTwoDotFourteen equals: 3 / 2.
	self assert: entry nextTwoDotFourteen equals: -2.
	self assert: entry nextTwoDotFourteen equals: 1 / 16384
]

{ #category : 'tests' }
TTFontTableDirEntryTest >> testNextUShort [

	| bytes entry |
	bytes := ByteArray new: 2.
	self putUShort: 1000 at: 1 in: bytes.
	entry := TTFontTableDirEntry onBytes: bytes.
	self assert: entry nextUShort equals: 1000
]

{ #category : 'tests' }
TTFontTableDirEntryTest >> testOffsetSetAndGet [

	| bytes entry |
	bytes := ByteArray new: 5.
	bytes at: 3 put: 77.
	entry := TTFontTableDirEntry onBytes: bytes.
	entry offset: 3.
	self assert: entry nextByte equals: 77
]

{ #category : 'tests' }
TTFontTableDirEntryTest >> testSkipAdvancesOffset [

	| bytes entry |
	bytes := ByteArray with: 0 with: 0 with: 99.
	entry := TTFontTableDirEntry onBytes: bytes.
	entry skip: 2.
	self assert: entry nextByte equals: 99
]

{ #category : 'tests' }
TTFontTableDirEntryTest >> testStringAtSingleByteEncoding [

	| bytes entry |
	bytes := ByteArray with: 65 with: 66 with: 67.
	entry := TTFontTableDirEntry onBytes: bytes.
	self
		assert: (entry stringAt: 1 length: 3 multiByte: false)
		equals: 'ABC'
]
