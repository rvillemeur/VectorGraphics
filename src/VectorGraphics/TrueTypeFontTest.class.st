Class {
	#name : 'TrueTypeFontTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-tests',
	#package : 'VectorGraphics',
	#tag : 'tests'
}

{ #category : 'helpers' }
TrueTypeFontTest >> makeFontDescription [

	| fd |
	fd := TTFontDescription new.
	fd setStrings: #( 'CR' 'Arial' 'Regular' 'Uniq' 'Arial' 'v1' 'Arial-Regular' 'TM' ).
	fd setAscent: 800 descent: -200 lineGap: 50.
	fd instVarNamed: 'letterMTopSideBearing' put: 800.
	^ fd
]

{ #category : 'helpers' }
TrueTypeFontTest >> makeFontWithEmphasis: anInt [

	| font |
	font := TrueTypeFont new.
	font instVarNamed: 'emphasis' put: anInt.
	font instVarNamed: 'pointSize' put: 12.
	font instVarNamed: 'glyphFormsByUtf8' put: (Array new: 256).
	font instVarNamed: 'baseFont' put: nil.
	font instVarNamed: 'derivativeFonts' put: Dictionary new.
	font instVarNamed: 'ttFontDescription' put: self makeFontDescription.
	^ font
]

{ #category : 'tests' }
TrueTypeFontTest >> testAddEmphasisCacheResetForStrikeThrough [

	"emphasis 8 (StrikeThrough) masks 4+8 — cache must be reset."

	| font oldCache |
	font := self makeFontWithEmphasis: 0.
	oldCache := font instVarNamed: 'glyphFormsByUtf8'.
	font addEmphasis: 8.
	self deny: (font instVarNamed: 'glyphFormsByUtf8') == oldCache
]

{ #category : 'tests' }
TrueTypeFontTest >> testAddEmphasisCacheResetForUnderline [

	"emphasis 4 (Underline) masks 4+8 — cache must be reset."

	| font oldCache |
	font := self makeFontWithEmphasis: 0.
	oldCache := font instVarNamed: 'glyphFormsByUtf8'.
	font addEmphasis: 4.
	self deny: (font instVarNamed: 'glyphFormsByUtf8') == oldCache
]

{ #category : 'tests' }
TrueTypeFontTest >> testAddEmphasisNoCacheResetForBold [

	"emphasis 1 (Bold) does NOT mask 4+8 — cache unchanged."

	| font oldCache |
	font := self makeFontWithEmphasis: 0.
	oldCache := font instVarNamed: 'glyphFormsByUtf8'.
	font addEmphasis: 1.
	self assert: (font instVarNamed: 'glyphFormsByUtf8') == oldCache
]

{ #category : 'tests' }
TrueTypeFontTest >> testEmphasizedCodeZeroReturnsSelf [

	| font |
	font := self makeFontWithEmphasis: 0.
	self assert: (font emphasized: 0) == font
]

{ #category : 'tests' }
TrueTypeFontTest >> testIsBaseFontFalseWhenBaseFontSet [

	| font base |
	font := self makeFontWithEmphasis: 1.
	base := self makeFontWithEmphasis: 0.
	font instVarNamed: 'baseFont' put: base.
	self deny: font isBaseFont
]

{ #category : 'tests' }
TrueTypeFontTest >> testIsBaseFontTrueWhenBaseFontNil [

	self assert: (self makeFontWithEmphasis: 0) isBaseFont
]

{ #category : 'tests' }
TrueTypeFontTest >> testIsBoldFalse [

	self deny: (self makeFontWithEmphasis: 0) isBold
]

{ #category : 'tests' }
TrueTypeFontTest >> testIsBoldTrue [

	self assert: (self makeFontWithEmphasis: 1) isBold
]

{ #category : 'tests' }
TrueTypeFontTest >> testIsItalicFalse [

	self deny: (self makeFontWithEmphasis: 1) isItalic
]

{ #category : 'tests' }
TrueTypeFontTest >> testIsItalicTrue [

	self assert: (self makeFontWithEmphasis: 2) isItalic
]

{ #category : 'tests' }
TrueTypeFontTest >> testIsStruckThrough [

	self deny: (self makeFontWithEmphasis: 4) isStruckThrough.
	self assert: (self makeFontWithEmphasis: 8) isStruckThrough
]

{ #category : 'tests' }
TrueTypeFontTest >> testIsSubscript [

	self deny: (self makeFontWithEmphasis: 16) isSubscript.
	self assert: (self makeFontWithEmphasis: 32) isSubscript
]

{ #category : 'tests' }
TrueTypeFontTest >> testIsSuperscript [

	self deny: (self makeFontWithEmphasis: 32) isSuperscript.
	self assert: (self makeFontWithEmphasis: 16) isSuperscript
]

{ #category : 'tests' }
TrueTypeFontTest >> testIsUnderlined [

	self assert: (self makeFontWithEmphasis: 4) isUnderlined.
	self deny: (self makeFontWithEmphasis: 8) isUnderlined
]

{ #category : 'tests' }
TrueTypeFontTest >> testPrintOn [

	| font family stream |
	font := self makeFontWithEmphasis: 0.
	family := TrueTypeFontFamily new.
	family instVarNamed: 'familyName' put: 'Arial'.
	font instVarNamed: 'family' put: family.
	stream := WriteStream on: String new.
	font printOn: stream.
	self assert: (stream contents includesSubstring: 'TrueTypeFont').
	self assert: (stream contents includesSubstring: 'Arial').
	self assert: (stream contents includesSubstring: '12')
]

{ #category : 'tests' }
TrueTypeFontTest >> testReleaseCachedStateNilsCache [

	| font cache |
	font := self makeFontWithEmphasis: 0.
	cache := font instVarNamed: 'glyphFormsByUtf8'.
	cache at: 1 put: 'someGlyph'.
	font releaseCachedState.
	self assert: (cache at: 1) isNil
]
