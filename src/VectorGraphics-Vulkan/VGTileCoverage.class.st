"
The part of a pixel one recorded fill covers, found the way a kernel invocation can afford to find it: no sorted array of crossings and no scratch buffer, one scan of the edges for the winding at the left of the pixel and one more for each run after it.

VGRasteriser answers the same numbers for a whole row at once, and it is the oracle: I sum the same terms for a pixel in the same order over the fifteen sub-rows VGRasteriser samples, so the two answer the same float and not merely the same number. atX:row: is the whole of my interface; the rest is the walk.
"
Class {
	#name : 'VGTileCoverage',
	#superclass : 'Object',
	#instVars : [
		'entry',
		'walks',
		'swept'
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

{ #category : 'accessing' }
VGTileCoverage >> clipWalks [
	"The walks of the shapes my clip holds, which is none where the clip is a rectangle."

	^ walks allButFirst
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

{ #category : 'accessing' }
VGTileCoverage >> entry [
	^ entry
]

{ #category : 'accessing' }
VGTileCoverage >> fill [
	"The walk of the shape being filled."

	^ walks first
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

{ #category : 'inspector' }
VGTileCoverage >> inspectorShapes: aBuilder [
	<inspectorPresentationOrder: 12 title: 'Shapes'>
	"The shapes a pixel of mine is covered by: the fill and every shape of my clip, walked
	 alike. An aliased shape answers whole pixels and is asked about the centre of one; the
	 swept ones are the shapes a sweep crosses, and the crossing named here is the first one
	 right of the left edge of the middle pixel. Every cell asks the walk itself."

	^ aBuilder newTable
		  addColumn: (SpStringTableColumn
				   title: 'Of'
				   evaluated: [ :each | each at: 2 ]);
		  addColumn: (SpStringTableColumn
				   title: 'Edges'
				   evaluated: [ :each | (each at: 3) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Aliased'
				   evaluated: [ :each | (each at: 4) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Swept'
				   evaluated: [ :each | (each at: 5) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Centre inside'
				   evaluated: [ :each | (each at: 6) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Next crossing'
				   evaluated: [ :each | (each at: 7) printString ]);
		  items: self shapeRows;
		  yourself
]

{ #category : 'inspector' }
VGTileCoverage >> inspectorShapesContext: aContext [
	aContext active: (entry notNil and: [ self clip bounds hasPositiveExtent ])
]

{ #category : 'walking' }
VGTileCoverage >> isInsideAt: anX onSubRow: aSubRow [
	"A point is covered where every swept shape calls it inside. That is the geometric
	 intersection Cairo performs: spans meet spans and coverages are never multiplied."

	^ swept allSatisfy: [ :each | each isInsideAt: anX onSubRow: aSubRow ]
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

{ #category : 'walking' }
VGTileCoverage >> nextCrossingAfter: anX to: aRight onSubRow: aSubRow [
	"The nearest crossing of any swept shape strictly right of anX, or aRight where none of them
	 crosses inside the window."

	| nearest |
	nearest := aRight.
	swept do: [ :each |
		(each crossingAfter: anX onSubRow: aSubRow) ifNotNil: [ :crossing |
			crossing < nearest ifTrue: [ nearest := crossing ] ] ].
	^ nearest
]

{ #category : 'printing' }
VGTileCoverage >> printOn: aStream [

	aStream
		nextPutAll: self class name;
		nextPut: $(;
		print: self fill size;
		nextPutAll: ' edges in ';
		print: self clip bounds.
	self clipWalks ifNotEmpty: [ :shapes |
		aStream
			nextPutAll: ' through ';
			print: shapes size;
			nextPutAll: ' clip shapes' ].
	aStream nextPut: $)
]

{ #category : 'coverage' }
VGTileCoverage >> rightEdgeAtX: anX [
	^ anX + 1 min: self clip bounds right
]

{ #category : 'initialization' }
VGTileCoverage >> setEntry: anEntry [
	"The fill is one shape to walk and every shape of its clip is another, and they are walked
	 alike: a pixel is covered by what all of them call inside. The antialiased ones are kept
	 apart as well, because they are the ones a sweep runs over, and a sweep runs once a sub-row
	 of every pixel of the tile."

	entry := anEntry.
	walks := { (VGShapeWalk of: (VGSpanScanner of: anEntry segments)) }
	         , (anEntry clip shapes collect: [ :each | VGShapeWalk of: each ]).
	swept := walks reject: [ :each | each isAliased ]
]

{ #category : 'inspector' }
VGTileCoverage >> shapeRows [
	"One row for every walk I built: whether it is the fill or a shape of the clip, how many
	 edges it holds, whether it is aliased and therefore gates the pixel by its centre, whether
	 it is swept, and what it answers in the middle of my clip. Each cell asks the walk, so a
	 shape whose verdict changes shows a changed row."

	| box row subRow x |
	box := self clip bounds.
	row := (box top + box bottom) // 2.
	subRow := row + 0.5.
	x := (box left + box right) // 2.
	^ walks withIndexCollect: [ :each :index |
		  {
			  index.
			  (index = 1
				   ifTrue: [ 'Fill' ]
				   ifFalse: [ 'Clip shape ' , (index - 1) printString ]).
			  each size.
			  each isAliased.
			  (swept includes: each).
			  (each isPixelCentreInsideAtX: x onSubRow: subRow).
			  (each crossingAfter: (self leftEdgeAtX: x) onSubRow: subRow) } ]
]

{ #category : 'walking' }
VGTileCoverage >> spansAtX: anX onSubRow: aSubRow do: aBlock [
	"The parts of that pixel my fill covers inside my clip, on that sub-row, left to right. An
	 aliased shape answers whole pixels, so it is asked about the centre of this one and then
	 leaves the window alone; the antialiased shapes are swept together."

	| left right |
	left := self leftEdgeAtX: anX.
	right := self rightEdgeAtX: anX.
	right <= left ifTrue: [ ^ self ].
	(walks allSatisfy: [ :each |
		 each isAliased not or: [
			 each isPixelCentreInsideAtX: anX onSubRow: aSubRow ] ]) ifFalse: [ ^ self ].
	swept ifEmpty: [ ^ aBlock value: left value: right ].
	self sweepFrom: left to: right onSubRow: aSubRow do: aBlock
]

{ #category : 'walking' }
VGTileCoverage >> sweepFrom: aLeft to: aRight onSubRow: aSubRow do: aBlock [
	"The parts of that window every swept shape calls inside, left to right. A piece runs from
	 where the last shape lets it in to where the first one shuts it out, so a crossing that
	 leaves the verdict alone does not cut a piece in two and the sums are the same floats the
	 rasteriser adds. Nothing is sorted and no crossing is kept: the verdict at a point is one
	 scan of the edges of each shape and the next crossing right of it is one more, which is what
	 one invocation of the kernel can afford."

	| cursor start inside |
	cursor := aLeft.
	start := aLeft.
	inside := self isInsideAt: aLeft onSubRow: aSubRow.
	[ cursor < aRight ] whileTrue: [
		| next |
		next := self nextCrossingAfter: cursor to: aRight onSubRow: aSubRow.
		next >= aRight
			ifTrue: [
				inside ifTrue: [ aBlock value: start value: aRight ].
				cursor := aRight ]
			ifFalse: [
				| nextInside |
				nextInside := self isInsideAt: next onSubRow: aSubRow.
				nextInside = inside ifFalse: [
					inside
						ifTrue: [ aBlock value: start value: next ]
						ifFalse: [ start := next ].
					inside := nextInside ].
				cursor := next ] ]
]
