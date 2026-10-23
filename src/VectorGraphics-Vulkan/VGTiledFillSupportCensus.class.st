"
I count what the tiled fill rasteriser can draw of a recorded frame, entry by entry, and why it refuses the rest.
The frame is the one unit 1.11 profiles and VGTileBinningCensus reads: eight hundred by six hundred, drawn through the Bloc renderer, with gradients, strokes, glyphs and blits in it.
VGTiledFillRasteriser class >> supportsEntry: decides, and reasonFor: names the clause of that predicate the entry fails first, so the two cannot drift apart: a test requires the supported reason of exactly the entries the rasteriser accepts.
Failover is a whole frame at a time, so one refused entry sends the frame to software. The pixel counts say how much of the frame sits behind each refusal, which is what decides whether the next kernel of the plan is worth building before the capability a real frame needs.
"
Class {
	#name : 'VGTiledFillSupportCensus',
	#superclass : 'Object',
	#instVars : [
		'frameName',
		'entries'
	],
	#category : 'VectorGraphics-Vulkan-Tiles',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Tiles'
}

{ #category : 'instance creation' }
VGTiledFillSupportCensus class >> of: aCollectionOfEntries named: aString [
	^ self new setEntries: aCollectionOfEntries named: aString
]

{ #category : 'instance creation' }
VGTiledFillSupportCensus class >> onTheReferenceFrame [
	"The frame unit 1.11 profiles, drawn through the Bloc renderer and recorded rather than
	 rasterised: eight hundred by six hundred, with gradients, strokes, glyphs and blits in it,
	 which is the frame a backend is really asked to draw.
	 The entries are copied out of the display list before the surface is flushed, because
	 draining a frame resets its list."

	| profile scene canvas surface census |
	profile := VGFrameProfile new.
	scene := profile sceneForRendererClass: VGRenderer.
	canvas := profile newCanvas.
	scene aeFullDrawOn: canvas.
	surface := canvas privateAeCairoSurface.
	census := self
		          of: surface displayList entries asArray
		          named: VGTileBinningCensus referenceFrameName.
	surface flush.
	^ census
]

{ #category : 'accessing' }
VGTiledFillSupportCensus class >> refusalReasons [
	"One reason for each clause of VGTiledFillRasteriser class >> supportsEntry:, in the order
	 that predicate asks them. An entry is counted under the first clause it fails, so the
	 reasons partition the entries and their counts add up to the frame."

	^ #( #notAFillOrABlit #paintNotSupported #clipNotRectangular
	     #operatorNotSupported )
]

{ #category : 'constants' }
VGTiledFillSupportCensus class >> supportedReason [
	"What an entry the device draws is counted under."

	^ #supported
]

{ #category : 'counting' }
VGTiledFillSupportCensus >> countByReason [
	"How many entries of the frame fall under each reason. Only the reasons the frame really
	 gives are keys, so a frame the device draws whole answers one entry alone."

	| counts |
	counts := Dictionary new.
	entries do: [ :entry |
		| reason |
		reason := self reasonFor: entry.
		counts at: reason put: (counts at: reason ifAbsent: [ 0 ]) + 1 ].
	^ counts
]

{ #category : 'accessing' }
VGTiledFillSupportCensus >> entries [
	"The entries of the frame, in the order they were drawn."

	^ entries
]

{ #category : 'reporting' }
VGTiledFillSupportCensus >> entryRows [
	"One row an entry, in the order the frame drew them: the index, the class of the entry, the
	 reason and the pixels its box reaches. The index is carried because the order is what
	 compositing depends on and a refused entry in the middle of a frame cannot be left out of
	 one."

	^ (1 to: entries size) collect: [ :index |
		  | entry |
		  entry := entries at: index.
		  {
			  index.
			  entry class name.
			  (self reasonFor: entry).
			  (self pixelsOf: entry) } ]
]

{ #category : 'accessing' }
VGTiledFillSupportCensus >> frameName [
	^ frameName
]

{ #category : 'inspector' }
VGTiledFillSupportCensus >> inspectorEntries: aBuilder [
	<inspectorPresentationOrder: 20 title: 'Entries'>
	"Every entry of the frame in the order it was drawn, with the reason it carries. A refusal in
	 the middle of a frame is what failover costs, so the order is shown and not only the totals."

	^ aBuilder newTable
		  items: self entryRows;
		  addColumn:
			  (SpStringTableColumn
				   title: 'Index'
				   evaluated: [ :each | (each at: 1) printString ]);
		  addColumn:
			  (SpStringTableColumn
				   title: 'Entry'
				   evaluated: [ :each | (each at: 2) asString ]);
		  addColumn:
			  (SpStringTableColumn
				   title: 'Reason'
				   evaluated: [ :each | (each at: 3) asString ]);
		  addColumn:
			  (SpStringTableColumn
				   title: 'Pixels'
				   evaluated: [ :each | (each at: 4) printString ]);
		  yourself
]

{ #category : 'inspector' }
VGTiledFillSupportCensus >> inspectorEntriesContext: aContext [
	"A census with no entries has none to list."

	aContext active: (entries isNotNil and: [ entries isNotEmpty ])
]

{ #category : 'inspector' }
VGTiledFillSupportCensus >> inspectorReasons: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Reasons'>
	"What the device draws of this frame and what refuses it, one row a reason. Every number is
	 read from the report, which asks the rasteriser about the live entries, so the tab cannot
	 claim a capability the code does not have."

	^ aBuilder newTable
		  items: self reportRows;
		  addColumn:
			  (SpStringTableColumn
				   title: 'Reason'
				   evaluated: [ :each | (each at: 1) asString ]);
		  addColumn: ((SpStringTableColumn
				    title: 'Entries'
				    evaluated: [ :each | (each at: 2) printString ])
				   beSortable;
				   yourself);
		  addColumn: ((SpStringTableColumn
				    title: 'Pixels'
				    evaluated: [ :each | (each at: 3) printString ])
				   beSortable;
				   yourself);
		  yourself
]

{ #category : 'inspector' }
VGTiledFillSupportCensus >> inspectorReasonsContext: aContext [
	"A census with no entries has nothing to apportion."

	aContext active: (entries isNotNil and: [ entries isNotEmpty ])
]

{ #category : 'counting' }
VGTiledFillSupportCensus >> isFrameSupported [
	"Whether the device could draw this frame at all. Failover is a whole frame at a time, so one
	 refused entry is enough to send every entry of it to software. The rasteriser is asked the
	 way the backend asks it, and I answer entries, which is all supports: reads of a frame."

	^ VGTiledFillRasteriser supports: self
]

{ #category : 'counting' }
VGTiledFillSupportCensus >> pixelsByReason [
	"How many pixels of the frame the entries of each reason can reach. Entries overlap, so the
	 sum is larger than the frame; what the number is read for is the share one refusal carries
	 against another."

	| pixels |
	pixels := Dictionary new.
	entries do: [ :entry |
		| reason |
		reason := self reasonFor: entry.
		pixels
			at: reason
			put: (pixels at: reason ifAbsent: [ 0 ]) + (self pixelsOf: entry) ].
	^ pixels
]

{ #category : 'counting' }
VGTiledFillSupportCensus >> pixelsOf: anEntry [
	"How much of the frame the entry can reach, which is the area of the box the binning reads.
	 It is the box and not the shape inside it, because a tile the box touches is dispatched
	 whatever the shape does there, and it is rounded to whole pixels because a box in device
	 space carries fractions from a transform."

	^ anEntry boundingBox area rounded
]

{ #category : 'printing' }
VGTiledFillSupportCensus >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPut: $(;
		nextPutAll: frameName asString;
		nextPutAll: ', ';
		print: self supportedCount;
		nextPut: $/;
		print: entries size;
		nextPutAll: ' supported)'
]

{ #category : 'accessing' }
VGTiledFillSupportCensus >> reasonFor: anEntry [
	"The clause of the rasteriser predicate this entry fails first, or the supported reason where
	 it fails none. The clauses are asked here in the order supportsEntry: asks them, and each
	 one is asked of the rasteriser itself rather than restated, so a subset that widens is
	 reported by this census on the same day."

	(VGTiledFillRasteriser supportsKindOf: anEntry) ifFalse: [
		^ #notAFillOrABlit ].
	(VGTiledFillRasteriser supportsPaint: anEntry paint) ifFalse: [
		^ #paintNotSupported ].
	anEntry clip isRectangular ifFalse: [ ^ #clipNotRectangular ].
	(VGTiledFillRasteriser supportedOperators includes: anEntry operator)
		ifFalse: [ ^ #operatorNotSupported ].
	^ self class supportedReason
]

{ #category : 'counting' }
VGTiledFillSupportCensus >> refusedCount [
	^ entries size - self supportedCount
]

{ #category : 'reporting' }
VGTiledFillSupportCensus >> reportRows [
	"One row a reason, ordered as the predicate asks its clauses and the supported entries first,
	 so the view and the printed form read one report. Each row carries the reason, how many
	 entries fall under it and how many pixels of the frame they can reach."

	| rows counts pixels |
	counts := self countByReason.
	pixels := self pixelsByReason.
	rows := OrderedCollection new.
	(Array with: self class supportedReason)
	, self class refusalReasons do: [ :reason |
		(counts includesKey: reason) ifTrue: [
			rows add: {
					reason.
					(counts at: reason).
					(pixels at: reason) } ] ].
	^ rows asArray
]

{ #category : 'initialization' }
VGTiledFillSupportCensus >> setEntries: aCollectionOfEntries named: aString [
	entries := aCollectionOfEntries.
	frameName := aString
]

{ #category : 'counting' }
VGTiledFillSupportCensus >> supportedCount [
	^ entries count: [ :each | VGTiledFillRasteriser supportsEntry: each ]
]
