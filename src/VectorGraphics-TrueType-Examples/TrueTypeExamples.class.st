"
The examples of the font reader: each reads a .ttf file and answers what the reader built from it, so one click shows the font's own data rather than a picture of it.

Only the examples that need no canvas are here. Rendering a glyph to a Form goes through VectorGraphics-Text, so those examples are TextDrawingExamples instead, and this package stays free of the engine.

`defaultFontPath` names the .ttf file the examples read; override it, or pass a path to `loadFontFrom:`, to read another. `newContourFromAbsolutePoints:` builds the contour the hand-made glyph example needs.

## The examples

- `fontMetadata` — the names and metrics the reader found, as a Dictionary
- `characterWidths` — the advance width of each printable ASCII character
- `glyphMap` — the whole TTFontDescription, for its inspector views
- `glyphWithContours` — a TTGlyph built by hand from absolute points, with no file behind it
"
Class {
	#name : 'TrueTypeExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-TrueType-Examples-Examples',
	#package : 'VectorGraphics-TrueType-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
TrueTypeExamples class >> catalogueOfTheInstalledFonts [
	"One click: the fonts of this machine, discovered once and read for what they say about
	 themselves. On this machine 544 files in 138 ms — 362 faces this project draws, 208
	 families, 357 of those faces indexed and five dropped as a second copy of a face already
	 met, and 182 files refused with the reason each one gave.
	 This is the one discovery two registries read: a font manager for the Bloc and Cairo route,
	 FontFamily for the VectorCanvas route. It builds no face of either kind, so nothing here
	 parses a glyph.
	 TrueTypeExamples catalogueOfTheInstalledFonts inspect"

	<sampleInstance>
	| catalogue |
	catalogue := TTFontCatalogue new.
	catalogue scanDefaultDirectories.
	^ catalogue
]

{ #category : 'examples' }
TrueTypeExamples class >> characterWidths [
	"Inspect the advance widths of printable ASCII characters.
	TrueTypeExamples characterWidths inspect"
<sampleInstance>
	| font widths |
	font := self loadFontFrom: self defaultFontPath.
	widths := Dictionary new.
	32 to: 126 do: [ :code |
		| char |
		char := Character value: code.
		widths at: char put: (font widthOf: char) ].
	^ widths
]

{ #category : 'private' }
TrueTypeExamples class >> defaultFontPath [
	"Override this or pass a path directly to loadFontFrom:.
	Set this to the absolute path of any .ttf file on your system."
	^ '/home/renaud/Downloads/Digital7Mono-Yz9J4.ttf'
]

{ #category : 'examples' }
TrueTypeExamples class >> fontMetadata [
	"Load a TTF file and inspect its metadata.
	TrueTypeExamples fontMetadata inspect"
<sampleInstance>
	| font info |
	font := self loadFontFrom: self defaultFontPath.
	info := Dictionary new.
	info at: 'familyName'  put: font familyName.
	info at: 'fullName'    put: font fullName.
	info at: 'emphasis'    put: font emphasis.
	info at: 'copyright'   put: font copyright.
	info at: 'unitsPerEm'  put: font unitsPerEm.
	info at: 'ascent'      put: font ascent.
	info at: 'descent'     put: font descent.
	info at: 'lineGap'     put: font lineGap.
	info at: 'bounds'      put: font bounds.
	^ info
]

{ #category : 'examples' }
TrueTypeExamples class >> fontNamesWithoutParsingGlyphs [
	"One click: the family and the style of every file in the font directories of this machine,
	 read by TTFontMetadataReader — the table directory and three small tables, with no glyph
	 parsed. This is what a font manager needs in order to name every face it can offer, and it
	 is one of the two services Alexandrie takes from FreeType that costs a scan of the whole
	 filesystem. A file the reader refuses is kept with the metadata carrying its reason, because
	 a scan that drops a file silently cannot be read against the directory it walked.
	 TrueTypeExamples fontNamesWithoutParsingGlyphs inspect"

	<sampleInstance>
	| names |
	names := Dictionary new.
	self catalogueOfTheInstalledFonts entries do: [ :each |
		names at: each source fullName put: each metadata ].
	^ names
]

{ #category : 'examples' }
TrueTypeExamples class >> glyphMap [
	"Inspect the font's UTF-8 to glyph map: the Glyph map tab lists every code point the font
	maps and the Map density tab says what those code points cost in floats and index entries.
	TrueTypeExamples glyphMap inspect"
<sampleInstance>
	^ self loadFontFrom: self defaultFontPath
]

{ #category : 'examples' }
TrueTypeExamples class >> glyphWithContours [
	"One glyph object, built from absolute points as the font reader leaves them: an outer
	triangle and an inner one, so the Contours view has two contours to report and the Glyph view
	a shape to draw. A font file holds no glyph object to inspect — the reader flattens every
	glyph into the contour data of its TTFontDescription — so this example builds one.
	boundsBottom holds the highest y of the glyph, which is what topSideBearing answers.
	TrueTypeExamples glyphWithContours inspect"

	<sampleInstance>
	| glyph |
	glyph := TTGlyph new.
	glyph contours: (Array
			 with: (self newContourFromAbsolutePoints: #( #( 0 0 ) #( 600 0 ) #( 300 700 ) ))
			 with: (self newContourFromAbsolutePoints: #( #( 200 100 ) #( 400 100 ) #( 300 400 ) ))).
	glyph advanceWidth: 700.
	glyph
		boundsLeft: 0
		boundsRight: 600
		boundsTop: 0
		boundsBottom: 700.
	^ glyph
]

{ #category : 'private' }
TrueTypeExamples class >> loadFontFrom: aPathString [
	"Load a TTFontDescription from a .ttf file path."
	| bytes |
	bytes := aPathString asFileReference binaryReadStreamDo: [ :s | s contents ].
	^ TTFontReader readTTFFrom: bytes
]

{ #category : 'examples' }
TrueTypeExamples class >> newContourFromAbsolutePoints: anArrayOfPairs [
	"Build one contour of a glyph. Every control point flag is left clear, so each segment is a
	straight line rather than a quadratic Bezier, and the points are already absolute, as the
	font reader leaves them once it has sent makePointsAbsolute."

	| points |
	points := Int16PointArray new: anArrayOfPairs size.
	anArrayOfPairs doWithIndex: [ :pair :index |
		points at: index putX: pair first.
		points at: index putY: pair second ].
	^ TTContourConstruction on: points
]

{ #category : 'examples' }
TrueTypeExamples class >> rejectionReasonsOfTheInstalledFonts [
	"One click: what the scan made of every file the font directories hold, as a count per
	 reason, with nil counting the files it would draw. On this machine: 362 nil, 101
	 #noGlyfTable — OpenType files whose outlines are CFF, which FreeType draws today and this
	 project does not — 3 #fontCollection and 78 #notAnSfntFont, metrics and bitmap fonts that
	 live beside the real ones. Nothing raises over the 544 files, which is the point of the
	 refusal: a catalogue walks a whole directory without a handler.
	 TrueTypeExamples rejectionReasonsOfTheInstalledFonts inspect"

	<sampleInstance>
	| counts |
	counts := Dictionary new.
	self catalogueOfTheInstalledFonts entries do: [ :each |
		| reason |
		reason := each metadata rejectionReason.
		counts at: reason put: (counts at: reason ifAbsent: [ 0 ]) + 1 ].
	^ counts
]

{ #category : 'examples' }
TrueTypeExamples class >> styleCountsOfTheInstalledFonts [
	"One click: how the drawable fonts on this machine classify themselves, as a count for every
	 weight class, width class and slant found. Each fact is read from the font''s own OS/2 and
	 head tables. Alexandrie reaches the same three facts by splitting the style name on spaces
	 and matching the tokens against word lists, so what shows here is information the chain does
	 not have today: a face whose style name says nothing of its width still states its width
	 class. A refused file is left out, and rejectionReasonsOfTheInstalledFonts counts those.
	 TrueTypeExamples styleCountsOfTheInstalledFonts inspect"

	<sampleInstance>
	| counts |
	counts := Dictionary new.
	self catalogueOfTheInstalledFonts entries do: [ :each |
		each metadata isRejected ifFalse: [
			| key |
			key := each styleKey.
			counts at: key put: (counts at: key ifAbsent: [ 0 ]) + 1 ] ].
	^ counts
]
