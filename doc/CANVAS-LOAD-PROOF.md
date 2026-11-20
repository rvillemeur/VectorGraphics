# The canvas load proof — to run on a real machine

`CANVAS-SPLIT-PLAN.md` split the canvas in three so that each part can be taken on its own: the
font layer with no renderer, the renderer with no font code, the canvas API with neither the
scan-line engine nor the text glue. Nothing of that is proved in the development image, where every
package is present already. This document loads each new group into a blank Pharo 13 or 14 image
and records what arrives. The development image of this project is Pharo 14.

`doc/P7-LOAD-PROOF.md` is the precedent and the same rules hold. Five steps, each one in its **own
fresh image**: a group loaded next to another group proves nothing. Every expression below was run
in the development image first, so each one is known to work when the packages it names are
present, and the numbers after "Expect" are what it answered there.

## 0. Once: a fresh image per step

Two ways to point Metacello at the code.

From GitHub, which needs `main` pushed first — when this was written the local branch was ahead of
the remote, `56445bd` against `6903791`:

```smalltalk
repository: 'github://rvillemeur/VectorGraphics:main/src'
```

From the checkout on this machine, which needs no push and is what makes the proof runnable the
minute a unit is committed:

```smalltalk
repository: 'tonel:///home/renaud/devzone/iceberg/rvillemeur/VectorGraphics/src'
```

A fresh image per step, however you normally get one:

```bash
mkdir -p ~/canvas-proof/step1 && cd ~/canvas-proof/step1
curl -s https://get.pharo.org/64/140+vm | bash
```

A virtual machine is on this machine already, under `~/devzone/Pharo/vms/140-x64`, so a blank image
alone is enough if you would rather not fetch a second one. Metacello caches a GitHub fetch under
`pharo-local/package-cache`, so only the first step downloads.

## The check to paste after each load

One expression. It prints the packages that arrived and the names the load left undeclared, which
is how a reference across a package boundary that the baseline does not declare shows itself:

```smalltalk
| out |
out := WriteStream on: String new.
out nextPutAll: 'packages: '; print: (((PackageOrganizer default packages select: [ :each |
	  each name beginsWith: 'VectorGraphics' ]) collect: [ :each | each name asString ])
	 asSortedCollection asArray); cr.
out nextPutAll: 'undeclared: '; print: (Smalltalk globals undeclared keys asSortedCollection asArray).
out contents
```

`BaselineOfVectorGraphics` is its own package and is not matched by that prefix, so it never appears
in the answer.

## Step 1 — `canvas-raster` alone

```smalltalk
Metacello new
	baseline: 'VectorGraphics';
	repository: 'tonel:///home/renaud/devzone/iceberg/rvillemeur/VectorGraphics/src';
	onConflictUseIncoming;
	load: 'canvas-raster'
```

Expected packages: `VectorGraphics-Canvas-Raster`, and nothing else. The renderer requires nothing:
no canvas API, no font code, no scan-line engine, no library and no window.

Expected undeclared: `VGCairoState` and `VGPaint`, and no other name. They are the four references
the renderer still makes into `VectorGraphics-Canvas`, which section 8 of `CANVAS-SPLIT-PLAN.md`
holds open as its one deferred review point:

```
VGCoonsPatch class >> channelsOf:                -> VGPaint
VGRasteriser class >> segments:fillRule:clip:    -> VGCairoState
VGSegments class >> coordinates:fillRule:        -> VGCairoState
VGStroker class >> path:matrix:lineWidth:        -> VGCairoState
```

A name beyond those two is a new reference and a red architecture test in the development image.
Then prove the package works alone, which it does because the backend selection asks for nothing
the package does not hold:

```smalltalk
{ VGSoftwareBackend isCandidate. VGSoftwareBackend probe class name }
```

Expect `#(true #VGSoftwareBackend)`.

## Step 2 — `canvas-fonts` with no renderer

```smalltalk
Metacello new
	baseline: 'VectorGraphics';
	repository: 'tonel:///home/renaud/devzone/iceberg/rvillemeur/VectorGraphics/src';
	onConflictUseIncoming;
	load: 'canvas-fonts'
```

Expected packages, three: `VectorGraphics-Canvas-Fonts`, `VectorGraphics-TrueType` and
`VectorGraphics-Paths` — the font layer names the `.ttf` reader, which answers a glyph as path
commands. Expected undeclared: nothing at all. This package is a leaf and makes no reference into
the canvas.

Absence, which is the claim of this step:

```smalltalk
{ (#VGSoftwareBackend -> (Smalltalk includesKey: #VGSoftwareBackend)).
  (#VGCairoContext -> (Smalltalk includesKey: #VGCairoContext)).
  (#VectorEngineAbstract -> (Smalltalk includesKey: #VectorEngineAbstract)).
  (#VGFontFace -> (Smalltalk includesKey: #VGFontFace)) }
```

Expect `false false false true`. Then scale a font and read a glyph outline, with no renderer in the
image. The face is the one Pharo embeds, so no system font has to be installed:

```smalltalk
| face |
face := VGFontFace default.
{ face familyName. face styleName. face glyphCount. face unitsPerEm.
  (face outlineOfGlyphAt: (face glyphIndexForCodePoint: $A codePoint)) class name }
```

Expect `#('Source Sans Pro' 'Regular' 1942 1000 #VGGlyphOutline)`.

## Step 3 — `canvas` brings neither the engine nor the glue

```smalltalk
Metacello new
	baseline: 'VectorGraphics';
	repository: 'tonel:///home/renaud/devzone/iceberg/rvillemeur/VectorGraphics/src';
	onConflictUseIncoming;
	load: 'canvas'
```

Expected packages, five: the three of the canvas, plus `VectorGraphics-TrueType` and
`VectorGraphics-Paths` under the font layer. `VectorGraphics-Engine`, `VectorGraphics-Text` and the
front-page `VectorGraphics` package must be absent:

```smalltalk
{ (#VectorEngineAbstract -> (Smalltalk includesKey: #VectorEngineAbstract)).
  (#VectorCanvas -> (Smalltalk includesKey: #VectorCanvas)).
  (#VGCairoContext -> (Smalltalk includesKey: #VGCairoContext)) }
```

Expect `false false true`. Then draw and read a pixel back, which is the whole stack from the
display list to the span writer:

```smalltalk
| surface context form |
surface := VGCairoImageSurface extent: 16 @ 16.
context := VGCairoContext newFor: surface.
context
	sourceColor: Color red;
	rectangleX: 2 y: 2 width: 8 height: 8;
	fill.
surface flush.
form := surface asForm.
{ VGBackend preferredClass name. (form colorAt: 4 @ 4). (form colorAt: 14 @ 14) }
```

Expect `#(#VGSoftwareBackend Color red Color transparent)`.

## Step 4 — `default`, unchanged in what it loads

```smalltalk
Metacello new
	baseline: 'VectorGraphics';
	repository: 'tonel:///home/renaud/devzone/iceberg/rvillemeur/VectorGraphics/src';
	onConflictUseIncoming;
	load: 'default'
```

Expected packages, eight: `VectorGraphics`, `VectorGraphics-Paths`, `VectorGraphics-Engine`,
`VectorGraphics-TrueType`, `VectorGraphics-Text`, and the three of the canvas. That is the same
content a `default` load had before the split, with one package of the canvas replaced by three,
and it is the step that proves the split cost an existing user nothing.

```smalltalk
| surface context form ink |
surface := VGCairoImageSurface extent: 64 @ 32.
context := VGCairoContext newFor: surface.
context
	sourceColor: Color black;
	fontSize: 18;
	moveToX: 2 y: 24;
	showText: 'Hi'.
surface flush.
form := surface asForm.
ink := 0.
0 to: 63 do: [ :x |
	0 to: 31 do: [ :y | (form colorAt: x @ y) isTransparent ifFalse: [ ink := ink + 1 ] ] ].
{ ink. (Smalltalk includesKey: #VectorCanvas) }
```

Expect `#(105 true)`: the glyphs of the embedded face, rasterised through the canvas, and the
scan-line engine present beside it.

## Step 5 — the three test groups, and the suites

```smalltalk
Metacello new
	baseline: 'VectorGraphics';
	repository: 'tonel:///home/renaud/devzone/iceberg/rvillemeur/VectorGraphics/src';
	onConflictUseIncoming;
	load: #( 'canvas-tests' 'canvas-raster-tests' 'canvas-fonts-tests' )
```

Expected packages, fifteen: the three of the canvas, their three `-Examples` and their three
`-Tests`, `VectorGraphics-Conformance`, `VectorGraphics-Tests` for the abstract documentation gate,
`VectorGraphics-Paths`, `VectorGraphics-TrueType` and its own `-Examples` and `-Tests`, which the
font tests require. The front-page `VectorGraphics` package is **not** among them.

```smalltalk
| out |
out := WriteStream on: String new.
#( 'VectorGraphics-Canvas-Tests' 'VectorGraphics-Canvas-Raster-Tests'
   'VectorGraphics-Canvas-Fonts-Tests' ) do: [ :name |
	| suite |
	suite := TestSuite new.
	(PackageOrganizer default packageNamed: name) definedClasses do: [ :each |
		((each inheritsFrom: TestCase) and: [ each isAbstract not ]) ifTrue: [
			suite addTests: each buildSuiteFromSelectors tests ] ].
	out nextPutAll: name; nextPutAll: ' '; nextPutAll: suite run printString; cr ].
out contents
```

Expected counts, from the development image: 274, 84 and 47 — 405 tests. `VGCairoExamplesTest`, in
`VectorGraphics-Canvas-Tests`, renders through every example of the canvas and takes minutes; the
run is not hung.

Three differences from the development image are expected and are not failures.

- **Skips for the missing checkout.** The gates that read `doc/ARCHITECTURE.md` find no Iceberg
  checkout and skip with *"There is no checkout of VectorGraphics in this image"*.
- **Skips for the missing Alexandrie.** No group of the canvas names Alexandrie, so a loaded image
  has no `Ae*` class and every test that compares against live Cairo skips on its own guard: the
  whole of `VGAlexandrieCorpusTest`, three of the six `VGCairoInventoryTest` tests, four of sixteen
  in `VGCairoMatrixTest`, two of twenty-two in `VGCairoContextStateTest` and one of twenty-nine in
  `VGCairoSurfaceTest`.
- **One documentation gate.** Asking for one layer brings one gate, which
  `testTheGateHierarchyFindsEveryDocumentedPackage` was already changed for.

One hole is known in advance, and the step is worth running for it alone.
`VGConformanceTest` has no such guard: `testEveryCaseThatDrawsMatchesCairo`,
`testAPatternOrASurfaceInACaseIsBuiltFromTheFamilyOfTheContextItDrawsOn` and
`testTheExperimentsPortedFromAlexandrieReadTheirFontWithNoFreeType` render a reference through
`AeCairoImageSurface`, so they will error rather than skip. Record the result before changing
anything. The fix is one of two, and it is a decision rather than a repair: guard those three the
way `VGAlexandrieCorpusTest` guards itself, with `VGAlexandrieCorpus isAvailable`, or declare
Alexandrie as a requirement of the canvas test packages and accept that asking for the suite fetches
it.

## What to send back

Per step: the `packages:` line, the `undeclared:` line, the absence list and the one working
snippet; for step 5 the three suite lines and whatever `VGConformanceTest` did. A package that
should not be there is a missing narrowing in `BaselineOfVectorGraphics >> declareBackendPackagesOn:`
or `declareGroupsOn:`; an undeclared name is a reference the architecture table does not allow; a
load error naming a class is a missing `requires:`. Each of the three can then be made to show the
same thing as a red test in the development image, which is where it gets fixed.
