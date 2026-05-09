"
Pure byte-parsing helpers extracted from TTFontReader.
Each class-side method takes a TTFontTableDirEntry and returns structured data
(a Dictionary) with no side effects on any font description.
This separation makes table parsing independently testable.
"
Class {
	#name : 'TTFontParser',
	#superclass : 'Object',
	#category : 'VectorGraphics-TrueType',
	#package : 'VectorGraphics',
	#tag : 'TrueType'
}

{ #category : 'parsing' }
TTFontParser class >> parseCmap: entry [

	"Parse a cmap subtable starting at the current entry position.
	Dispatches to format 0, 4, or 6. Returns an Array (glyph index map) or nil."

	| cmapFmt length entryCount segCount segments offset cmap firstCode |
	cmapFmt := entry nextUShort.
	length := entry nextUShort.
	entry skip: 2. "skip version"

	cmapFmt = 0 ifTrue: [ "byte encoded table"
		length := length - 6. "should be always 256"
		length <= 0 ifTrue: [ ^ nil ].
		cmap := Array new: length.
		entry nextBytes: length into: cmap startingAt: entry offset.
		^ cmap ].

	cmapFmt = 4 ifTrue: [ "segment mapping to delta values"
		segCount := entry nextUShort // 2.
		entry skip: 6. "skip searchRange, entrySelector, rangeShift"
		segments := (1 to: segCount) collect: [ :e | Array new: 4 ].
		1 to: segCount do: [ :i | (segments at: i) at: 2 put: entry nextUShort ]. "endCount"
		entry skip: 2. "skip reservedPad"
		1 to: segCount do: [ :i | (segments at: i) at: 1 put: entry nextUShort ]. "startCount"
		1 to: segCount do: [ :i | (segments at: i) at: 3 put: entry nextShort ]. "idDelta"
		offset := entry offset.
		1 to: segCount do: [ :i | (segments at: i) at: 4 put: entry nextUShort ]. "idRangeOffset"
		entryCount := segments inject: 0 into: [ :max :seg | max max: seg second ].
		cmap := Array new: entryCount + 1 withAll: 0.
		segments withIndexDo: [ :seg :si |
			| code |
			seg first to: seg second do: [ :i |
				seg last > 0
					ifTrue: [
						entry offset: i - seg first - 1 * 2 + seg last + si + si + offset.
						code := entry nextUShort.
						code > 0 ifTrue: [ code := code + seg third ] ]
					ifFalse: [ code := i + seg third ].
				cmap at: i + 1 put: code ] ].
		^ cmap ].

	cmapFmt = 6 ifTrue: [ "trimmed table"
		firstCode := entry nextUShort.
		entryCount := entry nextUShort.
		cmap := Array new: entryCount + firstCode withAll: 0.
		entryCount timesRepeat: [
			cmap at: (firstCode := firstCode + 1) put: entry nextUShort ].
		^ cmap ].
	^ nil
]

{ #category : 'parsing' }
TTFontParser class >> parseFontHeader: entry [

	"Parse the 'head' table. Returns a Dictionary with:
		#units         — unitsPerEm (UShort)
		#bounds        — Rectangle (xMin@yMin corner: xMax@yMax)
		#indexToLocFormat — SHORT (0=short offsets, 1=long offsets)"

	| units origin corner indexToLocFormat |
	entry skip: 18. "version(4) + revision(4) + checkSumAdj(4) + magic(4) + flags(2)"
	units := entry nextUShort.
	entry skip: 16. "created(8) + modified(8)"
	origin := entry nextShort @ entry nextShort.
	corner := entry nextShort @ entry nextShort.
	entry skip: 6. "macStyle(2) + lowestRecPPEM(2) + fontDirHint(2)"
	indexToLocFormat := entry nextShort.
	^ Dictionary with: #units -> units
	             with: #bounds -> (origin corner: corner)
	             with: #indexToLocFormat -> indexToLocFormat
]

{ #category : 'parsing' }
TTFontParser class >> parseGlyphFlags: entry size: nPts [

	"Read run-length-encoded glyph flags. Returns a ByteArray of size nPts."

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

{ #category : 'parsing' }
TTFontParser class >> parseHorizontalHeader: entry [

	"Parse the 'hhea' table. Returns a Dictionary with:
		#ascent        — SHORT
		#descent       — SHORT (usually negative)
		#lineGap       — SHORT
		#numHMetrics   — USHORT"

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

{ #category : 'parsing' }
TTFontParser class >> parseKernPairsType0: entry [

	"Parse a kern subtable type 0. Returns an Array of TTKernPair."

	| nKernPairs kernPairs kp |
	nKernPairs := entry nextUShort.
	entry skip: 6. "searchRange + entrySelector + rangeShift"
	kernPairs := Array new: nKernPairs.
	1 to: nKernPairs do: [ :i |
		kp := TTKernPair new.
		kp left: entry nextUShort.
		kp right: entry nextUShort.
		kp value: entry nextShort.
		kernPairs at: i put: kp ].
	^ kernPairs
]

{ #category : 'parsing' }
TTFontParser class >> parseMaximumProfile: entry [

	"Parse the 'maxp' table. Returns the glyph count (UShort)."

	entry skip: 4. "version"
	^ entry nextUShort
]

{ #category : 'parsing' }
TTFontParser class >> parseNamingTable: entry [

	"Parse the 'name' table. Returns an Array of 8 strings (empty string if not present)."

	| nRecords initialOffset format storageOffset strings |
	strings := Array new: 8.
	strings atAllPut: ''.
	initialOffset := entry offset.
	format := entry nextUShort.
	format = 0 ifFalse: [
		self error: 'Cannot handle format 1 naming tables' ].
	nRecords := entry nextUShort.
	storageOffset := entry nextUShort + initialOffset.
	1 to: nRecords do: [ :i |
		| pID sID lID nID length offset multiBytes string |
		pID := entry nextUShort.
		sID := entry nextUShort.
		lID := entry nextUShort.
		nID := entry nextUShort.
		length := entry nextUShort.
		offset := entry nextUShort.
		(pID = 1 or: [ pID = 3 and: [ sID = 1 ] ]) ifTrue: [
			multiBytes := pID = 3.
			string := entry
				          stringAt: storageOffset + offset
				          length: length
				          multiByte: multiBytes.
			((pID = 1 and: [ lID = 0 ]) or: [ pID = 3 and: [ lID = 16r0409 ] ])
				ifTrue: [
					nID < strings size ifTrue: [
						(pID = 1 or: [ (strings at: nID + 1) = '' ]) ifTrue: [
							strings at: nID + 1 put: string ] ] ] ] ].
	^ strings
]

{ #category : 'parsing' }
TTFontParser class >> selectGlyphFor: codePoint from: characterMap glyphs: glyphs unknownGlyph: unknownGlyph [

	"Select the best glyph for codePoint. Substitutes wide minus and centered asterisk
	Unicode code points for the ASCII dash and star. Falls back to the original codePoint
	if the preferred substitute is absent from the font."

	| preferredCodePoint g |
	preferredCodePoint := codePoint.
	codePoint = $- codePoint ifTrue: [ preferredCodePoint := 16r2212 ].
	codePoint = $* codePoint ifTrue: [ preferredCodePoint := 16r2217 ].
	g := glyphs at: (characterMap at: preferredCodePoint + 1) + 1 ifAbsent: [ unknownGlyph ].
	g == unknownGlyph ifTrue: [
		g := glyphs at: (characterMap at: codePoint + 1) + 1 ifAbsent: [ unknownGlyph ] ].
	^ g
]
