"
I hold `TrueTypeFontFamily`, the family built from one parsed description that answers a `TrueTypeFont` at any point size.

The family takes its name and its ASCII coverage from the description it was built with, and answers `isTrueTypeFontFamily` where `FontFamily` does not — the one place in the font code where the kind is asked rather than the behaviour. Asking for a point size builds a `TrueTypeFont` and remembers it, so the same size asked twice answers the same object and the point sizes asked for are the sizes the family lists.

`folderName` is held here too, although nothing in the image sets it: it is what remains of loading a family from a directory, which was removed in the review of 2026-11. The fixture sets the instance variable directly for that reason.
"
Class {
	#name : 'TrueTypeFontFamilyTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-TrueType-Tests-Tests',
	#package : 'VectorGraphics-TrueType-Tests',
	#tag : 'Tests'
}

{ #category : 'helpers' }
TrueTypeFontFamilyTest >> makeFamily [

	^ TrueTypeFontFamily baseTTFontDescription: self makeFontDescription
]

{ #category : 'helpers' }
TrueTypeFontFamilyTest >> makeFontDescription [

	"Regular font: familyName = fullName → emphasis 0."

	| fd |
	fd := TTFontDescription new.
	fd setStrings: #( 'CR' 'TestFamily' 'Regular' 'Uniq' 'TestFamily' 'v1' 'TestFamily-Regular' 'TM' ).
	fd setAscent: 800 descent: -200 lineGap: 50.
	fd instVarNamed: 'folderName' put: 'TestFonts'.
	fd instVarNamed: 'letterMTopSideBearing' put: 800.
	fd instVarNamed: 'contourDataIndexesByUtf8' put: (IntegerArray new: 256).
	fd instVarNamed: 'contourDataForUtf8' put: (Float32Array new: 10).
	^ fd
]

{ #category : 'tests' }
TrueTypeFontFamilyTest >> testAtPointSizeCachesResult [

	| family |
	family := self makeFamily.
	self assert: (family atPointSize: 12) == (family atPointSize: 12)
]

{ #category : 'tests' }
TrueTypeFontFamilyTest >> testAtPointSizeCreatesTrueTypeFont [

	| family font |
	family := self makeFamily.
	font := family atPointSize: 12.
	self assert: font class equals: TrueTypeFont.
	self assert: font pointSize equals: 12
]

{ #category : 'tests' }
TrueTypeFontFamilyTest >> testFamilyName [

	self assert: self makeFamily familyName equals: 'TestFamily'
]

{ #category : 'tests' }
TrueTypeFontFamilyTest >> testFolderName [

	self assert: self makeFamily folderName equals: 'TestFonts'
]

{ #category : 'tests' }
TrueTypeFontFamilyTest >> testIncludesAscii [

	"Mock description has all indexes=0 → includesAscii is false."

	self deny: self makeFamily includesAscii
]

{ #category : 'tests' }
TrueTypeFontFamilyTest >> testIsTrueTypeFontFamily [

	self assert: self makeFamily isTrueTypeFontFamily
]

{ #category : 'tests' }
TrueTypeFontFamilyTest >> testPointSizes [

	| sizes |
	sizes := self makeFamily pointSizes.
	self assert: (sizes includes: 12).
	self assert: (sizes includes: 6).
	self assert: (sizes includes: 144).
	self assert: sizes size equals: 18
]
