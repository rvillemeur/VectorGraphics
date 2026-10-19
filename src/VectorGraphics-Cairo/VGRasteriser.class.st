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
		'segments',
		'fillRule',
		'clip',
		'antialias'
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
VGRasteriser class >> segments: anArray fillRule: aSymbol antialias: anotherSymbol clip: aRectangle [
	^ self new
		  setSegments: anArray
		  fillRule: aSymbol
		  antialias: anotherSymbol
		  clip: aRectangle
]

{ #category : 'instance creation' }
VGRasteriser class >> segments: anArray fillRule: aSymbol clip: aRectangle [
	^ self
		  segments: anArray
		  fillRule: aSymbol
		  antialias: VGCairoState antialiasNames first
		  clip: aRectangle
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
	^ antialias
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
	 visited at all."

	| left width coverage |
	segments isEmpty ifTrue: [ ^ self ].
	left := clip left floor.
	width := clip right ceiling - left.
	width <= 0 ifTrue: [ ^ self ].
	coverage := Float64Array new: width.
	self rowRange do: [ :y |
		coverage atAllPut: 0.0.
		self isAliased
			ifTrue: [ self fillAliasedCoverage: coverage startingAt: left atRow: y ]
			ifFalse: [ self fillSampledCoverage: coverage startingAt: left atRow: y ].
		aBlock value: y value: coverage value: left ]
]

{ #category : 'private' }
VGRasteriser >> crossingsAt: aNumber [
	"Every edge the line crosses, as an x to direction association sorted by x. An edge is taken
	 half open, from its upper end inclusive to its lower end exclusive, so a vertex shared by two
	 edges is counted once rather than twice."
	| crossings |
	crossings := OrderedCollection new.
	1 to: segments size by: 4 do: [ :index |
		| y0 y1 |
		y0 := segments at: index + 1.
		y1 := segments at: index + 3.
		y0 = y1 ifFalse: [
			(aNumber >= (y0 min: y1) and: [ aNumber < (y0 max: y1) ]) ifTrue: [
				| x0 x1 |
				x0 := segments at: index.
				x1 := segments at: index + 2.
				crossings add:
					x0 + ((x1 - x0) * (aNumber - y0) / (y1 - y0))
					-> (y1 > y0 ifTrue: [ 1 ] ifFalse: [ -1 ]) ] ] ].
	^ crossings asArray sort: [ :a :b | a key <= b key ]
]

{ #category : 'private' }
VGRasteriser >> fillAliasedCoverage: aFloatArray startingAt: anInteger atRow: aRow [
	"Antialiasing off: one sample at the centre of the pixel, so every pixel is painted whole or
	 left alone and no edge carries a shade."

	self spansAt: aRow + 0.5 do: [ :from :to |
		1 to: aFloatArray size do: [ :index |
			| centre |
			centre := anInteger + index - 0.5.
			(centre >= from and: [ centre < to ]) ifTrue: [
				aFloatArray at: index put: 1.0 ] ] ]
]

{ #category : 'accessing' }
VGRasteriser >> fillRule [
	^ fillRule
]

{ #category : 'private' }
VGRasteriser >> fillSampledCoverage: aFloatArray startingAt: anInteger atRow: aRow [
	"The part of each pixel of the row the shape covers, sampled on the sub-row grid and exact
	 across the pixel."

	| samples |
	samples := self class samplesPerPixelRow.
	0 to: samples - 1 do: [ :sample |
		self
			spansAt: aRow + ((sample + 0.5) / samples)
			do: [ :from :to |
			self
				addOverlapFrom: from
				to: to
				into: aFloatArray
				startingAt: anInteger ] ].
	1 to: aFloatArray size do: [ :index |
		aFloatArray at: index put: ((aFloatArray at: index) / samples min: 1.0) ]
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
	aContext active: (segments notNil and: [ clip notNil ])
]

{ #category : 'testing' }
VGRasteriser >> isAliased [
	^ antialias == #none
]

{ #category : 'private' }
VGRasteriser >> isInside: anInteger [
	^ fillRule == #evenOdd
		  ifTrue: [ anInteger odd ]
		  ifFalse: [ anInteger ~= 0 ]
]

{ #category : 'printing' }
VGRasteriser >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPutAll: '(';
		print: segments size // 4;
		nextPutAll: ' edges, ';
		nextPutAll: fillRule;
		nextPutAll: ', clip ';
		print: clip;
		nextPut: $)
]

{ #category : 'private' }
VGRasteriser >> rowRange [
	"The rows the clip and the edges share. A shape well above or below the clip costs nothing."
	| top bottom |
	top := Float infinity.
	bottom := Float infinity negated.
	2 to: segments size by: 2 do: [ :index |
		| y |
		y := segments at: index.
		top := top min: y.
		bottom := bottom max: y ].
	^ (top floor max: clip top floor) to: (bottom ceiling min: clip bottom ceiling) - 1
]

{ #category : 'accessing' }
VGRasteriser >> segments [
	^ segments
]

{ #category : 'private' }
VGRasteriser >> setSegments: anArray fillRule: aSymbol antialias: anotherSymbol clip: aRectangle [
	segments := anArray.
	fillRule := aSymbol.
	antialias := anotherSymbol.
	clip := aRectangle
]

{ #category : 'enumerating' }
VGRasteriser >> spansAt: aNumber do: aBlock [
	"The spans of that horizontal line the fill rule calls inside. A crossing carries the direction
	 the edge runs in, because the winding rule counts those directions and the even-odd rule only
	 counts crossings."
	| crossings winding startX |
	crossings := self crossingsAt: aNumber.
	winding := 0.
	startX := nil.
	crossings do: [ :crossing |
		| wasInside |
		wasInside := self isInside: winding.
		winding := fillRule == #evenOdd
			           ifTrue: [ winding + 1 ]
			           ifFalse: [ winding + crossing value ].
		(self isInside: winding)
			ifTrue: [ wasInside ifFalse: [ startX := crossing key ] ]
			ifFalse: [ wasInside ifTrue: [ aBlock value: startX value: crossing key ] ] ]
]
