"
I am a blit rewritten as a fill, which is how the tiled rasteriser draws one. A blit carries a mask surface and no path, and the software backend draws it by walking the coverage of its own clip narrowed to the rectangle of that mask and scaling that coverage by the alpha of the mask pixel by pixel. That walk is a fill: the clip answers it for a path that is the rectangle of its extents, which is what VGClip >> coverageRasteriser builds. So my segments are that rectangle, my clip is the narrowed clip, and I carry the alpha of the mask over my rectangle as one byte a pixel, flattened once when I am built rather than sampled once a tile. My rectangle and my bytes are what the encoding writes into the mask buffers and what the kernel reads out of them, so a device and the two paths on the host all scale one coverage by one byte.
"
Class {
	#name : 'VGMaskedFillEntry',
	#superclass : 'VGFillEntry',
	#instVars : [
		'maskRectangle',
		'maskBytes'
	],
	#category : 'VectorGraphics-Vulkan-Tiles',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Tiles'
}

{ #category : 'instance creation' }
VGMaskedFillEntry class >> bytesOfMask: aMask over: aRectangle [
	"The alpha of every pixel of that rectangle, row by row from the top left, asked of the mask
	 in one go. The rectangle is in whole pixels, because it is the extents of a clip; the mask
	 builds the whole run with the work that does not change from pixel to pixel done once."

	^ aMask alphaBytesOver: aRectangle
]

{ #category : 'instance creation' }
VGMaskedFillEntry class >> fill: aFillEntry bytes: aByteArray over: aRectangle [
	"The fill that stands for a blit, carrying the alpha of its mask over that rectangle already
	 flattened: one byte a pixel, row by row from the top left, which is the layout the mask
	 buffer of an encoding holds and the kernel indexes into."

	^ (self
		   segments: aFillEntry segments
		   paint: aFillEntry paint
		   clip: aFillEntry clip
		   operator: aFillEntry operator)
		  setMaskRectangle: aRectangle bytes: aByteArray;
		  yourself
]

{ #category : 'instance creation' }
VGMaskedFillEntry class >> fill: aFillEntry sampling: aMask over: aRectangle [
	"The same, built by asking a mask surface for the alpha of every pixel of that rectangle.
	 The sampling happens once, here, because a blit reaches as many tiles as its rectangle
	 spans and a mask read once a tile would read the same byte once a tile."

	^ self
		  fill: aFillEntry
		  bytes: (self bytesOfMask: aMask over: aRectangle)
		  over: aRectangle
]

{ #category : 'inspector' }
VGMaskedFillEntry >> inspectorMask: aBuilder [
	<inspectorPresentationOrder: 20 title: 'Mask'>
	"The alpha I carry, row by row over my own rectangle, read through the very message the
	 rasteriser reads it with. The column before my rectangle and the column after it are shown
	 beside each row, because what I answer outside my rectangle is full alpha and not nothing,
	 and a reader who does not expect that would read the kernel wrongly."

	^ aBuilder newTable
		  addColumn: (SpStringTableColumn
				   title: 'Row'
				   evaluated: [ :each | (each at: 1) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Before'
				   evaluated: [ :each | (each at: 2) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Bytes'
				   evaluated: [ :each | (each at: 3) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'After'
				   evaluated: [ :each | (each at: 4) printString ]);
		  items: self maskRows;
		  yourself
]

{ #category : 'inspector' }
VGMaskedFillEntry >> inspectorMaskContext: aContext [
	aContext active: maskRectangle isNotNil
]

{ #category : 'inspector' }
VGMaskedFillEntry >> maskRows [
	"One row of my rectangle a row, with the byte I answer just outside each end of it. Every
	 byte is asked of tiledMaskByteAtX:y: rather than read out of my bytes, so the view cannot
	 drift from what the rasteriser sees."

	^ (maskRectangle top to: maskRectangle bottom - 1) collect: [ :y |
		  {
			  y.
			  (self tiledMaskByteAtX: maskRectangle left - 1 y: y).
			  ((maskRectangle left to: maskRectangle right - 1) collect: [ :x |
				   self tiledMaskByteAtX: x y: y ]).
			  (self tiledMaskByteAtX: maskRectangle right y: y) } ]
]

{ #category : 'printing' }
VGMaskedFillEntry >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPut: $(;
		print: maskRectangle;
		nextPutAll: ', ';
		print: operator;
		nextPut: $)
]

{ #category : 'draining' }
VGMaskedFillEntry >> replayOn: aBackend [
	"I am a blit rewritten as a fill for the tiled rasteriser, and my mask is already flattened
	 to the pixels of my rectangle. Replaying me would draw my clip rectangle and lose that
	 mask, so the blit I was made from is what a backend replays."

	self shouldNotImplement
]

{ #category : 'initialization' }
VGMaskedFillEntry >> setMaskRectangle: aRectangle bytes: aByteArray [
	maskRectangle := aRectangle.
	maskBytes := aByteArray
]

{ #category : 'drawing' }
VGMaskedFillEntry >> tiledMaskByteAtX: anX y: aRow [
	"The alpha of my mask at that device pixel, which the rasteriser scales the coverage of my
	 fill by. Outside my rectangle I answer full alpha and not nothing, because my coverage is
	 zero at every pixel outside it: my clip is narrowed to that rectangle and my path is the
	 rectangle itself, so a byte answered there is scaled into nothing either way, and the
	 kernel answers full alpha there too rather than branch on the kind of an entry."

	(maskRectangle containsPoint: anX @ aRow) ifFalse: [
		^ VGTiledFillEncoding fullAlphaByte ].
	^ maskBytes at:
		  (aRow - maskRectangle top) * maskRectangle width + anX
		  - maskRectangle left + 1
]

{ #category : 'accessing' }
VGMaskedFillEntry >> tiledMaskBytes [
	^ maskBytes
]

{ #category : 'accessing' }
VGMaskedFillEntry >> tiledMaskRectangle [
	^ maskRectangle
]
