"
Parser for the TrueType 'cmap' (Character Map) table.

Scans the subtable directory for a Unicode platform entry (platformID = 0), then delegates
to the appropriate format parser (format 0, 4, or 6). Returns an Array mapping code point
indices to glyph indices, or nil if no Unicode subtable is found.

TTFontReader checks for nil and signals an error; otherwise passes the map to
TTFontDescription via mapAndStoreGlyphsUsing:glyphs:.
"
Class {
	#name : 'TTCmapTableParser',
	#superclass : 'TTFontParser',
	#category : 'VectorGraphics-TrueType',
	#package : 'VectorGraphics',
	#tag : 'TrueType'
}

{ #category : 'parsing' }
TTCmapTableParser >> parseFormat [

	"Parse a cmap subtable starting at the current entry position.
	Dispatches to format 0, 4, or 6. Returns an Array or nil."

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
TTCmapTableParser >> process [

	"Scan subtable directory for a Unicode platform entry, then parse its format."

	| initialOffset nSubTables platformID platformSpecificEncodingID offset |
	initialOffset := entry offset.
	entry skip: 2. "skip table version"
	nSubTables := entry nextUShort.
	1 to: nSubTables do: [ :i |
		platformID := entry nextUShort.
		platformSpecificEncodingID := entry nextUShort.
		offset := entry nextULong.
		platformID = 0 ifTrue: [ "Unicode platform"
			entry offset: initialOffset + offset.
			^ self parseFormat ] ].
	^ nil
]
