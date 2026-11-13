Extension { #name : 'TTFontCatalogueEntry' }

{ #category : '*VectorGraphics-Bloc' }
TTFontCatalogueEntry >> inspectorShaping: aBuilder [
	"What HarfBuzz makes of a fixed sample word through me, at a fixed size. The figures are
	 shaped here and now rather than described: the scale is read back off the font HarfBuzz
	 answered, and the glyphs are the ones it placed, so neither can drift from
	 newHbFontScaledTo:. The source row names where the blob came from — a basename for a file,
	 a byte count for a font held in memory — which is the one thing that tells the two routes
	 apart.

	 Shaping calls libharfbuzz and, for a font held in memory, pins my bytes. It changes nothing
	 of mine."

	<inspectorPresentationOrder: 20 title: 'Shaping'>
	| font buffer rows |
	font := self newHbFontScaledTo: 22.
	buffer := AeHbBuffer new
		          direction: AeHbDirection leftToRight;
		          script: AeHbScript latin;
		          language: AeHbLanguage en;
		          addString: 'Pharo';
		          yourself.
	buffer shapeWithFont: font.
	rows := OrderedCollection new.
	rows add: 'blob source' -> source fontSourceName.
	rows add: 'scale, 26.6 of 22 px' -> font scale printString.
	buffer cairoGlyphArray doWithIndex: [ :each :index |
		rows add: 'glyph ' , index printString
				-> ('identifier ' , each index printString , ', x '
					 , each x printString) ].
	^ aBuilder newTable
		  addColumn:
			  ((SpStringTableColumn title: 'Name' evaluated: [ :each | each key ])
				   width: 160);
		  addColumn:
			  (SpStringTableColumn title: 'Value' evaluated: [ :each | each value ]);
		  items: rows asArray;
		  yourself
]

{ #category : '*VectorGraphics-Bloc' }
TTFontCatalogueEntry >> inspectorShapingContext: aContext [
	"The Shaping view shapes a word with me, which a refused file cannot do: newHbFontScaledTo:
	 signals rather than shape it. So the tab is there for a drawable entry only, and the
	 refusal itself is already named by the Source view."

	aContext active: self isRejected not
]

{ #category : '*VectorGraphics-Bloc' }
TTFontCatalogueEntry >> newHbFontScaledTo: aSize [
	"A HarfBuzz font over the font I name, ready to shape a run at this pixel size. An extension
	 of this project: upstream answers one from AeFaceEntry >> newHbFont, and I am not an
	 AeFaceEntry.

	 A refused file is refused here too, although HarfBuzz would read it: it parses a font file
	 itself and accepts a collection, which this project's reader rejects. The glyph identifiers
	 would then name glyphs of a face no font face of this project can draw. The sentence is the
	 one VGFontManager >> refuseFaceFor: says about a face, said about shaping.

	 The face index is 0 because I hold one font: a file holding several is a collection, which
	 the reader refuses before I am made drawable.

	 The scale is aSize * 64 on both axes. A font built from a blob is unscaled — its scale is
	 the units per em of its face — while AeHbBuffer >> cairoGlyphArray reads every advance and
	 offset as 26.6 fixed point. hb_ft_font_create_referenced posed this scale from the size
	 set on the FreeType face; nothing poses it for us."

	self isRejected ifTrue: [
		^ Error signal:
			  'The font reader refused ' , self source fontSourceName , ': '
			  , self metadata rejectionReason asString
			  , '. Nothing can be shaped with it.' ].
	^ (self source newHbBlob newHbFaceAtIndex: 0) newHbFont
		  scaleX: aSize * 64 y: aSize * 64;
		  yourself
]
