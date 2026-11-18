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
		'localSubrs'
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
TTCffTableParser class >> defaultWidthXOperator [
	"The private dictionary entry that says the advance width of a glyph whose charstring
	 states none."

	^ 20
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

{ #category : 'accessing' }
TTCffTableParser >> glyphCount [
	"One charstring a glyph, including the glyph of no name at index 1."

	^ charstrings size
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

	tableStart := entry offset.
	self readHeader.
	TTCffIndex readFrom: entry. "the font names, which an OpenType font takes from its name table"
	topDictionary := TTCffDictionary readFrom: ((TTCffIndex readFrom: entry) at: 1).
	TTCffIndex readFrom: entry. "the strings, which only a glyph name or a CID font needs"
	globalSubrs := TTCffIndex readFrom: entry.
	self rejectIfKeyedByCharacterIdentifiers.
	charstrings := TTCffIndex readFrom:
		               (self cursorAtTableOffset:
			                (topDictionary at: self class charStringsOperator) first).
	self readPrivateDictionary.
	^ self
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
TTCffTableParser >> rejectIfKeyedByCharacterIdentifiers [
	"A CID-keyed font reaches a glyph through an FDArray and an FDSelect instead of one private
	 dictionary. Reading it as if it were not draws the wrong hints and the wrong widths."

	(topDictionary includesOperator: self class registryOrderingSupplementOperator)
		ifTrue: [ TTCffError signal: 'this font is CID-keyed, which this reader does not draw' ]
]

{ #category : 'accessing' }
TTCffTableParser >> topDictionary [
	^ topDictionary
]
