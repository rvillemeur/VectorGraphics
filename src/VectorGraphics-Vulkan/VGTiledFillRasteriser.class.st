"
One frame drawn tile by tile, the way the Vulkan kernel will draw it: the display list is binned by VGTileBinning, each tile is drawn on its own, and each pixel of a tile takes its coverage from VGTileCoverage, which sorts nothing and keeps no scratch buffer.

I am the algorithm without the device. Quantising, the paint and the operator are the format's and the operator's own methods, the ones the software backend sends, so what I have to prove is the tiling and the coverage and nothing else: my gate is that a frame drawn through me holds the same bytes as the same frame drawn by VGSoftwareBackend. I draw the subset the kernel will draw — a solid paint, a rectangular clip and a bounded operator — and VGTiledFillRasteriser class >> supports: says so.
"
Class {
	#name : 'VGTiledFillRasteriser',
	#superclass : 'Object',
	#instVars : [
		'binning'
	],
	#category : 'VectorGraphics-Vulkan-Tiles',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Tiles'
}

{ #category : 'instance creation' }
VGTiledFillRasteriser class >> of: aDisplayList extent: anExtent [
	"The frame of a surface of that extent, binned over a grid of the default tile size."

	^ self of: aDisplayList grid: (VGTileGrid extent: anExtent)
]

{ #category : 'instance creation' }
VGTiledFillRasteriser class >> of: aDisplayList grid: aGrid [
	^ self new setBinning: (VGTileBinning of: aDisplayList grid: aGrid)
]

{ #category : 'testing' }
VGTiledFillRasteriser class >> supportedOperators [
	"Each of the three has its own integer mix of source, mask and destination, and the kernel
	 will carry one branch for each. They are compared by value and not by identity, because
	 VGCairoOperator answers a fresh instance to every send of a name."

	^ {
		  VGCairoOperator over.
		  VGCairoOperator source.
		  VGCairoOperator clear }
]

{ #category : 'testing' }
VGTiledFillRasteriser class >> supports: aDisplayList [
	"The frames I can draw: fills of a solid paint inside a rectangular clip under one of the
	 three operators the fill cases of the conformance corpus ask for. Everything else — a
	 gradient, a surface or a mesh paint, a blit, a shaped clip, or an operator that writes where
	 no source covers — belongs to a later unit, and a backend that meets one owes
	 VGBackendFailure rather than a frame half drawn."

	^ aDisplayList entries allSatisfy: [ :each | self supportsEntry: each ]
]

{ #category : 'testing' }
VGTiledFillRasteriser class >> supportsEntry: anEntry [
	^ (anEntry isKindOf: VGFillEntry) and: [
		  anEntry paint isSolid and: [
			  anEntry clip isRectangular and: [
				  self supportedOperators includes: anEntry operator ] ] ]
]

{ #category : 'accessing' }
VGTiledFillRasteriser >> binning [
	^ binning
]

{ #category : 'drawing' }
VGTiledFillRasteriser >> draw: aCoverage atX: anX y: aRow on: aSurface [
	"Quantise the coverage, scale it by the fill's own alpha and composite — the three sends the
	 software backend makes, through the same format and the same operator, so the bytes can only
	 differ where the coverage does. A pixel no source covers is left alone, which the subset I
	 draw may do because every operator in it is bounded. The read is the primitive one: I am
	 called from inside the surface's own flush, and the public reader flushes before it answers."

	| entry format mask source |
	entry := aCoverage entry.
	format := aSurface format.
	mask := format
		        scaleByte: (format maskByteForCoverage: (aCoverage atX: anX row: aRow))
		        by: (format shortByteOf: entry segments alpha).
	mask > 0 ifFalse: [ ^ self ].
	source := entry operator
		          sourceFromPaint: entry paint
		          in: format
		          atX: anX
		          y: aRow.
	source ifNil: [ ^ self ].
	aSurface
		primitivePixelAtX: anX
		y: aRow
		put: (entry operator
				 composeSource: source
				 mask: mask
				 over: (aSurface primitivePixelAtX: anX y: aRow)
				 in: format)
]

{ #category : 'drawing' }
VGTiledFillRasteriser >> drawOn: aSurface [
	"Every tile the frame touches, in index order. A tile owes nothing to any other tile, which is
	 the whole point of the binning: on the device one workgroup will own one tile and one
	 invocation one pixel of it, and the order the tiles are drawn in will not be this one."

	binning touchedTileIndexes asSortedCollection do: [ :index |
		self drawTileAt: index on: aSurface ]
]

{ #category : 'drawing' }
VGTiledFillRasteriser >> drawTileAt: anIndex on: aSurface [
	"The entries of one tile in the order they were drawn, because compositing is not commutative,
	 and of each entry the pixels of the tile it can reach."

	| bounds |
	bounds := self grid boundsOfTileAt: anIndex.
	(binning entriesOfTileAt: anIndex) do: [ :each |
		| box coverage |
		box := bounds intersect: (self grid wholePixelsOf: each boundingBox).
		coverage := VGTileCoverage of: each.
		box top to: box bottom - 1 do: [ :y |
			box left to: box right - 1 do: [ :x |
				self
					draw: coverage
					atX: x
					y: y
					on: aSurface ] ] ]
]

{ #category : 'inspector' }
VGTiledFillRasteriser >> drawnForm [
	"My own drawing, on a fresh surface of the grid's extent. The entries carry their paint, their
	 clip and their operator, so a frame draws the same wherever it is drawn."

	| surface |
	surface := VGCairoImageSurface extent: self grid extent.
	self drawOn: surface.
	^ surface asForm
]

{ #category : 'accessing' }
VGTiledFillRasteriser >> grid [
	^ binning grid
]

{ #category : 'inspector' }
VGTiledFillRasteriser >> inspectorDrawing: aBuilder [
	<inspectorPresentationOrder: 11 title: 'Drawing'>
	"The frame I draw, drawn now into a surface of my own, so that opening this tab cannot write
	 one pixel of the surface the frame was recorded on."

	^ aBuilder newImage
		  image: self drawnForm;
		  yourself
]

{ #category : 'inspector' }
VGTiledFillRasteriser >> inspectorDrawingContext: aContext [
	aContext active: binning isNotNil
]

{ #category : 'inspector' }
VGTiledFillRasteriser >> inspectorTiles: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Tiles'>
	"Every tile the frame touches, with the entries binned into it and whether the subset I draw
	 holds each of them. The answer comes from supportsEntry: and not from a list written here."

	^ aBuilder newTable
		  addColumn: (SpStringTableColumn
				   title: 'Tile'
				   evaluated: [ :each | (each at: 1) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Bounds'
				   evaluated: [ :each | (each at: 2) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Entries'
				   evaluated: [ :each | (each at: 3) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'In the subset'
				   evaluated: [ :each | (each at: 4) printString ]);
		  items: self tileReport;
		  yourself
]

{ #category : 'inspector' }
VGTiledFillRasteriser >> inspectorTilesContext: aContext [
	aContext active: binning isNotNil
]

{ #category : 'printing' }
VGTiledFillRasteriser >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPut: $(;
		print: binning touchedTileCount;
		nextPutAll: ' tiles, ';
		print: binning binnedEntryCount;
		nextPutAll: ' entries)'
]

{ #category : 'initialization' }
VGTiledFillRasteriser >> setBinning: aBinning [
	binning := aBinning
]

{ #category : 'inspector' }
VGTiledFillRasteriser >> tileReport [
	"The touched tiles in the order I draw them."

	^ binning touchedTileIndexes asSortedCollection asArray collect: [ :index |
		  | entries |
		  entries := binning entriesOfTileAt: index.
		  {
			  index.
			  (self grid boundsOfTileAt: index).
			  entries size.
			  (entries allSatisfy: [ :each | self class supportsEntry: each ]) } ]
]
