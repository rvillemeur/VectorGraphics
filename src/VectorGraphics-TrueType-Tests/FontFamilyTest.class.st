"
I hold `FontFamily` to the registry it keeps on its class side and to the degenerate answers a reader is entitled to.

The registry maps a family name to a family, so the tests state that `addFamily:` registers under the family's own name, that a second family joins rather than replaces, that the name list comes back sorted, and that `availableFamilies` is a collection even when nothing has been registered. Asking for an absent family, or for an absent family at a point size, answers `nil` rather than raising — the font code is expected to fall back, not to fail.

Point sizes are remembered as they are asked for, and `releaseCachedState` is passed down to the families, which must work when nothing has been cached yet.

The registry is global, so `setUp` saves it and `tearDown` puts it back: a test that leaves a family behind would change what every later test and every font-reading example sees.
"
Class {
	#name : 'FontFamilyTest',
	#superclass : 'TestCase',
	#instVars : [
		'savedEntries'
	],
	#category : 'VectorGraphics-TrueType-Tests-Tests',
	#package : 'VectorGraphics-TrueType-Tests',
	#tag : 'Tests'
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
	"releaseCachedState sends releaseCachedState to every font in baseFontBySizes."

	| family font |
	font := RecordingFont new.
	family := FontFamily new.
	family
		instVarNamed: 'baseFontBySizes'
		put: (Dictionary new
				 at: 12 put: font;
				 yourself).
	self deny: font wasReleased.
	family releaseCachedState.
	self assert: font wasReleased.
	self assert: font releaseCount equals: 1
]

{ #category : 'tests' }
FontFamilyTest >> testReleaseCachedStateWithNothingCachedDoesNotError [
	"The degenerate state: a family that has built no font yet holds an empty dictionary, and
	releasing it must do nothing rather than fail."

	| family |
	family := FontFamily new.
	family instVarNamed: 'baseFontBySizes' put: Dictionary new.
	family releaseCachedState.
	self assert: (family instVarNamed: 'baseFontBySizes') isEmpty
]
