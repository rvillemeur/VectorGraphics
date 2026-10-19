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
	     #textCases )
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
		  (self case: 'clip-circle' unit: '1.6' draw: [ :context |
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
	"Unit 1.7: the group, the mask and the one operator AeCanvas sets. The mask surface is a real
	 unit 1.1 surface, so a case stops on the group selector it is filed under."

	^ {
		  (self case: 'group-painted-with-alpha' unit: '1.7' draw: [ :context |
			    context paintGroupWith: [ :each |
				    each
					    circleCenterX: 24 y: 32 radius: 18;
					    fill;
					    circleCenterX: 40 y: 32 radius: 18;
					    fill ] alpha: 0.5 ]).
		  (self case: 'group-masked-by-surface' unit: '1.7' draw: [ :context |
			    context maskSurface: (VGCairoImageSurface extent: self caseExtent) x: 16 y: 16 ]).
		  (self case: 'group-masked-with-a-block' unit: '1.7' draw: [ :context |
			    context maskGroupWith: [ :each |
				    each
					    circleCenterX: 32 y: 32 radius: 16;
					    fill ] ]).
		  (self case: 'group-cleared-region' unit: '1.7' draw: [ :context |
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

{ #category : 'cases' }
VGConformanceCorpus class >> sourceCases [
	"Unit 1.5: what the painting verbs take their colour from. Each of the four pattern classes
	 appears here, because a class no case names would never be exercised at all. No case names a
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

{ #category : 'cases' }
VGConformanceCorpus class >> textCases [
	"Unit 1.8: glyphs. The scaled font is nil until unit 1.8 names the class that holds one, which is
	 enough for the unit 1.0 gate, because the case must stop on #scaledFont: anyway."

	^ {
		  (self case: 'text-glyph-run' unit: '1.8' draw: [ :context |
			    context
				    scaledFont: nil;
				    fontSize: 16;
				    moveTo: 6 @ 40;
				    showGlyphs: #() ]).
		  (self case: 'text-glyph-path' unit: '1.8' draw: [ :context |
			    context
				    scaledFont: nil;
				    appendGlyphsPath: #();
				    fill ]) }
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
