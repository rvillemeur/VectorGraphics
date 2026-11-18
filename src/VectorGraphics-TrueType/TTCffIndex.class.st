"
I am one CFF INDEX, read from a cursor into a font's bytes.

An INDEX is how CFF writes every list it holds: the font names, the top dictionaries, the strings, the subroutines and the charstrings. It is a count, the width of an offset, one offset per element and a last one past the end, then the elements' bytes end to end. An INDEX of no element is the count alone, two bytes, with no offset width and no offset.

I keep the cursor and the offsets, not the bytes: `at:` copies one element out when it is asked for, which is what the lazy reading of charstrings needs. Asking me for an element leaves the cursor where it was, so the parser that read me can go on reading what follows.

Offsets inside an INDEX count from 1 at the first element, so `dataStart` is the position just before the data, and element i runs from `dataStart + (offsets at: i)`.
"
Class {
	#name : 'TTCffIndex',
	#superclass : 'Object',
	#instVars : [
		'entry',
		'offsets',
		'dataStart'
	],
	#category : 'VectorGraphics-TrueType-CFF',
	#package : 'VectorGraphics-TrueType',
	#tag : 'CFF'
}

{ #category : 'instance creation' }
TTCffIndex class >> empty [
	"An INDEX of no element, for a font that leaves one out altogether rather than writing an
	 empty one: a private dictionary with no local subroutines, say."

	^ self new readFrom: (TTFontTableDirEntry onBytes: #[ 0 0 ] asByteArray)
]

{ #category : 'instance creation' }
TTCffIndex class >> readFrom: anEntry [
	"Read the INDEX the cursor is positioned at, and leave the cursor just past it."

	^ self new readFrom: anEntry
]

{ #category : 'accessing' }
TTCffIndex >> at: anIndex [
	"The bytes of one element, copied out. The cursor stays where it is."

	| start bytes |
	start := offsets at: anIndex.
	bytes := ByteArray new: (offsets at: anIndex + 1) - start.
	entry
		nextBytes: bytes size
		into: bytes
		startingAt: dataStart + start.
	^ bytes
]

{ #category : 'inspector' }
TTCffIndex >> inspectorElements: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Elements'>
	"One row per element: where it starts inside the INDEX, how many bytes it holds, and the
	first of those bytes. The offsets are asked of myself rather than restated, so a row says
	what at: would answer."

	^ aBuilder newTable
		  addColumn: ((SpStringTableColumn title: 'Element' evaluated: [ :each | each printString ]) width: 80);
		  addColumn: ((SpStringTableColumn title: 'Offset' evaluated: [ :each | (offsets at: each) printString ]) width: 80);
		  addColumn: ((SpStringTableColumn title: 'Bytes' evaluated: [ :each | (self at: each) size printString ]) width: 80);
		  addColumn: (SpStringTableColumn title: 'First bytes' evaluated: [ :each | ((self at: each) first: ((self at: each) size min: 16)) printString ]);
		  items: (1 to: self size);
		  yourself
]

{ #category : 'accessing' }
TTCffIndex >> isEmpty [
	^ self size = 0
]

{ #category : 'reading' }
TTCffIndex >> readFrom: anEntry [
	| count offSize |
	entry := anEntry.
	count := anEntry nextUShort.
	count = 0 ifTrue: [
		offsets := #( 1 ).
		dataStart := anEntry offset - 1.
		^ self ].
	offSize := anEntry nextByte.
	offsets := (1 to: count + 1) collect: [ :each |
		           self readOffsetOfSize: offSize ].
	dataStart := anEntry offset - 1.
	anEntry offset: dataStart + offsets last
]

{ #category : 'reading' }
TTCffIndex >> readOffsetOfSize: aByteCount [
	"One offset, big-endian, in the width this INDEX declared: one to four bytes."

	| value |
	value := 0.
	aByteCount timesRepeat: [ value := (value bitShift: 8) + entry nextByte ].
	^ value
]

{ #category : 'accessing' }
TTCffIndex >> size [
	^ offsets size - 1
]
