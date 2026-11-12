"
I am one font file a catalogue has met: where its bytes are, and what its own tables say about it.

My source is a FileReference or a ByteArray, and I ask it for `fontBytes` rather than asking what kind of thing it is. My metadata is a TTFontMetadata, read once at the moment I was made: the family, the style, the weight class, the width class, the slant, and the reason not to draw this face when there is one.

I hold no face of either kind. A full parse costs 200 ms against the 1 ms my metadata cost, so the consumer that needs outlines builds its own face from my bytes, when it needs them.

Unlike AeFileFaceEntry I carry no face index: a ttcf collection is refused before an entry is made for it, so the index of a face I can answer for is always zero.
"
Class {
	#name : 'TTFontCatalogueEntry',
	#superclass : 'Object',
	#instVars : [
		'source',
		'metadata'
	],
	#category : 'VectorGraphics-TrueType-Reading',
	#package : 'VectorGraphics-TrueType',
	#tag : 'Reading'
}

{ #category : 'accessing' }
TTFontCatalogueEntry >> bytes [
	"The whole font. Costly for a file on disk — 262 MB over the fonts of this machine — which
	 is why a scan never asks for this and a consumer asks only for the face it draws with."

	^ source fontBytes
]

{ #category : 'accessing' }
TTFontCatalogueEntry >> familyName [
	"The family my face states, as its own name table spells it. The catalogue keys me by this
	 name in lower case, and answers this one to a reader."

	^ metadata familyName
]

{ #category : 'inspecting' }
TTFontCatalogueEntry >> inspectorSource: aBuilder [
	"Where my bytes are, how many there are, and how few of them the scan read to know what
	 face I am. The read figure comes from the reader itself, over the table directory my
	 metadata kept, so it cannot drift from what the reader does."

	<inspectorPresentationOrder: 10 title: 'Source'>
	| read |
	read := TTFontMetadataReader bytesReadForTableLengths:
		        metadata tableLengthsByTag.
	^ aBuilder newTable
		  addColumn:
			  ((SpStringTableColumn title: 'Name' evaluated: [ :each | each key ])
				   width: 120);
		  addColumn:
			  (SpStringTableColumn title: 'Value' evaluated: [ :each | each value ]);
		  items: {
				  ('source' -> source fontSourceName).
				  ('bytes' -> source size printString).
				  ('read by the scan' -> read printString) };
		  yourself
]

{ #category : 'testing' }
TTFontCatalogueEntry >> isRejected [
	"Whether my face carries a reason not to draw it. Asked of me rather than of my metadata,
	 so a caller sorting entries does not have to know where the reason is kept."

	^ metadata isRejected
]

{ #category : 'accessing' }
TTFontCatalogueEntry >> metadata [
	"What my own tables say about me: a TTFontMetadata, read once when I was made."

	^ metadata
]

{ #category : 'accessing' }
TTFontCatalogueEntry >> metadata: aFontMetadata [
	"Set what my tables said. The catalogue reads it before it makes me, through whichever door
	 of the reader suits my source."

	metadata := aFontMetadata
]

{ #category : 'printing' }
TTFontCatalogueEntry >> printOn: aStream [
	"My metadata names the face, and my source names itself — a base name for a file, a byte
	 count for a font held in memory. A catalogue prints hundreds of me in one list."

	super printOn: aStream.
	aStream
		nextPutAll: ' ';
		print: metadata;
		nextPutAll: ' from ';
		nextPutAll: source fontSourceName
]

{ #category : 'accessing' }
TTFontCatalogueEntry >> source [
	"Where my bytes are: a FileReference, or the bytes themselves."

	^ source
]

{ #category : 'accessing' }
TTFontCatalogueEntry >> source: anObject [
	"Set where my bytes are. Anything that answers fontBytes will do."

	source := anObject
]

{ #category : 'accessing' }
TTFontCatalogueEntry >> styleKey [
	"What tells me apart from the other faces of my family: the slant, the weight class and the
	 width class, which is the triple a font manager matches a text style against."

	^ {
		  metadata slant.
		  metadata weightClass.
		  metadata widthClass }
]

{ #category : 'accessing' }
TTFontCatalogueEntry >> styleName [
	"The style my face states, as its own name table spells it — 'Regular', 'Bold Italic'. The
	 pair with familyName: what a reader of a catalogue sorts and groups by."

	^ metadata styleName
]
