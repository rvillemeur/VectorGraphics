"
I am a clip: the area of a surface a fill is allowed to touch. I hold the exact device-space bounds of that area and the shapes it was cut out with, one scanner each, and I am immutable - clipping me answers a new clip - so a saved state and the state it was saved from can share me.

Measured on a live Cairo context: a clip composes with a fill geometrically and not as a coverage mask. Clipping a circle and painting writes the same bytes as filling that circle, and clipping the same circle twice writes them again, so my spans are intersected with the spans of the fill sub-row by sub-row and coverages are never multiplied: a clip edge at 20.5 with a fill edge at 20.75 leaves a quarter of the pixel and not an eighth. Each of my shapes carries the fill rule and the antialiasing mode in force when it was clipped, because Cairo keeps those with the clip for the rest of its life.

The common case, and the only one a Bloc element builds for a rectangular geometry, is a clip of device-space rectangles alone: then I hold no shape at all and my bounds are the whole answer. My extents, which is what cairo_clip_extents reports, are those bounds rounded out to whole pixels, and the origin when I am empty.
"
Class {
	#name : 'VGClip',
	#superclass : 'Object',
	#instVars : [
		'bounds',
		'shapes'
	],
	#category : 'VectorGraphics-Cairo-Rasterising',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Rasterising'
}

{ #category : 'instance creation' }
VGClip class >> bounds: aRectangle [
	"The clip of a whole area, cut out by nothing: a surface starts with this one."

	^ self new setBounds: aRectangle shapes: #( )
]

{ #category : 'instance creation' }
VGClip class >> bounds: aRectangle shapes: aCollection [
	"The clip of an area cut out by those shapes. Only a reader of a written frame builds one
	 this way: every other clip grows by clippedBy:, which decides for itself whether the edges
	 it is given are a rectangle or a shape, and a decoder already knows which they were."

	^ self new setBounds: aRectangle shapes: aCollection asArray
]

{ #category : 'instance creation' }
VGClip class >> empty [
	"The clip that allows nothing. Measured: clipping with an empty path leaves a successful
	 status and clips everything away, and the extents collapse to the origin."

	^ self bounds: (0 @ 0 corner: 0 @ 0)
]

{ #category : 'private' }
VGClip >> addSpanFrom: aNumber to: anotherNumber into: aCollection [
	"A span of no width is no span: an empty intersection drops out here rather than reaching the
	 coverage."

	anotherNumber > aNumber ifTrue: [
		aCollection add: {
				aNumber.
				anotherNumber } ]
]

{ #category : 'accessing' }
VGClip >> bounds [
	"The exact device-space area I allow, fractions kept."

	^ bounds
]

{ #category : 'private' }
VGClip >> boundsNarrowedTo: aRectangle [
	"My bounds and that rectangle, or a rectangle of no area at all when the two do not meet.
	 Rectangle >> #intersect: answers a rectangle whose left is past its right in that case, and
	 a clip has to be plainly empty instead."

	| left top right bottom |
	left := bounds left max: aRectangle left.
	top := bounds top max: aRectangle top.
	right := bounds right min: aRectangle right.
	bottom := bounds bottom min: aRectangle bottom.
	(right > left and: [ bottom > top ]) ifFalse: [ ^ 0 @ 0 corner: 0 @ 0 ].
	^ left @ top corner: right @ bottom
]

{ #category : 'clipping' }
VGClip >> clippedBy: aSegments [
	"The clip that is me cut down by those edges. A segment array that is a device-space rectangle
	 narrows my bounds and adds no shape, which is the fast path; anything else is kept as a
	 scanner and intersected sub-row by sub-row. Edges that hold nothing clip everything away:
	 measured, a clip of an empty path leaves no pixel paintable."

	| rectangle |
	aSegments isEmpty ifTrue: [ ^ self class empty ].
	rectangle := aSegments asDeviceRectangle.
	rectangle ifNil: [
		^ self class new
			  setBounds: (self boundsNarrowedTo: aSegments exactBoundingBox)
			  shapes: (shapes copyWith: (VGSpanScanner of: aSegments)) ].
	aSegments isAliased ifTrue: [
		rectangle := self wholePixelsOf: rectangle ].
	^ self class new
		  setBounds: (self boundsNarrowedTo: rectangle)
		  shapes: shapes
]

{ #category : 'accessing' }
VGClip >> coverageRasteriser [
	"The real rasteriser, set to fill the whole of my extents through me, so its coverage is the
	 part of each pixel I allow. A fill needs none of this, because it meets me span by span
	 inside the rasteriser; a mask carries no spans to meet, so it is scaled by this coverage
	 instead, and the inspector draws it."

	| segments |
	segments := VGSegments rectangle: self extents.
	^ VGRasteriser
		  segments: segments coordinates
		  fillRule: segments fillRule
		  antialias: segments antialias
		  clip: self
]

{ #category : 'accessing' }
VGClip >> coverageRowsDo: aBlock [
	"The part of each pixel of every row I touch that I allow: the row, a Float64Array of
	 coverage from zero to one, and the device x its first entry stands for. The rim of a clip is
	 measured here exactly as the rim of a fill is, because the same rasteriser answers both. A
	 row I allow nothing of is not visited at all, and a clip of no area is not visited either."

	^ self coverageRasteriser coverageRowsDo: aBlock
]

{ #category : 'accessing' }
VGClip >> extents [
	"What cairo_clip_extents reports: my bounds rounded out to whole pixels, or the origin alone
	 when I allow nothing. Measured on a live Cairo context: a clip whose right edge falls at 20.5
	 reports twenty-one, and two clips that do not meet report 0@0 corner: 0@0."

	self isEmpty ifTrue: [ ^ 0 @ 0 corner: 0 @ 0 ].
	^ bounds left floor @ bounds top floor
	  corner: bounds right ceiling @ bounds bottom ceiling
]

{ #category : 'testing' }
VGClip >> holdsWholly: aRectangle [
	"Whether my area holds every point of that rectangle, its boundary included: what
	 bounds containsRect: answers, with the four numbers compared one at a time. A rectangle
	 comparison is two point comparisons, and a point comparison of my fractional bound against
	 a whole tile bound coerces one number against the other twice a corner, which the binning
	 of unit 3.5 paid for every entry and tile pair of the frame."

	| mine |
	mine := bounds.
	^ mine left <= aRectangle left and: [
		  mine top <= aRectangle top and: [
			  mine right >= aRectangle right and: [
				  mine bottom >= aRectangle bottom ] ] ]
]

{ #category : 'inspecting' }
VGClip >> inspectorHoldsWholly: aBuilder [
	<inspectorPresentationOrder: 4 title: 'Holds wholly'>
	"What I answer about rectangles taken from my own area, which is the question a tiled
	 binning asks of me once for every entry and tile pair of a frame. Each row asks the
	 predicate and asks my bounds beside it, so a spelling of the question that stopped
	 agreeing with Rectangle>>containsRect: would show as two different answers rather than go
	 unseen."

	| whole |
	whole := self extents.
	^ aBuilder newTable
		  items: {
				  ('my extents' -> whole).
				  ('my extents inset by one pixel' -> (whole insetBy: 1)).
				  ('my extents grown by one pixel' -> (whole expandBy: 1)).
				  ('my exact bounds' -> bounds).
				  ('the pixel at my top left' -> (whole origin corner: whole origin + (1 @ 1))).
				  ('one pixel past my right edge'
				   -> (whole topRight corner: whole bottomRight + (1 @ 0))) };
		  addColumn: (SpStringTableColumn title: 'Rectangle' evaluated: [ :each |
					   each key , ' ' , each value printString ]);
		  addColumn: (SpStringTableColumn title: 'Held wholly' evaluated: [ :each |
					   (self holdsWholly: each value) printString ]);
		  addColumn: (SpStringTableColumn title: 'Inside my bounds' evaluated: [ :each |
					   (bounds containsRect: each value) printString ]);
		  yourself
]

{ #category : 'inspecting' }
VGClip >> inspectorHoldsWhollyContext: aContext [
	"A clip with no bounds has no area to take a rectangle from."

	aContext active: bounds isNotNil
]

{ #category : 'inspector' }
VGClip >> inspectorMaskSide [
	"The side of the mask the walk view measures. Sixteen pixels is a glyph of a readable size,
	 which is the mask whose cost made the narrowing worth having."

	^ 16
]

{ #category : 'inspector' }
VGClip >> inspectorMaskWalk: aBuilder [
	<inspectorPresentationOrder: 20 title: 'Mask walk'>
	"What one mask costs through me. A mask carries no spans to meet me with, so the backend
	 scales it by my coverage pixel by pixel and walks me to do it; under a bounded operator a
	 mask byte of zero leaves the destination as it was, so the walk is narrowed to the rectangle
	 the mask covers, which is what narrowedTo: answers. Both counts are taken by walking the real
	 clips, so they cannot drift from VGSoftwareBackend >> maskWith:paint:clip:operator:into:.
	 Nothing here mutates me: narrowedTo: answers a new clip."

	| rectangle narrowed |
	rectangle := (self bounds center - (self inspectorMaskSide // 2)) extent:
		             self inspectorMaskSide asPoint.
	narrowed := self narrowedTo: rectangle.
	^ aBuilder newText
		  text: (String cr join: {
					   'my bounds: ' , self bounds printString.
					   'pixels walked for a mask: '
					   , (self inspectorPixelsWalkedBy: self) printString.
					   'a mask of ' , self inspectorMaskSide printString , ' square at: '
					   , rectangle printString.
					   'narrowed to: ' , narrowed bounds printString.
					   'pixels walked once narrowed: '
					   , (self inspectorPixelsWalkedBy: narrowed) printString });
		  beNotEditable;
		  yourself
]

{ #category : 'inspector' }
VGClip >> inspectorMaskWalkContext: aContext [
	"A clip of no area passes nothing anywhere, so there is no walk to measure for it."

	aContext active: self isEmpty not
]

{ #category : 'inspector' }
VGClip >> inspectorPassed: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Passed'>
	"What a fill of my own extents keeps, one character a pixel, drawn by the real rasteriser
	 with me as its clip. Nothing is restated here: the picture is the coverage a fill through me
	 would paint, and a mask through me is scaled by it, so it cannot drift from the rule."

	^ aBuilder newText
		  text: self coverageRasteriser coverageDrawing;
		  beNotEditable;
		  yourself
]

{ #category : 'inspecting' }
VGClip >> inspectorPassedContext: aContext [
	"A clip of no area passes nothing anywhere, so there is no picture to draw for it."
	aContext active: self isEmpty not
]

{ #category : 'inspector' }
VGClip >> inspectorPixelsWalkedBy: aClip [
	"How many pixels a backend visits for one mask through that clip, counted by walking the clip
	 itself rather than from its bounds, so a clip that keeps a shape counts what it really passes."

	| walked |
	walked := 0.
	aClip coverageRowsDo: [ :y :coverage :left | walked := walked + coverage size ].
	^ walked
]

{ #category : 'testing' }
VGClip >> isEmpty [
	^ bounds width <= 0 or: [ bounds height <= 0 ]
]

{ #category : 'testing' }
VGClip >> isRectangular [
	"I was cut out by device-space rectangles alone, so my bounds are the whole of me and no
	 scan conversion is needed to trim a fill to me."

	^ shapes isEmpty
]

{ #category : 'clipping' }
VGClip >> narrowedTo: aRectangle [
	"The clip that is me inside that rectangle: my own shapes, my own coverage, and no pixel
	 outside it. A mask carries no spans to meet me with, so it is scaled by my coverage pixel by
	 pixel and the walk that does it is narrowed to the rectangle the mask covers; see
	 VGSoftwareBackend >> maskWith:paint:clip:operator:into:."

	^ self class new
		  setBounds: (self boundsNarrowedTo: aRectangle)
		  shapes: shapes
]

{ #category : 'enumerating' }
VGClip >> pixelsInRowAt: aRow from: aLeft to: aRight do: aBlock [
	"The whole pixels of that row I allow, sampled at the centre of the pixel, which is how an
	 unbounded operator sweeps me: it writes where no source covers, and it writes whole pixels."

	self
		spanFrom: aLeft
		to: aRight
		at: aRow + (1 / 2)
		do: [ :from :to |
			(from - (1 / 2)) ceiling to: (to - (1 / 2)) ceiling - 1 do: [ :x |
				aBlock value: x ] ]
]

{ #category : 'printing' }
VGClip >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPut: $(;
		print: bounds;
		nextPutAll: ', ';
		print: shapes size;
		nextPutAll: ' shapes)'
]

{ #category : 'private' }
VGClip >> setBounds: aRectangle shapes: anArray [
	bounds := aRectangle.
	shapes := anArray
]

{ #category : 'accessing' }
VGClip >> shapes [
	"The scanners of the shapes I was cut out with, empty when I am rectangular."

	^ shapes
]

{ #category : 'clipping' }
VGClip >> spanFrom: aNumber to: anotherNumber at: aSubRow do: aBlock [
	"The parts of that span of a fill I allow, on the line aSubRow. The span is trimmed to my
	 bounds and then to every shape I hold, which is the geometric intersection Cairo performs:
	 spans meet spans and coverages are never multiplied."
	| spans |
	spans := OrderedCollection new.
	self
		addSpanFrom: (aNumber max: bounds left)
		to: (anotherNumber min: bounds right)
		into: spans.
	shapes do: [ :each |
		| trimmed |
		spans isEmpty ifTrue: [ ^ self ].
		trimmed := OrderedCollection new.
		each spansOfPixelRowAt: aSubRow do: [ :from :to |
			spans do: [ :span |
				self
					addSpanFrom: ((span at: 1) max: from)
					to: ((span at: 2) min: to)
					into: trimmed ] ].
		spans := trimmed ].
	spans do: [ :span | aBlock value: (span at: 1) value: (span at: 2) ]
]

{ #category : 'private' }
VGClip >> wholePixelsOf: aRectangle [
	"That rectangle as the whole pixels an aliased clip of it covers. Antialiasing off means one
	 sample at the centre of the pixel, so a pixel is in when its own centre is: measured on a
	 live Cairo context, an aliased clip whose edge falls at 20.5 covers pixel twenty whole and
	 one at 20.75 leaves it alone."

	^ (aRectangle left - 0.5) ceiling @ (aRectangle top - 0.5) ceiling
	  corner: (aRectangle right - 0.5) ceiling @ (aRectangle bottom - 0.5) ceiling
]
