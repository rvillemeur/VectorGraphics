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
VGClip >> extents [
	"What cairo_clip_extents reports: my bounds rounded out to whole pixels, or the origin alone
	 when I allow nothing. Measured on a live Cairo context: a clip whose right edge falls at 20.5
	 reports twenty-one, and two clips that do not meet report 0@0 corner: 0@0."

	self isEmpty ifTrue: [ ^ 0 @ 0 corner: 0 @ 0 ].
	^ bounds left floor @ bounds top floor
	  corner: bounds right ceiling @ bounds bottom ceiling
]

{ #category : 'inspecting' }
VGClip >> inspectorPassed: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Passed'>
	"What a fill of my own extents keeps, one character a pixel, drawn by the real rasteriser
	 with me as its clip. Nothing is restated here: the picture is the coverage a fill through me
	 would paint, so it cannot drift from the rule."
	^ aBuilder newText
		  text: (VGRasteriser
				   segments: (VGSegments rectangle: self extents) coordinates
				   fillRule: #winding
				   clip: self) coverageDrawing;
		  beNotEditable;
		  yourself
]

{ #category : 'inspecting' }
VGClip >> inspectorPassedContext: aContext [
	"A clip of no area passes nothing anywhere, so there is no picture to draw for it."
	aContext active: self isEmpty not
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
