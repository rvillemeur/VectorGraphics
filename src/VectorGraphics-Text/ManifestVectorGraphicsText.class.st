"
The glue that draws text with the rasteriser: six extension methods that carry a character
through the TrueType chain and hand its contours to an engine. The package defines no class of
its own, which is the point — it is the one place that depends on both `VectorGraphics-Engine`
and `VectorGraphics-TrueType`, and either loads without it.

Two ways in:

- `VectorCanvas >> drawString:from:to:at:font:color:` draws a Pharo string.
- `VectorCanvas >> drawUtf8:at:font:color:` draws UTF-8 bytes, a code point at a time.

Tags:

- `Manifest` — this comment and the Renraku rule configuration, the only class here.

Every method of the package is an extension of a class of another package, and Pharo files an
extension method under the package itself, so no other tag exists.

Section 8 of `doc/ARCHITECTURE.md` describes the two routes to a glyph and which one each of
these methods takes; `VectorGraphics-Text-Examples` draws a string and a single glyph.
"
Class {
	#name : 'ManifestVectorGraphicsText',
	#superclass : 'PackageManifest',
	#category : 'VectorGraphics-Text-Manifest',
	#package : 'VectorGraphics-Text',
	#tag : 'Manifest'
}
