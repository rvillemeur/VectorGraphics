"
I read the `CFF ` table of an `.otf` file: the header, the INDEX of font names, the INDEX of top dictionaries, the INDEX of strings and the INDEX of global subroutines, then the charstrings, the private dictionary and the local subroutines the top dictionary points at.

I read no charstring while I do that. A charstring is interpreted when a glyph is asked for, because a font holds thousands of them and a page draws dozens: `process` answers me, and I answer a glyph one at a time.

A CID-keyed font reaches its glyphs through an FDArray and an FDSelect rather than through one private dictionary. I refuse one with a TTCffError that says so, instead of reading it as if it were not.

Offsets inside a CFF table count from the first byte of the table, except the offset of the local subroutines, which counts from the first byte of the private dictionary.
"
Class {
	#name : 'TTCffTableParser',
	#superclass : 'TTFontParser',
	#instVars : [
		'tableStart',
		'topDictionary',
		'privateDictionary',
		'charstrings',
		'globalSubrs',
		'localSubrs',
		'charsetIdentifiers'
	],
	#category : 'VectorGraphics-TrueType-CFF',
	#package : 'VectorGraphics-TrueType',
	#tag : 'CFF'
}

{ #category : 'operators' }
TTCffTableParser class >> charStringsOperator [
	"The top dictionary entry that says where the charstrings are."

	^ 17
]

{ #category : 'operators' }
TTCffTableParser class >> charsetOperator [
	"The operator the top dictionary names the charset by."

	^ 15
]

{ #category : 'operators' }
TTCffTableParser class >> defaultWidthXOperator [
	"The private dictionary entry that says the advance width of a glyph whose charstring
	 states none."

	^ 20
]

{ #category : 'testing' }
TTCffTableParser class >> isKeyedByCharacterIdentifiers: anEntry [
	"Whether this table belongs to a CID-keyed font, read from its top dictionary alone. The
	 header, the font names and that dictionary are the first bytes of a CFF table, so a
	 reader that classifies a face answers the question from a prefix of a table that is
	 megabytes."

	^ (self on: anEntry) readTopDictionary includesOperator:
		  self registryOrderingSupplementOperator
]

{ #category : 'operators' }
TTCffTableParser class >> nominalWidthXOperator [
	"The private dictionary entry that says what a width stated by a charstring is counted from."

	^ 21
]

{ #category : 'operators' }
TTCffTableParser class >> privateOperator [
	"The top dictionary entry that says how big the private dictionary is and where it starts."

	^ 18
]

{ #category : 'constants' }
TTCffTableParser class >> quadraticTolerance [
	"How far, in font units, a quadratic curve may stray from the cubic it replaces. A font
	 unit is a thousandth of an em here, so a tenth of one is a hundredth of a pixel at a
	 hundred pixels an em: finer than any rasteriser reads."

	^ 0.1
]

{ #category : 'operators' }
TTCffTableParser class >> registryOrderingSupplementOperator [
	"ROS: the top dictionary entry that only a CID-keyed font carries."

	^ 1230
]

{ #category : 'operators' }
TTCffTableParser class >> subrsOperator [
	"The private dictionary entry that says where the local subroutines start, counted from the
	 private dictionary itself."

	^ 19
]

{ #category : 'parsing' }
TTCffTableParser >> addRunOfFormat: aFormat from: aCursor to: aCollection [
	"One run of consecutive identifiers: the one it starts at, and how many follow it. Format
	 1 counts those in a byte, format 2 in two bytes, and nothing else is a charset."

	| first left |
	(aFormat between: 1 and: 2) ifFalse: [
		^ TTCffError signal:
			  'charset format ' , aFormat printString , ' is one this reader does not know' ].
	first := aCursor nextUShort.
	left := aFormat = 1
		        ifTrue: [ aCursor nextByte ]
		        ifFalse: [ aCursor nextUShort ].
	0 to: left do: [ :each | aCollection add: first + each ]
]

{ #category : 'accessing' }
TTCffTableParser >> charsetIdentifiers [
	"The string identifier of every glyph, the first of them .notdef with the identifier 0."

	^ charsetIdentifiers
]

{ #category : 'accessing' }
TTCffTableParser >> charstringAt: anIndex [
	"The bytes that draw one glyph, counted from 1 as every INDEX is."

	^ charstrings at: anIndex
]

{ #category : 'reading' }
TTCffTableParser >> cursorAtTableOffset: anOffset [
	"The cursor, moved to an offset counted from the first byte of the table."

	entry offset: tableStart + anOffset.
	^ entry
]

{ #category : 'accessing' }
TTCffTableParser >> defaultWidthX [
	"The advance width of a glyph whose charstring states none. A private dictionary that
	 leaves it out means zero."

	^ (privateDictionary at: self class defaultWidthXOperator ifAbsent: [ #( 0 ) ]) first
]

{ #category : 'inspector' }
TTCffTableParser >> firstBytesOfCharstringAt: anIndex [
	"The opening bytes of one charstring, for a reader looking at the table."

	| charstring |
	charstring := self charstringAt: anIndex.
	^ (charstring first: (charstring size min: 16)) printString
]

{ #category : 'accessing' }
TTCffTableParser >> globalSubrs [
	^ globalSubrs
]

{ #category : 'glyphs' }
TTCffTableParser >> glyphAt: anIndex [
	"The glyph at that index, drawn from its own charstring and from nothing else. The
	 charstrings of the other glyphs are not read, which is what makes a face of four
	 thousand glyphs cheap to open."

	| interpreter contours glyph |
	interpreter := TTCffCharstringInterpreter on: self.
	contours := interpreter contoursOfGlyphAt: anIndex.
	glyph := TTGlyph new.
	glyph contours: (contours collect: [ :each |
			 each contourConstructionWithinTolerance:
				 self class quadraticTolerance ]).
	glyph advanceWidth: interpreter width.
	self setBoundsOf: glyph.
	^ glyph
]

{ #category : 'accessing' }
TTCffTableParser >> glyphCount [
	"One charstring a glyph, including the glyph of no name at index 1."

	^ charstrings size
]

{ #category : 'accessing' }
TTCffTableParser >> glyphIndexOfIdentifier: anInteger [
	"Which glyph carries this string identifier, counted as my charstrings are counted. A
	 font that holds no glyph for it answers nil."

	^ charsetIdentifiers indexOf: anInteger ifAbsent: [ nil ]
]

{ #category : 'inspector' }
TTCffTableParser >> inspectorCharstrings: aBuilder [
	<inspectorPresentationOrder: 20 title: 'Charstrings'>
	"One row per glyph: how many bytes draw it, and the first of them. A charstring is read
	here the way a glyph reads it, so a row costs what one glyph costs and no more."

	^ aBuilder newTable
		  addColumn: ((SpStringTableColumn title: 'Glyph' evaluated: [ :each | each printString ]) width: 80);
		  addColumn: ((SpStringTableColumn title: 'Bytes' evaluated: [ :each | (self charstringAt: each) size printString ]) width: 80);
		  addColumn: (SpStringTableColumn title: 'First bytes' evaluated: [ :each | self firstBytesOfCharstringAt: each ]);
		  items: (1 to: self glyphCount);
		  yourself
]

{ #category : 'inspector' }
TTCffTableParser >> inspectorTable: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Table'>
	"What the table says about the font, asked of the parser rather than restated: how many
	glyphs it holds, the two widths its private dictionary states, and how many subroutines
	it keeps in each of the two places a font keeps them."

	^ aBuilder newTable
		  addColumn: ((SpStringTableColumn title: 'What' evaluated: [ :each | each key ]) width: 220);
		  addColumn: (SpStringTableColumn title: 'Says' evaluated: [ :each | each value printString ]);
		  items: {
				  ('Glyphs' -> self glyphCount).
				  ('Default width x' -> self defaultWidthX).
				  ('Nominal width x' -> self nominalWidthX).
				  ('Local subroutines' -> localSubrs size).
				  ('Global subroutines' -> globalSubrs size).
				  ('Top dictionary entries' -> topDictionary size).
				  ('Private dictionary entries' -> privateDictionary size) };
		  yourself
]

{ #category : 'accessing' }
TTCffTableParser >> localSubrs [
	^ localSubrs
]

{ #category : 'accessing' }
TTCffTableParser >> nominalWidthX [
	"What a width stated by a charstring is counted from. A private dictionary that leaves it
	 out means zero."

	^ (privateDictionary at: self class nominalWidthXOperator ifAbsent: [ #( 0 ) ]) first
]

{ #category : 'accessing' }
TTCffTableParser >> privateDictionary [
	^ privateDictionary
]

{ #category : 'parsing' }
TTCffTableParser >> process [
	"Read everything the table says about the font, and nothing it says about a glyph."

	self readTopDictionary.
	TTCffIndex readFrom: entry. "the strings, which only a glyph name or a CID font needs"
	globalSubrs := TTCffIndex readFrom: entry.
	self rejectIfKeyedByCharacterIdentifiers.
	charstrings := TTCffIndex readFrom:
		               (self cursorAtTableOffset:
			                (topDictionary at: self class charStringsOperator) first).
	self readCharset.
	self readPrivateDictionary.
	^ self
]

{ #category : 'parsing' }
TTCffTableParser >> readCharset [
	"Which string identifier each glyph carries. A font that names no charset, or one of the
	 standard ones, is read as the standard order, where the identifier is the glyph index.
	 The first glyph is .notdef and is in no charset."

	| offset cursor format identifiers |
	offset := (topDictionary at: self class charsetOperator ifAbsent: [ #( 0 ) ]) first.
	offset <= 2 ifTrue: [
		^ charsetIdentifiers := (0 to: self glyphCount - 1) asArray ].
	cursor := self cursorAtTableOffset: offset.
	format := cursor nextByte.
	identifiers := OrderedCollection with: 0.
	[ identifiers size < self glyphCount ] whileTrue: [
		format = 0
			ifTrue: [ identifiers add: cursor nextUShort ]
			ifFalse: [ self addRunOfFormat: format from: cursor to: identifiers ] ].
	charsetIdentifiers := (identifiers first: self glyphCount) asArray
]

{ #category : 'reading' }
TTCffTableParser >> readHeader [
	"The header says its own size, and a font is free to make it bigger than the four bytes it
	 needs, so what follows starts where the header says and not four bytes in."

	| headerSize |
	entry skip: 2. "the major and minor version"
	headerSize := entry nextByte.
	entry skip: 1. "the width of an absolute offset, which every offset here states itself"
	entry offset: tableStart + headerSize
]

{ #category : 'reading' }
TTCffTableParser >> readPrivateDictionary [
	"The top dictionary says how many bytes the private dictionary holds and where it starts.
	 The local subroutines, if the font has any, start at an offset counted from there."

	| operands bytes subrsOffset |
	operands := topDictionary at: self class privateOperator.
	bytes := ByteArray new: operands first.
	entry
		nextBytes: bytes size
		into: bytes
		startingAt: tableStart + operands second.
	privateDictionary := TTCffDictionary readFrom: bytes.
	subrsOffset := privateDictionary at: self class subrsOperator ifAbsent: [ nil ].
	localSubrs := subrsOffset
		              ifNil: [ TTCffIndex empty ]
		              ifNotNil: [
			              TTCffIndex readFrom:
				              (self cursorAtTableOffset: operands second + subrsOffset first) ]
]

{ #category : 'reading' }
TTCffTableParser >> readTopDictionary [
	"The header, the font names and the top dictionary: the head of the table, which says
	 where everything else in it is. A reader that only classifies a face stops here."

	tableStart := entry offset.
	self readHeader.
	TTCffIndex readFrom: entry. "the font names, which an OpenType font takes from its name table"
	topDictionary := TTCffDictionary readFrom: ((TTCffIndex readFrom: entry) at: 1).
	^ topDictionary
]

{ #category : 'reading' }
TTCffTableParser >> rejectIfKeyedByCharacterIdentifiers [
	"A CID-keyed font reaches a glyph through an FDArray and an FDSelect instead of one private
	 dictionary. Reading it as if it were not draws the wrong hints and the wrong widths."

	(topDictionary includesOperator: self class registryOrderingSupplementOperator)
		ifTrue: [ TTCffError signal: 'this font is CID-keyed, which this reader does not draw' ]
]

{ #category : 'reading' }
TTCffTableParser >> setBoundsOf: aGlyph [
	"The box of a CFF glyph is computed from the points it draws, since a CFF font states no
	 box of its own for a glyph. TTGlyph carries the box in the order the glyf table writes
	 it — xMin, yMin, xMax, yMax — so what it calls the top is the smallest y and what it
	 calls the bottom is the largest. A glyph that inks nothing has a box of no width and no
	 height."

	| points |
	points := OrderedCollection new.
	aGlyph contours do: [ :each |
		1 to: each points size do: [ :index | points add: (each points at: index) ] ].
	points ifEmpty: [
		^ aGlyph
			  boundsLeft: 0
			  boundsRight: 0
			  boundsTop: 0
			  boundsBottom: 0 ].
	aGlyph
		boundsLeft: (points min: [ :each | each x ])
		boundsRight: (points max: [ :each | each x ])
		boundsTop: (points min: [ :each | each y ])
		boundsBottom: (points max: [ :each | each y ])
]

{ #category : 'accessing' }
TTCffTableParser >> topDictionary [
	^ topDictionary
]
