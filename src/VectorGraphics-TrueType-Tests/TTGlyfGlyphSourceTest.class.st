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

{ #category : 'fixtures' }
TTGlyfGlyphSourceTest >> subjectFontBytes [
	"A font whose one drawn glyph is a square in the glyf table, placed by the offsets loca
	 states."

	^ VGFontBytesFixture fontBytesWithGlyphRecords:
		  { (VGFontBytesFixture simpleGlyphRecordFrom: 50 @ 100 to: 450 @ 400) }
]

{ #category : 'tests' }
TTGlyfGlyphSourceTest >> testTheGlyphsViewListsEveryGlyphWithItsContourCountAndBox [
	"The view a reader opens on the source of a glyf font says, of every glyph the font holds,
	 how many contours it owns, whether it is a composite that owns none of its points, the
	 advance width hmtx filled in and the box the font states, all in font units. The glyph
	 the fixture draws is a square; glyph zero is the empty one every font begins with."

	| source builder presenter rows |
	source := self sourceForFontBytes: self subjectFontBytes.
	builder := SpPresenterBuilder newApplication: SpApplication new.
	presenter := (StInspectionContext new
		              inspectedObject: source;
		              methodSelector: #inspectorGlyphs:;
		              yourself) basicNewInspectionPresenter: builder.
	rows := presenter items collect: [ :item |
		        presenter columns collect: [ :column |
			        column evaluation value: item ] ].
	self
		assert: (rows collect: [ :each | each asArray ]) asArray
		equals: {
				#( '0' '0' 'no' '500' '0 0 0 0' ).
				#( '1' '1' 'no' '500' '50 400 450 100' ) }
]
