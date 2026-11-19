"
The facts of a glyph source whose outlines are in a `glyf` table. My font is built byte by byte by `VGFontBytesFixture`, so a test states the record it reads, and the common facts of any source are my superclass's.
"
Class {
	#name : 'TTGlyfGlyphSourceTest',
	#superclass : 'TTGlyphSourceTest',
	#category : 'VectorGraphics-TrueType-Tests-Tests',
	#package : 'VectorGraphics-TrueType-Tests',
	#tag : 'Tests'
}

{ #category : 'support' }
TTGlyfGlyphSourceTest >> sourceWithAComponentWithFlags: aFlagWord arguments: anArray transform: aTransformArray [
	"A source whose glyph 1 is the square of the fixture and whose glyph 2 is a composite
	 naming that square once, through a component record stating the flags, the arguments and
	 the transform given. The offsets flag is added here: a record without it is rejected, and
	 the tests below are about what follows the offsets, not about that rejection."

	^ self sourceForFontBytes: (VGFontBytesFixture fontBytesWithGlyphRecords: {
			   (VGFontBytesFixture simpleGlyphRecordFrom: 50 @ 100 to: 450 @ 400).
			   (VGFontBytesFixture compositeGlyphRecordWithComponents: {
					    (VGFontBytesFixture
						     componentRecordWithFlags:
						     aFlagWord + TTGlyfGlyphSource argumentsAreOffsetsFlag
						     glyphIndex: 1
						     arguments: anArray
						     transform: aTransformArray) }) })
]

{ #category : 'fixtures' }
TTGlyfGlyphSourceTest >> subjectFontBytes [
	"A font whose one drawn glyph is a square in the glyf table, placed by the offsets loca
	 states."

	^ VGFontBytesFixture fontBytesWithGlyphRecords:
		  { (VGFontBytesFixture simpleGlyphRecordFrom: 50 @ 100 to: 450 @ 400) }
]

{ #category : 'tests' }
TTGlyfGlyphSourceTest >> testAComponentPlacedByByteOffsetsReadsThemSigned [
	"Without the words flag a component states its two offsets as single bytes, and those
	 bytes are signed: 128 means minus 128. A component pushed left by the most a byte can say
	 has to land left of the glyph it names, not far to its right."

	| source square moved |
	source := self
		          sourceWithAComponentWithFlags: 0
		          arguments: #( -128 127 )
		          transform: #(  ).
	square := source outlineOfGlyphAt: 1.
	moved := source outlineOfGlyphAt: 2.
	self
		assert: moved contours first asArray
		equals: (square contours first collect: [ :each | each + (-128 @ 127) ])
			        asArray
]

{ #category : 'tests' }
TTGlyfGlyphSourceTest >> testAComponentWithATwoByTwoMatrixTurnsThePointsOfItsGlyph [
	"A component may carry a full two by two matrix, which is four F2Dot14 numbers read as xx,
	 xy, yx then yy. The matrix here is a quarter turn, so every point of the component lands
	 at minus its own y over its own x."

	| source square turned |
	source := self
		          sourceWithAComponentWithFlags:
		          TTGlyfGlyphSource componentHasMatrixFlag
		          arguments: #( 0 0 )
		          transform: #( 0 1 -1 0 ).
	square := source outlineOfGlyphAt: 1.
	turned := source outlineOfGlyphAt: 2.
	self
		assert: turned contours first asArray
		equals: (square contours first collect: [ :each | each y negated @ each x ])
			        asArray
]

{ #category : 'tests' }
TTGlyfGlyphSourceTest >> testAComponentWithOneScaleScalesBothAxesOfItsGlyphByIt [
	"The shortest transform a component carries is one F2Dot14 number, which scales both axes
	 alike. Reading it as a matrix, or as two scales, would walk off the end of the record and
	 place the component by whatever followed it."

	| source square scaled |
	source := self
		          sourceWithAComponentWithFlags:
		          TTGlyfGlyphSource componentHasOneScaleFlag
		          arguments: #( 0 0 )
		          transform: #( 1.5 ).
	square := source outlineOfGlyphAt: 1.
	scaled := source outlineOfGlyphAt: 2.
	self
		assert: scaled contours first asArray
		equals: (square contours first collect: [ :each | each * 1.5 ]) asArray
]

{ #category : 'tests' }
TTGlyfGlyphSourceTest >> testAComponentWithTwoScalesStretchesEachAxisOfItsGlyphOnItsOwn [
	"A component may scale its glyph by one number on x and another on y, which is two F2Dot14
	 numbers and not a matrix. Both have to be read, and read in that order: the glyph here is
	 one and a half times as wide and half as tall as the square it names."

	| source square scaled |
	source := self
		          sourceWithAComponentWithFlags:
		          TTGlyfGlyphSource componentHasTwoScalesFlag
		          arguments: #( 0 0 )
		          transform: #( 1.5 0.5 ).
	square := source outlineOfGlyphAt: 1.
	scaled := source outlineOfGlyphAt: 2.
	self
		assert: scaled contours first asArray
		equals: (square contours first collect: [ :each |
				  each x * 1.5 @ (each y * 0.5) ]) asArray
]

{ #category : 'tests' }
TTGlyfGlyphSourceTest >> testTheGlyphsViewListsEveryGlyphWithItsContourCountAndBox [
	"The view a reader opens on the source of a glyf font says, of every glyph the font holds,
	 how many contours it owns, whether it is a composite that owns none of its points, the
	 advance width hmtx filled in and the box the font states, all in font units. The glyph
	 the fixture draws is a square; glyph zero is the empty one every font begins with. The
	 columns are named, because a column of figures nobody can name says nothing."

	| source builder presenter rows |
	source := self sourceForFontBytes: self subjectFontBytes.
	builder := SpPresenterBuilder newApplication: SpApplication new.
	presenter := (StInspectionContext new
		              inspectedObject: source;
		              methodSelector: #inspectorGlyphs:;
		              yourself) basicNewInspectionPresenter: builder.
	self
		assert: (presenter columns collect: [ :each | each title ]) asArray
		equals: #( 'Glyph' 'Contours' 'Composite' 'Advance' 'Box (l b r t)' ).
	rows := presenter items collect: [ :item |
		        presenter columns collect: [ :column |
			        column evaluation value: item ] ].
	self
		assert: (rows collect: [ :each | each asArray ]) asArray
		equals: {
				#( '0' '0' 'no' '500' '0 0 0 0' ).
				#( '1' '1' 'no' '500' '50 400 450 100' ) }
]
