# Defects of the VectorCanvas port

## The premise of this document is withdrawn

This file used to record every place where `VectorCanvas` failed to answer the protocol a Pharo
`Canvas` is asked for, and it planned nine units of work to close those gaps. That whole premise
rested on `VectorCanvas` being a `Canvas` subclass handed to a morph tree, which is what it was in
Cuis.

Morphic is not a target of this project. `VectorCanvas` is independent: it is an `Object` that
rasterises paths onto a `Form` it owns, and the pixels are read back from that `Form`. The
inheritance was the last thread of the port, and `doc/REVIEW-PLAN.md` §A1 cut it.

So the gaps are not defects. A method `Canvas` declares and `VectorCanvas` does not answer is simply
a method this project never promised:

- **the seventeen unimplemented `Canvas` selectors** — gone with the superclass. `form`, `extent`,
  `depth` and `clipRect` are the four a caller of this package really wants, and `form` is now
  implemented; the others are one line each if a caller appears.
- **the two `super` sends to selectors `Canvas` lacks** — gone. `image:multipliedBy:at:` and
  `textComposition:bounds:color:selectionColor:` were Cuis canvas protocol with no Pharo equivalent,
  and step 3 of the review plan deleted them along with the ten other Morphic-chrome methods.
- **morph identity** — gone. Nothing in a Pharo image answers `morphId`, so the `morphIds` buffer
  stayed all zero and `morph:isAtPoint:` never found anything. Step 5 of the review plan removes the
  buffer, the two setters and the per-pixel write that filled it, which is also a speed-up: the
  blend pass stops touching a second buffer for every pixel it covers.

## What survives

**There is no translation and no transformation.** `VectorEngineAbstract >> geometryTransformation:`
is a no-op whose comment records that the Cuis `AffineTransformation` was dropped and coordinates
now pass straight to the primitives. Nothing in the project needs one today, because a caller builds
its path in the coordinates of the destination `Form`. It is written down here because it is the one
absence that would need real engine code rather than an accessor, and because a reader of the path
commands may expect a current transformation matrix and find none.

Two shapes, if a caller ever asks:

1. An offset applied where every path command already converges, the `basic…` layer of §2 of
   `doc/ARCHITECTURE.md`. One place changes and every `abs_` and `rel_` command inherits it. Enough
   for a scoped `translateBy:`.
2. A full affine transformation, a matrix per path command, plus a decision about what smoothing
   means for the sub-pixel engine.

Shape 1 first, and only from a real caller. Neither is planned work.

## Where the record lives now

`doc/REVIEW-PLAN.md` holds the current review and its nine steps, with the measurements behind each
one. `doc/ARCHITECTURE.md` describes how the working parts fit together. This file stays as the
record of a premise that was tested and dropped, so the question is not reopened from the old
tables.
