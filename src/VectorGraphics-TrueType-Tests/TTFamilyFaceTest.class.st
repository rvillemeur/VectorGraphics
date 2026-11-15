"
What a face of a family answers before and after its outlines are read. The fixtures carry no glyph tables, so a parse raises: that is how a test states that a face read nothing, and when it reached for the bytes.
"
Class {
	#name : 'TTFamilyFaceTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-TrueType-Tests-Tests',
	#package : 'VectorGraphics-TrueType-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
TTFamilyFaceTest >> testAFaceFromACatalogueEntryNamesItselfWithoutReadingItsOutlines [
	"A face a scan met says what it is from the entry alone: the family it belongs to, the
	 style it calls itself, and that nothing has been read of it. Reaching for its description
	 is the only thing that reads the bytes — with these fixtures, that raises."

	| catalogue entry face |
	catalogue := TTFontFixtures catalogueOfThreeFacesInOneFamily.
	entry := (catalogue entriesByFamilyName at: 'fixture sans') values detect: [
		         :each | each metadata styleName = 'Bold' ].
	face := TTFamilyFace catalogueEntry: entry.

	self assert: face familyName equals: 'Fixture Sans'.
	self assert: face styleName equals: 'Bold'.
	self deny: face isParsed.
	self assert: face catalogueEntry identicalTo: entry.
	self
		should: [ face ttFontDescription ]
		raise: Error
		withExceptionDo: [ :error |
			self
				assert: error messageText
				equals: 'Missing required TrueType table: head' ]
]

{ #category : 'tests' }
TTFamilyFaceTest >> testAFaceFromADescriptionIsParsedFromTheStartAndHasNoEntry [
	"A face posed as a parsed description — a font loaded on its own, by a test or an example —
	 is read from the start, has no catalogue entry behind it, and names itself from the
	 description."

	| description face |
	description := TrueTypeExamples loadFontFrom:
		               TrueTypeExamples defaultFontPath.
	face := TTFamilyFace ttFontDescription: description.

	self assert: face isParsed.
	self assert: face catalogueEntry equals: nil.
	self assert: face familyName equals: description familyName.
	self assert: face styleName equals: description fullName.
	self assert: face ttFontDescription identicalTo: description
]

{ #category : 'tests' }
TTFamilyFaceTest >> testTheFaceViewSaysWhereIComeFromAndReadsNothing [
	"The view the way the inspector builds it, through StInspectionContext, which refuses a
	 view that does not take a presenter builder. A table's column blocks run per drawn row
	 only, so each is run over each row here. Opening it on a pending face reads no bytes —
	 with these fixtures a read would raise."

	| builder presenter rows |
	builder := SpPresenterBuilder newApplication: SpApplication new.
	presenter := (StInspectionContext new
		              inspectedObject:
			              (TTFamilyFace catalogueEntry:
					               (TTFontFixtures catalogueOfThreeFacesInOneFamily
						                entryOfFamilyNamed: 'Fixture Sans'));
		              methodSelector: #inspectorFace:;
		              yourself) basicNewInspectionPresenter: builder.
	rows := presenter items collect: [ :item |
		        presenter columns collect: [ :column |
			        column evaluation value: item ] ].

	self assert: rows asArray equals: {
			{ 'Family'. 'Fixture Sans' }.
			{ 'Style'. 'Regular' }.
			{ 'Outlines'. 'pending' }.
			{ 'Comes from'. '219 bytes' } }
]
