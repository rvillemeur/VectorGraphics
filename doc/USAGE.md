# Using VectorGraphics in place of Alexandrie

VectorGraphics answers the same messages as the Cairo layer of Alexandrie, so a drawing moves from
one to the other without a line of its own changing.
This file shows the three levels at which the replacement is used, and how to run the Alexandrie
experiment corpus through it.

## The Cairo layer: a surface and a context

`VGCairoImageSurface` stands in for `AeCairoImageSurface` and answers a `VGCairoContext`, which
carries the selectors of `AeCairoContext`.

```smalltalk
| surface context |
surface := VGCairoImageSurface extent: 40 @ 40.
context := surface newContext.
context
	sourceColor: Color red;
	rectangleX: 5 y: 5 width: 20 height: 10;
	fill.
surface flush.
surface asForm
```

## A canvas: VGCanvas

Bloc draws through an `AeCanvas`, and almost all of that class is backend independent.
`VGCanvas` is an `AeCanvas` that overrides the six methods which build a backend object: the two
that build a surface, the two that build a gradient pattern, the one that builds the blurred alpha
surface of a shadow, and the one that builds a scaled font.
Everything else stays Alexandrie's.

```smalltalk
| canvas |
canvas := VGCanvas extent: 60 @ 60.
canvas
	pathFactory: [ :context | context rectangleX: 10 y: 10 width: 30 height: 20 ];
	setBackgroundWith: [ canvas setSourceColor: Color blue ];
	setBorderOff;
	drawFigureAndPrepareToClip: false.
canvas asForm
```

`setBackgroundWith:` takes a block that sets the source, not a colour; a colour passed there trips
an assertion inside Alexandrie.
`VGCanvasExamples` holds the same canvas as a one-click example, with a gradient one beside it.

## All of Bloc

`VGRenderer` is a `BARenderer`, and a host asks `BlHostRenderer preferableClass` for the engine of
every space it opens.
That default is `allSubclasses anyOne`, so name the one you want.

```smalltalk
BlHostRenderer preferableClass: VGRenderer.   "draw with VectorGraphics"
BlHostRenderer preferableClass: BARenderer.   "draw with Alexandrie again"
```

A window then reports `VectorGraphics` where Bloc names its engine.
Without a window:

```smalltalk
VGRenderer newFormFrom: aBlElement.
VGRenderer write: aBlElement asPngTo: 'drawing.png' asFileReference.
```

Bloc measures a paragraph during layout, before any frame exists, and the canvas that answers those
measurements is `VGOffscreen instance textMeasurer`.

## The Alexandrie experiment corpus

`AlexandrieCairoExperiment` belongs to the BookletGraphics package and holds 82 drawings.
`VGAlexandrieCorpus regenerate` derives one class-side method per experiment onto
`VGAlexandriePortedExperiments`, substituting the Alexandrie class names that have a counterpart of
ours and changing nothing else.
Those copies are generated: send `regenerate` and commit what it writes rather than editing one by
hand, and `VGAlexandrieCorpus driftingCases` names every copy that no longer matches.

A copy that runs carries the `<sampleInstance>` pragma, so the browser draws it in one click.

```smalltalk
VGAlexandriePortedExperiments meshPattern.
VGAlexandriePortedExperiments ContextPathWithArcCircle asMorph openInWindow.
```

A case draws the same script both ways and carries the verdict of the conformance gate.

```smalltalk
| case |
case := VGAlexandrieCase for: #meshPattern.
case ourForm.             "drawn by VectorGraphics"
case cairoForm.           "drawn live by Alexandrie"
case matchesCairo.        "the gate's own answer"
case comparisonWithCairo  "a VGFormComparison, with five inspector views"
```

`VGAlexandrieCorpus cases` is all 82 of them, and the corpus has a progress view of its own, so
`VGAlexandrieCorpus inspect` says how many of them draw.
Five do not.
`fillPaint1`, `fillPaint2`, `texWithHarfbuzzWithFontManager`, `textAllGlyphsInFontFace` and
`textWithoutHarfbuzzWithFontManager` still name `AeCairoFontOptions`, `AeCairoFreetypeFontFace`
and `AeCairoScaledFont`, which have no counterpart here yet, so those five carry no pragma and
raise a `MessageNotUnderstood` when they are clicked.
`getNumberOfGlyph` answers a number rather than a picture and is no case at all.

Two costs are worth knowing before a walk of the whole corpus.
A mesh is sampled at half a pixel in device space, so the largest mesh case takes about seventeen
seconds and an ordinary one about four.
`VGAlexandrieCase >> ourForm` renders on every send and is not memoised, so each traversal of the
corpus draws all of it again.

