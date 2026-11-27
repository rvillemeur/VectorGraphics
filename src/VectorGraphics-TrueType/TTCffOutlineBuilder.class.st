"
I build the contours of a glyph from steps.

A Type 2 charstring states every point as a step from the point before, and says nothing about where one contour ends: a move ends it. I keep the point reached, open a contour at every move, and answer contours whose points are absolute and in font units.

I drop a contour that was opened and never drawn in, which is what a font writes when one move follows another.

The interpreter reads the bytes and I hold what they draw, so neither of us has to know the other's business.
"
Class {
	#name : 'TTCffOutlineBuilder',
	#superclass : 'Object',
	#instVars : [
		'point',
		'contours',
		'contour'
	],
	#category : 'VectorGraphics-TrueType-CFF',
	#package : 'VectorGraphics-TrueType',
	#tag : 'CFF'
}

{ #category : 'building' }
TTCffOutlineBuilder >> addContours: aCollection [
	"Contours drawn elsewhere, which an accented glyph takes from the two glyphs it is made of."

	contours addAll: aCollection
]

{ #category : 'building' }
TTCffOutlineBuilder >> closeContour [
	"The contour being drawn ends here. One that was opened and never drawn in is dropped."

	contour ifNil: [ ^ self ].
	contour isEmpty ifFalse: [ contours add: contour ].
	contour := nil
]

{ #category : 'accessing' }
TTCffOutlineBuilder >> contours [
	"The contours drawn so far, the one being drawn excepted."

	<archRelation: #many to: #TTCffContour>
	^ contours asArray
]

{ #category : 'building' }
TTCffOutlineBuilder >> curveBy: aFirstPoint by: aSecondPoint by: aThirdPoint [
	"A cubic curve, given as three steps: the two control points and the end point are each a
	 step from the point before."

	| first second |
	first := point + aFirstPoint.
	second := first + aSecondPoint.
	point := second + aThirdPoint.
	contour addSegment: {
			first.
			second.
			point }
]

{ #category : 'initialization' }
TTCffOutlineBuilder >> initialize [
	super initialize.
	point := 0 @ 0.
	contours := OrderedCollection new
]

{ #category : 'inspector' }
TTCffOutlineBuilder >> inspectorContours: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Contours'>
	"One row per contour closed so far. The contour still being drawn is not among them,
	 since it is not closed and may yet be dropped for holding no segment."

	^ aBuilder newTable
		  addColumn: ((SpStringTableColumn title: 'Contour' evaluated: [ :each |
				    (contours indexOf: each) printString ]) width: 80);
		  addColumn: ((SpStringTableColumn title: 'Starts at' evaluated: [ :each |
				    each start printString ]) width: 120);
		  addColumn: (SpStringTableColumn title: 'Segments' evaluated: [ :each |
			   each segments size printString ]);
		  items: contours;
		  yourself
]

{ #category : 'building' }
TTCffOutlineBuilder >> lineBy: aPoint [
	"A straight line, one step long."

	point := point + aPoint.
	contour addSegment: { point }
]

{ #category : 'building' }
TTCffOutlineBuilder >> moveBy: aPoint [
	"Open a contour where the step lands, closing the one being drawn."

	self closeContour.
	point := point + aPoint.
	contour := TTCffContour startingAt: point
]

{ #category : 'accessing' }
TTCffOutlineBuilder >> point [
	"The point reached so far, which every step is counted from."

	^ point
]
