"
I am the replacement for AeCairoMeshPattern: the pattern a caller builds patch by patch.

Between `beginPatch` and `endPatch` a caller moves to the first corner, names three or four sides with lines and curves, and sets a colour at each corner. `endPatch` closes a patch of fewer than four sides with a straight line and hands it to my paint as a `VGCoonsPatch`; a patch of fewer than three sides is dropped, as Cairo puts its pattern in error and paints nothing. A corner whose colour is never set is transparent black, which is Cairo's own default.

No method of Bloc or of Alexandrie's canvas builds a mesh pattern, so I exist for the Alexandrie experiment corpus and for a caller that names Cairo's own API, which is why unit 1.12 comes last in phase 1.
"
Class {
	#name : 'VGCairoMeshPattern',
	#superclass : 'VGCairoPattern',
	#instVars : [
		'patchPoints',
		'patchColors',
		'insidePatch'
	],
	#category : 'VectorGraphics-Cairo-Pattern',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Pattern'
}

{ #category : 'constants' }
VGCairoMeshPattern class >> boundaryPointCount [
	"How many control points a finished patch hands to VGCoonsPatch."
	^ VGCoonsPatch boundaryGridPositions size
]

{ #category : 'constants' }
VGCairoMeshPattern class >> leastExplicitSideCount [
	"Cairo needs three sides to draw a patch, and the third may be the line endPatch closes the
	 patch with, so two sides from the caller are enough. One is not: measured against the
	 library, a patch of a single side paints no pixel at all."
	^ 2
]

{ #category : 'accessing' }
VGCairoMeshPattern class >> paintClass [
	"The paint class that holds what a pattern of mine means to the backend."
	^ VGMeshPaint
]

{ #category : 'constants' }
VGCairoMeshPattern class >> unsetCornerColor [
	"The colour of a corner the caller never named. Measured against the library: a four sided
	 patch whose fourth corner is unset fades to nothing along that side, so the corner is
	 transparent black."
	^ Color transparent
]

{ #category : 'private' }
VGCairoMeshPattern >> addStraightSideTo: aPoint [
	"The side itself, without the check that a patch is open, because endPatch closes a short
	 patch after the caller has finished with it."
	| from |
	from := patchPoints last.
	VGCoonsPatch straightSideFractions do: [ :fraction |
		patchPoints add: from + (aPoint - from * fraction) ].
	patchPoints add: aPoint
]

{ #category : 'private' }
VGCairoMeshPattern >> assertInsidePatch [
	insidePatch ifFalse: [ ^ self error: 'a patch point belongs between beginPatch and endPatch' ]
]

{ #category : 'building' }
VGCairoMeshPattern >> beginPatch [
	"The points and corner colours that follow belong to one patch, until endPatch. A corner the
	 caller never names stays nil and is read as the unset corner colour."
	insidePatch := true.
	self discardPatch
]

{ #category : 'building' }
VGCairoMeshPattern >> cornerAt: zeroBasedIndex putColor: aColor [
	"Cairo numbers the corners of a patch from zero; this layer keeps them in a list from one."
	self assertInsidePatch.
	patchColors at: zeroBasedIndex + 1 put: aColor
]

{ #category : 'building' }
VGCairoMeshPattern >> cornerAt: zeroBasedIndex putColorRGB: aColor [
	"Cairo has a call for each of rgb and rgba, and the rgb one leaves the corner opaque whatever
	 alpha the colour carries."
	^ self cornerAt: zeroBasedIndex putColor: (aColor alpha: 1.0)
]

{ #category : 'building' }
VGCairoMeshPattern >> cornerAt: zeroBasedIndex putColorRGBA: aColor [
	^ self cornerAt: zeroBasedIndex putColor: aColor
]

{ #category : 'building' }
VGCairoMeshPattern >> cornerAt: zeroBasedIndex putR: r g: g b: b [
	^ self cornerAt: zeroBasedIndex putColor: (Color r: r g: g b: b)
]

{ #category : 'building' }
VGCairoMeshPattern >> cornerAt: zeroBasedIndex putR: r g: g b: b a: a [
	^ self cornerAt: zeroBasedIndex putColor: ((Color r: r g: g b: b) alpha: a)
]

{ #category : 'building' }
VGCairoMeshPattern >> cornerColors: aSequenceOfColors [
	"The corners in order, named from one, which is the convenience Alexandrie publishes."
	aSequenceOfColors doWithIndex: [ :aColor :index |
		self cornerAt: index - 1 putColor: aColor ]
]

{ #category : 'building' }
VGCairoMeshPattern >> curveVia: firstControl via: secondControl to: aPoint [
	"A cubic side. With no current point Cairo starts the patch at the first control point, as it
	 documents."
	self assertInsidePatch.
	patchPoints ifEmpty: [ self moveTo: firstControl ].
	patchPoints
		add: firstControl;
		add: secondControl;
		add: aPoint
]

{ #category : 'building' }
VGCairoMeshPattern >> curveViaX: x1 y: y1 viaX: x2 y: y2 toX: x3 y: y3 [
	^ self curveVia: x1 @ y1 via: x2 @ y2 to: x3 @ y3
]

{ #category : 'private' }
VGCairoMeshPattern >> discardPatch [
	"Forget the patch under construction, which is what both beginPatch and a patch the library
	 would refuse leave behind."
	patchPoints := OrderedCollection new.
	patchColors := Array new: VGCoonsPatch sideCount
]

{ #category : 'building' }
VGCairoMeshPattern >> endPatch [
	"Close the patch and hand it to the paint. Cairo closes a patch of fewer than four sides with
	 a straight line to its first corner, and the closing loop below writes that line; a patch of
	 three sides gets a second, degenerate line, which is how Cairo carries a triangle. A patch
	 the library would refuse draws nothing, so it is dropped here: measured, a mesh whose only
	 patch has one side paints no pixel. The fourth corner of a triangle takes the first corner's
	 colour unless the caller named it, which is also measured."
	| explicitSides |
	insidePatch := false.
	explicitSides := self explicitSideCount.
	(explicitSides between: self class leastExplicitSideCount and: VGCoonsPatch sideCount)
		ifFalse: [ ^ self discardPatch ].
	[ self explicitSideCount < VGCoonsPatch sideCount ] whileTrue: [
		self addStraightSideTo: patchPoints first ].
	(explicitSides = self class leastExplicitSideCount
	 and: [ (patchColors at: VGCoonsPatch sideCount) isNil ]) ifTrue: [
		patchColors at: VGCoonsPatch sideCount put: patchColors first ].
	paint addPatch: (VGCoonsPatch
			 boundary: (patchPoints first: self class boundaryPointCount)
			 colors: (patchColors collect: [ :each |
					  each ifNil: [ self class unsetCornerColor ] ])).
	self discardPatch
]

{ #category : 'private' }
VGCairoMeshPattern >> explicitSideCount [
	"How many sides the caller has named. The first corner is one point and every side after it
	 adds its control points and the corner it ends at."
	^ patchPoints size - 1 // VGCoonsPatch pointsPerSide
]

{ #category : 'initialization' }
VGCairoMeshPattern >> initialize [
	super initialize.
	insidePatch := false.
	self discardPatch
]

{ #category : 'inspector' }
VGCairoMeshPattern >> inspectorPatches: aBuilder [
	<inspectorPresentationOrder: 30 title: 'Patches'>
	"The patches I was built from, one per row: where the patch sits, the colour at each of its four
	 corners, and the colour at the middle of its surface. A corner nobody set carries the colour an
	 unset corner takes, which the cells read from the patch rather than naming, so the view follows
	 what a patch really does with a side or a colour that was left out."

	^ aBuilder newTable
		  items: self patches;
		  addColumn: (SpStringTableColumn
				   title: 'Bounds'
				   evaluated: [ :patch | patch controlPointBounds printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Corner colours'
				   evaluated: [ :patch |
					   (patch cornerChannels collect: [ :channels |
							    channels collect: [ :channel | (channel * 255) rounded ] ])
						   printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Middle colour'
				   evaluated: [ :patch |
					   ((patch rgbaAtU: 0.5 v: 0.5) collect: [ :channel |
						    (channel * 255) rounded ]) printString ]);
		  yourself
]

{ #category : 'inspector' }
VGCairoMeshPattern >> inspectorPatchesContext: aContext [

	aContext active: self patches isEmptyOrNil not
]

{ #category : 'building' }
VGCairoMeshPattern >> lineTo: aPoint [
	"A straight side, written as the cubic that runs straight: Cairo stores every side of a patch
	 as a cubic, and the straight one has its control points at the thirds. With no current point
	 this is a move, as Cairo documents."
	self assertInsidePatch.
	patchPoints ifEmpty: [ ^ self moveTo: aPoint ].
	self addStraightSideTo: aPoint
]

{ #category : 'building' }
VGCairoMeshPattern >> lineToX: x y: y [
	^ self lineTo: x @ y
]

{ #category : 'building' }
VGCairoMeshPattern >> moveTo: aPoint [
	"The first corner of the patch, in pattern space."
	self assertInsidePatch.
	patchPoints ifNotEmpty: [ ^ self error: 'a patch starts at one point' ].
	patchPoints add: aPoint
]

{ #category : 'building' }
VGCairoMeshPattern >> moveToX: x y: y [
	^ self moveTo: x @ y
]

{ #category : 'accessing' }
VGCairoMeshPattern >> patches [
	"The patches my paint has taken, in the order they were ended."
	^ paint patches
]
