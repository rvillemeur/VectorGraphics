Class {
	#name : 'TrueTypeFontFamily',
	#superclass : 'Object',
	#instVars : [
		'baseTTFontDescription',
		'ttFontDescriptionsByEmphasis',
		'baseFontBySizes',
		'familyName'
	],
	#category : 'VectorGraphics-TrueType',
	#package : 'VectorGraphics',
	#tag : 'TrueType'
}

{ #category : 'instance creation' }
TrueTypeFontFamily class >> baseTTFontDescription: aTTFontDescription [

	^ self new baseTTFontDescription: aTTFontDescription
]

{ #category : 'instance creation' }
TrueTypeFontFamily class >> fileReaderServicesForFileEntry: filename suffix: suffix [

	"FileList buttons that read a TrueType font on contents."

	(#( 'ttf' ) includes: suffix) ifTrue: [ ^ { self serviceReadTTFont } ].

	^ #(  )
]

{ #category : 'instance creation' }
TrueTypeFontFamily class >> read: aDirectoryEntry [

	"	TrueTypeFontFamily read: '/home/juan/Downloads/DejaVu2.37/dejavu-fonts-ttf-2.37/ttf/' asDirectoryEntry
"

	| readFamilyNames |
	readFamilyNames := TTFontDescription read: aDirectoryEntry.
	readFamilyNames do: [ :familyName | 
		| ttDescriptions baseTTDescription family |
		ttDescriptions := TTFontDescription withFamilyName: familyName.
		baseTTDescription := ttDescriptions at: 0.
		family := TrueTypeFontFamily baseTTFontDescription:
			          baseTTDescription.
		ttDescriptions do: [ :ttfDesc | 
			ttfDesc emphasis = 0 ifFalse: [ 
				family addTTFontDescription: ttfDesc ] ].
		FontFamily addFamily: family ].
	^ readFamilyNames
]

{ #category : 'instance creation' }
TrueTypeFontFamily class >> readAdditionalFonts [

	^ TrueTypeFontFamily read:
		  DirectoryEntry smalltalkImageDirectory / 'TrueTypeFonts'
]

{ #category : 'instance creation' }
TrueTypeFontFamily class >> readTrueTypeFontEntry: ttFontFileEntry [

	| ttFontDescription familyName ttFontFamily |
	ttFontDescription := TTFontReader readTTFFrom:
		                     ttFontFileEntry binaryContents.
	familyName := ttFontDescription familyName.
	ttFontFamily := FontFamily familyNamed: familyName.
	ttFontFamily
		ifNil: [ 
			FontFamily addFamily:
				(self new baseTTFontDescription: ttFontDescription) ]
		ifNotNil: [ :fam | 
			ttFontDescription emphasis = 0
				ifTrue: [ fam baseTTFontDescription: ttFontDescription ]
				ifFalse: [ fam addTTFontDescription: ttFontDescription ].
			fam clearCache ].
	familyName = FontFamily defaultFamilyName ifTrue: [ 
		Preferences setDefaultFont: familyName ].
	PopUpMenu inform: 'loaded font ' , familyName
]

{ #category : 'instance creation' }
TrueTypeFontFamily class >> serviceReadTTFont [

	"Answer the service of reading a TrueType font"

	^ (SimpleServiceEntry
		   provider: self
		   label: 'load font'
		   selector: #readTrueTypeFontEntry:
		   description: 'load TrueType font'
		   buttonLabel: 'read font'
		   icon:
			   ((Theme content from: 'Theme' get: { '16x16'. 'mimetypes' }) 
				    at: 'font-x-generic.png')) argumentGetter: [ :fileList | 
		  fileList selectedFileEntry ]
]

{ #category : 'initialization' }
TrueTypeFontFamily >> addTTFontDescription: aTTFontDescription [

	ttFontDescriptionsByEmphasis
		at: aTTFontDescription emphasis
		put: aTTFontDescription
]

{ #category : 'accessing' }
TrueTypeFontFamily >> atPointSize: aNumber [

	| baseFont |
	baseFontBySizes
		at: aNumber
		ifPresent: [ :existingBaseFont | ^ existingBaseFont ].
	baseFont := TrueTypeFont
		            family: self
		            ttFontDescription: baseTTFontDescription
		            pointSize: aNumber.
	baseFontBySizes at: aNumber put: baseFont.
	ttFontDescriptionsByEmphasis do: [ :emphasizedTTFontDescription | 
		| emphasizedFont |
		emphasizedFont := TrueTypeFont
			                  family: self
			                  ttFontDescription: emphasizedTTFontDescription
			                  pointSize: aNumber.
		emphasizedFont baseFont: baseFont.
		baseFont addDerivativeFont: emphasizedFont ].
	^ baseFont
]

{ #category : 'initialization' }
TrueTypeFontFamily >> baseTTFontDescription: aTTFontDescription [

	self assert: aTTFontDescription emphasis = 0.
	familyName := aTTFontDescription familyName.
	baseFontBySizes := Dictionary new.
	baseTTFontDescription := aTTFontDescription.
	ttFontDescriptionsByEmphasis isNil ifTrue: [ 
		ttFontDescriptionsByEmphasis := Dictionary new ]
]

{ #category : 'initialization' }
TrueTypeFontFamily >> clearCache [

	"
	TrueTypeFontFamily  allInstancesDo: [ :each | each clearCache ].
	"

	| emphasized |
	emphasized := ttFontDescriptionsByEmphasis values.
	self baseTTFontDescription: baseTTFontDescription.
	emphasized do: [ :each | self addTTFontDescription: each ]
]

{ #category : 'accessing' }
TrueTypeFontFamily >> folderName [

	^ baseTTFontDescription folderName
]

{ #category : 'testing' }
TrueTypeFontFamily >> isTrueTypeFontFamily [

	^ true
]

{ #category : 'accessing' }
TrueTypeFontFamily >> pointSizes [

	^ #( 6 7 8 9 10 11 12 13 14 15 18 22 26 36 48 72 )
]
