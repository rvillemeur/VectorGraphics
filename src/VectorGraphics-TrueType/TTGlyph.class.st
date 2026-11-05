"
One simple glyph from a TrueType font, holding its outline geometry and metrics.

Created by TTFontReader during font loading and stored inside TTFontDescription.
At render time, TTFontDescription draws each glyph's contours onto a VectorCanvas
via `addContourDataTo:stream tx:`, which walks the contours and emits Bézier curves.

Subclass: TTCompositeGlyph (a glyph built from references to other TTGlyphs).

## Key instVars
- `boundsLeft/Right/Top/Bottom`  glyph bounding box in font design units
- `contours`                     Array of TTContourConstruction (outline segments)
- `advanceWidth`                 horizontal advance in font design units
- `leftSideBearing`              distance from origin to leftmost outline point
- `rightSideBearing`             distance from rightmost point to the advance width

## Key methods
- `addContourDataTo: stream tx: transformation` — emits path data (move/line/curve)
  for rendering onto a VectorCanvas or collecting into TTFontDescription's contour cache
- `boundsLeft`, `boundsTop`, `boundsRight`, `boundsBottom` — metric accessors
- `advanceWidth` — used by TrueTypeFont for character spacing
"
Class {
	#name : 'TTGlyph',
	#superclass : 'Object',
	#instVars : [
		'boundsLeft',
		'boundsRight',
		'boundsTop',
		'boundsBottom',
		'contours',
		'advanceWidth',
		'leftSideBearing',
		'rightSideBearing'
	],
	#category : 'VectorGraphics-TrueType-Glyphs',
	#package : 'VectorGraphics-TrueType',
	#tag : 'Glyphs'
}

{ #category : 'primitive format' }
TTGlyph >> addContourDataTo: stream [

	stream nextPut: self advanceWidth.
	stream nextPut: self boundsLeft.
	stream nextPut: self boundsRight.
	stream nextPut: self boundsTop.
	stream nextPut: self boundsBottom.
	stream nextPut: self contourCount.
	self addContourDataTo: stream tx: nil
]

{ #category : 'primitive format' }
TTGlyph >> addContourDataTo: stream tx: aGeometryTransformationOrNil [

	contours do: [ :c | 
		c addContourDataTo: stream tx: aGeometryTransformationOrNil ]
]

{ #category : 'accessing' }
TTGlyph >> advanceWidth [

	^ advanceWidth
]

{ #category : 'accessing' }
TTGlyph >> advanceWidth: aNumber [

	advanceWidth := aNumber
]

{ #category : 'accessing' }
TTGlyph >> boundsBottom [

	^ boundsBottom
	"
	boundsRight
	boundsTop
	boundsBottom
	"
]

{ #category : 'accessing' }
TTGlyph >> boundsLeft [

	^ boundsLeft
	"
	boundsRight
	boundsTop
	boundsBottom
	"
]

{ #category : 'accessing' }
TTGlyph >> boundsLeft: bl boundsRight: br boundsTop: bt boundsBottom: bm [

	boundsLeft := bl.
	boundsRight := br.
	boundsTop := bt.
	boundsBottom := bm
]

{ #category : 'accessing' }
TTGlyph >> boundsRight [

	^ boundsRight
	"
	boundsRight
	boundsTop
	boundsBottom
	"
]

{ #category : 'accessing' }
TTGlyph >> boundsTop [

	^ boundsTop
	"
	boundsRight
	boundsTop
	boundsBottom
	"
]

{ #category : 'accessing' }
TTGlyph >> contourCount [

	^ contours count: [ :each | each isEmpty not ]
]

{ #category : 'accessing' }
TTGlyph >> contours [

	^ contours
]

{ #category : 'accessing' }
TTGlyph >> contours: aCollection [

	contours := aCollection asArray
]

{ #category : 'drawing' }
TTGlyph >> drawGlyphOn: aVectorCanvas [

	self drawGlyphOn: aVectorCanvas geometryTransformation: nil
]

{ #category : 'drawing' }
TTGlyph >> drawGlyphOn: aVectorCanvas geometryTransformation: txOrNil [

	contours do: [ :contour | 
		contour isEmpty ifFalse: [ 
			aVectorCanvas moveToX: 0 y: 0.
			(contour initialMoveToCommand: txOrNil) runOn: aVectorCanvas.
			(contour pathCommand: txOrNil) runOn: aVectorCanvas ] ]
]

{ #category : 'initialization' }
TTGlyph >> initialize [

	super initialize.
	boundsLeft := boundsRight := boundsTop := boundsBottom := 0.
	contours := #(  ).
	advanceWidth := 0.
	leftSideBearing := 0.
	rightSideBearing := 0
]

{ #category : 'private-initialization' }
TTGlyph >> initializeContours: numContours with: endPoints [

	"Initialize the contours for creation of the glyph."

	| startPt pts endPt |
	contours := Array new: numContours.
	startPt := -1.
	1 to: numContours do: [ :i | 
		endPt := endPoints at: i.
		pts := Int16PointArray new: endPt - startPt.
		contours at: i put: (TTContourConstruction on: pts).
		startPt := endPt ]
]

{ #category : 'inspector' }
TTGlyph >> inspectorContourEntries [
	"Measure each contour the way the drawing code reads it. An empty contour is reported as
	such rather than skipped, since drawGlyphOn:geometryTransformation: skips one silently."

	^ contours collectWithIndex: [ :contour :index |
		  | straight curved bounds |
		  straight := 0.
		  curved := 0.
		  bounds := nil.
		  contour isEmpty ifFalse: [
			  contour quadraticBeziersDo: [ :endPoint :controlPoint |
				  endPoint = controlPoint
					  ifTrue: [ straight := straight + 1 ]
					  ifFalse: [ curved := curved + 1 ] ].
			  contour points do: [ :point |
				  bounds := bounds
					            ifNil: [ point corner: point ]
					            ifNotNil: [ bounds encompass: point ] ] ].
		  {
			  index .
			  contour points size .
			  straight .
			  curved .
			  (bounds ifNil: [ 'no point' ]) } ]
]

{ #category : 'inspector' }
TTGlyph >> inspectorContours: aBuilder [
	<inspectorPresentationOrder: 20 title: 'Contours'>
	"One row per contour, with the segments counted by asking quadraticBeziersDo: rather than by
	reading the flags again: a straight segment is the one whose control point is its end point,
	which is the rule that method itself applies."

	^ aBuilder newTable
		  addColumn: ((SpStringTableColumn title: 'Contour' evaluated: [ :each | each first printString ]) width: 80);
		  addColumn: ((SpStringTableColumn title: 'Points' evaluated: [ :each | each second printString ]) width: 80);
		  addColumn: ((SpStringTableColumn title: 'Straight segments' evaluated: [ :each | each third printString ]) width: 140);
		  addColumn: ((SpStringTableColumn title: 'Quadratic Beziers' evaluated: [ :each | each fourth printString ]) width: 140);
		  addColumn: (SpStringTableColumn title: 'Point bounds' evaluated: [ :each | each fifth printString ]);
		  items: self inspectorContourEntries;
		  yourself
]

{ #category : 'inspector' }
TTGlyph >> inspectorPointExtent [
	"The extent a form needs to hold every point of this glyph, read from the points themselves
	rather than from the bounds the font file declared, so a glyph whose bounds are missing still
	draws. One pixel is added because a point sits on the edge of the form it draws in."

	| right bottom |
	right := 0.
	bottom := 0.
	contours do: [ :contour |
		contour points do: [ :point |
			right := right max: point x.
			bottom := bottom max: point y ] ].
	^ (right + 1) @ (bottom + 1)
]

{ #category : 'testing' }
TTGlyph >> isComposite [

	^ false
]

{ #category : 'accessing' }
TTGlyph >> leftSideBearing [

	^ leftSideBearing
]

{ #category : 'accessing' }
TTGlyph >> leftSideBearing: aNumber [

	leftSideBearing := aNumber
]

{ #category : 'private-initialization' }
TTGlyph >> makePointsAbsolute [

	"Build the contours in the receiver glyph.
	The contour is constructed by converting the points
	form each contour into an absolute value and then
	compressing the contours into PointArrays."

	| contourOrigin |
	contourOrigin := 0 @ 0.
	contours do: [ :contour | 
		contourOrigin := contour makePointsAbsolute: contourOrigin ]
]

{ #category : 'printing' }
TTGlyph >> printOn: aStream [

	aStream
		nextPutAll: self class name;
		nextPut: $(;
		print: (contours ifNil: [ 0 ] ifNotNil: [ contours size ]);
		nextPut: $)
]

{ #category : 'private-initialization' }
TTGlyph >> replaceIndexesByComponentGlyphsIn: dummy [

	"NOP"

	
]

{ #category : 'accessing' }
TTGlyph >> rightSideBearing [

	^ rightSideBearing
]

{ #category : 'accessing' }
TTGlyph >> rightSideBearing: aNumber [

	rightSideBearing := aNumber
]

{ #category : 'accessing' }
TTGlyph >> topSideBearing [

	"
	https://www.freetype.org/freetype2/docs/glyphs/glyphs-3.html
	"

	^ boundsBottom
]

{ #category : 'private-initialization' }
TTGlyph >> updateRightSideBearing [

	"Update the right side bearing value"

	"@@: Is the following really correct?!?!"

	rightSideBearing := advanceWidth - leftSideBearing - boundsRight
	                    + boundsLeft
]
