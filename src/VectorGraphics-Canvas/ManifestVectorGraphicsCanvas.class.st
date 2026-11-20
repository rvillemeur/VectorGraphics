"
The canvas API and the device-independent model it records into. `VGCairoImageSurface` and
`VGCairoContext` answer the selectors of `AeCairoImageSurface` and `AeCairoContext`, which is what
the word *Cairo* means in a class name here: the replacement for that class, not a binding to the
library. No method of this package calls a native function and none names an `Ae*` class, so the
package loads in an image that holds neither Cairo nor Alexandrie.

A context draws nothing. Every call it receives is recorded as an entry in the `VGDisplayList` of
its surface, so two contexts on one surface draw in the order their calls were made, and a backend
decides later what pixels that means.

Two ways in:

- `VGCairoImageSurface class >> extent:format:` answers a surface, and `VGCairoContext class >>
  newFor:` a context recording into it.
- `VGBackend >> drainInto:` hands the recorded list to whatever rasterises or fills it.

Tags:

- `Surface` — the image surface and its pixel format.
- `Context` — the recording context, the state it keeps and the stroke style.
- `Display list` — the list and the two kinds of entry, a fill and a blit.
- `Paint` — what a fill is made of: a colour, a gradient, a surface, a mesh.
- `Pattern` — the Cairo pattern objects that carry a paint across the API.
- `Compositing` — one class per Porter-Duff and blend operator.
- `Matrix` — the affine transformation of the canvas.
- `Export` — the PDF and SVG surfaces, which record and never rasterise.
- `Inventory` — the list of selectors the correspondence with Alexandrie requires.
- `Skeleton` — the root object, the status enumeration and the not-yet-implemented signal.
- `Manifest` — this comment and the Renraku rule configuration.

The reference scan the architecture tests read a package with is `VectorGraphics-Reflection`
since unit 2 of `FONTS-LOAD-PLAN.md`, where it left this package for the same reason the
geometry did: the cairo route reads it and must not load the canvas to do so.

The renderer is `VectorGraphics-Canvas-Raster`, the glyph layer is
`VectorGraphics-Canvas-Fonts` and the path geometry is `VectorGraphics-Canvas-Paths`; this
package names all three. `CANVAS-SPLIT-PLAN.md` holds the split that made the first three and
`FONTS-LOAD-PLAN.md` the unit that took the geometry out, so that a font drawn on cairo loads
a path with no canvas behind it. `VectorGraphics-Canvas-Examples` holds a runnable example per
subject.
"
Class {
	#name : 'ManifestVectorGraphicsCanvas',
	#superclass : 'PackageManifest',
	#category : 'VectorGraphics-Canvas-Manifest',
	#package : 'VectorGraphics-Canvas',
	#tag : 'Manifest'
}
