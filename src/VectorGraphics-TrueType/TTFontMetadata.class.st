"
I am what a font scan needs to know about one face, and nothing more: the family it belongs to and the name of its style.

TTFontMetadataReader builds me from the name table of a font file. No glyph, no outline and no metric is read to build me, because a scan reads every font file on the machine and a full parse of one 2.2 MB face costs 200 ms.
"
Class {
	#name : 'TTFontMetadata',
	#superclass : 'Object',
	#instVars : [
		'familyName',
		'styleName',
		'tableLengthsByTag'
	],
	#category : 'VectorGraphics-TrueType-Reading',
	#package : 'VectorGraphics-TrueType',
	#tag : 'Reading'
}

{ #category : 'accessing' }
TTFontMetadata >> familyName [
	"The name of the family this face belongs to, as the font's own name table spells it."

	^ familyName
]

{ #category : 'accessing' }
TTFontMetadata >> familyName: aString [
	familyName := aString
]

{ #category : 'inspector' }
TTFontMetadata >> inspectorIdentity: aBuilder [
	"What a font manager keys a face by: the family it belongs to and its style within that
	 family. Both are read from the font's own name table, so what shows here is what the font
	 calls itself, not what its file is called."

	<inspectorPresentationOrder: 10 title: 'Identity'>
	^ aBuilder newTable
		  addColumn:
			  ((SpStringTableColumn title: 'Name' evaluated: [ :each | each key ])
				   width: 120);
		  addColumn:
			  (SpStringTableColumn title: 'Value' evaluated: [ :each | each value ]);
		  items: {
				  ('family' -> (familyName ifNil: [ '' ])).
				  ('style' -> (styleName ifNil: [ '' ])) };
		  yourself
]

{ #category : 'inspector' }
TTFontMetadata >> inspectorTables: aBuilder [
	"Every table the font carries, and which of them was read to name it. The Read column asks
	 TTFontMetadataReader nameTableTag, the same constant both doors of the reader ask, so it
	 cannot claim a table nothing touched. This is where the cost shows: a font holds fifteen
	 or twenty tables, glyf and loca are the large ones, and neither is read."

	<inspectorPresentationOrder: 20 title: 'Tables'>
	| lengths |
	lengths := tableLengthsByTag ifNil: [ Dictionary new ].
	^ aBuilder newTable
		  addColumn:
			  ((SpStringTableColumn title: 'Tag' evaluated: [ :each | each key ])
				   width: 70);
		  addColumn: ((SpStringTableColumn
					    title: 'Length'
					    evaluated: [ :each | each value printString ]) width: 90);
		  addColumn: (SpStringTableColumn
				   title: 'Read'
				   evaluated: [ :each |
					   each key = TTFontMetadataReader nameTableTag
						   ifTrue: [ 'yes' ]
						   ifFalse: [ '' ] ]);
		  items: (lengths associations asSortedCollection: [ :a :b |
					   a key <= b key ]) asArray;
		  yourself
]

{ #category : 'printing' }
TTFontMetadata >> printOn: aStream [
	"Family then style, which is how a font manager keys a face and how a reader names one."

	super printOn: aStream.
	aStream
		nextPutAll: ' ';
		print: familyName;
		nextPutAll: ' ';
		print: styleName
]

{ #category : 'accessing' }
TTFontMetadata >> styleName [
	"The name of this face within its family — Regular, Bold Italic, Condensed Light — as the
	 font's own name table spells it, in the record TrueType calls the subfamily."

	^ styleName
]

{ #category : 'accessing' }
TTFontMetadata >> styleName: aString [
	styleName := aString
]

{ #category : 'accessing' }
TTFontMetadata >> tableLengthsByTag [
	"The length the font's own directory records for every table, by four-character tag. The
	 reader fills it from the directory it walks, so I can say what was skipped and not read."

	^ tableLengthsByTag
]

{ #category : 'accessing' }
TTFontMetadata >> tableLengthsByTag: aDictionary [
	tableLengthsByTag := aDictionary
]
