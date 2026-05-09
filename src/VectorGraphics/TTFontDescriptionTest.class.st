Class {
	#name : 'TTFontDescriptionTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Tests',
	#package : 'VectorGraphics',
	#tag : 'Tests'
}

{ #category : 'helpers' }
TTFontDescriptionTest >> makeDescriptionWithFamilyName: family fullName: full subfamilyName: subfamily [

	| fd |
	fd := TTFontDescription new.
	fd setStrings: {
		'Copyright'.
		family.
		subfamily.
		'UniqueID'.
		full.
		'Version 1.0'.
		'PostScript'.
		'Trademark' }.
	^ fd
]

{ #category : 'helpers' }
TTFontDescriptionTest >> makeMinimalDescription [

	"Regular font (familyName = fullName) with mock contour data."

	| fd indexes data |
	fd := self makeDescriptionWithFamilyName: 'TestFamily' fullName: 'TestFamily' subfamilyName: 'Regular'.
	fd setAscent: 800 descent: -200 lineGap: 50.
	indexes := IntegerArray new: 256.
	data := Float32Array new: 10.
	data at: 1 put: 500.0.
	fd instVarNamed: 'contourDataIndexesByUtf8' put: indexes.
	fd instVarNamed: 'contourDataForUtf8' put: data.
	fd instVarNamed: 'letterMTopSideBearing' put: 1000.
	^ fd
]

{ #category : 'tests' }
TTFontDescriptionTest >> testComputeGlyphLayout [

	"letterMTopSideBearing=100, pixelSize=10 → toPixelsScale=0.1.
	left=10, right=90, top=-20, bottom=80."

	| fd layout |
	fd := self makeMinimalDescription.
	fd instVarNamed: 'letterMTopSideBearing' put: 100.
	layout := fd
		          computeGlyphLayoutForLeft: 10
		          right: 90
		          top: -20
		          bottom: 80
		          pixelSize: 10.
	self assert: (layout at: 1) equals: -2.  "leftPixelOffset"
	self assert: (layout at: 2) equals: 11.  "topPixelOffset"
	self assert: (layout at: 3) equals: 14.0. "formWidth"
	self assert: (layout at: 4) equals: 16.0. "formHeight"
	self assert: (layout at: 5) equals: 0.1   "toPixelsScale"
]

{ #category : 'tests' }
TTFontDescriptionTest >> testContourDataPositionFallsBackToOneForUnknown [

	"Index 0 means unknown glyph — falls back to position 1."

	| fd |
	fd := self makeMinimalDescription.
	self assert: (fd contourDataPositionForByte1: 65 byte2: nil byte3: nil byte4: nil) equals: 1
]

{ #category : 'tests' }
TTFontDescriptionTest >> testContourDataPositionKnownAsciiGlyph [

	"Byte 65 ('A') → slot 66 in the index array."

	| fd indexes |
	fd := self makeMinimalDescription.
	indexes := fd instVarNamed: 'contourDataIndexesByUtf8'.
	indexes at: 66 put: 7.
	self assert: (fd contourDataPositionForByte1: 65 byte2: nil byte3: nil byte4: nil) equals: 7
]

{ #category : 'tests' }
TTFontDescriptionTest >> testEmphasisBold [

	| fd |
	fd := self makeDescriptionWithFamilyName: 'MyFont' fullName: 'MyFont Bold' subfamilyName: 'Bold'.
	self assert: fd emphasis equals: 1
]

{ #category : 'tests' }
TTFontDescriptionTest >> testEmphasisBoldItalic [

	| fd |
	fd := self makeDescriptionWithFamilyName: 'MyFont' fullName: 'MyFont Bold Italic' subfamilyName: 'Bold Italic'.
	self assert: fd emphasis equals: 3
]

{ #category : 'tests' }
TTFontDescriptionTest >> testEmphasisItalic [

	| fd |
	fd := self makeDescriptionWithFamilyName: 'MyFont' fullName: 'MyFont Italic' subfamilyName: 'Italic'.
	self assert: fd emphasis equals: 2
]

{ #category : 'tests' }
TTFontDescriptionTest >> testEmphasisOblique [

	| fd |
	fd := self makeDescriptionWithFamilyName: 'MyFont' fullName: 'MyFont Oblique' subfamilyName: 'Oblique'.
	self assert: fd emphasis equals: 2
]

{ #category : 'tests' }
TTFontDescriptionTest >> testEmphasisRegular [

	"familyName = fullName → Regular (emphasis 0)"

	| fd |
	fd := self makeDescriptionWithFamilyName: 'MyFont' fullName: 'MyFont' subfamilyName: 'Regular'.
	self assert: fd emphasis equals: 0
]

{ #category : 'tests' }
TTFontDescriptionTest >> testIncludesAsciiFalseWhenAllUnknown [

	"All indexes are 0 (unknown glyph), so includesAscii is false."

	self deny: self makeMinimalDescription includesAscii
]

{ #category : 'tests' }
TTFontDescriptionTest >> testIncludesAsciiTrueWhenAllPresent [

	| fd indexes |
	fd := self makeMinimalDescription.
	indexes := fd instVarNamed: 'contourDataIndexesByUtf8'.
	33 to: 127 do: [ :cp | indexes at: cp + 1 put: 2 ].
	self assert: fd includesAscii
]

{ #category : 'tests' }
TTFontDescriptionTest >> testIsBaseFont [

	self assert: self makeMinimalDescription isBaseFont.
	self deny: (self makeDescriptionWithFamilyName: 'F' fullName: 'F Bold' subfamilyName: 'Bold') isBaseFont
]

{ #category : 'tests' }
TTFontDescriptionTest >> testLineSpacing [

	"lineSpacing = ascent - descent + lineGap = 800 - (-200) + 50 = 1050"

	self assert: self makeMinimalDescription lineSpacing equals: 1050
]

{ #category : 'tests' }
TTFontDescriptionTest >> testPrintOn [

	| fd stream |
	fd := self makeDescriptionWithFamilyName: 'Test' fullName: 'Test Regular' subfamilyName: 'Regular'.
	stream := WriteStream on: String new.
	fd printOn: stream.
	self assert: (stream contents includesSubstring: 'TTFontDescription').
	self assert: (stream contents includesSubstring: 'Test Regular')
]

{ #category : 'tests' }
TTFontDescriptionTest >> testSetAscentDescentLineGap [

	| fd |
	fd := TTFontDescription new.
	fd setAscent: 700 descent: -150 lineGap: 33.
	self assert: fd ascent equals: 700.
	self assert: fd descent equals: -150.
	self assert: fd lineGap equals: 33
]

{ #category : 'tests' }
TTFontDescriptionTest >> testSetStrings [

	| fd |
	fd := TTFontDescription new.
	fd setStrings: #( 'CR' 'Fam' 'Sub' 'Uniq' 'Full' 'Ver' 'PS' 'TM' ).
	self assert: fd copyright equals: 'CR'.
	self assert: fd familyName equals: 'Fam'.
	self assert: fd subfamilyName equals: 'Sub'.
	self assert: fd uniqueName equals: 'Uniq'.
	self assert: fd fullName equals: 'Full'.
	self assert: fd versionName equals: 'Ver'.
	self assert: fd postscriptName equals: 'PS'.
	self assert: fd trademark equals: 'TM'
]

{ #category : 'tests' }
TTFontDescriptionTest >> testWidthOfKnownGlyph [

	"Set index for 'A' (byte 65, slot 66) → position 3; advanceWidth at 3 = 700."

	| fd indexes data |
	fd := self makeMinimalDescription.
	indexes := fd instVarNamed: 'contourDataIndexesByUtf8'.
	data := fd instVarNamed: 'contourDataForUtf8'.
	indexes at: 66 put: 3.
	data at: 3 put: 700.0.
	self assert: (fd widthOfUtf8Byte1: 65 b2: nil b3: nil b4: nil) equals: 0.7
]

{ #category : 'tests' }
TTFontDescriptionTest >> testWidthOfUnknownGlyphFallsBackToPosition1 [

	"Byte with index 0 → falls back to position 1 (unknown glyph). advanceWidth=500, scale=1000 → 0.5"

	| fd |
	fd := self makeMinimalDescription.
	self assert: (fd widthOfUtf8Byte1: 65 b2: nil b3: nil b4: nil) equals: 0.5
]
