"
I test TTFontStyle, the triple a font states about itself: slant, weight class and width class.

What matters about a style is that it tells two faces of one family apart, so most of what I check is equality: two styles built from the same three facts are one key in a dictionary, and the plainest style is a style like any other rather than a special case the catalogue has to remember.
"
Class {
	#name : 'TTFontStyleTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-TrueType-Tests-Tests',
	#package : 'VectorGraphics-TrueType-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
TTFontStyleTest >> testAStyleIsTheThreeFactsAFontStatesAboutItsFace [
	"The three facts, each answered the way the font's own tables state it: the slant as the
	 symbol the metadata reader uses, the weight and width as the OS/2 classes themselves."
	| style |
	style := TTFontStyle slant: #italic weightClass: 700 widthClass: 3.
	self assert: style slant equals: #italic.
	self assert: style weightClass equals: 700.
	self assert: style widthClass equals: 3
]

{ #category : 'tests' }
TTFontStyleTest >> testAStylePrintsItsThreeFacts [
	"A style is read in an inspector row and in a failure message, so printing it says the three
	 facts rather than the class name alone."
	self
		assert: (TTFontStyle slant: #italic weightClass: 700 widthClass: 3) printString
		equals: 'TTFontStyle(italic 700 3)'.
	self
		assert: TTFontStyle plainest printString
		equals: 'TTFontStyle(normal 400 5)'
]

{ #category : 'tests' }
TTFontStyleTest >> testThePlainestStyleIsTheOrdinaryFaceAndKnowsItself [
	"The style a consumer means when it names a family and nothing else. The three facts are the
	 reader's own constants, so this cannot drift from what the reader calls normal, and a style
	 says whether it is that one rather than letting every caller compare three numbers."
	| plainest |
	plainest := TTFontStyle plainest.
	self assert: plainest slant equals: #normal.
	self assert: plainest weightClass equals: TTFontMetadataReader normalWeightClass.
	self assert: plainest widthClass equals: TTFontMetadataReader normalWidthClass.
	self assert: plainest isPlainest.
	self deny: (TTFontStyle slant: #normal weightClass: 700 widthClass: 5) isPlainest.
	self assert: plainest equals: (TTFontStyle
			 slant: #normal
			 weightClass: TTFontMetadataReader normalWeightClass
			 widthClass: TTFontMetadataReader normalWidthClass)
]

{ #category : 'tests' }
TTFontStyleTest >> testTheStyleViewPutsEveryFactOfMineBesideThePlainestOne [
	"The Style view: one row per slot I hold, read off the class so a fact added to me shows
	 without the view being touched, then a row for the predicate. The middle column states
	 this style, the last one states the plainest."
	| style table rows bold |
	style := TTFontStyle slant: #italic weightClass: 700 widthClass: 3.
	table := style inspectorStyle:
		         (SpPresenterBuilder newApplication: SpApplication new).
	rows := table items asArray.
	self
		assert: (rows collect: [ :each | each key ])
		equals: #( #slant #weightClass #widthClass #isPlainest ).
	bold := rows second.
	self assert: (table columns second evaluation value: bold) equals: '700'.
	self assert: (table columns last evaluation value: bold) equals: '400'.
	self
		assert: (table columns second evaluation value: rows last)
		equals: 'false'.
	self assert: (table columns last evaluation value: rows last) equals: 'true'
]

{ #category : 'tests' }
TTFontStyleTest >> testTwoStylesBuiltFromTheSameThreeFactsAreOneKey [
	"A catalogue indexes a family by style, and the style a consumer asks with is never the
	 object the scan built. So two styles stating the same three facts have to be equal and to
	 hash alike, and one differing fact has to be a different key."
	| style same dictionary |
	style := TTFontStyle slant: #normal weightClass: 400 widthClass: 5.
	same := TTFontStyle slant: #normal weightClass: 400 widthClass: 5.
	self assert: style equals: same.
	self assert: style hash equals: same hash.
	self deny: style = (TTFontStyle slant: #italic weightClass: 400 widthClass: 5).
	self deny: style = (TTFontStyle slant: #normal weightClass: 700 widthClass: 5).
	self deny: style = (TTFontStyle slant: #normal weightClass: 400 widthClass: 3).
	self deny: style = 'not a style'.
	dictionary := Dictionary new.
	dictionary at: style put: #theFace.
	self assert: (dictionary at: same) equals: #theFace
]
