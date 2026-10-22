"
A solid paint that is one premultiplied pixel already. `VGTiledFillEncoding` keeps a fill's colour as the pixel its paint answered, because a kernel carries a pixel and not a paint, and a decoded entry needs a paint that answers that pixel again. I answer it whatever the format and wherever it is asked for, so the encoding that builds me is the one place where the format is decided. I carry the tag of a solid colour, which is what one pixel stands for.
"
Class {
	#name : 'VGPixelPaint',
	#superclass : 'VGPaint',
	#instVars : [
		'pixel'
	],
	#category : 'VectorGraphics-Vulkan-Tiles',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Tiles'
}

{ #category : 'constants' }
VGPixelPaint class >> paintTag [
	"One premultiplied pixel is a solid colour, so I carry the tag of one; the ABI block and
	 Cairo's own pattern type number say the same thing about me as about the paint I came
	 from."
	^ VGColorPaint paintTag
]

{ #category : 'instance creation' }
VGPixelPaint class >> pixel: anInteger [
	^ self new setPixel: anInteger
]

{ #category : 'inspecting' }
VGPixelPaint >> channelReport [
	"My pixel as the format the encoding writes stores it: the alpha, and the three colour bytes
	 still multiplied by it. The format is asked rather than the bytes being shifted here."
	| format |
	format := VGTiledFillEncoding targetFormat.
	^ #( #alpha #red #green #blue )
		  with: { (format alphaOfPixel: pixel) }
			  , (format premultipliedChannelsOfPixel: pixel)
		  collect: [ :name :value | { name. value } ]
]

{ #category : 'inspecting' }
VGPixelPaint >> inspectorChannels: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Channels'>
	"The channels of my one pixel, read through the format that quantised it."
	^ aBuilder newTable
		  addColumn: (SpStringTableColumn
				   title: 'Channel'
				   evaluated: [ :each | (each at: 1) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Byte'
				   evaluated: [ :each | (each at: 2) printString ]);
		  items: self channelReport;
		  yourself
]

{ #category : 'inspecting' }
VGPixelPaint >> inspectorChannelsContext: aContext [
	aContext active: pixel isNotNil
]

{ #category : 'testing' }
VGPixelPaint >> isSolid [
	^ true
]

{ #category : 'accessing' }
VGPixelPaint >> pixel [
	^ pixel
]

{ #category : 'painting' }
VGPixelPaint >> pixelIn: aFormat atX: x y: y [
	"The one pixel I was built from, wherever it is asked for. The format is not read: I am
	 quantised already, and VGTiledFillEncoding, which is the only thing that builds me, encodes
	 a frame for one format and says which."
	^ pixel
]

{ #category : 'printing' }
VGPixelPaint >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPut: $(;
		nextPutAll: (pixel ifNil: [ 'nil' ] ifNotNil: [ pixel printStringHex ]);
		nextPut: $)
]

{ #category : 'initialization' }
VGPixelPaint >> setPixel: anInteger [
	pixel := anInteger
]
