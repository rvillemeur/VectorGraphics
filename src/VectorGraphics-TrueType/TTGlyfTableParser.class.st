"
Parser for the TrueType 'glyf' (Glyph Data) table.

Reads all glyph outlines and returns an Array of TTGlyph / TTCompositeGlyph.
Uses the loca offset array to locate each glyph within the table.

## Constructor
  `TTGlyfTableParser on: entry nGlyphs: n offsets: offsetArray`
  - n: glyph count from 'maxp'
  - offsetArray: per-glyph byte offsets from TTLocaTableParser

## Internal structure
  - `process` — top-level: iterates over glyphs, dispatches to simple/composite
  - `parseSimpleGlyph:` — reads contours, flags, x/y coordinates for a simple glyph
  - `parseCompositeGlyph` — reads component references for a composite glyph
  - `parseGlyphFlags:` — decodes run-length-encoded flag bytes
  - `readXCoords:nContours:flags:endPoints:` — reads x coordinate deltas
  - `readYCoords:nContours:flags:endPoints:` — reads y coordinate deltas
"
Class {
	#name : 'TTGlyfTableParser',
	#superclass : 'TTFontParser',
	#instVars : [
		'nGlyphs',
		'glyphOffsets'
	],
	#category : 'VectorGraphics-TrueType-Reading',
	#package : 'VectorGraphics-TrueType',
	#tag : 'Reading'
}

{ #category : 'instance creation' }
TTGlyfTableParser class >> on: anEntry nGlyphs: n offsets: offsetArray [

	^ self new initWithEntry: anEntry nGlyphs: n offsets: offsetArray
]

{ #category : 'initialization' }
TTGlyfTableParser >> initWithEntry: anEntry nGlyphs: n offsets: offsetArray [

	entry := anEntry.
	nGlyphs := n.
	glyphOffsets := offsetArray
]

{ #category : 'reading' }
TTGlyfTableParser >> parseCompositeGlyph [
	| glyph flags glyphIndex hasInstructions iLen bb bl br bt |
	glyph := TTCompositeGlyph new.
	bl := entry nextShort.
	bt := entry nextShort.
	br := entry nextShort.
	bb := entry nextShort.
	glyph
		boundsLeft: bl
		boundsRight: br
		boundsTop: bt
		boundsBottom: bb.
	hasInstructions := false.
	[
	flags := entry nextUShort.
	glyphIndex := entry nextUShort + 1.
	"The component offset is consumed and dropped: sub-transformations are not applied, so the
	only thing that matters here is leaving the stream on the next field. ARG_1_AND_2_ARE_WORDS
	says whether it is two shorts or two bytes."
	(flags allMask: 1)
		ifTrue: [
			entry nextShort.
			entry nextShort ]
		ifFalse: [
			entry nextByte.
			entry nextByte ].
	(flags allMask: 2) ifFalse: [
		"ARGS_ARE_XY_VALUES is clear: the two arguments are point numbers to match rather than
		an offset. Raising here is the whole support this parser has for that format."
		self error: 'composite glyph matches points instead of offsetting, which is unsupported' ].
	"ROUND_XY_TO_GRID = 4. Ignored"
	"The sub-transformation is never applied — the component is added with nil — but its bytes
	must still leave the stream on the next field: WE_HAVE_A_SCALE one short,
	WE_HAVE_AN_X_AND_Y_SCALE two, WE_HAVE_A_TWO_BY_TWO four."
	(flags allMask: 8) ifTrue: [ entry nextShort ].
	(flags allMask: 64) ifTrue: [
		entry nextShort.
		entry nextShort ].
	(flags allMask: 128) ifTrue: [
		entry nextShort.
		entry nextShort.
		entry nextShort.
		entry nextShort ].
	glyph addGlyph: glyphIndex transformation: nil.
	hasInstructions := hasInstructions or: [ flags allMask: 256 "WE_HAVE_INSTRUCTIONS" ].
	"Continue as long as the MORE_COMPONENTS bit is set"
	flags allMask: 32 "MORE_COMPONENTS" ] whileTrue.
	hasInstructions ifTrue: [
		iLen := entry nextUShort.
		entry skip: iLen ].
	^ glyph
]

{ #category : 'parsing - private' }
TTGlyfTableParser >> parseGlyphFlags: nPts [

	"Decode run-length-encoded glyph flags. Returns a ByteArray of size nPts."

	| flags index repCount flagBits |
	flags := ByteArray new: nPts.
	index := 1.
	[ index <= nPts ] whileTrue: [
		flagBits := entry nextByte.
		flags at: index put: flagBits.
		(flagBits allMask: 8) ifTrue: [
			repCount := entry nextByte.
			repCount timesRepeat: [
				index := index + 1.
				flags at: index put: flagBits ] ].
		index := index + 1 ].
	^ flags
]

{ #category : 'parsing - private' }
TTGlyfTableParser >> parseSimpleGlyph: nContours [

	| glyph endPts nPts iLength flags bb bl br bt |
	glyph := TTGlyph new.
	bl := entry nextShort.
	bt := entry nextShort.
	br := entry nextShort.
	bb := entry nextShort.
	glyph
		boundsLeft: bl
		boundsRight: br
		boundsTop: bt
		boundsBottom: bb.
	endPts := Array new: nContours.
	1 to: nContours do: [ :i | endPts at: i put: entry nextUShort ].
	glyph initializeContours: nContours with: endPts.
	nContours = 0 ifTrue: [ ^ glyph ].
	nPts := endPts last + 1.
	iLength := entry nextUShort. "instruction length"
	entry skip: iLength.
	flags := self parseGlyphFlags: nPts.
	self
		readXCoords: glyph
		nContours: nContours
		flags: flags
		endPoints: endPts.
	self
		readYCoords: glyph
		nContours: nContours
		flags: flags
		endPoints: endPts.
	glyph makePointsAbsolute.
	^ glyph
]

{ #category : 'parsing' }
TTGlyfTableParser >> process [

	"Parse all glyphs. Returns an Array of TTGlyph indexed by glyph number."

	| initialOffset glyphs glyph glyphOffset nextOffset glyphLength numberOfContours |
	initialOffset := entry offset.
	glyphs := Array new: nGlyphs.
	1 to: nGlyphs do: [ :glyphIndex |
		glyphOffset := glyphOffsets at: glyphIndex.
		nextOffset := glyphOffsets at: glyphIndex + 1.
		glyphLength := nextOffset - glyphOffset.
		glyph := glyphLength = 0
			          ifTrue: [ TTGlyph new ]
			          ifFalse: [
				          entry offset: initialOffset + glyphOffset.
				          numberOfContours := entry nextShort.
				          numberOfContours >= 0
					          ifTrue: [ self parseSimpleGlyph: numberOfContours ]
					          ifFalse: [ self parseCompositeGlyph ] ].
		glyphs at: glyphIndex put: glyph ].
	glyphs do: [ :g | g replaceIndexesByComponentGlyphsIn: glyphs ].
	^ glyphs
]

{ #category : 'parsing - private' }
TTGlyfTableParser >> readXCoords: glyph nContours: nContours flags: flags endPoints: endPts [

	"Read x coordinate deltas for each point in each contour."

	| startPoint endPoint flagBits xValue contour |
	startPoint := 1.
	1 to: nContours do: [ :i |
		contour := glyph contours at: i.
		endPoint := (endPts at: i) + 1.
		startPoint to: endPoint do: [ :j |
			flagBits := flags at: j.
			contour controlPointFlags
				bitAt: j - startPoint + 1
				put: 1 - (flagBits bitAnd: 1).
			xValue := (flagBits allMask: 2)
				          ifTrue: [ "one byte"
					          (flagBits allMask: 16)
						          ifTrue: [ entry nextByte ]
						          ifFalse: [ entry nextByte negated ] ]
				          ifFalse: [ "two bytes"
					          (flagBits allMask: 16)
						          ifTrue: [ 0 ]
						          ifFalse: [ entry nextShort ] ].
			contour points at: j - startPoint + 1 putX: xValue ].
		startPoint := endPoint + 1 ]
]

{ #category : 'parsing - private' }
TTGlyfTableParser >> readYCoords: glyph nContours: nContours flags: flags endPoints: endPts [

	"Read y coordinate deltas for each point in each contour."

	| startPoint endPoint flagBits yValue contour |
	startPoint := 1.
	1 to: nContours do: [ :i |
		contour := glyph contours at: i.
		endPoint := (endPts at: i) + 1.
		startPoint to: endPoint do: [ :j |
			flagBits := flags at: j.
			yValue := (flagBits allMask: 4)
				          ifTrue: [ "one byte"
					          (flagBits allMask: 32)
						          ifTrue: [ entry nextByte ]
						          ifFalse: [ entry nextByte negated ] ]
				          ifFalse: [ "two bytes"
					          (flagBits allMask: 32)
						          ifTrue: [ 0 ]
						          ifFalse: [ entry nextShort ] ].
			contour points at: j - startPoint + 1 putY: yValue ].
		startPoint := endPoint + 1 ]
]
