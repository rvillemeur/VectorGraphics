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
