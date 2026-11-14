Extension { #name : 'VGScaledFont' }

{ #category : '*VectorGraphics-Bloc' }
VGScaledFont >> aeTextFont [
	"My adapter for the Alexandrie route, built on first use and kept: it holds the masks Cairo
	 rasterised for my glyphs, and each context of a frame poses me again. This is the one
	 selector of that package I answer; the five text verbs are the adapter's."

	^ aeTextFont ifNil: [ aeTextFont := VGAeTextFont on: self ]
]

{ #category : '*VectorGraphics-Bloc' }
VGScaledFont >> glyphsOf: aGlyphArray size: aNumberOfGlyphs [
	"The first aNumberOfGlyphs glyphs of an array, as a collection I can walk. Alexandrie hands
	 over an opaque external array that answers its size and nothing else; the indexable
	 structure behind it comes from #asExternalStructure. Its glyphs answer index, x and y, as
	 ours do."

	| indexable |
	indexable := (aGlyphArray respondsTo: #asExternalStructure)
		             ifTrue: [ aGlyphArray asExternalStructure ]
		             ifFalse: [ aGlyphArray ].
	^ (1 to: aNumberOfGlyphs) collect: [ :index | indexable at: index ]
]
