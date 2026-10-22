"
I am one font file, read with the VectorGraphics TrueType parsers, and I answer what the font itself says: its metrics in font units, the glyph index of a code point, and the outline of a glyph.

I am the replacement for AeCairoFreetypeFontFace, but I carry no FreeType face and no handle: I read the glyf, loca, cmap, head, hhea, hmtx and maxp tables of the bytes I am given. A font with no glyf table, a CFF OpenType font for instance, is refused rather than drawn wrongly.

Everything I answer is in font units, which are unitsPerEm to the em square. Scaling is the scaled font's business, because the same face serves every size, and VGScaledFont is what holds a font matrix. I cache the outline of each glyph I am asked for, so a repeated draw parses nothing twice.
"
Class {
	#name : 'VGFontFace',
	#superclass : 'Object',
	#instVars : [
		'bytes',
		'glyphs',
		'characterMap',
		'unitsPerEm',
		'ascent',
		'descent',
		'lineGap',
		'maxAdvanceWidth',
		'boundsRectangle',
		'outlines',
		'glyfEntry',
		'glyfStart',
		'glyphDataOffsets'
	],
	#classInstVars : [
		'defaultFace'
	],
	#category : 'VectorGraphics-Cairo-Text',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Text'
}

{ #category : 'constants' }
VGFontFace class >> argumentsAreOffsetsFlag [
	"The two placement arguments are an offset, not a pair of point indices to match."

	^ 2
]

{ #category : 'constants' }
VGFontFace class >> argumentsAreWordsFlag [
	"The two placement arguments of a component record are 16 bit, not 8 bit."

	^ 1
]

{ #category : 'instance creation' }
VGFontFace class >> bytesForFamilyName: aFamilyName styleName: aStyleName [
	"The bytes of the font the manager registered under this family and style. A font we cannot
	 name falls back to the bundled default, because a frame drawn in the wrong font is better
	 than a frame that raises inside the renderer."

	| entry |
	entry := AeFontManager globalInstance faceEntries
		         detect: [ :each |
			         each familyName = aFamilyName and: [
				         each styleName = aStyleName ] ]
		         ifNone: [ nil ].
	entry ifNil: [ ^ self defaultBytes ].
	^ (entry isKindOf: AeMemoryFaceEntry)
		  ifTrue: [ entry bytes ]
		  ifFalse: [ entry location binaryReadStream upToEnd ]
]

{ #category : 'constants' }
VGFontFace class >> componentHasMatrixFlag [
	^ 128
]

{ #category : 'constants' }
VGFontFace class >> componentHasOneScaleFlag [
	^ 8
]

{ #category : 'constants' }
VGFontFace class >> componentHasTwoScalesFlag [
	^ 64
]

{ #category : 'constants' }
VGFontFace class >> compositeBoundsAndCountLength [
	"The number of contours and the four bounds of a glyph record, which the component records
	 follow."

	^ 10
]

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

{ #category : 'constants' }
VGFontFace class >> moreComponentsFlag [
	^ 32
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

{ #category : 'constants' }
VGFontFace class >> requiredTableTags [
	"The tables a TrueType outline font must carry for me to read it. A font missing one of them
	 is refused in #readBytes:."

	^ #( 'head' 'maxp' 'hhea' 'hmtx' 'loca' 'cmap' 'glyf' )
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

{ #category : 'constants' }
VGFontFace class >> twoDotFourteenScale [
	"A component matrix holds each of its numbers as an F2Dot14: a signed 16 bit fraction with
	 fourteen bits after the point."

	^ 16384
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

{ #category : 'private' }
VGFontFace >> componentsOfCompositeGlyphAt: aGlyphIndex [
	"Read the component records of a composite glyph straight from the glyf table. Each record
	 names a glyph, places it and may transform it; the records run on while one of them sets the
	 more components flag."

	| components flags |
	glyfEntry offset: glyfStart + (glyphDataOffsets at: aGlyphIndex + 1).
	glyfEntry skip: self class compositeBoundsAndCountLength.
	components := OrderedCollection new.
	[
	flags := glyfEntry nextUShort.
	components add: (self readComponentWithFlags: flags).
	flags allMask: self class moreComponentsFlag ] whileTrue.
	^ components asArray
]

{ #category : 'private' }
VGFontFace >> contoursOfGlyphAt: aGlyphIndex [
	"The contours of one glyph in font units. A composite glyph draws the contours of its
	 components, each one placed and transformed by its own record, and a component may itself be
	 a composite."

	| glyph |
	glyph := glyphs at: aGlyphIndex + 1.
	glyph isComposite ifFalse: [ ^ self contoursOfSimpleGlyph: glyph ].
	^ (self componentsOfCompositeGlyphAt: aGlyphIndex) flatCollect: [ :component |
		  (self contoursOfGlyphAt: component glyphIndex) collect: [ :contour |
			  contour collect: [ :point | component transformedPoint: point ] ] ]
]

{ #category : 'private' }
VGFontFace >> contoursOfSimpleGlyph: aGlyph [
	"Walk the glyph's contours once. TTContourConstruction answers a quadratic's end point and
	 its control point, in that order, and both absolute, so the odd-sized array of points I
	 build is the contour as it is drawn."

	^ (aGlyph contours reject: [ :each | each isEmpty ]) collect: [ :each |
		  Array streamContents: [ :stream |
			  stream nextPut: each points first.
			  each quadraticBeziersDo: [ :endPoint :controlPoint |
				  stream
					  nextPut: controlPoint;
					  nextPut: endPoint ] ] ]
]

{ #category : 'accessing' }
VGFontFace >> descent [
	"Negative in a TrueType font, because it is measured upwards from the baseline like every
	 other font coordinate."

	^ descent
]

{ #category : 'accessing' }
VGFontFace >> glyphCount [
	"How many glyphs the font holds, index zero included: that one is the glyph a code point the
	 font does not map is drawn with."

	^ glyphs size
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
	 shows."

	^ aBuilder newTable
		  items: {
				  ('Glyphs' -> self glyphCount).
				  ('Units per em' -> self unitsPerEm).
				  ('Ascent' -> self ascent).
				  ('Descent' -> self descent).
				  ('Line gap' -> self lineGap).
				  ('Maximum advance width' -> self maxAdvanceWidth).
				  ('Bounds in font units' -> self boundsRectangle).
				  ('Bytes' -> self bytes size) };
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

{ #category : 'private' }
VGFontFace >> nextSignedByte [
	"TTFontTableDirEntry reads a byte unsigned, and a component offset is signed."

	| value |
	value := glyfEntry nextByte.
	^ value > 127
		  ifTrue: [ value - 256 ]
		  ifFalse: [ value ]
]

{ #category : 'private' }
VGFontFace >> nextTwoDotFourteen [
	^ glyfEntry nextShort / self class twoDotFourteenScale
]

{ #category : 'accessing' }
VGFontFace >> outlineOfGlyphAt: aGlyphIndex [
	"The glyph's shape in font units, read once and kept, because a page of text asks for the
	 same few glyphs again and again."

	^ outlines at: aGlyphIndex ifAbsentPut: [ self readOutlineOfGlyphAt: aGlyphIndex ]
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
	"Read the tables I need from the font's own bytes. A font with no glyf table carries its
	 outlines in some other format, CFF for an OpenType font, and I would draw nothing for it,
	 so it is refused here rather than at the first glyph."

	| tables headData glyphCount |
	bytes := aByteArray.
	outlines := Dictionary new.
	tables := TTFontReader new buildTableDirectory: aByteArray offset: 0.
	self class requiredTableTags do: [ :tag |
		(tables includesKey: tag) ifFalse: [
			^ Error signal: 'the font has no ' , tag , ' table' ] ].
	headData := (TTHeadTableParser on: (tables at: 'head')) process.
	unitsPerEm := headData at: #units.
	boundsRectangle := headData at: #bounds.
	glyphCount := (TTMaxpTableParser on: (tables at: 'maxp')) process.
	glyphDataOffsets := (TTLocaTableParser
		                     on: (tables at: 'loca')
		                     format: (headData at: #indexToLocFormat)
		                     nGlyphs: glyphCount) process.
	characterMap := (TTCmapTableParser on: (tables at: 'cmap')) process.
	characterMap ifNil: [ ^ Error signal: 'the font maps no Unicode code point' ].
	self readGlyphsAndHorizontalMetricsFrom: tables count: glyphCount
]

{ #category : 'private' }
VGFontFace >> readComponentWithFlags: aFlagWord [
	"One component record, with the entry standing on the glyph index that follows its flags. A
	 record that matches two points instead of giving an offset is refused: no font we draw uses
	 it, and guessing the placement would move the component silently."

	| component |
	component := VGGlyphComponent glyphIndex: glyfEntry nextUShort.
	(aFlagWord allMask: self class argumentsAreOffsetsFlag) ifFalse: [
		^ Error signal: 'a component placed by matching points is not supported' ].
	component offset: ((aFlagWord allMask: self class argumentsAreWordsFlag)
			 ifTrue: [ glyfEntry nextShort @ glyfEntry nextShort ]
			 ifFalse: [ self nextSignedByte @ self nextSignedByte ]).
	(aFlagWord allMask: self class componentHasMatrixFlag)
		ifTrue: [
			component
				xx: self nextTwoDotFourteen
				xy: self nextTwoDotFourteen
				yx: self nextTwoDotFourteen
				yy: self nextTwoDotFourteen ]
		ifFalse: [
			(aFlagWord allMask: self class componentHasTwoScalesFlag)
				ifTrue: [
					component
						xx: self nextTwoDotFourteen
						xy: 0
						yx: 0
						yy: self nextTwoDotFourteen ]
				ifFalse: [
					(aFlagWord allMask: self class componentHasOneScaleFlag) ifTrue: [
						| scale |
						scale := self nextTwoDotFourteen.
						component
							xx: scale
							xy: 0
							yx: 0
							yy: scale ] ] ].
	^ component
]

{ #category : 'reading' }
VGFontFace >> readGlyphsAndHorizontalMetricsFrom: aTableDictionary count: aGlyphCount [
	"The outlines and the advances, which are read together because hmtx fills the glyphs the glyf
	 table gave. The maximum advance is read before TTHheaTableParser runs, because that parser
	 reads from the entry's current offset. The glyf entry and its start are kept because a
	 composite glyph is read from the table again: TTGlyfTableParser keeps the component glyphs of
	 a composite and discards the offsets that place them."

	| hheaEntry hheaData |
	hheaEntry := aTableDictionary at: 'hhea'.
	maxAdvanceWidth := self readMaxAdvanceWidthFrom: hheaEntry.
	hheaData := (TTHheaTableParser on: hheaEntry) process.
	ascent := hheaData at: #ascent.
	descent := hheaData at: #descent.
	lineGap := hheaData at: #lineGap.
	glyfEntry := aTableDictionary at: 'glyf'.
	glyfStart := glyfEntry offset.
	glyphs := (TTGlyfTableParser
		           on: glyfEntry
		           nGlyphs: aGlyphCount
		           offsets: glyphDataOffsets) process.
	(TTHmtxTableParser
		 on: (aTableDictionary at: 'hmtx')
		 glyphs: glyphs
		 numHMetrics: (hheaData at: #numHMetrics)) process
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

{ #category : 'private' }
VGFontFace >> readOutlineOfGlyphAt: aGlyphIndex [
	"The advance and the box come from the glyph's own record; the contours come from the glyph
	 itself, or from its components when it is a composite."

	| glyph |
	glyph := glyphs at: aGlyphIndex + 1.
	^ VGGlyphOutline
		  advance: glyph advanceWidth
		  boundsRectangle:
		  (glyph boundsLeft @ glyph boundsTop
		   corner: glyph boundsRight @ glyph boundsBottom)
		  contours: (self contoursOfGlyphAt: aGlyphIndex)
]

{ #category : 'accessing' }
VGFontFace >> unitsPerEm [
	"How many font units the em square is wide. A font matrix scales by its size over this."

	^ unitsPerEm
]
