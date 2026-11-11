"
I wrap a binary read stream and count the bytes a reader actually pulls through me.

A metadata reader exists to read a few kilobytes of a font file rather than the whole of it: on this machine the 362 TrueType files hold 262 MB, which takes 4.6 s to read off disk, while parsing their name tables takes 14 ms in total. A test that only checks the names cannot tell the two apart, so it reads them through me and asserts what the reader pulled.
"
Class {
	#name : 'TTCountingReadStream',
	#superclass : 'Object',
	#instVars : [
		'stream',
		'bytesPulled'
	],
	#category : 'VectorGraphics-TrueType-Tests-Fixtures',
	#package : 'VectorGraphics-TrueType-Tests',
	#tag : 'Fixtures'
}

{ #category : 'instance creation' }
TTCountingReadStream class >> on: aStream [
	^ self new on: aStream; yourself
]

{ #category : 'testing' }
TTCountingReadStream >> atEnd [
	^ stream atEnd
]

{ #category : 'accessing' }
TTCountingReadStream >> bytesPulled [
	"How many bytes of the file the reader asked me for."

	^ bytesPulled
]

{ #category : 'reading' }
TTCountingReadStream >> next: anInteger [
	| answer |
	answer := stream next: anInteger.
	bytesPulled := bytesPulled + answer size.
	^ answer
]

{ #category : 'initialization' }
TTCountingReadStream >> on: aStream [
	stream := aStream.
	bytesPulled := 0
]

{ #category : 'positioning' }
TTCountingReadStream >> position [
	^ stream position
]

{ #category : 'positioning' }
TTCountingReadStream >> position: anInteger [
	stream position: anInteger
]

{ #category : 'accessing' }
TTCountingReadStream >> size [
	"The size of the file, which a reader may ask without reading a byte of it."

	^ stream size
]

{ #category : 'positioning' }
TTCountingReadStream >> skip: anInteger [
	stream skip: anInteger
]
