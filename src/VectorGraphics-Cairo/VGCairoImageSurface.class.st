"
I am the replacement for AeCairoImageSurface: a premultiplied ARGB32 pixel target.

I can own my pixels or borrow them. Borrowing matters because BARenderer >> renderWith:pixels:stride:physicalRectangle:logicalRectangle: hands the renderer a raw host window address and a stride, and draws straight into it; see section 2.2 of VECTORCANVAS-PLAN.md. I also carry the device offset and the device scale that the host sets for a High DPI display.

Unit 1.1 implements me; until then my selectors signal VGNotYetImplemented.
"
Class {
	#name : 'VGCairoImageSurface',
	#superclass : 'VGCairoObject',
	#instVars : [
		'format',
		'width',
		'height',
		'stride',
		'data',
		'deviceOffset',
		'deviceScale',
		'status',
		'finished',
		'displayList',
		'backend'
	],
	#category : 'VectorGraphics-Cairo-Surface',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Surface'
}

{ #category : 'instance creation' }
VGCairoImageSurface class >> extent: aPoint [
	^ self extent: aPoint format: VGCairoSurfaceFormat argb32
]

{ #category : 'instance creation' }
VGCairoImageSurface class >> extent: aPoint format: aFormat [
	^ self newFormat: aFormat extent: aPoint
]

{ #category : 'skeleton - unit 1.9' }
VGCairoImageSurface class >> extent: aPoint to: aFileReference [
	^ self notYetImplementedIn: '1.9' selector: #extent:to:
]

{ #category : 'instance creation' }
VGCairoImageSurface class >> fromForm: aForm [
	"A Form holds straight alpha, so every pixel is premultiplied on the way in."
	| form surface |
	form := aForm asFormOfDepth: 32.
	surface := self extent: form extent.
	0 to: form height - 1 do: [ :y |
		0 to: form width - 1 do: [ :x |
			surface
				pixelAtX: x
				y: y
				put: (surface format pixelForColor: (form colorAt: x @ y)) ] ].
	^ surface
]

{ #category : 'instance creation' }
VGCairoImageSurface class >> newFormat: aFormat extent: aPoint [
	"I own these pixels: a ByteArray in object memory, zero filled, which is the fully transparent
	 surface Cairo answers from cairo_image_surface_create."
	| pixelFormat stride |
	pixelFormat := VGCairoSurfaceFormat normalize: aFormat.
	stride := pixelFormat strideForWidth: aPoint x.
	^ self new
		  setFormat: pixelFormat
		  extent: aPoint
		  stride: stride
		  data: (ByteArray new: stride * aPoint y)
]

{ #category : 'constants' }
VGCairoImageSurface class >> transparentFormPixel [
	"White with zero alpha: the word Alexandrie leaves in a Form where the surface is fully
	 transparent."
	^ 16r00FFFFFF
]

{ #category : 'instance creation' }
VGCairoImageSurface class >> unownedNewForData: aBuffer format: aFormat width: aWidth height: aHeight stride: aStride [
	"The pixels belong to the caller: a host window hands over a raw address and its own row pitch.
	 Both a ByteArray and an ExternalAddress answer #uint32AtOffset:put:, so either is accepted and
	 one code path serves both. A stride too small for one row is reported through my status, as
	 Cairo does, rather than signalled."
	| pixelFormat surface |
	pixelFormat := VGCairoSurfaceFormat normalize: aFormat.
	surface := self new
		           setFormat: pixelFormat
		           extent: aWidth @ aHeight
		           stride: aStride
		           data: aBuffer.
	aStride < (pixelFormat strideForWidth: aWidth) ifTrue: [
		surface setStatus: VGCairoStatus invalidStride ].
	^ surface
]

{ #category : 'converting' }
VGCairoImageSurface >> asForm [
	"A Form holds straight alpha, so the stored premultiplication is divided back out. A fully
	 transparent pixel answers 16r00FFFFFF, which is what Alexandrie answers, because a Form that
	 differed there would blit differently."
	| form bits |
	form := Form extent: self extent depth: 32.
	bits := form bits.
	0 to: height - 1 do: [ :y |
		0 to: width - 1 do: [ :x |
			bits
				at: y * width + x + 1
				put: (self straightAlphaPixelAtX: x y: y) ] ].
	^ form
]

{ #category : 'accessing' }
VGCairoImageSurface >> backend [
	"Whichever backend draws my frames. The software one is the default and the failover; phase 2
	 puts the Vulkan one here."
	^ backend ifNil: [ backend := VGSoftwareBackend new ]
]

{ #category : 'accessing' }
VGCairoImageSurface >> backend: aBackend [
	self flush.
	backend := aBackend
]

{ #category : 'pixel access' }
VGCairoImageSurface >> blendPixel: anInteger [
	"Every pixel of mine, with that source painted over what is already there. Row by row and only
	 width pixels wide, like #fillPixel:, because the padding belongs to whoever gave me the
	 stride."
	self ensureNotFinished.
	self flush.
	0 to: height - 1 do: [ :y |
		0 to: width - 1 do: [ :x |
			self
				primitivePixelAtX: x
				y: y
				put: (format blendPixel: anInteger over: (self primitivePixelAtX: x y: y)) ] ]
]

{ #category : 'accessing' }
VGCairoImageSurface >> boundsRectangle [
	"My whole area in device space, which is the clip until unit 1.6 brings the clip stack."
	^ 0 @ 0 corner: width @ height
]

{ #category : 'accessing' }
VGCairoImageSurface >> byteSize [
	^ stride * height
]

{ #category : 'pixels' }
VGCairoImageSurface >> colorAt: aPoint [
	^ self colorAtX: aPoint x y: aPoint y
]

{ #category : 'pixels' }
VGCairoImageSurface >> colorAtX: x y: y [
	^ format colorForPixel: (self pixelAtX: x y: y)
]

{ #category : 'accessing' }
VGCairoImageSurface >> data [
	"The buffer my pixels live in: my own ByteArray, or whatever the caller of
	 #unownedNewForData:format:width:height:stride: gave me."
	^ data
]

{ #category : 'device space' }
VGCairoImageSurface >> deviceOffset [
	^ deviceOffset
]

{ #category : 'device space' }
VGCairoImageSurface >> deviceOffset: aPoint [
	"Bloc's host renderer offsets a surface by the negated origin of the damaged rectangle, so the
	 drawing lands where the window wants it."
	deviceOffset := aPoint asPoint
]

{ #category : 'device space' }
VGCairoImageSurface >> deviceScale [
	^ deviceScale
]

{ #category : 'device space' }
VGCairoImageSurface >> deviceScale: aPoint [
	deviceScale := aPoint asPoint
]

{ #category : 'accessing - device space' }
VGCairoImageSurface >> deviceScaleMatrix [
	^ VGCairoMatrix newScalingByX: deviceScale x y: deviceScale y
]

{ #category : 'device space' }
VGCairoImageSurface >> deviceScaleX: aNumber y: anotherNumber [
	self deviceScale: aNumber @ anotherNumber
]

{ #category : 'accessing' }
VGCairoImageSurface >> displayList [
	"The frame being recorded on me. Every context drawing on me records here, so that two contexts
	 on one surface draw in the order their calls were made."
	^ displayList ifNil: [ displayList := VGDisplayList new ]
]

{ #category : 'lifecycle' }
VGCairoImageSurface >> ensureNotFinished [
	finished ifTrue: [
		self error: 'Surface is finished: no further drawing is allowed' ]
]

{ #category : 'accessing' }
VGCairoImageSurface >> extent [
	^ width @ height
]

{ #category : 'pixel access' }
VGCairoImageSurface >> fillPixel: anInteger [
	"Row by row and only width pixels wide: the bytes between one row and the next belong to whoever
	 gave me the stride, and a host window reads them back. The frame waiting on me is drawn first,
	 so that a fill really does cover what came before it."
	self ensureNotFinished.
	self flush.
	0 to: height - 1 do: [ :y |
		0 to: width - 1 do: [ :x | self primitivePixelAtX: x y: y put: anInteger ] ]
]

{ #category : 'lifecycle' }
VGCairoImageSurface >> finish [
	"Cairo refuses further drawing on a finished surface but leaves its pixels readable, and
	 finishing twice is not an error. What was recorded and not yet drawn is drawn first, as Cairo
	 flushes before it finishes."
	finished ifFalse: [ self flush ].
	finished := true.
	^ self
]

{ #category : 'drawing' }
VGCairoImageSurface >> flush [
	"Draw the frame recorded on me and keep nothing. This is Cairo's own synchronisation point:
	 everything that reads my pixels sends it first, and a caller holding a raw pointer has to send
	 it itself."
	self displayList isEmpty ifTrue: [ ^ self ].
	self displayList replayOn: self backend.
	self backend drainInto: self.
	self displayList reset
]

{ #category : 'accessing' }
VGCairoImageSurface >> format [
	^ format
]

{ #category : 'accessing' }
VGCairoImageSurface >> height [
	^ height
]

{ #category : 'inspector' }
VGCairoImageSurface >> inspectorLayout: aBuilder [
	<inspectorPresentationOrder: 11 title: 'Layout'>
	^ aBuilder newTable
		  items: self layoutDescription;
		  addColumn: (SpStringTableColumn title: 'Property' evaluated: [ :each | each key ]);
		  addColumn: (SpStringTableColumn
				   title: 'Value'
				   evaluated: [ :each | each value printString ]);
		  yourself
]

{ #category : 'inspector' }
VGCairoImageSurface >> inspectorLayoutContext: aContext [
	aContext active: data notNil
]

{ #category : 'inspector' }
VGCairoImageSurface >> inspectorPicture: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Picture'>
	"#asForm answers a fresh Form every call, so showing the surface cannot change it."
	^ aBuilder newImage
		  image: self asForm;
		  yourself
]

{ #category : 'inspector' }
VGCairoImageSurface >> inspectorPictureContext: aContext [
	aContext active: data notNil
]

{ #category : 'lifecycle' }
VGCairoImageSurface >> isFinished [
	^ finished
]

{ #category : 'inspector' }
VGCairoImageSurface >> layoutDescription [
	"Read back out of me, so the tab that shows it cannot drift from #strideForWidth: or from the
	 buffer I was handed."
	| used |
	used := width * format bytesPerPixel.
	^ {
		  ('format' -> format formatName).
		  ('extent' -> self extent).
		  ('stride' -> stride).
		  ('bytes per row carrying pixels' -> used).
		  ('padding bytes per row' -> (stride - used)).
		  ('byte size' -> self byteSize).
		  ('buffer' -> data class name).
		  ('device offset' -> deviceOffset).
		  ('device scale' -> deviceScale).
		  ('status' -> status).
		  ('finished' -> finished) }
]

{ #category : 'instance creation' }
VGCairoImageSurface >> newContext [
	^ VGCairoContext newFor: self
]

{ #category : 'instance creation' }
VGCairoImageSurface >> newSimilarImageFormat: aFormat width: aWidth height: aHeight [
	"AeCanvas builds its shadow mask this way and asks the result for its status."
	^ self class newFormat: aFormat extent: aWidth @ aHeight
]

{ #category : 'pixels' }
VGCairoImageSurface >> offsetOfX: x y: y [
	^ y * stride + (x * format bytesPerPixel)
]

{ #category : 'pixel access' }
VGCairoImageSurface >> pixelAtX: x y: y [
	"Both a ByteArray and an ExternalAddress answer #uint32AtOffset:, so the same path reads my own
	 buffer and a host window's memory. The frame is drained first, because a caller reading a
	 pixel means to see what it drew."
	self flush.
	^ self primitivePixelAtX: x y: y
]

{ #category : 'pixels' }
VGCairoImageSurface >> pixelAtX: x y: y put: anInteger [
	self ensureNotFinished.
	self primitivePixelAtX: x y: y put: anInteger.
	^ anInteger
]

{ #category : 'pixel access' }
VGCairoImageSurface >> primitivePixelAtX: x y: y [
	"The stored pixel, read without draining the frame first. The backend reads through me while it
	 is draining, so the public reader cannot be the one it uses."
	| offset |
	offset := self offsetOfX: x y: y.
	^ format isA8
		  ifTrue: [ data uint8AtOffset: offset ]
		  ifFalse: [ data uint32AtOffset: offset ]
]

{ #category : 'pixels' }
VGCairoImageSurface >> primitivePixelAtX: x y: y put: anInteger [
	| offset |
	offset := self offsetOfX: x y: y.
	format isA8
		ifTrue: [ data uint8AtOffset: offset put: anInteger ]
		ifFalse: [ data uint32AtOffset: offset put: anInteger ]
]

{ #category : 'initialization' }
VGCairoImageSurface >> setFormat: aFormat extent: aPoint stride: anInteger data: aBuffer [
	format := aFormat.
	width := aPoint x.
	height := aPoint y.
	stride := anInteger.
	data := aBuffer.
	deviceOffset := 0 @ 0.
	deviceScale := 1 @ 1.
	status := VGCairoStatus success.
	finished := false
]

{ #category : 'initialization' }
VGCairoImageSurface >> setStatus: aStatus [
	status := aStatus
]

{ #category : 'accessing' }
VGCairoImageSurface >> status [
	^ status
]

{ #category : 'converting' }
VGCairoImageSurface >> straightAlphaPixelAtX: x y: y [
	| colour |
	colour := self colorAtX: x y: y.
	colour isTransparent ifTrue: [ ^ self class transparentFormPixel ].
	^ colour pixelWordForDepth: 32
]

{ #category : 'accessing' }
VGCairoImageSurface >> stride [
	^ stride
]

{ #category : 'accessing' }
VGCairoImageSurface >> width [
	^ width
]

{ #category : 'converting' }
VGCairoImageSurface >> writePngTo: aFileReference [
	"Answers my status, as Alexandrie does, so a caller can cascade #ensureIsSuccess."
	aFileReference binaryWriteStreamDo: [ :stream |
		PNGReadWriter putForm: self asForm onStream: stream ].
	^ status
]
