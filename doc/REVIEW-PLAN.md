# VectorGraphics — architecture and code review

Measured in the live image on 2026-11-06, at the state of commit `e0bedf5`. **Nothing was
modified** when this document was written: it is the diagnosis and the plan, validated before the
first edit.

## 0. What was measured

- 23 packages, 48211 lines in all; production code about 24.7k lines (Cairo 9236, Vulkan 9561,
  Engine 2244, TrueType 1893, Bloc 1072, Paths 387, Text 273).
- Renraku (`run_critics`) over every production package.
- Every "sent but not implemented" and "self sent but not implemented" critique checked with
  `allImplementorsOf:` and `allSendersOf:`, because an abstract class whose subclass implements the
  selector is a false positive. Four such false positives were found and discarded (`clipRect:`,
  `blendStrokeAndFill`, `blendFillOnly`, `blendStrokeOnlyAtX:y:pixelIndex:`).
- The 27 extension methods on classes outside the project: none overrides an existing
  implementation.
- The dependency table (`VGArchitectureTest class >> allowedDependencies`) and the declared cycles
  (`edgesTheBaselineCannotDeclare`).
- Sibling duplication between the two concrete rasteriser engines, selector by selector.

## 1. Diagnosis — defects

Each item is a real failure, reachable from code that exists. Each needs its failing test written
first.

### D1. A live `self halt` inside font parsing

`TTGlyfTableParser >> parseCompositeGlyph`:

```smalltalk
(flags allMask: 2) ifFalse: [ self halt ]. "ARGS_ARE_XY_VALUES — unsupported"
```

A composite glyph that uses point matching rather than x/y offsets opens a debugger in the middle
of reading a font. The rule is that an unsupported case raises a named error; `halt` is a
breakpoint left in production code. It is the only live `halt` in the project (the other two sites
are commented out, and are dead code — see M2).

### D2. Underlined text raises a doesNotUnderstand

`TrueTypeFont >> makeUnderlinedGlyph:` sends `copyBits:from:at:clippingBox:rule:`, which no class
in the image implements. Pharo spells it `copyBits:from:at:clippingBox:rule:fillColor:`. The method
is reached from `TrueTypeFont >> glyphAtUtf8Byte1:byte2:byte3:byte4:` whenever `isUnderlined` is
true and the underline does not fit in the existing glyph form, so drawing an underlined string
fails. This is Cuis `Form` protocol that Pharo does not have.

### D3. The font-directory chain is broken end to end

`FontFamily class >> readIfNeeded:` (no sender) calls `TrueTypeFontFamily class >>
readAllTrueTypeFontsIn:`, which calls `TTFontDescription class >> read:`, which sends
`allFilesDo:matches:` — Cuis `DirectoryEntry` protocol, absent from Pharo. `FontFamily class >>
readIfNeeded:` also sends `textContents`, which no class implements. Three methods, one dead and
broken chain.

### D4. `privatePointsDo:` is an abstract hook two subclasses do not answer

`PathCommand >> privatePointsDo:` is `subclassResponsibility`. Nine subclasses implement it;
`PathLineToHCommand` and `PathLineToVCommand` do not, so sending it to either raises
doesNotUnderstand. The hook has **zero production senders** — its only four senders are test
methods. The implementation in `PathLineToCommand` carries a comment left from the Cuis original
saying the relative-coordinate case is wrong.

### D5. Temporary read before written

`TTGlyfTableParser >> parseCompositeGlyph` and `VectorCanvas >>
fillRectangle:color:borderWidth:borderStyleSymbol:baseColorForBorder:`. The second is dead code
(M1); the first is the same method as D1 and is fixed in the same pass.

## 2. Diagnosis — dead code

### M1. Morphic widget chrome on `VectorCanvas`, ten methods, no sender

`drawButtonIconFromCurrentMorph`, `drawCollapseIcon`, `drawDownIcon`, `drawExpandIcon`,
`drawLeftIcon`, `drawMenuIcon`, `drawRightIcon`, `drawUpIcon`,
`windowFrame:color:radius:border:labelHeight:gradientTop:gradientBottom:insideColor:` (nine
keyword arguments) and `fillRectangle:color:borderWidth:borderStyleSymbol:baseColorForBorder:`.
This is the Cuis window-decoration layer. The project draws through Bloc and Cairo; nothing calls
any of it.

### M2. Two methods whose `super` the superclass cannot understand

`VectorCanvas >> image:multipliedBy:at:` and `VectorCanvas >>
textComposition:bounds:color:selectionColor:` both send a `super` message that `Canvas` does not
implement. They carry Spanish comments, a commented-out `self halt` and a misspelled parameter
name (`boundddsRect`). Calling either fails; nothing calls either.

### M3. The morph-id hit-test layer cannot work, and it costs every pixel

Three instance variables of `VectorEngineAbstract` (`morphIds`, `currentMorphId`,
`clippingMorphId`) and five methods (`currentMorph:`, `clippingMorph:`, `morph:isAtPoint:` on two
classes, `pvtAllocateMorphIds`) implement the Cuis map of which morph painted which pixel.

`morphId` **has no implementor in the image**, so `currentMorph:` and `clippingMorph:` raise
doesNotUnderstand for any non-nil morph, and `morph:isAtPoint:` raises it for any morph. Neither
setter has a single sender; `morph:isAtPoint:` is sent only by one test, which asserts the
bounds-finder answers `false`.

What the dead feature costs today:

- `pvtAllocateMorphIds` allocates a `WordArray` of `width * height` for every target form — four
  bytes per pixel of the drawing surface.
- every one of the eight `blend*` methods writes `morphIds at: pixelIndex put: currentMorphId` for
  each pixel it covers, with `currentMorphId` always 0.
- `VectorEnginePixel >> blendStrokeOnly` and `finishPath:` read the map and compare two ids per
  pixel of the blend rectangle.

`morphBounds*` is a different thing and is live (`measuredMorphBounds`, the bounds finder): it
stays.

### M4. `privatePointsDo:` as a whole

Ten methods (nine implementations plus the abstract one) for a hook no production code sends. See
D4.

## 3. Diagnosis — architecture

### A1. `VectorCanvas` subclasses `Canvas` and does not honour the contract

In Cuis, `VectorCanvas` could stand in for `Canvas` and be used directly by Morphic. Morphic is
not the target of this project: `VectorCanvas` is independent, and the inheritance is the last
thread of the port.

It inherits 593 selectors from `Canvas`, of which **19 are still `subclassResponsibility`**:
`form`, `extent`, `origin`, `clipRect`, `depth`, `contentsOfArea:into:`, `clipBy:during:`,
`translateBy:during:`, `transformBy:clippingTo:during:smoothing:`,
`drawString:from:to:in:font:color:` (and its underline variant),
`drawPolygon:color:borderWidth:borderColor:`, `fillOval:color:borderWidth:borderColor:`,
`image:at:sourceRect:rule:`, `stencil:at:sourceRect:color:`, `paragraph:bounds:color:`,
`rubParagraph:bounds:color:`, `ffiLibraryName`, `subclassResponsibility`.

The inheritance therefore advertises a Morphic canvas that the class is not. It has already cost
us once: the P7 load proof had to be rewritten after `canvas form` raised *"VectorCanvas had the
subclass responsibility to implement #form"* — the natural way to read back the pixels does not
work. It is also the root cause of M2: those two methods only exist because a Cuis `Canvas`
implemented their `super`.

Nothing in the project uses a `VectorCanvas` as a `Canvas`. Every creation site is project code or
a test (`PathCommandExamples`, `SVGPathExamples`, `TTFontDescription`, `TTGlyph`,
`TextDrawingExamples`, `VectorCanvasExamples`, `VectorCanvasTest`), and the Bloc backend does not
touch it.

Refactoring: **Replace Inheritance with Delegation** — `VectorCanvas < Object`. The API of the
class becomes the 58 selectors it really implements.

### A2. Two declared dependency cycles, caused by library code filed in test packages

`edgesTheBaselineCannotDeclare` tolerates two cycles: `VectorGraphics-Cairo-Examples` and
`VectorGraphics-Cairo-Tests` each depend on the other, and so do
`VectorGraphics-Vulkan-Examples` and `VectorGraphics-Vulkan-Tests`.

They exist because classes that are not test cases live in the `-Tests` packages, and the examples
need them:

| Package | Class (not a `TestCase`) | Selectors | Tag |
|---|---|---|---|
| Cairo-Tests | `VGConformanceCorpus` | 48 | `Conformance` |
| Cairo-Tests | `VGConformanceCase` | 21 | `Conformance` |
| Cairo-Tests | `VGFormComparison` | 21 | `Conformance` |
| Cairo-Tests | `VGAlexandrieCorpus` | 30 | `Conformance` |
| Cairo-Tests | `VGAlexandrieCase` | 29 | `Conformance` |
| Cairo-Tests | `VGAlexandriePortedExperiments` | 82 | `Conformance` |
| Cairo-Tests | `VGAlexandrieFontLifetime` | 6 | `Fixtures` |
| Vulkan-Tests | `VGFrameDeviceBenchmark` | 58 | `Budget` |
| Vulkan-Tests | `VGFrameStageBenchmark` | 19 | `Budget` |
| Vulkan-Tests | `VGFrameDrawingKit` | 16 | `Budget` |

That is roughly 330 selectors of library code — a conformance corpus and a benchmark harness —
living where Pharo tools, the groups of the baseline and the dependency table all expect test
cases. The real stubs and fixtures in the same packages (`VGBrokenBackendStub`,
`VGCountingMaskStub`, `VGBackendFrameFixture`, `VGGradientFrameFixture`,
`VGNoDeviceRoundTripStub`, `VGNonPresentingSurfaceStub`, `VGNestedBlockReferenceFixture`) are
correctly placed and stay.

Refactoring: **Move Class** into two new packages, `VectorGraphics-Conformance` and
`VectorGraphics-Benchmarks`. Gain: both cycles disappear, `edgesTheBaselineCannotDeclare` becomes
empty, and the corpus and the benchmarks can be loaded without the suite — which is the whole
reason the project was split. Cost: 23 packages become 25, with an entry in `allowedDependencies`
and a declaration in the baseline for each, plus two groups.

### A3. `VectorGraphics-Vulkan` depends on Bloc and Cairo

Recorded, no action: the Vulkan backend genuinely measures itself against the Cairo path, and
`VGVulkanBlurTest` subclasses `VGBlurTest` on purpose.

## 4. Diagnosis — hygiene

### H1. 21 test classes with no class comment

All of them in the four rasteriser test packages (`VectorGraphics-Engine-Tests` 5,
`VectorGraphics-Paths-Tests` 4, `VectorGraphics-TrueType-Tests` 12). Every Cairo and Vulkan test
class has one, so this is the older half of the project. The documentation gate in
`VectorGraphics-Tests` checks packages; it does not check test classes.

## 5. What is deliberately left alone

- **The per-pixel blend methods** (`blendFillOnlyAtX:y:pixelIndex:isInside:` 38 lines,
  `blendStrokeAndFillAtX:y:pixelIndex:redIsInside:greenIsInside:blueIsInside:` 77 lines, and six
  more) and the 20 + 17 instance variables of the engines. Renraku calls them long and
  variable-heavy, and they are: they are the inner loop of a software rasteriser, where an
  instance variable is scanline state and an Extract Method costs a message send per pixel. The
  only change proposed here that touches them is M3, which makes them both shorter and faster.
- **The six selectors the two concrete engines share.** No pair of the six is identical
  (`updateAlphasForX:y:` is 72 lines in the sub-pixel engine and 36 in the whole-pixel one). They
  are parallel implementations of different pixel geometry — one coverage value against three —
  not copy-paste. A Pull Up Method would put a per-channel conditional back into the inner loop.
- **The 121 excessive-argument critiques in `VectorGraphics-Cairo`.** They mirror the `cairo_*`
  entry points one to one; renaming or wrapping them would hide the C API the bindings exist to
  expose.
- **The critics of `VectorGraphics-Vulkan`**, which are 41 inconsistent method classifications and
  nothing else.

## 6. The plan, in order

Each step: failing test first, smallest change to green, refactor, example and inspector view
where a new artefact appears, `run_critics` on what changed, commit at green. No test is changed
inside a refactoring step; where a step deletes a test on purpose it says so.

| # | Step | Gain | Risk |
|---|---|---|---|
| 1 | **D1** — `parseCompositeGlyph` raises a named error instead of `self halt`. Test: a composite glyph record with the `ARGS_ARE_XY_VALUES` bit clear. | A debugger no longer opens while reading a font | none |
| 2 | **D2** — `makeUnderlinedGlyph:` uses `copyBits:from:at:clippingBox:rule:fillColor:`. Test: an underlined `TrueTypeFont` asked for a glyph whose underline does not fit. | Underlined text draws | low |
| 3 | **M1 + M2** — delete the twelve dead Morphic methods of `VectorCanvas`. Pure deletion; `find_senders` on each first. | Twelve methods fewer, the Cuis chrome gone | none |
| 4 | **A1** — `VectorCanvas < Object`. Must follow step 3, which deletes the methods that need the protocol of `Canvas`. Then answer `form` itself. | The class stops promising 19 methods it has not got; `form` works | medium: run the whole rasteriser suite |
| 5 | **M3 and the `morphId` half of D2** — remove `morphIds`, `currentMorphId`, `clippingMorphId`, the five methods, and the per-pixel read and write. | Three instance variables fewer, four bytes per pixel of target saved, one store and two compares out of every pixel; measure with `VGFrameStageBenchmark` before and after | medium: touches the eight blend methods. One test (`VectorEngineBoundsFinderTest >> testAnswersNoHitTest`) pins the feature and is deleted with it, stated here in advance |
| 6 | **D3** — delete `FontFamily class >> readIfNeeded:`, `TrueTypeFontFamily class >> readAllTrueTypeFontsIn:` and `TTFontDescription class >> read:`. If loading a family from a directory is wanted, it comes back test-first on `FileReference`, not on the `DirectoryEntry` of Cuis. | Three broken methods gone | low |
| 7 | **D4 and M4** — delete `privatePointsDo:` and its nine implementations, with the four tests that are its only senders. | Ten methods fewer, and an abstract hook that lied about being implemented | low |
| 8 | **H1** — a class comment on the 21 test classes, and a gate test that fails when a test class has none. | The documentation rule covers the test packages too | none |
| 9 | **A2** — move the conformance corpus and the benchmark harness out of the `-Tests` packages, drop both declared cycles. | `edgesTheBaselineCannotDeclare` empty; corpus and benchmarks loadable alone | medium, and the largest piece of work here: two packages, two baseline groups, ten class moves |

Steps 1 to 8 are each small and independent. Step 9 is a package change of the same shape as
P0 to P7.

## 7. MuTalk

Steps 5, 6 and 7 delete code and, in 5 and 7, delete tests. Before step 5 and again after step 7,
run MuTalk with `classesToMutate` limited to `VectorEnginePixel`, `VectorEngineWholePixel`,
`VectorEngineSubPixel` and `PathCommand withAllSubclasses`, from a clean Iceberg checkout. The
score must not fall.
