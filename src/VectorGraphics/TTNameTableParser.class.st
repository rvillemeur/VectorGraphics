"
Parser for the TrueType 'name' (Naming) table.

Returns an Array of 8 strings indexed by name ID (0–7). Strings not present in the table
are empty strings. Prefers Windows platform (pID=3, English US) over Macintosh (pID=1).

TTFontReader passes the result to TTFontDescription >> setStrings:.
"
Class {
	#name : 'TTNameTableParser',
	#superclass : 'TTFontParser',
	#category : 'VectorGraphics-TrueType',
	#package : 'VectorGraphics',
	#tag : 'TrueType'
}

{ #category : 'parsing' }
TTNameTableParser >> process [

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
