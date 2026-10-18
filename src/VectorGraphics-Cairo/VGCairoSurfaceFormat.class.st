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

{ #category : 'accessing' }
VGCairoSurfaceFormat >> strideForWidth: aWidth [
	"What cairo_format_stride_for_width answers: the row span rounded up to a four-byte boundary."

	^ (aWidth * bitsPerPixel + 31) // 32 * 4
]
