"
Parser for the TrueType 'hmtx' (Horizontal Metrics) table.

Mutates the glyphs array in place, setting advanceWidth, leftSideBearing, and
rightSideBearing on each TTGlyph. The table stores full advance-width records for
the first numHMetrics glyphs; remaining glyphs reuse the last advance width and
store only a leftSideBearing entry.

## Constructor
  `TTHmtxTableParser on: entry glyphs: glyphsArray numHMetrics: n`
  - glyphsArray: the Array of TTGlyph built by TTGlyfTableParser
  - n: numHMetrics from TTHheaTableParser (#numHMetrics key)

`process` returns self (mutation in place; return value not used by TTFontReader).
"
Class {
	#name : 'TTHmtxTableParser',
	#superclass : 'TTFontParser',
	#instVars : [
		'glyphs',
		'numHMetrics'
	],
	#category : 'VectorGraphics-TrueType',
	#package : 'VectorGraphics',
	#tag : 'TrueType'
}

{ #category : 'instance creation' }
TTHmtxTableParser class >> on: anEntry glyphs: glyphsArray numHMetrics: n [

	^ self new initWithEntry: anEntry glyphs: glyphsArray numHMetrics: n
]

{ #category : 'initialization' }
TTHmtxTableParser >> initWithEntry: anEntry glyphs: glyphsArray numHMetrics: n [

	super initWithEntry: anEntry.
	glyphs := glyphsArray.
	numHMetrics := n
]

{ #category : 'parsing' }
TTHmtxTableParser >> process [

	| index lastAW glyph |
	index := 1.
	[ index <= numHMetrics ] whileTrue: [
		glyph := glyphs at: index.
		glyph advanceWidth: entry nextUShort.
		glyph leftSideBearing: entry nextShort.
		glyph updateRightSideBearing.
		index := index + 1 ].
	index = (glyphs size + 1) ifTrue: [ ^ self ].
	lastAW := (glyphs at: index - 1) advanceWidth.
	[ index <= glyphs size ] whileTrue: [
		glyph := glyphs at: index.
		glyph advanceWidth: lastAW.
		glyph leftSideBearing: entry nextShort.
		glyph updateRightSideBearing.
		index := index + 1 ]
]
