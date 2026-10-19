"
I am the software scan converter: I turn a set of edges and a fill rule into how much of each pixel is covered.

I take the edges as a flat array of x0, y0, x1, y1 quadruples in device space, which is what the
backend boundary passes, so I know nothing about paths, curves or paint.
I am exact across a pixel and sampled down it: a pixel row is cut into samplesPerPixelRow sub-rows,
each sub-row is crossed with every edge, the crossings give the spans the fill rule says are inside,
and a span adds the part of each pixel it really covers. So my error is bounded by one sub-row in y
and is nil in x, which is the same quantisation in y that Cairo's own scan converter uses.

coverageRowsDo: is the whole of my interface: it answers, for each row the clip and the edges share,
a Float64Array of coverage between zero and one and the device x the array starts at.
One edge at a time against every sub-row is the obvious loop and not the fast one; unit 1.11 of the
plan is where that is measured and attacked.
"
Class {
	#name : 'VGRasteriser',
	#superclass : 'Object',
	#instVars : [
		'scanner',
		'clip'
	],
	#category : 'VectorGraphics-Cairo-Rasterising',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Rasterising'
}

{ #category : 'constants' }
VGRasteriser class >> samplesPerPixelRow [
	"Fifteen sub-rows to a pixel row, which is the grid Cairo's own scan converter uses down the
	 row, so an antialiased edge of ours is quantised no more coarsely than Cairo's."
	^ 15
]

{ #category : 'instance creation' }
VGRasteriser class >> segments: anArray fillRule: aSymbol antialias: anotherSymbol clip: aClip [
	^ self new
		  setScanner: (VGSpanScanner
				   segments: anArray
				   fillRule: aSymbol
				   antialias: anotherSymbol)
		  clip: aClip
]

{ #category : 'instance creation' }
VGRasteriser class >> segments: anArray fillRule: aSymbol clip: aClip [
	^ self
		  segments: anArray
		  fillRule: aSymbol
		  antialias: VGCairoState antialiasNames first
		  clip: aClip
]

{ #category : 'private' }
VGRasteriser >> addOverlapFrom: aNumber to: anotherNumber into: aFloatArray startingAt: anInteger [
	"The part of each pixel the span really covers, in sub-row units: the caller divides by the
	 number of sub-rows once the row is finished, so a whole pixel sums to exactly one."
	| from to |
	from := aNumber max: anInteger.
	to := anotherNumber min: anInteger + aFloatArray size.
	to <= from ifTrue: [ ^ self ].
	from floor to: to ceiling - 1 do: [ :pixel |
		| overlap index |
		overlap := (pixel + 1 min: to) - (pixel max: from).
		overlap > 0 ifTrue: [
			index := pixel - anInteger + 1.
			aFloatArray at: index put: (aFloatArray at: index) + overlap ] ]
]

{ #category : 'accessing' }
VGRasteriser >> antialias [
	^ scanner antialias
]

{ #category : 'accessing' }
VGRasteriser >> clip [
	^ clip
]

{ #category : 'inspector' }
VGRasteriser >> coverageDrawing [
	"The coverage the rasteriser really computes, one character a pixel, read from
	 #coverageRowsDo: so the picture cannot drift from what a fill would paint. A row no edge
	 reaches is not visited, so it is absent rather than blank."

	| ramp |
	ramp := self coverageRamp.
	^ String streamContents: [ :stream |
		  self coverageRowsDo: [ :y :coverage :left |
			  stream
				  nextPutAll: (y printPaddedWith: Character space to: 4);
				  nextPutAll: ' |'.
			  coverage do: [ :each |
				  stream nextPut:
						  (ramp at: (each * (ramp size - 1)) rounded + 1) ].
			  stream nextPut: $|; cr ] ]
]

{ #category : 'inspector' }
VGRasteriser >> coverageRamp [
	"The characters a coverage from zero to one is drawn with, lightest first."

	^ ' .:-=+*#%@'
]

{ #category : 'accessing' }
VGRasteriser >> coverageRowsDo: aBlock [
	"The coverage of every row the clip and the edges share: the row, a Float64Array of coverage
	 from zero to one, and the device x its first entry stands for. A row no edge reaches is not
	 visited at all, and a clip that allows nothing is not visited either."

	| left width coverage |
	scanner isEmpty ifTrue: [ ^ self ].
	clip isEmpty ifTrue: [ ^ self ].
	left := clip bounds left floor.
	width := clip bounds right ceiling - left.
	width <= 0 ifTrue: [ ^ self ].
	coverage := Float64Array new: width.
	self rowRange do: [ :y |
		coverage atAllPut: 0.0.
		self fillCoverage: coverage startingAt: left atRow: y.
		aBlock value: y value: coverage value: left ]
]

{ #category : 'private' }
VGRasteriser >> fillCoverage: aFloatArray startingAt: anInteger atRow: aRow [
	"The part of each pixel of the row the shape covers inside the clip, sampled on the sub-row
	 grid and exact across the pixel. Every sub-row span of the shape is trimmed to the spans the
	 clip allows on that same sub-row, which is the geometric intersection Cairo performs. An
	 aliased shape or clip answers the same whole pixels on every sub-row of the row, so this one
	 loop serves both modes."
	| samples |
	samples := self class samplesPerPixelRow.
	0 to: samples - 1 do: [ :sample |
		| subRow |
		subRow := aRow + ((sample + 0.5) / samples).
		scanner spansOfPixelRowAt: subRow do: [ :from :to |
			clip spanFrom: from to: to at: subRow do: [ :start :end |
				self
					addOverlapFrom: start
					to: end
					into: aFloatArray
					startingAt: anInteger ] ] ].
	1 to: aFloatArray size do: [ :index |
		aFloatArray at: index put: ((aFloatArray at: index) / samples min: 1.0) ]
]

{ #category : 'accessing' }
VGRasteriser >> fillRule [
	^ scanner fillRule
]

{ #category : 'inspector' }
VGRasteriser >> inspectorCoverage: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Coverage'>
	"The sampled coverage as text, built by the real scan conversion."

	^ aBuilder newText
		  text: self coverageDrawing;
		  beNotEditable;
		  yourself
]

{ #category : 'inspector' }
VGRasteriser >> inspectorCoverageContext: aContext [
	aContext active: (scanner notNil and: [ clip notNil ])
]

{ #category : 'testing' }
VGRasteriser >> isAliased [
	^ scanner isAliased
]

{ #category : 'printing' }
VGRasteriser >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPut: $(;
		print: scanner size;
		nextPutAll: ' edges, ';
		nextPutAll: scanner fillRule;
		nextPutAll: ', clip ';
		print: clip;
		nextPut: $)
]

{ #category : 'private' }
VGRasteriser >> rowRange [
	"The rows the clip and the edges share. A shape well above or below the clip costs nothing."

	| top bottom segments |
	segments := scanner segments.
	top := Float infinity.
	bottom := Float infinity negated.
	2 to: segments size by: 2 do: [ :index |
		| y |
		y := segments at: index.
		top := top min: y.
		bottom := bottom max: y ].
	^ (top floor max: clip bounds top floor)
	  to: (bottom ceiling min: clip bounds bottom ceiling) - 1
]

{ #category : 'accessing' }
VGRasteriser >> scanner [
	"The scan conversion of my shape, which the clip performs on its own shapes too."

	^ scanner
]

{ #category : 'accessing' }
VGRasteriser >> segments [
	^ scanner segments
]

{ #category : 'private' }
VGRasteriser >> setScanner: aScanner clip: aClip [
	scanner := aScanner.
	clip := aClip
]
