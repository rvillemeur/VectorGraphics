"
I am one Coons patch of a mesh pattern: a bicubic surface over the unit square, named by its four boundary curves, with a colour at each of my four corners.

A caller names me by twelve boundary control points, in Cairo's own order: corner zero, the two control points of the side leaving it, corner one, and so on round me, the fourth side closing back to corner zero. The surface is a tensor product of sixteen control points, so the four interior ones are computed by the Coons conversion the PDF type six shading declares, which is what Cairo computes in `_calc_control_point`. The first parameter runs along the first side, from corner zero to corner one; the second runs down the fourth side, from corner zero to corner three. A colour is bilinear in those two parameters, unpremultiplied and in floating point.

A patch of three sides is closed with a straight line and its fourth side is a point: corner three sits on corner zero and carries corner zero's colour, which is how Cairo draws a Gouraud shaded triangle.

Unit 1.12 of VECTORCANVAS-PLAN.md implements me. `VGMeshRaster` walks me, and `VGMeshPaint` is the paint a mesh pattern hands to the backend.
"
Class {
	#name : 'VGCoonsPatch',
	#superclass : 'Object',
	#instVars : [
		'points',
		'colors'
	],
	#category : 'VectorGraphics-Cairo-Paint',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Paint'
}

{ #category : 'instance creation' }
VGCoonsPatch class >> boundary: twelvePoints colors: fourColors [
	"The patch those twelve boundary control points and four corner colours name. The points run
	 in Cairo's order: corner zero, the two control points of the side leaving it, corner one, and
	 so on round the patch, the fourth side closing back to corner zero."

	^ self new setBoundary: twelvePoints colors: fourColors
]

{ #category : 'constants' }
VGCoonsPatch class >> boundaryGridPositions [
	"Where the twelve boundary control points sit in the four by four grid, in the order a caller
	 names them: the first side along the first row, the second down the last column, the third
	 back along the last row, and the fourth up the first column."

	^ #( #( 1 1 ) #( 1 2 ) #( 1 3 ) #( 1 4 ) #( 2 4 ) #( 3 4 ) #( 4 4 ) #( 4 3 )
	   #( 4 2 ) #( 4 1 ) #( 3 1 ) #( 2 1 ) )
]

{ #category : 'converting' }
VGCoonsPatch class >> channelsOf: aColorOrChannels [
	"A corner is named by a Pharo Color, or by the four channels of one, because a corner a caller
	 never sets is transparent black and is named as channels."

	^ aColorOrChannels isCollection
		  ifTrue: [ aColorOrChannels asArray ]
		  ifFalse: [ VGPaint rgbaOf: aColorOrChannels ]
]

{ #category : 'constants' }
VGCoonsPatch class >> coonsConversionWeights [
	"The weights of the Coons conversion, which turns the twelve boundary control points of a
	 patch into the sixteen of the tensor product surface Cairo draws. One interior point is a
	 weighted sum of the near corner, the two boundary points beside it, the far corner along each
	 of its two sides, the two boundary points beside the far corners, and the opposite corner.
	 The PDF type six shading declares the same conversion, and Cairo computes it in
	 `_calc_control_point`."

	^ {
		  (#nearCorner -> -4).
		  (#beside -> 6).
		  (#farCorners -> -2).
		  (#besideTheFarCorners -> 3).
		  (#oppositeCorner -> -1).
		  (#divisor -> 9) }
]

{ #category : 'constants' }
VGCoonsPatch class >> cornerGridPositions [
	"Where the four corners sit in the grid, in the order their colours are given: corner zero at
	 the start of the first side, then corner one, corner two and corner three round the patch."

	^ #( #( 1 1 ) #( 1 4 ) #( 4 4 ) #( 4 1 ) )
]

{ #category : 'evaluating' }
VGCoonsPatch class >> cubicAt: t of: fourPoints [
	"The point a cubic Bezier of those four control points reaches at that parameter, by the
	 Bernstein form, which is how every curve of this layer is evaluated."

	| s |
	s := 1.0 - t.
	^ (fourPoints first * (s * s * s))
	  + (fourPoints second * (3.0 * s * s * t))
	  + (fourPoints third * (3.0 * s * t * t))
	  + (fourPoints fourth * (t * t * t))
]

{ #category : 'constants' }
VGCoonsPatch class >> cubicDerivativeFactor [
	"The derivative of a cubic Bezier is three times the difference of two neighbouring control
	 points, and the Bernstein weights of a tensor patch are a convex combination, so three times
	 the largest difference bounds how fast the surface can move."
	^ 3
]

{ #category : 'inspector' }
VGCoonsPatch class >> inspectorSampleCount [
	"How many values of a parameter the surface view shows. Five gives both ends, the middle and
	 the quarters, which is enough to read a bilinear colour and a bent side off the table."

	^ 5
]

{ #category : 'constants' }
VGCoonsPatch class >> interiorGridPositions [
	"The four control points of the grid that no side names, and that the Coons conversion
	 computes."

	^ #( #( 2 2 ) #( 2 3 ) #( 3 2 ) #( 3 3 ) )
]

{ #category : 'constants' }
VGCoonsPatch class >> pointsPerSide [
	"Each side of a patch is stored as a cubic, so it contributes two control points and the
	 corner it ends at."
	^ self boundaryGridPositions size / self sideCount
]

{ #category : 'constants' }
VGCoonsPatch class >> sideCount [
	"A patch has four sides, which is what makes its surface a tensor product of four by four
	 control points."

	^ 4
]

{ #category : 'constants' }
VGCoonsPatch class >> straightSideFractions [
	"Where the two control points of a cubic sit when the side is to run straight from one corner
	 to the next. Cairo keeps every side as a cubic, so a line is this cubic."
	^ { 1 / 3. 2 / 3 }
]

{ #category : 'evaluating' }
VGCoonsPatch >> columnCurveAtU: u [
	"The four control points of the curve my surface runs along as the second parameter grows, at
	 that value of the first. A walk of the surface evaluates this once a column and then only one
	 cubic a sample."

	^ (1 to: self class sideCount) collect: [ :row |
		  self class
			  cubicAt: u
			  of: ((1 to: self class sideCount) collect: [ :column |
					   self controlPointAtRow: row column: column ]) ]
]

{ #category : 'accessing' }
VGCoonsPatch >> controlPointAtRow: row column: column [
	"One of my sixteen control points, by row and column of the grid. The row is the second
	 parameter and the column the first, which is Cairo's own order."

	^ (points at: row) at: column
]

{ #category : 'accessing' }
VGCoonsPatch >> controlPointBounds [
	"The rectangle my sixteen control points fit in. A Bezier surface stays inside the convex
	 hull of its control points, so my picture stays inside this, which is what a rasteriser
	 needs to know before it allocates anything."

	^ Rectangle encompassing: (points flatCollect: [ :row | row ])
]

{ #category : 'initialization' }
VGCoonsPatch >> convertedInteriorPointAtRow: row column: column [
	"The interior control point of the tensor product surface at that place of the grid, as the
	 Coons conversion states it. Near and far are read from the place itself: the near row and
	 column are the side the point sits against, the far ones the sides opposite."

	| weights nearRow farRow nearColumn farColumn weightAt |
	weights := self class coonsConversionWeights.
	weightAt := [ :name |
	             (weights detect: [ :each | each key = name ]) value ].
	nearRow := row = 2
		           ifTrue: [ 1 ]
		           ifFalse: [ self class sideCount ].
	farRow := self class sideCount + 1 - nearRow.
	nearColumn := column = 2
		              ifTrue: [ 1 ]
		              ifFalse: [ self class sideCount ].
	farColumn := self class sideCount + 1 - nearColumn.
	^ ((self controlPointAtRow: nearRow column: nearColumn)
	   * (weightAt value: #nearCorner)
	   + (((self controlPointAtRow: nearRow column: column)
		    + (self controlPointAtRow: row column: nearColumn))
		   * (weightAt value: #beside))
	   + (((self controlPointAtRow: nearRow column: farColumn)
		    + (self controlPointAtRow: farRow column: nearColumn))
		   * (weightAt value: #farCorners))
	   + (((self controlPointAtRow: farRow column: column)
		    + (self controlPointAtRow: row column: farColumn))
		   * (weightAt value: #besideTheFarCorners))
	   + ((self controlPointAtRow: farRow column: farColumn)
		    * (weightAt value: #oppositeCorner)))
	  / (weightAt value: #divisor)
]

{ #category : 'accessing' }
VGCoonsPatch >> cornerChannels [
	"The four unpremultiplied channel arrays of my corners, in the order corner zero to corner
	 three."

	^ colors
]

{ #category : 'initialization' }
VGCoonsPatch >> fillInteriorControlPoints [
	"The Coons conversion. It is affine in the control points, so a patch carried into device
	 space by a matrix answers the same interior points whether they are converted before the
	 transformation or after it, and this is sent on every patch however its grid arrived."

	self class interiorGridPositions do: [ :position |
		(points at: position first)
			at: position second
			put: (self convertedInteriorPointAtRow: position first
					 column: position second) ]
]

{ #category : 'accessing' }
VGCoonsPatch >> firstParameterStepBound [
	"How far my surface can move while the first parameter crosses its whole range. The bound is
	 read from the control points, so a walk can choose a step count that keeps two samples
	 within a given distance of each other wherever the patch is stretched."
	^ self class cubicDerivativeFactor * (self largestNeighbourDistanceAlongRows: true)
]

{ #category : 'initialization' }
VGCoonsPatch >> gridFromBoundary: twelvePoints [
	"The four by four grid those boundary points sit on, with the interior left empty for the
	 conversion to fill."

	| grid |
	grid := (1 to: self class sideCount) collect: [ :each |
		        Array new: self class sideCount ].
	self class boundaryGridPositions doWithIndex: [ :position :index |
		(grid at: position first)
			at: position second
			put: (twelvePoints at: index) ].
	^ grid
]

{ #category : 'inspector' }
VGCoonsPatch >> inspectorSurface: aBuilder [
	<inspectorPresentationOrder: 30 title: 'Surface'>
	"The surface I stand for, read at a grid of my two parameters: one row per value of the second
	 parameter, one column per value of the first, each cell the point that pair of parameters lands
	 on and the colour there. The cells send pointAtU:v: and rgbaAtU:v:, so the view states nothing
	 of the Coons rule itself and follows every change to it."

	| samples table |
	samples := (0 to: self class inspectorSampleCount - 1) collect: [ :step |
		           step / (self class inspectorSampleCount - 1) ].
	table := aBuilder newTable
		         items: samples;
		         addColumn: (SpStringTableColumn
				          title: 'v'
				          evaluated: [ :v | v asFloat printShowingDecimalPlaces: 2 ]);
		         yourself.
	samples do: [ :u |
		table addColumn: (SpStringTableColumn
				 title: 'u = ' , (u asFloat printShowingDecimalPlaces: 2)
				 evaluated: [ :v |
					 | point channels |
					 point := self pointAtU: u v: v.
					 channels := self rgbaAtU: u v: v.
					 point x rounded printString , ' @ ' , point y rounded printString , ' '
					 , (channels collect: [ :channel | (channel * 255) rounded ]) printString ]) ].
	^ table
]

{ #category : 'inspector' }
VGCoonsPatch >> inspectorSurfaceContext: aContext [

	aContext active: points notNil
]

{ #category : 'evaluating' }
VGCoonsPatch >> interpolate: firstChannels to: secondChannels at: aFraction [
	"Unpremultiplied and in floating point, as a gradient's stops interpolate, and for the same
	 reason: a transparent corner ramping to an opaque one keeps its own hue."

	^ (1 to: firstChannels size) collect: [ :index |
		  | from |
		  from := firstChannels at: index.
		  from + (((secondChannels at: index) - from) * aFraction) ]
]

{ #category : 'private' }
VGCoonsPatch >> largestNeighbourDistanceAlongRows: alongRows [
	"The longest step between two neighbouring control points of my grid, taken along a row when
	 asked for the first parameter and down a column when asked for the second."
	| largest |
	largest := 0.
	1 to: self class sideCount do: [ :first |
		1 to: self class sideCount - 1 do: [ :second |
			| from to |
			from := alongRows
				        ifTrue: [ self controlPointAtRow: first column: second ]
				        ifFalse: [ self controlPointAtRow: second column: first ].
			to := alongRows
				      ifTrue: [ self controlPointAtRow: first column: second + 1 ]
				      ifFalse: [ self controlPointAtRow: second + 1 column: first ].
			largest := largest max: (to - from) r ] ].
	^ largest
]

{ #category : 'evaluating' }
VGCoonsPatch >> pointAtU: u v: v [
	"The point of my surface at those two parameters. The first runs along my first side, from
	 corner zero to corner one, and the second down my fourth side, from corner zero to corner
	 three."

	^ self class cubicAt: v of: (self columnCurveAtU: u)
]

{ #category : 'printing' }
VGCoonsPatch >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPutAll: ' corner zero at ';
		print: (self controlPointAtRow: 1 column: 1);
		nextPutAll: ' within ';
		print: self controlPointBounds
]

{ #category : 'evaluating' }
VGCoonsPatch >> rgbaAtU: u betweenCorner: firstCorner andCorner: secondCorner [
	^ self
		  interpolate: (colors at: firstCorner)
		  to: (colors at: secondCorner)
		  at: u
]

{ #category : 'evaluating' }
VGCoonsPatch >> rgbaAtU: u v: v [
	"The four unpremultiplied channels my corner colours interpolate to at those two parameters,
	 bilinearly and in floating point. Corners zero and one run along the first parameter, corners
	 three and two along the second, which is the order `cornerGridPositions` names them in."

	^ self
		  interpolate: (self rgbaAtU: u betweenCorner: 1 andCorner: 2)
		  to: (self rgbaAtU: u betweenCorner: 4 andCorner: 3)
		  at: v
]

{ #category : 'accessing' }
VGCoonsPatch >> secondParameterStepBound [
	"The same bound for the second parameter; see firstParameterStepBound."
	^ self class cubicDerivativeFactor * (self largestNeighbourDistanceAlongRows: false)
]

{ #category : 'initialization' }
VGCoonsPatch >> setBoundary: twelvePoints colors: fourColors [
	| grid |
	grid := self gridFromBoundary: twelvePoints.
	self
		setGrid: grid
		colors: (fourColors collect: [ :each | self class channelsOf: each ])
]

{ #category : 'initialization' }
VGCoonsPatch >> setGrid: aGrid colors: fourChannelArrays [
	points := aGrid.
	colors := fourChannelArrays.
	self fillInteriorControlPoints
]

{ #category : 'transforming' }
VGCoonsPatch >> transformedBy: aMatrix [
	"A patch of mine carried through that matrix, which is how a mesh named in pattern space
	 reaches the device space it is rasterised in. I am left as I was."

	^ self class new
		  setGrid: (points collect: [ :row |
					   row collect: [ :each | aMatrix value: each ] ])
		  colors: colors;
		  yourself
]
