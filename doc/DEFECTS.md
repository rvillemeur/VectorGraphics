# Defects of the VectorCanvas port

What this records: every place where `VectorCanvas` does not answer the protocol a Pharo `Canvas`
is asked for, or holds state nothing ever sets. The rasteriser underneath it works; these are gaps
of the port from Cuis, not of the design. `doc/ARCHITECTURE.md` describes how the working parts fit
together, and §7 of it covers the morph identity state named below.

Every symptom in the tables was produced by running the call, not read off the source. The probe:

```smalltalk
| canvas form |
form := Form extent: 60 @ 60 depth: 32.
form fillColor: Color white.
canvas := VectorCanvas onForm: form.
canvas form   "SubclassResponsibility: VectorCanvas had the subclass responsibility to implement #form"
```

Status: nothing in this file is fixed yet. One defect of the same family was fixed before it was
written: `boundsFinderEngine` was never built, so `updatingMorphBoundsDo:` swapped a nil engine in.
That fix is the shape every unit below should take — a failing test first, then the smallest code,
then an example, a view and clean critics.

## 1. The `Canvas` protocol `VectorCanvas` does not implement

Each of these is declared `subclassResponsibility` by `Canvas` and not overridden, so the call
raises `SubclassResponsibility` the moment Morphic makes it. There are seventeen, counted
from the image, not from this table. `FormCanvas` is the reference
implementation to mirror for semantics. The last column names what already exists in this package,
because most of these are adapter work over working code rather than new rasteriser work.

### State

| Selector | What a caller wants | Already here |
|---|---|---|
| `form` | the destination form | the `form` instance variable |
| `extent` | the extent of that form | `form extent` |
| `depth` | its depth, always 32 here | `VectorCanvas >> setForm:` already rejects any other depth |
| `clipRect` | the clip rectangle now in force | the engine holds `clipLeft`, `clipTop`, `clipRight`, `clipBottom` |
| `origin` | the current drawing origin | nothing: there is no translation state at all, see §3 |

### Clipping and transformation, scoped to a block

| Selector | What a caller wants | Already here |
|---|---|---|
| `clipBy:during:` | clip, run the block, restore | `setClipRect:`, which is immediate, private and has no save or restore |
| `translateBy:during:` | translate, run the block, restore | nothing, see §3 |
| `transformBy:clippingTo:during:smoothing:` | an affine transformation around a block | nothing, see §3 |

### Shapes

| Selector | What a caller wants | Already here |
|---|---|---|
| `drawPolygon:color:borderWidth:borderColor:` | a filled, bordered polygon | `polyLine:` inside `strokeWidth:color:fillColor:do:` |
| `fillOval:color:borderWidth:borderColor:` | a filled, bordered ellipse | `ellipseCenterX:y:rx:ry:borderWidth:borderColor:fillColor:` |

### Text

| Selector | What a caller wants | Already here |
|---|---|---|
| `drawString:from:to:in:font:color:` | a substring inside a rectangle | `drawString:from:to:at:font:color:`, which takes a point, so Morphic's call misses by one keyword |
| `drawString:from:to:in:font:color:underline:underlineColor:strikethrough:strikethroughColor:` | the same with decorations | the same method, plus `line:to:width:color:` for the two rules |
| `paragraph:bounds:color:` | a composed paragraph | the glyph route of §8 of the architecture document |
| `rubParagraph:bounds:color:` | the same for a Rubric text area | the same |

### Images

| Selector | What a caller wants | Already here |
|---|---|---|
| `image:at:sourceRect:rule:` | blit a form | nothing: the engine has no image path |
| `stencil:at:sourceRect:color:` | flood a colour through a mask | nothing |
| `contentsOfArea:into:` | read pixels back out | nothing in the canvas, but `Form >> contentsOfArea:into:` does it |

## 2. Two methods call `super` with a selector `Canvas` does not understand

| Method | Symptom |
|---|---|
| `VectorCanvas >> image:multipliedBy:at:` | `MessageNotUnderstood: Canvas >> #image:multipliedBy:at:` |
| `VectorCanvas >> textComposition:bounds:color:selectionColor:` | the same shape; `Canvas canUnderstand: #textComposition:bounds:color:selectionColor:` is false |

Both selectors exist only on `VectorCanvas` in this image, and the only sender of each is itself:
they are Cuis canvas protocol that Pharo does not have. Both still carry the porter's commented-out
`self halt` and a Spanish note. Neither can ever work as written.

## 3. There is no translation or transformation at all

`VectorEngineAbstract >> geometryTransformation:` is a no-op whose comment says the Cuis
`AffineTransformation` was removed and coordinates now pass straight to the primitives. So the three
scoped selectors of §1 have nothing to build on, and `origin` has nothing to answer. This is the one
gap in this file that needs new engine code rather than an adapter, and it is what a morph tree
needs most: Morphic draws children by translating the canvas.

## 4. Morph identity: the canvas half of the hit test

| What | State |
|---|---|
| `currentMorph` instance variable | never assigned anywhere; no setter; the canvas never sends `currentMorph:` to the engine |
| `VectorCanvas >> drawButtonIconFromCurrentMorph` | fails with `receiver of "iconName" is nil` |
| `morphIds` buffer | stays all zero, so `VectorEngineAbstract >> morph:isAtPoint:` finds nothing |
| `clippingMorphDisplayBounds` instance variable | never assigned; read only by `inspectorEngineEntries` |
| `clippingMorph:` | implemented on the engine, unreachable from the canvas |

`VectorEngineAbstract >> currentMorph:` asks the morph for `morphId`, and nothing in a Pharo image
answers it, which §7 of the architecture document already records. The engine side and the canvas
side are one defect: fixing `morphId` alone would still leave `morphIds` empty, because no one tells
the engine which morph is drawing.

## 5. Smaller things

- `VectorCanvas >> doSubPixelAntiAliasing` ends with the dead comment `"self newClipRect: nil"`.
  No `newClipRect:` exists in the image.
- The canvas offers no hit test of its own; only `VectorEngineAbstract >> morph:isAtPoint:` does.
- Nothing fails when a `Canvas` selector is missing until Morphic calls it, which is why §1 stayed
  invisible through 237 passing tests.

## The plan

Nine units. Each one is finished the way the project asks: the failing test first, then the smallest
code that passes, then a refactor with the suite green, then a class-side `<sampleInstance>` example
and an inspector view where the unit adds state worth seeing, then `run_critics` on what changed,
then its own commit. The order is cheapest first, except that the gate comes before everything so
each later unit can watch its own defect disappear.

### U0. The gate that makes §1 visible

A new `VectorCanvasConformanceTest` with one test: collect every selector that `Canvas` answers with
`subclassResponsibility`, reject the ones `VectorCanvas` overrides, and assert the rest is empty.
The test fails today with the seventeen selectors of §1 and shrinks as the units land, so no unit has
to be trusted to have listed its own selectors. A second test asserts that no method of
`VectorCanvas` sends a `super` message its superclass cannot understand, which is §2.

Both tests read the image rather than a list written by hand, so they cannot drift.

### U1. State: `form`, `extent`, `depth`, `clipRect`

Four accessors. `clipRect` needs the engine to answer its own clip rectangle, so add
`VectorEnginePixel >> clipRectangle` and have the canvas delegate; the convention of §7 of the
architecture document applies, the rectangle includes its left and top and excludes its right and
bottom, so the engine's `clipRight` and `clipBottom` are the last pixels drawn and the rectangle
must be one larger. `origin` waits for U3.

Test that each answers what the form really holds, and that `clipRect` follows `setClipRect:`.

### U2. Scoped clipping: `clipBy:during:`

Save the engine's clip rectangle, set the new one, run the block, restore in an `ensure:`. Nesting
must work, and the restore must happen when the block raises. Keep `setClipRect:` as it is.

Test nesting two deep, and a block that signals.

### U3. Translation and transformation

The one unit that needs engine code, and the one worth investigating before it is planned in detail.
Two candidate shapes:

1. An offset in the engine, applied where every path command already converges — the `basic…`
   layer of §2 of the architecture document — so one place changes and every `abs_` and `rel_`
   command inherits it. Cheap, and enough for `translateBy:during:` and `origin`.
2. A real affine transformation, which is what `transformBy:clippingTo:during:smoothing:` asks for.
   This is the Cuis `AffineTransformation` the port dropped, and it costs a matrix per path command
   plus a decision about what smoothing means here.

Plan: do shape 1 in this unit and answer `origin`, then decide whether shape 2 is worth it from a
real caller. If it is not, `transformBy:clippingTo:during:smoothing:` should raise an error that
says what is unsupported, which is still better than `subclassResponsibility` from a superclass.

### U4. Shapes: `drawPolygon:color:borderWidth:borderColor:` and `fillOval:color:borderWidth:borderColor:`

Adapters over `polyLine:` and `ellipseCenterX:y:rx:ry:borderWidth:borderColor:fillColor:`, inside
the right `strokeWidth:color:fillColor:do:`. `Canvas` sends both from several convenience methods,
so the tests should drive them through those too: `frameOval:width:color:` and
`drawPolygon:fillStyle:borderWidth:borderColor:`.

### U5. Text: the `in:` family

`drawString:from:to:in:font:color:` is `drawString:from:to:at:font:color:` with the rectangle's
top left as the point, clipped to the rectangle. The decorated variant adds an underline and a
strikethrough, both of which are `line:to:width:color:` at a font-derived offset. `paragraph:bounds:color:`
and `rubParagraph:bounds:color:` walk the paragraph's lines and send the first method per line.

Test against the glyph route of §8, and add a view only if a text run turns out to carry state worth
seeing.

### U6. Images: `contentsOfArea:into:`, `stencil:at:sourceRect:color:`, `image:at:sourceRect:rule:`

In that order, because the first is a `Form` copy with no engine involvement, the second is a mask
flood which the blend pass can express, and the third is a real blit that the engine has no path for
at all. If the third needs more than a form-to-form copy honouring the clip rectangle, it earns its
own plan rather than being forced into this unit.

### U7. Morph identity, both halves

The canvas owns the map: `currentMorph: aMorph` records the morph in an identity dictionary, hands
the engine the small integer id it allocated, and `morph:isAtPoint:` on the canvas looks the morph
back up. That removes the need for anything in the image to answer `morphId`, which is what §7 of
the architecture document records as the open defect, and it keeps the engine's buffers numeric as
they are. `VectorEngineAbstract >> currentMorph:` then takes an id rather than a morph, which is a
change to existing code and belongs in this unit with its own test.

Also: wire `clippingMorph:` through from the canvas, and either assign
`clippingMorphDisplayBounds` or delete it. `drawButtonIconFromCurrentMorph` becomes testable as soon
as `currentMorph` is set, so its test goes here.

### U8. Delete what cannot work

Once U5 and U6 exist, `image:multipliedBy:at:` and `textComposition:bounds:color:selectionColor:`
have Pharo equivalents, so both go, with the commented-out `self halt` and the Spanish notes. The
dead `"self newClipRect: nil"` comment goes with them. Check senders first, as the project asks;
today each is sent only by itself.

### U9. The architecture document catches up

`doc/ARCHITECTURE.md` §7 gains the canvas protocol as it then stands, and the open defect paragraph
about `morphId` becomes a description of the identity map. This file shrinks to what is still broken,
or goes away.

### What the order buys

U0 to U2 and U4 to U5 are adapters and accessors: they make a `VectorCanvas` survive being handed to
Morphic for anything that does not translate the coordinate system. U3 is what makes a morph tree
work, and U7 is what makes hit testing and shape clipping work, so the two of them together are what
"Morphic can really use this canvas" means. U6 is last because an image blit is the one thing this
rasteriser was never meant to do.
