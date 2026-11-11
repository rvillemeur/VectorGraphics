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
		'weightClass',
		'widthClass',
		'slant',
		'rejectionReason',
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

{ #category : 'initialization' }
TTFontMetadata >> initialize [
	"A face states no table until the reader walks the directory. An empty census, never nil, so
	 no reader of mine has to guard against one."

	super initialize.
	tableLengthsByTag := Dictionary new
]

{ #category : 'inspector' }
TTFontMetadata >> inspectorIdentity: aBuilder [
	"What a font manager keys a face by: the family it belongs to, its style within that family,
	 the three facts it is matched on, and the reason not to draw it when there is one. The names
	 come from the font's own name table and the three facts from its OS/2 and head tables, so
	 what shows here is what the font says about itself, not what its file is called nor what the
	 words of its style name suggest. The last row is empty for a face this project can draw."

	<inspectorPresentationOrder: 10 title: 'Identity'>
	^ aBuilder newTable
		  addColumn:
			  ((SpStringTableColumn title: 'Name' evaluated: [ :each | each key ])
				   width: 120);
		  addColumn:
			  (SpStringTableColumn title: 'Value' evaluated: [ :each | each value ]);
		  items: {
				  ('family' -> (familyName ifNil: [ '' ])).
				  ('style' -> (styleName ifNil: [ '' ])).
				  ('weight class' -> (weightClass ifNil: [ '' ] ifNotNil: [ :each |
						    each printString ])).
				  ('width class' -> (widthClass ifNil: [ '' ] ifNotNil: [ :each |
						    each printString ])).
				  ('slant' -> (slant ifNil: [ '' ] ifNotNil: [ :each |
						    each asString ])).
				  ('rejection' -> (rejectionReason ifNil: [ '' ] ifNotNil: [ :each |
						    each asString ])) };
		  yourself
]

{ #category : 'inspecting' }
TTFontMetadata >> inspectorTables: aBuilder [
	"Every table the font carries, and which of them was read to name it. The Read column asks
	 TTFontMetadataReader nameTableTag, the same constant both doors of the reader ask, so it
	 cannot claim a table nothing touched. This is where the cost shows: a font holds fifteen
	 or twenty tables, glyf and loca are the large ones, and neither is read."

	<inspectorPresentationOrder: 20 title: 'Tables'>
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
		  items: (tableLengthsByTag associations asSortedCollection: [ :a :b |
					   a key <= b key ]) asArray;
		  yourself
]

{ #category : 'accessing' }
TTFontMetadata >> isRejected [
	"Whether this face carries a reason not to draw it."

	^ rejectionReason isNotNil
]

{ #category : 'printing' }
TTFontMetadata >> printOn: aStream [
	"Family then style, which is how a font manager keys a face and how a reader names one, then
	 the reason not to draw the face when there is one. A font directory holds more files that
	 are not drawable fonts than files that are, and an example prints them all in one list."

	super printOn: aStream.
	aStream
		nextPutAll: ' ';
		print: familyName;
		nextPutAll: ' ';
		print: styleName.
	rejectionReason ifNotNil: [ :each |
		aStream
			nextPutAll: ' ';
			print: each ]
]

{ #category : 'accessing' }
TTFontMetadata >> rejectionReason [
	"Why this face cannot be drawn by this project, as a symbol, or nil when it can.
	 #notAnSfntFont, #fontCollection, #noNameTable, #noGlyfTable or #colourFont: the first cause
	 the reader met, in that order. A rejected face still carries every name and class the file
	 did state, so a catalogue can say which font it passed over."

	^ rejectionReason
]

{ #category : 'accessing' }
TTFontMetadata >> rejectionReason: aSymbolOrNil [

	rejectionReason := aSymbolOrNil
]

{ #category : 'accessing' }
TTFontMetadata >> slant [
	"#normal, #italic or #oblique: a true italic and a sheared roman are drawn differently and
	 AeFontSlant keeps them apart."

	^ slant
]

{ #category : 'accessing' }
TTFontMetadata >> slant: aSymbol [
	slant := aSymbol
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

{ #category : 'accessing' }
TTFontMetadata >> tableTags [
	"The four-character tags of every table the font's directory records, read or not. The
	 question asked of me twice: by the reader, to find the first reason not to draw the face,
	 and by a view, to say what was passed over."

	^ tableLengthsByTag keys
]

{ #category : 'accessing' }
TTFontMetadata >> weightClass [
	"The weight on the OS/2 scale, 100 thin to 1000 extra-black, 400 normal and 700 bold. It is
	 the scale AeFontWeight already answers from value, so the Bloc layer maps it with no
	 arithmetic."

	^ weightClass
]

{ #category : 'accessing' }
TTFontMetadata >> weightClass: anInteger [
	weightClass := anInteger
]

{ #category : 'accessing' }
TTFontMetadata >> widthClass [
	"The width on the OS/2 scale, 1 ultra-condensed to 9 ultra-expanded, 5 normal. AeFontStretch
	 numbers the same nine steps from zero, so the Bloc layer maps it by subtracting one; this is
	 the font format's own number and not Alexandrie's, which is why it is named for the field."

	^ widthClass
]

{ #category : 'accessing' }
TTFontMetadata >> widthClass: anInteger [
	widthClass := anInteger
]
