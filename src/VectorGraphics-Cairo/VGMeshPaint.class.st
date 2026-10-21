"
I am the paint of a mesh pattern: tag four of the frozen paint ABI, a list of Coons patches, and the device raster they make.

My patches are named in pattern space, and my matrix maps a device point into that space as every paint's does, so the raster is built from the patches carried the other way, through the inverse of that matrix, exactly as Cairo transforms a mesh by the inverse of the pattern matrix before it rasterises it. A matrix that cannot be inverted maps nothing and I paint nothing.

The patches travel beside the coefficient block, as a gradient's stops do, because there is no room in sixteen floats for sixteen control points and four colours a patch; the block carries how many patches there are. My extend mode and my filter are read like every other paint's and say nothing, because a mesh is painted where its patches are and nowhere else: Cairo hands a mesh to the compositor as an image, not as a function of the plane.

Unit 1.12 of VECTORCANVAS-PLAN.md implements me, and `VGMeshTest` holds me to the live library.
"
Class {
	#name : 'VGMeshPaint',
	#superclass : 'VGPaint',
	#instVars : [
		'patches',
		'raster'
	],
	#category : 'VectorGraphics-Cairo-Paint',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Paint'
}

{ #category : 'inspector' }
VGMeshPaint class >> inspectorSampleCount [
	"How many points of the diagonal of my raster the mesh view reads. Nine crosses a patch from
	 one corner to the other through its middle, which is where a bilinear colour and a fold are
	 both visible."

	^ 9
]

{ #category : 'constants' }
VGMeshPaint class >> paintTag [
	"Four, which is what cairo_pattern_type_t calls a mesh, so a mesh paint and the pattern that
	 built it carry the same number as every other paint does."

	^ 4
]

{ #category : 'constants' }
VGMeshPaint class >> patchCountFieldIndex [
	"Field nine of the block holds how many patches travel beside it. Sixteen control points and
	 four colours a patch do not fit in sixteen floats, so the patches are carried as a gradient's
	 stops are, and the block says how many there are."

	^ 9
]

{ #category : 'building' }
VGMeshPaint >> addPatch: aPatch [
	"A patch named in pattern space. The raster goes, because it was built from the patches I had
	 before: Cairo keeps a reference to a pattern, so a patch added after the pattern was made the
	 source is painted."

	patches add: aPatch.
	raster := nil.
	self recordPatchCount
]

{ #category : 'initialization' }
VGMeshPaint >> initialize [
	super initialize.
	patches := OrderedCollection new.
	self recordPatchCount
]

{ #category : 'inspector' }
VGMeshPaint >> inspectorMesh: aBuilder [
	<inspectorPresentationOrder: 30 title: 'Mesh'>
	"What a compositor reads from me along the diagonal of my raster, which is the one line that
	 crosses a patch from corner to corner through its middle. Each row sends rgbaAtX:y: at a point
	 of that line, so the view shows the answer itself and not the surface behind it; where the
	 answer is nothing, no patch reached that pixel. The raster is asked for through its own
	 accessor, which builds it on the first call, because a paint that has painted nothing yet holds
	 none."

	| bounds |
	bounds := self raster bounds.
	^ aBuilder newTable
		  items: (0 to: self class inspectorSampleCount - 1);
		  addColumn: (SpStringTableColumn
				   title: 'Point'
				   evaluated: [ :step |
					   | point |
					   point := self inspectorPointAlong: bounds at: step.
					   (point x printShowingDecimalPlaces: 1) , ' @ '
					   , (point y printShowingDecimalPlaces: 1) ]);
		  addColumn: (SpStringTableColumn
				   title: 'Channels'
				   evaluated: [ :step |
					   | point |
					   point := self inspectorPointAlong: bounds at: step.
					   (self rgbaAtX: point x y: point y)
						   ifNil: [ 'nothing painted' ]
						   ifNotNil: [ :channels |
							   (channels collect: [ :channel | (channel * 255) rounded ])
								   printString ] ]);
		  yourself
]

{ #category : 'inspector' }
VGMeshPaint >> inspectorMeshContext: aContext [
	"Asked before the view is built, so it may not build the raster: a paint with no patch paints
	 nothing and has nothing to show."

	aContext active: patches isEmptyOrNil not
]

{ #category : 'inspector' }
VGMeshPaint >> inspectorPointAlong: aRectangle at: aStep [
	"The point of that step of the mesh view's walk along the diagonal of a rectangle, taken at the
	 middle of a pixel so that it names one pixel and not a corner between four."

	| fraction |
	fraction := aStep / (self class inspectorSampleCount - 1).
	^ (aRectangle left + (aRectangle width * fraction)) floor + 0.5
	  @ ((aRectangle top + (aRectangle height * fraction)) floor + 0.5)
]

{ #category : 'accessing' }
VGMeshPaint >> matrix: aMatrix [
	"My raster is built in device space, by mapping every patch back through this matrix, so a
	 new matrix drops the raster I hold."
	super matrix: aMatrix.
	raster := nil
]

{ #category : 'accessing' }
VGMeshPaint >> patches [
	"My patches, in pattern space and in the order they were added, which is the order they are
	 rasterised in."

	^ patches
]

{ #category : 'copying' }
VGMeshPaint >> postCopy [
	"A fill records a copy of the paint, and the raster of this copy is built from the matrix the
	 copy is given, so it goes. The patch list is copied, because a patch added to the pattern
	 afterwards must not reach a fill already recorded, but a patch itself is never mutated."

	super postCopy.
	patches := patches copy.
	raster := nil
]

{ #category : 'reading' }
VGMeshPaint >> raster [
	"My patches rasterised into device pixels, built once and kept. My matrix maps a device point
	 into pattern space, so the patches are carried the other way, through its inverse, which is
	 what Cairo inverts the pattern matrix for. A matrix that cannot be inverted maps nothing, and
	 then I paint nothing."

	| toDevice |
	^ raster ifNil: [
		  self matrix isInvertible
			  ifFalse: [ raster := VGMeshRaster empty ]
			  ifTrue: [
				  toDevice := self matrix inverted.
				  raster := VGMeshRaster ofPatches:
					            (patches collect: [ :each | each transformedBy: toDevice ]) ] ]
]

{ #category : 'building' }
VGMeshPaint >> recordPatchCount [
	self coefficients
		at: self class patchCountFieldIndex
		put: patches size asFloat
]

{ #category : 'evaluating' }
VGMeshPaint >> rgbaAtX: x y: y [
	"A mesh is read by device pixel and not by a point of pattern space, because Cairo rasterises
	 a mesh into an image aligned with the device and composites that: the patch decides which
	 pixels are painted at all, and a pixel it reaches is opaque whatever fraction of it the patch
	 really covers."

	^ self raster rgbaAtX: x y: y
]

{ #category : 'evaluating' }
VGMeshPaint >> rgbaInPaintSpace: aPoint [
	"A mesh is not a function of pattern space: a pixel of it is the sample of a patch that
	 landed there, so there is nothing to answer for a point alone. `rgbaAtX:y:` reads the raster
	 instead, and nothing else of this layer asks a paint for a point of its own space."

	^ self shouldNotImplement
]
