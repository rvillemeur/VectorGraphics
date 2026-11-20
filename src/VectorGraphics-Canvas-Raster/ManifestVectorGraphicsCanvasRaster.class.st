"
The software renderer: what turns the display list of `VectorGraphics-Canvas` into pixels. It needs
no device, no library and no window, which is the point — it is the failover path when a device
backend refuses, and the oracle the Vulkan backend is compared against.

`VGBackend` is the abstract backend and `VGSoftwareBackend` the one here. `isCandidate` says
whether a backend stands for selection in the image it finds itself in, and `probe` answers the
backend itself, which for this one needs nothing and so never fails. `VGRasteriser`
scan-converts a fill, `VGSpanScanner` walks the spans of one scan line, `VGEdgeIndex` holds the
edges a span crosses, and `VGClip` is the clip they are tested against.

Two ways in:

- `VGSoftwareBackend >> drainInto:` draws a whole display list into a form.
- `VGRasteriser class >> segments:fillRule:clip:` rasterises one set of segments, which is the
  smallest unit of this package that stands alone.

Tags:

- `Backend` — the abstract backend, its failure, and the software one.
- `Rasterising` — the rasteriser, the span scanner, the edge index and the clip.
- `Path` — `VGStroker` and `VGSegments`, the stroke geometry a fill is made from.
- `Paint` — `VGMeshRaster` and `VGCoonsPatch`, the mesh a gradient patch is rasterised as.
- `Blur` — the A8 Gaussian filter, which blurs a mask and nothing else.
- `Display list` — `VGCairoSurfaceMask`, the mask entry a drain writes through.
- `Manifest` — this comment and the Renraku rule configuration.

Four methods of this package read a class of `VectorGraphics-Canvas`: three convenience
constructors reading a default state, and one colour conversion. That edge is a cycle, declared
rather than hidden, and section 8 of `CANVAS-SPLIT-PLAN.md` is the plan to remove it.
`VectorGraphics-Canvas-Raster-Examples` holds a runnable example per subject.
"
Class {
	#name : 'ManifestVectorGraphicsCanvasRaster',
	#superclass : 'PackageManifest',
	#category : 'VectorGraphics-Canvas-Raster-Manifest',
	#package : 'VectorGraphics-Canvas-Raster',
	#tag : 'Manifest'
}
