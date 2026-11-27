"
One face of a `TrueTypeFontFamily`: the catalogue entry a scan met, and the description a reader parses out of it when it first needs an outline. Both ends of a face live here, so a family keeps one dictionary of faces by emphasis rather than one dictionary of entries beside one of descriptions, and no caller has to ask which of the two a face is in.

A face built from a catalogue entry is unparsed, and `ttFontDescription` reads the bytes the first time it is asked — the 80 ms a font costs is paid by the first reader that needs an outline. A face built from a description is parsed from the start and has no entry behind it, which is how a font posed by hand, by a test or by an example, becomes a face of a family.

`isParsed` answers the question a reader of a lazy family has without reading anything, and `styleName` names the face from whichever end is there.
"
Class {
	#name : 'TTFamilyFace',
	#superclass : 'Object',
	#instVars : [
		'catalogueEntry',
		'ttFontDescription'
	],
	#category : 'VectorGraphics-TrueType-Fonts',
	#package : 'VectorGraphics-TrueType',
	#tag : 'Fonts'
}

{ #category : 'instance creation' }
TTFamilyFace class >> catalogueEntry: aCatalogueEntry [
	"A face a catalogue met, unparsed."

	^ self new setCatalogueEntry: aCatalogueEntry
]

{ #category : 'instance creation' }
TTFamilyFace class >> ttFontDescription: aTTFontDescription [
	"A face already parsed, with no catalogue entry behind it."

	^ self new setTTFontDescription: aTTFontDescription
]

{ #category : 'accessing' }
TTFamilyFace >> catalogueEntry [
	"The entry a scan made of me, or nil when I was posed as a parsed description.
	 Declared a cache rather than a holding, because a face holds this one or the description
	 below it and never needs both: the absence of either says nothing about the face."

	<archCache: #one to: #TTFontCatalogueEntry>
	^ catalogueEntry
]

{ #category : 'accessing' }
TTFamilyFace >> familyName [
	"The name of the family I belong to, as the font states it. Asking parses nothing."

	catalogueEntry ifNotNil: [ ^ catalogueEntry familyName ].
	^ ttFontDescription familyName
]

{ #category : 'inspecting' }
TTFamilyFace >> inspectorFace: aBuilder [
	"What I am and what has been read of me. The rows come from the entry a scan made of me,
	 never from my outlines, so opening this view on a pending face leaves it pending — the
	 point of a lazy face being that a reader can look at a family without paying for one
	 parse per face."

	<inspectorPresentationOrder: 10 title: 'Face'>
	^ aBuilder newTable
		  addColumn: ((SpStringTableColumn
				    title: 'Fact'
				    evaluated: [ :each | each key ])
				   width: 120);
		  addColumn: (SpStringTableColumn
				   title: 'Value'
				   evaluated: [ :each | each value ]);
		  items: {
				  ('Family' -> self familyName).
				  ('Style' -> self styleName).
				  ('Outlines' -> (self isParsed
					    ifTrue: [ 'parsed' ]
					    ifFalse: [ 'pending' ])).
				  ('Comes from' -> (catalogueEntry
					    ifNil: [ 'a description posed by hand' ]
					    ifNotNil: [ :entry | entry fontSourceName ])) };
		  yourself
]

{ #category : 'testing' }
TTFamilyFace >> isParsed [
	"Have my outlines been read? Asking never reads them."

	^ ttFontDescription notNil
]

{ #category : 'printing' }
TTFamilyFace >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPutAll: ' ';
		nextPutAll: self familyName;
		nextPutAll: ' ';
		nextPutAll: self styleName;
		nextPutAll: (self isParsed
				 ifTrue: [ ', parsed' ]
				 ifFalse: [ ', pending' ])
]

{ #category : 'initialization' }
TTFamilyFace >> setCatalogueEntry: aCatalogueEntry [
	catalogueEntry := aCatalogueEntry
]

{ #category : 'initialization' }
TTFamilyFace >> setTTFontDescription: aTTFontDescription [
	ttFontDescription := aTTFontDescription
]

{ #category : 'accessing' }
TTFamilyFace >> styleName [
	"What I call my style — 'Regular', 'Bold', 'Italic'. Read from the catalogue entry when
	 there is one, from the description otherwise. Asking parses nothing."

	catalogueEntry ifNotNil: [ ^ catalogueEntry metadata styleName ].
	^ ttFontDescription fullName
]

{ #category : 'accessing' }
TTFamilyFace >> ttFontDescription [
	"My outlines, parsed. A face that came from a catalogue entry reads the bytes here, at the
	 first ask, and keeps what it read."

	<archCache: #one to: #TTFontDescription>
	^ ttFontDescription ifNil: [
		  ttFontDescription := TTFontReader readTTFFrom: catalogueEntry bytes ]
]
