"
One line of the parity floor of unit 3.13: the reference frame with one part of it left out, at one extent, measured on both kits. I hold a `VGStageTimings` a kit, so the floor of any drawing phase can be read off me, and `recordFloorOf:` names the one the verdict is about.

`variant` is the part left out, by the name `VGFrameDeviceBenchmark class >> drawReferenceOn:using:recordingInto:without:` knows; `#whole` leaves nothing out, which is the row every other row is subtracted from.
"
Class {
	#name : 'VGFrameRecordComparisonRow',
	#superclass : 'Object',
	#instVars : [
		'variant',
		'extent',
		'ourTimings',
		'cairoTimings',
		'wholeRow'
	],
	#category : 'VectorGraphics-Benchmarks-Frames',
	#package : 'VectorGraphics-Benchmarks',
	#tag : 'Frames'
}

{ #category : 'constants' }
VGFrameRecordComparisonRow class >> recordStageName [
	"The phase the verdict of unit 3.13 is about: the entries recorded into the display list on
	 my side, and the drawing itself on Cairo's. One of the phases
	 VGFrameDeviceBenchmark class >> drawingStageNames names."
	^ #record
]

{ #category : 'constants' }
VGFrameRecordComparisonRow class >> sceneStageName [
	"The phase both kits pay alike: the layout of the scene, where the text is measured. It is
	 quoted beside the recording because a cost both sides pay is not part of the gap between
	 them."
	^ #scene
]

{ #category : 'instance creation' }
VGFrameRecordComparisonRow class >> variant: aSymbol extent: aPoint [
	^ self new
		  setVariant: aSymbol extent: aPoint;
		  yourself
]

{ #category : 'constants' }
VGFrameRecordComparisonRow class >> wholeFrameName [
	"The name of the variant that leaves nothing out. It is not a part of a frame, so it never
	 reaches the drawing: partLeftOut answers nil for it."
	^ #whole
]

{ #category : 'accessing' }
VGFrameRecordComparisonRow >> cairoFloorOf: aStageName [
	"The fastest pass of that drawing phase on Cairo's side, in milliseconds, or nil where the
	 phase was not measured."
	^ cairoTimings floorOf: aStageName
]

{ #category : 'accessing' }
VGFrameRecordComparisonRow >> cairoPartCost [
	"What the same part costs Cairo, in milliseconds. nil for the whole frame."
	wholeRow ifNil: [ ^ nil ].
	^ wholeRow cairoRecordFloor - self cairoRecordFloor
]

{ #category : 'printing' }
VGFrameRecordComparisonRow >> cairoPartCostString [
	^ self millisecondStringOf: self cairoPartCost
]

{ #category : 'accessing' }
VGFrameRecordComparisonRow >> cairoRecordFloor [
	"The fastest pass of Cairo drawing this variant, in milliseconds."
	^ self cairoFloorOf: self class recordStageName
]

{ #category : 'printing' }
VGFrameRecordComparisonRow >> cairoRecordFloorString [
	^ self millisecondStringOf: self cairoRecordFloor
]

{ #category : 'accessing' }
VGFrameRecordComparisonRow >> extent [
	^ extent
]

{ #category : 'measuring' }
VGFrameRecordComparisonRow >> measurePass: anIndex [
	"Both kits, once each. Which of them goes first alternates by pass, so neither kit is
	 always the one measured on the heap the other had just grown."
	| ours |
	ours := VGFrameDrawingKit ours.
	anIndex odd
		ifTrue: [
			self recordWith: ours into: ourTimings.
			self recordWith: ours counterpart into: cairoTimings ]
		ifFalse: [
			self recordWith: ours counterpart into: cairoTimings.
			self recordWith: ours into: ourTimings ]
]

{ #category : 'printing' }
VGFrameRecordComparisonRow >> millisecondStringOf: aNumberOrNil [
	"A floor as a report reads it, or a dash where the phase was measured once or not at all."
	aNumberOrNil ifNil: [ ^ '-' ].
	^ ourTimings millisecondStringFor: aNumberOrNil
]

{ #category : 'accessing' }
VGFrameRecordComparisonRow >> ourFloorOf: aStageName [
	"The fastest pass of that drawing phase on my side, in milliseconds, or nil where the phase
	 was not measured. The cheap phases are there too: unit 3.13 reads the scene phase beside
	 the recording, because a layout both kits pay is not part of the gap."
	^ ourTimings floorOf: aStageName
]

{ #category : 'accessing' }
VGFrameRecordComparisonRow >> ourPartCost [
	"What the part this variant leaves out costs my recording, in milliseconds: the whole frame
	 less this variant. nil for the whole frame, which leaves nothing out."
	wholeRow ifNil: [ ^ nil ].
	^ wholeRow ourRecordFloor - self ourRecordFloor
]

{ #category : 'printing' }
VGFrameRecordComparisonRow >> ourPartCostString [
	^ self millisecondStringOf: self ourPartCost
]

{ #category : 'accessing' }
VGFrameRecordComparisonRow >> ourRecordFloor [
	"The fastest pass of my own recording of this variant, in milliseconds."
	^ self ourFloorOf: self class recordStageName
]

{ #category : 'printing' }
VGFrameRecordComparisonRow >> ourRecordFloorString [
	^ self millisecondStringOf: self ourRecordFloor
]

{ #category : 'accessing' }
VGFrameRecordComparisonRow >> partLeftOut [
	"The part of the frame this variant leaves out, as the drawing names it, or nil where
	 nothing is left out. #whole is a name of this comparison and not of a part, so it must not
	 reach the drawing."
	variant = self class wholeFrameName ifTrue: [ ^ nil ].
	^ variant
]

{ #category : 'printing' }
VGFrameRecordComparisonRow >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: ' without ';
		nextPutAll: variant asString;
		nextPutAll: ' at ';
		print: extent;
		nextPutAll: ' ours ';
		nextPutAll: (self millisecondStringOf: self ourRecordFloor);
		nextPutAll: ' cairo ';
		nextPutAll: (self millisecondStringOf: self cairoRecordFloor)
]

{ #category : 'accessing' }
VGFrameRecordComparisonRow >> ratio [
	"How many times my recording of this variant costs what Cairo pays to draw the same
	 picture. The one figure the verdict of unit 3.13 is read off."
	^ self ourRecordFloor / self cairoRecordFloor
]

{ #category : 'printing' }
VGFrameRecordComparisonRow >> ratioString [
	"The verdict of one variant, in times rather than in milliseconds, as unit 7.6 prints its
	 own."
	self ourRecordFloor ifNil: [ ^ '-' ].
	self cairoRecordFloor ifNil: [ ^ '-' ].
	^ (self ratio asFloat printShowingDecimalPlaces: 2) , ' times'
]

{ #category : 'measuring' }
VGFrameRecordComparisonRow >> recordWith: aKit into: aTimings [
	"One pass of this variant on that kit. The surface is built fresh and outside the timing:
	 ours records a display list, so a surface drawn on twice would already hold the entries of
	 the pass before it."
	| surface |
	surface := aKit surfaceOfExtent: extent.
	VGFrameDeviceBenchmark
		drawReferenceOn: surface newContext
		using: aKit
		recordingInto: aTimings
		without: self partLeftOut
]

{ #category : 'initialization' }
VGFrameRecordComparisonRow >> setVariant: aSymbol extent: aPoint [
	variant := aSymbol.
	extent := aPoint.
	ourTimings := VGStageTimings new.
	cairoTimings := VGStageTimings new
]

{ #category : 'initialization' }
VGFrameRecordComparisonRow >> setWholeRow: aRow [
	"The row of the same extent that leaves nothing out, which is the row this one is
	 subtracted from to price the part it is missing. The whole row itself keeps nil: there is
	 nothing for it to be subtracted from."
	wholeRow := aRow
]

{ #category : 'accessing' }
VGFrameRecordComparisonRow >> variant [
	^ variant
]

{ #category : 'accessing' }
VGFrameRecordComparisonRow >> wholeRow [
	"The row this one is subtracted from, or nil for the whole frame itself."
	^ wholeRow
]
