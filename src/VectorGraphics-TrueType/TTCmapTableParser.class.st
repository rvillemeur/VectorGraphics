"
Parser for the TrueType `cmap` (Character Map) table. It scans the subtable directory for every Unicode character map the font carries, then reads them in the order of preference of `TTCmapTableParser class >> subtablePreferences` — Windows over every plane, then the Unicode platform, then Windows over the Basic Multilingual Plane — and answers the first one it can parse as an Array mapping code point indices to glyph indices.

Only formats 0, 4 and 6 are parsed, so a subtable in another format answers nothing and the next one in the order is tried. Nil means the font carries no Unicode subtable this parser can read: `VGFontFace >> readBytes:` and `TTFontReader` check for nil and reject the font on that, since a face that cannot turn a code point into a glyph is of no use to a drawing. A font of the Droid or Open Sans families carries a Windows subtable and no subtable of platform 0 at all, which is why the Windows platform is read here and not only the Unicode one.
"
Class {
	#name : 'TTCmapTableParser',
	#superclass : 'TTFontParser',
	#category : 'VectorGraphics-TrueType-Reading',
	#package : 'VectorGraphics-TrueType',
	#tag : 'Reading'
}

{ #category : 'constants' }
TTCmapTableParser class >> bmpEncodingId [
	"The Windows encoding of Unicode over the Basic Multilingual Plane alone. The most common
	 character map a font on a desktop carries."

	^ 1
]

{ #category : 'constants' }
TTCmapTableParser class >> everyPlaneEncodingId [
	"The Windows encoding of Unicode over every plane. It reaches the code points above the
	 Basic Multilingual Plane, which is why it is preferred over #bmpEncodingId."

	^ 10
]

{ #category : 'constants' }
TTCmapTableParser class >> prcEncodingId [
	"The Windows encoding of a Chinese code page. It is not Unicode, so #subtablePreferences
	 leaves it out: a font whose only Windows subtable carries this encoding maps no code
	 point this reader can follow."

	^ 3
]

{ #category : 'constants' }
TTCmapTableParser class >> subtablePreferences [
	"The platform and encoding pairs that name a Unicode character map, best first.
	 Platform 0 is Unicode itself, whatever its encoding; of the Windows platform only
	 encoding 10, every plane, and encoding 1, the Basic Multilingual Plane, are Unicode.
	 Encoding 10 comes first because it maps the code points that encoding 1 cannot reach,
	 and the Windows platform comes last of the Unicode maps because a font that carries
	 both platforms means the same thing by them."

	^ {
		  { self windowsPlatformId. self everyPlaneEncodingId }.
		  { self unicodePlatformId. nil }.
		  { self windowsPlatformId. self bmpEncodingId } }
]

{ #category : 'constants' }
TTCmapTableParser class >> unicodePlatformId [
	"The platform of a character map that is Unicode by itself, whatever encoding it names."

	^ 0
]

{ #category : 'constants' }
TTCmapTableParser class >> windowsPlatformId [
	"The platform of the Microsoft character maps. Its encoding says whether the map is
	 Unicode: encoding 1 and encoding 10 are, encoding 0 is a symbol font's private area and
	 encoding 3 is a Chinese code page."

	^ 3
]

{ #category : 'inspector' }
TTCmapTableParser >> inspectorSubtables: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Subtables'>
	"The subtable directory of the table this parser reads, as the parser itself sees it: the
	 platform and encoding of each subtable, where that pair stands in the order of preference,
	 and the format of the subtable. The row the parser would read is the one of best
	 preference whose format is 0, 4 or 6, so this view shows why a font is read or refused."

	^ aBuilder newTable
		  addColumn: ((SpStringTableColumn
				    title: 'Platform'
				    evaluated: [ :each | (each at: 1) printString ]) width: 80);
		  addColumn: ((SpStringTableColumn
				    title: 'Encoding'
				    evaluated: [ :each | (each at: 2) printString ]) width: 80);
		  addColumn: ((SpStringTableColumn
				    title: 'Preference'
				    evaluated: [ :each |
					    (each at: 3)
						    ifNil: [ 'not Unicode' ]
						    ifNotNil: [ :rank | rank printString ] ]) width: 110);
		  addColumn: (SpStringTableColumn
				   title: 'Format'
				   evaluated: [ :each | (each at: 4) printString ]);
		  items: self subtableDescriptions;
		  yourself
]

{ #category : 'parsing' }
TTCmapTableParser >> parseFormat [

	"Parse a cmap subtable starting at the current entry position.
	Dispatches to format 0, 4, or 6. Returns an Array or nil."

	| cmapFmt length entryCount segCount segments offset cmap firstCode |
	cmapFmt := entry nextUShort.
	cmapFmt = 12 ifTrue: [ ^ self parseFormatTwelve ]. "its header is not the one below"
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
TTCmapTableParser >> parseFormatTwelve [
	"The subtable of format 12, segmented coverage, read from just past its format word: a
	 count of groups, then one group of three long words per run of code points — the first
	 code point of the run, the last, and the glyph of the first, the glyphs of a run following
	 one another. It is the only format of this reader whose code points may lie above the
	 Basic Multilingual Plane, so the map it builds is as long as its highest code point.
	 A subtable of no group answers nothing rather than a map of nothing, so that
	 #process goes on to the next subtable the font carries."

	| groupCount groups highestCodePoint characterMap |
	entry skip: 10. "reserved, length and language"
	groupCount := entry nextULong.
	groupCount = 0 ifTrue: [ ^ nil ].
	groups := OrderedCollection new.
	groupCount timesRepeat: [
		groups add: {
				entry nextULong.
				entry nextULong.
				entry nextULong } ].
	highestCodePoint := groups inject: 0 into: [ :highest :group |
		                   highest max: group second ].
	characterMap := Array new: highestCodePoint + 1 withAll: 0.
	groups do: [ :group |
		group first to: group second do: [ :codePoint |
			characterMap
				at: codePoint + 1
				put: group third + codePoint - group first ] ].
	^ characterMap
]

{ #category : 'parsing' }
TTCmapTableParser >> preferenceOfPlatform: platformId encoding: encodingId [
	"Where a subtable of this platform and encoding stands in the order of preference, or
	 nil when the pair names no Unicode map at all. A nil encoding in the order matches
	 whatever encoding a subtable of that platform carries."

	^ self class subtablePreferences
		  detectIndex: [ :each |
			  each first = platformId and: [ each second isNil or: [ each second = encodingId ] ] ]
		  ifNone: [ nil ]
]

{ #category : 'parsing' }
TTCmapTableParser >> process [
	"Scan the subtable directory for every Unicode character map the font carries, then
	 parse them in the order of preference of #subtablePreferences and answer the first
	 one that reads. A subtable of a format this parser does not know answers nothing, so
	 the next one is tried: a font whose preferred map is in format 12 and whose second
	 map is in format 4 is read by the second. Nil means the font maps no Unicode code
	 point we can read, and the caller rejects the font on that."

	| initialOffset subtableCount offsetsByPreference |
	initialOffset := entry offset.
	entry skip: 2. "skip table version"
	subtableCount := entry nextUShort.
	offsetsByPreference := Dictionary new.
	subtableCount timesRepeat: [ | platformId encodingId offset preference |
		platformId := entry nextUShort.
		encodingId := entry nextUShort.
		offset := entry nextULong.
		preference := self preferenceOfPlatform: platformId encoding: encodingId.
		preference ifNotNil: [ offsetsByPreference at: preference ifAbsentPut: [ offset ] ] ].
	offsetsByPreference keys asSortedCollection do: [ :each |
		entry offset: initialOffset + (offsetsByPreference at: each).
		self parseFormat ifNotNil: [ :characterMap | ^ characterMap ] ].
	^ nil
]

{ #category : 'parsing' }
TTCmapTableParser >> subtableDescriptions [
	"One Array per subtable of the table this parser reads: the platform, the encoding, the
	 rank of that pair in #subtablePreferences or nil when the pair is no Unicode map, and the
	 format word of the subtable itself. The ranks are asked of #preferenceOfPlatform:encoding:
	 rather than restated, so a reader of this list cannot be told an order the parser does not
	 follow. Every read goes through a copy of the directory entry, because reading moves the
	 entry''s position and this answers a question without changing anything."

	| directory initialOffset subtableCount descriptions |
	directory := entry copy.
	initialOffset := directory offset.
	directory skip: 2. "skip table version"
	subtableCount := directory nextUShort.
	descriptions := OrderedCollection new.
	subtableCount timesRepeat: [ | platformId encodingId subtable |
		platformId := directory nextUShort.
		encodingId := directory nextUShort.
		subtable := entry copy.
		subtable offset: initialOffset + directory nextULong.
		descriptions add: {
				platformId.
				encodingId.
				(self preferenceOfPlatform: platformId encoding: encodingId).
				subtable nextUShort } ].
	^ descriptions
]
