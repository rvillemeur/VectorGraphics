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
VGCairoSurfaceFormat >> alphaOfPixel: anInteger [
	"An A8 pixel is alpha alone, an RGB24 pixel has no alpha byte and is always opaque."
	self isA8 ifTrue: [ ^ anInteger bitAnd: 255 ].
	self isRgb24 ifTrue: [ ^ 255 ].
	^ (anInteger bitShift: -24) bitAnd: 255
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

{ #category : 'accessing' }
VGCairoSurfaceFormat >> bytesPerPixel [
	^ bitsPerPixel // 8 max: 1
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
	 truncated and not rounded, of which only the top byte is stored."

	^ ((aNumber * 65535) truncated bitShift: -8) min: 255
]

{ #category : 'accessing' }
VGCairoSurfaceFormat >> strideForWidth: aWidth [
	"What cairo_format_stride_for_width answers: the row span rounded up to a four-byte boundary."

	^ (aWidth * bitsPerPixel + 31) // 32 * 4
]
