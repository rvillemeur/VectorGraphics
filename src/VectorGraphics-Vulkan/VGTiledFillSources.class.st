"
The runs of source pixels of one frame.

A fill whose paint is a surface pattern samples that surface on the device, so its pixels travel
there as the words they are: one run an entry, end to end in the order the entries are written.
I hold where each run starts and how long it is, and I write the runs into the buffer the dispatch
uploads.
An entry that paints from no surface has a run of no pixels, and its offset is that of the entry
after it, which is one past the end of the buffer for the last entry of a frame: the kernel reads a
pixel only where the paint of the entry standing is a surface.
VGTiledFillEncoding asks me for the offsets it writes into each header and for the one write of the
whole buffer; which pixel a source carries is the surface's own to answer, asked pixel by pixel so
that a source nothing has drained yet is drained first.
"
Class {
	#name : 'VGTiledFillSources',
	#superclass : 'Object',
	#instVars : [
		'entries',
		'offsets'
	],
	#category : 'VectorGraphics-Vulkan-Tiles',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Tiles'
}

{ #category : 'instance creation' }
VGTiledFillSources class >> of: aCollection [
	"The source runs of those entries, in the order they are written."

	^ self new
		  setEntries: aCollection;
		  yourself
]

{ #category : 'counting' }
VGTiledFillSources class >> pixelCountOf: anEntry [
	"The pixels of the source surface this entry paints out of, which is none for every paint but
	 a surface. The extent is the surface's own and not the frame's: a source smaller than the
	 frame is what an extend mode is for, and a source larger than it is sampled where it is
	 asked for."

	| paint |
	paint := anEntry paint.
	(paint isKindOf: VGSurfacePaint) ifFalse: [ ^ 0 ].
	^ paint surface width * paint surface height
]

{ #category : 'constants' }
VGTiledFillSources class >> pixelsShownPerEntry [
	"How many pixels of a run a row of the Runs tab lists. A source of sixty-four by sixty-four
	 carries four thousand of them and a row of a table holds a few."

	^ 6
]

{ #category : 'inspecting' }
VGTiledFillSources >> inspectorRuns: aBuilder [
	<inspectorPresentationOrder: 1 title: 'Runs'>
	"The runs of source pixels as the device reads them: one row an entry, naming the extent of
	 its source, the offset its run starts at, its length and the first pixels of it. An entry
	 that paints from no surface has a run of none, and the entry after it starts where it does."

	^ aBuilder newTable
		  addColumn: (SpStringTableColumn
				   title: 'Entry'
				   evaluated: [ :each | (each at: 1) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Source'
				   evaluated: [ :each | (each at: 2) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Offset'
				   evaluated: [ :each | (each at: 3) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Pixels'
				   evaluated: [ :each | (each at: 4) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'First'
				   evaluated: [ :each | (each at: 5) printString ]);
		  items: self runRows;
		  yourself
]

{ #category : 'inspecting' }
VGTiledFillSources >> inspectorRunsContext: aContext [
	aContext active: entries isNotNil
]

{ #category : 'accessing' }
VGTiledFillSources >> offsets [
	"Where every entry's run of pixels starts, counted in pixels from the first pixel of the
	 buffer. It holds one number more than there are entries, the last being the total."

	^ offsets
]

{ #category : 'accessing' }
VGTiledFillSources >> pixelCount [
	"The pixels of every source of the frame together, which is the size of the buffer."

	^ offsets last
]

{ #category : 'printing' }
VGTiledFillSources >> printOn: aStream [
	"The entries and the pixels, which is what a frame of sources amounts to."

	super printOn: aStream.
	aStream
		nextPutAll: '(';
		print: entries size;
		nextPutAll: ' entries, ';
		print: self pixelCount;
		nextPutAll: ' pixels)'
]

{ #category : 'inspecting' }
VGTiledFillSources >> runRows [
	"One entry a row, with the extent of its source, where its run starts, how long it is and the
	 first pixels of it. The pixels are read out of a buffer I write here and not out of the
	 entries, so a run written at the wrong offset or packed to the wrong width shows as a row
	 whose pixels are not the pixels of its own source."

	| written |
	written := WordArray new: (self pixelCount max: 1).
	self writeInto: written.
	^ (1 to: entries size) collect: [ :index |
		  | paint count |
		  paint := (entries at: index) paint.
		  count := self class pixelCountOf: (entries at: index).
		  {
			  index.
			  ((paint isKindOf: VGSurfacePaint)
				   ifTrue: [ paint surface width @ paint surface height ]
				   ifFalse: [ 0 @ 0 ]).
			  (offsets at: index).
			  count.
			  ((1 to: (count min: self class pixelsShownPerEntry)) collect: [ :each |
				   (written at: (offsets at: index) + each) printStringHex ]) } ]
]

{ #category : 'initialization' }
VGTiledFillSources >> setEntries: aCollection [
	"The entries and the running total of their runs: one offset an entry and the total after
	 them, which is the size the buffer is allocated at."

	| total |
	entries := aCollection.
	offsets := Array new: aCollection size + 1.
	total := 0.
	aCollection withIndexDo: [ :each :index |
		offsets at: index put: total.
		total := total + (self class pixelCountOf: each) ].
	offsets at: aCollection size + 1 put: total
]

{ #category : 'writing' }
VGTiledFillSources >> writeInto: aWordArray [
	"Every run into that buffer at its own offset: the pixels of each source row by row from its
	 top left and packed to its own width, whatever the stride of that surface is. Each pixel is
	 asked of the surface itself, which drains a source that has not been drawn yet, exactly as
	 the software backend does when it samples one."

	entries withIndexDo: [ :each :index |
		| paint source offset |
		paint := each paint.
		(paint isKindOf: VGSurfacePaint) ifTrue: [
			source := paint surface.
			offset := offsets at: index.
			0 to: source height - 1 do: [ :y |
				0 to: source width - 1 do: [ :x |
					aWordArray
						at: offset + (y * source width) + x + 1
						put: (source pixelAtX: x y: y) ] ] ] ]
]
