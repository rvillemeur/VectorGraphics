Class {
	#name : 'TTCompositeGlyphTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-tests',
	#package : 'VectorGraphics',
	#tag : 'tests'
}

{ #category : 'helpers' }
TTCompositeGlyphTest >> makeGlyphWithNonEmptyContour [

	| glyph pts contour |
	pts := Int16PointArray new: 3.
	pts at: 1 put: 0 @ 0.
	pts at: 2 put: 10 @ 0.
	pts at: 3 put: 5 @ 10.
	contour := TTContourConstruction new.
	contour instVarNamed: 'points' put: pts.
	contour instVarNamed: 'controlPointFlags' put: (ByteArray newBits: 3).
	glyph := TTGlyph new.
	glyph contours: (Array with: contour).
	^ glyph
]

{ #category : 'tests' }
TTCompositeGlyphTest >> testAddContourDataToDelegatesToSubGlyphs [

	"Composite with one sub-glyph (tx=nil): stream receives the sub-glyph's contour data."

	| composite subGlyph stream compositeStream |
	subGlyph := self makeGlyphWithNonEmptyContour.
	composite := TTCompositeGlyph new.
	composite addGlyph: subGlyph transformation: nil.

	"Collect what the sub-glyph writes directly."
	stream := WriteStream on: Float32Array new.
	subGlyph addContourDataTo: stream tx: nil.

	"Collect what the composite writes — should match."
	compositeStream := WriteStream on: Float32Array new.
	composite addContourDataTo: compositeStream tx: nil.

	self assert: compositeStream contents equals: stream contents
]

{ #category : 'tests' }
TTCompositeGlyphTest >> testAddGlyphAppearsInGlyphs [

	| composite subGlyph |
	subGlyph := TTGlyph new.
	composite := TTCompositeGlyph new.
	composite addGlyph: subGlyph transformation: nil.
	self assert: composite glyphs size equals: 1.
	self assert: composite glyphs first equals: subGlyph
]

{ #category : 'tests' }
TTCompositeGlyphTest >> testAddMultipleGlyphs [

	| composite g1 g2 |
	g1 := TTGlyph new.
	g2 := TTGlyph new.
	composite := TTCompositeGlyph new.
	composite addGlyph: g1 transformation: nil.
	composite addGlyph: g2 transformation: nil.
	self assert: composite glyphs size equals: 2
]

{ #category : 'tests' }
TTCompositeGlyphTest >> testContourCountEmpty [

	self assert: TTCompositeGlyph new contourCount equals: 0
]

{ #category : 'tests' }
TTCompositeGlyphTest >> testContourCountSumsSubGlyphs [

	"One sub-glyph with 1 non-empty contour + one with 1 non-empty contour = 2."

	| composite |
	composite := TTCompositeGlyph new.
	composite addGlyph: self makeGlyphWithNonEmptyContour transformation: nil.
	composite addGlyph: self makeGlyphWithNonEmptyContour transformation: nil.
	self assert: composite contourCount equals: 2
]

{ #category : 'tests' }
TTCompositeGlyphTest >> testGlyphsEmptyAfterInitialize [

	self assert: TTCompositeGlyph new glyphs isEmpty
]

{ #category : 'tests' }
TTCompositeGlyphTest >> testIsComposite [

	self assert: TTCompositeGlyph new isComposite
]

{ #category : 'tests' }
TTCompositeGlyphTest >> testIsCompositeContrastWithTTGlyph [

	self deny: TTGlyph new isComposite
]

{ #category : 'tests' }
TTCompositeGlyphTest >> testReplaceIndexesByComponentGlyphs [
	"During parsing, glyphs are stored as integer indexes.
	replaceIndexesByComponentGlyphsIn: resolves them to real TTGlyph instances."

	| composite realGlyph glyphArray |
	realGlyph := TTGlyph new.
	glyphArray := Array new: 3.
	glyphArray at: 2 put: realGlyph.

	composite := TTCompositeGlyph new.
	composite addGlyph: 2 transformation: nil. "2 = index, not yet resolved"
	composite replaceIndexesByComponentGlyphsIn: glyphArray.

	self assert: composite glyphs size equals: 1.
	self assert: composite glyphs first identicalTo: realGlyph
]

{ #category : 'tests' }
TTCompositeGlyphTest >> testTxAndContoursDo [

	"Iterates transformation/contours pairs for each sub-glyph."

	| composite subGlyph txs contoursSeen |
	subGlyph := self makeGlyphWithNonEmptyContour.
	composite := TTCompositeGlyph new.
	composite addGlyph: subGlyph transformation: nil.

	txs := OrderedCollection new.
	contoursSeen := OrderedCollection new.
	composite txAndContoursDo: [ :tx :contours |
		txs add: tx.
		contoursSeen add: contours ].

	self assert: txs size equals: 1.
	self assert: txs first isNil.
	self assert: contoursSeen first equals: subGlyph contours
]
