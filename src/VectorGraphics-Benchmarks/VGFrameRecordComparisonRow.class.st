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
		'wholeRow',
		'cairoSurface'
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
VGFrameRecordComparisonRow >> cairoKit [
	"The kit that draws as it is asked, which is the counterpart of mine."
	^ VGFrameDrawingKit ours counterpart
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
VGFrameRecordComparisonRow >> cairoSurface [
	"The one Cairo surface every pass of this row draws on, built the first time a pass asks
	 for it. A window has one surface for every frame it draws, and a fresh Cairo surface is
	 paged in by the drawing that first touches it: on this machine that first touch was
	 0.58 ms of a 1.47 ms frame at 800 by 600, which a second run of the same budget did not
	 pay. Measuring it once a pass would measure the operating system."
	^ cairoSurface ifNil: [
		  cairoSurface := self cairoKit surfaceOfExtent: extent ]
]

{ #category : 'accessing' }
VGFrameRecordComparisonRow >> extent [
	^ extent
]

{ #category : 'measuring' }
VGFrameRecordComparisonRow >> measureCairoPass [
	"One pass of Cairo's, on the one surface of this row."
	self
		recordWith: self cairoKit
		into: cairoTimings
		on: self cairoSurface
]

{ #category : 'measuring' }
VGFrameRecordComparisonRow >> measureOurPass [
	"One pass of mine, on a surface of its own: our recording appends to the display list of
	 the surface it draws on, so a surface kept would make every pass record against a longer
	 list than the pass before it. Building the surface is outside the timing, and our
	 recording touches no pixel of it, so the fresh pages a Cairo pass would pay for cost this
	 one nothing."
	| kit |
	kit := VGFrameDrawingKit ours.
	self
		recordWith: kit
		into: ourTimings
		on: (kit surfaceOfExtent: extent)
]

{ #category : 'measuring' }
VGFrameRecordComparisonRow >> measurePass: anIndex [
	"Both kits, once each. Which of them goes first alternates by pass, so neither kit is
	 always the one measured on the heap the other had just grown."
	anIndex odd
		ifTrue: [
			self measureOurPass.
			self measureCairoPass ]
		ifFalse: [
			self measureCairoPass.
			self measureOurPass ]
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
VGFrameRecordComparisonRow >> recordWith: aKit into: aTimings on: aSurface [
	"One pass of this variant on that kit, drawn on that surface."
	VGFrameDeviceBenchmark
		drawReferenceOn: aSurface newContext
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
