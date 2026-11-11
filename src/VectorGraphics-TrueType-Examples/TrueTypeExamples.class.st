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

{ #category : 'constants' }
TrueTypeExamples class >> fontDirectories [
	"Where this machine keeps its fonts. Unit 1.4 of FONT-PLAN.md gives TTFontCatalogue the
	 scan and this list with it; until that exists the list lives here, so that the example
	 below runs with one click rather than needing a path typed into it."

	^ {
		  (FileLocator home / '.fonts').
		  (FileLocator home / '.local/share/fonts').
		  '/usr/share/fonts' asFileReference.
		  '/usr/local/share/fonts' asFileReference.
		  (FileLocator imageDirectory / 'Fonts') }
]

{ #category : 'examples' }
TrueTypeExamples class >> fontFiles [
	"Every TrueType file this machine holds, in the directories above. Unit 1.4 of FONT-PLAN.md
	 moves the walk into TTFontCatalogue; it lives here so the examples below run with one click."

	^ Array streamContents: [ :stream |
		  self fontDirectories do: [ :directory |
			  directory exists ifTrue: [
				  directory allChildren do: [ :each |
					  (each isFile and: [
						   each basename asLowercase endsWith: '.ttf' ]) ifTrue: [
						  stream nextPut: each ] ] ] ] ]
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
	"One click: the family and the style of every TrueType file on this machine, read by
	 TTFontMetadataReader — the table directory and three small tables, with no glyph parsed.
	 This is what a font manager needs in order to name every face it can offer, and it is one of
	 the two services Alexandrie takes from FreeType that costs a scan of the whole filesystem. A
	 file the reader refuses is kept with the reason it gave, because a scan that drops a file
	 silently cannot be read against the directory it walked.
	 TrueTypeExamples fontNamesWithoutParsingGlyphs inspect"

	<sampleInstance>
	| names |
	names := Dictionary new.
	self fontFiles do: [ :each |
		names at: each fullName put: (self metadataOrReasonFor: each) ].
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

{ #category : 'private' }
TrueTypeExamples class >> metadataOrReasonFor: aFileReference [
	"The metadata of one font file, or the message of the error reading it raised. The reader
	 pulls the offset table, the directory and the name table off the stream, so a 2 MB font
	 costs a few hundred bytes of disk. Unit 1.3 of FONT-PLAN.md gives the reader a refusal
	 that answers a reason instead of raising, and this handler goes when it lands; until then
	 a file the reader cannot read must still be named here, with what it said, rather than
	 stopping the scan."

	^ [ aFileReference binaryReadStreamDo: [ :stream |
		  TTFontMetadataReader readStream: stream ] ]
		  on: Error
		  do: [ :error | error messageText ]
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
TrueTypeExamples class >> styleCountsOfTheInstalledFonts [
	"One click: how the fonts on this machine classify themselves, as a count for every weight
	 class, width class and slant found. Each fact is read from the font's own OS/2 and head
	 tables. Alexandrie reaches the same three facts by splitting the style name on spaces and
	 matching the tokens against word lists, so what shows here is information the chain does not
	 have today: a face whose style name says nothing of its width still states its width class.
	 TrueTypeExamples styleCountsOfTheInstalledFonts inspect"

	<sampleInstance>
	| counts |
	counts := Dictionary new.
	self fontFiles do: [ :each |
		| metadata |
		metadata := self metadataOrReasonFor: each.
		metadata isString ifFalse: [
			| key |
			key := {
				       metadata weightClass.
				       metadata widthClass.
				       metadata slant }.
			counts at: key put: (counts at: key ifAbsent: [ 0 ]) + 1 ] ].
	^ counts
]
