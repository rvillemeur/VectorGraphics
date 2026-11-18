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
TTCffBytesFixture class >> putOffset: anInteger size: aByteCount on: aStream [
	"An INDEX offset, big-endian, in as many bytes as the INDEX's own offSize says."

	aByteCount to: 1 by: -1 do: [ :each |
		aStream nextPut: (anInteger bitShift: 8 - (each * 8)) \\ 256 ]
]
