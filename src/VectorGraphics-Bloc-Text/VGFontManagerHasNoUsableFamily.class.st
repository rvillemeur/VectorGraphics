"
I am raised when a manager is asked for a default face and none of the families the caller named is installed on the machine.

I carry the family names that were looked for, in the order they were preferred, and how many families the manager held at the time: an empty manager and a manager full of other families are different mistakes, and the sentence a reader sees says which one it is.

VGFontManager class >> newWithDefaultFaces reaches me through defaultFaceOfFirstFamilyNamedIn: when neither preferredTextFamilyNames nor preferredCodeFamilyNames can be answered. Nobody catches me: a default face left nil comes back from BAFontConverter >> faceFor: and breaks in the drawing instead of here.
"
Class {
	#name : 'VGFontManagerHasNoUsableFamily',
	#superclass : 'Error',
	#instVars : [
		'familyNames',
		'familyCount'
	],
	#category : 'VectorGraphics-Bloc-Text-Fonts',
	#package : 'VectorGraphics-Bloc-Text',
	#tag : 'Fonts'
}

{ #category : 'signalling' }
VGFontManagerHasNoUsableFamily class >> signalForFamilyNames: aCollection outOf: anInteger [
	"Raise the refusal for that preference list, against a manager holding that many families.
	 The instance is built before it is signalled, because a cascade on `self new` would send
	 the signal to me and not to the refusal."
	| refusal |
	refusal := self new.
	refusal familyNames: aCollection.
	refusal familyCount: anInteger.
	^ refusal signal
]

{ #category : 'accessing' }
VGFontManagerHasNoUsableFamily >> familyCount [
	"How many families the manager held when it was asked. Zero says the manager scanned
	 nothing; a larger number says the machine has fonts but none that was asked for."
	^ familyCount
]

{ #category : 'accessing' }
VGFontManagerHasNoUsableFamily >> familyCount: anInteger [
	familyCount := anInteger
]

{ #category : 'accessing' }
VGFontManagerHasNoUsableFamily >> familyNames [
	"The families that were looked for, best first. Answered so a handler can say what the
	 machine would have to install rather than only that something is missing."
	^ familyNames
]

{ #category : 'accessing' }
VGFontManagerHasNoUsableFamily >> familyNames: aCollection [
	familyNames := aCollection
]

{ #category : 'inspector' }
VGFontManagerHasNoUsableFamily >> inspectorFamilies: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Families'>
	"What was looked for, in the order it was preferred, against what this machine answers now.
	 The last column is not read off me: a manager scans the machine's font directories when
	 this view is built and is asked for each family, so a reader sees whether the refusal
	 still holds or whether a font was installed since. The scan happens once, here, because a
	 column block runs per drawn row."
	| manager |
	manager := VGFontManager new scanDefaultDirectories; yourself.
	^ aBuilder newTable
		  items: (familyNames withIndexCollect: [ :each :index |
					   index -> each ]);
		  addColumn: ((SpStringTableColumn
				    title: 'Preference'
				    evaluated: [ :each | each key printString ]) width: 90);
		  addColumn:
			  (SpStringTableColumn title: 'Family' evaluated: [ :each | each value ]);
		  addColumn: (SpStringTableColumn
				   title: 'On this machine now'
				   evaluated: [ :each |
					   (manager includesFamilyName: each value)
						   ifTrue: [ 'installed' ]
						   ifFalse: [ 'absent' ] ]);
		  yourself
]

{ #category : 'inspector' }
VGFontManagerHasNoUsableFamily >> inspectorFamiliesContext: aContext [
	"Off for an instance that was built and never signalled: signalForFamilyNames:outOf: is
	 what fills the two slots, and a bare new has no list to show."
	aContext active: familyNames notNil
]

{ #category : 'accessing' }
VGFontManagerHasNoUsableFamily >> messageText [
	"The sentence a reader sees: what was looked for, in the order it was preferred, and how
	 many families there were to look through."
	^ messageText ifNil: [
		  messageText := String streamContents: [ :stream |
				          stream
					          nextPutAll: 'None of the families ';
					          nextPutAll: (', ' join: familyNames);
					          nextPutAll: ' is installed: the manager holds ';
					          print: familyCount;
					          nextPutAll: ' families.' ] ]
]
