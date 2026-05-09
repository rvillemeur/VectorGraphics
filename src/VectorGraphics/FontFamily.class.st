"
Registry and abstract base for a typeface (also called a font family).

FontFamily maintains a class-side dictionary of all loaded families (AvailableFamilies),
keyed by family name. It also tracks the system-wide default family name and default point
size. Subclass TrueTypeFontFamily extends this with TrueType-specific loading and emphasis
(bold/italic) handling.

## Relationships
- Subclassed by TrueTypeFontFamily.
- Each family holds TrueTypeFont instances (via `baseFontBySizes`) at different point sizes.
- TrueTypeFont instances are retrieved via `familyName:pointSize:` or `defaultFamilyAndPointSize`.

## Key class-side methods
- `familyName: aString pointSize: aNumber` — returns (or creates) the font at a given size
- `familyNamed: aString` — looks up an already-registered family
- `defaultFamilyAndPointSize` — returns the default family at the default size
- `addFamily: aFontFamily` — registers a new family in AvailableFamilies
- `readIfNeeded: dir` — loads TrueType fonts from a directory if not yet loaded

## Key instance methods
- `atPointSize: aNumber` — returns a TrueTypeFont at the requested size (creating it if needed)
- `familyName` — the human-readable family name (e.g. 'Source Sans Pro')
"
Class {
	#name : 'FontFamily',
	#superclass : 'Object',
	#instVars : [
		'familyName',
		'baseFontBySizes'
	],
	#classVars : [
		'AvailableFamilies',
		'DefaultFamilyName',
		'DefaultPointSize'
	],
	#category : 'VectorGraphics-TrueType',
	#package : 'VectorGraphics',
	#tag : 'TrueType'
}

{ #category : 'initialization' }
FontFamily class >> addFamily: aFontFamily [

	self availableFamilies at: aFontFamily familyName put: aFontFamily
]

{ #category : 'accessing' }
FontFamily class >> availableFamilies [

	AvailableFamilies ifNil: [ AvailableFamilies := Dictionary new ].
	^ AvailableFamilies
]

{ #category : 'accessing fonts' }
FontFamily class >> defaultFamilyAndPointSize [
	"	FontFamily defaultFamilyAndPointSize	"

	| family |
	family := AvailableFamilies at: DefaultFamilyName.
	^ family atPointSize: DefaultPointSize
]

{ #category : 'accessing' }
FontFamily class >> defaultFamilyName [

	^ DefaultFamilyName
]

{ #category : 'initialization' }
FontFamily class >> defaultFamilyName: aString [

	self defaultFamilyName: aString defaultPointSize: nil
]

{ #category : 'initialization' }
FontFamily class >> defaultFamilyName: aStringOrNil defaultPointSize: aNumberOrNil [
	"Nil just means leave it as it is now."

	aStringOrNil ifNotNil: [ DefaultFamilyName := aStringOrNil ].
	aNumberOrNil ifNotNil: [ DefaultPointSize := aNumberOrNil ]
]

{ #category : 'accessing fonts' }
FontFamily class >> defaultFamilyPointSize: aNumber [
	"FontFamily defaultFamilyPointSize: 12"

	| family |
	family := AvailableFamilies at: DefaultFamilyName.
	^ family atPointSize: aNumber
]

{ #category : 'defaults' }
FontFamily class >> defaultLineSpacing [

	^ FontFamily defaultFamilyAndPointSize lineSpacing
]

{ #category : 'accessing' }
FontFamily class >> defaultPointSize [
	"	FontFamily defaultPointSize	"

	^ DefaultPointSize
]

{ #category : 'initialization' }
FontFamily class >> defaultPointSize: aNumber [

	self defaultFamilyName: nil defaultPointSize: aNumber
]

{ #category : 'accessing fonts' }
FontFamily class >> familyName: aString pointSize: aNumber [
	"	FontFamily familyName: FontFamily defaultFamilyName pointSize: 12
			FontFamily defaultFamilyPointSize: 12	"

	| family |
	family := AvailableFamilies at: aString ifAbsent: [ ^ nil ].
	^ family atPointSize: aNumber
]

{ #category : 'accessing fonts' }
FontFamily class >> familyNamed: aString [
	"	FontFamily familyNamed: FontFamily defaultFamilyName	"

	^ AvailableFamilies at: aString ifAbsent: [  ]
]

{ #category : 'accessing' }
FontFamily class >> familyNames [
	"	FontFamily familyNames	"

	^ AvailableFamilies keys sort
]

{ #category : 'accessing fonts' }
FontFamily class >> pointSizesFor: aString [
	"	FontFamily pointSizesFor: FontFamily defaultFamilyName	"

	| family |
	family := AvailableFamilies at: aString ifAbsent: [ ^ nil ].
	^ family pointSizes
]

{ #category : 'ui' }
FontFamily class >> readIfNeeded: dir [
	"Read from disk if not in memory"

	| fontNameFile fontName |
	fontNameFile := dir // 'fontName.txt'.
	fontName := fontNameFile exists
		            ifTrue: [ fontNameFile textContents ]
		            ifFalse: [ dir name ].
	(FontFamily familyNamed: fontName) ifNotNil: [ :it | ^ it ].
	TrueTypeFontFamily readAllTrueTypeFontsIn: dir.
	^ FontFamily familyNamed: fontName
]

{ #category : 'cached state access' }
FontFamily class >> releaseClassCachedState [

	AvailableFamilies keysAndValuesDo: [ :familyName :fontFamily |
		fontFamily releaseCachedState ]
]

{ #category : 'accessing' }
FontFamily >> atPointSize: aNumber [
	"	^baseFontBySizes at: aNumber ifAbsent: nil"

	^ baseFontBySizes at: aNumber ifAbsent: [
		  | found |
		  found := nil.
		  baseFontBySizes do: [ :font |
			  (found isNil or: [
				   (found pointSize - aNumber) abs
				   > (font pointSize - aNumber) abs ]) ifTrue: [ found := font ] ].
		  found ]
]

{ #category : 'accessing' }
FontFamily >> familyName [

	^ familyName
]

{ #category : 'initialization' }
FontFamily >> familyName: aString [

	familyName := aString.
	baseFontBySizes := Dictionary new
]

{ #category : 'accessing' }
FontFamily >> folderName [

	^ nil
]

{ #category : 'testing' }
FontFamily >> isTrueTypeFontFamily [

	^ false
]

{ #category : 'accessing' }
FontFamily >> pointSizes [

	^ baseFontBySizes keys sort
]

{ #category : 'caching' }
FontFamily >> releaseCachedState [

	baseFontBySizes keysAndValuesDo: [ :size :font |
		font releaseCachedState ]
]
