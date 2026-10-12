Extension { #name : 'Bitmap' }

{ #category : '*VectorGraphics' }
Bitmap >> byteAt: byteAddress [
	"Extract a byte from a Bitmap.  Note that this is a byte address and it is one-order.  For repeated use, create an instance of BitBlt and use pixelAt:.  See Form>>#pixelAt:"
	| lowBits |
	lowBits := byteAddress - 1 bitAnd: 3.
	^ ((self at: (byteAddress - 1 - lowBits) // 4 + 1) bitShift: (lowBits - 3) * 8) bitAnd: 255
]

{ #category : '*VectorGraphics' }
Bitmap >> byteAt: byteAddress put: byte [
	"Insert a byte into a Bitmap.  Note that this is a byte address and it is one-order.  For repeated use, create an instance of BitBlt and use pixelAt:put:.  See Form>>#pixelAt:put:"
	| longWord shift lowBits longAddr |
	(byte < 0 or: [ byte > 255 ]) ifTrue: [ ^ self errorImproperStore ].
	lowBits := byteAddress - 1 bitAnd: 3.
	longWord := self at: (longAddr := (byteAddress - 1 - lowBits) // 4 + 1).
	shift := (3 - lowBits) * 8.
	longWord := longWord - (longWord bitAnd: (255 bitShift: shift)) + (byte bitShift: shift).
	self
		at: longAddr
		put: longWord.
	^ byte
]

{ #category : '*VectorGraphics' }
Bitmap >> bytesAt: index [
	"Answer a ByteArray of 4 elements.
	The 32-bit word is split in 4 bytes, in little endian format
	((WordArray with: 16rFF32791B) bytesAt: 1) hex
	"

	| bytes word |
	bytes := ByteArray new: 4.
	word := self at: index. "Usually a SmallInteger, but may be a Large Integer in 32-bit images"
	1 to: 4 do: [ :i | bytes at: i put: (word digitAt: i) ].
	^ bytes
]

{ #category : '*VectorGraphics' }
Bitmap >> bytesAt: index put: aByteArray [
	"Takes a ByteArray of 4 elements.
	Store the 32-bit word made with those byes, in little endian format
	((WordArray new: 1) bytesAt: 1 put: #[16r1B 16r79 16r32 16rFF]) first hex
	"

	| word |
	word := 0.
	4 to: 1 by: -1 do: [ :i | word := word * 256 + (aByteArray at: i) ].
	self at: index put: word
]
