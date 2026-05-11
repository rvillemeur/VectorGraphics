"
Parser for the TrueType 'maxp' (Maximum Profile) table.

Returns an Integer: the total number of glyphs in the font.
TTFontReader uses this value when constructing TTLocaTableParser and TTGlyfTableParser.
"
Class {
	#name : 'TTMaxpTableParser',
	#superclass : 'TTFontParser',
	#category : 'VectorGraphics-TrueType',
	#package : 'VectorGraphics',
	#tag : 'TrueType'
}

{ #category : 'parsing' }
TTMaxpTableParser >> process [

	entry skip: 4. "version"
	^ entry nextUShort
]
