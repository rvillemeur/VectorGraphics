"
This class represents an entry in a truetype font table directory. Used by TTFontReader only.
"
Class {
	#name : 'TTFontTableDirEntry',
	#superclass : 'Object',
	#instVars : [
		'tag',
		'fontData',
		'offset',
		'length',
		'checkSum'
	],
	#category : 'VectorGraphics-TrueType',
	#package : 'VectorGraphics',
	#tag : 'TrueType'
}

{ #category : 'instance creation' }
TTFontTableDirEntry class >> on: fontData at: index [

	^ self new on: fontData at: index
]

{ #category : 'instance creation' }
TTFontTableDirEntry class >> onBytes: aByteArray [

	"Create an entry wrapping a raw ByteArray starting at position 1. Used for testing."

	^ self new
		  instVarNamed: 'fontData' put: aByteArray;
		  instVarNamed: 'offset' put: 1;
		  yourself
]

{ #category : 'accessing' }
TTFontTableDirEntry >> nextByte [

	| value |
	value := fontData byteAt: offset.
	offset := offset + 1.
	^ value
]

{ #category : 'accessing' }
TTFontTableDirEntry >> nextBytes: numBytes into: array startingAt: byteOffset [

	1 to: numBytes do: [ :i | 
	array at: i put: (fontData byteAt: byteOffset + i - 1) ]
]

{ #category : 'accessing' }
TTFontTableDirEntry >> nextLong [

	| value |
	value := fontData longAt: offset bigEndian: true.
	offset := offset + 4.
	^ value
]

{ #category : 'accessing' }
TTFontTableDirEntry >> nextShort [

	| value |
	value := fontData shortAt: offset bigEndian: true.
	offset := offset + 2.
	^ value
]

{ #category : 'accessing' }
TTFontTableDirEntry >> nextULong [

	| value |
	value := fontData unsignedLongAt: offset bigEndian: true.
	offset := offset + 4.
	^ value
]

{ #category : 'accessing' }
TTFontTableDirEntry >> nextUShort [

	| value |
	value := fontData unsignedShortAt: offset bigEndian: true.
	offset := offset + 2.
	^ value
]

{ #category : 'accessing' }
TTFontTableDirEntry >> offset [

	^ offset
]

{ #category : 'accessing' }
TTFontTableDirEntry >> offset: newOffset [

	offset := newOffset
]

{ #category : 'initialize-release' }
TTFontTableDirEntry >> on: fd at: index [

	fontData := fd.
	tag := fontData longAt: index bigEndian: true.
	checkSum := fontData longAt: index + 4 bigEndian: true.
	offset := (fontData longAt: index + 8 bigEndian: true) + 1.
	length := fontData longAt: index + 12 bigEndian: true
]

{ #category : 'accessing' }
TTFontTableDirEntry >> skip: n [

	"Skip n bytes"

	offset := offset + n
]

{ #category : 'accessing' }
TTFontTableDirEntry >> stringAt: stringOffset length: byteLength multiByte: aBoolean [

	| string index stringLength |
	aBoolean
		ifFalse: [ 
			stringLength := byteLength.
			string := String new: stringLength.
			index := stringOffset.
			1 to: stringLength do: [ :i | 
				string
					at: i
					put: (Character codePoint: (fontData byteAt: index + i - 1)) ].
			^ string ]
		ifTrue: [ "UTF-16BE
		https://docs.microsoft.com/en-us/typography/opentype/spec/name#enc3
		This code appears to assume only lower byte is needed, most likely only ascii is supported here (jmv)"
			stringLength := byteLength // 2.
			string := String new: stringLength.
			index := stringOffset.
			1 to: stringLength do: [ :i | 
				string
					at: i
					put: (Character codePoint: (fontData byteAt: index + 1)).
				index := index + 2 ].
			^ string ]
]
