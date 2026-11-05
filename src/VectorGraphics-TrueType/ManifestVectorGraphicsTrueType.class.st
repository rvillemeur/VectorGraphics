"
Reading a TrueType font: the `.ttf` table parsers, the glyphs and metrics they yield, and the
font classes a caller asks for a face by name. No rendering happens here — a glyph is contours
and advance widths until `VectorGraphics-Text` draws it.

Two ways in:

- `FontFamily class >> familyName:pointSize:` answers a `TrueTypeFont` for an installed family.
- `TTFontReader class >> readTTFFrom:` reads one font file's bytes into a `TTFontDescription`.

Tags:

- `Reading` — one parser per `.ttf` table, and the directory entry that locates each.
- `Fonts` — the font and family classes, and the description that caches a file's glyphs.
- `Glyphs` — a glyph's contours, composite glyphs, kern pairs and the point arrays they use.
- `Manifest` — this comment and the Renraku rule configuration.

Sections 8 to 10 of `doc/ARCHITECTURE.md` describe the chain from a character to a glyph and the
four caches on it, with the class variables that hold them;
`VectorGraphics-TrueType-Examples` reads a real font from the system.
"
Class {
	#name : 'ManifestVectorGraphicsTrueType',
	#superclass : 'PackageManifest',
	#category : 'VectorGraphics-TrueType-Manifest',
	#package : 'VectorGraphics-TrueType',
	#tag : 'Manifest'
}
