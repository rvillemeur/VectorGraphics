"
I state that a run of text is shaped into glyph identifiers through HarfBuzz from a catalogue entry of this project, with no FreeType face anywhere in the route.

HarfBuzz is not in Bloc's own text path: the only senders of `AeHbBuffer` in this image are Alexandrie's experiments and tests, this project's ported experiments, and me. What I pin is therefore the shaping service itself, not the drawing of a window: a consumer that wants ligatures or a complex script asks `TTFontCatalogueEntry >> newHbFontScaledTo:` and shapes with it.

Upstream reaches HarfBuzz two ways. `AeHbBuffer >> cairoGlyphArrayForFace:size:` sets a size on an `AeFTFace` and calls `hb_ft_font_create_referenced`, which needs FreeType. `AeFaceEntry >> newHbFont` builds a blob instead, which needs nothing but the bytes — and no production method sent it before this unit. I take the second way and count the `AeFTFace` instances of the image across the shaping to prove the first one is not taken.

One test per kind of source, because the two take different routes to the blob and only one of them can hand HarfBuzz a pointer into Pharo's object memory.

I call libharfbuzz through uFFI. Commit before running me.
"
Class {
	#name : 'VGHarfbuzzShapingTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Bloc-Tests',
	#package : 'VectorGraphics-Bloc-Tests'
}

{ #category : 'tests' }
VGHarfbuzzShapingTest >> testAFileTheReaderRefusedIsNotShapedAtAll [
	"HarfBuzz would happily open a file this project's reader refuses — it parses the file
	 itself and even reads a collection, which the reader rejects. The glyph identifiers it
	 answered would then name glyphs of a face no Cairo font face of this project can draw, and
	 the drawing would fail far from the cause. So the entry refuses first, naming the file and
	 the reason the reader gave."

	| catalogue entry |
	catalogue := TTFontCatalogue new.
	entry := catalogue addBytes: 'StartFontMetrics 2.0' asByteArray.
	self assert: entry isRejected.
	self
		should: [ entry newHbFontScaledTo: 22 ]
		raise: Error
		withExceptionDo: [ :error |
			self assert:
				(error messageText includesSubstring: entry source fontSourceName).
			self assert: (error messageText includesSubstring:
					 entry metadata rejectionReason asString) ]
]

{ #category : 'tests' }
VGHarfbuzzShapingTest >> testAFontOnDiskShapesAWordThroughABlobHarfbuzzOpensItself [
	"A font read from a file shapes the same word. HarfBuzz opens the file, so the bytes it
	 reads are never in Pharo's object memory: the route differs from the one an embedded font
	 takes, which is why this test exists beside the other one."

	| catalogue entry font buffer glyphs freetypeFacesBefore |
	freetypeFacesBefore := AeFTFace allInstances size.
	catalogue := TTFontCatalogue new.
	catalogue addFile: AeFilesystemResources inriaSerifRegularTTF.
	entry := catalogue entries first.
	self deny: entry isRejected.
	font := entry newHbFontScaledTo: 22.
	self assert: font scale equals: 22 * 64 @ (22 * 64).
	buffer := AeHbBuffer new
		          direction: AeHbDirection leftToRight;
		          script: AeHbScript latin;
		          language: AeHbLanguage en;
		          addString: 'Pharo'.
	buffer shapeWithFont: font.
	glyphs := buffer cairoGlyphArray.
	self assert: glyphs size equals: 5.
	glyphs do: [ :each | self assert: each index > 0 ].
	self assert: AeFTFace allInstances size equals: freetypeFacesBefore
]

{ #category : 'tests' }
VGHarfbuzzShapingTest >> testAnEmbeddedFontShapesAWordIntoGlyphIdentifiersWithoutFreeType [
	"A font this project carries in memory shapes a word. The scale is the one the 26.6 fixed
	 point of AeHbBuffer >> cairoGlyphArray assumes, and no FreeType face is built on the way."

	| catalogue entry font buffer glyphs freetypeFacesBefore |
	freetypeFacesBefore := AeFTFace allInstances size.
	catalogue := TTFontCatalogue new.
	catalogue addBytes: AeSourceSansPro_Regular fontContentsData.
	entry := catalogue entries first.
	font := entry newHbFontScaledTo: 22.
	self assert: font scale equals: 22 * 64 @ (22 * 64).
	buffer := AeHbBuffer new
		          direction: AeHbDirection leftToRight;
		          script: AeHbScript latin;
		          language: AeHbLanguage en;
		          addString: 'Pharo'.
	buffer shapeWithFont: font.
	glyphs := buffer cairoGlyphArray.
	self assert: glyphs size equals: 5.
	glyphs do: [ :each | self assert: each index > 0 ].
	self assert: AeFTFace allInstances size equals: freetypeFacesBefore
]

{ #category : 'tests' }
VGHarfbuzzShapingTest >> testTheShapingViewShapesTheSampleWordAndIsOfferedOnDrawableEntriesOnly [
	"The view a reader opens on an entry. It shapes rather than describes, so the scale it shows
	 is the one HarfBuzz answers and the glyph rows are the glyphs it placed. A refused entry
	 cannot shape at all, so the tab is not offered on one."

	| entry rows refused context |
	entry := TTFontCatalogue new addBytes:
		         AeSourceSansPro_Regular fontContentsData.
	rows := (entry inspectorShaping:
		         (SpPresenterBuilder newApplication: SpApplication new)) items.
	self assert: rows size equals: 7.
	self assert: rows first key equals: 'blob source'.
	self assert: rows first value equals: entry source fontSourceName.
	self assert: (rows at: 2) value equals: (22 * 64 @ (22 * 64)) printString.
	self
		assert: ((rows last: 5) collect: [ :each | each key ])
		equals: #( 'glyph 1' 'glyph 2' 'glyph 3' 'glyph 4' 'glyph 5' ).
	context := StInspectionContext new.
	entry inspectorShapingContext: context.
	self assert: context isActive.
	refused := TTFontCatalogue new addBytes: 'StartFontMetrics 2.0' asByteArray.
	context := StInspectionContext new.
	refused inspectorShapingContext: context.
	self deny: context isActive
]
