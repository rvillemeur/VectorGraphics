Extension { #name : 'ByteArray' }

{ #category : '*VectorGraphics' }
ByteArray >> bitAt: bitIndex [
	"Answer the bit (0 or 1) at a bit index.
	This way, the receiver behaves as a BitArray.
	Note: There is no error raised if you access the possible extra bits at the end if size is not multiple of 8."
	| bitPosition index |
	index := bitIndex - 1 // 8 + 1.
	bitPosition := bitIndex - 1 \\ 8 + 1.
	^ self bitAt: index bitPosition: bitPosition
]

{ #category : '*VectorGraphics' }
ByteArray >> bitAt: index bitPosition: bitPosition [
	"Answer the bit (0 or 1) at byte at index, at bitPosition.
	The bits are indexed starting at 1 for the least significant bit"
	^(self at: index) bitAt: bitPosition
]

{ #category : '*VectorGraphics' }
ByteArray >> bitAt: index bitPosition: bitPosition put: aBit [
	"Set the bit (0 or 1) at byte at index, at bitPosition. 
	The bit value should be 0 or 1, otherwise raise an Error.
	The bits are indexed starting at 1 for the least significant bit"
	self at: index put: ((self at: index) bitAt: bitPosition put: aBit)
]

{ #category : '*VectorGraphics' }
ByteArray >> bitAt: bitIndex put: aBit [
	"Set the bit (0 or 1) at a bit index. This way, the receiver behaves as a BitArray
	Note: There is no error raised if you access the possible extra bits at the end if size is not multiple of 8.
	#[1 0 0 ] bitAt: 1
	#[0 1  0 ] bitAt: 9
	#[0 0 128 ] bitAt: 24
	"
	| bitPosition index |
	index := bitIndex - 1 // 8 + 1.
	bitPosition := bitIndex - 1 \\ 8 + 1.
	self bitAt: index bitPosition: bitPosition put: aBit
]

{ #category : '*VectorGraphics' }
ByteArray >> bitBooleanAt: bitIndex [
	"Consider the bit at bitIndex as a Boolean value.
	0 -> false
	1 -> true"
	^ (self bitAt: bitIndex) = 1
]

{ #category : '*VectorGraphics' }
ByteArray class >> newBits: bitCount [
	"
	(ByteArray newBits: 8) bitAt: 8 put: 1; bitAt: 8
	(ByteArray newBits: 9) bitAt: 9 put: 1; bitAt: 9
	"
	^self new: bitCount + 7 // 8
]
