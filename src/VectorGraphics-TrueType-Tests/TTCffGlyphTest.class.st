"
I test the glyph record an OpenType font answers: one that interprets its own charstring the first time somebody asks for its shape. Every fact a drawn glyph states must hold of me too, whichever selector is asked first, because the font description and the drawing loop read a glyph through whatever accessor they happen to need.
"
Class {
	#name : 'TTCffGlyphTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-TrueType-Tests-CFF',
	#package : 'VectorGraphics-TrueType-Tests',
	#tag : 'CFF'
}

{ #category : 'running' }
TTCffGlyphTest >> glyphAtIndex: anInteger [
	"A glyph record of the fixture font, built but not drawn. The font draws one square,
	 from 50 @ 100 to 450 @ 400."

	| parser |
	parser := (TTCffTableParser on: (TTCffBytesFixture new
		            charstrings: { (TTCffBytesFixture charstringBytesWith:
				             #( 50 100 #rmoveto 400 #hlineto 300 #vlineto -400
				                #hlineto #endchar )) };
		            yourself) tableCursor) process.
	^ TTCffGlyph onTable: parser index: anInteger
]

{ #category : 'tests' }
TTCffGlyphTest >> testACharstringThisReaderCannotDrawRaisesWhereTheShapeIsAskedFor [
	"An operator this reader does not draw must not stop a font from being read: every
	 other glyph of it still draws. So the record is built without complaint and raises
	 only when something asks it for its shape."

	| parser glyph |
	parser := (TTCffTableParser on: (TTCffBytesFixture new
		            charstrings: { ((TTCffBytesFixture charstringBytesWith:
				             #( 50 100 #rmoveto )) , #[ 2 ]) };
		            yourself) tableCursor) process.
	glyph := TTCffGlyph onTable: parser index: 1.
	self deny: glyph isDrawn.
	self should: [ glyph contours ] raise: TTCffError.
	self deny: glyph isDrawn
]

{ #category : 'tests' }
TTCffGlyphTest >> testARecordDrawsNothingUntilItsShapeIsAsked [
	"A face reads the metrics of three thousand glyphs and draws none of them. So a record
	 answers that it is not drawn, and keeps answering it until something asks for a fact
	 the charstring holds."

	| glyph |
	glyph := self glyphAtIndex: 1.
	self deny: glyph isDrawn.
	self deny: glyph isDrawn.
	glyph contours.
	self assert: glyph isDrawn.
	self assert: glyph printString equals: 'TTCffGlyph(1, 1 contours)'
]

{ #category : 'tests' }
TTCffGlyphTest >> testEveryFactOfAGlyphIsAnsweredWhicheverSelectorDrawsIt [
	"A reader of a glyph does not know it is lazy: the font description asks the letter M for
	 its top side bearing, the drawing loop asks for contour data, the inspector asks for the
	 extent of the points. Each one must draw the glyph it reads, so the answer is the same
	 whichever is asked first — a font whose description divided by an undrawn top side
	 bearing raised a ZeroDivide."

	| drawn |
	drawn := self glyphAtIndex: 1.
	drawn contours.
	self
		assert: (self glyphAtIndex: 1) topSideBearing
		equals: drawn topSideBearing.
	self
		assert: (self glyphAtIndex: 1) inspectorPointExtent
		equals: drawn inspectorPointExtent.
	self
		assert: (Float32Array streamContents: [ :stream |
				 (self glyphAtIndex: 1) addContourDataTo: stream ])
		equals: (Float32Array streamContents: [ :stream |
				 drawn addContourDataTo: stream ])
]

{ #category : 'tests' }
TTCffGlyphTest >> testEverySelectorThatNeedsTheCharstringDrawsTheRecord [
	"Whichever fact of the shape is asked for first draws the glyph: the box, its four
	 edges, how many contours there are, the room the box leaves. A selector left out of
	 this list answers whatever the record held before it was drawn, which is nothing."

	#( #contours #contourCount #boundsLeft #boundsRight #boundsTop #boundsBottom
	   #rightSideBearing ) do: [ :selector |
		| glyph |
		glyph := self glyphAtIndex: 1.
		glyph perform: selector.
		self assert: glyph isDrawn description: selector printString , ' drew nothing' ]
]

{ #category : 'tests' }
TTCffGlyphTest >> testTheBoxIsTheExtentOfThePointsTheCharstringDraws [
	"The fixture draws one square from 50 @ 100 to 450 @ 400. The box of the drawn glyph is
	 that square, and one contour holds it."

	| glyph |
	glyph := self glyphAtIndex: 1.
	self assert: glyph contourCount equals: 1.
	self assert: glyph boundsLeft equals: 50.
	self assert: glyph boundsRight equals: 450.
	self assert: glyph boundsTop equals: 100.
	self assert: glyph boundsBottom equals: 400
]

{ #category : 'tests' }
TTCffGlyphTest >> testTheMetricsHmtxWroteSurviveTheDrawingAndTheRoomTheBoxLeavesIsComputedByIt [
	"The advance and the left side bearing are written by TTHmtxTableParser before anybody
	 asks for a shape, and drawing must not overwrite them. The right side bearing cannot
	 be written then, since it needs the box: the hook hmtx sends leaves it alone, and
	 drawing computes it — 150 font units for a square of 50 to 450 in an advance of 600."

	| glyph |
	glyph := self glyphAtIndex: 1.
	glyph
		advanceWidth: 600;
		leftSideBearing: 50;
		updateRightSideBearing.
	self deny: glyph isDrawn.
	self assert: glyph contours size equals: 1.
	self assert: glyph advanceWidth equals: 600.
	self assert: glyph leftSideBearing equals: 50.
	self assert: glyph rightSideBearing equals: 150
]

{ #category : 'tests' }
TTCffGlyphTest >> testTheRecordViewReadsTheGlyphWithoutDrawingIt [
	"The view a reader opens on a lazy record says what the record knows before any charstring
	 is read: which glyph it is, that it is not drawn, how many bytes its charstring holds and
	 the three widths it will be drawn with. Opening it must leave the record undrawn, or the
	 inspector would answer a question by changing the object it is showing."

	| glyph builder presenter rows |
	glyph := self glyphAtIndex: 1.
	builder := SpPresenterBuilder newApplication: SpApplication new.
	presenter := (StInspectionContext new
		              inspectedObject: glyph;
		              methodSelector: #inspectorRecord:;
		              yourself) basicNewInspectionPresenter: builder.
	rows := presenter items collect: [ :item |
		        (presenter columns first evaluation value: item)
		        -> (presenter columns last evaluation value: item) ].
	self assert: rows asArray equals: {
			('glyph index' -> '1').
			('drawn' -> 'false').
			('charstring bytes' -> '13').
			('advance width' -> '0').
			('default width x' -> '0').
			('nominal width x' -> '0') }.
	self assert: glyph printString equals: 'TTCffGlyph(1, not drawn)'
]

{ #category : 'tests' }
TTCffGlyphTest >> testTheRecordsOfATableAreOneGlyphEachCountedFromOneAndNoneOfThemDrawn [
	"A face asks its table for every glyph at once, and that must read no charstring: the
	 records are built in the order of the charstrings and counted from one, as a CFF
	 table counts them."

	| parser records |
	parser := (TTCffTableParser on: (TTCffBytesFixture new
		            charstrings: {
				            (TTCffBytesFixture charstringBytesWith:
					             #( 50 100 #rmoveto 400 #hlineto 300 #vlineto -400 #hlineto
					                #endchar )).
				            (TTCffBytesFixture charstringBytesWith: #( #endchar )) };
		            yourself) tableCursor) process.
	records := TTCffGlyph onTable: parser count: 2.
	self assert: records size equals: 2.
	self assert: (records collect: [ :each | each isDrawn ]) equals: #( false false ).
	self
		assert: (records collect: [ :each | each printString ])
		equals: #( 'TTCffGlyph(1, not drawn)' 'TTCffGlyph(2, not drawn)' )
]
