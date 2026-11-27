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
	#classVars : [
		'DefaultFontPath'
	],
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

{ #category : 'examples - cff' }
TrueTypeExamples class >> cffCubicCurve [
	"One cubic curve of a glyph outline, deep enough that no single quadratic holds it: a
	bowl three hundred units wide and three hundred tall. A TrueType glyph has to hold it
	in quadratics, and the Quadratics view shows the chain it is split into.

	TrueTypeExamples cffCubicCurve inspect"

	<sampleInstance>
	^ TTCffCubic
		  from: 0 @ 0
		  via: 0 @ 300
		  and: 300 @ 300
		  to: 300 @ 0
]

{ #category : 'examples - cff' }
TrueTypeExamples class >> cffGlyph [
	"The glyph the example table draws, built the way a face builds one: the charstring is
	read, its cubics are held in quadratics, and the box is computed from the points,
	since a CFF font states no box of its own for a glyph.

	TrueTypeExamples cffGlyph inspect"

	<sampleInstance>
	| bytes |
	bytes := #[ 1 0 4 2 0 1 1 1 8 70 105 120 116 117 114 101 0 1 1 1 6 169 17 145 193 18 0 0
		            0 0 0 1 1 1 20 189 139 21 248 36 6 239 247 92 239 239 247 92 39 8 252 236 6
		            14 248 116 20 247 15 21 0 0 ] asByteArray.
	^ ((TTCffTableParser on: (TTFontTableDirEntry onBytes: bytes)) process
		   glyphAt: 1)
]

{ #category : 'examples - cff' }
TrueTypeExamples class >> cffGlyphContour [
	"The one contour the example glyph draws: where it starts, and the line, curve and line
	that bring it back. Every point of it is absolute and in font units, which is what the
	interpreter adds up from the steps the charstring states.

	TrueTypeExamples cffGlyphContour inspect"

	<sampleInstance>
	^ self cffGlyphInterpreter contours first
]

{ #category : 'examples - cff' }
TrueTypeExamples class >> cffGlyphInterpreter [
	"The interpreter of one glyph, stopped where it finished drawing. The glyph is a line, a
	cubic curve and a line back, written as a Type 2 charstring in a table built here
	rather than read from a font.

	The charstring says '50 0 rmoveto 400 hlineto 100 200 100 100 200 -100 rrcurveto -600
	hlineto endchar': every number is a step from the point before, and endchar closes the
	contour that rmoveto opened.

	TrueTypeExamples cffGlyphInterpreter inspect"

	<sampleInstance>
	| bytes table interpreter |
	bytes := #[ 1 0 4 2 0 1 1 1 8 70 105 120 116 117 114 101 0 1 1 1 6 169 17 145 193 18 0 0
		            0 0 0 1 1 1 20 189 139 21 248 36 6 239 247 92 239 239 247 92 39 8 252 236 6
		            14 248 116 20 247 15 21 0 0 ] asByteArray.
	table := (TTCffTableParser on: (TTFontTableDirEntry onBytes: bytes)) process.
	interpreter := TTCffCharstringInterpreter on: table.
	interpreter contoursOfGlyphAt: 1.
	^ interpreter
]

{ #category : 'examples - cff' }
TrueTypeExamples class >> cffGlyphOutlineBuilder [
	"A builder drawn in by hand, as the interpreter draws in one: a move opens a contour, a
	line and a curve are drawn in it, and a second move closes it and opens another. The
	steps are relative and the contours answered are absolute.

	TrueTypeExamples cffGlyphOutlineBuilder inspect"

	<sampleInstance>
	| builder |
	builder := TTCffOutlineBuilder new.
	builder moveBy: 100 @ 100.
	builder lineBy: 300 @ 0.
	builder curveBy: 100 @ 100 by: 0 @ 100 by: -100 @ 100.
	builder lineBy: -300 @ 0.
	builder moveBy: 0 @ 400.
	builder lineBy: 200 @ 0.
	builder lineBy: 0 @ 200.
	builder closeContour.
	^ builder
]

{ #category : 'examples' }
TrueTypeExamples class >> cffGlyphRecordNotYetDrawn [
	"The record a face holds for one glyph of an OpenType font: it knows its table and its
	 index, and it interprets its charstring the first time somebody asks for its shape. A
	 face of four thousand glyphs holds four thousand of these and reads none of them, which
	 is what makes opening the face cheap. The hmtx table still fills in every advance width,
	 because that costs no charstring.
	 The inspector reads the record without drawing it; send #contours to see it drawn.

	 TrueTypeExamples cffGlyphRecordNotYetDrawn inspect"

	<sampleInstance>
	^ TTCffGlyph onTable: self cffTableOfATwoGlyphFont index: 2
]

{ #category : 'examples - cff' }
TrueTypeExamples class >> cffGlyphSource [
	"The glyph source of a real OpenType font, whose outlines are charstrings in a CFF table
	 rather than points in glyf. The same factory reads it, so a face cannot tell the two
	 formats apart, and the Glyphs tab says of every glyph whether its charstring has been
	 interpreted yet: opening the font interprets none of them.
	 Answers nil on a machine with no font carrying a CFF table of Type 2 charstrings. The .otf
	 files of a distribution can all be CFF2, a format this reader does not read.
	TrueTypeExamples cffGlyphSource inspect"

	<sampleInstance>
	<needsAFontThisMachineMayLack: 'an installed font with a CFF table of Type 2 charstrings'>
	| path |
	path := self openTypeFontPath.
	path ifNil: [ ^ nil ].
	^ self glyphSourceForFontBytes:
		  (path asFileReference binaryReadStreamDo: [ :stream | stream contents ])
]

{ #category : 'examples - cff' }
TrueTypeExamples class >> cffIndexOfThreeElements [
	"One CFF INDEX, read from bytes written here rather than from a font: three elements of one,
	two and three bytes. Every list inside a CFF table is an INDEX of this shape, so this is the
	structure the Elements view reports.

	TrueTypeExamples cffIndexOfThreeElements inspect"

	<sampleInstance>
	| bytes |
	bytes := #[ 0 3 1 1 2 4 7 65 66 67 68 69 70 ] asByteArray.
	^ TTCffIndex readFrom: (TTFontTableDirEntry onBytes: bytes)
]

{ #category : 'examples - cff' }
TrueTypeExamples class >> cffTableOfATwoGlyphFont [
	"A whole CFF table, written here rather than read from a font: two charstrings, a private
	dictionary that states both widths, one local subroutine and one global one. This is the
	shape an .otf file holds its outlines in, where a .ttf holds them in glyf and loca.

	The table is read without a single charstring being interpreted, which is what reading a
	face of four thousand glyphs has to cost.

	TrueTypeExamples cffTableOfATwoGlyphFont inspect"

	<sampleInstance>
	| bytes |
	bytes := #[ 1 0 4 2 0 1 1 1 8 70 105 120 116 117 114 101 0 1 1 1 13 139 139 248 136 249 80
		            5 181 17 147 191 18 0 0 0 1 1 1 3 10 11 0 2 1 1 2 5 14 139 139 14 248 116 20
		            247 15 21 147 19 0 1 1 1 2 11 ] asByteArray.
	^ (TTCffTableParser on: (TTFontTableDirEntry onBytes: bytes)) process
]

{ #category : 'examples - cff' }
TrueTypeExamples class >> cffTopDictionaryOfASmallFont [
	"One CFF top dictionary, read from bytes written here rather than from a font: the font matrix
	of a thousand-unit em, the font bounding box, where the charset is and where the charstrings
	are. The operands come before their operator in the bytes, which is why a dictionary has to
	be read before it can be asked anything.

	TrueTypeExamples cffTopDictionaryOfASmallFont inspect"

	<sampleInstance>
	| bytes |
	bytes := #[ 30 10 0 31 139 139 30 10 0 31 139 139 12 7 251 92 251 92 250 124 250 24 5 139 15
		            28 4 210 17 ] asByteArray.
	^ TTCffDictionary readFrom: bytes
]

{ #category : 'examples - catalogue' }
TrueTypeExamples class >> characterMapOfAFormatTwelveFont [
	"One click: the character map of a font whose only subtable is of format 12, segmented
	 coverage. DroidSansJapanese.ttf is such a font on this machine: one subtable, platform 3
	 encoding 10, format 12, 6619 code points mapped out of a map 65440 long, and no Latin at
	 all — its first group starts at U+203E. Hiragana a, U+3042, answers glyph 26.
	 A reader with no such font installed gets nil, which is the answer and not a failure.

	 TrueTypeExamples characterMapOfAFormatTwelveFont inspect"

	<sampleInstance>
	<needsAFontThisMachineMayLack: 'DroidSansJapanese.ttf, or another font whose character map is of format 12'>
	| path directory |
	"The finder lowercases the name it compares, so the name asked for is lowercase too."
	path := self installedFontPathEndingWith: 'droidsansjapanese.ttf'.
	path ifNil: [ ^ nil ].
	directory := TTFontReader
		             buildTableDirectory: path asFileReference binaryReadStream contents
		             offset: 0.
	^ (TTCmapTableParser on: (directory at: 'cmap')) process
]

{ #category : 'examples - catalogue' }
TrueTypeExamples class >> characterMapsOfTheInstalledFonts [
	"One click: the character map every font of this machine carries, as a count per platform
	 and encoding pair over the faces the scan would draw. On this machine, of 462 faces, eleven shapes, and 22
	 faces carry Windows subtables and no subtable of platform 0 at all: 20 of them (3 -> 1)
	 alone, one both (3 -> 1) and (3 -> 10), one (3 -> 10) alone. That is why this reader takes
	 the Windows platform as Unicode and not only platform 0 — the Droid and the Open Sans
	 families are those 22, and every one of them was refused before. The last of them,
	 DroidSansJapanese.ttf, carries its one subtable in format 12; since that format is read
	 too, every one of the 462 faces answers a map.

	 Inspect a parser of the list to see the subtable rows of one font.

	 TrueTypeExamples characterMapsOfTheInstalledFonts inspect"

	<sampleInstance>
	| counts |
	counts := Dictionary new.
	(self catalogueOfTheInstalledFonts entries reject: [ :each | each isRejected ]) do: [ :entry |
		| directory cmap |
		directory := TTFontReader buildTableDirectory: entry bytes offset: 0.
		cmap := directory at: 'cmap' ifAbsent: [ nil ].
		cmap ifNotNil: [ | pairs |
			pairs := ((TTCmapTableParser on: cmap) subtableDescriptions collect: [ :each |
				          each first -> each second ]) asArray.
			counts at: pairs put: (counts at: pairs ifAbsent: [ 0 ]) + 1 ] ].
	^ counts
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

{ #category : 'examples' }
TrueTypeExamples class >> defaultFontChoice [
	"Why the examples draw with the font they draw with: the families they ask for, which of
	 them this machine installed, and the path the choice lands on."

	<sampleInstance>
	| catalogue choice |
	catalogue := TTFontCatalogue new
		             scanDefaultDirectories;
		             yourself.
	choice := Dictionary new.
	choice at: 'asked for' put: self preferredFontFamilyNames.
	choice
		at: 'installed here'
		put: (self installedPreferredFamilyNamesIn: catalogue).
	choice at: 'drawable faces found' put: catalogue drawableEntries size.
	choice at: 'chosen' put: self findDefaultFontPath.
	^ choice
]

{ #category : 'accessing' }
TrueTypeExamples class >> defaultFontPath [
	"The absolute path of a font the examples draw with: the plainest face of the best-placed
	 family of preferredFontFamilyNames this machine has, or any drawable face a scan meets when
	 it has none of them. Found once and kept, since a scan costs some 85 ms and every example
	 that draws asks for it. A kept path that no longer names a file is found again, so an
	 uninstalled font or an image carried to another machine needs nothing done; send
	 forgetDefaultFontPath to look again for any other reason, or defaultFontPath: to draw with
	 a font of your own."

	(DefaultFontPath isNil or: [ DefaultFontPath asFileReference exists not ])
		ifTrue: [ DefaultFontPath := self findDefaultFontPath ].
	^ DefaultFontPath
]

{ #category : 'accessing' }
TrueTypeExamples class >> defaultFontPath: aString [
	"Draw with this font from now on, in place of the one I would find. The door the comment of
	 defaultFontPath points at: a reader trying another face sets it here rather than editing an
	 example. A path that names no file is dropped at the next asking."

	DefaultFontPath := aString
]

{ #category : 'accessing' }
TrueTypeExamples class >> findDefaultFontPath [
	"Scan this machine''s font directories and answer the path of the face the examples should
	 draw with: the plainest face of the best-placed family of preferredFontFamilyNames it has,
	 or any drawable face otherwise."

	| catalogue found |
	catalogue := TTFontCatalogue new
		             scanDefaultDirectories;
		             yourself.
	found := (self installedPreferredFamilyNamesIn: catalogue)
		         ifNotEmpty: [ :names |
			         catalogue entryOfFamilyNamed: names first ]
		         ifEmpty: [ catalogue drawableEntries ifNotEmpty: [ :all | all first ] ].
	found ifNil: [
		^ self error: 'no drawable font in the default font directories' ].
	^ found source fullName
]

{ #category : 'support' }
TrueTypeExamples class >> font: aFileReference holdsTableNamed: aTableTag [
	"Whether this file is an sfnt font carrying this table. Only the offset table and one record
	 per table are read, not the glyphs. A file that is not a font at all, or one this reader
	 cannot even index, is a no and not a failure: the question asked is which fonts of a
	 machine a reader can use, and the directories hold licence files and caches too."

	^ [
	  (aFileReference binaryReadStreamDo: [ :stream |
		   TTFontReader buildTableDirectory: stream contents offset: 0 ])
		  includesKey: aTableTag ]
		  on: Error
		  do: [ :error | false ]
]

{ #category : 'examples' }
TrueTypeExamples class >> fontFaceOfThisMachine [
	"One click: the plain face of the family the examples draw with, as a family holds it —
	 named, placed, and not read. Inspect it, then send it ttFontDescription and inspect it
	 again to see the outlines appear.

	TrueTypeExamples fontFaceOfThisMachine inspect"

	<sampleInstance>
	| family |
	family := self fontFamilyOfThisMachine.
	^ TTFamilyFace catalogueEntry: (family catalogueEntryForEmphasis: 0)
]

{ #category : 'examples' }
TrueTypeExamples class >> fontFamilyOfThisMachine [
	"One click: the family of the font the examples draw with, taken from this machine's own
	 fonts the way an installation takes it — the plainest face as the base, the bold and the
	 italic ones filed by emphasis, and not one of them parsed yet. Inspect its faces to see
	 which of them have been read, then ask it for a font and look again.

	TrueTypeExamples fontFamilyOfThisMachine inspect"

	<sampleInstance>
	| catalogue names |
	catalogue := TTFontCatalogue new
		             scanDefaultDirectories;
		             yourself.
	names := self installedPreferredFamilyNamesIn: catalogue.
	^ TrueTypeFontFamily
		  fromCatalogue: catalogue
		  familyNamed: (names ifEmpty: [ catalogue familyNames ]) first
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

{ #category : 'initialization' }
TrueTypeExamples class >> forgetDefaultFontPath [
	"Throw away the path I found, so the next asker scans the font directories again. The
	 fonts of a machine change while an image runs, and the image itself can be carried to
	 another machine."

	DefaultFontPath := nil
]

{ #category : 'examples' }
TrueTypeExamples class >> glyfGlyphSource [
	"The glyph source of a real TrueType font: the records of the glyf and loca tables, one per
	 glyph, with the advance width hmtx holds already filled in. Inspect it, then read the
	 Glyphs tab: every row is a glyph as the font wrote it, in font units, and a composite row
	 says so rather than pretending to own its points.
	 Answers nil on a machine with no .ttf file installed.
	TrueTypeExamples glyfGlyphSource inspect"

	<sampleInstance>
	| path |
	path := self trueTypeFontPath.
	path ifNil: [ ^ nil ].
	^ self glyphSourceForFontBytes:
		  (path asFileReference binaryReadStreamDo: [ :stream | stream contents ])
]

{ #category : 'examples' }
TrueTypeExamples class >> glyphMap [
	"Inspect the font's UTF-8 to glyph map: the Glyph map tab lists every code point the font
	maps and the Map density tab says what those code points cost in floats and index entries.
	TrueTypeExamples glyphMap inspect"
<sampleInstance>
	^ self loadFontFrom: self defaultFontPath
]

{ #category : 'support' }
TrueTypeExamples class >> glyphSourceForFontBytes: aByteArray [
	"The glyph source of a font, built the way VGFontFace builds one: the table directory of
	 the bytes, the glyph count maxp states, the loca format head states, then the advances
	 hmtx holds. Whether the outlines are in glyf or in a CFF table is the business of the
	 factory, so these three lines read either format."

	| tables source |
	tables := TTFontReader buildTableDirectory: aByteArray offset: 0.
	source := TTGlyphSource
		          on: tables
		          count: (TTMaxpTableParser on: (tables at: 'maxp')) process
		          indexToLocFormat:
		          ((TTHeadTableParser on: (tables at: 'head')) process at: #indexToLocFormat).
	source
		fillAdvancesFrom: tables
		numHMetrics:
			((TTHheaTableParser on: (tables at: 'hhea')) process at: #numHMetrics).
	^ source
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

{ #category : 'support' }
TrueTypeExamples class >> installedFontPathEndingWith: anExtensionString [
	"The absolute path of the first installed font file whose name ends with this extension,
	 or nil when this machine has none. The examples of the reader need a font of a stated
	 format: .ttf keeps its outlines in glyf, .otf keeps them in a CFF table, and
	 defaultFontPath answers whichever of the two the preferred families lead to, which on
	 this machine is a .otf."

	^ self installedFontPathSuchThat: [ :file |
		  file basename asLowercase endsWith: anExtensionString ]
]

{ #category : 'support' }
TrueTypeExamples class >> installedFontPathEndingWith: anExtensionString holdingTableNamed: aTableTag [
	"The absolute path of the first installed font named for this format and carrying this table,
	 or nil when this machine has none. The name narrows the candidates so that the table
	 directory of every font on the machine need not be read."

	^ self installedFontPathSuchThat: [ :file |
		  (file basename asLowercase endsWith: anExtensionString) and: [
			  self font: file holdsTableNamed: aTableTag ] ]
]

{ #category : 'support' }
TrueTypeExamples class >> installedFontPathSuchThat: aBlock [
	"The absolute path of the first installed font file this block accepts, or nil when this
	 machine has none. The directories are the ones the catalogue scans. Two questions are asked
	 of a candidate — its name, and the tables it carries — and both walk the same files."

	TTFontCatalogue defaultFontDirectories do: [ :each |
		| directory |
		directory := each asFileReference.
		directory exists ifTrue: [
			directory allFiles do: [ :file |
				(aBlock value: file) ifTrue: [ ^ file fullName ] ] ] ].
	^ nil
]

{ #category : 'accessing' }
TrueTypeExamples class >> installedPreferredFamilyNamesIn: aCatalogue [
	"Which of preferredFontFamilyNames that catalogue holds, best first. The one rule for what
	 the examples would rather draw with, asked by the choice, by the example that shows it and
	 by the test that pins it."

	^ self preferredFontFamilyNames select: [ :each |
		  (aCatalogue entryOfFamilyNamed: each) isNotNil ]
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

{ #category : 'support' }
TrueTypeExamples class >> openTypeFontPath [
	"The path of an installed font whose outlines are charstrings in a CFF table, or nil when
	 this machine has none. The extension alone is not the rule: a .otf file can hold CFF2, a
	 format this reader does not read, and answering such a file made every CFF example fail on
	 the missing table instead of showing what it means to show. Cantarell-VF.otf, the only .otf
	 of the machine this was written on, is such a font."

	^ self installedFontPathEndingWith: '.otf' holdingTableNamed: 'CFF '
]

{ #category : 'accessing' }
TrueTypeExamples class >> preferredFontFamilyNames [
	"The families the examples would rather draw with, best first. The first two are the faces
	 Pharo itself defaults to, through AeFontManager defaultFontFamilyName and
	 defaultCodeFontFamilyName; they ship inside the image rather than in a font directory, so
	 a scan finds them only on a machine that installed them as well. The rest are the text
	 families a desktop usually carries. Every one of them maps the Latin letters and digits the
	 examples draw, which an icon font does not."

	^ #( 'Source Sans Pro' 'Source Code Pro' 'DejaVu Sans' 'Liberation Sans'
	     'Noto Sans' )
]

{ #category : 'examples' }
TrueTypeExamples class >> rejectionReasonsOfTheInstalledFonts [
	"One click: what the scan made of every file the font directories hold, as a count per
	 reason, with nil counting the files it would draw. On this machine: 462 nil — 362 TrueType
	 files and 100 OpenType files, whose outlines are CFF and which this project draws since
	 FONT-PLAN section 8 — 1 #noOutlineTable, 3 #fontCollection and 78 #notAnSfntFont, metrics
	 and bitmap fonts that live beside the real ones. A CID-keyed font would count as
	 #cidKeyedFont; this machine has none. Nothing raises over the 544 files, which is the
	 point of the refusal: a catalogue walks a whole directory without a handler.

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
			key := each style.
			counts at: key put: (counts at: key ifAbsent: [ 0 ]) + 1 ] ].
	^ counts
]

{ #category : 'examples' }
TrueTypeExamples class >> styleOfTheBoldestFaceOfThisMachine [
	"One click: the style of the heaviest face installed here — the slant, weight class and
	 width class that face states, as the one object a catalogue keys a family by. The faces of
	 this machine are read for what they say about themselves and the heaviest one wins; a tie
	 goes to the first face met.
	 TrueTypeExamples styleOfTheBoldestFaceOfThisMachine inspect"
	<sampleInstance>
	| styles |
	styles := self catalogueOfTheInstalledFonts drawableEntries collect: [ :each |
		          each style ].
	^ styles inject: TTFontStyle plainest into: [ :boldest :each |
		  each weightClass > boldest weightClass
			  ifTrue: [ each ]
			  ifFalse: [ boldest ] ]
]

{ #category : 'support' }
TrueTypeExamples class >> trueTypeFontPath [
	"The path of an installed font whose outlines are points in the glyf table."

	^ self installedFontPathEndingWith: '.ttf'
]
