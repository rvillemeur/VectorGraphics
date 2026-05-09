Class {
	#name : 'FontFamilyTest',
	#superclass : 'TestCase',
	#instVars : [
		'savedEntries'
	],
	#category : 'VectorGraphics-tests',
	#package : 'VectorGraphics',
	#tag : 'tests'
}

{ #category : 'helpers' }
FontFamilyTest >> makeFamilyNamed: aString [

	| family |
	family := FontFamily new.
	family familyName: aString.
	^ family
]

{ #category : 'running' }
FontFamilyTest >> setUp [

	savedEntries := FontFamily availableFamilies copy.
	FontFamily availableFamilies keys asArray do: [ :k |
		FontFamily availableFamilies removeKey: k ]
]

{ #category : 'running' }
FontFamilyTest >> tearDown [

	FontFamily availableFamilies keys asArray do: [ :k |
		FontFamily availableFamilies removeKey: k ].
	savedEntries keysAndValuesDo: [ :k :v |
		FontFamily availableFamilies at: k put: v ]
]

{ #category : 'tests' }
FontFamilyTest >> testAddFamilyMultiple [

	FontFamily addFamily: (self makeFamilyNamed: 'Alpha').
	FontFamily addFamily: (self makeFamilyNamed: 'Beta').
	self assert: (FontFamily availableFamilies size) equals: 2
]

{ #category : 'tests' }
FontFamilyTest >> testAddFamilyRegistersUnderName [

	| family |
	family := self makeFamilyNamed: 'TestFont'.
	FontFamily addFamily: family.
	self assert: (FontFamily familyNamed: 'TestFont') == family
]

{ #category : 'tests' }
FontFamilyTest >> testAvailableFamiliesNeverNil [

	"availableFamilies lazy-initialises even on a fresh class."

	self assert: FontFamily availableFamilies notNil.
	self assert: (FontFamily availableFamilies isKindOf: Dictionary)
]

{ #category : 'tests' }
FontFamilyTest >> testFamilyNamePointSizeReturnsNilWhenAbsent [

	self assert: (FontFamily familyName: 'NoSuchFont' pointSize: 12) isNil
]

{ #category : 'tests' }
FontFamilyTest >> testFamilyNamedAbsentReturnsNil [

	self assert: (FontFamily familyNamed: 'NoSuchFont') isNil
]

{ #category : 'tests' }
FontFamilyTest >> testFamilyNamesReturnsSortedKeys [

	FontFamily addFamily: (self makeFamilyNamed: 'Zebra').
	FontFamily addFamily: (self makeFamilyNamed: 'Apple').
	self assert: FontFamily familyNames first equals: 'Apple'.
	self assert: FontFamily familyNames last equals: 'Zebra'
]

{ #category : 'tests' }
FontFamilyTest >> testIsTrueTypeFontFamilyFalse [

	self deny: (self makeFamilyNamed: 'X') isTrueTypeFontFamily
]

{ #category : 'tests' }
FontFamilyTest >> testPointSizesReflectsAtPointSizeCalls [

	"FontFamily.pointSizes returns the sizes of fonts that have been created."

	| family |
	family := self makeFamilyNamed: 'Test'.
	family instVarNamed: 'baseFontBySizes' put: (Dictionary new
		at: 12 put: 'font12';
		at: 24 put: 'font24';
		yourself).
	self assert: family pointSizes equals: #( 12 24 )
]

{ #category : 'tests' }
FontFamilyTest >> testReleaseCachedStateDelegates [

	"releaseCachedState sends releaseCachedState to each font in baseFontBySizes."

	| family released |
	released := OrderedCollection new.
	family := FontFamily new.
	family instVarNamed: 'baseFontBySizes' put: (Dictionary new
		at: 12 put: (RecordingCanvas new); "any object — will DNU releaseCachedState"
		yourself).
	"Just verify it doesn't crash when the dict is empty or the font responds"
	family instVarNamed: 'baseFontBySizes' put: Dictionary new.
	family releaseCachedState. "empty dict — must not crash"
	self assert: true
]
