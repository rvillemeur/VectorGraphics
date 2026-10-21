"
I am a mesh rasterised into device pixels: the image Cairo builds for a mesh pattern before it composites it, and nothing more.

Cairo does not evaluate a mesh pattern pixel by pixel. It walks each patch over a grid of its two parameters and writes a pixel for every sample, so the picture has a hard edge: a pixel the patch meets is opaque and a pixel it does not meet is untouched, whatever the fraction of the pixel the patch really covers. I hold that image, as unpremultiplied channels and by whole device pixel, over the bounding box of the patches I was built from.

Three choices of mine are measured against the live library rather than assumed. A sample lands in the pixel whose unit square contains it, which is the truncation of its coordinates. Cairo subdivides a patch until a piece of it is about a pixel across and writes the colour of the middle of that piece, so where a patch covers a pixel once, the colour of the pixel is the colour of the surface at the middle of the pixel, and my samples of one such piece are arbitrated by distance to that middle. Where a patch folds over itself, two pieces far apart in the parameters reach the same pixel, and Cairo writes the lower parameters first, so the later piece keeps the pixel; samples that far apart are arbitrated by which comes later. How close in the parameters two samples must be to count as one piece of Cairo's is sameBranchSteps, which says why.

What is left of the difference is the hard edge itself, one pixel wide, and VGAlexandrieCorpus states it as a colour tolerance with a count of pixels allowed past it.

Unit 1.12 of VECTORCANVAS-PLAN.md implements me.
"
Class {
	#name : 'VGMeshRaster',
	#superclass : 'Object',
	#instVars : [
		'origin',
		'extent',
		'channels',
		'firstParameters',
		'secondParameters',
		'centreDistances',
		'firstStep',
		'secondStep'
	],
	#category : 'VectorGraphics-Cairo-Paint',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Paint'
}

{ #category : 'constants' }
VGMeshRaster class >> channelsPerPixel [
	"Red, green, blue and alpha, unpremultiplied, which is what a paint of this layer answers."

	^ 4
]

{ #category : 'constants' }
VGMeshRaster class >> coordinateSnap [
	"How close to a pixel boundary a sample coordinate has to be before it is read as being on
	 the boundary, in device pixels. A sample is evaluated in floating point from the Bernstein
	 form, so a coordinate that is exactly on a boundary can come out a few units in the last
	 place either side of it: measured, the right hand side of a patch at x = 60 yields
	 59.99999999999999 at some rows, and the pixel at column 60, which Cairo paints, was left
	 empty. A nanopixel is far above that drift and far below anything a patch means to say."
	^ 1.0e-9
]

{ #category : 'constants' }
VGMeshRaster class >> edgeSamplePitch [
	"How far apart two samples of the edge of a patch may be, in device pixels. The grid walk
	 inside the patch reaches every pixel the patch covers by an area of its own, but a pixel the
	 patch only grazes near its edge can fall between two samples of that grid, and Cairo, whose
	 own grid is a different one, paints some of those pixels. A walk of the edge at a pitch well
	 below a pixel reaches every pixel the edge crosses, which is where every grazed pixel is, and
	 it costs a walk of the perimeter rather than of the area."
	^ 0.125
]

{ #category : 'instance creation' }
VGMeshRaster class >> empty [
	"The raster of a mesh with no patch at all, which paints nothing anywhere."

	^ self ofPatches: #()
]

{ #category : 'instance creation' }
VGMeshRaster class >> ofPatches: devicePatches [
	"The raster those patches make, each already carried into device space."

	^ self new setPatches: devicePatches
]

{ #category : 'constants' }
VGMeshRaster class >> sameBranchSteps [
	"How many steps of my own walk two samples may be apart in a parameter and still count as
	 samples of the same piece of the patch. Cairo subdivides a patch until a piece is about a
	 pixel across and draws one pixel for the middle of that piece, so where a patch covers a
	 pixel once, the colour Cairo writes is the colour at the middle of the pixel, and where a
	 patch folds over itself, two pieces far apart in the parameters write the same pixel and the
	 later one wins. My own walk is finer than a pixel, so several of my samples stand for one
	 piece of Cairo's: samples this close in both parameters are arbitrated by distance to the
	 centre of the pixel, as a single piece of Cairo's would be, and samples further apart than
	 this are arbitrated by which comes later. Four steps of a walk whose pitch is half a pixel
	 is two pixels, which is wider than any single pixel can be reached from."
	^ 4
]

{ #category : 'constants' }
VGMeshRaster class >> samplePitch [
	"How far apart two samples of a patch may be, in device pixels. Half a pixel is finer than the
	 pixel a sample lands in, so every pixel a patch reaches is offered a sample near its middle."

	^ 0.5
]

{ #category : 'constants' }
VGMeshRaster class >> unpaintedParameter [
	"The parameter value I store for a pixel no sample has reached. A parameter of a patch runs
	 from zero to one, so any negative value is outside that range and loses to every real
	 sample."
	^ -1.0
]

{ #category : 'reading' }
VGMeshRaster >> bounds [
	"The whole pixels I hold, origin inclusive and corner exclusive."

	^ origin extent: extent
]

{ #category : 'building' }
VGMeshRaster >> boundsOfPatches: devicePatches [
	"The pixels the patches can reach: every pixel whose unit square a control point hull meets.
	 Cairo paints the pixel the far edge of a patch falls on, because it assigns a sample by the
	 truncation of its coordinates, so the far edge contributes a pixel of its own."
	| union |
	devicePatches ifEmpty: [ ^ 0 @ 0 corner: 0 @ 0 ].
	union := devicePatches
		         inject: devicePatches first controlPointBounds
		         into: [ :box :each | box merge: each controlPointBounds ].
	^ (self snappedFloorOf: union origin x) @ (self snappedFloorOf: union origin y)
	  corner: (self snappedFloorOf: union corner x) + 1 @ ((self snappedFloorOf: union corner y) + 1)
]

{ #category : 'private' }
VGMeshRaster >> cellIndexFor: aCoordinate relativeTo: anOriginCoordinate [
	"The column or row a device coordinate falls in, as Cairo assigns it: the truncation of the
	 coordinate, relative to my own origin."
	^ (self snappedFloorOf: aCoordinate) - anOriginCoordinate
]

{ #category : 'private' }
VGMeshRaster >> centreOfPixelAtColumn: column row: row [
	^ origin + (column + 0.5 @ (row + 0.5))
]

{ #category : 'inspector' }
VGMeshRaster >> inspectorPixels: aBuilder [
	<inspectorPresentationOrder: 30 title: 'Pixels'>
	"One row of me per row of the table, as the pixels I painted and the pixels I left alone. A mesh
	 has no antialiasing, so the edge of a patch is where that map steps, and this is the view that
	 shows it. The map asks rgbaAtX:y: at the middle of every pixel rather than reading my channels,
	 so it answers what a compositor would read and cannot drift from it."

	^ aBuilder newTable
		  items: (0 to: extent y - 1);
		  addColumn:
			  (SpStringTableColumn title: 'y' evaluated: [ :row | (origin y + row) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Painted'
				   evaluated: [ :row |
					   String streamContents: [ :out |
						   0 to: extent x - 1 do: [ :column |
							   out nextPut: ((self
									     rgbaAtX: origin x + column + 0.5
									     y: origin y + row + 0.5)
									    ifNil: [ $. ]
									    ifNotNil: [ $# ]) ] ] ]);
		  addColumn: (SpStringTableColumn
				   title: 'Channels at the middle of the row'
				   evaluated: [ :row |
					   (self rgbaAtX: origin x + (extent x / 2) y: origin y + row + 0.5)
						   ifNil: [ 'nothing painted' ]
						   ifNotNil: [ :pixelChannels |
							   (pixelChannels collect: [ :channel | (channel * 255) rounded ])
								   printString ] ]);
		  yourself
]

{ #category : 'inspector' }
VGMeshRaster >> inspectorPixelsContext: aContext [

	aContext active: (extent notNil and: [ extent x > 0 and: [ extent y > 0 ] ])
]

{ #category : 'building' }
VGMeshRaster >> isBetterSampleAt: index u: u v: v squaredDistance: squaredDistance [
	"Whether a sample at those two parameters takes the pixel from the sample it already holds,
	 and record it where it does. Two samples of one piece of the patch are arbitrated by
	 distance to the centre of the pixel, and samples of pieces further apart than
	 sameBranchSteps by which of them Cairo writes later, which is the later pair of parameters.
	 An unpainted pixel holds a parameter outside the range, so the first sample to reach it
	 always wins."
	| heldU heldV takesIt |
	heldU := firstParameters at: index.
	heldU < 0 ifTrue: [ takesIt := true ] ifFalse: [
		heldV := secondParameters at: index.
		takesIt := ((u - heldU) abs <= (firstStep * self class sameBranchSteps) and: [
			             (v - heldV) abs <= (secondStep * self class sameBranchSteps) ])
			           ifTrue: [ squaredDistance < (centreDistances at: index) ]
			           ifFalse: [ u > heldU or: [ u = heldU and: [ v > heldV ] ] ] ].
	takesIt ifFalse: [ ^ false ].
	firstParameters at: index put: u.
	secondParameters at: index put: v.
	centreDistances at: index put: squaredDistance.
	^ true
]

{ #category : 'building' }
VGMeshRaster >> offerAt: aPoint u: u v: v rgba: channelArray [
	"Offer a sample of a patch to the pixel whose unit square holds it, which is the truncation
	 of its coordinates, as Cairo's own rasteriser does. Which sample keeps the pixel is decided
	 by isBetterSampleAt:u:v:squaredDistance:, because Cairo's answer depends on whether the
	 patch covers the pixel once or folds over it."
	| column row index offset |
	column := self cellIndexFor: aPoint x relativeTo: origin x.
	row := self cellIndexFor: aPoint y relativeTo: origin y.
	(column between: 0 and: extent x - 1) ifFalse: [ ^ self ].
	(row between: 0 and: extent y - 1) ifFalse: [ ^ self ].
	index := row * extent x + column + 1.
	offset := aPoint - (self centreOfPixelAtColumn: column row: row).
	(self
		 isBetterSampleAt: index
		 u: u
		 v: v
		 squaredDistance: (offset dotProduct: offset)) ifFalse: [ ^ self ].
	1 to: self class channelsPerPixel do: [ :channel |
		channels
			at: index - 1 * self class channelsPerPixel + channel
			put: (channelArray at: channel) ]
]

{ #category : 'accessing' }
VGMeshRaster >> paintedPixelCount [
	"How many pixels a sample landed in, which is the footprint of the mesh."
	^ firstParameters count: [ :each | each >= 0 ]
]

{ #category : 'printing' }
VGMeshRaster >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPutAll: ' over ';
		print: self bounds;
		nextPutAll: ', ';
		print: self paintedPixelCount;
		nextPutAll: ' pixels painted'
]

{ #category : 'accessing' }
VGMeshRaster >> rgbaAtX: x y: y [
	"The four unpremultiplied channels I hold for the pixel that device point falls in, or nil
	 where no sample of any patch landed. A mesh has a hard edge, so there is no partial pixel
	 here: either a patch reached the pixel or it did not."
	| column row index |
	column := self cellIndexFor: x relativeTo: origin x.
	row := self cellIndexFor: y relativeTo: origin y.
	(column between: 0 and: extent x - 1) ifFalse: [ ^ nil ].
	(row between: 0 and: extent y - 1) ifFalse: [ ^ nil ].
	index := row * extent x + column + 1.
	(firstParameters at: index) < 0 ifTrue: [ ^ nil ].
	^ (1 to: self class channelsPerPixel) collect: [ :channel |
		  channels at: index - 1 * self class channelsPerPixel + channel ]
]

{ #category : 'building' }
VGMeshRaster >> setPatches: devicePatches [
	| bounds cellCount |
	bounds := self boundsOfPatches: devicePatches.
	origin := bounds origin.
	extent := bounds extent.
	cellCount := extent x * extent y.
	channels := Float32Array new: cellCount * self class channelsPerPixel.
	firstParameters := (Float32Array new: cellCount)
		                   atAllPut: self class unpaintedParameter.
	secondParameters := (Float32Array new: cellCount)
		                    atAllPut: self class unpaintedParameter.
	centreDistances := (Float32Array new: cellCount) atAllPut: Float infinity.
	devicePatches do: [ :each |
		self splatPatch: each.
		self splatEdgesOf: each ]
]

{ #category : 'private' }
VGMeshRaster >> snappedFloorOf: aCoordinate [
	"The truncation of a device coordinate, snapped first so that floating point drift does not
	 throw a sample or an edge into the pixel before it. See coordinateSnap."
	^ (aCoordinate roundTo: self class coordinateSnap) floor
]

{ #category : 'building' }
VGMeshRaster >> splatEdgesOf: aPatch [
	"Walk the four edges of the patch at the edge pitch and offer every sample, so that a pixel
	 the patch only grazes is painted here as well. A sample of an edge is still a point of the
	 patch at its own two parameters, so this cannot paint a pixel the patch does not meet, and
	 it is arbitrated by the same rule as the grid, against the grid's own step: an edge sample
	 beside a grid sample of the same piece of the patch has to lose to it on distance to the
	 centre of the pixel rather than win as a later piece. See edgeSamplePitch."
	| steps |
	steps := self
		         stepsAlongBound:
		         (aPatch firstParameterStepBound max: aPatch secondParameterStepBound)
		         pitch: self class edgeSamplePitch.
	0 to: steps do: [ :step |
		| t |
		t := step / steps.
		{ 0 -> t. 1 -> t. t -> 0. t -> 1 } do: [ :parameters |
			self
				offerAt: (aPatch pointAtU: parameters key v: parameters value)
				u: parameters key
				v: parameters value
				rgba: (aPatch rgbaAtU: parameters key v: parameters value) ] ]
]

{ #category : 'building' }
VGMeshRaster >> splatPatch: aPatch [
	"Walk the patch over a grid of its two parameters and offer every sample to the pixel it
	 lands in. The step count of each parameter comes from the patch's own bound on how fast it
	 can move, so a patch that is stretched in one parameter, or near a degenerate corner, is
	 still sampled finely enough to reach every pixel it covers. The colours of the two sides are
	 interpolated once a column, because they do not depend on the second parameter, and the
	 point is one cubic a sample."
	| columns rows |
	columns := self stepsAlongBound: aPatch firstParameterStepBound.
	rows := self stepsAlongBound: aPatch secondParameterStepBound.
	firstStep := 1 / columns.
	secondStep := 1 / rows.
	0 to: columns do: [ :column |
		| u curve nearColors farColors |
		u := column / columns.
		curve := aPatch columnCurveAtU: u.
		nearColors := aPatch rgbaAtU: u betweenCorner: 1 andCorner: 2.
		farColors := aPatch rgbaAtU: u betweenCorner: 4 andCorner: 3.
		0 to: rows do: [ :row |
			| v point |
			v := row / rows.
			point := VGCoonsPatch cubicAt: v of: curve.
			self
				offerAt: point
				u: u
				v: v
				rgba: (aPatch interpolate: nearColors to: farColors at: v) ] ]
]

{ #category : 'private' }
VGMeshRaster >> stepsAlongBound: aDistance [
	^ self stepsAlongBound: aDistance pitch: self class samplePitch
]

{ #category : 'private' }
VGMeshRaster >> stepsAlongBound: aDistance pitch: aPitch [
	"How many steps a walk takes to cross a patch whose points can move that far, so that two
	 neighbouring samples stay within that pitch of each other. A patch smaller than one step
	 still takes one."
	^ (aDistance / aPitch) ceiling max: 1
]
