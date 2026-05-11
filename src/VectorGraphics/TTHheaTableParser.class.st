"
Parser for the TrueType 'hhea' (Horizontal Header) table.

Returns a Dictionary with four keys:
  #ascent       — Short, typically positive (design units above baseline)
  #descent      — Short, typically negative (design units below baseline)
  #lineGap      — Short, additional line spacing
  #numHMetrics  — UShort, number of full advance-width entries in 'hmtx'

TTFontReader uses #ascent/#descent/#lineGap to initialise TTFontDescription vertical metrics,
and passes #numHMetrics to TTHmtxTableParser.
"
Class {
	#name : 'TTHheaTableParser',
	#superclass : 'TTFontParser',
	#category : 'VectorGraphics-TrueType',
	#package : 'VectorGraphics',
	#tag : 'TrueType'
}

{ #category : 'parsing' }
TTHheaTableParser >> process [

	| ascent descent lineGap numHMetrics |
	entry skip: 4. "version"
	ascent := entry nextShort.
	descent := entry nextShort.
	lineGap := entry nextShort.
	entry skip: 24.
	"advanceWidthMax(2) + minLSB(2) + minRSB(2) + xMaxExtent(2)
	 + caretSlopeRise(2) + caretSlopeRun(2) + reserved×5(10) + metricDataFormat(2)"
	numHMetrics := entry nextUShort.
	^ Dictionary
		  with: #ascent -> ascent
		  with: #descent -> descent
		  with: #lineGap -> lineGap
		  with: #numHMetrics -> numHMetrics
]
