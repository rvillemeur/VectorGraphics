"
I am what tells two faces of one family apart: the slant, the weight class and the width class a font states about itself.

The three facts come from the font's own tables, as TTFontMetadataReader reads them — the slant as a symbol (`#normal`, `#italic`, `#oblique`), the weight and the width as the OS/2 classes themselves, 400 and 5 for an ordinary face. I hold them and nothing else, and two styles built from the same three facts are equal and hash alike, so a catalogue indexes a family by me.

`plainest` is the ordinary face of a family: upright, normal weight, normal width. A consumer that names only a family means that one.

I say nothing about a family name, nor about a style name: those two are what a font calls itself, where I am what it measures. A face whose style name says nothing of its width still states a width class.
"
Class {
	#name : 'TTFontStyle',
	#superclass : 'Object',
	#instVars : [
		'slant',
		'weightClass',
		'widthClass'
	],
	#category : 'VectorGraphics-TrueType-Reading',
	#package : 'VectorGraphics-TrueType',
	#tag : 'Reading'
}

{ #category : 'instance creation' }
TTFontStyle class >> plainest [
	"The ordinary face of a family: upright, normal weight, normal width. The three facts are
	 the metadata reader's own constants, so what counts as plain is stated in one place."
	^ self
		  slant: #normal
		  weightClass: TTFontMetadataReader normalWeightClass
		  widthClass: TTFontMetadataReader normalWidthClass
]

{ #category : 'instance creation' }
TTFontStyle class >> slant: aSymbol weightClass: aWeightClass widthClass: aWidthClass [
	"The style of a face that states these three facts."
	^ self new
		  setSlant: aSymbol
		  weightClass: aWeightClass
		  widthClass: aWidthClass
]

{ #category : 'comparing' }
TTFontStyle >> = anObject [
	"Two styles are one style when they state the same three facts: that is what makes me a key."
	^ self class = anObject class and: [
		  slant = anObject slant and: [
			  weightClass = anObject weightClass and: [
				  widthClass = anObject widthClass ] ] ]
]

{ #category : 'comparing' }
TTFontStyle >> hash [
	^ slant hash bitXor: (weightClass hash bitXor: widthClass hash)
]

{ #category : 'inspector' }
TTFontStyle >> inspectorStyle: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Style'>
	"The facts I hold, each beside what the plainest style states for the same fact, so a reader
	 sees which one makes this face unusual. The rows are my own slots, read off the class, so a
	 fact added to me shows here without this view being touched; the last row asks isPlainest
	 rather than comparing the rows itself."
	| plainest |
	plainest := self class plainest.
	^ aBuilder newTable
		  items: ((self class allInstVarNames collect: [ :each |
					    each -> {
							    (self instVarNamed: each).
							    (plainest instVarNamed: each) } ])
				   copyWith: #isPlainest -> {
						   self isPlainest.
						   plainest isPlainest });
		  addColumn: (SpStringTableColumn title: 'Fact' evaluated: #key);
		  addColumn: (SpStringTableColumn
				   title: 'This style'
				   evaluated: [ :each | (each value at: 1) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Plainest'
				   evaluated: [ :each | (each value at: 2) printString ]);
		  yourself
]

{ #category : 'inspector' }
TTFontStyle >> inspectorStyleContext: aContext [
	"Nothing to compare while I am half built: a style with no slant yet is an instance the
	 reader of an example sees for a moment, and the table would show nils against the plainest
	 style's facts."
	aContext active: slant notNil
]

{ #category : 'testing' }
TTFontStyle >> isPlainest [
	"Am I the ordinary face of a family? Asked by whoever shows a list of faces, so a reader
	 does not compare three numbers of their own."
	^ self = self class plainest
]

{ #category : 'printing' }
TTFontStyle >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPut: $(;
		nextPutAll: slant;
		nextPut: $ ;
		print: weightClass;
		nextPut: $ ;
		print: widthClass;
		nextPut: $)
]

{ #category : 'initialization' }
TTFontStyle >> setSlant: aSymbol weightClass: aWeightClass widthClass: aWidthClass [
	slant := aSymbol.
	weightClass := aWeightClass.
	widthClass := aWidthClass
]

{ #category : 'accessing' }
TTFontStyle >> slant [
	"#normal, #italic or #oblique, the symbol the metadata reader states."
	^ slant
]

{ #category : 'accessing' }
TTFontStyle >> weightClass [
	"The OS/2 weight class itself: 400 for an ordinary face, 700 for a bold one."
	^ weightClass
]

{ #category : 'accessing' }
TTFontStyle >> widthClass [
	"The OS/2 width class itself, counted from one: 5 for an ordinary face, 1 for
	 ultra-condensed."
	^ widthClass
]
