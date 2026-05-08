"
TTFontReader builds a TTFontDescription from a TrueType font file (.ttf).
"
Class {
	#name : 'TTFontReader',
	#superclass : 'Object',
	#instVars : [
		'glyphs',
		'nGlyphs',
		'kernPairs',
		'fontDescription'
	],
	#category : 'VectorGraphics-TrueType',
	#package : 'VectorGraphics',
	#tag : 'TrueType'
}

{ #category : 'instance creation' }
TTFontReader class >> readTTFFrom: aByteArray [

	^ self new readTTFFrom: aByteArray
]

{ #category : 'private' }
TTFontReader >> decodeCmapFmtTable: entry [

	| cmapFmt length entryCount segCount segments offset cmap firstCode |
	cmapFmt := entry nextUShort.
	length := entry nextUShort.
	entry skip: 2. "skip version"

	cmapFmt = 0 ifTrue: [ "byte encoded table"
		length := length - 6. "should be always 256"
		length <= 0 ifTrue: [ ^ nil ]. "but sometimes, this table is empty"
		cmap := Array new: length.
		entry nextBytes: length into: cmap startingAt: entry offset.
		^ cmap ].

	cmapFmt = 4 ifTrue: [ "segment mapping to deltavalues"
		segCount := entry nextUShort // 2.
		entry skip: 6. "skip searchRange, entrySelector, rangeShift"
		segments := Array new: segCount.
		segments := (1 to: segCount) collect: [ :e | Array new: 4 ].
		1 to: segCount do: [ :i | 
		(segments at: i) at: 2 put: entry nextUShort ]. "endCount"
		entry skip: 2. "skip reservedPad"
		1 to: segCount do: [ :i | 
		(segments at: i) at: 1 put: entry nextUShort ]. "startCount"
		1 to: segCount do: [ :i | 
		(segments at: i) at: 3 put: entry nextShort ]. "idDelta"
		offset := entry offset.
		1 to: segCount do: [ :i | 
		(segments at: i) at: 4 put: entry nextUShort ]. "idRangeOffset"
		entryCount := segments
			              inject: 0
			              into: [ :max :seg | max max: seg second ].
		cmap := Array new: entryCount + 1 withAll: 0.
		segments withIndexDo: [ :seg :si | 
			| code |
			seg first to: seg second do: [ :i | 
				seg last > 0
					ifTrue: [ "offset to glypthIdArray - this is really C-magic!"
						entry offset:
							i - seg first - 1 * 2 + seg last + si + si + offset.
						code := entry nextUShort.
						code > 0 ifTrue: [ code := code + seg third ] ]
					ifFalse: [ "simple offset" code := i + seg third ].
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

{ #category : 'private' }
TTFontReader >> getGlyphFlagsFrom: entry size: nPts [

	"Read in the flags for this glyph.  The outer loop gathers the flags that
	are actually contained in the table.  If the repeat bit is set in a flag
	then the next byte is read from the table; this is the number of times
	to repeat the last flag.  The inner loop does this, incrementing the
	outer loops index each time."

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

{ #category : 'processing' }
TTFontReader >> getTableDirEntry: tagString from: fontData offset: offset [

	"Find the table named tagString in fontData and return a table directory entry for it."

	| numTables pos currentTag tag |
	numTables := fontData shortAt: 5 + offset bigEndian: true.
	tag := ByteArray new: 4.
	1 to: 4 do: [ :i | tag byteAt: i put: (tagString at: i) asciiValue ].
	tag := tag longAt: 1 bigEndian: true.
	pos := 13 + offset.
	1 to: numTables do: [ :i | 
		currentTag := fontData longAt: pos bigEndian: true.
		currentTag = tag ifTrue: [ 
			^ TTFontTableDirEntry on: fontData at: pos ].
		pos := pos + 16 ].
	^ nil
]

{ #category : 'processing' }
TTFontReader >> mapAndStoreGlyphsUsing: characterMap [

	"
	https://developer.apple.com/fonts/TrueType-Reference-Manual/RM07/appendixB.html
	"

	| glyphsByIso5559s15 glyphsByUTF8 unknownGlyph nullGlyph spaceGlyph mapSize preferredCodePoint |
	unknownGlyph := glyphs first.
	nullGlyph := glyphs second.
	mapSize := characterMap size.
	glyphsByIso5559s15 := Array new: 256.
	glyphsByUTF8 := Array new: 256.
	0 to: mapSize - 1 do: [ :codePoint | 
		| g array prevByte |
		preferredCodePoint := codePoint.
		codePoint = $- codePoint ifTrue: [ preferredCodePoint := 16r2212 ]. "WIDE MINUS"
		codePoint = $* codePoint ifTrue: [ preferredCodePoint := 16r2217 ]. "CENTERED ASTERISK"
		g := glyphs
			     at: (characterMap at: preferredCodePoint + 1) + 1
			     ifAbsent: [ unknownGlyph ].
		g == unknownGlyph ifTrue: [ 
			g := glyphs
				     at: (characterMap at: codePoint + 1) + 1
				     ifAbsent: [ unknownGlyph ] ].

		g == unknownGlyph ifFalse: [ 
			(Character iso8859s15CodeForUnicodeCodePoint: codePoint) ifNotNil: [ 
				:iso8859s15 | glyphsByIso5559s15 at: iso8859s15 + 1 put: g ] ].

		array := glyphsByUTF8.
		prevByte := nil.
		Character
			evaluate: [ :byte | 
				prevByte notNil ifTrue: [ 
					array := (array at: prevByte + 1) ifNil: [ 
						         array at: prevByte + 1 put: (Array new: 256) ] ].
				prevByte := byte ]
			withUtf8BytesOfUnicodeCodePoint: codePoint.
		array at: prevByte + 1 put: g.
		codePoint = 32 ifTrue: [ spaceGlyph := g ] ].
	Character separators do: [ :s | 
		glyphsByIso5559s15 at: s codePoint + 1 put: spaceGlyph.
		glyphsByUTF8 at: s codePoint + 1 put: spaceGlyph ].
	fontDescription
		glyphsByIso8859s15: glyphsByIso5559s15
		glyphsByUtf8Bytes: glyphsByUTF8
		unknownGlyph: unknownGlyph
]

{ #category : 'processing' }
TTFontReader >> processCharacterMappingTable: entry [

	"Read the font's character to glyph index mapping table.
	If an appropriate mapping can be found then return an association
	with the format identifier and the contents of the table"

	| initialOffset nSubTables platformID platformSpecificEncodingID offset |
	initialOffset := entry offset.
	entry skip: 2. "Skip table version"
	nSubTables := entry nextUShort.
	1 to: nSubTables do: [ :i | 
		platformID := entry nextUShort.
		platformSpecificEncodingID := entry nextUShort.
		offset := entry nextULong.
		platformID = 0 ifTrue: [ "Only consider Unicode""Go to the beginning of the table"
			entry offset: initialOffset + offset.
			^ self decodeCmapFmtTable: entry ] ].
	^ nil
]

{ #category : 'processing' }
TTFontReader >> processCompositeGlyphFrom: entry [

	"Read a composite glyph from the font data."

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
		ifTrue: [ "'Hay Offset short x@y' print."
			ofsX := entry nextShort.
			ofsY := entry nextShort ]
		ifFalse: [ "'Hay Offset byte x@y' print."
			(ofsX := entry nextByte) > 127 ifTrue: [ ofsX := ofsX - 256 ].
			(ofsY := entry nextByte) > 127 ifTrue: [ ofsY := ofsY - 256 ] ]. "ARG_1_AND_2_ARE_WORDS"

	(flags allMask: 2) ifFalse: [ self halt ]. "ARGS_ARE_XY_VALUES" "Unsupported"
	"ROUND_XY_TO_GRID = 4. Ignored"
	"AffineTransformation and MorphicTranslation (Cuis-specific) removed.
	Composite glyph sub-transformations are not applied — passed as nil.
	Flags 8 (WE_HAVE_A_SCALE), 64 (WE_HAVE_AN_X_AND_Y_SCALE), 128 (WE_HAVE_A_TWO_BY_TWO)
	still consume the correct number of bytes from the stream."
	(flags anyMask: 8 + 64 + 128) ifFalse: [
		geometryTransformation := nil ]. "was: MorphicTranslation withTranslation: ofsX@ofsY"
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
	hasInstructions := hasInstructions or: [ 
		                   flags allMask: 256 "WE_HAVE_INSTRUCTIONS" ].
	"Continue as long as the MORE_COMPONENTS bit is set"
	flags allMask: 32 "MORE_COMPONENTS" ] whileTrue.
	hasInstructions ifTrue: [ "Ignore them"
		iLen := entry nextUShort.
		entry skip: iLen ].
	^ glyph
]

{ #category : 'processing' }
TTFontReader >> processFontHeaderTable: entry [

	"Value				Data Type    Description
unitsPerEm			USHORT      Granularity of the font's em square.
xMax				USHORT      Maximum X-coordinate for the entire font.
xMin				USHORT      Minimum X-coordinate for the entire font.
yMax				USHORT      Maximum Y-coordinate for the entire font.
yMin				USHORT      Minimum Y-coordinate for the entire font.
indexToLocFormat	SHORT       Used when processing the Index To Loc Table."

	| origin corner units indexToLocFormat |
	entry skip: 4. "Skip table version number"
	entry skip: 4. "Skip font revision number"
	entry skip: 4. "Skip check sum adjustment"
	entry skip: 4. "Skip magic number"
	entry skip: 2. "Skip flags"

	units := entry nextUShort.

	entry skip: 8. "Skip creation date"
	entry skip: 8. "Skip modification date"

	"Get min/max values of all glyphs"
	origin := entry nextShort @ entry nextShort.
	corner := entry nextShort @ entry nextShort.

	entry skip: 2. "Skip mac style"
	entry skip: 2. "Skip lowest rec PPEM"
	entry skip: 2. "Skip font direction hint"
	indexToLocFormat := entry nextShort.

	fontDescription setBounds: (origin corner: corner) unitsPerEm: units.
	^ indexToLocFormat
]

{ #category : 'processing' }
TTFontReader >> processGlyphDataTable: entry offsets: offsetArray [

	"Read the actual glyph data from the font.
	offsetArray contains the start offsets in the data for each glyph."

	| initialOffset |
	initialOffset := entry offset.
	glyphs := Array new: nGlyphs.
	'Reading glyph data'
		displayProgressAt: 100 @ 100
		from: 1
		to: nGlyphs
		during: [ :bar | 
			| glyph glyphOffset nextOffset glyphLength numberOfContours |
			1 to: nGlyphs do: [ :glyphIndex | 
				bar value: glyphIndex.
				glyphOffset := offsetArray at: glyphIndex.
				nextOffset := offsetArray at: glyphIndex + 1.
				glyphLength := nextOffset - glyphOffset.
				glyph := glyphLength = 0
					         ifTrue: [ TTGlyph new ]
					         ifFalse: [ 
						         entry offset: initialOffset + glyphOffset.
						         numberOfContours := entry nextShort.
						         numberOfContours >= 0
							         ifTrue: [ 
							         self
								         processSimpleGlyphContours: numberOfContours
								         from: entry ]
							         ifFalse: [ self processCompositeGlyphFrom: entry ] ].
				glyphs at: glyphIndex put: glyph ] ].
	glyphs do: [ :g | g replaceIndexesByComponentGlyphsIn: glyphs ]
]

{ #category : 'processing' }
TTFontReader >> processHorizontalHeaderTable: entry [

	"See 
https://www.freetype.org/freetype2/docs/glyphs/glyphs-3.html
https://docs.microsoft.com/en-us/typography/opentype/spec/hhea
https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6hhea.html
http://chanae.walon.org/pub/ttf/ttf_glyphs.htm

https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6.html
"

	"
ascent  						SHORT          Distance from baseline of highest ascender.
descent  					SHORT          Distance from baseline of lowest descender.
lineGap  					SHORT          Typographic line gap.
numOfLongHorMetrics  	USHORT       Number of advance widths in metrics table (HTMX Table); may be smaller than the total number of glyphs.
"

	| ascent descent lineGap numOfLongHorMetrics |
	entry skip: 4. "Skip table version"
	ascent := entry nextShort.
	descent := entry nextShort.
	lineGap := entry nextShort.
	entry skip: 2. "Skip advanceWidthMax"
	entry skip: 2. "Skip minLeftSideBearing"
	entry skip: 2. "Skip minRightSideBearing"
	entry skip: 2. "Skip xMaxExtent"
	entry skip: 2. "Skip caretSlopeRise"
	entry skip: 2. "Skip caretSlopeRun"
	entry skip: 10. "Skip 5 reserved shorts"
	entry skip: 2. "Skip metricDataFormat"

	numOfLongHorMetrics := entry nextUShort.
	fontDescription setAscent: ascent descent: descent lineGap: lineGap.
	^ numOfLongHorMetrics
]

{ #category : 'processing' }
TTFontReader >> processHorizontalMetricsTable: entry length: numHMetrics [

	"Extract the advance width, left side bearing, and right
	side bearing for each glyph from the Horizontal Metrics Table."

	| index lastAW glyph |
	index := 1.
	[ index <= numHMetrics ] whileTrue: [ 
		glyph := glyphs at: index.
		glyph advanceWidth: entry nextUShort.
		glyph leftSideBearing: entry nextShort.
		glyph updateRightSideBearing.
		index := index + 1 ].
	index = (nGlyphs + 1) ifTrue: [ ^ true ].
	lastAW := (glyphs at: index - 1) advanceWidth.

	[ index <= nGlyphs ] whileTrue: [ 
		glyph := glyphs at: index.
		glyph advanceWidth: lastAW.
		glyph leftSideBearing: entry nextShort.
		glyph updateRightSideBearing.
		index := index + 1 ]
]

{ #category : 'processing' }
TTFontReader >> processIndexToLocationTable: entry format: indexToLocFormat [

	"glyphOffset    ULONG[numGlyphs]   An array that contains each glyph's
                                 offset into the Glyph Data Table.
"

	| glyphOffset offset |
	glyphOffset := Array new: nGlyphs + 1.
	1 to: nGlyphs + 1 do: [ :i | 
		indexToLocFormat = 0
			ifTrue: [ "Format0: offset/2 is stored" 
			offset := entry nextUShort * 2 ]
			ifFalse: [ "Format1: store actual offset" 
			offset := entry nextULong ].
		glyphOffset at: i put: offset ].
	^ glyphOffset
]

{ #category : 'processing' }
TTFontReader >> processKerningSubTableType0: entry [

	| kp nKernPairs |
	nKernPairs := entry nextUShort.
	entry skip: 2. "Skip search range"
	entry skip: 2. "Skip entry selector"
	entry skip: 2. "Skip range shift"
	kernPairs := Array new: nKernPairs.
	1 to: nKernPairs do: [ :i | 
		kp := TTKernPair new.
		kp left: entry nextUShort.
		kp right: entry nextUShort.
		kp value: entry nextShort.
		kernPairs at: i put: kp ].
	^ true
]

{ #category : 'processing' }
TTFontReader >> processKerningTable: entry [

	"Extract the kerning information for pairs of glyphs."

	| version nTables covLow covHigh |
	version := entry nextUShort. "Skip table version"
	nTables := entry nextUShort. "Skip number of sub tables -- we're using the first one only"
	nTables = 0 ifTrue: [ " This detection is hacky "
		entry skip: -4. "rewind"
		^ self processOSXKerningTable: entry ].
	entry skip: 2. "Skip current subtable number"
	entry skip: 2. "Skip length of subtable"
	covHigh := entry nextByte.
	covLow := entry nextByte.

	"Make sure the format is right (kerning table and format type 0)"
	((covLow allMask: 2) or: [ covHigh ~= 0 ]) ifTrue: [ ^ false ].
	"Subtable"
	^ self processKerningSubTableType0: entry
]

{ #category : 'processing' }
TTFontReader >> processMaximumProfileTable: entry [

	"
numGlyphs         USHORT      The number of glyphs in the font.
"

	entry skip: 4. "Skip Table version number"
	nGlyphs := entry nextUShort
]

{ #category : 'processing' }
TTFontReader >> processNamingTable: entry [

	"copyright         CHARPTR     The font's copyright notice.
familyName        CHARPTR     The font's family name.
subfamilyName     CHARPTR     The font's subfamily name.
uniqueName        CHARPTR     A unique identifier for this font.
fullName          CHARPTR     The font's full name (a combination of
                                          familyName and subfamilyName).
versionName       CHARPTR     The font's version string.
"

	| nRecords initialOffset format storageOffset strings |
	strings := Array new: 8.
	strings atAllPut: ''.
	initialOffset := entry offset.
	format := entry nextUShort.
	format = 0 ifFalse: [ 
		self error: 'Cannot handle format 1 naming tables' ].
	"Get the number of name records"
	nRecords := entry nextUShort.
	"Offset from the beginning of this table"
	storageOffset := entry nextUShort + initialOffset.
	1 to: nRecords do: [ :i | 
		| pID sID lID nID length offset multiBytes string |
		pID := entry nextUShort.
		sID := entry nextUShort.
		lID := entry nextUShort.
		nID := entry nextUShort.
		length := entry nextUShort.
		offset := entry nextUShort.
		"Read only Macintosh or Microsoft strings"
		(pID = 1 or: [ pID = 3 and: [ sID = 1 ] ]) ifTrue: [ "MS uses Unicode all others single byte"
			multiBytes := pID = 3.
			string := entry
				          stringAt: storageOffset + offset
				          length: length
				          multiByte: multiBytes.

			"Select only English names.
			Note: We prefer Macintosh strings about everything."
			((pID = 1 and: [ lID = 0 ]) or: [ pID = 3 and: [ lID = 16r0409 ] ]) 
				ifTrue: [ "Put the name at the right location."
					nID < strings size ifTrue: [ 
						(pID = 1 or: [ (strings at: nID + 1) = '' ]) ifTrue: [ 
							strings at: nID + 1 put: string ] ] ] ] ].
	fontDescription setStrings: strings
]

{ #category : 'processing' }
TTFontReader >> processOSXKerningTable: entry [

	"From Apple's TrueType reference:
	
	Previous versions of the 'kern' table defined both the version and nTables fields in the header as UInt16 values and not UInt32 values. Use of the older format on OS X is discouraged (although AAT can sense an old kerning table and still make correct use of it). Microsoft Windows still uses the older format for the 'kern' table and will not recognize the newer one. Fonts targeted for OS X only should use the new format; fonts targeted for both OS X and Windows should use the old format.
	"

	"Extract the kerning information for pairs of glyphs."

	| version nTables length coverage tupleIndex |
	version := entry nextULong. "Skip table version"
	nTables := entry nextULong. "Skip number of sub tables -- we're using the first one only"

	length := entry nextULong. "Skip length of subtable"
	coverage := entry nextUShort.
	tupleIndex := entry nextUShort. "Skip tuple index"
	coverage = 0 ifFalse: [ ^ false ].
	"Make sure the format is right (kerning table and format type 0)"

	"Subtable"
	^ self processKerningSubTableType0: entry
]

{ #category : 'processing' }
TTFontReader >> processSimpleGlyphContours: nContours from: entry [

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
	nContours = 0 ifTrue: [ ^ self ].
	nPts := endPts last + 1.
	iLength := entry nextUShort. "instruction length"
	entry skip: iLength.
	flags := self getGlyphFlagsFrom: entry size: nPts.
	self
		readGlyphXCoords: entry
		glyph: glyph
		nContours: nContours
		flags: flags
		endPoints: endPts.
	self
		readGlyphYCoords: entry
		glyph: glyph
		nContours: nContours
		flags: flags
		endPoints: endPts.
	glyph makePointsAbsolute.
	^ glyph
]

{ #category : 'processing' }
TTFontReader >> readFrom: fontData fromOffset: offset [

	| headerEntry maxProfileEntry nameEntry indexLocEntry charMapEntry glyphEntry horzHeaderEntry horzMetricsEntry kerningEntry glyphOffset characterMap numHMetrics indexToLocFormat |
	"Search the tables required to build the font"
	(headerEntry := self
		                getTableDirEntry: 'head'
		                from: fontData
		                offset: offset) == nil ifTrue: [ 
		^ self error: 'This font does not have a header table' ].
	(maxProfileEntry := self
		                    getTableDirEntry: 'maxp'
		                    from: fontData
		                    offset: offset) == nil ifTrue: [ 
		^ self error: 'This font does not have a maximum profile table' ].
	(nameEntry := self
		              getTableDirEntry: 'name'
		              from: fontData
		              offset: offset) == nil ifTrue: [ 
		^ self error: 'This font does not have a name table' ].
	(indexLocEntry := self
		                  getTableDirEntry: 'loca'
		                  from: fontData
		                  offset: offset) == nil ifTrue: [ 
		^ self error: 'This font does not have a relocation table' ].
	(charMapEntry := self
		                 getTableDirEntry: 'cmap'
		                 from: fontData
		                 offset: offset) == nil ifTrue: [ 
		^ self error: 'This font does not have a character map table' ].
	(glyphEntry := self
		               getTableDirEntry: 'glyf'
		               from: fontData
		               offset: offset) == nil ifTrue: [ 
		^ self error: 'This font does not have a glyph table' ].
	(horzHeaderEntry := self
		                    getTableDirEntry: 'hhea'
		                    from: fontData
		                    offset: offset) == nil ifTrue: [ 
		^ self error: 'This font does not have a horizontal header table' ].
	(horzMetricsEntry := self
		                     getTableDirEntry: 'hmtx'
		                     from: fontData
		                     offset: offset) == nil ifTrue: [ 
		^ self error: 'This font does not have a horizontal metrics table' ].
	(kerningEntry := self
		                 getTableDirEntry: 'kern'
		                 from: fontData
		                 offset: offset) == nil ifTrue: [ "Transcript cr; show:'This font does not have a kerning table';endEntry"
		 ].


	"Process the data"
	indexToLocFormat := self processFontHeaderTable: headerEntry.
	self processMaximumProfileTable: maxProfileEntry.
	self processNamingTable: nameEntry.
	glyphOffset := self
		               processIndexToLocationTable: indexLocEntry
		               format: indexToLocFormat.
	characterMap := self processCharacterMappingTable: charMapEntry.
	characterMap isNil ifTrue: [ 
		^ self error: 'This font has no Unicode character mappings' ].
	self processGlyphDataTable: glyphEntry offsets: glyphOffset.
	numHMetrics := self processHorizontalHeaderTable: horzHeaderEntry.
	self
		processHorizontalMetricsTable: horzMetricsEntry
		length: numHMetrics.
	kerningEntry isNil
		ifTrue: [ kernPairs := #(  ) ]
		ifFalse: [ self processKerningTable: kerningEntry ].
	self mapAndStoreGlyphsUsing: characterMap.
	"jmv kernPairs refer to glyph number (in the .ttf file) while fontDescription glyphs are indexed by Unicode code point...
	Correct this before making any use of the kernPairs data."
	fontDescription setKernPairs: kernPairs
]

{ #category : 'private' }
TTFontReader >> readGlyphXCoords: entry glyph: glyph nContours: nContours flags: flags endPoints: endPts [

	"Read the x coordinates for the given glyph from the font file."

	| startPoint endPoint flagBits xValue contour |
	startPoint := 1.
	1 to: nContours do: [ :i | 
		contour := glyph contours at: i.
		"Get the end point"
		endPoint := (endPts at: i) + 1.
		"Store number of points"
		startPoint to: endPoint do: [ :j | 
			flagBits := flags at: j.
			"If bit zero in the flag is set then this point is an on-curve
			point, if not, then it is an off-curve point."
			contour controlPointFlags
				bitAt: j - startPoint + 1
				put: 1 - (flagBits bitAnd: 1).
			"First we check to see if bit one is set.  This would indicate that
			the corresponding coordinate data in the table is 1 byte long.
			If the bit is not set, then the coordinate data is 2 bytes long."
			xValue := (flagBits allMask: 2)
				          ifTrue: [ "one byte"
					          (flagBits allMask: 16)
						          ifTrue: [ entry nextByte ]
						          ifFalse: [ entry nextByte negated ] ]
				          ifFalse: [ "two byte""If bit four is set, then this coordinate is the same as the
					last one, so the relative offset (of zero) is stored.  If bit
					is not set, then read in two bytes and store it as a signed value."
					          (flagBits allMask: 16)
						          ifTrue: [ 0 ]
						          ifFalse: [ entry nextShort ] ].
			contour points at: j - startPoint + 1 putX: xValue ].
		startPoint := endPoint + 1 ]
]

{ #category : 'private' }
TTFontReader >> readGlyphYCoords: entry glyph: glyph nContours: nContours flags: flags endPoints: endPts [

	"Read the y coordinates for the given glyph from the font file."

	| startPoint endPoint flagBits yValue contour |
	startPoint := 1.
	1 to: nContours do: [ :i | 
		contour := glyph contours at: i.
		"Get the end point"
		endPoint := (endPts at: i) + 1.
		"Store number of points"
		startPoint to: endPoint do: [ :j | 
			flagBits := flags at: j.
			"Check if this value one or two byte encoded"
			yValue := (flagBits allMask: 4)
				          ifTrue: [ "one byte"
					          (flagBits allMask: 32)
						          ifTrue: [ entry nextByte ]
						          ifFalse: [ entry nextByte negated ] ]
				          ifFalse: [ "two byte"
					          (flagBits allMask: 32)
						          ifTrue: [ 0 ]
						          ifFalse: [ entry nextShort ] ].
			contour points at: j - startPoint + 1 putY: yValue ].
		startPoint := endPoint + 1 ]
]

{ #category : 'public' }
TTFontReader >> readTTFFrom: aByteArray [

	"Read the raw font byte data"

	fontDescription := TTFontDescription new.
	self readFrom: aByteArray fromOffset: 0.
	^ fontDescription
]
