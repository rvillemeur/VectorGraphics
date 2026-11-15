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

{ #category : 'private' }
FontFamilyTest >> catalogueOfSixFacesInTwoFamilies [
	"A catalogue of fonts nobody wrote to disk: three styles each of two families, met through
	 addBytes:. The bytes carry a name table and an OS/2 table, which is all a scan reads, and
	 no glyph tables at all — so a parse of one of them raises, which is how a test states that
	 registering a family parsed nothing."

	| catalogue |
	catalogue := TTFontCatalogue new.
	#( 'Source Sans Pro' 'Source Code Pro' ) do: [ :familyName |
		{
			{ 'Regular'. 400. false }.
			{ 'Bold'. 700. false }.
			{ 'Italic'. 400. true } } do: [ :style |
			catalogue addBytes: (TTFontFixtures
					 renderableFontBytesWithFamilyName: familyName
					 styleName: style first
					 weightClass: style second
					 italic: style third) ] ].
	^ catalogue
]

{ #category : 'helpers' }
FontFamilyTest >> makeFamilyNamed: aString [

	| family |
	family := FontFamily new.
	family familyName: aString.
	^ family
]

{ #category : 'running' }
FontFamilyTest >> setUp [
	super setUp.
	savedEntries := FontFamily availableFamilies copy.
	FontFamily availableFamilies keys asArray do: [ :k |
		FontFamily availableFamilies removeKey: k ]
]

{ #category : 'running' }
FontFamilyTest >> tearDown [
	FontFamily availableFamilies keys asArray do: [ :k |
		FontFamily availableFamilies removeKey: k ].
	savedEntries keysAndValuesDo: [ :k :v |
		FontFamily availableFamilies at: k put: v ].
	super tearDown
]

{ #category : 'tests' }
FontFamilyTest >> testAddFamiliesFromACatalogueRegistersALazyFamilyPerNameAndLeavesThePosedOnesAlone [
	"Unit 5.4: the registry takes its families from a catalogue. Four facts. One family per name
	 the catalogue holds, under the name a font states rather than the lower-case key the
	 catalogue indexes by. Each is a TrueTypeFontFamily. A family posed by hand under a name the
	 catalogue also holds is left exactly where it was, since a scan is a floor and not an
	 authority. And nothing was parsed: these fixtures carry no glyph tables, so the parse the
	 first point size asks for is the one that raises."

	| posed |
	posed := self makeFamilyNamed: 'Source Sans Pro'.
	FontFamily addFamily: posed.
	FontFamily addFamiliesFrom: self catalogueOfSixFacesInTwoFamilies.
	self
		assert: FontFamily familyNames
		equals: #( 'Source Code Pro' 'Source Sans Pro' ).
	self assert: (FontFamily familyNamed: 'Source Sans Pro') identicalTo: posed.
	self
		assert: (FontFamily familyNamed: 'Source Code Pro') class
		equals: TrueTypeFontFamily.
	self
		assert: (FontFamily familyNamed: 'Source Code Pro') familyName
		equals: 'Source Code Pro'.
	self
		should: [ (FontFamily familyNamed: 'Source Code Pro') atPointSize: 12 ]
		raise: Error
		withExceptionDo: [ :error |
			self
				assert: error messageText
				equals: 'Missing required TrueType table: head' ]
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
