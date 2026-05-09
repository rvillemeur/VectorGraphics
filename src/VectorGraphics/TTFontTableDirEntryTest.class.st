Class {
	#name : 'TTFontTableDirEntryTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-tests',
	#package : 'VectorGraphics',
	#tag : 'tests'
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
