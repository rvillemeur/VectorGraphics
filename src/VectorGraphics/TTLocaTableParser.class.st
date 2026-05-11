"
Parser for the TrueType 'loca' (Index to Location) table.

Returns an Array of (nGlyphs + 1) byte offsets into the 'glyf' table data. The format
determines whether offsets are stored as 16-bit half-values (format 0) or 32-bit full values
(format 1); both are returned as full byte offsets.

## Constructor
  `TTLocaTableParser on: entry format: aFormat nGlyphs: n`
  - aFormat: the indexToLocFormat value from the 'head' table (0 or 1)
  - n: the glyph count from the 'maxp' table
"
Class {
	#name : 'TTLocaTableParser',
	#superclass : 'TTFontParser',
	#instVars : [
		'format',
		'nGlyphs'
	],
	#category : 'VectorGraphics-TrueType',
	#package : 'VectorGraphics',
	#tag : 'TrueType'
}

{ #category : 'instance creation' }
TTLocaTableParser class >> on: anEntry format: aFormat nGlyphs: n [

	^ self new initWithEntry: anEntry format: aFormat nGlyphs: n
]

{ #category : 'initialization' }
TTLocaTableParser >> initWithEntry: anEntry format: aFormat nGlyphs: n [

	super initWithEntry: anEntry.
	format := aFormat.
	nGlyphs := n
]

{ #category : 'parsing' }
TTLocaTableParser >> process [

	| offsets offset |
	offsets := Array new: nGlyphs + 1.
	1 to: nGlyphs + 1 do: [ :i |
		offset := format = 0
			          ifTrue: [ entry nextUShort * 2 ]
			          ifFalse: [ entry nextULong ].
		offsets at: i put: offset ].
	^ offsets
]
