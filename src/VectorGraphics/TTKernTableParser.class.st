"
Parser for the TrueType 'kern' (Kerning) table.

Returns an Array of TTKernPair. Handles both the Windows kern table format (version +
nTables as UShort) and the OS X/AAT format (version + nTables as ULong). In both cases
only the first subtable of type 0 is used.

If the table format is unrecognised or coverage flags are wrong, returns an empty Array.
"
Class {
	#name : 'TTKernTableParser',
	#superclass : 'TTFontParser',
	#category : 'VectorGraphics-TrueType',
	#package : 'VectorGraphics',
	#tag : 'TrueType'
}

{ #category : 'parsing - private' }
TTKernTableParser >> parseOSXFormat [

	"OS X / AAT kern table: version and nTables are ULong."

	| length coverage |
	entry nextULong. "version (already consumed 4 bytes as 2×UShort above — re-read as 2 ULong)"
	entry nextULong. "nTables"
	length := entry nextULong.
	coverage := entry nextUShort.
	entry nextUShort. "tupleIndex"
	coverage = 0 ifFalse: [ ^ #() ].
	^ self parseSubTableType0
]

{ #category : 'parsing - private' }
TTKernTableParser >> parseSubTableType0 [

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
TTKernTableParser >> process [

	"Detect Windows vs OS X kern table format and dispatch accordingly."

	| version nTables covLow covHigh |
	version := entry nextUShort.
	nTables := entry nextUShort.
	nTables = 0 ifTrue: [
		"nTables = 0 as UShort means this is the OS X format where the field is ULong.
		Rewind and re-read as the OS X header."
		entry skip: -4.
		^ self parseOSXFormat ].
	entry skip: 2. "skip current subtable number"
	entry skip: 2. "skip subtable length"
	covHigh := entry nextByte.
	covLow := entry nextByte.
	"Require horizontal kerning (bit 1 clear) and format 0 (covHigh = 0)"
	((covLow allMask: 2) or: [ covHigh ~= 0 ]) ifTrue: [ ^ #() ].
	^ self parseSubTableType0
]
