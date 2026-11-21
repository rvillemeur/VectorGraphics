"
The path geometry of the canvas: a path, the runs it is made of, and the builder that records
one from the construction calls a context makes. Every point is already in device space, because
Cairo transforms a coordinate when the call is made and not when the path is painted, so filling a
path needs no matrix. A path and a run are immutable, which is what `fillPreservingPath` asks for:
one path can be handed to two entries of a display list without either seeing the other's changes.

`VGPathBuilder` flattens every curve into a polyline by recursive subdivision, stopping when the
control points lie within `flatteningTolerance` of the chord, which is how Cairo reads its own
tolerance. `VGPath` answers the edges of its runs, and `VGSubPath` one run and whether it closes.

Two ways in:

- `VGPathBuilder new` records `moveTo:`, `lineTo:`, `curveVia:via:to:` and `closePath`, and
  `path` answers what was built.
- `VGPath class >> subPaths:` builds a path from runs made by `VGSubPath class >> points:closed:`,
  which is the smallest unit of this package that stands alone.

Tags:

- `Path` — the path, its runs and the builder, which is all this package holds.
- `Manifest` — this comment and the Renraku rule configuration.

This package is a leaf: it names no other package of this project. The two methods of `VGPath`
that answer a set of segments are extensions `VectorGraphics-Canvas-Raster` owns, so a path can be
built and measured with no renderer in the image. That is what `FONTS-LOAD-PLAN.md` took it out of
the canvas for: a font drawn through the real Cairo library reads glyph outlines into a builder,
and wants neither the canvas API nor the scan-line renderer behind it.

`VectorGraphics-Canvas-Paths-Examples` holds a runnable example per subject.
"
Class {
	#name : 'ManifestVectorGraphicsCanvasGeometry',
	#superclass : 'PackageManifest',
	#category : 'VectorGraphics-Canvas-Geometry-Manifest',
	#package : 'VectorGraphics-Canvas-Geometry',
	#tag : 'Manifest'
}
