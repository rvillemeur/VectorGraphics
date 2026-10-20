"
I am one font face at one size, under one transformation, with one set of options: what Cairo calls a cairo_scaled_font_t. I am immutable once built, which is what lets a context cache me and lets the glyph atlas key on me.

My font matrix takes the em square to user space, and my user to device matrix is the context's transformation at the moment I was built. Their product is the matrix a glyph outline passes through, so a scaled font knows the device size of its glyphs without asking the context again.

I answer the metrics Cairo answers: `fontExtents` for the vertical geometry of the face, `textExtentsOf:` and `glyphExtentsOf:` for a run, and `glyphArrayForString:` for the unshaped glyph array of a string. I cache the user space outline of each glyph I am asked for, so a repeated draw transforms nothing twice.

With the metrics unhinted my numbers are exactly the font's own values scaled by my matrix. With them hinted I round the way FreeType rounds: the ascent and the descent up, the height and the maximum advance to the nearest whole pixel.
"
Class {
	#name : 'VGScaledFont',
	#superclass : 'Object',
	#instVars : [
		'fontFace',
		'fontMatrix',
		'userToDeviceMatrix',
		'options',
		'fontExtents',
		'outlines',
		'atlas'
	],
	#category : 'VectorGraphics-Cairo-Text',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Text'
}

{ #category : 'instance creation' }
VGScaledFont class >> fontFace: aFontFace fontMatrix: aFontMatrix userToDeviceMatrix: aUserToDeviceMatrix options: aFontOptions [
	"The four things Cairo asks for when it scales a font. None of them changes afterwards."

	^ self new
		  setFontFace: aFontFace
		  fontMatrix: aFontMatrix
		  userToDeviceMatrix: aUserToDeviceMatrix
		  options: aFontOptions
]

{ #category : 'constants' }
VGScaledFont class >> sampleRun [
	"The string the Run view lays out: two letters that ink, a space that does not, and a letter
	 that is composite in many fonts."

	^ 'Hi a'
]

{ #category : 'accessing' }
VGScaledFont >> atlas [
	"The rasterised glyphs of this font. It lives here because a caller keeps one scaled font for
	 a whole page of text, so this is the object whose lifetime a glyph cache wants."

	^ atlas
]

{ #category : 'private' }
VGScaledFont >> computeFontExtents [
	"The face's own hhea numbers over the em square, through my font matrix. Unhinted, that is the
	 answer; hinted, FreeType rounds the ascent and the descent up and the height and the maximum
	 advance to the nearest pixel, and Cairo passes those numbers on unchanged.

	 The rounding happens here in user space. That is Cairo's own answer whenever the user to
	 device matrix is a translation or the identity, which is the case this gate measures; under a
	 scaled transformation FreeType rounds device pixels instead, and we do not follow it there."

	| upem ascentDistance descentDistance heightDistance maxAdvance hinted |
	upem := fontFace unitsPerEm.
	ascentDistance := (self distanceX: 0 y: fontFace ascent / upem) y.
	descentDistance := (self distanceX: 0 y: fontFace descent negated / upem) y.
	heightDistance := (self
		                   distanceX: 0
		                   y: fontFace ascent - fontFace descent + fontFace lineGap / upem) y.
	maxAdvance := self distanceX: fontFace maxAdvanceWidth / upem y: 0.
	hinted := options hintsMetrics.
	^ VGFontExtents new
		  ascent: (hinted ifTrue: [ ascentDistance ceiling ] ifFalse: [ ascentDistance ]);
		  descent: (hinted ifTrue: [ descentDistance ceiling ] ifFalse: [ descentDistance ]);
		  height: (hinted ifTrue: [ heightDistance rounded ] ifFalse: [ heightDistance ]);
		  maxAdvanceX: (hinted ifTrue: [ maxAdvance x rounded ] ifFalse: [ maxAdvance x ]);
		  maxAdvanceY: (hinted ifTrue: [ maxAdvance y rounded ] ifFalse: [ maxAdvance y ]);
		  yourself
]

{ #category : 'private' }
VGScaledFont >> computeUserSpaceContoursOfGlyphAt: aGlyphIndex [
	"Font coordinates grow upwards over an em square of unitsPerEm; user space grows downwards
	 over a square the font matrix decides. So the y of a font point is negated and both
	 coordinates go through the matrix as a distance, with no translation."

	| upem |
	upem := fontFace unitsPerEm.
	^ (fontFace outlineOfGlyphAt: aGlyphIndex) contours collect: [ :contour |
		  contour collect: [ :point |
			  self distanceX: point x / upem y: point y negated / upem ] ]
]

{ #category : 'private' }
VGScaledFont >> distanceX: aNumber y: anotherNumber [
	"A distance in em units through my font matrix. A distance is not a point: the matrix's
	 translation does not move it, which is why this does not send #valueX:y:."

	^ fontMatrix sx * aNumber + (fontMatrix shx * anotherNumber)
	  @ (fontMatrix shy * aNumber + (fontMatrix sy * anotherNumber))
]

{ #category : 'metrics' }
VGScaledFont >> emptyTextExtents [
	^ VGTextExtents new
		  bearingX: 0;
		  bearingY: 0;
		  width: 0;
		  height: 0;
		  advanceX: 0;
		  advanceY: 0;
		  yourself
]

{ #category : 'metrics' }
VGScaledFont >> fontExtents [
	"The vertical geometry of my face, in user space. I am immutable, so one computation serves
	 every caller."

	^ fontExtents ifNil: [ fontExtents := self computeFontExtents ]
]

{ #category : 'accessing' }
VGScaledFont >> fontFace [
	^ fontFace
]

{ #category : 'accessing' }
VGScaledFont >> fontMatrix [
	^ fontMatrix
]

{ #category : 'metrics' }
VGScaledFont >> glyphAdvanceOf: aGlyphIndex [
	"How far the pen moves after one glyph, in user space.

	 Hinted, Cairo answers the advance FreeType last computed for the shared face, which depends on
	 the pixel size that face was loaded at and so is not reproducible from the font alone. We
	 round the linear advance instead, which is what FreeType itself does for a face loaded at our
	 own size."

	| advance |
	advance := self
		           distanceX: (fontFace outlineOfGlyphAt: aGlyphIndex) advance
			           / fontFace unitsPerEm
		           y: 0.
	^ options hintsMetrics
		  ifTrue: [ advance x rounded @ advance y rounded ]
		  ifFalse: [ advance ]
]

{ #category : 'layout' }
VGScaledFont >> glyphArrayForString: aString [
	"Unshaped layout, the way cairo_scaled_font_text_to_glyphs lays a string out: one glyph for
	 every code point, each one at the sum of the advances before it, no kerning and no
	 substitution. A caller that wants shaping runs HarfBuzz first and hands me glyphs."

	| pen |
	pen := 0 @ 0.
	^ (1 to: aString size) collect: [ :position |
		  | index glyph |
		  index := fontFace glyphIndexForCodePoint: (aString at: position) codePoint.
		  glyph := VGGlyph index: index x: pen x y: pen y.
		  pen := pen + (self glyphAdvanceOf: index).
		  glyph ]
]

{ #category : 'metrics' }
VGScaledFont >> glyphExtentsOf: aGlyphCollection [
	"The geometry of a laid out run, the way cairo_scaled_font_glyph_extents answers it: the inked
	 box of the glyphs, relative to the origin of the first one, and the advance from the first
	 origin to where the next run would start. A run that inks nothing is all zeroes, which is
	 also Cairo's answer."

	| box origin last advance |
	aGlyphCollection ifEmpty: [ ^ self emptyTextExtents ].
	box := nil.
	aGlyphCollection do: [ :glyph |
		(self inkedBoxOfGlyphAt: glyph index) ifNotNil: [ :glyphBox |
			| placed |
			placed := glyphBox translateBy: glyph position.
			box := box
				       ifNil: [ placed ]
				       ifNotNil: [ box merge: placed ] ] ].
	box ifNil: [ ^ self emptyTextExtents ].
	origin := aGlyphCollection first position.
	last := aGlyphCollection last.
	advance := last position + (self glyphAdvanceOf: last index) - origin.
	^ VGTextExtents new
		  bearingX: box left - origin x;
		  bearingY: box top - origin y;
		  width: box width;
		  height: box height;
		  advanceX: advance x;
		  advanceY: advance y;
		  yourself
]

{ #category : 'metrics' }
VGScaledFont >> inkedBoxOfGlyphAt: aGlyphIndex [
	"The box the font stores for one glyph, in user space, with its origin at the glyph's origin.
	 Nil for a glyph that inks nothing, a space for instance, so that it cannot widen the box of a
	 run.

	 Font coordinates grow upwards and user space grows downwards, so the y of a font point is
	 negated before the font matrix sees it. All four corners go through the matrix, because a
	 sheared matrix does not map the corners of a box to the corners of a box."

	| outline bounds upem corners xs ys |
	outline := fontFace outlineOfGlyphAt: aGlyphIndex.
	outline isEmpty ifTrue: [ ^ nil ].
	bounds := outline boundsRectangle.
	upem := fontFace unitsPerEm.
	corners := {
		           bounds origin.
		           bounds topRight.
		           bounds bottomLeft.
		           bounds corner } collect: [ :each |
		           self distanceX: each x / upem y: each y negated / upem ].
	xs := corners collect: [ :each | each x ].
	ys := corners collect: [ :each | each y ].
	^ xs min @ ys min corner: xs max @ ys max
]

{ #category : 'inspector' }
VGScaledFont >> inspectorMetrics: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Metrics'>
	"The metrics a caller lays text out with, each asked of the real method. The font options are
	 shown beside them because the hinted and the unhinted answers differ, and the one in force
	 is the one the options name."

	| extents |
	extents := self fontExtents.
	^ aBuilder newTable
		  items: {
				  ('Ascent' -> extents ascent).
				  ('Descent' -> extents descent).
				  ('Height' -> extents height).
				  ('Maximum advance' -> extents maxAdvance).
				  ('Font matrix' -> self fontMatrix).
				  ('User to device matrix' -> self userToDeviceMatrix).
				  ('Hint style' -> self options hintStyle).
				  ('Hint metrics' -> self options hintMetrics).
				  ('Antialias' -> self options antialias).
				  ('Rounds its metrics' -> self options hintsMetrics) };
		  addColumn: (SpStringTableColumn title: 'Property' evaluated: [ :each | each key ]);
		  addColumn: (SpStringTableColumn
				   title: 'Value'
				   evaluated: [ :each | each value printString ]);
		  yourself
]

{ #category : 'inspector' }
VGScaledFont >> inspectorMetricsContext: aContext [
	aContext active: self fontFace notNil
]

{ #category : 'inspector' }
VGScaledFont >> inspectorRun: aBuilder [
	<inspectorPresentationOrder: 11 title: 'Run'>
	"A sample string laid out by this font: where each glyph sits, what it advances by and the box
	 it inks. The layout is the real one, so the pen positions here are the positions a draw uses.
	 Reading a glyph fills the face's outline memo; no view shows that memo, so opening this one
	 changes nothing any view reports."

	^ aBuilder newTable
		  items: (self glyphArrayForString: self class sampleRun);
		  addColumn: (SpStringTableColumn
				   title: 'Glyph'
				   evaluated: [ :each | each index printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Position'
				   evaluated: [ :each | each position printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Advance'
				   evaluated: [ :each | (self glyphAdvanceOf: each index) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Inked box'
				   evaluated: [ :each |
					   (self inkedBoxOfGlyphAt: each index)
						   ifNil: [ 'inks nothing' ]
						   ifNotNil: [ :box | box printString ] ]);
		  yourself
]

{ #category : 'inspector' }
VGScaledFont >> inspectorRunContext: aContext [
	aContext active: self fontFace notNil
]

{ #category : 'accessing' }
VGScaledFont >> options [
	^ options
]

{ #category : 'printing' }
VGScaledFont >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPutAll: '(';
		print: fontFace;
		nextPutAll: ' through ';
		print: fontMatrix;
		nextPut: $)
]

{ #category : 'initialization' }
VGScaledFont >> setFontFace: aFontFace fontMatrix: aFontMatrix userToDeviceMatrix: aUserToDeviceMatrix options: aFontOptions [
	fontFace := aFontFace.
	fontMatrix := aFontMatrix.
	userToDeviceMatrix := aUserToDeviceMatrix.
	options := aFontOptions.
	outlines := Dictionary new.
	atlas := VGGlyphAtlas new
]

{ #category : 'metrics' }
VGScaledFont >> textExtentsOf: aString [
	"The geometry of a string laid out without shaping."

	^ self glyphExtentsOf: (self glyphArrayForString: aString)
]

{ #category : 'outlines' }
VGScaledFont >> userSpaceContoursOfGlyphAt: aGlyphIndex [
	"The contours of one glyph in user space, cached, so a repeated draw transforms nothing
	 twice. Each contour is an odd-sized array of points: the start point, then a control point
	 and an end point for every quadratic."

	^ outlines
		  at: aGlyphIndex
		  ifAbsentPut: [ self computeUserSpaceContoursOfGlyphAt: aGlyphIndex ]
]

{ #category : 'accessing' }
VGScaledFont >> userToDeviceMatrix [
	^ userToDeviceMatrix
]
