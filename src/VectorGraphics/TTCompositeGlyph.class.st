"
A composite TrueType glyph composed of references to one or more simple TTGlyphs.

Composite glyphs are used in fonts for characters that combine existing glyphs with optional
transformations (e.g. accented letters built from a base letter + a diacritic glyph).

TTFontReader creates TTCompositeGlyph when the glyph table entry has a negative contour count
(the TrueType spec's flag for composite glyphs). It stores each component as a (transform, glyph)
Association in the `glyphs` collection.

## Key instVar
- `glyphs`  OrderedCollection of Association (key: transformation, value: TTGlyph)

## Key method override
- `addContourDataTo: stream tx: aGeometryTransformationOrNil`
  Delegates to each component glyph with its combined transformation, producing the
  same path output as a simple glyph but from multiple source glyphs.
"
Class {
	#name : 'TTCompositeGlyph',
	#superclass : 'TTGlyph',
	#instVars : [
		'glyphs'
	],
	#category : 'VectorGraphics-TrueType',
	#package : 'VectorGraphics',
	#tag : 'TrueType'
}

{ #category : 'primitive format' }
TTCompositeGlyph >> addContourDataTo: stream tx: aGeometryTransformationOrNil [

	| glyph tx |
	glyphs do: [ :txAndGlyph | 
		tx := txAndGlyph key.
		aGeometryTransformationOrNil notNil ifTrue: [ 
			tx := aGeometryTransformationOrNil composedWith: tx ].
		glyph := txAndGlyph value.
		glyph addContourDataTo: stream tx: tx ]
]

{ #category : 'accessing' }
TTCompositeGlyph >> addGlyph: aGlyph transformation: aMatrix [

	glyphs := glyphs copyWith: aMatrix -> aGlyph
]

{ #category : 'accessing' }
TTCompositeGlyph >> contourCount [

	| glyph count |
	count := 0.
	glyphs do: [ :txAndGlyph | 
		glyph := txAndGlyph value.
		count := count + glyph contourCount ].
	^ count
]

{ #category : 'drawing' }
TTCompositeGlyph >> drawGlyphOn: aVectorCanvas [

	glyphs do: [ :each | 
		each value
			drawGlyphOn: aVectorCanvas
			geometryTransformation: each key ]
]

{ #category : 'accessing' }
TTCompositeGlyph >> glyphs [

	^ glyphs collect: [ :assoc | assoc value ]
]

{ #category : 'initialization' }
TTCompositeGlyph >> initialize [

	super initialize.
	glyphs := #(  )
]

{ #category : 'testing' }
TTCompositeGlyph >> isComposite [

	^ true
]

{ #category : 'private-initialization' }
TTCompositeGlyph >> replaceIndexesByComponentGlyphsIn: anArray [

	glyphs := glyphs collect: [ :assoc | 
		          assoc key -> (anArray at: assoc value) ]
]

{ #category : 'drawing' }
TTCompositeGlyph >> txAndContoursDo: aBlock [

	glyphs do: [ :assoc | 
		aBlock value: assoc key value: assoc value contours ]
]
