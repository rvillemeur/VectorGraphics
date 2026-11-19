"
I am one font file, read with the VectorGraphics TrueType parsers, and I answer what the font itself says: the family and style it names itself, its metrics in font units, the glyph index of a code point, and the outline of a glyph.

I am the replacement for AeCairoFreetypeFontFace, but I carry no FreeType face and no handle: I read the glyf, loca, cmap, head, hhea, hmtx and maxp tables of the bytes I am given. A font with no glyf table, a CFF OpenType font for instance, is rejected rather than drawn wrongly.

Everything I answer is in font units, which are unitsPerEm to the em square. Scaling is the scaled font's business, because the same face serves every size, and VGScaledFont is what holds a font matrix. I cache the outline of each glyph I am asked for, so a repeated draw parses nothing twice.
"
Class {
	#name : 'VGFontFace',
	#superclass : 'Object',
	#instVars : [
		'bytes',
		'glyphSource',
		'characterMap',
		'unitsPerEm',
		'ascent',
		'descent',
		'lineGap',
		'maxAdvanceWidth',
		'boundsRectangle',
		'outlines',
		'metadata'
	],
	#classInstVars : [
		'defaultFace'
	],
	#category : 'VectorGraphics-Cairo-Text',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Text'
}

{ #category : 'default face' }
VGFontFace class >> default [
	"The default face, read once and kept, so that a text verb with no font parses the tables of
	 the bundled font once in the life of the image and every default scaled font shares one
	 glyph cache."

	^ defaultFace ifNil: [ defaultFace := self newForBytes: self defaultBytes ]
]

{ #category : 'default face' }
VGFontFace class >> defaultBytes [
	"The bytes of the default family, read from the font Pharo embeds. A family that is not
	 embedded would have to be read from a path the provider does not keep, so a provider without
	 the embedded family is an error that names what is missing rather than a silent fallback to
	 some other font."

	| family member info |
	family := FreeTypeFontProvider current families
		          detect: [ :each | each familyName = self defaultFamilyName ]
		          ifNone: [ nil ].
	family ifNil: [ ^ self error: 'no font family named ' , self defaultFamilyName ].
	member := family memberWithStyleName: self defaultStyleName.
	member ifNil: [
		^ self error: self defaultFamilyName , ' has no ' , self defaultStyleName , ' style' ].
	info := member fileInfo.
	info isEmbedded ifFalse: [
		^ self error: self defaultFamilyName , ' is not embedded in this image' ].
	^ info fileContents
]

{ #category : 'default face' }
VGFontFace class >> defaultFamilyName [
	"The family of the face a text verb falls back to. Cairo resolves its toy default face
	 through fontconfig, which this replacement does not bind, so the fallback is a family Pharo
	 itself embeds and which is therefore in every image: the bytes are read from Pharo's font
	 provider, no FreeType call is made on them, and the outlines are parsed here as any other
	 face is."

	^ 'Source Sans Pro'
]

{ #category : 'default face' }
VGFontFace class >> defaultStyleName [
	"The style of the default family. Cairo's toy default face is upright and of normal weight."

	^ 'Regular'
]

{ #category : 'testing' }
VGFontFace class >> holdsTrueTypeOutlines: aTableDictionary [
	"Whether the glyphs of this font are TrueType outlines rather than CFF charstrings. The
	 rule is TTFontReader's, so the eager door onto a font and this one cannot disagree about
	 which format a font is in."

	^ TTFontReader holdsTrueTypeOutlines: aTableDictionary
]

{ #category : 'instance creation' }
VGFontFace class >> newForBytes: aByteArray [
	"The face of a font held in memory."

	^ self new
		  readBytes: aByteArray;
		  yourself
]

{ #category : 'instance creation' }
VGFontFace class >> newForFile: aFileReference [
	"The face of a font on disc."

	^ self newForBytes: aFileReference binaryReadStream upToEnd
]

{ #category : 'accessing' }
VGFontFace class >> outlineTableTagsIn: aTableDictionary [
	"The tables I read the outlines of this font from, which is TTFontReader's rule: glyf and
	 loca, or the one CFF table."

	^ TTFontReader outlineTableTagsIn: aTableDictionary
]

{ #category : 'accessing' }
VGFontFace class >> requiredTableTags [
	"The tables a font must carry for me to read it whatever its outlines are drawn in. The
	 tables the outlines themselves are read from are stated by #outlineTableTagsIn:, since
	 they differ between the two formats. A font missing one of either list is rejected in
	 #readBytes:."

	^ #( 'head' 'maxp' 'hhea' 'hmtx' 'cmap' )
]

{ #category : 'default face' }
VGFontFace class >> resetDefault [
	"Forget the kept default face, so a test can hold that it is read once and an image that
	 gained a font can be told to look again."

	defaultFace := nil
]

{ #category : 'constants' }
VGFontFace class >> sampleCharacters [
	"The characters the Alphabet view shows: round letters, a straight one, one that is composite
	 in many fonts, a space and a digit."

	^ 'Hagi A1' asArray
]

{ #category : 'accessing' }
VGFontFace >> ascent [
	^ ascent
]

{ #category : 'accessing' }
VGFontFace >> boundsRectangle [
	"The box the font says holds every one of its glyphs, in font units."

	^ boundsRectangle
]

{ #category : 'accessing' }
VGFontFace >> bytes [
	^ bytes
]

{ #category : 'accessing' }
VGFontFace >> cachedGlyphCount [
	"How many glyph outlines I have parsed and kept. It is what tells a repeated draw from a
	 first one, and the inspector shows it."

	^ outlines size
]

{ #category : 'accessing' }
VGFontFace >> descent [
	"Negative in a TrueType font, because it is measured upwards from the baseline like every
	 other font coordinate."

	^ descent
]

{ #category : 'accessing' }
VGFontFace >> familyName [
	"The family the font names itself, as its own name table states it. nil for a font that
	 carries no name table: I can draw such a font, so I read it, and only naming it fails."

	^ metadata familyName
]

{ #category : 'accessing' }
VGFontFace >> glyphCount [
	"How many glyphs the font holds, index zero included: that one is the glyph a code point the
	 font does not map is drawn with."

	^ glyphSource glyphCount
]

{ #category : 'accessing' }
VGFontFace >> glyphIndexForCodePoint: aCodePoint [
	"The glyph the font maps this code point to, or zero when it maps none: glyph zero is the
	 one every TrueType font keeps for a code point it does not cover. The character map holds
	 one slot per code point of the basic multilingual plane, so a code point above it is not
	 mapped either."

	aCodePoint >= characterMap size ifTrue: [ ^ 0 ].
	^ characterMap at: aCodePoint + 1
]

{ #category : 'inspector' }
VGFontFace >> inspectorAlphabet: aBuilder [
	<inspectorPresentationOrder: 11 title: 'Alphabet'>
	"The cmap and the outlines at work: a row for each character of a sample string, with the
	 glyph the face maps it to and what that glyph holds. The rows call the real lookup and the
	 real reader, so a change in either shows up here."

	^ aBuilder newTable
		  items: self class sampleCharacters asArray;
		  addColumn: (SpStringTableColumn
				   title: 'Character'
				   evaluated: [ :each | each asString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Glyph'
				   evaluated: [ :each |
					   (self glyphIndexForCodePoint: each codePoint) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Advance in font units'
				   evaluated: [ :each |
					   (self outlineOfGlyphAt: (self glyphIndexForCodePoint: each codePoint))
						   advance printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Contours'
				   evaluated: [ :each |
					   (self outlineOfGlyphAt: (self glyphIndexForCodePoint: each codePoint))
						   contours size printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Inks'
				   evaluated: [ :each |
					   (self outlineOfGlyphAt: (self glyphIndexForCodePoint: each codePoint))
						   isEmpty not printString ]);
		  yourself
]

{ #category : 'inspector' }
VGFontFace >> inspectorAlphabetContext: aContext [
	aContext active: self bytes notNil
]

{ #category : 'inspector' }
VGFontFace >> inspectorFace: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Face'>
	"What the font's own tables say, read through the public readers rather than restated. No row
	 reports the outline memo cache, so a glyph a later view reads cannot change what this one
	 shows. The two name rows are nil for a font carrying no name table, which I still draw.

	 The last row sends newCairoFontFace rather than saying what it answers, so it stops being
	 true the day that method answers something other than me."

	^ aBuilder newTable
		  items: {
				  ('Family' -> self familyName).
				  ('Style' -> self styleName).
				  ('Glyphs' -> self glyphCount).
				  ('Units per em' -> self unitsPerEm).
				  ('Ascent' -> self ascent).
				  ('Descent' -> self descent).
				  ('Line gap' -> self lineGap).
				  ('Maximum advance width' -> self maxAdvanceWidth).
				  ('Bounds in font units' -> self boundsRectangle).
				  ('Bytes' -> self bytes size).
				  ('Own Cairo font face' -> (self newCairoFontFace == self)) };
		  addColumn: (SpStringTableColumn title: 'Property' evaluated: [ :each | each key ]);
		  addColumn: (SpStringTableColumn
				   title: 'Value'
				   evaluated: [ :each | each value printString ]);
		  yourself
]

{ #category : 'inspector' }
VGFontFace >> inspectorFaceContext: aContext [
	aContext active: self bytes notNil
]

{ #category : 'accessing' }
VGFontFace >> lineGap [
	^ lineGap
]

{ #category : 'accessing' }
VGFontFace >> maxAdvanceWidth [
	^ maxAdvanceWidth
]

{ #category : 'instance creation' }
VGFontFace >> newCairoFontFace [
	"Myself: a face of this project is already the Cairo font face a drawing scales. Cairo spells
	 the font face and the scaled font as two objects, and Alexandrie's canvas asks the face it is
	 given for the first of them before asking that one for the second, which is the single place
	 where the backend is reached with no Cairo class named in the source. Upstream's AeFTFace
	 answers an AeCairoFreetypeFontFace there, a wrapper over a FreeType handle; nothing of mine
	 is a handle, so there is nothing to wrap.

	 This and newScaledFontWithFontMatrix:userToDeviceMatrix:options: are the two messages that
	 protocol sends a font face, which is why they sit together."

	^ self
]

{ #category : 'instance creation' }
VGFontFace >> newScaledFontWithFontMatrix: aFontMatrix userToDeviceMatrix: aUserToDeviceMatrix options: aFontOptions [
	"Myself at a size, under a user to device matrix, with those rendering options. Cairo spells
	 the same thing both ways round, through the face and through the scaled font class, and a
	 drawing uses either, so this is the face's spelling of
	 VGScaledFont class >> #fontFace:fontMatrix:userToDeviceMatrix:options:."

	^ VGScaledFont
		  fontFace: self
		  fontMatrix: aFontMatrix
		  userToDeviceMatrix: aUserToDeviceMatrix
		  options: aFontOptions
]

{ #category : 'accessing' }
VGFontFace >> outlineOfGlyphAt: aGlyphIndex [
	"The glyph's shape in font units, read once and kept, because a page of text asks for the
	 same few glyphs again and again."

	^ outlines
		  at: aGlyphIndex
		  ifAbsentPut: [ glyphSource outlineOfGlyphAt: aGlyphIndex ]
]

{ #category : 'printing' }
VGFontFace >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: '(';
		print: self glyphCount;
		nextPutAll: ' glyphs, ';
		print: unitsPerEm;
		nextPutAll: ' units per em)'
]

{ #category : 'reading' }
VGFontFace >> readBytes: aByteArray [
	"Read the tables I need from the font's own bytes, each step one table or one rejection. The
	 metadata reader keeps its own judgement: I store what it answers whether or not it would
	 have rejected this font, since what I need to draw and what it needs to name are not the
	 same tables."

	| tables headData glyphCount |
	bytes := aByteArray.
	outlines := Dictionary new.
	tables := TTFontReader buildTableDirectory: aByteArray offset: 0.
	self rejectIfATableIsMissingFrom: tables.
	metadata := TTFontMetadataReader readBytes: aByteArray.
	headData := (TTHeadTableParser on: (tables at: 'head')) process.
	unitsPerEm := headData at: #units.
	boundsRectangle := headData at: #bounds.
	glyphCount := (TTMaxpTableParser on: (tables at: 'maxp')) process.
	characterMap := (TTCmapTableParser on: (tables at: 'cmap')) process.
	characterMap ifNil: [ ^ Error signal: 'the font maps no Unicode code point' ].
	self
		readGlyphsAndHorizontalMetricsFrom: tables
		count: glyphCount
		indexToLocFormat: (headData at: #indexToLocFormat)
]

{ #category : 'reading' }
VGFontFace >> readGlyphsAndHorizontalMetricsFrom: aTableDictionary count: aGlyphCount indexToLocFormat: anInteger [
	"The glyph records and the advances, which are read together because hmtx fills the records
	 the outline table gave. The order is the whole of what this method says: hhea states how
	 many metrics hmtx holds, and hmtx needs the records to write into. Which outline table the
	 font carries is the source's business, not mine."

	| numHMetrics |
	numHMetrics := self readHorizontalMetricsFrom: aTableDictionary.
	glyphSource := TTGlyphSource
		               on: aTableDictionary
		               count: aGlyphCount
		               indexToLocFormat: anInteger.
	glyphSource fillAdvancesFrom: aTableDictionary numHMetrics: numHMetrics
]

{ #category : 'reading' }
VGFontFace >> readHorizontalMetricsFrom: aTableDictionary [
	"The metrics the hhea table states, and the count of glyphs hmtx holds a metric for, which
	 the caller needs to read hmtx. The maximum advance is read before TTHheaTableParser runs,
	 because that parser reads from the entry's current offset."

	| hheaEntry hheaData |
	hheaEntry := aTableDictionary at: 'hhea'.
	maxAdvanceWidth := self readMaxAdvanceWidthFrom: hheaEntry.
	hheaData := (TTHheaTableParser on: hheaEntry) process.
	ascent := hheaData at: #ascent.
	descent := hheaData at: #descent.
	lineGap := hheaData at: #lineGap.
	^ hheaData at: #numHMetrics
]

{ #category : 'initialization' }
VGFontFace >> readMaxAdvanceWidthFrom: aTableDirEntry [
	"The widest advance the font holds, which a scaled font answers as its maximum advance.
	 TTHheaTableParser skips the field, so read it here: it is the fourth 16 bit field of hhea,
	 after the 32 bit version and the ascender, the descender and the line gap. A parser reads an
	 entry from wherever its offset stands, so the offset is put back before anything else reads
	 the table."

	| start value |
	start := aTableDirEntry offset.
	aTableDirEntry offset: start + 10.
	value := aTableDirEntry nextUShort.
	aTableDirEntry offset: start.
	^ value
]

{ #category : 'reading' }
VGFontFace >> rejectIfATableIsMissingFrom: aTableDictionary [
	"The tables I read every glyph and every metric from have to be there before I read any of
	 them: the five every font carries, and the ones the outlines of this font are drawn from.
	 A font carrying neither glyf nor CFF holds its glyphs in some format I do not read, or
	 holds none, and is rejected here rather than at the first glyph. Raises; the caller reads
	 nothing further."

	(self class requiredTableTags
	 , (self class outlineTableTagsIn: aTableDictionary)) do: [ :tag |
		(aTableDictionary includesKey: tag) ifFalse: [
			Error signal: 'the font has no ' , tag , ' table' ] ]
]

{ #category : 'accessing' }
VGFontFace >> styleName [
	"The style the font names itself — 'Regular', 'Bold Italic' — as its own name table states
	 it. nil for a font that carries no name table, like familyName."

	^ metadata styleName
]

{ #category : 'accessing' }
VGFontFace >> unitsPerEm [
	"How many font units the em square is wide. A font matrix scales by its size over this."

	^ unitsPerEm
]
