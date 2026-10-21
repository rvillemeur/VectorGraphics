"
I hold unit 1.12 of VECTORCANVAS-PLAN.md: the mesh pattern and the Coons patch it is built from.

A patch is a bicubic surface over the unit square, named by its four boundary curves and a colour at each of its four corners. Cairo turns the four boundary curves into the full four by four grid of control points by the Coons conversion, interpolates the corner colours bilinearly in the two parameters, and rasterises the patch by walking that grid and writing a pixel for every sample. The footprint is therefore hard edged: a pixel a sample lands in is opaque and a pixel no sample lands in is untouched, whatever the fraction of the pixel the patch really covers. My tests state each of those facts, and the last of them measures a mesh against the live library.
"
Class {
	#name : 'VGMeshTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Cairo-Tests-Tests',
	#package : 'VectorGraphics-Cairo-Tests',
	#tag : 'Tests'
}

{ #category : 'fixtures' }
VGMeshTest >> foldedMeshPaint [
	"The folded probe's paint at an identity device matrix."
	^ self foldedMeshPattern paintForDeviceMatrix: VGCairoMatrix newIdentity
]

{ #category : 'fixtures' }
VGMeshTest >> foldedMeshPattern [
	"A patch that folds about the middle of its first parameter: its first and third sides are the
	 same loop out to the right and back again, and its second and fourth sides are the straight
	 line down the left edge, so the point at one parameter and the point at one minus that
	 parameter are the same point. The colours mirror the fold, red where the first parameter
	 starts and green where it ends, so a test can say which half of the fold painted a pixel."
	^ VGCairoMeshPattern new
		  beginPatch;
		  moveToX: 0 y: 0;
		  curveViaX: 8 y: 0 viaX: 8 y: 0 toX: 0 y: 0;
		  curveViaX: 0 y: 2 viaX: 0 y: 4 toX: 0 y: 6;
		  curveViaX: 8 y: 6 viaX: 8 y: 6 toX: 0 y: 6;
		  curveViaX: 0 y: 4 viaX: 0 y: 2 toX: 0 y: 0;
		  cornerAt: 0 putColorRGB: Color red;
		  cornerAt: 1 putColorRGB: Color green;
		  cornerAt: 2 putColorRGB: Color green;
		  cornerAt: 3 putColorRGB: Color red;
		  endPatch;
		  yourself
]

{ #category : 'fixture' }
VGMeshTest >> squareMeshPaint [
	"The probe's paint at an identity device matrix, which is what a fill records."

	^ self squareMeshPattern paintForDeviceMatrix: VGCairoMatrix newIdentity
]

{ #category : 'fixture' }
VGMeshTest >> squareMeshPattern [
	"The four by four probe, built through the pattern API Cairo publishes."

	^ VGCairoMeshPattern new
		  beginPatch;
		  moveToX: 0 y: 0;
		  lineToX: 4 y: 0;
		  lineToX: 4 y: 4;
		  lineToX: 0 y: 4;
		  cornerAt: 0 putColorRGB: Color red;
		  cornerAt: 1 putColorRGB: Color green;
		  cornerAt: 2 putColorRGB: Color blue;
		  cornerAt: 3 putColorRGB: Color yellow;
		  endPatch;
		  yourself
]

{ #category : 'fixture' }
VGMeshTest >> squarePatch [
	"The patch of the four by four probe this unit was measured against: an axis aligned square
	 of straight sides, red at the origin and then green, blue and yellow round it."

	^ VGCoonsPatch
		  boundary: (self straightBoundaryThrough: {
					   (0 @ 0).
					   (4 @ 0).
					   (4 @ 4).
					   (0 @ 4) })
		  colors: {
				  Color red.
				  Color green.
				  Color blue.
				  Color yellow }
]

{ #category : 'fixture' }
VGMeshTest >> straightBoundaryThrough: fourCorners [
	"The twelve boundary control points of a patch whose four sides are straight lines, in
	 Cairo's order: a corner, the two control points of the side leaving it, the next corner, and
	 so on round the patch, the fourth side closing back to the first corner."

	| points |
	points := OrderedCollection new.
	1 to: 4 do: [ :index |
		| from to |
		from := fourCorners at: index.
		to := fourCorners at: index \\ 4 + 1.
		points
			add: from;
			add: from + (to - from / 3);
			add: from + (to - from * 2 / 3) ].
	^ points asArray
]

{ #category : 'tests' }
VGMeshTest >> testAMeshOfNoPatchesPaintsNothing [
	"The degenerate state. A pattern asked for before a patch is begun, or one whose patch has
	 fewer than three sides, paints nothing anywhere, as a gradient of no stops does."

	| empty short |
	empty := VGCairoMeshPattern new paintForDeviceMatrix:
		         VGCairoMatrix newIdentity.
	self assert: empty patches isEmpty.
	self assert: (empty rgbaAtX: 1.5 y: 1.5) isNil.
	short := VGCairoMeshPattern new
		         beginPatch;
		         moveToX: 0 y: 0;
		         lineToX: 4 y: 0;
		         endPatch;
		         yourself.
	self assert: short paint patches isEmpty
]

{ #category : 'tests' }
VGMeshTest >> testAMeshPaintCarriesTheMeshTagAndItsPatchCountInItsBlock [
	"Rule two of the plan: the tag is cairo_pattern_type_t itself, which is four for a mesh, and
	 the patches travel beside the block as a gradient's stops do, so the block carries how many
	 of them there are."

	| paint |
	paint := self squareMeshPaint.
	self assert: paint tag equals: 4.
	self assert: (VGPaint nameIn: VGPaint typeNames for: paint tag) equals: #mesh.
	self assert: self squareMeshPattern type equals: #mesh.
	self
		assert: (paint coefficients at: VGMeshPaint patchCountFieldIndex)
		equals: 1.0.
	self deny: paint isSolid
]

{ #category : 'tests' }
VGMeshTest >> testAMeshPaintPaintsThePixelsOfItsPatchAndNothingOutside [
	"A mesh is painted where its patches are and nowhere else, whatever the extend mode says:
	 the rasterised patch is the whole of the paint, which is why Cairo hands a mesh to the
	 compositor as an image and not as a function of the plane. The probe spans the square from
	 nothing to four, and Cairo paints five columns and five rows of it, because it assigns a
	 sample to a pixel by the truncation of its coordinates, so the far edge of the patch
	 contributes a pixel of its own and the near edge does not. The colour of a pixel is the
	 colour at the middle of that pixel: measured, Cairo writes 223 red over 55 green over 4 blue
	 at the origin, where this answers 223 over 56 over 4, and 0 over 224 over 31 at the far edge
	 of the first row, where this answers 0 over 223 over 32."
	| paint painted origin farEdge |
	paint := self squareMeshPaint.
	painted := 0.
	0 to: 6 do: [ :y |
		0 to: 6 do: [ :x |
			(paint rgbaAtX: x + 0.5 y: y + 0.5) ifNotNil: [ painted := painted + 1 ] ] ].
	self assert: painted equals: 5 * 5.
	self assert: (paint rgbaAtX: 0.5 y: 0.5 - 1) isNil.
	origin := paint rgbaAtX: 0.5 y: 0.5.
	self assert: (origin collect: [ :each | (each * 255) rounded ]) equals: #( 223 56 4 255 ).
	farEdge := paint rgbaAtX: 4.5 y: 0.5.
	self assert: (farEdge collect: [ :each | (each * 255) rounded ]) equals: #( 0 223 32 255 ).
	paint extend: #repeat.
	self
		assert: (paint rgbaAtX: 5.5 y: 5.5) isNil
		description: 'a mesh does not repeat'
]

{ #category : 'tests' }
VGMeshTest >> testAPatchTransformedByAMatrixMovesEveryControlPoint [
	"A mesh is rasterised in device space, as Cairo rasterises it, so the patch has to be able to
	 carry itself there."

	| patch moved |
	patch := self squarePatch.
	moved := patch transformedBy: (VGCairoMatrix newTranslationByX: 10 y: 20).
	self assert: (moved pointAtU: 0.0 v: 0.0) equals: 10 @ 20.
	self assert: (moved pointAtU: 1.0 v: 1.0) equals: 14 @ 24.
	self assert: (moved rgbaAtU: 0.0 v: 0.0) equals: (patch rgbaAtU: 0.0 v: 0.0).
	self
		assert: (patch pointAtU: 0.0 v: 0.0) = (0 @ 0)
		description: 'transforming a patch answers a new one and leaves the old alone'
]

{ #category : 'tests' }
VGMeshTest >> testTheColourOfAPatchIsBilinearInItsTwoParameters [
	"Corner zero and corner one along the first parameter, corner three and corner two along the
	 second, interpolated unpremultiplied and in floating point, as every other paint of this
	 layer interpolates."

	| patch middle |
	patch := self squarePatch.
	self assert: (patch rgbaAtU: 0.0 v: 0.0) equals: (VGPaint rgbaOf: Color red).
	self assert: (patch rgbaAtU: 1.0 v: 1.0) equals: (VGPaint rgbaOf: Color blue).
	middle := patch rgbaAtU: 0.5 v: 0.0.
	self assert: (middle first closeTo: 0.5).
	self assert: (middle second closeTo: 0.5).
	self assert: (middle third closeTo: 0.0).
	self assert: (middle fourth closeTo: 1.0)
]

{ #category : 'tests' }
VGMeshTest >> testTheCornersOfAPatchAreTheCornersOfItsParameterSquare [
	"The first parameter runs along the first side, from corner zero to corner one, and the
	 second runs down the fourth side, from corner zero to corner three. That is Cairo's own
	 order, measured on the four by four probe."

	| patch |
	patch := self squarePatch.
	self assert: (patch pointAtU: 0.0 v: 0.0) equals: 0 @ 0.
	self assert: (patch pointAtU: 1.0 v: 0.0) equals: 4 @ 0.
	self assert: (patch pointAtU: 1.0 v: 1.0) equals: 4 @ 4.
	self assert: (patch pointAtU: 0.0 v: 1.0) equals: 0 @ 4
]

{ #category : 'tests' }
VGMeshTest >> testTheHigherParameterOfAFoldWinsItsPixel [
	"A patch that doubles back over itself covers a pixel twice, and Cairo keeps the piece of
	 the patch it writes later, which is the piece of higher parameter. The probe folds about the
	 middle of its first parameter and runs from red to green along it, so every pixel it paints
	 is at least as green as it is red, and the left column, which only the end of the fold
	 reaches, is nearly pure green. Measured on the live library: the probe paints seven columns
	 and seven rows, the left column is 0 red over 255 green, the next 12 over 243, column five
	 is 76 over 179 and column six, the apex the two halves of the fold meet at, is 128 over 128.
	 The left column parts from Cairo by five of red, because the sample of mine nearest the
	 centre of that pixel sits a little before the end of the fold while Cairo's own piece ends
	 on it."
	| paint painted edge |
	paint := self foldedMeshPaint.
	painted := 0.
	0 to: 8 do: [ :y |
		0 to: 8 do: [ :x |
			(paint rgbaAtX: x + 0.5 y: y + 0.5) ifNotNil: [ :rgba |
				painted := painted + 1.
				self
					assert: rgba second + 1.0e-6 >= rgba first
					description: 'the higher parameter of the fold won the pixel at '
						, x printString , ' ' , y printString ] ] ].
	self assert: painted equals: 7 * 7.
	edge := paint rgbaAtX: 0.5 y: 0.5.
	self assert: (edge first * 255) rounded equals: 5.
	self assert: (edge second * 255) rounded equals: 250.
	self assert: ((paint rgbaAtX: 6.5 y: 0.5) first closeTo: 0.5)
]

{ #category : 'tests' }
VGMeshTest >> testTheInteriorControlPointsAreTheCoonsConversionOfTheBoundary [
	"A patch is named by its four boundary curves, and the surface is a tensor product of
	 sixteen control points, so the four interior ones are computed. The conversion Cairo uses is
	 the one the PDF type six shading declares, and on a patch whose sides are straight it
	 answers the regular grid: a third and two thirds of the way along each side."

	| patch |
	patch := self squarePatch.
	self assert: ((patch controlPointAtRow: 2 column: 2) - (4 / 3 @ (4 / 3))) r < 1e-12.
	self assert: ((patch controlPointAtRow: 2 column: 3) - (8 / 3 @ (4 / 3))) r < 1e-12.
	self assert: ((patch controlPointAtRow: 3 column: 2) - (4 / 3 @ (8 / 3))) r < 1e-12.
	self assert: ((patch controlPointAtRow: 3 column: 3) - (8 / 3 @ (8 / 3))) r < 1e-12
]

{ #category : 'tests' }
VGMeshTest >> testTheMeshPatternBuildsTheSamePatchFromStraightSidesAsItsBoundaryDoes [
	"The pattern is the facade: a straight side it is given has to reach the patch as the two
	 control points a third and two thirds along, which is what a line is as a cubic."

	| fromPattern fromBoundary |
	fromPattern := self squareMeshPattern paint patches first.
	fromBoundary := self squarePatch.
	1 to: 4 do: [ :row |
		1 to: 4 do: [ :column |
			self
				assert:
				((fromPattern controlPointAtRow: row column: column)
				 - (fromBoundary controlPointAtRow: row column: column)) r < 1e-12
				description: 'control point ' , row printString , ' '
					, column printString ] ].
	self
		assert: (fromPattern rgbaAtU: 1.0 v: 0.0)
		equals: (VGPaint rgbaOf: Color green)
]
