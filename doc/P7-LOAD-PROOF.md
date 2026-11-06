# P7 — the load proof, to run on a real machine

The split was made for flexibility: the font reader without the rasteriser, the rasteriser without
the font code, each test group on its own. Nothing proves that in the development image, where
every package is present already. P7 loads each group into a blank Pharo 13 and checks what
arrived.

Six steps. Each one wants its **own fresh image** — a group loaded into an image that already holds
another group proves nothing.

Every expression below was run in the development image first, so the snippets are known to work
when the packages they name are present. What P7 tests is whether they still work, and what is
absent, after a load.

## 0. Once: a fresh image per step

`main` is pushed. `git ls-remote` answers
`152cd8c55202dba6247ac4228c1d116208c5d5af	refs/heads/main`, which is the commit the steps below
expect, so GitHub is the source and no clone is needed:

```smalltalk
repository: 'github://rvillemeur/VectorGraphics:main/src'
```

A fresh image per step, however you normally get one:

```bash
mkdir -p ~/p7/step1 && cd ~/p7/step1
curl -s https://get.pharo.org/64/130+vm | bash
```

Metacello caches a GitHub fetch under `pharo-local/package-cache`, so only the first step downloads.
A step must still get its **own blank image** — a group loaded next to another group proves nothing.

## The check to paste after each load

One expression. It prints `PASS`, or `FAIL` with what really arrived. Replace the `expected` list
with the step's own:

```smalltalk
| expected actual |
expected := #( 'VectorGraphics-Paths' ) asSortedCollection asArray.
actual := ((PackageOrganizer default packages select: [ :each |
	            each name beginsWith: 'VectorGraphics' ]) collect: [ :each |
	           each name asString ]) asSortedCollection asArray.
actual = expected
	ifTrue: [ 'PASS' ]
	ifFalse: [ 'FAIL — loaded ' , actual printString ]
```

`BaselineOfVectorGraphics` is its own package and is not matched by that prefix, so it never
appears in the answer.

## Step 1 — `paths` alone

```smalltalk
Metacello new
	baseline: 'VectorGraphics';
	repository: 'github://rvillemeur/VectorGraphics:main/src';
	onConflictUseIncoming;
	load: 'paths'
```

Expected packages: `VectorGraphics-Paths`, and nothing else.

Absence, which is the real claim of this step:

```smalltalk
{ (#VectorEngineAbstract -> (Smalltalk includesKey: #VectorEngineAbstract)).
  (#VectorCanvas -> (Smalltalk includesKey: #VectorCanvas)).
  (#TTFontDescription -> (Smalltalk includesKey: #TTFontDescription)).
  (#SVGPathParser -> (Smalltalk includesKey: #SVGPathParser)) }
```

Expect `false false false true`. Then prove the package works alone:

```smalltalk
(SVGPathParser parse: 'M 10 10 L 20 20 Z') size
```

Expect `3`.

## Step 2 — `truetype` with no engine

```smalltalk
Metacello new
	baseline: 'VectorGraphics';
	repository: 'github://rvillemeur/VectorGraphics:main/src';
	onConflictUseIncoming;
	load: 'truetype'
```

Expected packages: `VectorGraphics-Paths`, `VectorGraphics-TrueType`. Paths arrives because a glyph
comes back as path commands; the rasteriser does not arrive at all.

```smalltalk
{ (#VectorEngineAbstract -> (Smalltalk includesKey: #VectorEngineAbstract)).
  (#VectorCanvas -> (Smalltalk includesKey: #VectorCanvas)).
  (#TrueTypeFont -> (Smalltalk includesKey: #TrueTypeFont)).
  ('the glyph-to-Form glue' -> (TTFontDescription includesSelector:
	   #formGlyphForUtf8Byte1:byte2:byte3:byte4:pixelSize:)) }
```

Expect `false false true false`. The last row is the point of `VectorGraphics-Text`: turning a
glyph into a `Form` needs the rasteriser, so that method is an extension method of the Text layer
and must be absent here. Then read a real font with no rasteriser in the image:

```smalltalk
| file description |
file := '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf' asFileReference.
file exists ifFalse: [
	file := ('/usr/share/fonts' asFileReference allChildrenMatching: '*.ttf') first ].
description := TTFontReader readTTFFrom: file binaryReadStream contents.
description familyName -> description unitsPerEm
```

Expect a family name and a unit count — in this VM, `'Adwaita Mono' -> 1000`. The answer is a
`TTFontDescription`, built by the reader with no rasteriser anywhere.

## Step 3 — `engine` with no font code

```smalltalk
Metacello new
	baseline: 'VectorGraphics';
	repository: 'github://rvillemeur/VectorGraphics:main/src';
	onConflictUseIncoming;
	load: 'engine'
```

Expected packages: `VectorGraphics-Engine` alone — not even `VectorGraphics-Paths`.

```smalltalk
{ (#TTFontDescription -> (Smalltalk includesKey: #TTFontDescription)).
  (#TrueTypeFont -> (Smalltalk includesKey: #TrueTypeFont)).
  (#SVGPathParser -> (Smalltalk includesKey: #SVGPathParser)).
  ('the text glue' -> (VectorCanvas includesSelector: #drawUtf8:at:font:color:)) }
```

Expect `false false false false`. The last row is the other half of the same point: the six glue
methods live in `VectorGraphics-Text`, so an engine loaded without them has no way to draw a
string. Then rasterise something:

```smalltalk
| target canvas |
target := Form extent: 64 @ 64 depth: 32.
canvas := VectorCanvas onForm: target.
canvas fillColor: Color red do: [
	canvas moveToX: 8 y: 8; lineToX: 56 y: 8; lineToX: 32 y: 56; closePath ].
(target colorAt: 32 @ 30) -> (target colorAt: 1 @ 1)
```

Expect `Color red -> Color transparent` — inside the triangle filled, outside untouched. The
pixels come from the `Form` you made, and `canvas form` answers that same form: `VectorCanvas` is an
`Object` that owns its destination, not a `Canvas` subclass.

## Step 4 — `default`

```smalltalk
Metacello new
	baseline: 'VectorGraphics';
	repository: 'github://rvillemeur/VectorGraphics:main/src';
	onConflictUseIncoming;
	load
```

Expected packages, all six: `VectorGraphics`, `VectorGraphics-Paths`, `VectorGraphics-Engine`,
`VectorGraphics-TrueType`, `VectorGraphics-Text`, `VectorGraphics-Cairo`.

The claim to hold here is that nothing of Bloc or Alexandrie is needed:

```smalltalk
{ (#BARenderer -> (Smalltalk includesKey: #BARenderer)).
  (#AeCanvas -> (Smalltalk includesKey: #AeCanvas)).
  (#BlElement -> (Smalltalk includesKey: #BlElement)).
  ('the glue is back' -> (VectorCanvas includesSelector: #drawUtf8:at:font:color:)) }
```

Expect `false false false true` in an image where Bloc was never loaded.

## Step 5 — `cairo` brings neither the engine nor the glue

New since P6, and the result most likely to surprise:

```smalltalk
Metacello new
	baseline: 'VectorGraphics';
	repository: 'github://rvillemeur/VectorGraphics:main/src';
	onConflictUseIncoming;
	load: 'cairo'
```

Expected packages: `VectorGraphics-Cairo`, `VectorGraphics-Paths`, `VectorGraphics-TrueType` — the
Cairo backend names the font reader and nothing else of the four layers. `VectorGraphics-Engine`,
`VectorGraphics-Text` and the front-page `VectorGraphics` package must be absent:

```smalltalk
{ (#VectorEngineAbstract -> (Smalltalk includesKey: #VectorEngineAbstract)).
  (#VGCairoContext -> (Smalltalk includesKey: #VGCairoContext)) }
```

Expect `false true`. If anything of the Cairo layer turns out to need the engine, the fix is a
`requires:` in `declareBackendPackagesOn:` and an edge in `allowedDependencies`; the architecture
suite in the development image will then name the method that makes the reference.

## Step 6 — the four test groups, and the suite

```smalltalk
Metacello new
	baseline: 'VectorGraphics';
	repository: 'github://rvillemeur/VectorGraphics:main/src';
	onConflictUseIncoming;
	load: #( 'paths-tests' 'engine-tests' 'truetype-tests' 'text-tests' )
```

Expected packages, thirteen: the four code packages, plus `VectorGraphics-Tests`, the four
`-Examples` and the four `-Tests`. The front-page `VectorGraphics` package is **not** among them.
Each test group pulls `VectorGraphics-Tests` for the abstract documentation gate — the first time
that package is loaded anywhere but the development image.

```smalltalk
| out |
out := WriteStream on: String new.
#( 'VectorGraphics-Paths-Tests' 'VectorGraphics-Engine-Tests' 'VectorGraphics-TrueType-Tests'
   'VectorGraphics-Text-Tests' ) do: [ :name |
	| suite |
	suite := TestSuite new.
	(PackageOrganizer default packageNamed: name) definedClasses do: [ :each |
		((each inheritsFrom: TestCase) and: [ each isAbstract not ]) ifTrue: [
			suite addTests: each buildSuiteFromSelectors tests ] ].
	out nextPutAll: name; nextPutAll: ' '; nextPutAll: suite run printString; cr ].
out contents
```

Expected, from the development image: 60, 56, 165, 21 — 302 tests, no failures and no errors.

Two differences from the development image are expected and are not failures:

- **Skips.** The gates that read `doc/ARCHITECTURE.md` find no Iceberg checkout in a
  Metacello-loaded image and skip with *"There is no checkout of VectorGraphics in this image"*.
- **One gate per layer.** Asking for one group alone brings one documentation gate.
  `testTheGateHierarchyFindsEveryDocumentedPackage` was changed for exactly this (commit
  `152cd8c`); loading all four together is the easier case.

Worth watching, because it has never been tested: the gates that read the **package comment**. A
package comment is part of the Tonel package file, so it should arrive. If it does not, those gates
fail in a loaded image, and the fix is to skip them the way the document gates skip, not to delete
them.

## What to send back

Per step: the `PASS`/`FAIL` line, the absence list, the one working snippet, and for step 6 the
four suite lines. A `FAIL` naming a package that should not be there is a missing narrowing in
`BaselineOfVectorGraphics >> declareRasteriserPackagesOn:` or `declareBackendPackagesOn:`; a load
error naming a class is a missing `requires:`. Either way the development image can then be made to
show the same thing as a red architecture test.
