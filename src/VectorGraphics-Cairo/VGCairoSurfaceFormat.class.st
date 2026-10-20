"
I name a pixel format, with the same integer code Cairo uses, so that a caller holding Alexandrie's own AeCairoSurfaceFormat can be understood without this package naming that class: my class-side #normalize: accepts either, because both answer #asInteger. I answer the stride Cairo would compute for a width, which is the row span rounded up to a four-byte boundary, and the three formats this engine renders: argb32 is premultiplied ARGB in native byte order, rgb24 is the same thirty-two bits with the alpha byte unused, and a8 is the single-byte mask AeCanvas asks for when it builds a shadow.
"
Class {
	#name : 'VGCairoSurfaceFormat',
	#superclass : 'Object',
	#instVars : [
		'code',
		'bitsPerPixel',
		'formatName'
	],
	#category : 'VectorGraphics-Cairo-Surface',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Surface'
}

{ #category : 'instance creation' }
VGCairoSurfaceFormat class >> a8 [
	"One byte of alpha per pixel: the mask format AeCanvas asks for when it blurs a shadow."

	^ self code: 2 bitsPerPixel: 8 name: #a8
]

{ #category : 'instance creation' }
VGCairoSurfaceFormat class >> all [
	^ {
		  self argb32.
		  self rgb24.
		  self a8 }
]

{ #category : 'instance creation' }
VGCairoSurfaceFormat class >> argb32 [
	"Premultiplied ARGB, thirty-two bits, native byte order."

	^ self code: 0 bitsPerPixel: 32 name: #argb32
]

{ #category : 'private' }
VGCairoSurfaceFormat class >> code: anInteger bitsPerPixel: aBitCount name: aSymbol [
	| newFormat |
	newFormat := self new.
	newFormat setCode: anInteger bitsPerPixel: aBitCount name: aSymbol.
	^ newFormat
]

{ #category : 'instance creation' }
VGCairoSurfaceFormat class >> fromInteger: anInteger [
	^ self all
		  detect: [ :each | each asInteger = anInteger ]
		  ifNone: [ self error: 'No pixel format has the Cairo code ' , anInteger printString ]
]

{ #category : 'instance creation' }
VGCairoSurfaceFormat class >> normalize: aFormat [
	"Answer one of mine for anything that names a Cairo format: one of mine, an Alexandrie
	 AeCairoSurfaceFormat, or the plain integer code. Accepting the Alexandrie value by #asInteger is
	 what lets this package stay free of Ae class names while a VGCanvas subclass passes Alexandrie's
	 own constants straight through."

	aFormat class = self ifTrue: [ ^ aFormat ].
	^ self fromInteger: aFormat asInteger
]

{ #category : 'instance creation' }
VGCairoSurfaceFormat class >> rgb24 [
	"Thirty-two bits with the upper byte unused."

	^ self code: 1 bitsPerPixel: 32 name: #rgb24
]

{ #category : 'comparing' }
VGCairoSurfaceFormat >> = anObject [
	^ self class = anObject class and: [ code = anObject asInteger ]
]

{ #category : 'blending' }
VGCairoSurfaceFormat >> alphaComposing: aSourceAlphaByte over: aDestinationAlphaByte [
	"The alpha pixman writes for every blend mode on its integer path: three parts, each rounded
	 on its own, rather than one rounded sum. Measured over a hundred pairs of alphas: a
	 destination of 1 under a source of 128 writes 128, where rounding the sum once writes 129.
	 No pair of bytes can carry it over two hundred and fifty-five, which was checked over all
	 sixty-five thousand five hundred and thirty-six of them, so it needs no cap."
	^ (self scaleByte: aDestinationAlphaByte by: 255 - aSourceAlphaByte)
	  + (self scaleByte: aSourceAlphaByte by: 255 - aDestinationAlphaByte)
	  + (self dividedByte: aSourceAlphaByte * aDestinationAlphaByte)
]

{ #category : 'blending' }
VGCairoSurfaceFormat >> alphaOfPixel: anInteger [
	"An A8 pixel is alpha alone, an RGB24 pixel has no alpha byte and is always opaque."
	self isA8 ifTrue: [ ^ anInteger bitAnd: 255 ].
	self isRgb24 ifTrue: [ ^ 255 ].
	^ (anInteger bitShift: -24) bitAnd: 255
]

{ #category : 'blending' }
VGCairoSurfaceFormat >> alphaOfWidePixel: anInteger [
	"An A8 wide pixel is one short of alpha alone, and an RGB24 one carries no alpha and is
	 always opaque."
	self isA8 ifTrue: [ ^ anInteger bitAnd: 65535 ].
	self isRgb24 ifTrue: [ ^ 65535 ].
	^ (anInteger bitShift: -48) bitAnd: 65535
]

{ #category : 'accessing' }
VGCairoSurfaceFormat >> asInteger [
	^ code
]

{ #category : 'accessing' }
VGCairoSurfaceFormat >> bitsPerPixel [
	^ bitsPerPixel
]

{ #category : 'blending' }
VGCairoSurfaceFormat >> blendPixel: aSourcePixel maskedBy: aMaskByte over: aDestinationPixel [
	"Source-over at a coverage: the source is scaled by the mask and composited. A plain RGB pixel
	 has no alpha byte to carry the mask, so there the two are mixed by the mask directly, which
	 is the same arithmetic: opaque black at half coverage over white is the grey 16r7F7F7F on a
	 live Cairo RGB24 surface."

	aMaskByte = 255 ifTrue: [ ^ self blendPixel: aSourcePixel over: aDestinationPixel ].
	self isRgb24 ifTrue: [
		^ self lerpPixel: aSourcePixel over: aDestinationPixel by: aMaskByte ].
	^ self
		  blendPixel: (self pixel: aSourcePixel scaledBy: aMaskByte)
		  over: aDestinationPixel
]

{ #category : 'blending' }
VGCairoSurfaceFormat >> blendPixel: aSourcePixel over: aDestinationPixel [
	"Source-over on premultiplied pixels: source plus destination scaled by one minus the source
	 alpha. Premultiplication is what makes that one multiply per channel instead of three."
	| sourceAlpha inverse |
	self isRgb24 ifTrue: [ ^ aSourcePixel ].
	sourceAlpha := self alphaOfPixel: aSourcePixel.
	inverse := 255 - sourceAlpha.
	self isA8 ifTrue: [
		^ sourceAlpha + (self scaleByte: (aDestinationPixel bitAnd: 255) by: inverse) ].
	^ (0 to: 24 by: 8) inject: 0 into: [ :pixel :shift |
		  | source destination |
		  source := (aSourcePixel bitShift: shift negated) bitAnd: 255.
		  destination := (aDestinationPixel bitShift: shift negated) bitAnd: 255.
		  pixel + (((source + (self scaleByte: destination by: inverse)) min: 255) bitShift: shift) ]
]

{ #category : 'blending' }
VGCairoSurfaceFormat >> byteForFloat: aNumber [
	"The byte pixman stores for a channel it composited in floating point: multiply by two
	 hundred and fifty-six, truncate, then take the overflow bit back off, so a full channel
	 lands on two hundred and fifty-five and everything under it floors. Measured: 0.2490 of a
	 channel writes 63 where a rounding division by two hundred and fifty-five writes 64."
	| scaled |
	scaled := ((aNumber * self byteScale) truncated max: 0) min: self byteScale.
	^ scaled - (scaled // self byteScale)
]

{ #category : 'constants' }
VGCairoSurfaceFormat >> byteScale [
	"The power of two pixman's floating point store multiplies a channel by before it truncates,
	 and the divisor its own rounding division by two hundred and fifty-five shifts by."
	^ 256
]

{ #category : 'accessing' }
VGCairoSurfaceFormat >> bytesPerPixel [
	^ bitsPerPixel // 8 max: 1
]

{ #category : 'arithmetic' }
VGCairoSurfaceFormat >> channelShifts [
	"Where my channels sit in a pixel word, lowest first. An A8 pixel is alpha alone and an RGB24
	 pixel has no alpha channel to weigh, which is why the operators have to ask rather than
	 assume four."

	self isA8 ifTrue: [ ^ #( 0 ) ].
	self isRgb24 ifTrue: [ ^ #( 0 8 16 ) ].
	^ #( 0 8 16 24 )
]

{ #category : 'converting' }
VGCairoSurfaceFormat >> colorForPixel: anInteger [
	"The colour that pixel word holds, with the alpha divided back out. A fully transparent pixel
	 answers Color transparent whatever its other bytes say, because the colour it premultiplied is
	 not recoverable and callers compare against that one instance."
	| alpha |
	alpha := self alphaOfPixel: anInteger.
	alpha = 0 ifTrue: [ ^ Color transparent ].
	self isA8 ifTrue: [ ^ Color r: 0.0 g: 0.0 b: 0.0 alpha: alpha / 255 ].
	^ Color
		  r: ((anInteger bitShift: -16) bitAnd: 255) / alpha
		  g: ((anInteger bitShift: -8) bitAnd: 255) / alpha
		  b: (anInteger bitAnd: 255) / alpha
		  alpha: alpha / 255
]

{ #category : 'blending' }
VGCairoSurfaceFormat >> dividedByte: aNumerator [
	"Pixman's own division of a channel numerator by two hundred and fifty-five, written as it
	 writes it: add half a byte, shift down a byte, add that back, shift down a byte again. It is
	 not (aNumerator + 128) // 255 — the two differ at 127 and at every two hundred and fifty-five
	 steps above it, which is a whole step of a channel."
	| offset |
	offset := aNumerator + (self byteScale // 2).
	^ ((offset // self byteScale) + offset) // self byteScale
]

{ #category : 'accessing' }
VGCairoSurfaceFormat >> formatName [
	^ formatName
]

{ #category : 'comparing' }
VGCairoSurfaceFormat >> hash [
	^ code hash
]

{ #category : 'testing' }
VGCairoSurfaceFormat >> isA8 [
	^ formatName = #a8
]

{ #category : 'testing' }
VGCairoSurfaceFormat >> isArgb32 [
	^ formatName = #argb32
]

{ #category : 'testing' }
VGCairoSurfaceFormat >> isRgb24 [
	^ formatName = #rgb24
]

{ #category : 'blending' }
VGCairoSurfaceFormat >> lerpPixel: aSourcePixel over: aDestinationPixel by: aMaskByte [
	"The two pixels mixed channel by channel, the source weighted by the mask and the destination
	 by what is left of it. On a plain RGB surface this is source-over itself: the source there is
	 always opaque and carries no alpha byte for the mask to ride in, so the mask is the only
	 weight there is."

	| inverse |
	inverse := 255 - aMaskByte.
	^ (0 to: 24 by: 8) inject: 0 into: [ :pixel :shift |
		  | source destination |
		  source := (aSourcePixel bitShift: shift negated) bitAnd: 255.
		  destination := (aDestinationPixel bitShift: shift negated) bitAnd: 255.
		  pixel + (((self scaleByte: source by: aMaskByte)
			    + (self scaleByte: destination by: inverse) min: 255) bitShift: shift) ]
]

{ #category : 'blending' }
VGCairoSurfaceFormat >> maskByteForCoverage: aNumber [
	"The eight-bit mask Cairo scales a pixel by for that coverage: the coverage times two hundred
	 and fifty-six, rounded, capped at two hundred and fifty-five. Measured over a sweep of
	 clip edges a two hundred and fifty-sixth apart: a coverage of two hundred and fifty over two
	 hundred and fifty-six stores an alpha of two hundred and fifty exactly, where a mask of the
	 coverage times two hundred and fifty-five would store two hundred and forty-nine."

	^ (aNumber * 256) rounded min: 255
]

{ #category : 'arithmetic' }
VGCairoSurfaceFormat >> mixPixel: aPixel weightedBy: aByte withPixel: anotherPixel weightedBy: anotherByte [
	"Two premultiplied pixels, each scaled by a weight of its own and added, channel by channel.
	 The sum is capped because the add operator weighs both of them fully, and an RGB24 word
	 keeps the opaque alpha byte it is stored with, since the channels themselves carry no
	 alpha."

	| mixed |
	mixed := self channelShifts inject: 0 into: [ :pixel :shift |
		         | one another |
		         one := (aPixel bitShift: shift negated) bitAnd: 255.
		         another := (anotherPixel bitShift: shift negated) bitAnd: 255.
		         pixel + (((self scaleByte: one by: aByte)
			            + (self scaleByte: another by: anotherByte) min: 255)
			           bitShift: shift) ].
	^ self isRgb24
		  ifTrue: [ mixed + (255 bitShift: 24) ]
		  ifFalse: [ mixed ]
]

{ #category : 'blending' }
VGCairoSurfaceFormat >> pixel: aPixel scaledBy: aMaskByte [
	"A premultiplied pixel with every channel scaled by an eight-bit mask, the alpha along with
	 the colours, which keeps it premultiplied. This is how Cairo pays for a partly covered
	 pixel: the paint is quantised once and the mask is applied to the result, so a solid
	 16r7F3F1F5F at half coverage is 16r40201030 and never 16r3F1F0F2F. One measured difference
	 remains, at the very bottom of the range: a mask of one over an opaque grey of 16r80 writes
	 a colour byte of zero on a live context where the rule here writes one."

	aMaskByte = 255 ifTrue: [ ^ aPixel ].
	self isA8 ifTrue: [ ^ self scaleByte: (aPixel bitAnd: 255) by: aMaskByte ].
	^ (0 to: 24 by: 8) inject: 0 into: [ :pixel :shift |
		  pixel
		  + ((self
				    scaleByte: ((aPixel bitShift: shift negated) bitAnd: 255)
				    by: aMaskByte) bitShift: shift) ]
]

{ #category : 'arithmetic' }
VGCairoSurfaceFormat >> pixelForAlpha: anAlphaByte channels: anArray [
	"The pixel word for an alpha byte and three premultiplied channel bytes, in the order red,
	 green, blue. An RGB24 pixel carries no alpha, so the byte in that position is the full byte."

	self isA8 ifTrue: [ ^ anAlphaByte ].
	^ ((self isRgb24
		    ifTrue: [ 255 ]
		    ifFalse: [ anAlphaByte ]) bitShift: 24)
	  + ((anArray at: 1) bitShift: 16)
	  + ((anArray at: 2) bitShift: 8)
	  + (anArray at: 3)
]

{ #category : 'converting' }
VGCairoSurfaceFormat >> pixelForColor: aColor [
	"The premultiplied pixel word a surface of my format stores for that colour. An A8 pixel is one
	 byte of alpha, and an RGB24 pixel carries no alpha at all, so it is stored opaque."
	| alpha |
	self isA8 ifTrue: [ ^ (aColor alpha * 255) rounded ].
	alpha := self isRgb24
		         ifTrue: [ 255 ]
		         ifFalse: [ (aColor alpha * 255) rounded ].
	^ (alpha bitShift: 24)
	  + ((self premultiplyChannel: aColor red byAlpha: alpha) bitShift: 16)
	  + ((self premultiplyChannel: aColor green byAlpha: alpha) bitShift: 8)
	  + (self premultiplyChannel: aColor blue byAlpha: alpha)
]

{ #category : 'converting' }
VGCairoSurfaceFormat >> pixelForRgba: anArray [
	"The premultiplied pixel word a surface of my format stores for those four unpremultiplied
	 channels, in the order red, green, blue, alpha. The premultiplication is by the alpha as a
	 float and is rounded once per channel, which is what live Cairo stores for a gradient: at the
	 centre of pixel 32 of a sixty-four wide ramp from transparent blue to opaque red it writes
	 16r81420040, where premultiplying by the rounded alpha byte instead would write a blue of 63.
	 An RGB24 pixel carries no alpha at all, so its channels are stored unmultiplied."

	| alpha multiplier |
	self isA8 ifTrue: [ ^ ((anArray at: 4) * 255) rounded ].
	alpha := self isRgb24
		         ifTrue: [ 255 ]
		         ifFalse: [ ((anArray at: 4) * 255) rounded ].
	multiplier := self isRgb24
		              ifTrue: [ 1.0 ]
		              ifFalse: [ anArray at: 4 ].
	^ (alpha bitShift: 24)
	  + (((anArray at: 1) * multiplier * 255) rounded bitShift: 16)
	  + (((anArray at: 2) * multiplier * 255) rounded bitShift: 8)
	  + ((anArray at: 3) * multiplier * 255) rounded
]

{ #category : 'converting' }
VGCairoSurfaceFormat >> pixelForRgbaThroughShorts: anArray [
	"The premultiplied pixel word Cairo stores for a solid colour of those four unpremultiplied
	 channels. A solid colour goes through four sixteen-bit shorts: each short is the product of
	 the channel, the alpha and sixty-five thousand five hundred and thirty-five, truncated, and
	 the pixel keeps the top byte of each. This is one step away from the rule a gradient follows,
	 which rounds the product of the channel and two hundred and fifty-five: r 0.5 g 0.25 b 0.75
	 alpha 0.5 is stored as 16r7F3F1F5F here and as 16r7F40205F there, both measured on a live
	 Cairo context. An alpha only surface keeps no colour and an RGB one keeps no alpha."

	| alpha multiplier |
	self isA8 ifTrue: [ ^ self shortByteOf: (anArray at: 4) ].
	alpha := self isRgb24
		         ifTrue: [ 255 ]
		         ifFalse: [ self shortByteOf: (anArray at: 4) ].
	multiplier := self isRgb24
		              ifTrue: [ 1.0 ]
		              ifFalse: [ anArray at: 4 ].
	^ (alpha bitShift: 24)
	  + ((self shortByteOf: (anArray at: 1) * multiplier) bitShift: 16)
	  + ((self shortByteOf: (anArray at: 2) * multiplier) bitShift: 8)
	  + (self shortByteOf: (anArray at: 3) * multiplier)
]

{ #category : 'arithmetic' }
VGCairoSurfaceFormat >> premultipliedChannelsOfPixel: anInteger [
	"The red, green and blue bytes the pixel word stores, still multiplied by its alpha. An A8
	 pixel stores no colour, so it answers three zeroes and the caller keeps its alpha."

	self isA8 ifTrue: [ ^ #( 0 0 0 ) ].
	^ {
		  ((anInteger bitShift: -16) bitAnd: 255).
		  ((anInteger bitShift: -8) bitAnd: 255).
		  (anInteger bitAnd: 255) }
]

{ #category : 'blending' }
VGCairoSurfaceFormat >> premultipliedChannelsOfWidePixel: anInteger [
	"The red, green and blue shorts the wide pixel stores, still multiplied by its alpha. An A8
	 pixel stores no colour, so it answers three zeroes and the caller keeps its alpha."
	self isA8 ifTrue: [ ^ #( 0 0 0 ) ].
	^ {
		  ((anInteger bitShift: -32) bitAnd: 65535).
		  ((anInteger bitShift: -16) bitAnd: 65535).
		  (anInteger bitAnd: 65535) }
]

{ #category : 'converting' }
VGCairoSurfaceFormat >> premultiplyChannel: aFraction byAlpha: anAlphaByte [
	"Premultiplication: a stored channel is already multiplied by the alpha it carries, which is why
	 half-transparent red is 16r80800000 and not 16r80FF0000."
	^ (aFraction * anAlphaByte) rounded
]

{ #category : 'printing' }
VGCairoSurfaceFormat >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPutAll: '(';
		nextPutAll: formatName;
		nextPut: $)
]

{ #category : 'converting' }
VGCairoSurfaceFormat >> rgbaForPixel: anInteger [
	"The four channels that pixel word holds, as floats in zero to one with the alpha divided back
	 out. This is colorForPixel: without the detour through a Pharo Color, which keeps ten bits a
	 channel and so cannot carry every step of a two-hundred-and-fifty-five-step ramp."

	| alpha |
	alpha := self alphaOfPixel: anInteger.
	alpha = 0 ifTrue: [ ^ #( 0.0 0.0 0.0 0.0 ) ].
	self isA8 ifTrue: [ ^ { 0.0. 0.0. 0.0. alpha / 255 } ].
	^ {
		  (((anInteger bitShift: -16) bitAnd: 255) / alpha).
		  (((anInteger bitShift: -8) bitAnd: 255) / alpha).
		  ((anInteger bitAnd: 255) / alpha).
		  (alpha / 255) }
]

{ #category : 'blending' }
VGCairoSurfaceFormat >> scaleByte: aByte by: anAlphaByte [
	"Divides by 255 with rounding, which is what Cairo's integer blend does, so our pixels and
	 Cairo's agree byte for byte."
	^ (aByte * anAlphaByte + 127) // 255
]

{ #category : 'private' }
VGCairoSurfaceFormat >> setCode: anInteger bitsPerPixel: aBitCount name: aSymbol [
	code := anInteger.
	bitsPerPixel := aBitCount.
	formatName := aSymbol
]

{ #category : 'converting' }
VGCairoSurfaceFormat >> shortByteOf: aNumber [
	"The byte Cairo keeps for one channel of a solid colour: the channel as a sixteen-bit short,
	 of which only the top byte is stored."
	^ (self shortOf: aNumber) bitShift: -8
]

{ #category : 'converting' }
VGCairoSurfaceFormat >> shortOf: aNumber [
	"The sixteen-bit short Cairo converts one channel of a solid colour into, rounded. Measured
	 with exact doubles on a live context: a half of sixty-five thousand five hundred and
	 thirty-five is 32767.5 and is kept as 32768, so the short rounds and does not truncate."
	^ ((aNumber * 65535) rounded min: 65535) max: 0
]

{ #category : 'constants' }
VGCairoSurfaceFormat >> shortsPerByte [
	"What one byte of a channel is worth in sixteen-bit shorts. Stretching a byte by this is
	 exact: two hundred and fifty-five times it is sixty-five thousand five hundred and
	 thirty-five, so a byte over 255 and the stretched short over 65535 are the same number."
	^ 65535 / 255
]

{ #category : 'accessing' }
VGCairoSurfaceFormat >> strideForWidth: aWidth [
	"What cairo_format_stride_for_width answers: the row span rounded up to a four-byte boundary."

	^ (aWidth * bitsPerPixel + 31) // 32 * 4
]

{ #category : 'converting' }
VGCairoSurfaceFormat >> widePixelForRgba: anArray [
	"The source word pixman composites a solid colour from when it works in floating point: the
	 four sixteen-bit shorts of which pixelForRgbaThroughShorts: keeps only the top byte each,
	 packed alpha, red, green, blue, sixteen bits apiece. The eight operators Cairo composites in
	 floating point read the colour at this precision, and land a step out of live Cairo when
	 they are given the bytes instead. An alpha only surface keeps no colour and an RGB one is
	 always opaque."
	| alpha multiplier |
	self isA8 ifTrue: [ ^ self shortOf: (anArray at: 4) ].
	alpha := self isRgb24
		         ifTrue: [ 65535 ]
		         ifFalse: [ self shortOf: (anArray at: 4) ].
	multiplier := self isRgb24
		              ifTrue: [ 1.0 ]
		              ifFalse: [ anArray at: 4 ].
	^ (alpha bitShift: 48)
	  + ((self shortOf: (anArray at: 1) * multiplier) bitShift: 32)
	  + ((self shortOf: (anArray at: 2) * multiplier) bitShift: 16)
	  + (self shortOf: (anArray at: 3) * multiplier)
]

{ #category : 'converting' }
VGCairoSurfaceFormat >> widenPixel: anInteger [
	"The same pixel with every byte stretched into a sixteen-bit short, which loses nothing and
	 adds nothing. This is how a paint Cairo evaluates in bytes, a gradient or a surface, reaches
	 an operator that composites in floating point: the unpremultiplied colour it answers is the
	 same either way, and only a solid colour carries more precision than this."
	| channels |
	self isA8 ifTrue: [ ^ (anInteger bitAnd: 255) * self shortsPerByte ].
	channels := self premultipliedChannelsOfPixel: anInteger.
	^ ((self alphaOfPixel: anInteger) * self shortsPerByte bitShift: 48)
	  + ((channels first) * self shortsPerByte bitShift: 32)
	  + ((channels second) * self shortsPerByte bitShift: 16)
	  + (channels third * self shortsPerByte)
]
