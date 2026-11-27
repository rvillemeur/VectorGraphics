# Documenting the Bloc font-engine replacement

This is the decided plan, settled in the design interview of 25 November 2026. It supersedes the
first draft of this document, which proposed one library and a static view of the route.

The subject is the route by which text in a Bloc window is drawn by our own code instead of by
FreeType and Cairo's toy font API: `VGFontEngine install` and everything it puts in the way of a
glyph. The code works and every class carries a comment, yet the project reads as obscure, because
nothing in it shows *which object holds which* and *what happens in what order*. Those two
questions get one artefact each, and both artefacts are generated from the code rather than written
beside it.

## 1. The route

| Package | Classes | Part in the route |
|---|---|---|
| `VectorGraphics-Canvas-Fonts` | 12 | The font objects proper: face, scaled font, options, glyph, atlas, mask, extents. |
| `VectorGraphics-TrueType` | 47 | Reads an sfnt file: tables, character map, glyph outlines, CFF charstrings, the catalogue of installed families. |
| `VectorGraphics-Bloc-Text` | 8 | The Bloc and Alexandrie side: canvas, renderer, offscreen, text context, the Cairo adapter, the font manager. |
| `VectorGraphics-Bloc-FontEngine` | 1 | `VGFontEngine`, which writes the two image slots and takes them back. |

`VGFontEngine install` writes exactly two slots: `AeFontManager globalInstance`, which becomes a
`VGFontManager` reading the machine's fonts through our own sfnt reader and no FreeType at all, and
`BlHostRenderer class >> preferableClass`, which becomes `VGAeRenderer`, whose canvas builds a
`VGAeTextContext` that asks the posed font for its `VGAeTextFont` adapter instead of marshalling a
`cairo_scaled_font_t`.

## 2. What already exists, and what is missing

Already in the image: a class comment on every class of the route; 15 `<sampleInstance>` examples in
`VectorGraphics-Bloc-Text-Examples` over four holder classes, among them
`managerReadyToDrawDefaultText` and `textFontWithAWarmCairoMaskAtlas`; inspector views on
`VGFontEngine class`, `VGScaledFont`, `VGFontManager`, `VGAeTextFont`, `VGFontFace` and
`VGGlyphAtlas`; and package-level layering already enforced by the 77 tests of
`VGArchitectureTest`, whose `allowedDependencies` table states what may reach what.

Missing, and therefore the whole of this plan: not one relation is declared, so no diagram can be
generated and nothing fails when a holding stops being true; there is no view of a live object's
graph; there is no artefact at all that shows the order of the hand-offs; and the two Bloc packages
have no manifest.

## 3. Decisions

1. **ArchDoc** — structure — is its own checkout at
   `/home/me/workspace/iceberg/rvillemeur/ArchDoc`, registered in Iceberg, no remote for now.
2. **AlgoTrace** — order — is a second checkout on the same terms.
3. The generated views live **in VectorGraphics**, in a new package `VectorGraphics-Documentation`,
   and the project's own agreement is extended in the same commit that adds it.
4. The renderer is **Roassal**, in `ArchDoc-Roassal`, shown through `aBuilder newRoassal`.
5. A relation is declared by a **pragma on the accessor** that reads the instance variable. For a
   class that deliberately exposes no accessor — only `VGFontFace`, which hides `glyphSource`,
   `metadata` and `outlines` behind `familyName`, `styleName` and `outlineOfGlyphAt:` — the
   declarations go in a **class-side `archRelations` table**. No instance variable is given a new
   public accessor for the sake of documentation.
6. A lazily built holding is declared with its own kind, `<archCache: #one to: #Target>`, and drawn
   in a distinct edge style. The five are `VGScaledFont >> fontExtents`, `>> outlines`,
   `>> aeTextFont`, `VGFontFace >> outlines` and `VGAeTextFont >> cairoMaskAtlas`.
7. `VectorGraphics-TrueType` is documented **whole**, 47 classes, with its own diagram, leaning on
   the `ManifestVectorGraphicsTrueType` that already exists.
8. The order of the hand-offs is **traced from a real run**. The trace is captured by **MetaLink**
   from the documentation package, on a declared list of methods, uninstalled in an `ensure:` block.
   No production method is instrumented, and the recording therefore crosses into `Bloc` and
   `Alexandrie`, which the standing rules forbid us to edit. The recorded trace is kept as a
   fixture, so a reader never instruments anything.
9. The enforcement tests live in a new package `VectorGraphics-Documentation-Tests`, in
   `VGFontArchitectureTest`. `VGArchitectureTest` gains only the dependency rows and the new project
   names; package layering stays its subject, object-level holdings become the new class's.
10. The architecture itself is written in the **manifest class comments**, in Microdown, in the
    image. `doc/ARCHITECTURE.md` and `README.md` get pointers of a few lines, never a second copy.
11. The work is cut into **two slices**. Slice one is judged before slice two starts.

## 4. The two libraries

### ArchDoc

| Package | Holds |
|---|---|
| `ArchDoc-Core` | `ArchDocRelation`, `ArchDocEdge`, `ArchDocGraph`, `ArchDocModel`, `ArchDocObjectGraph`, `ArchDocChecker`, `ArchDocDependencies`. No UI dependency. |
| `ArchDoc-Roassal` | The class-diagram and object-graph renderers. |
| `ArchDoc-Examples` | One `<sampleInstance>` example per class. |
| `ArchDoc-Tests` | The suite. |

`ArchDocModel` reads the declarations of a package — pragmas and class-side tables alike — and
infers the undeclared edges from static references, so the diagram distinguishes a declared holding
from a mere use. `ArchDocChecker` answers `unresolvedRelations`, `missingOpposites`,
`sampleInstanceViolations` and `forbiddenDependencies`; an architecture test is a test over those
four answers.

### AlgoTrace

| Package | Holds |
|---|---|
| `AlgoTrace-Core` | `AlgoTrace`, `AlgoStep`, `AlgoPhase`, the null and recording tracers, and `AlgoMetaLinkRecorder`. No UI dependency. |
| `AlgoTrace-Inspector` | The Spec views on a trace and on a step. |
| `AlgoTrace-Examples` | One `<sampleInstance>` example per class. |
| `AlgoTrace-Tests` | The suite. |

`AlgoMetaLinkRecorder` is the addition the algorithm-explainer skill does not describe: it takes a
list of methods, installs a `MetaLink` on each that records a step into the current trace, runs a
block, and removes every link in an `ensure:`, whether the block answered or raised.

## 5. The relations of slice one

Twelve classes of `VectorGraphics-Canvas-Fonts`, seventeen declarations. *Certain* means the class
comment or the code states the holding outright; *external* means the target is not ours.

| Holder | Accessor | Kind | Target | Note |
|---|---|---|---|---|
| `VGScaledFont` | `fontFace` | one | `VGFontFace` | certain |
| `VGScaledFont` | `options` | one | `VGFontOptions` | certain |
| `VGScaledFont` | `atlas` | one | `VGGlyphAtlas` | certain |
| `VGScaledFont` | `fontExtents` | cache one | `VGFontExtents` | memoised, immutable font |
| `VGScaledFont` | `outlines` | cache many | `VGGlyphOutline` | per-glyph cache |
| `VGScaledFont` | `aeTextFont` | cache one | `VGAeTextFont` | lazy adapter, opposite `scaledFont` |
| `VGFontOptions` | `antialias` | one | `VGCairoAntialias` | certain |
| `VGFontOptions` | `hintStyle` | one | `VGCairoHintStyle` | certain |
| `VGFontOptions` | `hintMetrics` | one | `VGCairoHintMetrics` | certain |
| `VGFontOptions` | `subpixelOrder` | one | `VGCairoSubpixelOrder` | certain |
| `VGGlyphAtlas` | `masks` | many | `VGGlyphMask` | certain |
| `VGGlyphMask` | `surface` | one | `AeCairoImageSurface` | certain, external |
| `VGFontFace` | `glyphSource` | one | `TTGlyphSource` | class-side table, no accessor |
| `VGFontFace` | `metadata` | one | `TTFontMetadata` | class-side table, no accessor |
| `VGFontFace` | `outlines` | cache many | `VGGlyphOutline` | class-side table, no accessor |
| `VGFontFace class` | `defaultFace` | cache one | `VGFontFace` | lazily built, kept for the session |
| `VGAeTextFont` | `cairoMaskAtlas` | cache one | `VGGlyphAtlas` | the *second* atlas; Cairo's masks are not ours |

Two rows of the first draft were wrong and are corrected here: `cairoMaskAtlas` holds one
`VGGlyphAtlas`, not a collection of masks, and `VGGlyphOutline >> contours` holds plain arrays of
points, no class of ours, so it is not a relation at all.

Value objects are not relations: `fontMatrix`, `userToDeviceMatrix`, and the numbers inside
`VGFontExtents`, `VGTextExtents` and `VGGlyph`.

### What unit 1.7 found when the declarations were written

Five of the seventeen rows were not relations, and the live objects said so:

- `VGScaledFont >> outlines` caches arrays of points, not `VGGlyphOutline` instances; the outline
  objects belong to `VGFontFace`, and the scaled font keeps the transformed contours.
- the four rows of `VGFontOptions` name symbols. `VGCairoAntialias` and its three siblings are
  namespaces of constants with no instance side at all, and the slots hold the symbol a constant
  answers, so these are value holdings like `fontMatrix`.

Two more rows were corrected against the objects: `VGGlyphAtlas >> masks` is a cache of many, not a
structural holding, because the answer for a glyph that inks nothing is `nil`, remembered so a space
is looked at once and never again; and `VGGlyphMask >> surface` holds a `VGCairoImageSurface`, this
package's own surface class, not Alexandrie's `AeCairoImageSurface`.

One row was added: `VGAeTextFont >> scaledFont`, the reciprocal of `aeTextFont`, without which the
checker reports a declaration whose opposite nothing states.

That makes thirteen declarations, which the checker now reads with nothing to say about them, except
one finding that is a real defect of the examples rather than of the declarations:
`VGScaledFontExamples >> fontFaceOfAnOpenTypeFont` raises `Error: the font has no CFF table` in this
container, because the system font it picks has no CFF table. It is pinned in unit 1.9.

ArchDoc gained three things it needed to state the real architecture, each with its own test:

- `archClassRelations`, a class-side table for what a class object itself holds, since
  `VGFontFace class >> defaultFace` keeps the bundled face for the life of the image;
- `archCache:to:opposite:`, so a lazily built adapter can name the role it is reached back under;
- a `brokenExample` finding, so an example that cannot run is reported rather than stopping the
  reading of the package.

## 6. Slice one, unit by unit

Every unit obeys the cycle: failing test, smallest code that passes, refactor with the suite green,
a class-side `<sampleInstance>` example in the sibling `-Examples` package, an
`inspection<Name>: aBuilder` view, then `run_critics` on what changed. A unit is not done until all
five artefacts exist and critics are clean.

- **Unit 1.0 — the checkouts.** `git init` both repos, write `.project` and `.properties`, register
  both in Iceberg. *Done.*
- **Unit 1.1 — `ArchDocRelation`.** Parse one accessor pragma into a relation that answers its role,
  its target symbol, its multiplicity and whether it is a cache. First failing test:
  `ArchDocRelationTest >> testOneRelationReadsItsRoleAndTargetFromAnAccessorPragma`.
- **Unit 1.2 — `ArchDocModel`.** Collect the relations of a package from pragmas and from class-side
  `archRelations` tables; answer the inferred uses from static references; answer an `ArchDocGraph`
  of nodes and edges.
- **Unit 1.3 — `ArchDocChecker`.** The four answers, each with a test that constructs a broken
  declaration and sees it reported.
- **Unit 1.4 — `ArchDocObjectGraph`.** Walk a live instance through its declared relations by slot
  reflection, not by sending accessors, so a class that hides an instance variable is still read.
  Bound in depth and in node count, and it must never force a lazy holding: an unbuilt cache reads
  as absent, not as an error.
- **Unit 1.5 — `ArchDoc-Roassal`.** The class diagram of a package and the graph of an object.
  Declared edges solid, caches dashed, inferred uses faint.
- **Unit 1.6 — `BaselineOfArchDoc`** and a load proof from the local checkout into a fresh image.
- **Unit 1.7 — the declarations** of the seventeen rows above, in VectorGraphics.
- **Unit 1.8 — `VectorGraphics-Documentation`**: an *Architecture* tab on `Package` and an *Object
  graph* tab on `VGScaledFont`.
- **Unit 1.9 — `VGFontArchitectureTest`** in `VectorGraphics-Documentation-Tests`: every declaration
  resolves, every opposite is reciprocal, every sample instance's actual holdings agree with its
  declarations.
- **Unit 1.10 — the agreement edits**, in one commit: two `allowedDependencies` rows, two packages
  and a `documentation` group in `BaselineOfVectorGraphics`, and `'ArchDoc'` and `'Roassal'` added
  to the list `testTheBaselineNamesOnlyBlocMuTalkAndPharoVulkanAsExternalProjects` asserts — a test
  whose name then changes to say what it now asserts.

Then stop, open the two tabs, and judge whether the picture answers the question.

## 7. Slice two, once slice one is judged

- Relations on the eight classes of `VectorGraphics-Bloc-Text` and the whole of
  `VectorGraphics-TrueType`, with a diagram for each package. *Done* — the Bloc side in one commit,
  the reader one commit per tag, Reading, Glyphs, Fonts and CFF.
- `ManifestVectorGraphicsBlocText` and `ManifestVectorGraphicsBlocFontEngine`, their class comments
  holding the architecture of the route in Microdown, plus `archDocEntryPoints` and
  `archDocForbiddenDependencies` on the manifest of `VectorGraphics-Canvas-Fonts`. *Done, except
  the forbidden dependencies*, which were cut from the slice when it was agreed: the dependency
  table in `VGArchitectureTest class >> allowedDependencies` already states every edge of this
  project and enforces it, so declaring the same rule a second time on a manifest buys a reader
  nothing and gives the two statements room to disagree. The entry points went on all four
  manifests of the route rather than on Canvas-Fonts alone, since a reader asks the same question
  of every package and silence reads as an oversight.
- AlgoTrace, `AlgoMetaLinkRecorder`, the declared route list, the recorded trace fixture, and the
  *Route* tab that shows the hand-offs in order — extending the `inspectorRoute:` view that
  `VGFontEngine class` already carries. *Deferred by agreement*, as its own slice: it is a
  recorder of a live run rather than a reading of declarations, and the declarations were worth
  judging first.
- The pointers in `doc/ARCHITECTURE.md`, which today states that the canvas layer is deliberately
  not described there, and in `README.md` beside the `load: 'fonts'` recipe. *Done* — section 14 of
  the first and a *Reading the font route* section in the second, plus the rows the packages and
  groups tables of `README.md` were missing.

Three facts the slice turned up, each worth its own decision:

- `VGAeTextContext >> ownTextFont` is declared a cache, by this project's reading of the word: a
  holding whose absence in a live object means nothing. It is nil for the whole life of a context
  that a real Alexandrie font is posed on, and that route never reads it.
- `VectorGraphics-Documentation-Examples` was walking a live `VGFontManager`, which is an edge to
  `VectorGraphics-Bloc-Text` that neither the dependency table nor the baseline granted. Both now
  state it, and the baseline requires the package for the documentation itself as well, because the
  *Object graph* tab is an extension installed on that class and an extension of an absent class is
  dropped at load.
- The one `.otf` installed on this machine, `Cantarell-VF.otf`, holds a `CFF2` table and no `CFF `
  one. Every OpenType failure of the suite is that: `VGScaledFontExamples class >>
  fontFaceOfAnOpenTypeFont`, `TrueTypeExamples class >> cffGlyphSource`, three failures and five
  errors in `VectorGraphics-TrueType-Tests` and one error in `VectorGraphics-Canvas-Fonts-Tests`.
  Reading `CFF2`, or testing OpenType against a font the project carries, is the next decision on
  the reader and not part of this documentation work.

## 8. Out of scope

PharoVulkan, which is the next subject and gets the same treatment once this one is proved;
`ArchDoc-Bloc`, since `aBuilder newRoassal` serves; any change to the font code itself, which has no
bug behind it; and the Morphic font route, `TrueTypeFont` and `TTFontDescription`, which the Bloc
route never reaches.

## 9. Commit discipline

Each unit is committed from the image through Iceberg at its green step. Documents outside `src/`
are committed from the host shell *before* any image commit, because an image commit sweeps every
untracked file in the checkout.

## 10. The fonts this repository does not carry

Two of the examples of the font route read a font that is neither in this repository nor certain to
be installed on the machine running them. They are parked rather than deleted, and they re-arm by
themselves on the day the file lands.

What is missing, and what to carry:

- An `.otf` file holding a `CFF ` table of Type 2 charstrings, for the twelve `TTCff…` classes and
  for the OpenType gates of the reader, of the metadata reader and of the scaled-font layer. The
  extension is not the rule: the one `.otf` installed on the machine this was written on,
  `Cantarell-VF.otf`, holds a `CFF2` table and no `CFF ` one, and `CFF2` is a different format this
  reader does not read.
- A font whose character map is of format 12, for `TTCharacterMapReader`. `DroidSansJapanese.ttf`
  is one.

How the absence is stated, in one place each:

- `TrueTypeExamples class >> openTypeFontPath` asks for a `.otf` *holding a `CFF ` table*, by
  reading the table directory of each candidate. It answers nil when the machine has none.
- An example that may answer nil carries `<needsAFontThisMachineMayLack: '<what to install>'>`
  beside its `<sampleInstance>`. The example gates read that pragma and tolerate nil for those
  methods alone; every other example still has to answer an object, twice, rebuilt. A pragma
  crosses no package edge, which is why the mechanism is a pragma: the two marked examples sit in
  packages that may not name each other, nor the test packages that gate them.
- `TTInstalledFonts class >> noCffFontInstalledReason` holds the one sentence the three machine-font
  tests skip with: `'no installed font holds a CFF table; carry one in the repository to run this'`.
- `VGFontArchitectureTest` pins nothing any more. It states that no example of the route raises and
  that the marked example says which font it needs; the four whitelist methods it used to carry are
  gone.

When the two files are carried in the repository, the examples read them instead of scanning the
machine, the three skips become runs, and the pragmas come off. Nothing else has to change.
