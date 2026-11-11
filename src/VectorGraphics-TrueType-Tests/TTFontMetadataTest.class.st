"
I test TTFontMetadata, the value object a font scan keeps for one face: the family it belongs to and its style within that family.

Both names come from the font's own name table, read by TTFontMetadataReader. I hold no glyph, no metric and no outline, so there is nothing here that costs a parse.
"
Class {
	#name : 'TTFontMetadataTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-TrueType-Tests-Tests',
	#package : 'VectorGraphics-TrueType-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
TTFontMetadataTest >> testPrintingNamesTheFamilyAndTheStyle [
	"A reader of a font list sees many of these at once, so the printed form has to say which
	 face it is without being opened."

	| metadata |
	metadata := TTFontMetadata new.
	metadata familyName: 'Source Sans Pro'.
	metadata styleName: 'Bold Italic'.
	self assert: (metadata printString includesSubstring: 'Source Sans Pro').
	self assert: (metadata printString includesSubstring: 'Bold Italic')
]

{ #category : 'tests' }
TTFontMetadataTest >> testTheIdentityViewOfAFaceWithNothingReadYetBuildsAndShowsEmptyStrings [
	"The degenerate state: a metadata object whose names and style have not been set. A table
	 column answering nil draws nothing and raises nothing, so only running the column blocks
	 over the rows catches it — which is what the inspector does per drawn row."

	| builder presenter values |
	builder := SpPresenterBuilder newApplication: SpApplication new.
	presenter := (StInspectionContext new
		              inspectedObject: TTFontMetadata new;
		              methodSelector: #inspectorIdentity:;
		              yourself) basicNewInspectionPresenter: builder.
	values := OrderedCollection new.
	presenter columns do: [ :column |
		presenter items do: [ :item | values add: (column evaluation value: item) ] ].
	self assert: (values allSatisfy: [ :each | each isString ]).
	self assert: presenter items size equals: 5
]

{ #category : 'tests' }
TTFontMetadataTest >> testTheIdentityViewShowsTheThreeFactsAFaceIsMatchedOn [
	"A reader opening a face must see what a font manager will match it on, in the font's own
	 numbers: the OS/2 weight class, the OS/2 width class and the slant."

	| builder metadata presenter values |
	metadata := TTFontMetadata new.
	metadata
		familyName: 'Source Sans Pro';
		styleName: 'Bold Italic';
		weightClass: 700;
		widthClass: 3;
		slant: #italic.
	builder := SpPresenterBuilder newApplication: SpApplication new.
	presenter := (StInspectionContext new
		              inspectedObject: metadata;
		              methodSelector: #inspectorIdentity:;
		              yourself) basicNewInspectionPresenter: builder.
	values := presenter items collect: [ :item |
		          (presenter columns last evaluation value: item) ].
	self assert: values asArray equals: #( 'Source Sans Pro' 'Bold Italic' '700' '3' 'italic' )
]

{ #category : 'tests' }
TTFontMetadataTest >> testTheTablesViewBuildsThroughThePresenterBuilderAndMarksOnlyTheTableThatIsRead [
	"The view the way the inspector builds it: through StInspectionContext, which hands the
	 method a presenter builder and refuses a view that does not take one. A table's column
	 blocks run per drawn row only, so each is run over each row here. The Read column must
	 mark the name table and nothing else, which is the claim the view makes about the cost."

	| builder metadata presenter marked |
	metadata := TTFontMetadata new.
	metadata tableLengthsByTag: (Dictionary newFrom: {
				 (TTFontMetadataReader nameTableTag -> 820).
				 ('glyf' -> 1537448).
				 ('loca' -> 7836) }).
	builder := SpPresenterBuilder newApplication: SpApplication new.
	presenter := (StInspectionContext new
		              inspectedObject: metadata;
		              methodSelector: #inspectorTables:;
		              yourself) basicNewInspectionPresenter: builder.
	marked := OrderedCollection new.
	presenter columns do: [ :column |
		presenter items do: [ :item |
			| value |
			value := column evaluation value: item.
			(column title = 'Read' and: [ value = 'yes' ]) ifTrue: [
				marked add: item key ] ] ].
	self assert: presenter items size equals: 3.
	self assert: marked asArray equals: { TTFontMetadataReader nameTableTag }
]
