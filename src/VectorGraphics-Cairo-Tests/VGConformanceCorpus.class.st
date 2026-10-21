"
I hold the conformance corpus: the cases that say what Cairo parity means, grouped by the unit of VECTORCANVAS-PLAN.md that owes them.

Each group is one class-side method, so a unit can be read on its own, and cases answers them all. A case drives nothing but the Cairo API, so it runs against our VGCairoContext and against a real AeCairoContext without change.

I am seeded with the primitives rather than with the eleven AeCanvas figure combinations, because a primitive that fails names one selector while a figure that fails names eleven. The figure combinations come back as integration cases once unit 1.7 lands.
"
Class {
	#name : 'VGConformanceCorpus',
	#superclass : 'Object',
	#category : 'VectorGraphics-Cairo-Tests-Conformance',
	#package : 'VectorGraphics-Cairo-Tests',
	#tag : 'Conformance'
}

{ #category : 'private' }
VGConformanceCorpus class >> antialiasedCase: aString unit: aUnitString draw: aBlock [
	"A case whose picture has a curved or slanted edge, so its edge pixels are shades rather than
	 one value or the other, and Cairo's shade and ours may differ by a little."

	^ (self case: aString unit: aUnitString draw: aBlock)
		  tolerance: self antialiasingTolerance;
		  yourself
]

{ #category : 'constants' }
VGConformanceCorpus class >> antialiasingTolerance [
	"How far a channel of an antialiased edge pixel may sit from Cairo's own. Our scan converter
	 is exact across a pixel and samples fifteen sub-rows down it, which is the grid Cairo's own
	 converter uses, so the two agree on every pixel a shape covers wholly or not at all and can
	 only disagree on the shades of an edge. Measured over the cases that draw, the worst
	 disagreement is twenty-one of two hundred and fifty-five, on a filled circle; the gate is set
	 a little above that and the exterior is held exactly, which is the condition that catches a
	 wrong shape."

	^ 24
]

{ #category : 'private' }
VGConformanceCorpus class >> appendFivePointedStarTo: aContext [
	"A self-intersecting path, so that the two fill rules give different pictures."

	| center outer inner |
	center := 32 @ 32.
	outer := 26.
	inner := 11.
	aContext moveTo: center + (0 @ outer negated).
	1 to: 9 do: [ :index |
		| angle radius |
		angle := index * Float pi / 5.0.
		radius := index odd
			          ifTrue: [ inner ]
			          ifFalse: [ outer ].
		aContext lineTo: center + ((angle sin * radius) @ (angle cos * radius) negated) ].
	aContext closePath
]

{ #category : 'cases - shadow' }
VGConformanceCorpus class >> blurFilterFor: aContext [
	"The Gaussian blur filter in the family of the context. This one cannot be reached by
	 substituting a prefix the way classNamed:for: does: Alexandrie calls it
	 AeCairoA8FastGaussianBlurFilter although it touches no Cairo call and has a slower sibling it
	 shares every method with, and ours is named for what it is."

	^ ((aContext isKindOf: VGCairoContext)
		   ifTrue: [ Smalltalk at: #VGA8GaussianBlurFilter ]
		   ifFalse: [ Smalltalk at: #AeCairoA8FastGaussianBlurFilter ]) new
]

{ #category : 'private' }
VGConformanceCorpus class >> case: aString unit: aUnitString draw: aBlock [
	^ VGConformanceCase
		  name: aString
		  unit: aUnitString
		  extent: self caseExtent
		  draw: aBlock
]

{ #category : 'constants' }
VGConformanceCorpus class >> caseExtent [
	"One size for every case: large enough to show a join and a dash, small enough that a reference
	 PNG is a few kilobytes."

	^ 64 @ 64
]

{ #category : 'constants' }
VGConformanceCorpus class >> caseMethodSelectors [
	"The one list the corpus grows by. A new group means a new entry here and a new method, and the
	 conformance test reads this list rather than the protocol, so a method that nobody named cannot
	 hide in the corpus."

	^ #( #targetCases #transformCases #pathCases #strokeCases #sourceCases #clipCases #groupCases
	     #figureCases #textCases #shadowCases #meshCases )
]

{ #category : 'cases' }
VGConformanceCorpus class >> cases [
	^ self caseMethodSelectors flatCollect: [ :each | self perform: each ]
]

{ #category : 'private' }
VGConformanceCorpus class >> classNamed: aString for: aContext [
	"The class of that name in the family of the context: ours when the replacement is drawing,
	 Alexandrie's when the reference is. One draw block runs on both contexts, so a case that
	 needs a pattern or a second surface has to ask for it this way: Alexandrie's context hands
	 whatever it is given straight to a Cairo call, which wants a pointer our objects do not have."

	| prefix |
	prefix := (aContext isKindOf: VGCairoContext)
		          ifTrue: [ 'VGCairo' ]
		          ifFalse: [ 'AeCairo' ].
	^ Smalltalk at: (prefix , aString) asSymbol
]

{ #category : 'cases' }
VGConformanceCorpus class >> clipCases [
	"Unit 1.6: the clip, read through a shape that reaches outside it."
	^ {
		  (self antialiasedCase: 'clip-circle' unit: '1.6' draw: [ :context |
			   context
				   circleCenterX: 32 y: 32 radius: 18;
				   clip;
				   rectangleX: 0 y: 0 width: 64 height: 40;
				   fill ]).
		  (self case: 'clip-preserving-path' unit: '1.6' draw: [ :context |
			   context
				   rectangleX: 8 y: 8 width: 48 height: 48;
				   clipPreservingPath;
				   stroke ]) }
]

{ #category : 'cases' }
VGConformanceCorpus class >> figureCases [
	"Unit 1.7: the two AeCanvas figure methods that emulate a border lying outside the path,
	 written out message for message. AeCanvas cannot drive the replacement itself yet, because it
	 sets font options on the context it is handed and those are unit 1.8, so each case here is the
	 body of AeCanvas >> #drawFigureWithBorderOutsideAndNoBackground and of
	 #drawFigureWithBorderOutsideAndTranslucentBackground with clipAfterwards false. The emulation
	 is what the group and the clear operator are for: it strokes at double width inside a group and
	 clears the inner half, so a group that leaks onto the target, a clear that escapes it or a
	 state that outlives the pop all show here as a filled disc or an empty picture."
	^ {
		  (self
			   antialiasedCase: 'figure-outskirts-outside-no-background'
			   unit: '1.7'
			   draw: [ :context |
				   context circleCenterX: 32 y: 32 radius: 20.
				   context paintGroupWith: [
					   context
						   sourceColor: (Color r: 0.1 g: 0.3 b: 0.8);
						   strokeSize: 8.0;
						   strokePreservingPath;
						   setOperatorClear;
						   fillPreservingPath: false ] ]).
		  (self
			   antialiasedCase: 'figure-outskirts-outside-translucent-background'
			   unit: '1.7'
			   draw: [ :context |
				   context circleCenterX: 32 y: 32 radius: 20.
				   context paintGroupWith: [
					   context
						   sourceColor: (Color r: 0.8 g: 0.2 b: 0.1);
						   strokeSize: 8.0;
						   strokePreservingPath;
						   setOperatorClear;
						   fillPreservingPath ].
				   context sourceColor: (Color r: 0.2 g: 0.7 b: 0.3).
				   context restoreStateAfter: [
					   context
						   clip;
						   paintWithAlpha: 0.6 ] ]) }
]

{ #category : 'constants' }
VGConformanceCorpus class >> gradientInterpolationTolerance [
	"How far a channel of a gradient may sit from Cairo's own. Cairo hands a gradient to pixman,
	 which walks the ramp in fixed point, and we evaluate it in floating point: on an axis aligned
	 ramp the two agree byte for byte on all sixty-four pixels, which VGCairoSurfaceTest and
	 VGPaintTest hold exactly, and they part by one on the pixels where the offset lands on a
	 boundary of the fixed point step. Measured: sixty-four pixels of a diagonal ramp, all on the
	 line where the offset is exactly a half, and thirty-two pixels of a radial one, all on one
	 ring. The exterior is still held exactly, which is what catches a wrong shape."

	^ 1
]

{ #category : 'cases' }
VGConformanceCorpus class >> groupCases [
	"Unit 1.7: the group, the two masks, a paint carried through an alpha and the one operator
	 AeCanvas sets by name. A group's block takes no argument, because Cairo redirects the context
	 the caller already holds rather than handing over a second one, and a mask surface has to
	 belong to whichever side is drawing, which is why these cases ask classNamed:for: for it
	 through maskTileFor:. Every picture here has a curved or faded edge, so each is gated at the
	 antialiasing tolerance."
	^ {
		  (self antialiasedCase: 'group-painted-with-alpha' unit: '1.7' draw: [ :context |
			   context sourceColor: (Color r: 0.9 g: 0.3 b: 0.1).
			   context
				   paintGroupWith: [
					   context
						   circleCenterX: 24 y: 32 radius: 18;
						   fill;
						   circleCenterX: 40 y: 32 radius: 18;
						   fill ]
				   alpha: 0.5 ]).
		  (self antialiasedCase: 'paint-through-an-alpha' unit: '1.7' draw: [ :context |
			   context
				   sourceColor: (Color r: 0.1 g: 0.7 b: 0.4);
				   paintWithAlpha: 0.4 ]).
		  (self antialiasedCase: 'group-masked-by-surface' unit: '1.7' draw: [ :context |
			   context
				   sourceColor: (Color r: 0.2 g: 0.4 b: 0.9);
				   maskSurface: (self maskTileFor: context) x: 8 y: 8 ]).
		  (self antialiasedCase: 'group-masked-with-a-block' unit: '1.7' draw: [ :context |
			   context sourceColor: (Color r: 0.8 g: 0.2 b: 0.6).
			   context maskGroupWith: [
				   context
					   circleCenterX: 32 y: 32 radius: 16;
					   fill ] ]).
		  (self antialiasedCase: 'group-cleared-region' unit: '1.7' draw: [ :context |
			   context
				   paint;
				   setOperatorClear;
				   circleCenterX: 32 y: 32 radius: 14;
				   fill ]) }
]

{ #category : 'inspecting' }
VGConformanceCorpus class >> inspectorCases: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Cases'>
	"The whole corpus with the selector each case stops on, which is the one view that shows how much
	 of the Cairo surface the engine already covers. Each row runs its own case on a fresh target."

	^ aBuilder newTable
		  items: (self cases collect: [ :each | each -> each blockingFailure ]);
		  addColumn: (SpStringTableColumn title: 'Case' evaluated: [ :each | each key name ]);
		  addColumn: (SpStringTableColumn title: 'Unit' evaluated: [ :each | each key unit ]);
		  addColumn: (SpStringTableColumn title: 'Stops on' evaluated: [ :each |
					   each value ifNil: [ 'nothing: the case draws' ] ifNotNil: [ :failure | failure selectorName ] ]);
		  addColumn: (SpStringTableColumn title: 'Owed by unit' evaluated: [ :each |
					   each value ifNil: [ '-' ] ifNotNil: [ :failure | failure unit ] ]);
		  yourself
]

{ #category : 'inspecting' }
VGConformanceCorpus class >> inspectorCasesContext: aContext [
	"The corpus is the root that holds the cases; a subclass of it would describe a narrower set."

	aContext active: self superclass = Object
]

{ #category : 'private' }
VGConformanceCorpus class >> interpolatedCase: aString unit: aUnitString draw: aBlock [
	"A case whose colour comes from a gradient, so a pixel of it may sit one off Cairo's own;
	 see gradientInterpolationTolerance."

	^ (self case: aString unit: aUnitString draw: aBlock)
		  tolerance: self gradientInterpolationTolerance;
		  yourself
]

{ #category : 'private' }
VGConformanceCorpus class >> maskTileFor: aContext [
	"A mask surface in the family of the context: transparent at the top left, half opaque over a
	 band, and opaque under a disc, so that every one of the three alphas a mask can carry shows
	 in the picture a case draws through it. A blank surface would mask everything away and the
	 case would prove nothing."
	| tile tileContext extent |
	extent := self caseExtent.
	tile := (self classNamed: 'ImageSurface' for: aContext) extent: extent.
	tileContext := tile newContext.
	tileContext clearTransparent.
	tileContext sourceColorR: 1.0 g: 1.0 b: 1.0 a: 0.5.
	tileContext rectangleX: 0 y: extent y / 2 width: extent x height: extent y / 2.
	tileContext fill.
	tileContext sourceColorR: 1.0 g: 1.0 b: 1.0 a: 1.0.
	tileContext circleCenterX: extent x / 2 y: extent y / 2 radius: extent x / 4.
	tileContext fill.
	tile flush.
	^ tile
]

{ #category : 'tolerances' }
VGConformanceCorpus class >> meshBoundaryPixelTable [
	"How many pixels of each mesh case may be further from Cairo than meshColourTolerance, by case
	 name. The number is the ring of pixels the edge of a patch grazes, where one rasteriser paints
	 a pixel the other leaves alone and the colours part by the whole colour of the patch there. It
	 is measured and then given a tenth of headroom, so a change of shape fails the gate while the
	 ring does not. Measured on 21 October 2026: none on the straight patch, whose edges are the
	 pixel grid itself and whose worst channel is four; none on the folded patch, whose worst
	 channel is two; six on the triangle and ten on the curved patch, all of them pixels we paint
	 where Cairo paints nothing, along the slanted and curved sides."

	^ Dictionary newFrom: {
		  ('mesh-straight-patch' -> 0).
		  ('mesh-triangle' -> 7).
		  ('mesh-curved-patch' -> 11).
		  ('mesh-folded-patch' -> 0) }
]

{ #category : 'private' }
VGConformanceCorpus class >> meshCase: aString draw: aBlock [
	"A case whose paint is a mesh pattern. A mesh is the one paint with a hard edge, so its gate is
	 a colour tolerance with a count of the pixels the edge of a patch is allowed to put past it;
	 see meshColourTolerance, meshStrayAlphaAllowance and meshBoundaryPixelTable."

	^ (self case: aString unit: '1.12' draw: aBlock)
		  tolerance: self meshColourTolerance;
		  strayAlphaAllowance: self meshStrayAlphaAllowance;
		  pixelsAllowedBeyondTolerance: (self meshBoundaryPixelTable at: aString);
		  yourself
]

{ #category : 'cases' }
VGConformanceCorpus class >> meshCases [
	"Unit 1.12: the four shapes a patch can take. The straight patch is bilinear colour over a
	 square, which is the whole of the Coons surface when every side is a line. The triangle sets
	 three sides and three corners and leaves Cairo to close it and to repeat the first corner's
	 colour, which is Gouraud shading. The curved patch bends all four sides outwards, so the
	 surface the colour runs over is no longer flat. The folded patch is one loop out to the right
	 and back again, so the two halves of its first parameter reach the same pixels and the later
	 half must win them."

	^ {
		  (self meshCase: 'mesh-straight-patch' draw: [ :context |
			   context
				   sourcePattern: ((self classNamed: 'MeshPattern' for: context) new
						    beginPatch;
						    moveToX: 8 y: 8;
						    lineToX: 56 y: 8;
						    lineToX: 56 y: 56;
						    lineToX: 8 y: 56;
						    cornerAt: 0 putColorRGB: Color red;
						    cornerAt: 1 putColorRGB: Color green;
						    cornerAt: 2 putColorRGB: Color blue;
						    cornerAt: 3 putColorRGB: Color yellow;
						    endPatch;
						    yourself);
				   paint ]).
		  (self meshCase: 'mesh-triangle' draw: [ :context |
			   context
				   sourcePattern: ((self classNamed: 'MeshPattern' for: context) new
						    beginPatch;
						    moveToX: 32 y: 6;
						    lineToX: 58 y: 54;
						    lineToX: 6 y: 54;
						    cornerAt: 0 putColorRGB: Color red;
						    cornerAt: 1 putColorRGB: Color green;
						    cornerAt: 2 putColorRGB: Color blue;
						    endPatch;
						    yourself);
				   paint ]).
		  (self meshCase: 'mesh-curved-patch' draw: [ :context |
			   context
				   sourcePattern: ((self classNamed: 'MeshPattern' for: context) new
						    beginPatch;
						    moveToX: 10 y: 10;
						    curveViaX: 26 y: 2 viaX: 38 y: 2 toX: 54 y: 10;
						    curveViaX: 62 y: 26 viaX: 62 y: 38 toX: 54 y: 54;
						    curveViaX: 38 y: 62 viaX: 26 y: 62 toX: 10 y: 54;
						    curveViaX: 2 y: 38 viaX: 2 y: 26 toX: 10 y: 10;
						    cornerAt: 0 putColorRGB: Color red;
						    cornerAt: 1 putColorRGB: Color green;
						    cornerAt: 2 putColorRGB: Color blue;
						    cornerAt: 3 putColorRGB: Color yellow;
						    endPatch;
						    yourself);
				   paint ]).
		  (self meshCase: 'mesh-folded-patch' draw: [ :context |
			   context
				   sourcePattern: ((self classNamed: 'MeshPattern' for: context) new
						    beginPatch;
						    moveToX: 8 y: 8;
						    curveViaX: 56 y: 8 viaX: 56 y: 8 toX: 8 y: 8;
						    curveViaX: 8 y: 24 viaX: 8 y: 40 toX: 8 y: 56;
						    curveViaX: 56 y: 56 viaX: 56 y: 56 toX: 8 y: 56;
						    curveViaX: 8 y: 40 viaX: 8 y: 24 toX: 8 y: 8;
						    cornerAt: 0 putColorRGB: Color red;
						    cornerAt: 1 putColorRGB: Color green;
						    cornerAt: 2 putColorRGB: Color green;
						    cornerAt: 3 putColorRGB: Color red;
						    endPatch;
						    yourself);
				   paint ]) }
]

{ #category : 'tolerances' }
VGConformanceCorpus class >> meshColourTolerance [
	"How far a channel of a mesh may be from Cairo's. A mesh is bilinear colour over a surface
	 Cairo subdivides into pieces about a pixel across, and our raster samples the same surface on
	 a walk of its own, so a pixel of ours stands for a point of the surface a fraction of a pixel
	 from the point Cairo took, and the colour parts by the gradient across that fraction. Eight
	 of two hundred and fifty-five is what that measures at over the cases here; the pixels the
	 edge of a patch grazes part by far more and are counted instead, by
	 pixelsAllowedBeyondTolerance."

	^ 8
]

{ #category : 'tolerances' }
VGConformanceCorpus class >> meshStrayAlphaAllowance [
	"How heavy a pixel we paint outside a mesh of Cairo's may be. A mesh has no antialiasing: a
	 pixel a patch reaches is opaque and a pixel it does not reach is untouched, so a pixel the two
	 rasterisers disagree about at the edge of a patch is opaque on whichever side painted it, and
	 weighing it says nothing. What bounds the edge here is how many pixels may be wrong at all,
	 which is pixelsAllowedBeyondTolerance, and a stray pixel is one of them because the tally
	 counts it."

	^ 255
]

{ #category : 'cases' }
VGConformanceCorpus class >> pathCases [
	"Unit 1.3: a path, a fill rule, and the three painting verbs. The source is left alone, because
	 a context starts with opaque black, so these cases owe nothing to unit 1.5."

	^ {
		  (self case: 'path-filled-rectangle' unit: '1.3' draw: [ :context |
			    context
				    rectangleX: 8 y: 8 width: 48 height: 24;
				    fill ]).
		  (self antialiasedCase: 'path-filled-circle' unit: '1.3' draw: [ :context |
			    context
				    circleCenterX: 32 y: 32 radius: 20;
				    fill ]).
		  (self antialiasedCase: 'path-filled-rounded-rectangle' unit: '1.3' draw: [ :context |
			    context
				    roundedRectangleLeft: 6 top: 6 right: 58 bottom: 58 tl: 16 tr: 2 br: 16 bl: 2;
				    fill ]).
		  (self antialiasedCase: 'path-filled-star-even-odd' unit: '1.3' draw: [ :context |
			    context useFillRuleEvenOdd.
			    self appendFivePointedStarTo: context.
			    context fill ]).
		  (self antialiasedCase: 'path-filled-star-winding' unit: '1.3' draw: [ :context |
			    context useFillRuleWinding.
			    self appendFivePointedStarTo: context.
			    context fill ]).
		  (self antialiasedCase: 'path-curve-stroked' unit: '1.3' draw: [ :context |
			    context
				    moveTo: 6 @ 48;
				    curveVia: 20 @ 4 via: 44 @ 60 to: 58 @ 16;
				    stroke ]).
		  (self case: 'path-painted-whole-target' unit: '1.3' draw: [ :context | context paint ]) }
]

{ #category : 'cases - text' }
VGConformanceCorpus class >> scaledFontFor: aContext size: aNumber [
	"A scaled font in the family of the context, over the same bytes at the same size with the
	 metrics unhinted, so both families lay the run out from the same numbers. The hint style is
	 named on both sides because Alexandrie's default would let FreeType move the outlines."

	(aContext isKindOf: VGCairoContext) ifTrue: [
		^ VGScaledFont
			  fontFace: (VGFontFace newForBytes: self textCaseFontBytes)
			  fontMatrix: (VGCairoMatrix newScalingBy: aNumber asPoint)
			  userToDeviceMatrix: VGCairoMatrix newIdentity
			  options: (VGFontOptions new
					   hintStyle: #none;
					   hintMetrics: #off;
					   yourself) ].
	^ AeCairoScaledFont
		  fontFace: (AeCairoFreetypeFontFace newForFace:
				   (AeFTLibrary newInitialized
					    newFaceFromBytes: self textCaseFontBytes
					    index: 0))
		  fontMatrix: (AeCairoMatrix newScalingBy: aNumber asPoint)
		  userToDeviceMatrix: AeCairoMatrix newIdentity
		  options: (AeCairoFontOptions new
				   hintStyle: AeCairoHintStyle none;
				   hintMetrics: AeCairoHintMetrics off;
				   yourself)
]

{ #category : 'constants' }
VGConformanceCorpus class >> shadowBlurTolerance [
	"A shadow is an alpha surface blurred, so the only difference between the two sides is the
	 difference between the two rasterisations of the geometry underneath, and three box passes
	 average that difference down rather than up: measured, the curved shadow cases differ by 2 of
	 255 at worst where the unblurred circle of unit 1.3 differs by 21, and no pixel of ours falls
	 outside the reference at all. The two axis-aligned shadow cases are exact and are held exact."

	^ 4
]

{ #category : 'cases - shadow' }
VGConformanceCorpus class >> shadowCaseBlurRadii [
	"The widths the shadow cases blur by, in the order of the cases that use them. A radius of zero
	 is kept because it is the degenerate state: the filter must leave the alpha surface alone and
	 the picture must be the geometry itself, masked."

	^ #( 10 16 4 0 )
]

{ #category : 'cases - shadow' }
VGConformanceCorpus class >> shadowCaseColor [
	^ Color r: 0.1 g: 0.1 b: 0.4
]

{ #category : 'cases - shadow' }
VGConformanceCorpus class >> shadowCaseNamed: aName geometry: aBlock blurRadius: aNumber [
	"One shadow case: the geometry drawn opaque into an alpha surface, blurred by the radius, then
	 masked onto the target at the shadow offset in the shadow colour, which is the path
	 BlGaussianShadowEffect takes through AeCanvas."

	^ self case: aName unit: '1.9' draw: [ :context |
		  context
			  sourceColor: self shadowCaseColor;
			  maskSurface: (self
					   shadowMaskFor: context
					   geometry: aBlock
					   blurRadius: aNumber)
			  x: self shadowCaseOffset x
			  y: self shadowCaseOffset y ]
]

{ #category : 'cases - shadow' }
VGConformanceCorpus class >> shadowCaseOffset [
	"Where the blurred mask is laid down. A Bloc shadow is offset from the element it belongs to,
	 so the cases mask at an offset rather than at the origin."

	^ 4 @ 4
]

{ #category : 'cases' }
VGConformanceCorpus class >> shadowCases [
	"Unit 1.9: a Bloc shadow, which is the one thing the blur filter exists for. The two curved
	 cases carry the blur tolerance; the sharp one and the one that blurs by nothing are held
	 exact, because an axis-aligned edge is the same byte on both sides before the blur and the
	 blur of it stays the same byte after."

	| radii |
	radii := self shadowCaseBlurRadii.
	^ {
		  ((self
			    shadowCaseNamed: 'shadow-rounded-rectangle'
			    geometry: [ :maskContext |
				    maskContext
					    roundedRectangleLeft: 14
					    top: 14
					    right: 50
					    bottom: 50
					    tl: 8
					    tr: 8
					    br: 8
					    bl: 8 ]
			    blurRadius: (radii at: 1))
			   tolerance: self shadowBlurTolerance;
			   yourself).
		  ((self
			    shadowCaseNamed: 'shadow-circle'
			    geometry: [ :maskContext | maskContext circleCenterX: 32 y: 32 radius: 16 ]
			    blurRadius: (radii at: 2))
			   tolerance: self shadowBlurTolerance;
			   yourself).
		  (self
			   shadowCaseNamed: 'shadow-sharp-rectangle'
			   geometry: [ :maskContext | maskContext rectangleX: 16 y: 20 width: 32 height: 24 ]
			   blurRadius: (radii at: 3)).
		  (self
			   shadowCaseNamed: 'shadow-blurred-by-nothing'
			   geometry: [ :maskContext | maskContext rectangleX: 16 y: 20 width: 32 height: 24 ]
			   blurRadius: (radii at: 4)) }
]

{ #category : 'cases - shadow' }
VGConformanceCorpus class >> shadowMaskFor: aContext geometry: aBlock blurRadius: aRadius [
	"The alpha surface a shadow is masked through: an alpha-only surface of the case size with the
	 geometry drawn on it and then blurred, which is what AeCanvas builds for a Bloc shadow. The
	 geometry is drawn opaque, because only the alpha of this surface is ever read."

	| surface surfaceContext |
	surface := (self classNamed: 'ImageSurface' for: aContext)
		           extent: self caseExtent
		           format: (self classNamed: 'SurfaceFormat' for: aContext) a8.
	surfaceContext := surface newContext.
	surfaceContext sourceColorR: 0.0 g: 0.0 b: 0.0 a: 1.0.
	aBlock value: surfaceContext.
	surfaceContext fill.
	(self blurFilterFor: aContext)
		surface: surface;
		applyRadius: aRadius.
	^ surface
]

{ #category : 'cases' }
VGConformanceCorpus class >> sourceCases [
	"Unit 1.5: what the painting verbs take their colour from. Every pattern class of unit 1.5
	 appears here, because a class no case names would never be exercised at all; the mesh pattern
	 of unit 1.12 is the one pattern not of this group and has meshCases to itself. No case names a
	 class of either side itself; see classNamed:for:."

	^ {
		  (self case: 'source-flat-colour' unit: '1.5' draw: [ :context |
			   context
				   sourceColor: (Color r: 0.9 g: 0.3 b: 0.1);
				   rectangleX: 8 y: 8 width: 48 height: 48;
				   fill ]).
		  (self case: 'source-colour-pattern' unit: '1.5' draw: [ :context |
			   context
				   sourcePattern:
					   ((self classNamed: 'ColorPattern' for: context) r: 0.1 g: 0.7 b: 0.4);
				   paint ]).
		  (self interpolatedCase: 'source-linear-gradient' unit: '1.5' draw: [ :context |
			   context
				   sourcePattern: ((self classNamed: 'LinearGradientPattern' for: context)
						    from: 0 @ 0
						    to: 64 @ 64
						    addStopsFrom: self twoStopRamp);
				   paint ]).
		  (self interpolatedCase: 'source-radial-gradient' unit: '1.5' draw: [ :context |
			   context
				   sourcePattern: ((self classNamed: 'RadialGradientPattern' for: context)
						    innerCenter: 32 @ 32
						    innerRadius: 2
						    outerCenter: 32 @ 32
						    outerRadius: 30
						    addStopsFrom: self twoStopRamp);
				   paint ]).
		  (self case: 'source-surface-pattern' unit: '1.5' draw: [ :context |
			   context
				   sourcePattern: ((self classNamed: 'SurfacePattern' for: context)
						    surface: (self tileFor: context));
				   rectangleX: 0 y: 0 width: 64 height: 64;
				   fill ]).
		  (self case: 'source-surface-directly' unit: '1.5' draw: [ :context |
			   context
				   sourceSurface: (self tileFor: context);
				   rectangleX: 0 y: 0 width: 64 height: 64;
				   fill ]) }
]

{ #category : 'constants' }
VGConformanceCorpus class >> strayAlphaAllowance [
	"How heavy a pixel we paint outside Cairo shape may be. Cairo steps a polygon edge across a
	 grid of five hundred and twelfths of a pixel with integer arithmetic, while our scan
	 converter is exact across the pixel, so a near tangential edge, such as the tip of a star,
	 can leave us a coverage of a fraction of one step of alpha where Cairo rounds to none. One
	 step is the smallest alpha a pixel can carry and is invisible; anything heavier is a shape
	 we got wrong, which is what the gate is for."
	^ 1
]

{ #category : 'cases' }
VGConformanceCorpus class >> strokeCases [
	"Unit 1.4: the stroke parameters. A case that must draw the same picture on our context and on
	 a live Cairo one names a cap and a join through the six use verbs, which both contexts answer
	 and neither reads from an enumeration object. The antialiasing mode is the one stroke
	 parameter Alexandrie offers no verb for, so that case names its enumeration object, which the
	 test package is allowed to do; it fills a polygon rather than a circle, because a flattened
	 curve lands its vertices in a phase of its own and an aliased pixel is wholly on or wholly
	 off, which turns a sliver of a difference into a whole pixel."

	^ {
		  (self antialiasedCase: 'stroke-caps' unit: '1.4' draw: [ :context |
			   #( #useStrokeCapButt #useStrokeCapRound #useStrokeCapSquare )
				   doWithIndex: [ :each :index |
					   context
						   perform: each;
						   strokeSize: 9;
						   lineFrom: 14 @ (index * 16) to: 50 @ (index * 16);
						   stroke ] ]).
		  (self antialiasedCase: 'stroke-joins' unit: '1.4' draw: [ :context |
			   #( #useStrokeJoinMiter #useStrokeJoinRound #useStrokeJoinBevel )
				   doWithIndex: [ :each :index |
					   context
						   perform: each;
						   strokeJoinMiterLimit: 10;
						   strokeSize: 7;
						   moveTo: 10 @ (index * 20);
						   lineTo: 32 @ (index * 20 - 12);
						   lineTo: 54 @ (index * 20);
						   stroke ] ]).
		  (self case: 'stroke-dashes' unit: '1.4' draw: [ :context |
			   context
				   strokeSize: 6;
				   strokeDashPattern: #( 9 4 ) offset: 2;
				   lineFrom: 6 @ 32 to: 58 @ 32;
				   stroke ]).
		  (self case: 'stroke-antialias-none' unit: '1.4' draw: [ :context |
			   context antialias: AeCairoAntialias none.
			   self appendFivePointedStarTo: context.
			   context fill ]) }
]

{ #category : 'cases' }
VGConformanceCorpus class >> targetCases [
	"Unit 1.1: the target itself, with no path involved."

	^ {
		  (self
			   case: 'target-cleared-to-transparent'
			   unit: '1.1'
			   draw: [ :context | context clearTransparent ]).
		  (self
			   case: 'target-cleared-to-a-colour'
			   unit: '1.1'
			   draw: [ :context | context clearColor: (Color r: 0.2 g: 0.4 b: 0.9) ]) }
]

{ #category : 'cases - text' }
VGConformanceCorpus class >> textAtlasStrayAlphaAllowance [
	"How heavy a pixel the atlas route may paint outside Cairo's own glyph. FreeType rounds a
	 faint edge coverage to nothing where our converter keeps it, so a glyph of ours is a hair
	 wider than the reference. Measured over the run case: five pixels, the heaviest at an alpha
	 of thirteen of two hundred and fifty-five, which is a shade no eye reads; the gate is set a
	 little above that."

	^ 16
]

{ #category : 'cases - text' }
VGConformanceCorpus class >> textAtlasTolerance [
	"How far a channel of a glyph drawn through the atlas may sit from Cairo's. Cairo rasterises
	 a glyph with FreeType, which walks the outline on its own grid and drops a coverage of its
	 own, while we rasterise the same outline with the scan converter every other case uses, so
	 the shades along a stem differ by more than an edge of a path does. Measured over the run
	 case: thirty-three of two hundred and fifty-five at worst, and the gate is set a little
	 above that."

	^ 36
]

{ #category : 'cases - text' }
VGConformanceCorpus class >> textCaseFontBytes [
	"The font every text case draws with, read from Alexandrie's embedded copy. A font file is
	 named here rather than in the corpus's drawing scripts because both families read the same
	 bytes: ours through its own TrueType tables, Alexandrie's through FreeType."

	^ AeSourceSansPro_Regular fontContentsData
]

{ #category : 'cases - text' }
VGConformanceCorpus class >> textCaseFontSize [
	"Large enough that a glyph has shades on its curve, small enough that a whole word fits the
	 case extent."

	^ 20
]

{ #category : 'cases - text' }
VGConformanceCorpus class >> textCaseOrigin [
	"Where the baseline of a text case starts: a whole pixel, so the two families place the run
	 identically and the comparison is about the glyphs rather than about rounding."

	^ 4 @ 44
]

{ #category : 'cases - text' }
VGConformanceCorpus class >> textCaseRun [
	"A capital, a descender, a composite glyph and a round one, which is as much of a font as a
	 run of this width can exercise."

	^ 'Agio'
]

{ #category : 'cases' }
VGConformanceCorpus class >> textCases [
	"Unit 1.8: the same run drawn both ways. The path case appends the glyph outlines and fills
	 them, which Cairo rasterises with the same scan converter as any other path, so it is held to
	 the antialiasing tolerance of every other antialiased case. The run case goes through the
	 glyph atlas, which Cairo rasterises with FreeType instead, so it carries a tolerance and an
	 exterior allowance of its own; that the two routes of ours agree byte for byte is held by
	 VGCairoTextTest, which is what makes the path case a check on both."

	^ {
		  ((self
			    case: 'text-glyph-run'
			    unit: '1.8'
			    draw: [ :context |
				    context
					    scaledFont:
						    (self scaledFontFor: context size: self textCaseFontSize);
					    sourceColor: Color black;
					    moveTo: self textCaseOrigin;
					    showText: self textCaseRun ])
			   tolerance: self textAtlasTolerance;
			   strayAlphaAllowance: self textAtlasStrayAlphaAllowance;
			   yourself).
		  (self
			   antialiasedCase: 'text-glyph-path'
			   unit: '1.8'
			   draw: [ :context |
				   | font |
				   font := self scaledFontFor: context size: self textCaseFontSize.
				   context
					   scaledFont: font;
					   sourceColor: Color black;
					   appendGlyphsPath:
						   (self textGlyphsOf: font at: self textCaseOrigin);
					   fill ]) }
]

{ #category : 'cases - text' }
VGConformanceCorpus class >> textGlyphsOf: aScaledFont at: aPoint [
	"The run laid out by that font and moved to aPoint, in whatever form the font's own family
	 wants. Alexandrie answers an opaque array over external memory, so its glyphs are moved in
	 place through the structure that array points at."

	| glyphs |
	glyphs := aScaledFont glyphArrayForString: self textCaseRun.
	(glyphs isKindOf: Array) ifTrue: [
		^ glyphs collect: [ :each |
			  VGGlyph index: each index x: each x + aPoint x y: each y + aPoint y ] ].
	1 to: glyphs size do: [ :index |
		| glyph |
		glyph := glyphs asExternalStructure at: index.
		glyph
			x: glyph x + aPoint x;
			y: glyph y + aPoint y ].
	^ glyphs
]

{ #category : 'private' }
VGConformanceCorpus class >> tileFor: aContext [
	"A source surface in the family of the context, of the extent every case draws at, cleared to
	 a colour with its right half painted over, so a pattern over it shows which half of it a
	 pixel came from."

	| tile tileContext |
	tile := (self classNamed: 'ImageSurface' for: aContext) extent: self caseExtent.
	tileContext := tile newContext.
	tileContext clearColor: (Color r: 0.1 g: 0.6 b: 0.8).
	tileContext sourceColor: (Color r: 1.0 g: 0.5 b: 0.0).
	tileContext
		rectangleX: self caseExtent x / 2
		y: 0
		width: self caseExtent x / 2
		height: self caseExtent y.
	tileContext fill.
	tile flush.
	^ tile
]

{ #category : 'cases' }
VGConformanceCorpus class >> transformCases [
	"The matrix, read through a shape whose position and shape depend on it. The matrix itself is
	 unit 1.2, but a case is only drawable once the shape verbs arrive, so these are filed under
	 unit 1.3."

	^ {
		  (self case: 'transform-translated-rectangle' unit: '1.3' draw: [ :context |
			    context
				    translateBy: 12 @ 20;
				    rectangleX: 0 y: 0 width: 24 height: 16;
				    fill ]).
		  (self antialiasedCase: 'transform-rotated-rectangle' unit: '1.3' draw: [ :context |
			    context
				    translateBy: 32 @ 32;
				    rotateByRadians: Float pi / 6;
				    rectangleX: -16 y: -10 width: 32 height: 20;
				    fill ]).
		  (self antialiasedCase: 'transform-scaled-circle' unit: '1.3' draw: [ :context |
			    context
				    translateBy: 32 @ 32;
				    scaleBy: 1.8 @ 0.6;
				    circleCenterX: 0 y: 0 radius: 16;
				    fill ]) }
]

{ #category : 'constants' }
VGConformanceCorpus class >> twoStopRamp [
	"Two stops, so that a gradient case shows an interpolation rather than a flat fill."

	^ {
		  (0.0 -> (Color r: 1.0 g: 0.9 b: 0.2)).
		  (1.0 -> (Color r: 0.1 g: 0.2 b: 0.8)) }
]
