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

{ #category : 'cases' }
VGConformanceCorpus class >> groupCases [
	"Unit 1.7: the group, the mask and the one operator AeCanvas sets. The mask surface is built
	 reflectively, as the harness target is, so that the case stops on the group selector it is
	 filed under rather than on the unit 1.1 constructor."

	^ {
		  (self case: 'group-painted-with-alpha' unit: '1.7' draw: [ :context |
			    context paintGroupWith: [ :each |
				    each
					    circleCenterX: 24 y: 32 radius: 18;
					    fill;
					    circleCenterX: 40 y: 32 radius: 18;
					    fill ] alpha: 0.5 ]).
		  (self case: 'group-masked-by-surface' unit: '1.7' draw: [ :context |
			    context maskSurface: VGCairoImageSurface basicNew x: 16 y: 16 ]).
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

{ #category : 'cases' }
VGConformanceCorpus class >> pathCases [
	"Unit 1.3: a path, a fill rule, and the three painting verbs. The source is left alone, because
	 a context starts with opaque black, so these cases owe nothing to unit 1.5."

	^ {
		  (self case: 'path-filled-rectangle' unit: '1.3' draw: [ :context |
			    context
				    rectangleX: 8 y: 8 width: 48 height: 24;
				    fill ]).
		  (self case: 'path-filled-circle' unit: '1.3' draw: [ :context |
			    context
				    circleCenterX: 32 y: 32 radius: 20;
				    fill ]).
		  (self case: 'path-filled-rounded-rectangle' unit: '1.3' draw: [ :context |
			    context
				    roundedRectangleLeft: 6 top: 6 right: 58 bottom: 58 tl: 16 tr: 2 br: 16 bl: 2;
				    fill ]).
		  (self case: 'path-filled-star-even-odd' unit: '1.3' draw: [ :context |
			    context useFillRuleEvenOdd.
			    self appendFivePointedStarTo: context.
			    context fill ]).
		  (self case: 'path-filled-star-winding' unit: '1.3' draw: [ :context |
			    context useFillRuleWinding.
			    self appendFivePointedStarTo: context.
			    context fill ]).
		  (self case: 'path-curve-stroked' unit: '1.3' draw: [ :context |
			    context
				    moveTo: 6 @ 48;
				    curveVia: 20 @ 4 via: 44 @ 60 to: 58 @ 16;
				    stroke ]).
		  (self case: 'path-painted-whole-target' unit: '1.3' draw: [ :context | context paint ]) }
]

{ #category : 'cases' }
VGConformanceCorpus class >> sourceCases [
	"Unit 1.5: what the painting verbs take their colour from. Each of the four pattern classes
	 appears here, because a class no case names would never be exercised at all."

	^ {
		  (self case: 'source-flat-colour' unit: '1.5' draw: [ :context |
			    context
				    sourceColor: (Color r: 0.9 g: 0.3 b: 0.1);
				    rectangleX: 8 y: 8 width: 48 height: 48;
				    fill ]).
		  (self case: 'source-colour-pattern' unit: '1.5' draw: [ :context |
			    context
				    sourcePattern: (VGCairoColorPattern r: 0.1 g: 0.7 b: 0.4);
				    paint ]).
		  (self case: 'source-linear-gradient' unit: '1.5' draw: [ :context |
			    context
				    sourcePattern: (VGCairoLinearGradientPattern
						     from: 0 @ 0
						     to: 64 @ 64
						     addStopsFrom: self twoStopRamp);
				    paint ]).
		  (self case: 'source-radial-gradient' unit: '1.5' draw: [ :context |
			    context
				    sourcePattern: (VGCairoRadialGradientPattern
						     innerCenter: 32 @ 32
						     innerRadius: 2
						     outerCenter: 32 @ 32
						     outerRadius: 30
						     addStopsFrom: self twoStopRamp);
				    paint ]).
		  (self case: 'source-surface-pattern' unit: '1.5' draw: [ :context |
			    context
				    sourcePattern: (VGCairoSurfacePattern surface: VGCairoImageSurface basicNew);
				    rectangleX: 0 y: 0 width: 64 height: 64;
				    fill ]).
		  (self case: 'source-surface-directly' unit: '1.5' draw: [ :context |
			    context
				    sourceSurface: VGCairoImageSurface basicNew;
				    rectangleX: 0 y: 0 width: 64 height: 64;
				    fill ]) }
]

{ #category : 'cases' }
VGConformanceCorpus class >> strokeCases [
	"Unit 1.4: the stroke parameters. The cap, the join and the fill rule are named by symbol here,
	 so that the corpus runs in an image that has no Cairo at all; unit 1.4 decides whether the
	 setters also accept Alexandrie's own enumeration objects, which AeCanvas passes them."

	^ {
		  (self case: 'stroke-caps' unit: '1.4' draw: [ :context |
			    #( #butt #round #square ) doWithIndex: [ :each :index |
				    context
					    strokeCap: each;
					    strokeSize: 9;
					    lineFrom: 14 @ (index * 16) to: 50 @ (index * 16);
					    stroke ] ]).
		  (self case: 'stroke-joins' unit: '1.4' draw: [ :context |
			    #( #miter #round #bevel ) doWithIndex: [ :each :index |
				    context
					    strokeJoin: each;
					    strokeJoinMiterLimit: 10;
					    strokeSize: 7;
					    moveTo: 10 @ (index * 20);
					    lineTo: 32 @ (index * 20 - 12);
					    lineTo: 54 @ (index * 20);
					    stroke ] ]).
		  (self case: 'stroke-dashes' unit: '1.4' draw: [ :context |
			    context
				    strokeSize: 5;
				    strokeDashPattern: #( 9 4 ) offset: 2;
				    lineFrom: 6 @ 32 to: 58 @ 32;
				    stroke ]).
		  (self case: 'stroke-antialias-none' unit: '1.4' draw: [ :context |
			    context
				    antialias: #none;
				    tolerance: 0.1;
				    circleCenterX: 32 y: 32 radius: 20;
				    fill ]) }
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

{ #category : 'cases' }
VGConformanceCorpus class >> transformCases [
	"Unit 1.2: the matrix, read through a shape whose position and shape depend on it."

	^ {
		  (self case: 'transform-translated-rectangle' unit: '1.2' draw: [ :context |
			    context
				    translateBy: 12 @ 20;
				    rectangleX: 0 y: 0 width: 24 height: 16;
				    fill ]).
		  (self case: 'transform-rotated-rectangle' unit: '1.2' draw: [ :context |
			    context
				    translateBy: 32 @ 32;
				    rotateByRadians: Float pi / 6;
				    rectangleX: -16 y: -10 width: 32 height: 20;
				    fill ]).
		  (self case: 'transform-scaled-circle' unit: '1.2' draw: [ :context |
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
