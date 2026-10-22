"
I bin a collection of frames and report what the tiles hold.

I am the gate of unit 2.2 and the measurement the default tile size is chosen by. `overCases:` draws
every case it is handed, bins it and counts the tiles it touches; a case is anything answering a
name, an extent and `drawOn:`, which is the protocol of a conformance case. The cases are handed to
me rather than fetched, because the conformance corpus lives in a test package and this one may not
name it — `VGTileBinningTest` passes the corpus in.

`overTheReferenceFrame` bins the eight hundred by six hundred frame unit 1.11 profiles, which is the
frame that decides the tile size: a conformance case is sixty-four pixels square and touches nearly
every tile of its own grid whatever the size, so the corpus says nothing about occupancy.

`strayPixelCount` is the honest one: for each frame I compare the drawn pixels against a surface
nothing has drawn on, and count the pixels that changed and lie in no tile I touched. It reads
pixels and never a bounding box, so a box that is too small cannot hide from it. A new ARGB32
surface is not all zero — its pixels read as transparent white — which is why the comparison is
against a blank form and not against zero.

`referenceOccupancyByTileExtent` runs the reference frame at each of `tileExtentsMeasured`, and
`VGTileGrid class >> defaultTileExtent` quotes its numbers. Every measurement here draws on the
software path, so it is slow and belongs in an example rather than in a test.
"
Class {
	#name : 'VGTileBinningCensus',
	#superclass : 'Object',
	#instVars : [
		'tileExtent',
		'rows'
	],
	#category : 'VectorGraphics-Vulkan-Tiles',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Tiles'
}

{ #category : 'instance creation' }
VGTileBinningCensus class >> overCases: aCollection [
	^ self overCases: aCollection withTileExtent: VGTileGrid defaultTileExtent
]

{ #category : 'instance creation' }
VGTileBinningCensus class >> overCases: aCollection withTileExtent: aTileExtent [
	"The cases are passed in rather than fetched, because the conformance corpus lives in a test
	 package and this class does not: a code package may not name one."

	^ self new runCases: aCollection withTileExtent: aTileExtent
]

{ #category : 'instance creation' }
VGTileBinningCensus class >> overTheReferenceFrame [
	^ self overTheReferenceFrameWithTileExtent: VGTileGrid defaultTileExtent
]

{ #category : 'instance creation' }
VGTileBinningCensus class >> overTheReferenceFrameWithTileExtent: aTileExtent [
	^ self new runReferenceFrameWithTileExtent: aTileExtent
]

{ #category : 'constants' }
VGTileBinningCensus class >> referenceFrameName [
	^ 'reference-frame'
]

{ #category : 'measuring' }
VGTileBinningCensus class >> referenceOccupancyByTileExtent [
	"The measurement VGTileGrid class >> defaultTileExtent is chosen by: the reference frame
	 binned at each of the three tile sizes. It draws an eight hundred by six hundred frame on the
	 software path once per size, so it belongs in an example and not in a test."

	^ self tileExtentsMeasured
		  collect: [ :each | each -> (self overTheReferenceFrameWithTileExtent: each) ]
]

{ #category : 'constants' }
VGTileBinningCensus class >> tileExtentsMeasured [
	"The three sizes the choice of defaultTileExtent was made between: half, the chosen one and
	 double."

	^ { 8 @ 8. 16 @ 16. 32 @ 32 }
]

{ #category : 'running' }
VGTileBinningCensus >> blankFormOfExtent: anExtent [
	"A surface of the same size that nothing has drawn on. A new ARGB32 surface is not all zero —
	 its pixels read as transparent white — so a written pixel is one that differs from this, and
	 not one that differs from zero."

	^ (VGCairoImageSurface extent: anExtent) asForm
]

{ #category : 'accessing' }
VGTileBinningCensus >> entryGrowth [
	"Entries counted once per tile, over entries drawn. One means no entry spans a tile boundary;
	 a large number means the tiles are small for this corpus."

	| drawn |
	drawn := rows inject: 0 into: [ :sum :each | sum + each entries ].
	drawn isZero ifTrue: [ ^ 0 ].
	^ ((rows inject: 0 into: [ :sum :each | sum + each binnedEntries ]) / drawn)
		  asFloat
]

{ #category : 'inspector' }
VGTileBinningCensus >> inspectorCases: aBuilder [
	"A line per frame, which is the count of tiles touched per case the gate of unit 2.2 asks
	 for."

	<inspectorPresentationOrder: 1 title: 'Cases'>
	^ aBuilder newTable
		  addColumn:
			  (SpStringTableColumn title: 'Case' evaluated: [ :each | each name ]);
		  addColumn: (SpStringTableColumn
				   title: 'Entries'
				   evaluated: [ :each | each entries printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Tiles touched'
				   evaluated: [ :each |
					   each tilesTouched printString , ' of '
					   , each tilesTotal printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Of frame'
				   evaluated: [ :each | each tilesTouchedPercent rounded printString , '%' ]);
		  addColumn: (SpStringTableColumn
				   title: 'Binned'
				   evaluated: [ :each | each binnedEntries printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Busiest tile'
				   evaluated: [ :each | each maxEntriesInATile printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Stray pixels'
				   evaluated: [ :each | each strayPixelCount printString ]);
		  items: rows;
		  yourself
]

{ #category : 'inspector' }
VGTileBinningCensus >> inspectorCasesContext: aContext [
	aContext active: rows isNotNil
]

{ #category : 'inspector' }
VGTileBinningCensus >> inspectorCensus: aBuilder [
	<inspectorPresentationOrder: 2 title: 'Census'>
	^ aBuilder newTable
		  addColumn: (SpStringTableColumn title: 'What' evaluated: [ :each | each key ]);
		  addColumn:
			  (SpStringTableColumn title: 'Value' evaluated: [ :each | each value ]);
		  items: self reportRows;
		  yourself
]

{ #category : 'inspector' }
VGTileBinningCensus >> inspectorCensusContext: aContext [
	aContext active: rows isNotNil
]

{ #category : 'accessing' }
VGTileBinningCensus >> maxEntriesInATile [
	^ rows inject: 0 into: [ :most :each | most max: each maxEntriesInATile ]
]

{ #category : 'accessing' }
VGTileBinningCensus >> meanTilesTouchedPercent [
	"Averaged over the cases and not over the tiles, because the question is what a frame costs."

	rows isEmpty ifTrue: [ ^ 0 ].
	^ ((rows inject: 0 into: [ :sum :each | sum + each tilesTouchedPercent ])
	   / rows size) asFloat
]

{ #category : 'printing' }
VGTileBinningCensus >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPutAll: ' at ';
		print: tileExtent;
		nextPutAll: ': ';
		print: rows size;
		nextPutAll: ' cases, ';
		print: self strayPixelCount;
		nextPutAll: ' stray pixels'
]

{ #category : 'reporting' }
VGTileBinningCensus >> reportRows [
	^ {
		  ('tile' -> tileExtent printString).
		  ('frames' -> rows size printString).
		  ('tiles touched, mean'
		   -> (self meanTilesTouchedPercent rounded printString , '%')).
		  ('entry growth' -> ((self entryGrowth roundTo: 0.01) printString , 'x')).
		  ('busiest tile' -> self maxEntriesInATile printString).
		  ('stray pixels' -> self strayPixelCount printString) }
]

{ #category : 'running' }
VGTileBinningCensus >> rowFor: aCase [
	"The display list has to be read before the surface is flushed, because draining it resets it.
	 The pixels have to be read after, because that is when they are written."

	| surface binning |
	surface := VGCairoImageSurface extent: aCase extent.
	aCase drawOn: surface newContext.
	binning := VGTileBinning
		           of: surface displayList
		           grid: (VGTileGrid extent: aCase extent tileExtent: tileExtent).
	surface flush.
	^ self rowNamed: aCase name binning: binning form: surface asForm
]

{ #category : 'running' }
VGTileBinningCensus >> rowForReferenceFrame [
	"The frame unit 1.11 profiles, which is the frame the tile size is really chosen for: the
	 conformance cases are sixty-four pixels square and nearly every tile of such a case is
	 touched whatever the tile size, so they say nothing about occupancy. This one is eight
	 hundred by six hundred and carries gradients, strokes, glyphs and blits."

	| profile scene canvas surface binning |
	profile := VGFrameProfile new.
	scene := profile sceneForRendererClass: VGRenderer.
	canvas := profile newCanvas.
	scene aeFullDrawOn: canvas.
	surface := canvas privateAeCairoSurface.
	binning := VGTileBinning
		           of: surface displayList
		           grid: (VGTileGrid extent: profile extent tileExtent: tileExtent).
	surface flush.
	^ self
		  rowNamed: self class referenceFrameName
		  binning: binning
		  form: canvas asForm
]

{ #category : 'running' }
VGTileBinningCensus >> rowNamed: aName binning: aBinning form: aForm [
	^ VGTileBinningCensusRow
		  name: aName
		  binning: aBinning
		  strayPixelCount: (self
				   strayPixelsOf: aForm
				   against: (self blankFormOfExtent: aForm extent)
				   binnedBy: aBinning)
]

{ #category : 'accessing' }
VGTileBinningCensus >> rows [
	^ rows
]

{ #category : 'running' }
VGTileBinningCensus >> runCases: aCollection withTileExtent: aTileExtent [
	"A case is anything that answers a name, an extent and drawOn:, which is the protocol of a
	 conformance case."

	tileExtent := aTileExtent.
	rows := aCollection collect: [ :each | self rowFor: each ].
	^ self
]

{ #category : 'running' }
VGTileBinningCensus >> runReferenceFrameWithTileExtent: aTileExtent [
	tileExtent := aTileExtent.
	rows := { self rowForReferenceFrame }.
	^ self
]

{ #category : 'accessing' }
VGTileBinningCensus >> strayPixelCount [
	^ rows inject: 0 into: [ :sum :each | sum + each strayPixelCount ]
]

{ #category : 'running' }
VGTileBinningCensus >> strayPixelsOf: aForm against: aBlankForm binnedBy: aBinning [
	"Pixels the frame really changed that lie in no tile the binning touched. This asks the pixels
	 and never a bounding box, which is the whole point of the count: a box that is too small
	 cannot hide here."

	| touched grid bits blank width stray |
	grid := aBinning grid.
	touched := aBinning touchedTileIndexes asSet.
	bits := aForm bits.
	blank := aBlankForm bits.
	width := aForm width.
	stray := 0.
	0 to: aForm height - 1 do: [ :y |
		| rowStart row |
		rowStart := y * width.
		row := y // grid tileExtent y.
		0 to: width - 1 do: [ :x |
			| at |
			at := rowStart + x + 1.
			(bits at: at) = (blank at: at) ifFalse: [
				(touched includes:
					 (grid indexAtColumn: x // grid tileExtent x row: row)) ifFalse: [
					stray := stray + 1 ] ] ] ].
	^ stray
]

{ #category : 'accessing' }
VGTileBinningCensus >> tileExtent [
	^ tileExtent
]
