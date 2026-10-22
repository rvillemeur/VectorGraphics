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

{ #category : 'conformance' }
VGAlexandrieCorpus class >> boundaryPixelAllowanceFor: aSelector [
	"How many pixels of that experiment may be further from Cairo than its tolerance allows.
	 None, unless the experiment paints a mesh or draws a run of glyphs: see meshBoundaryPixelTable
	 and hintedGlyphRunPixelTable. The two tables name disjoint experiments, because a mesh carries
	 no text, so the first entry found answers."

	^ ((self meshBoundaryPixelTable , self hintedGlyphRunPixelTable)
		   detect: [ :each | each key = aSelector ]
		   ifNone: [ nil ]) ifNil: [ 0 ] ifNotNil: [ :each | each value ]
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

{ #category : 'conformance' }
VGAlexandrieCorpus class >> hintedGlyphRunPixelTable [
	"The experiments that select a font and draw a run of glyphs, each with how many pixels may be
	 further from Cairo than hintedGlyphRunTolerance allows, and why there are any at all. Cairo
	 rasterises a glyph through FreeType, which grid-fits the outline to the pixel grid before
	 filling it, and this package fills the outline the font carries. Every stem therefore stands a
	 fraction of a pixel away from Cairo's and is a whole shade different down its whole length,
	 which is a disagreement about where the stem is and not about how much of a pixel it covers,
	 so one worst channel cannot bound it and a count of pixels does, as it does for a mesh. Unit
	 1.8 measured why it cannot be closed from outside Cairo's own face: the hinted advances are
	 not reproducible there. Each count is measured, with a tenth of headroom. The two paragraph
	 experiments measure one thousand two hundred and fifty-six and nine hundred and sixty-six
	 pixels of eighty-eight thousand; the two paint experiments, which draw one line of text over a
	 page of antialiased shapes, measure four hundred and seventy-four and one hundred and
	 eighty-six of three hundred and fifty thousand; and the experiment that draws every glyph the
	 face carries, which asks for hintStyle slight explicitly, measures thirty-four thousand nine
	 hundred and twelve of eight hundred and eighty thousand."

	^ {
		  (#fillPaint1 -> 522).
		  (#fillPaint2 -> 205).
		  (#texWithHarfbuzzWithFontManager -> 1063).
		  (#textAllGlyphsInFontFace -> 38404).
		  (#textWithoutHarfbuzzWithFontManager -> 1382) }
]

{ #category : 'conformance' }
VGAlexandrieCorpus class >> hintedGlyphRunTolerance [
	"How far one channel of a glyph may stand from Cairo's. It is the tolerance the atlas cases of
	 the plan's own corpus already carry, because the cause is the same one: Cairo rasterises a
	 glyph through FreeType and we walk the outline the font carries. See
	 VGConformanceCorpus class >> textAtlasTolerance and hintedGlyphRunPixelTable."

	^ VGConformanceCorpus textAtlasTolerance
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

{ #category : 'tolerances' }
VGAlexandrieCorpus class >> meshBoundaryPixelTable [
	"The mesh experiments, each with how many pixels may be further from Cairo than
	 meshColourTolerance allows, and why there are any at all. A mesh pattern is not
	 antialiased: Cairo paints whole pixels for the pieces it subdivides a patch into, so the
	 edge of a patch is a step, and a pixel that the patch only grazes is either the full colour
	 or untouched. Two rasterisers that walk a patch over different grids therefore disagree
	 about a ring of pixels one pixel wide along the boundary of every patch, and each of those
	 pixels is a whole colour apart, either as a pixel of ours Cairo leaves untouched, a pixel of
	 Cairo's we leave untouched, or a pixel where one of us has the patch and the other has
	 whatever was beneath it. The allowance of a case is therefore a count of boundary pixels and
	 not a distance; it is measured, with a tenth of headroom, and it is far below the perimeter
	 it belongs to. The four quadrant experiment measures one thousand one hundred and eighteen
	 against a perimeter of about two thousand eight hundred, because its patches lie over a
	 stroked circle and share their straight edges with each other; the single quadrant measures
	 forty-five, the Coons patch twenty-two and the mesh of the Cairo manual sixteen; the Gouraud
	 shaded triangles measure none at all, because every edge of those patches is a straight line
	 the two walks place identically."
	^ {
		  (#CanonicalGradientAllQuadrantPattern -> 1230).
		  (#CanonicalGradientFirstQuadrantPattern -> 50).
		  (#CoonsPatchMeshPattern -> 25).
		  (#GouraudShadingTriangleMesh -> 0).
		  (#meshPattern -> 18) }
]

{ #category : 'tolerances' }
VGAlexandrieCorpus class >> meshColourTolerance [
	"How far a channel of a mesh pattern may differ from Cairo away from the edge of a patch.
	 Cairo does not evaluate a mesh pixel by pixel: it subdivides a patch until a piece of it is
	 about a pixel across and writes the colour of the middle of that piece, so the colour of a
	 pixel is the colour of the surface somewhere inside it. Our own walk is finer, and the
	 sample we keep is the one nearest the middle of the pixel, so the two colours part by the
	 gradient of the patch over a fraction of a pixel. Measured over the four mesh experiments
	 that carry a gradient, that is eight of two hundred and fifty-five, and the pixels beyond it
	 are on the edge of a patch: of the one thousand and fifty-three pixels of the four quadrant
	 experiment that differ by more than eight, nine hundred and ninety-five lie on the arc the
	 patches share with the circle stroked beneath them, forty-eight on the axes they share with
	 each other, and ten beside the corner where all four patches collapse to a point, which is
	 where the colour swings fastest; the worst of those ten is nineteen. See
	 meshBoundaryPixelTable."
	^ 8
]

{ #category : 'constants' }
VGAlexandrieCorpus class >> missingClassUnitTable [
	"The Alexandrie Cairo classes the experiments name that the replacement has no counterpart
	 for, each against the unit of VECTORCANVAS-PLAN.md that owes it. The corpus reads this to
	 say why a case cannot run yet, so a class missing from the table is a gap the test reports.
	 It is empty since unit 1.13 gave the font classes their counterparts, and it stays here
	 because it is where the next gap is filed; testEveryFiledMissingClassIsReallyMissing is what
	 empties it, since a filed class whose counterpart exists is a gap reported after it closed."

	^ { }
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

{ #category : 'constants' }
VGAlexandrieCorpus class >> ourNameExceptions [
	"The Alexandrie Cairo classes whose counterpart here is not named by the prefix rule, each
	 against the name we give it. The font classes are named for what they are rather than for
	 Cairo, because the font stack of this project reads a font's own tables and calls no Cairo
	 function; the four enumeration classes do follow the rule and need no entry."

	^ {
		  (#AeCairoFreetypeFontFace -> #VGFontFace).
		  (#AeCairoScaledFont -> #VGScaledFont).
		  (#AeCairoFontOptions -> #VGFontOptions) }
]

{ #category : 'constants' }
VGAlexandrieCorpus class >> ourNameFor: anAlexandrieClassName [
	"Our name for an Alexandrie Cairo class, which differs only in the prefix except for the
	 classes ourNameExceptions names, or nil for a class that is not part of the Cairo engine at
	 all."

	(self ourNameExceptions
		 detect: [ :each | each key = anAlexandrieClassName ]
		 ifNone: [ nil ]) ifNotNil: [ :each | ^ each value ].
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

{ #category : 'tolerances' }
VGAlexandrieCorpus class >> strayAlphaAllowanceFor: aSelector [
	"How heavy a pixel we may paint outside Cairo's shape in that experiment. The corpus's own
	 allowance of one step of coverage holds everywhere but a mesh, whose edge is a step rather
	 than a shade: a pixel of a mesh is opaque or untouched, so the alpha of a stray says nothing
	 about how wrong it is and the count in meshBoundaryPixelTable is what bounds it."
	^ (self meshBoundaryPixelTable anySatisfy: [ :each | each key = aSelector ])
		  ifTrue: [ 255 ]
		  ifFalse: [ VGConformanceCorpus strayAlphaAllowance ]
]

{ #category : 'accessing' }
VGAlexandrieCorpus class >> toleranceFor: aSelector [
	^ (self toleranceTable detect: [ :each | each key = aSelector ] ifNone: [ nil ])
		  ifNil: [ 0 ]
		  ifNotNil: [ :each | each value ]
]

{ #category : 'conformance' }
VGAlexandrieCorpus class >> toleranceTable [
	"The cases that may not match Cairo exactly, each with how far one channel may differ and why.
	 It is empty while no case renders; a case added here has to carry its reason, so that a
	 tolerance is never a quiet way of passing. Four reasons cover every entry. All but one of
	 the first group draw a curve, a slanted edge or a half-pixel stroke, so their edge pixels are
	 shades and ours part from Cairo by a little, and fillPaint3 also scales a bitmap, which we
	 still sample without a filter. A clip of a circle is an edge of that kind too: the shade is
	 the one the clip itself carries, and the maskAndClip cases carry it twice over, because a
	 mask through a clip is scaled by the coverage of the rim of that clip. The mesh cases differ
	 for a third reason, which is that Cairo colours a pixel of a mesh from the middle of the
	 piece it subdivided the patch into rather than from the pixel itself. The cases that select a
	 font and draw a run of glyphs differ for a fourth, which is that Cairo grid-fits the outline
	 of a glyph through FreeType before filling it, so a stem of ours stands a fraction of a pixel
	 away from Cairo's; those cases are bounded by a count of pixels as well, because the distance
	 of one channel says nothing about a stem in the wrong place. See antialiasedEdgeTolerance,
	 nearestSampleTolerance, meshColourTolerance and hintedGlyphRunTolerance."

	| edges meshes glyphs |
	edges := self antialiasedEdgeTolerance.
	meshes := self meshColourTolerance.
	glyphs := self hintedGlyphRunTolerance.
	^ {
		  (#CanonicalGradientAllQuadrantPattern -> meshes).
		  (#CanonicalGradientFirstQuadrantPattern -> meshes).
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
		  (#CoonsPatchMeshPattern -> meshes).
		  (#GouraudShadingTriangleMesh -> meshes).
		  (#clip1 -> edges).
		  (#clip2 -> edges).
		  (#fillLinearGradientExperiment -> edges).
		  (#fillLinearGradientExperimentDiagonal -> edges).
		  (#fillPaint1 -> glyphs).
		  (#fillPaint2 -> glyphs).
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
		  (#meshPattern -> meshes).
		  (#polygonLinearGradient -> edges).
		  (#radialGradientPattern1 -> edges).
		  (#strokeAndFill -> edges).
		  (#strokeAndFill2 -> edges).
		  (#texWithHarfbuzzWithFontManager -> glyphs).
		  (#textAllGlyphsInFontFace -> glyphs).
		  (#textWithoutHarfbuzzWithFontManager -> glyphs).
		  (#transformationShear -> edges) }
]

{ #category : 'substitution' }
VGAlexandrieCorpus class >> unitForMissingClass: aClassName [
	^ (self missingClassUnitTable detect: [ :each | each key = aClassName ] ifNone: [ nil ])
		  ifNotNil: [ :each | each value ]
]
