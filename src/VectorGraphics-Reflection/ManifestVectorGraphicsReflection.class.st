"
The reference scan: `VGCairoReferenceScanner` reads the compiled methods of a package and answers
which classes of another project they name. It reads the literals of a method, blocks included,
not the class the method is installed on, so it answers what a package would drag into an image
rather than what it is filed under.

Two ways in:

- `VGCairoReferenceScanner default` scans this project for the Cairo classes it must not name.
  The answer is empty, which is what makes the failover real.
- `offendersIn:naming:` answers the methods of one package that name one set of classes, which
  is what the architecture gate and the backend selection tests ask it.

Tags:

- `Reflection` — the scanner, which is all this package holds.
- `Manifest` — this comment and the Renraku rule configuration.

This package is a leaf: it names no other package of this project, so every layer may require
it. It left `VectorGraphics-Canvas` in unit 2 of `FONTS-LOAD-PLAN.md`, because the cairo route
reads the scan through `VGFontCanvas class >> upstreamCairoRows` and must not load the canvas to
do so. `VectorGraphics-Reflection-Examples` holds a runnable example per subject.
"
Class {
	#name : 'ManifestVectorGraphicsReflection',
	#superclass : 'PackageManifest',
	#category : 'VectorGraphics-Reflection-Manifest',
	#package : 'VectorGraphics-Reflection',
	#tag : 'Manifest'
}
