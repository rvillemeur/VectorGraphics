"
The glyph records of an OpenType font, whose outlines are Type 2 charstrings in one `CFF ` table. `TTCffTableParser` reads the table once, for everything it says about the font, and the records are `TTCffGlyph` instances: each interprets its own charstring the first time somebody asks for its shape, so building me draws nothing.

A charstring says nothing about building a glyph from other glyphs, so I keep my superclass's contours and add no composite route. A CID-keyed font is rejected by the table parser, not by me.
"
Class {
	#name : 'TTCffGlyphSource',
	#superclass : 'TTGlyphSource',
	#category : 'VectorGraphics-TrueType-Reading',
	#package : 'VectorGraphics-TrueType',
	#tag : 'Reading'
}

{ #category : 'inspector' }
TTCffGlyphSource >> inspectorGlyphs: aBuilder [
	<inspectorPresentationOrder: 20 title: 'Glyphs'>
	"Every glyph of the font, and whether its charstring has been interpreted yet. A face of
	 four thousand glyphs reads none of them when it opens, which is what makes opening it
	 cheap, so this view asks each record what it knows and nothing that would draw it: the
	 advance width comes from hmtx and costs no charstring. Open the Contours tab of a glyph
	 to draw that one, then come back here to see its row say so."

	^ aBuilder newTable
		  addColumn: ((SpStringTableColumn
				    title: 'Glyph'
				    evaluated: [ :each | each key printString ])
				   width: 70;
				   yourself);
		  addColumn: (SpStringTableColumn
				   title: 'Drawn'
				   evaluated: [ :each |
					   each value isDrawn
						   ifTrue: [ 'yes' ]
						   ifFalse: [ 'no' ] ]);
		  addColumn: (SpStringTableColumn
				   title: 'Advance'
				   evaluated: [ :each | each value advanceWidth printString ]);
		  items: self glyphEntries;
		  yourself
]

{ #category : 'reading' }
TTCffGlyphSource >> readFrom: aTableDictionary count: aGlyphCount indexToLocFormat: anInteger [
	"The glyphs of an OpenType font: the CFF table is read for everything it says about the
	 font and for nothing it says about a glyph, and each record draws itself the first time
	 somebody asks for its shape. There is no loca table, so the format of one means nothing
	 here."

	glyphs := TTCffGlyph
		          onTable: (TTCffTableParser on: (aTableDictionary at: 'CFF ')) process
		          count: aGlyphCount.
	^ self
]
