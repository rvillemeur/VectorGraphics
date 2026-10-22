"
I am one frame's line in a tile binning census.

I hold the name of the frame, its extent, how many entries it drew, how many the tiles hold between
them, how many tiles were touched out of how many there are, the depth of the busiest tile, and the
count of pixels the frame changed outside every touched tile. That last number has to be zero.

I copy those numbers out of the binning rather than keep the binning, because a census over the
whole corpus would otherwise hold every display list and every surface of every case. See
`VGTileBinningCensus`, which builds me.
"
Class {
	#name : 'VGTileBinningCensusRow',
	#superclass : 'Object',
	#instVars : [
		'name',
		'extent',
		'entries',
		'binnedEntries',
		'tilesTouched',
		'tilesTotal',
		'maxEntriesInATile',
		'strayPixelCount'
	],
	#category : 'VectorGraphics-Vulkan-Tiles',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Tiles'
}

{ #category : 'instance creation' }
VGTileBinningCensusRow class >> name: aName binning: aBinning strayPixelCount: aCount [
	^ self new
		  setName: aName
		  binning: aBinning
		  strayPixelCount: aCount
]

{ #category : 'accessing' }
VGTileBinningCensusRow >> binnedEntries [
	^ binnedEntries
]

{ #category : 'accessing' }
VGTileBinningCensusRow >> entries [
	^ entries
]

{ #category : 'accessing' }
VGTileBinningCensusRow >> extent [
	^ extent
]

{ #category : 'accessing' }
VGTileBinningCensusRow >> maxEntriesInATile [
	^ maxEntriesInATile
]

{ #category : 'accessing' }
VGTileBinningCensusRow >> name [
	^ name
]

{ #category : 'printing' }
VGTileBinningCensusRow >> printOn: aStream [
	aStream
		nextPutAll: name;
		nextPutAll: ': ';
		print: entries;
		nextPutAll: ' entries over ';
		print: tilesTouched;
		nextPutAll: ' of ';
		print: tilesTotal;
		nextPutAll: ' tiles'
]

{ #category : 'initialization' }
VGTileBinningCensusRow >> setName: aName binning: aBinning strayPixelCount: aCount [
	"The numbers are copied out of the binning rather than the binning kept, because a census over
	 the corpus would otherwise hold every display list and every surface of every case."

	name := aName.
	extent := aBinning grid extent.
	entries := aBinning entries size.
	binnedEntries := aBinning binnedEntryCount.
	tilesTouched := aBinning touchedTileCount.
	tilesTotal := aBinning grid tileCount.
	maxEntriesInATile := aBinning maxEntriesInATile.
	strayPixelCount := aCount
]

{ #category : 'accessing' }
VGTileBinningCensusRow >> strayPixelCount [
	^ strayPixelCount
]

{ #category : 'accessing' }
VGTileBinningCensusRow >> tilesTotal [
	^ tilesTotal
]

{ #category : 'accessing' }
VGTileBinningCensusRow >> tilesTouched [
	^ tilesTouched
]

{ #category : 'accessing' }
VGTileBinningCensusRow >> tilesTouchedPercent [
	"How much of the frame a dispatch would have to cover. This is the number the tile size is
	 chosen by: a small shape in a large frame should answer a small percentage."

	tilesTotal isZero ifTrue: [ ^ 0 ].
	^ (tilesTouched / tilesTotal * 100) asFloat
]
