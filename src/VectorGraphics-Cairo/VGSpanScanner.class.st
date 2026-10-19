"
I scan-convert one shape, one horizontal line at a time: given the y of a line I answer the x spans of it that the fill rule calls inside. I hold the edge coordinates in device space, four floats an edge, with the fill rule and the antialiasing mode they are to be read with.

Both the rasteriser and the clip stack need the same scan conversion - the rasteriser to find the coverage of a fill, the clip to find where the fill is allowed - so the scanning lives here and neither owns it. An aliased shape is sampled once at the centre of its pixel row and its spans snap to whole pixels, so every sub-row of that row answers the same ones.
"
Class {
	#name : 'VGSpanScanner',
	#superclass : 'Object',
	#instVars : [
		'segments',
		'fillRule',
		'antialias'
	],
	#category : 'VectorGraphics-Cairo-Rasterising',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Rasterising'
}

{ #category : 'instance creation' }
VGSpanScanner class >> of: aSegments [
	"The scanner of a segment array, which already carries the fill rule and the antialiasing
	 mode its edges are to be read with."

	^ self
		  segments: aSegments coordinates
		  fillRule: aSegments fillRule
		  antialias: aSegments antialias
]

{ #category : 'instance creation' }
VGSpanScanner class >> segments: anArray fillRule: aSymbol antialias: anotherSymbol [
	^ self new
		  setSegments: anArray
		  fillRule: aSymbol
		  antialias: anotherSymbol
]

{ #category : 'accessing' }
VGSpanScanner >> antialias [
	^ antialias
]

{ #category : 'private' }
VGSpanScanner >> crossingsAt: aNumber [
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

{ #category : 'accessing' }
VGSpanScanner >> fillRule [
	^ fillRule
]

{ #category : 'inspecting' }
VGSpanScanner >> inspectorSpans: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Spans'>
	"The spans I really answer, one line a sub-row over the rows my edges reach, read through
	 the same span method the rasteriser and the clip call."
	| box samples |
	box := VGSegments
		       coordinates: segments
		       fillRule: fillRule
		       antialias: antialias.
	samples := VGRasteriser samplesPerPixelRow.
	^ aBuilder newText
		  text: (String streamContents: [ :stream |
					   box boundingBox ifNotNil: [ :bounds |
						   bounds top to: bounds bottom - 1 do: [ :row |
							   0 to: samples - 1 do: [ :sample |
								   | subRow |
								   subRow := row + ((sample + 0.5) / samples).
								   stream
									   nextPutAll: (subRow printShowingDecimalPlaces: 3);
									   nextPutAll: ' |'.
								   self spansOfPixelRowAt: subRow do: [ :from :to |
									   stream
										   print: from;
										   nextPutAll: ' to ';
										   print: to;
										   nextPut: $  ].
								   stream cr ] ] ] ]);
		  beNotEditable;
		  yourself
]

{ #category : 'inspecting' }
VGSpanScanner >> inspectorSpansContext: aContext [
	"A scanner with no edges answers no span anywhere, so there is nothing to list."
	aContext active: self isEmpty not
]

{ #category : 'testing' }
VGSpanScanner >> isAliased [
	"Only Cairo's #none mode changes what the scanning does; the other six ask for antialiasing of
	 one quality or another and we sample them all the same way."

	^ antialias == #none
]

{ #category : 'testing' }
VGSpanScanner >> isEmpty [
	^ segments isEmpty
]

{ #category : 'private' }
VGSpanScanner >> isInside: anInteger [
	^ fillRule == #evenOdd
		  ifTrue: [ anInteger odd ]
		  ifFalse: [ anInteger ~= 0 ]
]

{ #category : 'printing' }
VGSpanScanner >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPut: $(;
		print: self size;
		nextPutAll: ' edges, ';
		nextPutAll: fillRule;
		nextPut: $)
]

{ #category : 'accessing' }
VGSpanScanner >> segments [
	^ segments
]

{ #category : 'private' }
VGSpanScanner >> setSegments: anArray fillRule: aSymbol antialias: anotherSymbol [
	segments := anArray.
	fillRule := aSymbol.
	antialias := anotherSymbol
]

{ #category : 'accessing' }
VGSpanScanner >> size [
	"How many edges I hold."

	^ segments size // 4
]

{ #category : 'enumerating' }
VGSpanScanner >> spansAt: aNumber do: aBlock [
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

{ #category : 'scanning' }
VGSpanScanner >> spansOfPixelRowAt: aNumber do: aBlock [
	"The spans of that line, or, when I am aliased, the whole pixels of the row the line falls
	 in. The row is the floor of the line, because a sub-row lies strictly inside its own pixel
	 row. Antialiasing off means one sample at the centre of the pixel: a pixel is inside when
	 its own centre is, so a span runs from the first centre it holds to the first one it does
	 not, and every sub-row of the row answers the same whole pixels. Measured on a live Cairo
	 context: an aliased clip whose edge falls at 20.5 covers pixel twenty whole and one at 20.75
	 leaves it alone."
	self isAliased ifFalse: [ ^ self spansAt: aNumber do: aBlock ].
	self spansAt: aNumber floor + 0.5 do: [ :from :to |
		| first after |
		first := (from - 0.5) ceiling.
		after := (to - 0.5) ceiling.
		after > first ifTrue: [ aBlock value: first asFloat value: after asFloat ] ]
]
