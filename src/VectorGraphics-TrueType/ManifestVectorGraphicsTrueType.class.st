"
Reading an sfnt font: the table parsers of a `.ttf` or an `.otf` file, the glyphs and metrics
they yield, and the font classes a caller asks for a face by name. No rendering happens here — a
glyph is contours and advance widths until `VectorGraphics-Text` draws it.

Two ways in:

- `FontFamily class >> familyName:pointSize:` answers a `TrueTypeFont` for an installed family.
- `TTFontReader class >> readTTFFrom:` reads one font file's bytes into a `TTFontDescription`.

Tags:

- `Reading` — one parser per sfnt table, and the directory entry that locates each.
- `CFF` — the INDEXes, dictionaries and Type 2 charstrings of a `CFF ` table, where an `.otf` file holds the outlines a `.ttf` holds in `glyf` and `loca`.
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

{ #category : 'architecture' }
ManifestVectorGraphicsTrueType class >> archDocEntryPoints [
	"Where a reader of this package starts, in the order to read them, which is the prose of my
	 comment said in a form a tool can read. Forty-four classes are too many to meet at once:
	 the family is what a caller asks for a font by name, the reader is what turns bytes into a
	 description, the description is what the rest of the project draws from, and the glyph is
	 the one object a reader must understand before any table parser makes sense."

	^ #( #FontFamily #TTFontReader #TTFontDescription #TTGlyph )
]
