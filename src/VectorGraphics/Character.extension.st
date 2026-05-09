Extension { #name : 'Character' }

{ #category : '*VectorGraphics' }
Character class >> evaluate: aBlock withUtf8BytesOf: aCodePoint [
	"See senders for typical usage"

	| mask nBytes shift |
	aCodePoint < 128 ifTrue: [
		^aBlock value: aCodePoint ].
	nBytes := aCodePoint highBit + 3 // 5.
	mask := #(128 192 224 240 248 252 254 255) at: nBytes.
	shift := nBytes - 1 * -6.
	aBlock value: (aCodePoint bitShift: shift) + mask.
	2 to: nBytes do: [ :i | 
		shift := shift + 6.
		aBlock value: ((aCodePoint bitShift: shift) bitAnd: 63) + 128 ]
]

{ #category : '*VectorGraphics' }
Character class >> utf8BytesOf: aCodePoint [

	^ ByteArray streamContents: [ :strm |
		Character
			evaluate: [ :byte |
				strm nextPut: byte ]
			withUtf8BytesOf: aCodePoint ]
]
