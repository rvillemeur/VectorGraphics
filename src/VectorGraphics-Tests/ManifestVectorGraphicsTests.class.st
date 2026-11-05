"
The abstract documentation gate the four code packages' suites subclass:
`VectorGraphicsDocumentationTest`. It holds each package comment to the package's real tags, runs
every example of the package's sibling `-Examples` package, builds every inspector view of the
classes a subclass names, and holds `doc/ARCHITECTURE.md` to the image — every backticked name
must exist and every method it names must be implemented by the class it names.

It lives in a package of its own so that no code package is depended on for a test parent, and so
that a test class sits in a package whose name ends in `-Tests`, which is what Pharo's tools and
Renraku expect.

Tags:

- `Tests` — the abstract gate. Its four concrete subclasses live in the four code packages' own test packages.
- `Manifest` — this comment and the Renraku rule configuration.
"
Class {
	#name : 'ManifestVectorGraphicsTests',
	#superclass : 'PackageManifest',
	#category : 'VectorGraphics-Tests-Manifest',
	#package : 'VectorGraphics-Tests',
	#tag : 'Manifest'
}
