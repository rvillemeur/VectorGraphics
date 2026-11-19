"
The glyph records of a TrueType font, read from its `glyf` table at the offsets `loca` states. I keep the table entry and the offsets, because a composite glyph is read from the table a second time: `TTGlyfTableParser` keeps the component glyphs of a composite and discards the records that place them, so I read those records myself and answer one `VGGlyphComponent` each.

My contours are therefore either the glyph's own, like any source's, or the contours of its components, transformed by the matrix each component record carries. A component may itself be a composite.

The flags of a component record and the scale of an F2Dot14 are my class-side constants.
"
Class {
	#name : 'TTGlyfGlyphSource',
	#superclass : 'TTGlyphSource',
	#instVars : [
		'glyfEntry',
		'glyfStart',
		'glyphDataOffsets'
	],
	#category : 'VectorGraphics-TrueType-Reading',
	#package : 'VectorGraphics-TrueType',
	#tag : 'Reading'
}

{ #category : 'constants' }
TTGlyfGlyphSource class >> argumentsAreOffsetsFlag [
	"The two placement arguments are an offset, not a pair of point indices to match."

	^ 2
]

{ #category : 'constants' }
TTGlyfGlyphSource class >> argumentsAreWordsFlag [
	"The two placement arguments of a component record are 16 bit, not 8 bit."

	^ 1
]

{ #category : 'constants' }
TTGlyfGlyphSource class >> componentHasMatrixFlag [
	^ 128
]

{ #category : 'constants' }
TTGlyfGlyphSource class >> componentHasOneScaleFlag [
	^ 8
]

{ #category : 'constants' }
TTGlyfGlyphSource class >> componentHasTwoScalesFlag [
	^ 64
]

{ #category : 'constants' }
TTGlyfGlyphSource class >> compositeBoundsAndCountLength [
	"The number of contours and the four bounds of a glyph record, which the component records
	 follow."

	^ 10
]

{ #category : 'constants' }
TTGlyfGlyphSource class >> moreComponentsFlag [
	^ 32
]

{ #category : 'constants' }
TTGlyfGlyphSource class >> twoDotFourteenScale [
	"A component matrix holds each of its numbers as an F2Dot14: a signed 16 bit fraction with
	 fourteen bits after the point."

	^ 16384
]

{ #category : 'reading' }
TTGlyfGlyphSource >> applyMatrixTo: aComponent [
	"The four F2Dot14 numbers of a full two by two matrix, in the order the record writes
	 them: xx, xy, yx, yy."

	aComponent
		xx: self nextTwoDotFourteen
		xy: self nextTwoDotFourteen
		yx: self nextTwoDotFourteen
		yy: self nextTwoDotFourteen
]

{ #category : 'reading' }
TTGlyfGlyphSource >> applyOneScaleTo: aComponent [
	"One F2Dot14 number scaling both axes alike, which is the shortest transform a record
	 carries."

	| scale |
	scale := self nextTwoDotFourteen.
	aComponent
		xx: scale
		xy: 0
		yx: 0
		yy: scale
]

{ #category : 'reading' }
TTGlyfGlyphSource >> applyTransformFromFlags: aFlagWord to: aComponent [
	"The transform a component record states, read from the entry standing on it. The three
	 forms are mutually exclusive and are tested in the order the specification writes them,
	 because each reads a different number of F2Dot14 numbers and reading the wrong one leaves
	 the entry over the next field. A record stating none of the three leaves the component
	 with the identity it was built with."

	(aFlagWord allMask: self class componentHasMatrixFlag) ifTrue: [
		^ self applyMatrixTo: aComponent ].
	(aFlagWord allMask: self class componentHasTwoScalesFlag) ifTrue: [
		^ self applyTwoScalesTo: aComponent ].
	(aFlagWord allMask: self class componentHasOneScaleFlag) ifTrue: [
		^ self applyOneScaleTo: aComponent ]
]

{ #category : 'reading' }
TTGlyfGlyphSource >> applyTwoScalesTo: aComponent [
	"One scale for x and another for y, in that order, and nothing off the diagonal."

	| xScale |
	xScale := self nextTwoDotFourteen.
	aComponent
		xx: xScale
		xy: 0
		yx: 0
		yy: self nextTwoDotFourteen
]

{ #category : 'inspector' }
TTGlyfGlyphSource >> boxDescriptionOf: aGlyph [
	"The four edges of the box a glyph states, in the order the glyf table writes them. A
	 Rectangle is not used: an empty one is normalised into one that holds points, and a glyph
	 whose top is above its bottom in font units would be rewritten rather than shown."

	^ String streamContents: [ :stream |
		  { aGlyph boundsLeft. aGlyph boundsBottom. aGlyph boundsRight. aGlyph boundsTop }
			  do: [ :each | stream print: each ]
			  separatedBy: [ stream space ] ]
]

{ #category : 'reading' }
TTGlyfGlyphSource >> componentsOfCompositeGlyphAt: aGlyphIndex [
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

{ #category : 'accessing' }
TTGlyfGlyphSource >> contoursOfGlyphAt: aGlyphIndex [
	"A composite glyph draws the contours of its components, each one placed and transformed by
	 its own record, and a component may itself be a composite."

	| glyph |
	glyph := self glyphAt: aGlyphIndex.
	glyph isComposite ifFalse: [ ^ super contoursOfGlyphAt: aGlyphIndex ].
	^ (self componentsOfCompositeGlyphAt: aGlyphIndex) flatCollect: [ :component |
		  (self contoursOfGlyphAt: component glyphIndex) collect: [ :contour |
			  contour collect: [ :point | component transformedPoint: point ] ] ]
]

{ #category : 'inspector' }
TTGlyfGlyphSource >> inspectorGlyphs: aBuilder [
	<inspectorPresentationOrder: 20 title: 'Glyphs'>
	"Every glyph of the font as the glyf table wrote it: how many contours it owns, whether it
	 is a composite that owns none of its points and borrows them from other glyphs, the
	 advance width hmtx filled in, and the box the font states. Everything is in font units,
	 so a figure here divided by unitsPerEm is a fraction of the em square. The rows are read
	 from the records the table parser already built, so showing them parses nothing and moves
	 no cursor: a composite is left to the Contours tab of the glyph itself."

	^ aBuilder newTable
		  addColumn: ((SpStringTableColumn
				    title: 'Glyph'
				    evaluated: [ :each | each key printString ])
				   width: 70;
				   yourself);
		  addColumn: (SpStringTableColumn
				   title: 'Contours'
				   evaluated: [ :each | each value contourCount printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Composite'
				   evaluated: [ :each |
					   each value isComposite
						   ifTrue: [ 'yes' ]
						   ifFalse: [ 'no' ] ]);
		  addColumn: (SpStringTableColumn
				   title: 'Advance'
				   evaluated: [ :each | each value advanceWidth printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Box (l b r t)'
				   evaluated: [ :each | self boxDescriptionOf: each value ]);
		  items: self glyphEntries;
		  yourself
]

{ #category : 'reading' }
TTGlyfGlyphSource >> nextSignedByte [
	"TTFontTableDirEntry reads a byte unsigned, and a component offset is signed."

	| value |
	value := glyfEntry nextByte.
	^ value > 127
		  ifTrue: [ value - 256 ]
		  ifFalse: [ value ]
]

{ #category : 'reading' }
TTGlyfGlyphSource >> nextTwoDotFourteen [
	^ glyfEntry nextShort / self class twoDotFourteenScale
]

{ #category : 'reading' }
TTGlyfGlyphSource >> offsetFromFlags: aFlagWord [
	"Where a component record places the glyph it names, read from the entry standing on the
	 two arguments. They are words or bytes as the flags say, and signed either way."

	^ (aFlagWord allMask: self class argumentsAreWordsFlag)
		  ifTrue: [ glyfEntry nextShort @ glyfEntry nextShort ]
		  ifFalse: [ self nextSignedByte @ self nextSignedByte ]
]

{ #category : 'reading' }
TTGlyfGlyphSource >> readComponentWithFlags: aFlagWord [
	"One component record, with the entry standing on the glyph index that follows its flags. A
	 record that matches two points instead of giving an offset is rejected: no font we draw uses
	 it, and guessing the placement would move the component silently."

	| component |
	component := VGGlyphComponent glyphIndex: glyfEntry nextUShort.
	(aFlagWord allMask: self class argumentsAreOffsetsFlag) ifFalse: [
		^ Error signal: 'a component placed by matching points is not supported' ].
	component offset: (self offsetFromFlags: aFlagWord).
	self applyTransformFromFlags: aFlagWord to: component.
	^ component
]

{ #category : 'reading' }
TTGlyfGlyphSource >> readFrom: aTableDictionary count: aGlyphCount indexToLocFormat: anInteger [
	"The glyphs the glyf table holds, read at the offsets loca gave. The glyf entry and its
	 start are kept because a composite glyph is read from the table again: TTGlyfTableParser
	 keeps the component glyphs of a composite and discards the offsets that place them."

	glyphDataOffsets := (TTLocaTableParser
		                     on: (aTableDictionary at: 'loca')
		                     format: anInteger
		                     nGlyphs: aGlyphCount) process.
	glyfEntry := aTableDictionary at: 'glyf'.
	glyfStart := glyfEntry offset.
	glyphs := (TTGlyfTableParser
		           on: glyfEntry
		           nGlyphs: aGlyphCount
		           offsets: glyphDataOffsets) process.
	^ self
]
