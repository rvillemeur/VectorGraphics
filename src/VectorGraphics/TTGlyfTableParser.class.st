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
	#category : 'VectorGraphics-TrueType',
	#package : 'VectorGraphics',
	#tag : 'TrueType'
}

{ #category : 'instance creation' }
TTGlyfTableParser class >> on: anEntry nGlyphs: n offsets: offsetArray [

	^ self new initWithEntry: anEntry nGlyphs: n offsets: offsetArray
]

{ #category : 'initialization' }
TTGlyfTableParser >> initWithEntry: anEntry nGlyphs: n offsets: offsetArray [

	super initWithEntry: anEntry.
	nGlyphs := n.
	glyphOffsets := offsetArray
]

{ #category : 'parsing - private' }
TTGlyfTableParser >> parseCompositeGlyph [

	| glyph flags glyphIndex hasInstructions ofsX ofsY iLen geometryTransformation bb bl br bt |
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

	(flags allMask: 1)
		ifTrue: [ "'Hay Offset short x@y'"
			ofsX := entry nextShort.
			ofsY := entry nextShort ]
		ifFalse: [ "'Hay Offset byte x@y'"
			(ofsX := entry nextByte) > 127 ifTrue: [ ofsX := ofsX - 256 ].
			(ofsY := entry nextByte) > 127 ifTrue: [ ofsY := ofsY - 256 ] ]. "ARG_1_AND_2_ARE_WORDS"

	(flags allMask: 2) ifFalse: [ self halt ]. "ARGS_ARE_XY_VALUES — unsupported"
	"ROUND_XY_TO_GRID = 4. Ignored"
	"AffineTransformation removed. Composite sub-transformations not applied — passed as nil.
	Flags 8 (WE_HAVE_A_SCALE), 64 (WE_HAVE_AN_X_AND_Y_SCALE), 128 (WE_HAVE_A_TWO_BY_TWO)
	still consume the correct number of bytes from the stream."
	(flags anyMask: 8 + 64 + 128) ifFalse: [
		geometryTransformation := nil ].
	(flags allMask: 8) ifTrue: [
		entry nextShort. "consume WE_HAVE_A_SCALE bytes"
		geometryTransformation := nil ].
	(flags allMask: 64) ifTrue: [
		entry nextShort. entry nextShort. "consume WE_HAVE_AN_X_AND_Y_SCALE bytes"
		geometryTransformation := nil ].
	(flags allMask: 128) ifTrue: [
		entry nextShort. entry nextShort. entry nextShort. entry nextShort. "consume 2x2 bytes"
		geometryTransformation := nil ].

	glyph addGlyph: glyphIndex transformation: geometryTransformation.
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
