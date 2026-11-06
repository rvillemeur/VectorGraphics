"
The pure-Pharo vector rasteriser: anti-aliased strokes and fills, Bézier curves, arcs and
ellipses. It is a port of the Cuis Smalltalk VectorEngine and it depends on nothing above it —
no Bloc, no Alexandrie, no device — so it loads on its own.

Two ways in:

- `VectorCanvas class >> onForm:` owns the destination `Form` and answers it with `form`.
  It is an `Object`, not a `Canvas` subclass: Morphic is not a target.
- `VectorEngineSubPixel onForm:` draws straight onto a `Form`, with no canvas at all.

Tags:

- `Kernel` — the canvas and the five engine classes, which own the path state and the buffers.
- `Manifest` — this comment and the Renraku rule configuration.

`VectorGraphics-Paths` adds the SVG path letters above this package, and `VectorGraphics-Text`
adds drawing a string with a TrueType font. Sections 1 to 7 and 10 of `doc/ARCHITECTURE.md`
describe the coordinate spaces, the hop loop, the buffers it writes, the blend stage and the
caches; `VectorGraphics-Engine-Examples` holds one runnable example per drawing call.

Original source:
https://github.com/Cuis-Smalltalk/Cuis-Smalltalk-Dev/blob/master/Packages/Features/VectorEnginePlugin.pck.st
"
Class {
	#name : 'ManifestVectorGraphicsEngine',
	#superclass : 'PackageManifest',
	#category : 'VectorGraphics-Engine-Manifest',
	#package : 'VectorGraphics-Engine',
	#tag : 'Manifest'
}
