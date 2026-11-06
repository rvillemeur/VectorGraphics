# Splitting the `VectorGraphics` package

A plan to break the one 71-class package at the bottom of this project into packages that can be
loaded, tested and reused one at a time, each with its own tests package and its own examples
package.

Written 5 November 2026, against `VectorGraphics` repository head `443fe8f9`, working copy clean.

## 1. What exists today

One package, `VectorGraphics`, 71 classes and 867 methods, in the `rvillemeur/VectorGraphics`
repository. It has seven class tags:

| Tag | Classes | What it holds |
|---|---|---|
| `Kernel` | 6 | `VectorCanvas`, `VectorEngineAbstract`, `VectorEnginePixel`, `VectorEngineSubPixel`, `VectorEngineWholePixel`, `VectorEngineBoundsFinder` |
| `PathCommands` | 12 | `PathCommand` and its eleven subclasses, plus `PathCommandError` |
| `SVG` | 2 | `SVGPathParser`, `SVGNumberStream` |
| `TrueType` | 22 | the ten `TT…` parsers, `TTGlyph`, `TTCompositeGlyph`, `TTContourConstruction`, `TTFontDescription`, `TTFontReader`, `TTFontTableDirEntry`, `TTKernPair`, `TrueTypeFont`, `TrueTypeFontFamily`, `FontFamily`, `FormGlyph`, `Int16PointArray` |
| `Examples` | 2 | `VectorCanvasExample` (27 `<sampleInstance>` of 29 class-side methods), `TrueTypeExample` (8 of 11) |
| `Tests` | 26 | 24 `TestCase` classes plus two fixtures, `RecordingCanvas` and `MockNumberStream` |
| `Manifest` | 1 | `ManifestVectorGraphics`, which carries the package comment and no rule configuration |

Fifteen extension methods on base classes also live here: bit and byte accessors on `Bitmap`,
`ByteArray`, `WordArray` and `SmallInteger`, and `Character class >> utf8BytesOf:` with its
`evaluate:withUtf8BytesOf:` companion.

### The dependencies that exist, measured in the image

Cross-cluster class references, counted over method literals:

- `VectorCanvas` names `FontFamily` in exactly two methods, `drawString:from:to:at:font:color:` and
  `drawUtf8:at:font:color:`, both only to find a default font when the caller passes none.
- `TTFontDescription >> formGlyphForUtf8Byte1:byte2:byte3:byte4:pixelSize:` names `VectorCanvas`,
  `Form` and `FormGlyph`: it rasterises a glyph through the engine.
- `TTGlyph >> inspectorGlyph` names `VectorCanvas` and two Spec2 presenters.
- `TTContourConstruction` names `PathMoveToCommand` and `PathQuadraticCurveToCommand`.
- `FontFamily class >> readIfNeeded:` names `TrueTypeFontFamily`, so `FontFamily` cannot be
  separated from the TrueType code; it is the registry of that code, not a neutral protocol.
- `VectorEngineAbstract >> displayUtf8:at:trueTypeFont:color:scaleX:scaleY:` names
  `TTFontDescription`, for `isUtf8ContinuationByte:` and `unknownGlyphContourDataPosition`. This
  one was missed by the first count and found by the P2 gate; see §11.
- The path commands and the engine do not name each other at all: a command runs on a canvas
  polymorphically, through `runOn:`.

So the engine and the TrueType reader hold each other by six methods in total, and nothing else.

### What the layers above actually use

Every reference from the other nine packages of this project into `VectorGraphics`:

```
VectorGraphics-Cairo -> TTCmapTableParser TTFontReader TTGlyfTableParser TTHeadTableParser
                        TTHheaTableParser TTHmtxTableParser TTLocaTableParser TTMaxpTableParser
```

That is all. `VectorGraphics-Cairo` uses eight TrueType table parsers and nothing else;
`VectorGraphics-Bloc`, `VectorGraphics-Vulkan` and every test and examples package of the project
name nothing in this package. No package outside the project names anything in it either.

This is the strongest argument for the split: the whole Cairo-replacement stack depends on the
TrueType reader alone, and today it drags in the rasteriser, the path commands, the SVG parser and
their 24 test classes to get it.

## 2. What the split is for

1. The TrueType reader becomes loadable on its own, which is what the FreeType replacement work
   needs: HarfBuzz shapes from a font blob with no FreeType, and a pure-Pharo font manager needs the
   tables, not the canvas. See `reference_truetype_vs_freetype_cost` for the measured figures.
2. The engine becomes loadable on its own, as a Morphic rasteriser, with no font code.
3. Tests stop living in the code package, which is what the rest of this project already does and
   what `ReTestClassNotInPackageWithTestEndingNameRule` expects.
4. Examples move into `-Examples` packages as `<Subject>Examples` classes, as in the Cairo, Bloc and
   Vulkan layers.
5. Each half can gain a dependency without the other paying for it, and the architecture table says
   so out loud.

## 3. Target layout

Four code packages, each with a tests package and an examples package: twelve packages in place of
one. The project goes from ten packages to twenty-one.

### `VectorGraphics-Paths` — 14 classes, no dependencies

`PathCommand` and its eleven subclasses, `PathCommandError`, `SVGPathParser`, `SVGNumberStream`.
Tags: `Commands`, `SVG`, `Manifest`.

- `VectorGraphics-Paths-Tests`: `PathCommandDispatchTest`, `PathCommandParseTest`,
  `PathMoveToCommandTest`, `PathQuadraticCurveCommandTest`, fixture `MockNumberStream`.
- `VectorGraphics-Paths-Examples`: `PathCommandExamples` and `SVGPathExamples`, built from the
  seven `examplePathCommand…` and `exampleSvg…` methods of `VectorCanvasExample`. These draw on a
  canvas, so this examples package depends on `VectorGraphics-Engine`.

### `VectorGraphics-Engine` — 6 classes, no dependencies

`VectorCanvas` and the five `VectorEngine…` classes, plus the bit and byte extension methods on
`Bitmap`, `WordArray` and `ByteArray` that the engines send. Tags: `Kernel`, `Manifest`.

- `VectorGraphics-Engine-Tests`: `VectorCanvasTest`, `VectorEngineAbstractTest`,
  `VectorEnginePixelTest`, `VectorEngineWholePixelTest`, `VectorEngineBoundsFinderTest`,
  `PathCommandRunOnTest` (it runs commands on a canvas, so it belongs with the canvas), fixture
  `RecordingCanvas`.
- `VectorGraphics-Engine-Examples`: `VectorCanvasExamples`, the drawing examples of
  `VectorCanvasExample` minus the path, SVG and text ones.

### `VectorGraphics-TrueType` — 22 classes, depends on `VectorGraphics-Paths`

The ten table parsers, `TTFontParser`, `TTFontReader`, `TTFontTableDirEntry`, `TTGlyph`,
`TTCompositeGlyph`, `TTContourConstruction`, `TTFontDescription`, `TTKernPair`, `TrueTypeFont`,
`TrueTypeFontFamily`, `FontFamily`, `FormGlyph`, `Int16PointArray`, and
`Character class >> utf8BytesOf:` with its companion. Tags: `Reading`, `Glyphs`, `Fonts`,
`Manifest`.

The one edge is `TTContourConstruction`, which builds `PathMoveToCommand` and
`PathQuadraticCurveToCommand` as it walks a contour.

- `VectorGraphics-TrueType-Tests`: `TTFontParserTest`, `TTFontReaderTest`,
  `TTFontTableDirEntryTest`, `TTGlyphTest`, `TTCompositeGlyphTest`, `TTContourConstructionTest`,
  `TTFontDescriptionTest`, `TTKernPairTest`, `TrueTypeFontTest`, `TrueTypeFontFamilyTest`,
  `FontFamilyTest`, `FormGlyphTest`, `Int16PointArrayTest`.
- `VectorGraphics-TrueType-Examples`: `TrueTypeExamples`, from `TrueTypeExample`.

### `VectorGraphics-Text` — 0 classes, six extension methods, depends on both

The glue, and the whole reason the two halves can be split at all:

| Method | Moves from | Names |
|---|---|---|
| `VectorCanvas >> drawString:from:to:at:font:color:` | Engine | `FontFamily` |
| `VectorCanvas >> drawUtf8:at:font:color:` | Engine | `FontFamily` |
| `VectorEngineAbstract >> displayUtf8:at:trueTypeFont:color:scaleX:scaleY:` | Engine | `TTFontDescription` |
| `TTFontDescription >> formGlyphForUtf8Byte1:byte2:byte3:byte4:pixelSize:` | TrueType | `VectorCanvas`, `FormGlyph` |
| `TrueTypeFont >> glyphAtUtf8Byte1:byte2:byte3:byte4:` | TrueType | nothing; sends into the glue |
| `TTGlyph >> inspectorGlyph` | TrueType | `VectorCanvas`, Spec2 |

Each carries a comment naming the two packages it bridges and why it is not in either.

- `VectorGraphics-Text-Tests`: `VGTextDrawingTest`, the tests that drive the glue methods. P3 found
  these are the two unknown-glyph cases of `VectorEngineAbstractTest`, not cases of
  `VectorCanvasTest` or `TTFontDescriptionTest` as first assumed; see §12.
- `VectorGraphics-Text-Examples`: `TextDrawingExamples`, from `exampleDrawString` and
  `exampleDrawUtf8`.

A package with no classes of its own is unusual, and the alternative in §8 avoids it; the gain is
that neither half has to depend on the other.

## 4. The dependency table after the split

Entries to add to `VGArchitectureTest class >> allowedDependencies`, which is in
`VectorGraphics-Cairo-Tests` and is held against the real references by its own tests:

```
'VectorGraphics-Paths'             -> #(  )
'VectorGraphics-Paths-Tests'       -> #( 'VectorGraphics-Paths' 'VectorGraphics-Paths-Examples' )
'VectorGraphics-Paths-Examples'    -> #( 'VectorGraphics-Paths' 'VectorGraphics-Engine' )
'VectorGraphics-Engine'            -> #(  )
'VectorGraphics-Engine-Tests'      -> #( 'VectorGraphics-Engine' 'VectorGraphics-Engine-Examples'
                                         'VectorGraphics-Paths' )
'VectorGraphics-Engine-Examples'   -> #( 'VectorGraphics-Engine' )
'VectorGraphics-TrueType'          -> #( 'VectorGraphics-Paths' )
'VectorGraphics-TrueType-Tests'    -> #( 'VectorGraphics-TrueType'
                                         'VectorGraphics-TrueType-Examples' 'VectorGraphics-Engine' )
'VectorGraphics-TrueType-Examples' -> #( 'VectorGraphics-TrueType' )
'VectorGraphics-Text'              -> #( 'VectorGraphics-Engine' 'VectorGraphics-TrueType' )
'VectorGraphics-Text-Tests'        -> #( 'VectorGraphics-Text' 'VectorGraphics-Text-Examples'
                                         'VectorGraphics-Engine' 'VectorGraphics-TrueType' )
'VectorGraphics-Text-Examples'     -> #( 'VectorGraphics-Text' 'VectorGraphics-Engine'
                                         'VectorGraphics-TrueType' )
```

and the one existing entry that changes:

```
'VectorGraphics-Cairo' -> #( 'VectorGraphics-TrueType' )
```

`VectorGraphics-Bloc` and `VectorGraphics-Vulkan` keep their edges to `VectorGraphics-Cairo` and
gain none, because they name nothing in the old package.

`BaselineOfVectorGraphics >> declarePackagesOn:` gets the same twelve packages with the same
`requires:`, and `declareGroupsOn:` gains `paths`, `engine`, `truetype`, `text` and their
`-examples` and `-tests` groups. The `core` group stays, as the union of `paths`, `engine`,
`truetype` and `text`, so `default` and every existing loader keep working. The project-wide
`examples` and `tests` groups gain the four new layer groups.

## 5. Phases

Each phase ends green, is committed on its own, and the suite is run before and after. Every class
move and method move happens through the image with the MCP tools; no Tonel file is hand-edited.

**P0 — the baseline.** Record, in this file, the per-class test counts of all 24 test classes and
the total, read per concrete class rather than per package (a package-level count double-counts the
subclasses of an abstract `TestCase`). Record `run_critics` output on `VectorGraphics`. Commit
nothing; this is the number every later phase is held to.

**P1 — the four code packages.** Create `VectorGraphics-Paths`, `VectorGraphics-Engine`,
`VectorGraphics-TrueType` and `VectorGraphics-Text` with their tags, and move the 44 code classes
into them with `packageTag:`. Tests and examples stay where they are for now; they keep passing
because a class move does not change a reference. Gate: the suite count equals P0's, and
`run_critics` on each new package is clean but for the `ReClassNotCategorizedRule` fixed by the tag.

**P2 — the glue.** Move the glue methods of §3 into `VectorGraphics-Text` as extension methods, each
with its comment. Gate: a reference scan in the image shows `VectorGraphics-Engine` names no class
of `VectorGraphics-TrueType` and vice versa, and `VectorGraphics-TrueType` names only
`VectorGraphics-Paths`. This is the phase the whole plan exists for; if it does not come out clean
the split is not worth doing.

**P3 — the test packages.** Create the four `-Tests` packages with `Tests` and `Fixtures` tags and
move the 24 test classes and two fixtures as listed in §3, splitting `VectorCanvasTest` and
`TTFontDescriptionTest` so the text cases land in `VectorGraphics-Text-Tests`. Gate: same total test
count as P0, every test class in a package named for what it covers, no code package holding a
`TestCase`.

**P4 — the examples packages.** Create the four `-Examples` packages. Rename `VectorCanvasExample`
to `VectorCanvasExamples` and `TrueTypeExample` to `TrueTypeExamples`, write `PathCommandExamples`,
`SVGPathExamples` and `TextDrawingExamples`, give each a class comment, drop the `example` prefix
from every selector, and rename any example that opens a window to `open…`. The two examples that
are not tagged `<sampleInstance>` in `VectorCanvasExample` and the three in `TrueTypeExample` are
helpers; they stay as helpers. Each examples package gains a gate test class in its sibling
`-Tests` package, modelled on `VGCairoExamplesTest`, which runs every `<sampleInstance>` that does
not open a window. Gate: every example runs, and no gate runs a window example.

**P5 — the documentation gate.** `VectorGraphicsDocumentationTest` holds the package comment to the
package's tags and `doc/ARCHITECTURE.md` to the image, and it is written for one package. Make it
abstract with `packageUnderTest` as the subclass hook, and give it one concrete subclass per code
package. Write the four package comments, each with its own `Tags:` list, because the gate checks
that list names every tag and no tag that is absent. Re-section `doc/ARCHITECTURE.md` so each
package's part is findable, and update the package table of `README.md`. Gate: four green
documentation suites, and the per-concrete-class counts recorded, since the abstract parent makes
the package-level number lie.

**P6 — the table and the baseline.** Add the twelve entries of §4 to
`VGArchitectureTest class >> allowedDependencies`, change the `VectorGraphics-Cairo` entry, and
update `declarePackagesOn:` and `declareGroupsOn:`. Gate: the twenty-odd architecture tests pass,
which is what proves the stated edges are the real ones.

**P7 — the load proof.** In a fresh image, load each group on its own: `truetype` with no engine,
`engine` with no font code, `paths` alone, then `default`. Gate: four clean loads and the suite
green in the last one. This is the only phase that needs a second image, and it is the phase that
demonstrates the flexibility the split was for.

## 6. What this costs

Roughly 44 class moves, 26 test and fixture moves, six method moves, five new examples classes,
four package comments, five new or changed documentation classes, two baseline methods, one
architecture table and two documents. Two to three days of work at the project's usual pace, almost
all of it mechanical, with P2, P4 and P5 holding the real decisions.

## 7. Risks

- **The package name `VectorGraphics` disappears.** Any loader that names the package rather than a
  group breaks. The `core` group keeps groups working, and nothing outside this repository names the
  package today, but it is a one-way change for anyone who has.
- **Divergence from Cuis.** The package comment records that this code is a port of the Cuis
  `VectorEnginePlugin`. After the split a change from upstream has to be placed by hand across four
  packages. Worth saying in the comment of each new package.
- **Twelve packages for 71 classes** is a lot of ceremony, and three of the twelve hold fewer than
  six classes. §8 is the smaller version.
- **An abstract documentation `TestCase`** makes package-level test counts wrong, as the project has
  already been bitten by. P5's gate records per-class counts for that reason.
- **The Iceberg commit sweeps untracked files**; clean the checkout before each phase's commit, and
  commit the documents with git before committing code from the image.

## 8. The smaller alternative, if twelve packages is too many

Keep the name `VectorGraphics` for the engine and extract two packages only:

- `VectorGraphics` — the engine, the path commands and the SVG parser, with its tests and examples
  packages, 20 code classes.
- `VectorGraphics-TrueType` — the 22 font classes, with its tests and examples packages, depending
  on `VectorGraphics`.

Six packages instead of twelve, no glue package, no baseline break, and the TrueType reader still
becomes loadable with the Cairo stack and nothing else — because `VectorGraphics-Cairo` names only
the table parsers, the engine it drags in is dead weight rather than a dependency. What it does not
give is an engine that loads without the font code, or a TrueType reader that loads without the
engine.

## 9. P0 as recorded, 5 November 2026

Repository `VectorGraphics` at head `443fe8f9`, working copy clean, nothing committed for this phase.
Both runs were forked at priority 70 and wrote to `p0-baseline.txt` and `p0-critics.txt` in
`Smalltalk imageDirectory`.

### The suite, per concrete test class

Read per class, never per package: a package-level count double-counts the subclasses of an
abstract `TestCase`, and P5 makes the documentation test abstract. None of the 24 classes is
abstract today.

| Test class | Tests | Test class | Tests |
|---|---|---|---|
| `FontFamilyTest` | 9 | `TTFontTableDirEntryTest` | 8 |
| `FormGlyphTest` | 8 | `TTGlyphTest` | 11 |
| `Int16PointArrayTest` | 12 | `TTKernPairTest` | 5 |
| `PathCommandDispatchTest` | 16 | `TrueTypeFontFamilyTest` | 7 |
| `PathCommandParseTest` | 17 | `TrueTypeFontTest` | 16 |
| `PathCommandRunOnTest` | 9 | `VectorCanvasTest` | 11 |
| `PathMoveToCommandTest` | 4 | `VectorEngineAbstractTest` | 8 |
| `PathQuadraticCurveCommandTest` | 4 | `VectorEngineBoundsFinderTest` | 6 |
| `TTCompositeGlyphTest` | 10 | `VectorEnginePixelTest` | 3 |
| `TTContourConstructionTest` | 12 | `VectorEngineWholePixelTest` | 2 |
| `TTFontDescriptionTest` | 17 | `VectorGraphicsDocumentationTest` | 12 |
| `TTFontParserTest` | 24 | | |
| `TTFontReaderTest` | 6 | | |

**24 classes, 237 tests, 237 passed, 0 failures, 0 errors.**

Every later phase is held to that total. Splitting `VectorCanvasTest` and `TTFontDescriptionTest` in
P3 moves cases between classes but must not change the sum, and the examples gate classes P4 adds
are new tests counted on top, stated in the phase that adds them.

`TestSuite class >> forPackagesNamed:` does not exist in this image, which is another reason the
count is taken per class.

### Renraku, before the split

145 critiques over this package's own code — its 71 classes, their metaclasses, their methods, and
the 15 extension methods on base classes. The MCP `run_critics` call on the package answers 226
because it also reads the whole of `SmallInteger` and the other extended base classes; those
critiques belong to Pharo, not here, so this count is the one to compare against.

| Rule | Count | Rule | Count |
|---|---|---|---|
| `ReExcessiveArgumentsRule` | 30 | `ReJustSendsSuperRule` | 3 |
| `ReLongMethodsRule` | 27 | `ReExcessiveVariablesRule` | 3 |
| `ReTestClassNotInPackageWithTestEndingNameRule` | 24 | `ReUnclassifiedMethodsRule` | 2 |
| `ReCyclomaticComplexityRule` | 10 | `ReSubclassResponsibilityNotDefinedRule` | 2 |
| `ReInconsistentMethodClassificationRule` | 9 | `ReSentButNotUnderstoodBySuperRule` | 2 |
| `ReTempsReadBeforeWrittenRule` | 8 | `ReSendsDifferentSuperRule` | 2 |
| `ReRefersToClassRule` | 6 | six rules with one each | 6 |
| `ReSentNotImplementedRule` | 6 | | |
| `ReSelfSentNotImplementedRule` | 4 | | |

The 24 `ReTestClassNotInPackageWithTestEndingNameRule` critiques are exactly the 24 test classes and
P3 removes all of them, so the figure to expect at the end of the split is **121**, spread over the
new packages. The heaviest classes are `VectorEngineAbstract` (21), `VectorCanvas` (17),
`VectorEngineSubPixel` (14) and `VectorEnginePixel` (11); they are the engine's hop loop and its
blend stage, where the long methods and the argument counts are deliberate, and they all land in
`VectorGraphics-Engine`.

No critique is to be fixed as part of this split. A split that also fixes critiques cannot be read
in a diff, and the project rule applies: no image-code change without a real
bug behind it.

## 10. P1 as built, 5 November 2026

Done in the image only, **not committed**, by decision: P1 to P4 stay uncommitted until P5 rewrites
the documentation gate, so that history holds one green state. A crash before then is replayed from
Epicea. Nothing was pushed.

Three packages exist with their classes; `VectorGraphics-Text` is created in P2, because a package
holds nothing until its glue methods arrive.

| Package | Classes | Tags |
|---|---|---|
| `VectorGraphics-Paths` | 14 | `Commands` 12, `SVG` 2 |
| `VectorGraphics-Engine` | 6 | `Kernel` 6 |
| `VectorGraphics-TrueType` | 22 | `Reading` 12, `Glyphs` 6, `Fonts` 4 |

Classes moved with `(package ensureTag: name) addClass: aClass`; `Package >> addClass:` and
`moveClass:toTag:` exist as well. The old `VectorGraphics` package now holds the 24 test classes,
two fixtures, the two examples classes and the manifest, with tags `Tests`, `Examples`, `Manifest`.

### The 15 extension methods, placed by who sends them

Placed by reference scan, then re-protocolled to `*VectorGraphics-<Package>`:

- `VectorGraphics-Engine`, 7: `Bitmap >> byteAt:`, `byteAt:put:`, `bytesAt:`, `bytesAt:put:`;
  `WordArray >> bytesAt:`, `bytesAt:put:`; `SmallInteger >> digitAt:`.
- `VectorGraphics-TrueType`, 8: `ByteArray class >> newBits:`; `ByteArray >> bitAt:`,
  `bitAt:put:`, `bitAt:bitPosition:`, `bitAt:bitPosition:put:`, `bitBooleanAt:`;
  `Character class >> utf8BytesOf:`, `evaluate:withUtf8BytesOf:`.

The plan of §3 put the two `Character` methods in TrueType already. `evaluate:withUtf8BytesOf:` is
also sent from `VectorCanvas >> drawString:from:to:at:font:color:`, which is one of the glue
methods P2 moves into `VectorGraphics-Text`, so the Engine package ends P2 with no use of it.

### Gate

- 24 test classes, 237 tests, **235 passed, 2 failed**, 0 errors. Both reds are in
  `VectorGraphicsDocumentationTest`, both caused by the move and both P5's to fix:
  - `testThePackageCommentNamesNoTagThePackageDoesNotHave`: the comment still lists `Kernel`, which
    the old package no longer holds.
  - `testEveryNameTheArchitectureDocumentBackticksExists`: `doc/ARCHITECTURE.md` names the class
    variables `AvailableFamilies` and `Descriptions`, and the gate looks for class variables only in
    the classes of `packageUnderTest`, which is the old package.
- Every other test class passes unchanged, which is the evidence that a class move does not change
  a reference.
- Renraku on `VectorGraphics-Paths`: 7 critiques, all among the 145 of §9. On
  `VectorGraphics-TrueType` the MCP call also reads `Character` and `ByteArray` whole, as it did for
  `SmallInteger`, so its count is not comparable; the own-code count is taken at the end of the
  split, against 121.

## 11. P2 record — the glue, done

`VectorGraphics-Text` exists and holds six extension methods, no classes. Each carries a comment
naming the two packages it bridges and why it is in neither.

| Method | Was in | Why it is glue |
|---|---|---|
| `VectorCanvas >> drawString:from:to:at:font:color:` | Engine | names `FontFamily` for the default font |
| `VectorCanvas >> drawUtf8:at:font:color:` | Engine | same |
| `VectorEngineAbstract >> displayUtf8:at:trueTypeFont:color:scaleX:scaleY:` | Engine | walks the contour data of a `TTFontDescription` |
| `TTFontDescription >> formGlyphForUtf8Byte1:byte2:byte3:byte4:pixelSize:` | TrueType | rasterises a glyph on a `VectorCanvas` |
| `TrueTypeFont >> glyphAtUtf8Byte1:byte2:byte3:byte4:` | TrueType | its cache is filled by the method above |
| `TTGlyph >> inspectorGlyph` | TrueType | draws the glyph with the engine to show it |

### Two methods the first count missed, and how

§3 named four. The reference gate found a fifth and a send-level check found a sixth.

- `VectorEngineAbstract >> displayUtf8:at:trueTypeFont:color:scaleX:scaleY:` names
  `TTFontDescription` twice, both times on the class side
  (`isUtf8ContinuationByte:`, `unknownGlyphContourDataPosition`). The first count read the literals
  of `VectorCanvas` and missed the engine class behind it. With it still in Engine the gate failed:
  `VGArchitectureTest edgesOf: 'VectorGraphics-Engine'` answered
  `#('VectorGraphics-TrueType')`. This is the method that does the real text drawing, so
  `VectorGraphics-Engine` draws no text at all once it is gone — which is the point of the split,
  stated plainly.
- `TrueTypeFont >> glyphAtUtf8Byte1:byte2:byte3:byte4:` names no class of the other half, so no
  reference scan can see it, but it sends
  `formGlyphForUtf8Byte1:byte2:byte3:byte4:pixelSize:` to its own `ttFontDescription` instance
  variable. Had it stayed behind, `VectorGraphics-TrueType` loaded alone would answer that send
  with a doesNotUnderstand. Both methods carry the comment "Needed only for BitBltCanvasEngine",
  and the `Form` route they make up is exactly what needs the canvas, so they move together.

### The gate

`VGArchitectureTest class >> edgesOf:` reads the literals of every method of a package, including
the literals of nested blocks to any depth and the extension methods the package owns on other
packages' classes. Run over the four code packages after the move:

| Package | References |
|---|---|
| `VectorGraphics-Paths` | nothing |
| `VectorGraphics-Engine` | nothing |
| `VectorGraphics-TrueType` | `VectorGraphics-Paths` |
| `VectorGraphics-Text` | `VectorGraphics-Engine`, `VectorGraphics-TrueType` |

This is the target table of §4 exactly. The old `VectorGraphics` package, which still holds the
tests and examples, references all three code packages, as expected until P3 and P4.
`VectorGraphics-Cairo` still references `VectorGraphics-TrueType` and nothing else of the project,
which is the one line §4 changes in P6.

### The send-level check, and the one edge it leaves

A reference scan cannot see a send, so each package was also scanned for selectors that only the
other half implements:

- `VectorGraphics-Engine`: none.
- `VectorGraphics-TrueType`: none, once `glyphAtUtf8Byte1:byte2:byte3:byte4:` moved.
- `VectorGraphics-Paths`: nine selectors —  `multiLineTo:points:`, `multiLineTo:xs:`,
  `multiLineTo:ys:`, `multiMoveTo:points:`, `multiCurveTo:toPoints:control1Points:control2Points:`,
  `multiCurveToSmooth:toPoints:control2Points:`,
  `multiQuadraticCurveTo:toPoints:controlPoints:`, `multiQuadraticCurveToSmooth:toPoints:` and
  `multiArc:rs:xAxisRotations:toPoints:doLargerArcs:useIncreasingAngless:` — implemented only by
  `VectorCanvas`.

That last one is left alone deliberately. The receiver is the method's own argument
(`PathLineToCommand >> runOn: aCanvas` sends `aCanvas multiLineTo:points:`), so a path command runs
on anything that answers the drawing protocol and `VectorGraphics-Paths` loads and runs with no
engine present. The `glyphAtUtf8` case was different in kind: there the receiver was the object's
own instance variable, so the absent package meant a certain doesNotUnderstand rather than a choice
left to the caller. Reference edges and sends to an argument are not the same dependency, and only
the first belongs in the table.

### Suite and critics

237 tests over 24 concrete test classes, 235 passed, 2 failures — the same two documentation
failures P1 left, no new red:

- `VectorGraphicsDocumentationTest >> testEveryNameTheArchitectureDocumentBackticksExists`
- `VectorGraphicsDocumentationTest >> testThePackageCommentNamesNoTagThePackageDoesNotHave`

P5 owns both. Renraku on the six moved methods: 8 critiques, all of them the pre-existing
length, argument-count and cyclomatic-complexity complaints about bodies this phase did not touch,
unchanged from the P0 baseline. Nothing is committed; the first commit is P5, as agreed.

### Next

P3, the test packages.

## 12. P3 record — the test packages, done

Four `-Tests` packages exist. No code package holds a `TestCase` any more.

| Package | `Tests` tag | `Fixtures` tag |
|---|---|---|
| `VectorGraphics-Paths-Tests` | `PathCommandDispatchTest`, `PathCommandParseTest`, `PathMoveToCommandTest`, `PathQuadraticCurveCommandTest` | `MockNumberStream` |
| `VectorGraphics-Engine-Tests` | `VectorCanvasTest`, `VectorEngineAbstractTest`, `VectorEnginePixelTest`, `VectorEngineWholePixelTest`, `VectorEngineBoundsFinderTest`, `PathCommandRunOnTest` | `RecordingCanvas` |
| `VectorGraphics-TrueType-Tests` | the thirteen `TT…`, `TrueType…`, `FontFamily`, `FormGlyph` and `Int16PointArray` test classes | `RecordingFont` (new) |
| `VectorGraphics-Text-Tests` | `VGTextDrawingTest` (new) | — |

The old `VectorGraphics` package is down to four classes: `VectorGraphicsDocumentationTest`,
`VectorCanvasExample`, `TrueTypeExample` and `ManifestVectorGraphics`. The documentation test stays
there until P5, which is the phase that splits it into one concrete subclass per package.

### Where the text tests really were

§3 said the text cases would come out of `VectorCanvasTest` and `TTFontDescriptionTest`. They do
not. Read against the six glue methods, not one test of either class touches them:
`VectorCanvasTest` tests the engine's creation, measuring and path calls, and
`TTFontDescriptionTest` tests `computeGlyphLayoutForLeft:…`, the emphasis flags and the contour
data positions — all of which stay in their own package.

The two tests that do drive the glue were in `VectorEngineAbstractTest`:
`testAByteWithNoIndexEntryDrawsTheUnknownGlyph` and
`testAnUnmappedMultiByteCharacterDrawsOneUnknownGlyph`, both of which call
`displayUtf8:at:trueTypeFont:color:scaleX:scaleY:` through the helper `formAfterDrawingUtf8:`.
Those two tests and the six helpers they alone use — `formAfterDrawingUtf8:`,
`sparseFontDescription`, `glyphWithTriangleContour`, `fixtureEmBox`, `fixturePointSize` and
`paintedPixelCountIn:` — are now `VGTextDrawingTest` in `VectorGraphics-Text-Tests`.
`engineOnSmallForm`, which the other six tests of `VectorEngineAbstractTest` use, stayed behind.
So the cut was clean: no test method is shared between the two classes.

### The one fixture reference that had to go, and the test it was hiding

`RecordingCanvas` belongs to `VectorGraphics-Engine-Tests`, and
`FontFamilyTest >> testReleaseCachedStateDelegates` named it — an edge from
`VectorGraphics-TrueType-Tests` to `VectorGraphics-Engine-Tests` that §4 does not allow. The
reference was dead: the test put a `RecordingCanvas` into `baseFontBySizes`, then overwrote the
whole dictionary with an empty one before sending anything, so the double was never used and the
test's one assertion was `self assert: true`. It asserted nothing about delegation, which is what
its name claims.

Rather than delete the dead line and leave the name lying, the test now states the fact. A new
fixture `RecordingFont` in `VectorGraphics-TrueType-Tests` counts the `releaseCachedState` messages
it receives — the one message `FontFamily >> releaseCachedState` sends to each font it holds — and
the test denies `wasReleased` before the send and asserts it after, so the assertion has teeth
without a parsed font file. The degenerate case the old test actually covered is now its own test,
`testReleaseCachedStateWithNothingCachedDoesNotError`. That is the whole reason the test count goes
up by one.

`RecordingFont` carries no `<sampleInstance>` example and no inspector view, which follows the two
fixtures already in the project: `RecordingCanvas` and `MockNumberStream` have neither. A test
double is built by the test that needs it, and an example of one shows nothing a reader of the test
cannot see.

### The gate

`VGArchitectureTest edgesOf:` over the eight packages that now exist:

| Package | References |
|---|---|
| `VectorGraphics-Paths` | nothing |
| `VectorGraphics-Paths-Tests` | `VectorGraphics-Paths` |
| `VectorGraphics-Engine` | nothing |
| `VectorGraphics-Engine-Tests` | `VectorGraphics-Engine`, `VectorGraphics-Paths` |
| `VectorGraphics-TrueType` | `VectorGraphics-Paths` |
| `VectorGraphics-TrueType-Tests` | `VectorGraphics-Paths`, `VectorGraphics-TrueType` |
| `VectorGraphics-Text` | `VectorGraphics-Engine`, `VectorGraphics-TrueType` |
| `VectorGraphics-Text-Tests` | `VectorGraphics-Engine`, `VectorGraphics-TrueType` |

Two entries of §4 are wider than reality and P6 must narrow them, or
`testEveryAllowedDependencyIsOneThePackageReallyMakes` fails on an edge that is permitted but never
made:

- `VectorGraphics-TrueType-Tests` does not name `VectorGraphics-Engine`. Drop it.
- `VectorGraphics-Text-Tests` cannot name `VectorGraphics-Text`, because that package defines no
  class — only extension methods on classes of the other two packages. The entry has to be
  `#( 'VectorGraphics-Engine' 'VectorGraphics-TrueType' 'VectorGraphics-Text-Examples' )`, and the
  same holds for the `-Examples` entry. A glue package of pure extension methods is invisible to a
  reference scan from above, which is worth stating in `doc/ARCHITECTURE.md` in P5.

### Suite and critics

238 tests over 25 concrete test classes, 236 passed, the same two documentation failures P1 and P2
left. The count is 237 + 1, the new degenerate-case test described above; no test was lost in the
moves.

Renraku on everything P3 wrote — `RecordingFont`, `VGTextDrawingTest`, both `FontFamilyTest`
methods — is clean at 0 critiques. The first compile of `RecordingFont` went through
`compile:classified:` from `evaluate_pharo` and planted LF line endings in all four methods, which
`[lf] Method source contains linefeeds` caught; recompiling through `compile_method`, which
normalises them, cleared it. The pre-existing critiques of `VectorEngineAbstractTest` ("temporaries
may be read before written") and `FontFamilyTest` (`super setUp`, `super tearDown`) are untouched
and count against the P0 baseline as before.

Twenty-one of the test classes still have an empty class comment, which the P0 baseline already
held. P5 owns package comments; the class comments are not in any phase of this plan and should be
logged separately.

Nothing is committed. The first commit is P5, as agreed.


## 13. P4 record — the examples packages, done

Four packages created, each with an `Examples` tag: `VectorGraphics-Paths-Examples`,
`VectorGraphics-Engine-Examples`, `VectorGraphics-TrueType-Examples` and
`VectorGraphics-Text-Examples`. Five holder classes hold 35 `<sampleInstance>` examples between
them, every one class-side, argument-free and carrying its own class comment.

| Examples class | Package | Examples | Helpers |
|---|---|---|---|
| `VectorCanvasExamples` | `VectorGraphics-Engine-Examples` | 17 | `newForm`, `newCanvasOn:` |
| `PathCommandExamples` | `VectorGraphics-Paths-Examples` | 5 | 2 |
| `SVGPathExamples` | `VectorGraphics-Paths-Examples` | 3 | 2 |
| `TrueTypeExamples` | `VectorGraphics-TrueType-Examples` | 4 | `defaultFontPath`, `loadFontFrom:`, `newContourFromAbsolutePoints:` |
| `TextDrawingExamples` | `VectorGraphics-Text-Examples` | 6 | 4 |

`VectorCanvasExample` and `TrueTypeExample` are gone, removed with `removeFromSystem` after the two
senders of their selectors — `VectorGraphicsDocumentationTest >> viewSubjects` — were rewired to
the new holders. The `example` prefix was dropped from every moved selector, so
`exampleGlyphMap` is now `TrueTypeExamples class >> glyphMap`. No example of this layer opens a
window, so no `open…` selector was needed; the rule is still gated, see below.

### Helpers are duplicated on purpose

`TextDrawingExamples` holds its own copies of `newForm`, `newCanvasOn:`, `defaultFontPath` and
`loadFontFrom:` rather than sending them to `VectorCanvasExamples` and `TrueTypeExamples`. A
cross-package send would make `VectorGraphics-Text-Examples` depend on two other examples packages,
which is the opposite of what the split is for: a package must load with only the packages its own
dependency-table row names. Four short helper methods is the price of that independence. The
alternative, a shared `VectorGraphics-Examples-Support` package, costs a thirteenth package to
hold four methods and was not taken.

### The gate, four times over

Each `-Tests` package gained one gate class modelled on `VGCairoExamplesTest`:
`VGEngineExamplesTest`, `VGPathsExamplesTest`, `VGTrueTypeExamplesTest` and `VGTextExamplesTest`.
Each has a class comment, its own `exampleHolders`, a class-side `windowExamplePrefix` answering
`'open'`, and the same five tests:

| Test | What it holds |
|---|---|
| `testEveryExampleRunsAndAnswersSomething` | every gated example runs and answers non-nil |
| `testEveryExampleRebuildsItsObject` | two calls answer two objects, so an inspection shows no leftover state; a class answering itself is exempt |
| `testEveryExampleTakesNoArgumentAndIsOnTheClassSide` | one click runs it from the browser |
| `testEveryExampleHolderHasAComment` | a holder read from the browser says what it shows |
| `testAnExampleThatOpensAWindowIsNamedForItAndNoGateRunsIt` | the window rule, read from `windowExamplePrefix` rather than restated, and the two sets add up to the whole |

The window test is the one that keeps the gate honest while no window example exists: it asserts the
prefix set and the gated set are disjoint and together are all of `allExampleMethods`, so an
example added later is either run or named `open…`, never silently skipped.

The nine shared methods were compiled once on `VGEngineExamplesTest` through `compile_method`, then
copied to the other three in one `evaluate_pharo` by reading `sourceCode` and `protocol name` from
the compiled methods. That route matters: the image and the agent's shell share no filesystem — the
image's `Smalltalk imageDirectory` is under `/home/renaud`, and neither the scratchpad nor
`/home/me/workspace` exists for it — so there is no file to compile from, and `compile:classified:`
with a source string typed into `evaluate_pharo` plants LF line endings. Copying an
already-compiled `sourceCode` carries the CR endings `compile_method` normalised.

### Suite and critics

258 tests over 29 concrete test classes in the split's own scope — the four `-Tests` packages plus
what is left of `VectorGraphics` — and 254 pass. That is P3's 238 plus the 20 new gate tests, which
is 258, so no test was lost. All 35 examples run; all four gates are green.

The four red tests are all `VectorGraphicsDocumentationTest`, and P5 owns every one:

| Test | Why it is red |
|---|---|
| `testEveryNameTheArchitectureDocumentBackticksExists` | `AvailableFamilies` and `Descriptions` are named by `doc/ARCHITECTURE.md` and absent from the image — red since P1 |
| `testThePackageCommentNamesNoTagThePackageDoesNotHave` | the comment names `Kernel`, which is no longer a tag of `VectorGraphics` — red since P1 |
| `testEveryMethodTheArchitectureDocumentNamesIsImplementedByThatClass` | the document still names the five old `VectorCanvasExample`/`TrueTypeExample` selectors — new in P4, and exactly the drift P5's re-sectioning fixes |
| `testEverySampleInstanceOfThisPackageRuns` | "This package holds no example" — true and correct: every example moved out of `VectorGraphics`. In P5 this test belongs to each code package's concrete subclass, reading that package's own examples package |

Renraku over everything P4 wrote — the five holder classes, the four gate classes, their metaclasses
and all their methods — is **0 critiques**. Two things had to be fixed to get there:
`defaultTimeLimit` was classified `tests` and `ReInconsistentMethodClassificationRule` wants
`accessing`, which is where `VGCairoExamplesTest` keeps it; and `VGPathsExamplesTest >>
exampleHolders` had been compiled through `compile:classified:` and carried LF, which
`ReMethodSourceContainsLinefeedsRule` caught. Both are the same two traps P3 recorded.

### One failure outside the scope, not ours

A whole-project run (72 classes, 918 tests) was taken first and showed 29 red, all in packages this
split does not touch: the architecture table P6 owns, and the Cairo, Bloc, Alexandrie and Vulkan
suites that need a live FreeType handle or a device this long-running image no longer has.
`VGBlocExamplesTest` fails on `spaceDrawnIntoAPixelBuffer` answering nil, which is that dead handle,
not a P4 effect. Only the 258-test scope above is the gate for this phase.

Nothing is committed at the time of writing. The image then crashed, P1 to P4 were replayed from
Epicea, and the restored work was committed as `aa690a3` on the user's instruction, before P5
rather than with it. See section 14.

### Next

P5, the documentation gate.

## 14. P5 record — the documentation gate, done

`VectorGraphicsDocumentationTest` is now abstract and has one concrete subclass per code package.
Every documentation fact it held for one package is held for four, and the four package comments it
reads were written.

### The crash and the first commit

P1 to P4 were never committed when the image died. All four phases were replayed from the dead
session's Epicea log — the recipe and the trap that cost two attempts are in
`~/.claude/projects/-home-me/memory/reference_iceberg_dirty_after_crash.md` — verified against disk
in both directions, and committed as `aa690a3` on `main` before P5 began, not after it. Not pushed.

### The hierarchy

| Class | Package | Names |
|---|---|---|
| `VectorGraphicsDocumentationTest` | `VectorGraphics-Tests` | abstract: every test, every helper |
| `VGEngineDocumentationTest` | `VectorGraphics-Engine-Tests` | `VectorGraphics-Engine`, four view subjects |
| `VGPathsDocumentationTest` | `VectorGraphics-Paths-Tests` | `VectorGraphics-Paths`, no view subject |
| `VGTrueTypeDocumentationTest` | `VectorGraphics-TrueType-Tests` | `VectorGraphics-TrueType`, two view subjects |
| `VGTextDocumentationTest` | `VectorGraphics-Text-Tests` | `VectorGraphics-Text`, no view subject |

A subclass states two things and inherits thirteen tests: `packageUnderTest` on the class side, and
`viewSubjects` when its classes have inspector views. Three hooks made that possible:

- `packageUnderTest` moved to the class side, so the whole hierarchy can be asked which packages
  are documented without building an instance. The instance method delegates to it.
- `examplesPackageUnderTest` answers `packageUnderTest name , '-Examples'`, which is where P4 moved
  every example. `testEverySampleInstanceOfThisPackageRuns` reads that package, and it is strict:
  a code package with no examples package is a hole, not a pass.
- `documentedPackages` and `concreteGates` walk the hierarchy from its abstract root instead of
  listing it, so `architectureDocumentMayName:` sees the class variables of all four packages. That
  is what makes `AvailableFamilies` and `Descriptions` legal names again: both are class variables,
  of `FontFamily` and `TTFontDescription`, which now live in `VectorGraphics-TrueType` and so were
  invisible to a gate scoped to one package.

`isAbstract` answers `true` on the parent and `false` on each subclass, rather than comparing with a
class literal: `ReRefersToClassRule` catches the literal, and the walk in `concreteGates` would
have needed the name too. One new test, `testTheGateHierarchyFindsEveryDocumentedPackage`, holds
the walk: it was written first, failed with `#concreteGates` not understood, and passes now.

### The thirteenth package

`VectorGraphics-Tests` was not in the plan. The abstract parent cannot stay in `VectorGraphics`:
`ReTestClassNotInPackageWithTestEndingNameRule` wants a test class in a package whose name ends in
`-Tests`, and four `-Tests` packages depending on a code package for their test parent is the
dependency the split exists to remove. So the parent moved, and `VectorGraphics` now holds nothing
but its manifest — the front page of the project in the browser, and the name the baseline and the
repository are called by. P6 must decide whether an empty code package stays in the `core` group.

### The five package comments

Each comment names the ways into its package, its real tags one tag a line, and the sections of
`doc/ARCHITECTURE.md` that describe it. The tag list is what the gate reads, and two traps were
paid for:

- **Writing the comment creates the tag.** `packageComment:` installs a manifest class, which gives
  the package a `Manifest` tag it did not have, and the gate then fails on a tag the comment does
  not name. Every comment names `Manifest`.
- **A tag entry must be one line.** The reader stops at the first line under `Tags:` that is
  neither a `- `Name`` line nor blank, so a wrapped entry hides every tag below it.

`VectorGraphics-Text` has no tag but `Manifest`: all six of its methods are extensions of classes
of other packages, and Pharo files an extension method under the package itself.

`VectorGraphics` and `VectorGraphics-Tests` have comments but no gate, since no concrete subclass
names them. That is the one hole P5 leaves; it is cheap to fill if either comment ever drifts.

### The document and the README

`doc/ARCHITECTURE.md` is 283 lines. Its thirteen section headings each name the package they
describe, the paragraph that claimed everything was in one package is now a map from package to
sections, and section 13's table names the new example holders —
`VectorCanvasExamples class >> engineDuringAFillPath` and the four others, with the `example`
prefix gone. The closing paragraph names the four concrete gates. `README.md` lists the five new
packages, the four new examples packages and the five new test packages in its package table; its
group table is untouched, because the baseline still declares the old groups. P6 owns that.

### Gate

| Suite | Tests | Result |
|---|---|---|
| `VGEngineDocumentationTest` | 13 | green |
| `VGPathsDocumentationTest` | 13 | green |
| `VGTrueTypeDocumentationTest` | 13 | green |
| `VGTextDocumentationTest` | 13 | green |
| `VectorGraphics-Engine-Tests` | 55 | green |
| `VectorGraphics-Paths-Tests` | 59 | green |
| `VectorGraphics-TrueType-Tests` | 164 | green |
| `VectorGraphics-Text-Tests` | 20 | green |

298 distinct tests in the split's scope, all passing: P4's 258, plus 40 for the four subclasses
after the single parent's 12 stopped counting, plus the four copies of the one new hierarchy test.
The package-level number lies exactly as the plan warned: `VectorGraphics-Tests` holds one abstract
class and runs 52 tests, because Pharo builds the suite from the concrete subclasses, each of which
is counted again in its own package. Ask per concrete class when the number matters.

Renraku over the parent, the four subclasses, their metaclasses and `VectorGraphics-Tests` is
**0 critiques**.

No example and no inspector view was written for the five gate classes, as in P4: a test of a test
is the test itself, and an example of a gate would be the gate running.

### Next

P6, the dependency table and the baseline. Note two things P5 changed for it: the four `-Tests`
packages now depend on `VectorGraphics-Tests`, not on `VectorGraphics`, and `VectorGraphics-Tests`
depends on nothing, since the parent names no class of any code package — only
`PackageOrganizer` and the packages its subclasses name.

### Addendum — an inspector view takes the presenter builder

Reported after P5: `inspectorGlyphMap` and `inspectorContours` were dead in the browser with
*"Inspections made without presenter builder are no longer supported. Please rewrite your
inspection using it"*. `StInspectionContext >> basicNewInspectionPresenter:` signals that Warning
and answers nil when `methodSelectorNeedsBuilder` is false, and that predicate is just
`self methodSelector last = $:`. Eight views of the rasteriser — the four of
`VectorGraphics-Engine`, three of `VectorGraphics-TrueType` and `TTGlyph >> inspectorGlyph` of
`VectorGraphics-Text` — were written in the old style, instantiating `SpTablePresenter`,
`SpTextPresenter` and `SpImagePresenter` themselves. Every view of the Cairo, Bloc and Vulkan
packages already took a builder; the eight were the oldest code in the project, the Cuis port.

All eight now read `inspectorFoo: aBuilder` and build through `aBuilder newTable`, `aBuilder newText`
and `aBuilder newImage`. `doc/ARCHITECTURE.md` section 13 names the keyword selectors. Four stale
example names in those method comments — `VectorCanvasExample class >> exampleEngineDuringAFillPath`
and friends, renamed in P4 — were corrected in the same edit.

Two gate changes, both written before the fix and both seen to fail first:

- `testEveryInspectorViewOfThisPackageTakesAPresenterBuilder` reads the package's own methods, so an
  extension method on another package's class is read too, and asks
  `StInspectionContext >> methodSelectorNeedsBuilder` rather than restating the rule.
- `buildView:of:` no longer performs the selector with no argument. It builds through
  `StInspectionContext >> basicNewInspectionPresenter:`, which is what the inspector itself calls,
  so a view this gate passes is a view a reader can open. `newInspectionPresenterOnApplication:`
  is deliberately not used: it catches every error and answers a debug presenter, which would make
  the gate pass on a broken view.

Both were proved against a planted zero-argument view on `PathCommandError`: the test named it, and
`buildView:of:` raised the Warning. The planted method was removed.

An image-wide scan leaves no zero-argument view in any package of this project. The ones that
remain are Pharo's own — `CTArray2D`, `MicElement`, `IceNode` and four others — and are not ours to
edit.

302 tests in the split's scope, all green: Engine-Tests 56, Paths-Tests 60, TrueType-Tests 165,
Text-Tests 21, 14 per documentation subclass. No new critique on any method touched.

## 15. P6 record — the table and the baseline, done

Committed as `bad9b02` on `main`, working tree clean, not pushed. The image was saved after the
commit.

### What the split had left unguarded

`VGArchitectureTest class >> allowedDependencies` covered nine packages. The image held
twenty-three: the twelve packages of the rasteriser and `VectorGraphics-Tests` had no entry, and
`assertEdgesOfPackageNamed:` grants nothing for a package absent from the table *and is never run
for it*, so every reference those thirteen made was agreed by nobody. Three tests were red before
any edit — the coverage meta test, the Cairo entry, and the stale `VectorGraphics` edge — which is
what P6 came to fix.

### The edges, measured rather than predicted

The table is now read off `edgesOf:`, which reads the literals of a package's own methods, blocks
included. Three entries differ from the prediction in §4:

| §4 predicted | measured | why |
|---|---|---|
| `TrueType-Tests` names `Engine` | names `Paths` | a font is parsed and measured with no rasteriser; the glyph comes back as path commands |
| `Text-Tests` names `Text` | does not | `VectorGraphics-Text` holds six extension methods and no class, so nothing can name it |
| `Text-Examples` names `Text` | does not | same reason |

So `VectorGraphics-Text` is a package with no incoming edge at all, and both the P3 narrowings
hold. The one changed entry is `'VectorGraphics-Cairo' -> #( 'VectorGraphics-TrueType' )`: the Cairo
backend names the font reader and nothing else of the four, which is why `cairo`, `cairo-examples`
and `cairo-tests` no longer bring the whole rasteriser — stated in the group test rather than left
to be discovered.

Thirteen new per-package tests, one line each, and the old `testTheEngineStaysInsideIts…` renamed to
`testTheFrontPagePackageStaysInsideIts…`, since `VectorGraphics` is no longer the engine but a
package comment with no code.

### Two defects the new gates found

Both were written first and seen to fail.

- **`testNoClassOfThisProjectInheritsFromAnObsoleteClass`.** `TrueTypeFontFamily` was a subclass of
  `AnObsoleteFontFamily`. The crash recovery of P5 reloaded `FontFamily` from its `.class.st`, which
  installed a *new* class and left the subclass pointing at the dead copy — same name, same seven
  methods, same two instance variables, so nothing failed and the browser looked right. The live
  `FontFamily` had no subclasses and a method added to it would never have reached
  `TrueTypeFontFamily`. Fixed by reinstalling the class under `FontFamily`; comment, methods,
  package and tag survived. The gate walks `allSuperclasses` of every class of every project
  package, so it also covers the next class moved between packages.
- **`testEveryPackageOfThisProjectIsScannedByOneOfMyTests`.** Being in the table is not being
  scanned. This reads the package name out of the string literals of every test that sends
  `assertEdgesOfPackageNamed:`, so the two can no longer drift. Proved by removing
  `testTextStaysInsideItsAllowedDependencies` and watching it fail, then recompiling it.

### The baseline

Four edges the baseline must declare and the table must not: the four documentation gates subclass
`VectorGraphicsDocumentationTest`, and `VectorGraphics-Text-Tests` and `-Text-Examples` exercise the
glue of `VectorGraphics-Text`. None is a reference a method makes, so `edgesOf:` cannot see them and
`testEveryAllowedDependencyIsOneThePackageReallyMakes` would reject them in the table. Left out of
the baseline, the group loads and the suite then fails on a missing superclass or a missing method.
Both methods now say so in their comments.

`declarePackagesOn:` is replaced by `declareRasteriserPackagesOn:` and
`declareBackendPackagesOn:` — twenty-three packages in one method raised
`ReCyclomaticComplexityRule` and `ReLongMethodsRule`, and the split is along the seam the project
already has. `baseline:` calls four methods instead of three. All five live in the `baselines`
protocol, which `ReInstanceSideBaselineMethodProtocolRule` asks for and the old `baseline` protocol
failed.

Groups: `paths`, `engine`, `truetype`, `text`, each with `-examples` and `-tests`, and `core` is
their union plus the front page. `bloc` and `vulkan` now name `core` explicitly, because before the
split the whole rasteriser arrived through the Cairo backend's requires and a backend must keep
bringing it. `default` is `core` and `cairo` as before, so every existing loader is unaffected;
`examples` and `tests` are the union of seven layer groups instead of three.
`VectorGraphics-Tests` needs no group: every `-tests` package requires it.

### Documents

- `doc/ARCHITECTURE.md` claimed `VectorGraphics-Engine`, `VectorGraphics-Paths` and
  `VectorGraphics-TrueType` "each depend on nothing but the image". That was never true of the font
  reader, which depends on `VectorGraphics-Paths`. Corrected, and the paragraph now points at
  `allowedDependencies` as the statement of record.
- `README.md` gains the twelve new groups and says what each really loads, including that `cairo`
  brings `paths` and `truetype` and not the whole of `core`, and that `cairo-tests` brings five
  packages rather than four.

### Gate

| Suite | Tests | Result |
|---|---|---|
| `VGArchitectureTest` | 39 | green |
| the four rasteriser `-Tests` packages | 302 | green |
| the four documentation subclasses | 56 | green |
| `VGBackendSelectionTest` and four Cairo unit suites | 51 | green |

Critics: clean on `VGArchitectureTest` and on `BaselineOfVectorGraphics`. One pre-existing critique
stands on `TrueTypeFontFamily class >> readAllTrueTypeFontsIn:` (`ReRefersToClassRule`, names itself
instead of `self`); it is not P6's and no bug has been seen behind it.

Not run: the long Cairo drawing, text, stroke, surface and conformance suites. They exceed the MCP
call timeout in this image and the Cairo layer's only P6 change is its one table entry, which the
architecture suite holds.

### Next

P7, the load proof in a fresh image: `paths` alone, `truetype` with no engine, `engine` with no font
code, then `default`, and the suite green in the last one. Two things P6 changed for it — `cairo`
loads neither the engine nor the text glue, so a fresh image taking `cairo-tests` must be checked
for a reference to either; and the four `-tests` groups each pull `VectorGraphics-Tests`, which is
the first time that package is loaded anywhere but this image.

## 16. P7 — the load proof, handed to the machine

P7 cannot run here: a Metacello load wants a fresh image, and this VM has one image, the
development one, where every package is present already. The instructions are written out instead,
in `P7-LOAD-PROOF.md`, for the user to run on a real machine.

Six steps, each in its own blank Pharo 13 image, loading
`github://rvillemeur/VectorGraphics:main/src` — `main` is pushed and `git ls-remote` answers
`152cd8c`, the commit the steps expect. Per step: the expected package set, measured here from the baseline's own groups; an
absence list, which is what the step really proves; and one snippet that does real work with only
that group loaded.

| Step | Group | Expected packages | What the absence proves |
|---|---|---|---|
| 1 | `paths` | Paths | the path layer needs neither engine nor font code |
| 2 | `truetype` | Paths, TrueType | a font reads with no rasteriser; the glyph-to-`Form` glue is absent |
| 3 | `engine` | Engine | the rasteriser fills a path with no font code, and cannot draw a string |
| 4 | `default` | VectorGraphics + the four layers + Cairo | no Bloc, no Alexandrie |
| 5 | `cairo` | Cairo, Paths, TrueType | the Cairo backend names the font reader only |
| 6 | the four `-tests` | the four layers, Tests, four `-Examples`, four `-Tests` | 302 tests green outside this image |

Three facts were settled before writing the steps, each by measurement in this image:

- **The snippets run.** `SVGPathParser parse:` answers 3 commands; `TTFontReader readTTFFrom:` on a
  real `.ttf` answers a `TTFontDescription` (`'Adwaita Mono' -> 1000` here) and takes a `ByteArray`,
  not a stream; the triangle fill goes through `fillColor:do:` with `moveToX:y:` and `lineToX:y:`,
  and the pixels are read from the `Form` handed to `onForm:` — `VectorCanvas` does not answer
  `form`, which is a `subclassResponsibility` on `Canvas`.
- **The document gates skip.** `architectureDocumentFile` answers nil with no `IceRepository` named
  `VectorGraphics`, so `skipTheDocumentIsAbsent` fires and the gates that read `doc/ARCHITECTURE.md`
  are skips, not failures, in a loaded image.
- **One gate can run alone.** `testTheGateHierarchyFindsEveryDocumentedPackage` asserted
  `documentedPackages size > 1`, which a one-group load makes false. Rewritten to state the facts
  that hold for any subset — one gate per documented package, this gate among them, its own package
  among them, no nil, no duplicate, no abstract — and committed as `152cd8c`.

The suite counts to compare against: 60 Paths, 56 Engine, 165 TrueType, 21 Text.

### Next

P7's result comes back from the machine. A package in the loaded image that the table does not
expect is a missing narrowing in `declareRasteriserPackagesOn:` or `declareBackendPackagesOn:`; a
load error naming a class is a missing `requires:`. Both are reproducible here as a red
architecture test, which is where the fix belongs.

## 17. P7 record — the load proof passed

Run by the user on a real machine, 2026-11-06, loading
`github://rvillemeur/VectorGraphics:main/src` at `152cd8c`. Every group loaded the packages the
table expects and every test passed. The split is proved outside the image that built it.

Three things the run settled that this VM could not:

- **Each layer loads alone.** `paths`, `truetype` and `engine` each arrive without the packages
  they do not name, so the three-way separation is real and not an artefact of the development
  image holding everything.
- **The baseline narrowings are right.** No step loaded a package the measured expectation did not
  list, so no `requires:` in `declareRasteriserPackagesOn:` or `declareBackendPackagesOn:` is wider
  than the dependency table.
- **The package-comment gates survive a Tonel load.** This was the one open risk in the step 6
  note: a package comment does arrive with the package file, so those gates need no skip.

P0–P7 are complete. The twelve-package split is done, loadable group by group, and held by
`VGArchitectureTest class >> allowedDependencies` plus the two baseline declaration methods — a new
dependency means an entry in both, in the commit that needs it.

### Next

Nothing is outstanding in this plan. Carried work elsewhere: unit 7.3 of
`VECTORCANVAS-PRESENT-PLAN.md`, paused by the user; `doc/DEFECTS.md` U0–U9, deprioritised; the 21
test classes with empty class comments, which no phase owns; and the long Cairo drawing, text,
stroke, surface and conformance suites, which exceed the MCP call timeout and so have never run in
the development image.
