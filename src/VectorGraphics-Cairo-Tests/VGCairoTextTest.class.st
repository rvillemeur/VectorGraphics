"
I gate unit 1.8: the font face, the scaled font, the glyph atlas and the text verbs of the context.

My fixture is the Source Sans Pro regular font that Alexandrie embeds, because it is a real glyf-based TrueType font that is present in any image with Alexandrie loaded and needs no file system. The engine itself reads the font file with the VectorGraphics TrueType parsers, so what I assert about a glyph is what the font says, and the metrics tests compare that with FreeType through Alexandrie.
"
Class {
	#name : 'VGCairoTextTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Cairo-Tests-Tests',
	#package : 'VectorGraphics-Cairo-Tests',
	#tag : 'Tests'
}

{ #category : 'fixture constants' }
VGCairoTextTest class >> cairoAdvanceOfTheFixtureRun [
	"The advance live Cairo reports for the fixture run ''Cairo A'' at size 30 with the metrics
	 unhinted. Two tests hold the font to it: the one that measures the run''s extents, and the one
	 that measures where #showText: leaves the current point."

	^ 88.62
]

{ #category : 'fixture constants' }
VGCairoTextTest class >> fixtureRun [
	"The string the measured text constants of this class were taken from."

	^ 'Cairo A'
]

{ #category : 'fixture constants' }
VGCairoTextTest class >> liveCairoMetricTolerance [
	"Our metrics are exact rationals read from the font tables and Cairo's are doubles, so a
	 comparison of the two has nothing between it but the width of a double."

	^ 1.0e-12
]

{ #category : 'fixture constants' }
VGCairoTextTest class >> oneStepOfTheFixedPointGrid [
	"One step of the 24.8 fixed point grid Cairo keeps path coordinates on, which is the largest
	 distance a coordinate can move by being stored in a path."

	^ 1 / 256
]

{ #category : 'helpers' }
VGCairoTextTest >> fixtureFontBytes [
	"Source Sans Pro regular, embedded in Alexandrie, as raw TrueType bytes. The test package
	 is allowed to name an Ae class; the engine is not, and never sees anything but the bytes."

	^ AeSourceSansPro_Regular fontContentsData
]

{ #category : 'helpers' }
VGCairoTextTest >> fixtureFontBytesWithTheTableTagsRenamed: aTag [
	"The fixture font with one table tag spelled differently, so the table directory no longer
	 holds it. It is how a font that carries its outlines in another format looks to me: the
	 directory is sound and the table I need is absent."

	| copy numberOfTables position |
	copy := self fixtureFontBytes copy.
	numberOfTables := copy shortAt: 5 bigEndian: true.
	position := 13.
	1 to: numberOfTables do: [ :index |
		| tag |
		tag := String new: 4.
		1 to: 4 do: [ :each | tag at: each put: (Character value: (copy byteAt: position + each - 1)) ].
		tag = aTag ifTrue: [
			1 to: 4 do: [ :each | copy byteAt: position + each - 1 put: $x asInteger ] ].
		position := position + 16 ].
	^ copy
]

{ #category : 'helpers' }
VGCairoTextTest >> fixtureFontFamilyName [
	"The family name the font manager registers my fixture font under."

	^ 'Source Sans Pro'
]

{ #category : 'helpers' }
VGCairoTextTest >> fixtureFreeTypeFace [
	"My fixture font as the font manager answers it: an AeFTFace, which carries a family name and
	 a style name and no bytes at all. A drawing picks its font this way, so this is what the
	 replacement is handed and has to resolve."

	| manager |
	manager := AeFontManager globalInstance.
	^ manager
		  detectFamilyName: self fixtureFontFamilyName
		  slant: AeFontSlant normal
		  weight: AeFontWeight normal
		  stretch: AeFontStretch normal
		  ifNone: [
			  manager scanEmbeddedFonts.
			  manager
				  detectFamilyName: self fixtureFontFamilyName
				  slant: AeFontSlant normal
				  weight: AeFontWeight normal
				  stretch: AeFontStretch normal
				  ifNone: [ nil ] ]
]

{ #category : 'helpers' }
VGCairoTextTest >> fixtureManagerEntryFor: anAeFTFace [
	"The entry the font manager holds for that face. It is the entry, and not the face, that
	 carries the bytes, which is why the replacement resolves a face through the manager."

	^ AeFontManager globalInstance faceEntries
		  detect: [ :each |
			  each familyName = anAeFTFace familyName and: [
				  each styleName = anAeFTFace styleName ] ]
		  ifNone: [ nil ]
]

{ #category : 'helpers' }
VGCairoTextTest >> fixtureScaledFontOfSize: aNumber hintMetrics: aSymbol [
	"The fixture font at one size, with hinting of the metrics on or off. The user to device
	 matrix is the identity, so user space and device space agree and a measured number is a
	 pixel count."

	^ VGScaledFont
		  fontFace: (VGFontFace newForBytes: self fixtureFontBytes)
		  fontMatrix: (VGCairoMatrix newScalingBy: aNumber asPoint)
		  userToDeviceMatrix: VGCairoMatrix newIdentity
		  options: (VGFontOptions new
				   hintMetrics: aSymbol;
				   yourself)
]

{ #category : 'fixture' }
VGCairoTextTest >> liveCairoScaledFontOfSize: aNumber [
	"The same font, size and options as #fixtureScaledFontOfSize:hintMetrics:, through Cairo and
	 FreeType themselves. The library and the face are held by the answered font, so the caller
	 needs no second reference. Alexandrie is named here because this is the test package; the
	 packages under test name none of it."

	| library options |
	library := AeFTLibrary newInitialized.
	options := AeCairoFontOptions new
		           hintStyle: AeCairoHintStyle none;
		           hintMetrics: AeCairoHintMetrics off;
		           yourself.
	^ AeCairoScaledFont
		  fontFace: (AeCairoFreetypeFontFace newForFace:
				   (library newFaceFromBytes: self fixtureFontBytes index: 0))
		  fontMatrix: (AeCairoMatrix newScalingBy: aNumber asPoint)
		  userToDeviceMatrix: AeCairoMatrix newIdentity
		  options: options
]

{ #category : 'running' }
VGCairoTextTest >> newSurface [
	^ VGCairoImageSurface extent: 64 @ 32
]

{ #category : 'running' }
VGCairoTextTest >> newTextSurface [
	"Wide enough for the fixture string at size 30, which advances eighty-nine pixels."

	^ VGCairoImageSurface extent: 128 @ 48
]

{ #category : 'tests' }
VGCairoTextTest >> testACompositeGlyphIsReadThroughItsComponentsAtTheirOffsets [
	"The letter i of this font is a composite glyph: a stem and a dot, each a glyph of its own and
	 each placed by an offset the composite carries. VectorGraphics' own TTGlyfTableParser reads
	 those offsets and throws them away, so the face reads a composite glyph itself. The box the
	 font stores for the glyph says where its ink really is, so the composed contours must fill
	 that box and no more."

	| face outline points |
	face := VGFontFace newForBytes: self fixtureFontBytes.
	outline := face outlineOfGlyphAt: (face glyphIndexForCodePoint: $i codePoint).
	self assert: outline contours size equals: 2.
	self assert: outline boundsRectangle equals: (69 @ 0 corner: 179 @ 694).
	points := outline contours flatCollect: [ :each | each ].
	self assert: (points collect: [ :each | each x ]) min equals: 69.
	self assert: (points collect: [ :each | each x ]) max equals: 179.
	self assert: (points collect: [ :each | each y ]) min equals: 0.
	self assert: (points collect: [ :each | each y ]) max equals: 694
]

{ #category : 'tests' }
VGCairoTextTest >> testAFaceAnswersTheScaledFontTheClassSideConstructorBuilds [
	"A drawing asks the face for a scaled font where this package asks the scaled font class for
	 one. Both spellings must build the same font, down to the run it measures."

	| face matrix identity options fromTheFace fromTheClass |
	face := VGFontFace newForBytes: self fixtureFontBytes.
	matrix := VGCairoMatrix newScalingBy: 30 asPoint.
	identity := VGCairoMatrix newIdentity.
	options := VGFontOptions new.
	fromTheFace := face
		               newScaledFontWithFontMatrix: matrix
		               userToDeviceMatrix: identity
		               options: options.
	fromTheClass := VGScaledFont
		                fontFace: face
		                fontMatrix: matrix
		                userToDeviceMatrix: identity
		                options: options.
	self assert: fromTheFace fontFace identicalTo: face.
	self assert: fromTheFace fontMatrix equals: matrix.
	self assert: fromTheFace options equals: options.
	self
		assert: (fromTheFace textExtentsOf: 'Cairo in Pharo') advance
		equals: (fromTheClass textExtentsOf: 'Cairo in Pharo') advance
]

{ #category : 'tests' }
VGCairoTextTest >> testAFaceBuiltFromAFreeTypeFaceReadsTheFontTheManagerHolds [
	"A drawing that picks its font by family name hands over an AeFTFace. The face of ours built
	 from it must read the bytes the manager registered under that family and style, because
	 otherwise the replacement draws the right shapes in the wrong typeface."

	| freetypeFace ours |
	freetypeFace := self fixtureFreeTypeFace.
	ours := VGFontFace newForFace: freetypeFace.
	self assert: ours bytes equals: (self fixtureManagerEntryFor: freetypeFace) bytes.
	self assert: ours glyphCount equals: freetypeFace numberOfGlyphs
]

{ #category : 'tests' }
VGCairoTextTest >> testAFaceParsesAGlyphOnceAndKeepsIt [
	"A page of text asks for the same few glyphs again and again, so a glyph is parsed once. The
	 same outline object comes back, and the face says how many it holds."

	| face first second |
	face := VGFontFace newForBytes: self fixtureFontBytes.
	self assert: face cachedGlyphCount equals: 0.
	first := face outlineOfGlyphAt: 2.
	second := face outlineOfGlyphAt: 2.
	self assert: first identicalTo: second.
	self assert: face cachedGlyphCount equals: 1.
	face outlineOfGlyphAt: 28.
	self assert: face cachedGlyphCount equals: 2
]

{ #category : 'tests' }
VGCairoTextTest >> testAFontFaceAnswersTheGlyphIndexOfACodePoint [
	"The index comes from the font's own character map, and a code point the font does not map
	 answers zero, which is the glyph every TrueType font keeps for exactly that."

	| face |
	face := VGFontFace newForBytes: self fixtureFontBytes.
	self assert: (face glyphIndexForCodePoint: $A codePoint) equals: 2.
	self assert: (face glyphIndexForCodePoint: $a codePoint) equals: 28.
	self assert: (face glyphIndexForCodePoint: Character space codePoint) equals: 1.
	self assert: (face glyphIndexForCodePoint: 16r2615) equals: 0.
	self assert: (face glyphIndexForCodePoint: 16r10FFFF) equals: 0
]

{ #category : 'tests' }
VGCairoTextTest >> testAFontFaceReadsItsOwnMetricsFromTheFontFile [
	"The face is built from the font's own bytes, so its metrics are the font's, in font units."

	| face |
	face := VGFontFace newForBytes: self fixtureFontBytes.
	self assert: face unitsPerEm equals: 1000.
	self assert: face glyphCount equals: 1972.
	self assert: face ascent equals: 984.
	self assert: face descent equals: -273.
	self assert: face lineGap equals: 0
]

{ #category : 'tests' }
VGCairoTextTest >> testAFontWithNoOutlineTableIsRefused [
	"A CFF OpenType font has no glyf table, and every glyph of it would be empty here, so the
	 face refuses the font instead of drawing a page of nothing."

	self
		should: [ VGFontFace newForBytes: (self fixtureFontBytesWithTheTableTagsRenamed: 'glyf') ]
		raise: Error
		description: 'a font with no glyf table must be refused'
]

{ #category : 'tests' }
VGCairoTextTest >> testAGlyphOutlineHoldsAbsoluteFontUnitPointsAndTheGlyphsAdvance [
	"An outline is the glyph as the font draws it: contours of quadratic segments in font units,
	 each contour a start point followed by control and end point pairs. A glyph with no contour,
	 a space, still carries its advance."

	| face outline contour space |
	face := VGFontFace newForBytes: self fixtureFontBytes.
	outline := face outlineOfGlyphAt: 2.
	self assert: outline advance equals: 544.
	self assert: outline boundsRectangle equals: (3 @ 0 corner: 541 @ 656).
	self assert: outline contours size equals: 2.
	contour := outline contours first.
	self assert: contour first equals: 203 @ 367.
	self assert: contour size odd.
	self assert: contour size equals: 17.
	space := face outlineOfGlyphAt: (face glyphIndexForCodePoint: Character space codePoint).
	self assert: space contours isEmpty.
	self assert: space advance equals: 200
]

{ #category : 'tests' }
VGCairoTextTest >> testAGlyphThatInksNothingIsLookedAtOnceAndRasterisedNever [
	"A space has no contour, so it has no mask. The atlas remembers that it has none, and the
	 count of rasterised glyphs does not move for it."

	| font index glyphs surface |
	font := self fixtureScaledFontOfSize: 30 hintMetrics: #off.
	index := font fontFace glyphIndexForCodePoint: Character space codePoint.
	glyphs := #( 0 20 ) collect: [ :x |
		          VGGlyph
			          index: index
			          x: x
			          y: 30 ].
	surface := self newTextSurface.
	surface newContext
		scaledFont: font;
		showGlyphs: glyphs.
	surface flush.
	self assert: font atlas renderedGlyphCount equals: 0.
	self assert: font atlas size equals: 1.
	self assert: surface data asArray asSet asArray equals: #( 0 )
]

{ #category : 'tests' }
VGCairoTextTest >> testAStringBecomesGlyphsLaidOutAtTheirOwnAdvances [
	"Unshaped layout: one glyph per code point, each one at the sum of the advances before it.
	 Measured on live Cairo, which answers the same seven indices and the same seven positions."

	| glyphs |
	glyphs := (self fixtureScaledFontOfSize: 30 hintMetrics: #off)
		          glyphArrayForString: 'Cairo A'.
	self
		assert: (glyphs collect: [ :each | each index ]) asArray
		equals: #( 4 28 36 45 42 1 2 ).
	self assert: (glyphs allSatisfy: [ :each | each y = 0 ]).
	(glyphs collect: [ :each | each x ]) asArray
		with: #( 0 17.13 32.25 39.63 50.04 66.3 72.3 )
		do: [ :measured :expected | self assert: measured closeTo: expected ]
]

{ #category : 'tests - default face' }
VGCairoTextTest >> testATextVerbWithNoFontDrawsThroughTheDefaultFace [
	"A text verb with no font selected draws, and draws exactly what selecting the default face
	 by hand draws. Ink is asserted too, so that a default face which resolved to nothing could
	 not pass the comparison by leaving both surfaces blank."

	| withNoFont withTheDefault |
	withNoFont := self newTextSurface.
	withNoFont newContext
		sourceColorR: 0.1 g: 0.1 b: 0.1;
		moveTo: 2 @ 20;
		showText: 'Hi'.
	withNoFont flush.
	withTheDefault := self newTextSurface.
	withTheDefault newContext
		scaledFont: withTheDefault newContext defaultScaledFont;
		sourceColorR: 0.1 g: 0.1 b: 0.1;
		moveTo: 2 @ 20;
		showText: 'Hi'.
	withTheDefault flush.
	self deny: (withNoFont data asArray allSatisfy: [ :each | each = 0 ]).
	self assert: withNoFont data asArray equals: withTheDefault data asArray
]

{ #category : 'tests' }
VGCairoTextTest >> testAnUnhintedFontExtentIsTheFontsOwnNumberScaledByTheFontMatrix [
	"With the metrics unhinted there is no rounding anywhere: an extent is the font's own value
	 over the em square, times the font matrix. Measured on live Cairo with the same font at the
	 same size, which answers 37.71, 29.52, 8.19 and 66.0."

	| extents |
	extents := (self fixtureScaledFontOfSize: 30 hintMetrics: #off) fontExtents.
	self assert: extents ascent closeTo: 29.52.
	self assert: extents descent closeTo: 8.19.
	self assert: extents height closeTo: 37.71.
	self assert: extents maxAdvanceX closeTo: 66.0.
	self assert: extents maxAdvanceY equals: 0
]

{ #category : 'tests' }
VGCairoTextTest >> testAppendingTheGlyphsPathAddsOneClosedSubPathPerContour [
	"cairo_glyph_path adds closed subpaths for the glyphs to the path being built and draws
	 nothing. The letter A of this font has two contours, the outside and the counter, and the
	 path is in device space, so the box it covers is the inked box of the glyph moved to where
	 the glyph was placed."

	| context font path box |
	context := self newSurface newContext.
	font := self fixtureScaledFontOfSize: 30 hintMetrics: #off.
	context
		scaledFont: font;
		translateBy: 10 @ 25;
		appendGlyphsPath: (font glyphArrayForString: 'A').
	path := context pathBuilder path.
	self assert: path subPaths size equals: 2.
	self assert: (path subPaths allSatisfy: [ :each | each isClosed ]).
	box := path boundingBox.
	self assert: box left closeTo: 10.09 precision: 0.01.
	self assert: box top closeTo: 5.32 precision: 0.01.
	self assert: box right closeTo: 26.23 precision: 0.01.
	self assert: box bottom closeTo: 25.0 precision: 0.01.
	self assert: context surface displayList isEmpty
]

{ #category : 'tests' }
VGCairoTextTest >> testEveryCairoFontEnumerationAnswersTheNamesTheOptionsKnow [
	"The enumeration classes and VGFontOptions may not drift apart, so each class is asked for a
	 value under every name its option knows, and is allowed no value beyond them. #names is the
	 one class-side selector that is not a value, because it is where the names come from."

	{
		{ VGCairoAntialias. VGFontOptions antialiasNames }.
		{ VGCairoHintMetrics. VGFontOptions hintMetricsNames }.
		{ VGCairoHintStyle. VGFontOptions hintStyleNames }.
		{ VGCairoSubpixelOrder. VGFontOptions subpixelOrderNames } } do: [ :each |
		| enumeration names |
		enumeration := each first.
		names := each second.
		self assert: (names collect: [ :name | enumeration perform: name ]) equals: names.
		self
			assert: (enumeration class selectors reject: [ :selector | selector = #names ]) asSet
			equals: names asSet ]
]

{ #category : 'tests' }
VGCairoTextTest >> testHintedMetricsAreRoundedTheWayFreetypeRoundsThem [
	"FreeType rounds the ascent and the descent up, and the height and the maximum advance to the
	 nearest pixel. Measured on live Cairo with the metrics hinted: at size 30 it answers 30, 9, 38
	 and 66, and at size 16 it answers 16, 5, 20 and 35."

	| atThirty atSixteen |
	atThirty := (self fixtureScaledFontOfSize: 30 hintMetrics: #on) fontExtents.
	self assert: atThirty ascent equals: 30.
	self assert: atThirty descent equals: 9.
	self assert: atThirty height equals: 38.
	atSixteen := (self fixtureScaledFontOfSize: 16 hintMetrics: #on) fontExtents.
	self assert: atSixteen ascent equals: 16.
	self assert: atSixteen descent equals: 5.
	self assert: atSixteen height equals: 20
]

{ #category : 'tests' }
VGCairoTextTest >> testOptionsBuiltFromCairosEnumerationsEqualOursBuiltFromOurOwnNames [
	"A drawing names Cairo's enumerations where this package names symbols, so the four
	 enumeration classes have to be two spellings of one option rather than two options."

	| throughEnumerations throughNames |
	throughEnumerations := VGFontOptions new
		                       antialias: VGCairoAntialias fast;
		                       hintMetrics: VGCairoHintMetrics on;
		                       hintStyle: VGCairoHintStyle slight;
		                       subpixelOrder: VGCairoSubpixelOrder default;
		                       yourself.
	throughNames := VGFontOptions new
		                antialias: #fast;
		                hintMetrics: #on;
		                hintStyle: #slight;
		                subpixelOrder: #default;
		                yourself.
	self assert: throughEnumerations equals: throughNames
]

{ #category : 'tests' }
VGCairoTextTest >> testShowingTextDrawsFromTheCurrentPointAndLeavesItAfterTheRun [
	"cairo_show_text lays a string out with no shaping, draws it from the current point, and
	 leaves the current point where the next glyph would start. It is Cairo's toy API over
	 cairo_show_glyphs, so it must draw exactly what that verb draws for the same run placed at
	 the same point. The new current point is a path coordinate, so it is held on the 24.8 grid
	 and is read back a fraction of a pixel away from the exact advance; the precision allows
	 that one step of the grid."

	| font throughText context throughGlyphs origin |
	font := self fixtureScaledFontOfSize: 30 hintMetrics: #off.
	origin := 2 @ 33.
	throughText := self newTextSurface.
	context := throughText newContext.
	context
		scaledFont: font;
		sourceColorR: 0.1 g: 0.1 b: 0.1;
		moveTo: origin;
		showText: 'Cairo A'.
	throughText flush.
	self
		assert: context currentPointInUserSpace x
		closeTo: origin x + self class cairoAdvanceOfTheFixtureRun
		precision: self class oneStepOfTheFixedPointGrid.
	self assert: context currentPointInUserSpace y closeTo: origin y.
	throughGlyphs := self newTextSurface.
	throughGlyphs newContext
		scaledFont: font;
		sourceColorR: 0.1 g: 0.1 b: 0.1;
		showGlyphs: ((font glyphArrayForString: 'Cairo A') collect: [ :glyph |
					 VGGlyph
						 index: glyph index
						 x: glyph x + origin x
						 y: glyph y + origin y ]).
	throughGlyphs flush.
	self assert: throughText data asArray equals: throughGlyphs data asArray
]

{ #category : 'tests' }
VGCairoTextTest >> testTheAtlasRasterisesOneGlyphOnceHoweverOftenItIsDrawn [
	"The second half of the gate: the atlas is built once for a repeated draw. The three glyphs
	 sit on whole pixels, so all three share one phase and one mask, and drawing the run again,
	 a whole pixel to the right, rasterises nothing new: the key holds the matrix without its
	 translation."

	| font index glyphs surface context |
	font := self fixtureScaledFontOfSize: 30 hintMetrics: #off.
	index := font fontFace glyphIndexForCodePoint: $a codePoint.
	glyphs := #( 0 20 40 ) collect: [ :x |
		          VGGlyph
			          index: index
			          x: x
			          y: 30 ].
	surface := self newTextSurface.
	context := surface newContext.
	context
		scaledFont: font;
		showGlyphs: glyphs.
	self assert: font atlas renderedGlyphCount equals: 1.
	context
		translateBy: 1 @ 0;
		showGlyphs: glyphs.
	self assert: font atlas renderedGlyphCount equals: 1.
	self assert: font atlas size equals: 1
]

{ #category : 'tests' }
VGCairoTextTest >> testTheAtlasRouteAndThePathRouteDrawTheSameBytes [
	"The gate of unit 1.8. A run drawn with #showGlyphs:, which blits one cached mask per glyph,
	 must lay down the same bytes as the same run filled as a path. Both routes place a glyph on
	 the same snapped device point and hand the same coverage to the same compositing, so the two
	 surfaces agree byte for byte and not merely closely."

	| font glyphs throughAtlas throughPath |
	font := self fixtureScaledFontOfSize: 30 hintMetrics: #off.
	glyphs := font glyphArrayForString: 'Cairo A'.
	throughAtlas := self newTextSurface.
	throughAtlas newContext
		scaledFont: font;
		translateBy: 2.5 @ 33.25;
		sourceColorR: 0.0 g: 0.2 b: 0.9;
		showGlyphs: glyphs.
	throughAtlas flush.
	throughPath := self newTextSurface.
	throughPath newContext
		scaledFont: font;
		translateBy: 2.5 @ 33.25;
		sourceColorR: 0.0 g: 0.2 b: 0.9;
		appendGlyphsPath: glyphs;
		fill.
	throughPath flush.
	self deny: throughPath data asArray asSet asArray equals: #( 0 ).
	self assert: throughAtlas data asArray equals: throughPath data asArray
]

{ #category : 'tests' }
VGCairoTextTest >> testTheContextAnswersTheFontExtentsOfTheScaledFontItWasGiven [
	"cairo_set_scaled_font replaces the face, the font matrix and the options of the context in
	 one go, and cairo_font_extents then answers that font's own numbers."

	| context extents |
	context := self newSurface newContext.
	context scaledFont: (self fixtureScaledFontOfSize: 30 hintMetrics: #off).
	extents := context fontExtents.
	self assert: extents ascent closeTo: 29.52.
	self assert: extents descent closeTo: 8.19.
	self assert: extents height closeTo: 37.71
]

{ #category : 'tests' }
VGCairoTextTest >> testTheContextFillsTheTextExtentsRecordItIsGiven [
	"AeCanvas owns the record and hands it over to be filled, so the context writes into it
	 through the record's own setters and answers nothing of its own. The record here is
	 Alexandrie's, which is the one the real caller passes, so this also gates the duck typing
	 that lets our records stand in for Cairo's."

	| context font glyphs record |
	context := self newSurface newContext.
	font := self fixtureScaledFontOfSize: 30 hintMetrics: #off.
	context scaledFont: font.
	glyphs := font glyphArrayForString: 'A'.
	record := AeCairoTextExtents new.
	context getGlyphExtentsOf: glyphs size: glyphs size into: record.
	self assert: record width closeTo: 16.14.
	self assert: record height closeTo: 19.68.
	self assert: record bearingX closeTo: 0.09.
	self assert: record bearingY closeTo: -19.68.
	self assert: record advanceX closeTo: 16.32.
	self assert: record advanceY closeTo: 0
]

{ #category : 'tests - default face' }
VGCairoTextTest >> testTheDefaultFaceIsReadOnceAndKept [
	"The bundled font is nearly three hundred kilobytes of tables, and a text verb with no font
	 is the slowest path there is if every send parses them again. The face is therefore read
	 once and kept, which also means two default scaled fonts share one glyph cache."

	| first second |
	VGFontFace resetDefault.
	first := VGFontFace default.
	second := VGFontFace default.
	self assert: first identicalTo: second.
	VGFontFace resetDefault.
	self deny: VGFontFace default identicalTo: first.
	self assert: VGFontFace default bytes equals: first bytes
]

{ #category : 'tests - default face' }
VGCairoTextTest >> testTheDefaultScaledFontIsPharosOwnBundledFaceAtCairosDefaultSize [
	"Cairo draws with a toy default face when the caller selected none, and resolves that face
	 through fontconfig, which this replacement does not have. The face has to come from
	 somewhere that is always there, so it is the sans family Pharo itself embeds, at Cairo's own
	 default font size, with the font options a context starts with."

	| context font |
	context := self newSurface newContext.
	font := context defaultScaledFont.
	self assert: font fontFace bytes equals: VGFontFace defaultBytes.
	self
		assert: font fontMatrix
		equals: (VGCairoMatrix newScalingBy: VGCairoContext defaultFontSize asPoint).
	self assert: font options equals: VGFontOptions new
]

{ #category : 'tests' }
VGCairoTextTest >> testTheExtentsOfARunAreTheInkedBoxOfItsGlyphs [
	"The extent is the union of the inked boxes, the bearing says where that union sits relative
	 to the origin of the run, and the advance is where the next run would start. Measured on live
	 Cairo for the same string at the same size with the metrics unhinted."

	| extents |
	extents := (self fixtureScaledFontOfSize: 30 hintMetrics: #off)
		           textExtentsOf: 'Cairo A'.
	self assert: extents width closeTo: 86.97.
	self assert: extents height closeTo: 21.18.
	self assert: extents bearingX closeTo: 1.56.
	self assert: extents bearingY closeTo: -20.82.
	self assert: extents advanceX closeTo: self class cairoAdvanceOfTheFixtureRun.
	self assert: extents advanceY closeTo: 0
]

{ #category : 'tests' }
VGCairoTextTest >> testTheExtentsOfOneGlyphAreThatGlyphsOwnBoxScaled [
	"One glyph measured on its own: the box the font stores for it, scaled by the font matrix, with
	 y pointing down. Measured on live Cairo for the letter A at size 30."

	| font extents |
	font := self fixtureScaledFontOfSize: 30 hintMetrics: #off.
	extents := font glyphExtentsOf: (font glyphArrayForString: 'A').
	self assert: extents width closeTo: 16.14.
	self assert: extents height closeTo: 19.68.
	self assert: extents bearingX closeTo: 0.09.
	self assert: extents bearingY closeTo: -19.68.
	self assert: extents advanceX closeTo: 16.32.
	self assert: extents advanceY closeTo: 0
]

{ #category : 'tests' }
VGCairoTextTest >> testTheFontSizeReplacesTheFontMatrixAndKeepsTheFace [
	"cairo_set_font_size replaces the font matrix with a scale, and leaves the face and the
	 options alone, so the extents are the same face's numbers at the new size: 984 over the em
	 square of 1000, at 16."

	| context |
	context := self newSurface newContext.
	context scaledFont: (self fixtureScaledFontOfSize: 30 hintMetrics: #off).
	context fontSize: 16.
	self assert: context fontExtents ascent closeTo: 15.744.
	self assert: (context scaledFont textExtentsOf: 'A') advanceX closeTo: 8.704
]

{ #category : 'tests' }
VGCairoTextTest >> testTheGlyphsOfAStringMatchLiveCairoAndFreeType [
	"The other measured half of the metrics gate: the same string, through our own cmap and hmtx
	 tables and through FreeType, must answer the same glyph indices at the same positions."

	| theirs ours theirGlyphs ourGlyphs |
	theirs := self liveCairoScaledFontOfSize: 30.
	ours := self fixtureScaledFontOfSize: 30 hintMetrics: #off.
	theirGlyphs := (theirs glyphArrayForString: self class fixtureRun) asExternalStructure.
	ourGlyphs := ours glyphArrayForString: self class fixtureRun.
	self assert: ourGlyphs size equals: self class fixtureRun size.
	ourGlyphs doWithIndex: [ :each :position |
		| theirGlyph |
		theirGlyph := theirGlyphs at: position.
		self assert: each index equals: theirGlyph index.
		self
			assert: each x
			closeTo: theirGlyph x
			precision: self class liveCairoMetricTolerance.
		self
			assert: each y
			closeTo: theirGlyph y
			precision: self class liveCairoMetricTolerance ]
]

{ #category : 'tests' }
VGCairoTextTest >> testTheUnhintedMetricsMatchLiveCairoAndFreeType [
	"The metrics half of the gate of unit 1.8, measured rather than frozen: the same font at the
	 same size, through our own TrueType tables and through FreeType, must answer the same font
	 extents and the same run extents. Our numbers are exact rationals read from the tables and
	 Cairo's are doubles, so only the width of a double separates them. Hinted metrics are left
	 out on purpose: Cairo's hinted advances come from a FreeType face shared with whatever else
	 in the image last set its size, so they are not reproducible from outside."

	| theirs ours theirExtents ourExtents |
	theirs := self liveCairoScaledFontOfSize: 30.
	ours := self fixtureScaledFontOfSize: 30 hintMetrics: #off.
	theirExtents := theirs fontExtents.
	ourExtents := ours fontExtents.
	#( #ascent #descent #height #maxAdvanceX #maxAdvanceY ) do: [ :each |
		self
			assert: (ourExtents perform: each)
			closeTo: (theirExtents perform: each)
			precision: self class liveCairoMetricTolerance ].
	theirExtents := theirs textExtentsOf: self class fixtureRun.
	ourExtents := ours textExtentsOf: self class fixtureRun.
	#( #width #height #bearingX #bearingY #advanceX #advanceY ) do: [ :each |
		self
			assert: (ourExtents perform: each)
			closeTo: (theirExtents perform: each)
			precision: self class liveCairoMetricTolerance ]
]
