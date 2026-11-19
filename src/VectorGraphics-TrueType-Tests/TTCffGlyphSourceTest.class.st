"
The facts of a glyph source whose outlines are Type 2 charstrings in one `CFF ` table. My font is the one `VGFontBytesFixture` assembles around a charstring, and the common facts of any source are my superclass's.
"
Class {
	#name : 'TTCffGlyphSourceTest',
	#superclass : 'TTGlyphSourceTest',
	#category : 'VectorGraphics-TrueType-Tests-Tests',
	#package : 'VectorGraphics-TrueType-Tests',
	#tag : 'Tests'
}

{ #category : 'fixtures' }
TTCffGlyphSourceTest >> subjectFontBytes [
	"A font whose one drawn glyph is the same square, said as a Type 2 charstring in one CFF
	 table and in no glyf table at all."

	^ VGFontBytesFixture cffFontBytes
]

{ #category : 'tests' }
TTCffGlyphSourceTest >> testTheGlyphsViewSaysWhichCharstringsAreDrawnAndDrawsNone [
	"The view a reader opens on the source of a CFF font says, of every glyph, whether its
	 charstring has been interpreted yet and the advance width hmtx filled in, which costs no
	 charstring. Opening the view must leave every glyph undrawn, or the inspector would
	 answer the question it is asked by changing the object it is showing."

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
				#( '0' 'no' '500' ).
				#( '1' 'no' '500' ) }.
	self
		assert: ((0 to: source glyphCount - 1) allSatisfy: [ :index |
				 (source glyphAt: index) isDrawn not ])
]
