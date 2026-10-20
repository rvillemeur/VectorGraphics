"
I am the cache of rasterised glyphs of one scaled font. I answer a VGGlyphMask for a glyph, and I rasterise it only the first time I am asked.

My key is the glyph index, the device matrix in force and the sub-pixel phase of the glyph's origin. The phase belongs in the key because a mask is a grid of pixels: the same glyph a third of a pixel to the right covers its pixels differently. Our device coordinates are snapped to Cairo's grid of two hundred and fifty sixths of a pixel, so there is a finite number of phases, and text laid out on whole pixels reuses one mask for every repetition of a letter.

`renderedGlyphCount` counts the rasterisations I have done, which is how a test proves that a repeated draw builds each glyph once.
"
Class {
	#name : 'VGGlyphAtlas',
	#superclass : 'Object',
	#instVars : [
		'masks',
		'renderedGlyphCount'
	],
	#category : 'VectorGraphics-Cairo-Text',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Text'
}

{ #category : 'initialization' }
VGGlyphAtlas >> initialize [
	super initialize.
	masks := Dictionary new.
	renderedGlyphCount := 0
]

{ #category : 'inspector' }
VGGlyphAtlas >> inspectorMasks: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Masks'>
	"One row per glyph the atlas has been asked for, with the key it was cached under: the glyph,
	 its sub-pixel phase and the matrix without its translation. A glyph that inks nothing is kept
	 with no mask, which is why a row can say so; that is what stops it being rasterised again."

	^ aBuilder newTable
		  items: self masks associations asArray;
		  addColumn: (SpStringTableColumn
				   title: 'Glyph'
				   evaluated: [ :each | each key first printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Phase'
				   evaluated: [ :each | each key second printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Matrix'
				   evaluated: [ :each | each key third printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Mask'
				   evaluated: [ :each |
					   each value
						   ifNil: [ 'inks nothing' ]
						   ifNotNil: [ :mask | mask extent printString ] ]);
		  addColumn: (SpStringTableColumn
				   title: 'Offset'
				   evaluated: [ :each |
					   each value
						   ifNil: [ '' ]
						   ifNotNil: [ :mask | mask offset printString ] ]);
		  yourself
]

{ #category : 'inspector' }
VGGlyphAtlas >> inspectorMasksContext: aContext [
	aContext active: self masks notNil
]

{ #category : 'inspector' }
VGGlyphAtlas >> inspectorWork: aBuilder [
	<inspectorPresentationOrder: 11 title: 'Work saved'>
	"What the atlas is for: the number of glyphs it holds against the number it actually
	 rasterised. The difference is the glyphs that ink nothing, and the gap between either number
	 and the glyphs a drawing asked for is the work the cache saved."

	^ aBuilder newTable
		  items: {
				  ('Cached keys' -> self size).
				  ('Rasterised' -> self renderedGlyphCount).
				  ('Cached with no ink' -> (self masks count: [ :each | each isNil ])) };
		  addColumn: (SpStringTableColumn title: 'Property' evaluated: [ :each | each key ]);
		  addColumn: (SpStringTableColumn
				   title: 'Value'
				   evaluated: [ :each | each value printString ]);
		  yourself
]

{ #category : 'inspector' }
VGGlyphAtlas >> inspectorWorkContext: aContext [
	aContext active: self masks notNil
]

{ #category : 'accessing' }
VGGlyphAtlas >> maskForGlyph: aGlyphIndex phase: aPoint matrix: aMatrix ifAbsentPut: aBlock [
	"The mask of one glyph under one matrix at one phase, rasterised by the block the first time
	 it is asked for. A glyph that inks nothing has no mask; nil is remembered for it like any
	 other answer, so a space is looked at once and never again, and it counts as nothing
	 rasterised."

	| key mask |
	key := {
		       aGlyphIndex.
		       aPoint.
		       aMatrix }.
	masks at: key ifPresent: [ :cached | ^ cached ].
	mask := aBlock value.
	mask ifNotNil: [ renderedGlyphCount := renderedGlyphCount + 1 ].
	^ masks at: key put: mask
]

{ #category : 'accessing' }
VGGlyphAtlas >> masks [
	^ masks
]

{ #category : 'printing' }
VGGlyphAtlas >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPutAll: '(';
		print: masks size;
		nextPutAll: ' cached, ';
		print: renderedGlyphCount;
		nextPutAll: ' rasterised)'
]

{ #category : 'accessing' }
VGGlyphAtlas >> renderedGlyphCount [
	"How many glyphs I have rasterised. A repeated draw must not raise it."

	^ renderedGlyphCount
]

{ #category : 'accessing' }
VGGlyphAtlas >> size [
	^ masks size
]
