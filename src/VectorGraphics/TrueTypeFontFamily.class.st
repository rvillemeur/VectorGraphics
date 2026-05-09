Class {
	#name : 'TrueTypeFontFamily',
	#superclass : 'FontFamily',
	#instVars : [
		'baseTTFontDescription',
		'ttFontDescriptionsByEmphasis'
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
TrueTypeFontFamily class >> readAllTrueTypeFontsIn: aDirectoryEntry [

	| readFamilyNames |
	readFamilyNames := TTFontDescription read: aDirectoryEntry.
	readFamilyNames do: [ :aFamilyName |
		| ttDescriptions baseTTDescription family |
		ttDescriptions := TTFontDescription withFamilyName: aFamilyName.
		baseTTDescription := ttDescriptions at: 0.
		family := TrueTypeFontFamily baseTTFontDescription: baseTTDescription.
		ttDescriptions do: [ :ttfDesc |
			ttfDesc emphasis = 0 ifFalse: [
				family addTTFontDescription: ttfDesc ] ].
		FontFamily addFamily: family ].
	^ readFamilyNames
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
	baseFontBySizes at: aNumber ifPresent: [ :existingBaseFont | ^ existingBaseFont ].
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
	TrueTypeFontFamily allInstancesDo: [ :each | each clearCache ].
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
TrueTypeFontFamily >> includesAscii [

	"Answer true if we include the basic ASCII characters.
	If not, we are not suitable for displaying Smalltalk code."

	^ baseTTFontDescription includesAscii
]

{ #category : 'testing' }
TrueTypeFontFamily >> isTrueTypeFontFamily [

	^ true
]

{ #category : 'accessing' }
TrueTypeFontFamily >> pointSizes [

	^ #( 6 7 8 9 10 11 12 13 14 15 18 22 26 36 48 72 96 144 )
]
