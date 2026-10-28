"
I hold the frames the tests of the tiled rasteriser draw and the four ways they draw one: the software backend, which is the oracle of every one of them, the tiled rasteriser over a display list, the same rasteriser over the buffers of an encoding, and the device itself. My subclasses are the gates of one capability each, and they share these because a gate is the same frame drawn two ways and it has to be the same frame. I am abstract and declare no test of my own.
"
Class {
	#name : 'VGTiledFrameTestCase',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Vulkan-Tests-Tests',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Tests'
}

{ #category : 'constants' }
VGTiledFrameTestCase class >> deviceChannelTolerance [
	"How far a channel of a device pixel may sit from the same channel drawn by the software
	 backend. The device computes in f32 and the software backend in Float64, so a pixel on an
	 antialiased edge or inside a gradient ramp can land one byte either side of the rounding
	 boundary. Measured over the twenty-four cases of the subset and the fifteen gradient frames
	 of the fixture: no pixel of any of them is farther than this."
	^ 1
]

{ #category : 'constants' }
VGTiledFrameTestCase class >> devicePixelsAllowedToDifferPerCase [
	"How many pixels of one frame may differ from the software backend at all, within the channel
	 tolerance. Measured over the twenty-four cases of the subset and the fifteen gradient frames
	 of the fixture: six frames differ and the rest are byte for byte identical. One pixel of
	 path-filled-rounded-rectangle differs, which is the antialiased edge of unit 2.3, and the
	 other five are gradients, where a whole run of the ramp lands on a rounding boundary —
	 128 pixels of linearUnderRepeat and of linearUnderReflect, 64 of source-linear-gradient and
	 48 of linearUnderNone and of linearUnderPad.
	 Those runs are not device arithmetic. The device reads the stop channels as f32, and against
	 a software frame whose own stops are narrowed the same way only the one antialiased pixel
	 differs at all, so what the ramp crosses is the quantisation of the narrowed stop and not the
	 evaluation."
	^ 128
]

{ #category : 'testing' }
VGTiledFrameTestCase class >> isAbstract [
	"I hold the frames and the ways of drawing them, and no gate of my own, so no suite is ever
	 built from me."

	^ self = VGTiledFrameTestCase
]

{ #category : 'private' }
VGTiledFrameTestCase >> assertDeviceDrawsCase: aCase with: aBlock [
	"One case drawn on the device and by the software backend on the same frame and compared
	 premultiplied: no pixel farther than the tolerance in any channel, and at most the measured
	 count of pixels differing at all. The case is named in the description, because a gate that
	 walks the corpus has to say which case broke it."

	| comparison |
	comparison := VGFormComparison
		              between: (self deviceFormOfExtent: aCase extent drawnWith: aBlock)
		              and: (self softwareFormOfExtent: aCase extent drawnWith: aBlock).
	self
		assert:
			(comparison pixelsFartherThan: self class deviceChannelTolerance) = 0
		description: aCase name.
	self
		assert: comparison differingPixelCount
			    <= self class devicePixelsAllowedToDifferPerCase
		description: aCase name
]

{ #category : 'fixtures' }
VGTiledFrameTestCase >> caseExtent [
	"The extent of every case of the conformance corpus, and of every frame I draw myself."

	^ VGConformanceCorpus caseExtent
]

{ #category : 'private' }
VGTiledFrameTestCase >> deviceFormOfExtent: anExtent drawnWith: aBlock [
	"The same frame drawn on the device: encoded, dispatched over one workgroup a tile and the
	 pixels written back. The pixels are packed by the backend itself, because the frame has to
	 reach the device the way a drained surface sends it. The device, the kernel and the buffers
	 are the session's and are kept between frames, so a suite of cases opens one context and
	 grows each buffer to the largest frame it draws. Nothing here goes through the failover, so a
	 device that fails raises rather than quietly answering the software picture."

	| surface encoding pixels backend |
	surface := VGCairoImageSurface extent: anExtent.
	aBlock value: surface newContext.
	encoding := VGTiledFillEncoding of: surface displayList extent: anExtent.
	surface displayList reset.
	backend := VGVulkanBackend new.
	pixels := backend pixelsOf: surface.
	(VGVulkanDeviceSession default dispatchForEncoding: encoding)
		draw: encoding
		into: pixels.
	backend write: pixels into: surface.
	^ surface asForm
]

{ #category : 'fixtures' }
VGTiledFrameTestCase >> displayListOfExtent: anExtent drawnWith: aBlock [
	"The recorded frame itself, read before anything drains it."

	| surface |
	surface := VGCairoImageSurface extent: anExtent.
	aBlock value: surface newContext.
	^ surface displayList
]

{ #category : 'fixtures' }
VGTiledFrameTestCase >> encodedFormOfExtent: anExtent drawnWith: aBlock [
	"The same frame drawn from the buffers alone: the rasteriser of step one reads the encoding
	 and never the display list it came from."
	| surface |
	surface := VGCairoImageSurface extent: anExtent.
	aBlock value: surface newContext.
	(VGTiledFillRasteriser on:
		 (VGTiledFillEncoding of: surface displayList extent: anExtent))
		drawOn: surface.
	surface displayList reset.
	^ surface asForm
]

{ #category : 'fixtures' }
VGTiledFrameTestCase >> encodingOfExtent: anExtent drawnWith: aBlock [
	"The frame that block draws, written out as buffers. The display list is reset afterwards, so
	 that reading the pixels of the surface does not replay the frame on the software backend as
	 well."

	| surface encoding |
	surface := VGCairoImageSurface extent: anExtent.
	aBlock value: surface newContext.
	encoding := VGTiledFillEncoding of: surface displayList extent: anExtent.
	surface displayList reset.
	^ encoding
]

{ #category : 'private' }
VGTiledFrameTestCase >> hasDevice [
	"Whether a device on this machine computes, asked of the session that holds it. A test of mine
	 that needs one answers early where there is none: a machine with no driver has nothing to
	 compare and that is not a failure."

	^ VGVulkanDeviceSession default contextOrNil isNotNil
]

{ #category : 'fixtures' }
VGTiledFrameTestCase >> roundedToSingleFloat: aNumber [
	"The number as a buffer of single floats keeps it, widened again so that the oracle of this
	 step computes in the values the buffers hold. Read through the bit pattern rather than
	 through a Float32Array, so that the oracle narrows by its own route and not by the
	 encoding's."
	^ Float fromIEEE32Bit: aNumber asFloat asIEEE32BitWord
]

{ #category : 'fixtures' }
VGTiledFrameTestCase >> singleFloatBlitOf: anEntry [
	"The blit with its clip and the stops of its paint narrowed to single floats and its mask
	 its own. The rectangle the encoding writes for a mask is the extents of a clip and so whole
	 pixels, and the alpha of a mask is a byte, so neither of those narrows; the clip is narrowed
	 before it meets the mask rather than after, which is the same rectangle either way because
	 the mask rectangle is exact in a single float."

	^ VGBlitEntry
		  surface: anEntry surface
		  at: anEntry origin
		  paint: (self singleFloatPaintOf: anEntry paint)
		  clip: (VGClip bounds: (self singleFloatRectangleOf: anEntry clip bounds))
		  operator: anEntry operator
]

{ #category : 'fixtures' }
VGTiledFrameTestCase >> singleFloatCopyOf: aDisplayList [
	"A display list of my own, holding the same frame in single floats. It is built before the
	 frame is drained, because draining resets the list."
	| copied |
	copied := VGDisplayList new.
	aDisplayList entries do: [ :each |
		copied add: (self singleFloatEntryOf: each) ].
	^ copied
]

{ #category : 'fixtures' }
VGTiledFrameTestCase >> singleFloatEntryOf: anEntry [
	"The entry as the buffers can hold it. The two kinds a frame holds narrow differently, so
	 each answers its own."

	^ (anEntry isKindOf: VGBlitEntry)
		  ifTrue: [ self singleFloatBlitOf: anEntry ]
		  ifFalse: [ self singleFloatFillOf: anEntry ]
]

{ #category : 'fixtures' }
VGTiledFrameTestCase >> singleFloatFillOf: anEntry [
	"The fill with its coordinates, its clip and the stops of its paint narrowed to single
	 floats and everything else its own: the operator, the fill rule, the antialiasing mode, the
	 alpha and the coefficient block of its own paint are carried by the encoding without
	 arithmetic, so this gates the layout alone."

	| segments |
	segments := (VGSegments
		             coordinates:
			             (anEntry segments coordinates collect: [ :each |
				              self roundedToSingleFloat: each ])
		             fillRule: anEntry segments fillRule
		             antialias: anEntry segments antialias) withAlpha:
		            anEntry segments alpha.
	^ VGFillEntry
		  segments: segments
		  paint: (self singleFloatPaintOf: anEntry paint)
		  clip: (VGClip
				   bounds: (self singleFloatRectangleOf: anEntry clip bounds)
				   shapes: (self singleFloatShapesOf: anEntry clip))
		  operator: anEntry operator
]

{ #category : 'fixtures' }
VGTiledFrameTestCase >> singleFloatFormOfExtent: anExtent drawnWith: aBlock [
	"The oracle of this step: the same frame narrowed to single floats and drawn through the
	 entries themselves. Where the buffers hold the frame and nothing more, the two agree byte
	 for byte."
	| surface list |
	surface := VGCairoImageSurface extent: anExtent.
	aBlock value: surface newContext.
	list := self singleFloatCopyOf: surface displayList.
	surface displayList reset.
	(VGTiledFillRasteriser of: list extent: anExtent) drawOn: surface.
	^ surface asForm
]

{ #category : 'running' }
VGTiledFrameTestCase >> singleFloatPaintOf: aPaint [
	"The paint as the buffers can hold it. A coefficient block is single floats already, so it
	 travels unchanged; a stop list is kept in Float64 and is narrowed here. A paint with no stop
	 list is its own narrowing."

	| narrowed |
	aPaint hasStops ifFalse: [ ^ aPaint ].
	narrowed := aPaint class fromBlock: aPaint coefficients.
	aPaint stops do: [ :stop |
		narrowed
			addStopAt: (self roundedToSingleFloat: stop key)
			channels: (stop value collect: [ :channel |
					 self roundedToSingleFloat: channel ]) ].
	^ narrowed
]

{ #category : 'fixtures' }
VGTiledFrameTestCase >> singleFloatRectangleOf: aRectangle [
	^ Rectangle
		  left: (self roundedToSingleFloat: aRectangle left)
		  right: (self roundedToSingleFloat: aRectangle right)
		  top: (self roundedToSingleFloat: aRectangle top)
		  bottom: (self roundedToSingleFloat: aRectangle bottom)
]

{ #category : 'fixtures' }
VGTiledFrameTestCase >> singleFloatShapesOf: aClip [
	"The shapes of a clip with their coordinates narrowed to single floats, which is the only
	 thing the buffers change about a shape: the fill rule and the antialiasing mode ride as
	 codes and come back as they went."

	^ aClip shapes collect: [ :shape |
		  VGSpanScanner
			  segments: (shape segments collect: [ :each |
					   self roundedToSingleFloat: each ])
			  fillRule: shape fillRule
			  antialias: shape antialias ]
]

{ #category : 'fixtures' }
VGTiledFrameTestCase >> softwareFormOfExtent: anExtent drawnWith: aBlock [
	"The frame the software backend draws, which is the oracle of every test of mine."

	| surface |
	surface := VGCairoImageSurface extent: anExtent.
	aBlock value: surface newContext.
	surface flush.
	^ surface asForm
]

{ #category : 'fixtures' }
VGTiledFrameTestCase >> supportedCasesDo: aBlock [
	"Every case of the conformance corpus whose frame the subset draws, with the block that
	 draws it and the entries it records. A case is drawn once to find out what it records,
	 because that is written down nowhere else, and a subclass gates the cases of its own
	 capability out of these."

	VGConformanceCorpus cases do: [ :case |
		| draw list |
		draw := [ :context | case drawOn: context ].
		list := self displayListOfExtent: case extent drawnWith: draw.
		(VGTiledFillRasteriser supports: list) ifTrue: [
			aBlock
				value: case
				value: draw
				value: list entries ] ]
]

{ #category : 'fixtures' }
VGTiledFrameTestCase >> tiledFormOfExtent: anExtent drawnWith: aBlock [
	"The same frame drawn through the tiles. The display list is read before anything drains it and
	 reset afterwards, so that reading the pixels does not replay the frame on the software
	 backend as well."

	| surface |
	surface := VGCairoImageSurface extent: anExtent.
	aBlock value: surface newContext.
	(VGTiledFillRasteriser of: surface displayList extent: anExtent) drawOn: surface.
	surface displayList reset.
	^ surface asForm
]

{ #category : 'fixtures' }
VGTiledFrameTestCase >> tiledFormOfExtent: anExtent tileExtent: aTileExtent drawnWith: aBlock [
	"The same frame over a grid of that tile size. A tile owns its pixels alone, so the size of a
	 tile may change how the work is cut up and may not change one byte of the result."

	| surface |
	surface := VGCairoImageSurface extent: anExtent.
	aBlock value: surface newContext.
	(VGTiledFillRasteriser
		 of: surface displayList
		 grid: (VGTileGrid extent: anExtent tileExtent: aTileExtent)) drawOn: surface.
	surface displayList reset.
	^ surface asForm
]
