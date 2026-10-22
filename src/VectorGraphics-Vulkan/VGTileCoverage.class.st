"
The part of a pixel one recorded fill covers, found the way a kernel invocation can afford to find it: no sorted array of crossings and no scratch buffer, one scan of the edges for the winding at the left of the pixel and one more for each run after it.

VGRasteriser answers the same numbers for a whole row at once, and it is the oracle: I sum the same terms for a pixel in the same order over the fifteen sub-rows VGRasteriser samples, so the two answer the same float and not merely the same number. atX:row: is the whole of my interface; the rest is the walk.
"
Class {
	#name : 'VGTileCoverage',
	#superclass : 'Object',
	#instVars : [
		'entry',
		'scanner'
	],
	#category : 'VectorGraphics-Vulkan-Tiles',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Tiles'
}

{ #category : 'instance creation' }
VGTileCoverage class >> of: anEntry [
	"The coverage of one recorded fill. The fill rule and the antialiasing mode ride inside the
	 entry's segments, as they do everywhere else in this engine, and the clip is the entry's own."

	^ self new setEntry: anEntry
]

{ #category : 'coverage' }
VGTileCoverage >> aliasedSpanAtX: anX onSubRow: aSubRow do: aBlock [
	"Antialiasing off is one sample at the centre of the pixel row, and a pixel is inside when its
	 own centre is: the run is then the whole of the pixel the clip allows. Every sub-row of a row
	 answers this same run, which is how VGRasteriser sums fifteen of them and reaches one."

	(scanner isInside: (self windingUpTo: anX + 0.5 onSubRow: aSubRow floor + 0.5)) ifFalse: [
		^ self ].
	aBlock value: (self leftEdgeAtX: anX) value: (self rightEdgeAtX: anX)
]

{ #category : 'coverage' }
VGTileCoverage >> allowsRowAt: aRow [
	"The rows VGRasteriser visits at all: whole pixel rows, from the floor of the clip's top to
	 the ceiling of its bottom. A clip is trimmed horizontally on every sub-row and vertically by
	 whole rows alone, so a fractional clip edge is antialiased across but not down, and the
	 oracle here is the software backend rather than what one might expect of it."

	^ aRow >= self clip bounds top floor and: [
		  aRow < self clip bounds bottom ceiling ]
]

{ #category : 'coverage' }
VGTileCoverage >> atX: anX row: aRow [
	"The part of that pixel my fill covers, from zero to one. Every pixel of VGRasteriser holds
	 its own accumulator, so the terms of one pixel arrive there in the order they arrive here,
	 and the sum is the same float and not merely the same number."

	| samples coverage |
	(self allowsRowAt: aRow) ifFalse: [ ^ 0.0 ].
	samples := VGRasteriser samplesPerPixelRow.
	coverage := 0.0.
	0 to: samples - 1 do: [ :sample |
		self
			spansAtX: anX
			onSubRow: aRow + ((sample + 0.5) / samples)
			do: [ :from :to | coverage := coverage + (to - from) ] ].
	^ coverage / samples min: 1.0
]

{ #category : 'accessing' }
VGTileCoverage >> clip [
	^ entry clip
]

{ #category : 'inspector' }
VGTileCoverage >> coverageDrawing [
	"The coverage my walk really answers, one character a pixel over the whole pixels of my clip.
	 Nothing here states the rule a second time: every character comes from atX:row:."

	| ramp box |
	ramp := VGRasteriser new coverageRamp.
	box := self clip bounds.
	^ String streamContents: [ :stream |
		  box top floor to: box bottom ceiling - 1 do: [ :y |
			  stream
				  nextPutAll: (y printPaddedWith: Character space to: 4);
				  nextPutAll: ' |'.
			  box left floor to: box right ceiling - 1 do: [ :x |
				  stream nextPut:
						  (ramp at: ((self atX: x row: y) * (ramp size - 1)) rounded + 1) ].
			  stream
				  nextPut: $|;
				  cr ] ]
]

{ #category : 'winding' }
VGTileCoverage >> crossingAfter: anX onSubRow: aSubRow [
	"The nearest crossing strictly right of anX, or nil where my edges have none. One scan of the
	 edges, which is what a run costs here instead of a sorted array of every crossing."

	| coordinates nearest |
	coordinates := scanner segments.
	nearest := nil.
	1 to: coordinates size by: 4 do: [ :index |
		| crossing |
		crossing := self crossingOfEdgeAt: index onSubRow: aSubRow.
		(crossing notNil and: [
			 crossing > anX and: [ nearest isNil or: [ crossing < nearest ] ] ]) ifTrue: [
			nearest := crossing ] ].
	^ nearest
]

{ #category : 'winding' }
VGTileCoverage >> crossingOfEdgeAt: anIndex onSubRow: aSubRow [
	"Where the edge stored at anIndex crosses that sub-row, or nil where it does not reach it. The
	 edge is taken half open from its upper end, and the expression is VGSpanScanner's term for
	 term, so the two classes answer the same float for the same edge."

	| coordinates y0 y1 x0 x1 |
	coordinates := scanner segments.
	y0 := coordinates at: anIndex + 1.
	y1 := coordinates at: anIndex + 3.
	y0 = y1 ifTrue: [ ^ nil ].
	(aSubRow >= (y0 min: y1) and: [ aSubRow < (y0 max: y1) ]) ifFalse: [ ^ nil ].
	x0 := coordinates at: anIndex.
	x1 := coordinates at: anIndex + 2.
	^ x0 + ((x1 - x0) * (aSubRow - y0) / (y1 - y0))
]

{ #category : 'winding' }
VGTileCoverage >> directionOfEdgeAt: anIndex [
	"Down the page is one and up the page is minus one, as VGSpanScanner counts it."

	| coordinates |
	coordinates := scanner segments.
	^ (coordinates at: anIndex + 3) > (coordinates at: anIndex + 1)
		  ifTrue: [ 1 ]
		  ifFalse: [ -1 ]
]

{ #category : 'coverage' }
VGTileCoverage >> endOfRunFrom: aStart to: aRight onSubRow: aSubRow [
	"Where the run that begins at aStart stops: the first crossing right of it that puts the walk
	 outside the shape, or aRight where none does before the pixel ends."

	| cursor winding |
	cursor := aStart.
	winding := self windingUpTo: aStart onSubRow: aSubRow.
	[ cursor < aRight ] whileTrue: [
		cursor := self crossingAfter: cursor onSubRow: aSubRow.
		(cursor isNil or: [ cursor >= aRight ]) ifTrue: [ ^ aRight ].
		winding := winding + (self windingStepAt: cursor onSubRow: aSubRow).
		(scanner isInside: winding) ifFalse: [ ^ cursor ] ].
	^ aRight
]

{ #category : 'accessing' }
VGTileCoverage >> entry [
	^ entry
]

{ #category : 'inspector' }
VGTileCoverage >> inspectorCoverage: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Coverage'>
	"My own walk, one character a pixel, sampled over the whole of my clip through atX:row:, so
	 the picture cannot drift from what a fill through me would paint. The ramp is the one
	 VGRasteriser draws its own coverage with, so the two tabs can be read against each other."

	^ aBuilder newText
		  text: self coverageDrawing;
		  beNotEditable;
		  yourself
]

{ #category : 'inspector' }
VGTileCoverage >> inspectorCoverageContext: aContext [
	aContext active: (entry notNil and: [ self clip bounds hasPositiveExtent ])
]

{ #category : 'inspector' }
VGTileCoverage >> inspectorMiddleRow: aBuilder [
	<inspectorPresentationOrder: 11 title: 'Middle row'>
	"The numbers behind the middle row of the picture: what the walk answers and the byte the
	 format quantises it to, which is what the pixel is really composited with."

	^ aBuilder newTable
		  addColumn: (SpStringTableColumn
				   title: 'x'
				   evaluated: [ :each | (each at: 1) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Coverage'
				   evaluated: [ :each | (each at: 2) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Mask'
				   evaluated: [ :each | (each at: 3) printString ]);
		  items: self middleRowReport;
		  yourself
]

{ #category : 'inspector' }
VGTileCoverage >> inspectorMiddleRowContext: aContext [
	aContext active: (entry notNil and: [ self clip bounds hasPositiveExtent ])
]

{ #category : 'coverage' }
VGTileCoverage >> leftEdgeAtX: anX [
	"Where that pixel starts inside the clip. VGRasteriser trims a span to the clip's bounds and
	 then to the pixel, and both are a maximum of exact floats, so the order does not matter."

	^ anX max: self clip bounds left
]

{ #category : 'inspector' }
VGTileCoverage >> middleRowReport [
	"One row of the middle of my clip: the pixel, the coverage and the mask byte the format makes
	 of it. The quantisation is the format's own method and not a copy of it."

	| box row format |
	box := self clip bounds.
	row := (box top + box bottom) // 2.
	format := VGCairoSurfaceFormat argb32.
	^ (box left floor to: box right ceiling - 1) collect: [ :x |
		  | coverage |
		  coverage := self atX: x row: row.
		  {
			  x.
			  coverage.
			  (format maskByteForCoverage: coverage) } ]
]

{ #category : 'printing' }
VGTileCoverage >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPut: $(;
		print: scanner size;
		nextPutAll: ' edges in ';
		print: self clip bounds;
		nextPut: $)
]

{ #category : 'coverage' }
VGTileCoverage >> rightEdgeAtX: anX [
	^ anX + 1 min: self clip bounds right
]

{ #category : 'coverage' }
VGTileCoverage >> runFrom: aCursor to: aRight onSubRow: aSubRow [
	"The next inside run at or after aCursor, as its two bounds, or nil where none begins before
	 aRight. Nothing is sorted and no crossing is kept: the winding where the walk stands is one
	 scan of the edges, and the next crossing to the right of it is one more. A sort and a scratch
	 array are what an invocation of the kernel cannot afford, so this walk does without both."

	| cursor winding |
	cursor := aCursor.
	winding := self windingUpTo: cursor onSubRow: aSubRow.
	[ scanner isInside: winding ] whileFalse: [
		cursor := self crossingAfter: cursor onSubRow: aSubRow.
		(cursor isNil or: [ cursor >= aRight ]) ifTrue: [ ^ nil ].
		winding := winding + (self windingStepAt: cursor onSubRow: aSubRow) ].
	^ cursor -> (self endOfRunFrom: cursor to: aRight onSubRow: aSubRow)
]

{ #category : 'coverage' }
VGTileCoverage >> runsFrom: aLeft to: aRight onSubRow: aSubRow do: aBlock [
	"The inside runs between those two bounds, left to right. A run ends where the walk steps out
	 of the shape, and the next one is looked for from there."

	| cursor |
	cursor := aLeft.
	[ cursor < aRight ] whileTrue: [
		| run |
		run := self runFrom: cursor to: aRight onSubRow: aSubRow.
		run ifNil: [ ^ self ].
		aBlock value: run key value: run value.
		cursor := run value ]
]

{ #category : 'accessing' }
VGTileCoverage >> scanner [
	^ scanner
]

{ #category : 'initialization' }
VGTileCoverage >> setEntry: anEntry [
	entry := anEntry.
	scanner := VGSpanScanner of: anEntry segments
]

{ #category : 'coverage' }
VGTileCoverage >> spansAtX: anX onSubRow: aSubRow do: aBlock [
	"My fill's inside runs within that pixel on that sub-row, trimmed to the clip, left to right."

	| left right |
	left := self leftEdgeAtX: anX.
	right := self rightEdgeAtX: anX.
	right <= left ifTrue: [ ^ self ].
	scanner isAliased ifTrue: [ ^ self aliasedSpanAtX: anX onSubRow: aSubRow do: aBlock ].
	self
		runsFrom: left
		to: right
		onSubRow: aSubRow
		do: aBlock
]

{ #category : 'winding' }
VGTileCoverage >> windingOnSubRow: aSubRow crossing: aBlock [
	"What the crossings aBlock accepts contribute to the winding. The even-odd rule counts a
	 crossing and the winding rule counts the direction the edge runs in, which is what
	 VGSpanScanner does as it walks its sorted crossings. The kernel inlines this scan at each of
	 its two call sites, because it has no blocks."

	| coordinates winding evenOdd |
	coordinates := scanner segments.
	evenOdd := scanner fillRule == #evenOdd.
	winding := 0.
	1 to: coordinates size by: 4 do: [ :index |
		| crossing |
		crossing := self crossingOfEdgeAt: index onSubRow: aSubRow.
		(crossing notNil and: [ aBlock value: crossing ]) ifTrue: [
			winding := winding
			           + (evenOdd
					            ifTrue: [ 1 ]
					            ifFalse: [ self directionOfEdgeAt: index ]) ] ].
	^ winding
]

{ #category : 'winding' }
VGTileCoverage >> windingStepAt: anX onSubRow: aSubRow [
	"What the crossings at exactly anX add to the winding. Two edges can cross one point, and a
	 walk that took them one at a time would call the space between them a run of its own."

	^ self windingOnSubRow: aSubRow crossing: [ :x | x = anX ]
]

{ #category : 'winding' }
VGTileCoverage >> windingUpTo: anX onSubRow: aSubRow [
	"The winding number just right of anX, in one scan of the edges. A crossing exactly at anX
	 counts: a run that starts there is inside from there, and a run that ends there has ended."

	^ self windingOnSubRow: aSubRow crossing: [ :x | x <= anX ]
]
