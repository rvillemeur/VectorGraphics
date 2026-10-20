"
I am the second conformance corpus: the Cairo drawings that live as class-side
<sampleInstance> methods on AlexandrieCairoExperiment, used as an oracle for the replacement.

I do not copy those drawings by hand. VGAlexandriePortedExperiments holds one derived copy of each,
in which every Alexandrie class name that has a counterpart of ours is substituted for it and
nothing else changes, so the original stays the single source and VGAlexandrieCorpusTest fails when
a derived copy drifts from it. A case therefore runs the same script twice, once on Cairo and once
on us, and compares the two Forms.

My cases answer, through VGAlexandrieCase, which selector or which class still blocks them, so the
corpus reports how much of the real Cairo surface the engine covers, unit by unit.
"
Class {
	#name : 'VGAlexandrieCorpus',
	#superclass : 'Object',
	#category : 'VectorGraphics-Cairo-Tests-Conformance',
	#package : 'VectorGraphics-Cairo-Tests',
	#tag : 'Conformance'
}

{ #category : 'accessing' }
VGAlexandrieCorpus class >> allExperimentSelectors [
	"Every drawing the experiment class offers, found by its pragma rather than by a kept list."
	self experimentClass ifNil: [ ^ #(  ) ].
	^ (self experimentClass class selectors select: [ :each |
		   (self experimentClass class >> each) pragmas anySatisfy: [ :one |
			   one selector = #sampleInstance ] ]) asSortedCollection asArray
]

{ #category : 'constants' }
VGAlexandrieCorpus class >> antialiasedEdgeTolerance [
	"How far a channel of an antialiased edge pixel of an experiment may sit from Alexandrie's own.
	 Our scan converter samples the same grid as Cairo's, so the two agree on every pixel a shape
	 covers wholly or not at all, and part only on the shades along a curve, a slanted edge or a
	 half-pixel stroke. How far apart a shade can be follows the contrast across the edge, and these
	 experiments are drawn in saturated colours: the worst measured is thirty-five of two hundred
	 and fifty-five, on the rim of a yellow to red sphere over dark blue, where the conformance
	 corpus of this plan, drawn in quieter colours, stays within twenty-one. The exterior is held
	 exactly in every case, which is the condition that catches a wrong shape."

	^ 36
]

{ #category : 'substitution' }
VGAlexandrieCorpus class >> cairoClassNamesUsed [
	"Every Alexandrie Cairo class the experiments name, read from their literals."
	| names |
	names := Set new.
	self experimentSelectors do: [ :each |
		names addAll: (VGAlexandrieCase for: each) referencedCairoClassNames ].
	^ names asSortedCollection asArray
]

{ #category : 'accessing' }
VGAlexandrieCorpus class >> cases [
	^ self experimentSelectors collect: [ :each | VGAlexandrieCase for: each ]
]

{ #category : 'accessing' }
VGAlexandrieCorpus class >> casesWithCairosToyDefaultFont [
	"The cases whose drawing sends a text verb without selecting a font, so Cairo draws them in the
	 toy default face it picks through fontconfig. This replacement binds no fontconfig and uses
	 the face Pharo bundles, so the glyphs are a different typeface and no tolerance on a channel
	 could honestly cover the difference; the shapes around the label are compared by the cases
	 that do select a font. `testEveryCaseWithNoSelectedFontIsFiled` holds this list against the
	 real rule, so a case added later is filed or fails."

	^ #( #lineCap #linejoin #linejoin2 )
]

{ #category : 'substitution' }
VGAlexandrieCorpus class >> classNameMap [
	"Alexandrie class name to ours, for the classes the experiments name and we have a counterpart
	 for. Longest first, so that substituting AeCairoSurface cannot eat AeCairoSurfaceFormat."
	| map |
	map := Dictionary new.
	self cairoClassNamesUsed do: [ :each |
		| ours |
		ours := self ourNameFor: each.
		(ours notNil and: [ Smalltalk includesKey: ours ]) ifTrue: [ map at: each put: ours ] ].
	^ (map associations asSortedCollection: [ :a :b | a key size >= b key size ]) asArray
]

{ #category : 'generating' }
VGAlexandrieCorpus class >> driftingCases [
	"Every case whose compiled copy is not what the substitution would write now, which is how an
	 edit to an experiment, or to a copy, is caught."
	^ self cases reject: [ :each | each portedCopyIsCurrent ]
]

{ #category : 'accessing' }
VGAlexandrieCorpus class >> experimentClass [
	"The class that holds the Alexandrie drawings. It belongs to the user's own BookletGraphics
	 package, so it may be absent from an image that only loaded the replacement."
	^ Smalltalk at: #AlexandrieCairoExperiment ifAbsent: [ nil ]
]

{ #category : 'accessing' }
VGAlexandrieCorpus class >> experimentSelectors [
	^ self allExperimentSelectors
		  reject: [ :each | self nonPictureSelectors includes: each ]
]

{ #category : 'inspecting' }
VGAlexandrieCorpus class >> inspectorProgress: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Waiting on'>
	^ aBuilder newTable
		  items: self progressDescription;
		  addColumn: (SpStringTableColumn
				   title: 'Unit'
				   evaluated: [ :each | each first ]);
		  addColumn: (SpStringTableColumn
				   title: 'Cases'
				   evaluated: [ :each | each second ]);
		  yourself
]

{ #category : 'inspecting' }
VGAlexandrieCorpus class >> inspectorProgressContext: aContext [
	"The corpus holds class-side behaviour only, so the view belongs to the class itself: a
	 subclass would have no experiments of its own, and the gate reads its position in the
	 hierarchy rather than naming me."
	aContext active: (self superclass == Object and: [ self isAvailable ])
]

{ #category : 'accessing' }
VGAlexandrieCorpus class >> isAvailable [
	^ self experimentClass notNil and: [ VGCairoInventory isLiveCairoAvailable ]
]

{ #category : 'constants' }
VGAlexandrieCorpus class >> missingClassUnitTable [
	"The Alexandrie Cairo classes the experiments name that the replacement has no counterpart for,
	 each against the unit of VECTORCANVAS-PLAN.md that owes it. The corpus reads this to say why a
	 case cannot run yet, so a class missing from the table is a gap the test reports.
	 The font classes name unit 1.10 rather than 1.8: unit 1.8 built the font face, the scaled
	 font, the metrics and the glyph atlas, but a case that draws text picks its font by family
	 name through AeFontManager and shapes it with HarfBuzz, and the bridge to those is what 1.10
	 brings."
	^ {
		  (#AeCairoAntialias -> '1.4').
		  (#AeCairoFontOptions -> '1.10').
		  (#AeCairoFreetypeFontFace -> '1.10').
		  (#AeCairoHintMetrics -> '1.10').
		  (#AeCairoHintStyle -> '1.10').
		  (#AeCairoScaledFont -> '1.10').
		  (#AeCairoSubpixelOrder -> '1.10').
		  (#AeCairoMeshPattern -> '1.12') }
]

{ #category : 'constants' }
VGAlexandrieCorpus class >> nearestSampleTolerance [
	"How far a channel of a surface pattern we sample without a filter may sit from Alexandrie's
	 own. Cairo filters a surface pattern it has to scale; we read the nearest pixel, which is
	 exact at one to one and coarse under a scale, and the real filters arrive with the surface unit
	 1.9. One experiment scales a bitmap to a quarter, and its worst pixel is ninety-five of two
	 hundred and fifty-five; the gate is set just above that so that a wrong shape still fails, and
	 the exterior of the picture is held exactly as everywhere else."

	^ 96
]

{ #category : 'accessing' }
VGAlexandrieCorpus class >> nonPictureSelectors [
	"The experiments that answer something other than a picture, so there is nothing to compare.
	 #getNumberOfGlyph answers a glyph count, and it asks the global font manager rather than a
	 Cairo surface."
	^ #( #getNumberOfGlyph )
]

{ #category : 'substitution' }
VGAlexandrieCorpus class >> ourNameFor: anAlexandrieClassName [
	"Our name for an Alexandrie Cairo class, which differs only in the prefix, or nil for a class
	 that is not part of the Cairo engine at all."
	^ (anAlexandrieClassName beginsWith: 'AeCairo')
		  ifTrue: [ ('VGCairo' , (anAlexandrieClassName allButFirst: 7)) asSymbol ]
		  ifFalse: [ nil ]
]

{ #category : 'accessing' }
VGAlexandrieCorpus class >> portedClass [
	^ VGAlexandriePortedExperiments
]

{ #category : 'inspecting' }
VGAlexandrieCorpus class >> progressDescription [
	"One row for every unit of the plan that the corpus is waiting on, with the number of cases it
	 unblocks. The counts are asked of the cases themselves, so the view states what the corpus
	 measures now rather than a number written down here."
	| counts |
	counts := self cases
		          inject: Bag new
		          into: [ :bag :each |
			          bag add: (each blockingUnit ifNil: [ 'draws already' ]).
			          bag ].
	^ (counts asSet asSortedCollection: [ :a :b |
		   (VGCairoInventory planUnits indexOf: a) <= (VGCairoInventory planUnits indexOf: b) ])
		  asArray collect: [ :each |
		  {
			  each.
			  (counts occurrencesOf: each) printString } ]
]

{ #category : 'generating' }
VGAlexandrieCorpus class >> regenerate [
	"Compile a derived copy of every experiment onto the ported class and remove the copies whose
	 original is gone. The copies are generated, never edited: VGAlexandrieCorpusTest compares each
	 one against what this would write."
	| wanted |
	wanted := self experimentSelectors asSet.
	self portedClass class selectors do: [ :each |
		(wanted includes: each) ifFalse: [ self portedClass class removeSelector: each ] ].
	self cases do: [ :each | each compilePortedCopy ].
	^ self portedClass class selectors size
]

{ #category : 'accessing' }
VGAlexandrieCorpus class >> toleranceFor: aSelector [
	^ (self toleranceTable detect: [ :each | each key = aSelector ] ifNone: [ nil ])
		  ifNil: [ 0 ]
		  ifNotNil: [ :each | each value ]
]

{ #category : 'constants' }
VGAlexandrieCorpus class >> toleranceTable [
	"The cases that may not match Cairo exactly, each with how far one channel may differ and why.
	 It is empty while no case renders; a case added here has to carry its reason, so that a
	 tolerance is never a quiet way of passing. Two reasons cover every entry: all but one of these
	 experiments draw a curve, a slanted edge or a half-pixel stroke, so their edge pixels are
	 shades and ours part from Cairo by a little, and fillPaint3 also scales a bitmap, which we
	 still sample without a filter. A clip of a circle is an edge of that kind too: the shade is
	 the one the clip itself carries, and the maskAndClip cases carry it twice over, because a
	 mask through a clip is scaled by the coverage of the rim of that clip. See
	 antialiasedEdgeTolerance and nearestSampleTolerance."

	| edges |
	edges := self antialiasedEdgeTolerance.
	^ {
		  (#ContextPathWithArcCircle -> edges).
		  (#ContextPathWithArcCurve -> edges).
		  (#ContextPathWithArcCurveCW -> edges).
		  (#ContextPathWithArcCurveExampleDraw -> edges).
		  (#ContextPathWithArcCurveExampleDrawClockWise -> edges).
		  (#ContextPathWithArcCurveExampleDrawCounterClockWise -> edges).
		  (#ContextPathWithArcCurveWithoutSubPath -> edges).
		  (#ContextPathWithArcSweep -> edges).
		  (#ContextPathWithCubicBezier -> edges).
		  (#ContextPathWithCubicBezier2 -> edges).
		  (#ContextPathWithCubicBezier3 -> edges).
		  (#ContextPathWithLine -> edges).
		  (#ContextPathWithQuadraticBezier -> edges).
		  (#ContextPathWithRoundedRectangle -> edges).
		  (#clip1 -> edges).
		  (#clip2 -> edges).
		  (#fillLinearGradientExperiment -> edges).
		  (#fillLinearGradientExperimentDiagonal -> edges).
		  (#fillPaint3 -> self nearestSampleTolerance).
		  (#lineColor -> edges).
		  (#lineDash -> edges).
		  (#linePath -> edges).
		  (#maskAndClip1 -> edges).
		  (#maskAndClip2 -> edges).
		  (#maskAndClip3 -> edges).
		  (#maskAndClip4 -> edges).
		  (#maskAndClip5 -> edges).
		  (#maskAndClip6 -> edges).
		  (#polygonLinearGradient -> edges).
		  (#radialGradientPattern1 -> edges).
		  (#strokeAndFill -> edges).
		  (#strokeAndFill2 -> edges).
		  (#transformationShear -> edges) }
]

{ #category : 'substitution' }
VGAlexandrieCorpus class >> unitForMissingClass: aClassName [
	^ (self missingClassUnitTable detect: [ :each | each key = aClassName ] ifNone: [ nil ])
		  ifNotNil: [ :each | each value ]
]
