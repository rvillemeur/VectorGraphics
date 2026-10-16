Class {
	#name : 'VectorEngineAbstractTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Tests',
	#package : 'VectorGraphics',
	#tag : 'Tests'
}

{ #category : 'helpers' }
VectorEngineAbstractTest >> engineOnSmallForm [

	^ VectorEngineWholePixel onForm: (Form extent: 50 @ 50 depth: 32)
]

{ #category : 'fixtures' }
VectorEngineAbstractTest >> fixtureEmBox [
	"The em box the fixture glyphs are built in. displayUtf8:at:trueTypeFont:color:scaleX:scaleY:
	 divides by the M glyph's top side bearing, so it must not be zero."

	^ 1000
]

{ #category : 'fixtures' }
VectorEngineAbstractTest >> fixturePointSize [
	"A point size that puts the fixture glyph's em box inside the 50 by 50 fixture form."

	^ 28
]

{ #category : 'fixtures' }
VectorEngineAbstractTest >> formAfterDrawingUtf8: aByteArray [
	"Answer the form left by drawing aByteArray through a sparse font description, at a
	 baseline and a scale that put a fixture glyph inside the form."

	| form engine |
	form := Form extent: 50 @ 50 depth: 32.
	form fillColor: Color white.
	engine := VectorEngineWholePixel onForm: form.
	engine
		displayUtf8: aByteArray
		at: 5 @ 45
		trueTypeFont: self sparseFontDescription
		color: Color black
		scaleX: 1.0 * self fixturePointSize
		scaleY: -1.0 * self fixturePointSize.
	^ form
]

{ #category : 'fixtures' }
VectorEngineAbstractTest >> glyphWithTriangleContour [
	"A glyph with one straight-sided contour, so that drawing it paints pixels a test can
	 compare. points: leaves every control point flag clear, which makes each segment a
	 straight line rather than a Bezier."

	| points contour glyph |
	points := Int16PointArray new: 3.
	points at: 1 putX: 0.
	points at: 1 putY: 0.
	points at: 2 putX: 600.
	points at: 2 putY: 0.
	points at: 3 putX: 300.
	points at: 3 putY: 700.
	contour := TTContourConstruction new.
	contour points: points.
	glyph := TTGlyph new.
	glyph contours: (Array with: contour).
	glyph advanceWidth: 700.
	glyph
		boundsLeft: 0
		boundsRight: 600
		boundsTop: 0
		boundsBottom: self fixtureEmBox.
	^ glyph
]

{ #category : 'fixtures' }
VectorEngineAbstractTest >> paintedPixelCountIn: aForm [
	"How many pixels of aForm the drawing changed, the fixture form starting out white."

	| count |
	count := 0.
	0 to: aForm height - 1 do: [ :y |
		0 to: aForm width - 1 do: [ :x |
			(aForm colorAt: x @ y) = Color white ifFalse: [ count := count + 1 ] ] ].
	^ count
]

{ #category : 'fixtures' }
VectorEngineAbstractTest >> sparseFontDescription [
	"A description built the way a font that maps few code points builds one: a slot for $M,
	 which is where letterMTopSideBearing is read from, and nothing else. Every other code
	 point has to reach the unknown glyph through the index table's fallback."

	| glyphsByUtf8 unknown description |
	unknown := self glyphWithTriangleContour.
	glyphsByUtf8 := Array new: 256.
	glyphsByUtf8 at: $M codePoint + 1 put: self glyphWithTriangleContour.
	description := TTFontDescription new.
	description glyphsByUtf8Bytes: glyphsByUtf8 unknownGlyph: unknown.
	^ description
]

{ #category : 'tests - text' }
VectorEngineAbstractTest >> testAByteWithNoIndexEntryDrawsTheUnknownGlyph [
	"A font that maps few code points leaves most slots of the index table empty, and nothing
	 stops a string from naming one of them. The draw loop must read the unknown glyph's data
	 there rather than index the flattened data at zero."

	self
		assert: (self paintedPixelCountIn: (self formAfterDrawingUtf8: #[ 65 ])) > 0
		description: 'a byte with no index entry should paint the unknown glyph'
]

{ #category : 'tests - text' }
VectorEngineAbstractTest >> testAnUnmappedMultiByteCharacterDrawsOneUnknownGlyph [
	"U+4E2D is three UTF-8 bytes. With no index entry for its lead byte there is no table to
	 descend, so the continuation bytes must be skipped rather than read as characters of
	 their own: one unmapped character is one unknown glyph, exactly as a single unmapped byte
	 is."

	self
		assert: (self formAfterDrawingUtf8: #[ 16rE4 16rB8 16rAD ]) bits
		equals: (self formAfterDrawingUtf8: #[ 65 ]) bits
]

{ #category : 'tests' }
VectorEngineAbstractTest >> testClosePathRestoresFirstPoint [

	| engine capturedX capturedY |
	engine := self engineOnSmallForm.
	engine strokeWidth: 2.0 color: Color black do: [
		engine abs_MoveTo: 10 @ 20.
		engine abs_LineTo: 40 @ 45.
		engine do_ClosePath.
		capturedX := engine instVarNamed: 'previousCallX'.
		capturedY := engine instVarNamed: 'previousCallY' ].
	self assert: capturedX equals: 10.
	self assert: capturedY equals: 20
]

{ #category : 'tests' }
VectorEngineAbstractTest >> testInitializePathResetsState [

	| engine pathFirstX pathFirstY pathCurrentX pathCurrentY prevX prevY |
	engine := self engineOnSmallForm.
	engine strokeWidth: 2.0 color: Color black do: [
		engine abs_MoveTo: 33 @ 44.
		engine initializePath.
		pathFirstX := engine instVarNamed: 'pathFirstX'.
		pathFirstY := engine instVarNamed: 'pathFirstY'.
		pathCurrentX := engine instVarNamed: 'pathCurrentX'.
		pathCurrentY := engine instVarNamed: 'pathCurrentY'.
		prevX := engine instVarNamed: 'previousCallX'.
		prevY := engine instVarNamed: 'previousCallY' ].
	self assert: pathFirstX equals: 0.
	self assert: pathFirstY equals: 0.
	self assert: pathCurrentX equals: 0.0.
	self assert: pathCurrentY equals: 0.0.
	self assert: prevX equals: 0.0.
	self assert: prevY equals: 0.0
]

{ #category : 'tests' }
VectorEngineAbstractTest >> testLineToUpdatesCurrentPoint [

	| engine capturedX capturedY |
	engine := self engineOnSmallForm.
	engine strokeWidth: 2.0 color: Color black do: [
		engine abs_MoveTo: 5 @ 5.
		engine abs_LineTo: 40 @ 30.
		capturedX := engine instVarNamed: 'pathCurrentX'.
		capturedY := engine instVarNamed: 'pathCurrentY' ].
	self assert: capturedX equals: 40.
	self assert: capturedY equals: 30
]

{ #category : 'tests' }
VectorEngineAbstractTest >> testMoveToSetsAllPathState [

	| engine pathFirstX pathFirstY pathCurrentX pathCurrentY prevX prevY |
	engine := self engineOnSmallForm.
	engine strokeWidth: 2.0 color: Color black do: [
		engine abs_MoveTo: 10 @ 20.
		pathFirstX := engine instVarNamed: 'pathFirstX'.
		pathFirstY := engine instVarNamed: 'pathFirstY'.
		pathCurrentX := engine instVarNamed: 'pathCurrentX'.
		pathCurrentY := engine instVarNamed: 'pathCurrentY'.
		prevX := engine instVarNamed: 'previousCallX'.
		prevY := engine instVarNamed: 'previousCallY' ].
	self assert: pathFirstX equals: 10.
	self assert: pathFirstY equals: 20.
	self assert: pathCurrentX equals: 10.
	self assert: pathCurrentY equals: 20.
	self assert: prevX equals: 10.
	self assert: prevY equals: 20
]

{ #category : 'tests' }
VectorEngineAbstractTest >> testMultipleMoveToUpdatesFirstPoint [

	| engine capturedFirstX capturedFirstY |
	engine := self engineOnSmallForm.
	engine strokeWidth: 2.0 color: Color black do: [
		engine abs_MoveTo: 10 @ 20.
		engine abs_LineTo: 30 @ 30.
		engine abs_MoveTo: 45 @ 48.
		capturedFirstX := engine instVarNamed: 'pathFirstX'.
		capturedFirstY := engine instVarNamed: 'pathFirstY' ].
	self assert: capturedFirstX equals: 45.
	self assert: capturedFirstY equals: 48
]

{ #category : 'tests' }
VectorEngineAbstractTest >> testRelativeLineAddsToCurrentPoint [

	| engine capturedX capturedY |
	engine := self engineOnSmallForm.
	engine strokeWidth: 2.0 color: Color black do: [
		engine abs_MoveTo: 10 @ 10.
		engine rel_LineTo: 20 @ 15.
		capturedX := engine instVarNamed: 'pathCurrentX'.
		capturedY := engine instVarNamed: 'pathCurrentY' ].
	self assert: capturedX equals: 30.
	self assert: capturedY equals: 25
]
