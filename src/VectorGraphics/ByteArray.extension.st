Extension { #name : 'ByteArray' }

{ #category : '*VectorGraphics' }
ByteArray class >> newBits: bitCount [
	"
	(ByteArray newBits: 8) bitAt: 8 put: 1; bitAt: 8
	(ByteArray newBits: 9) bitAt: 9 put: 1; bitAt: 9
	"
	^self new: bitCount + 7 // 8
]
