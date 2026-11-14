"
I answer an Alexandrie context for one of our scaled fonts.

A `VGScaledFont` is the font model: a face, a font matrix, a user to device matrix, the options, and the metrics and outlines it reads from them. An `AeCairoContext` knows nothing of it and has no `cairo_scaled_font_t` to ask about it, so Alexandrie's five text verbs — pose, show a run, measure a run, append the path of a run, answer the font extents — cannot reach Cairo with one of ours. I implement those five for the font that holds me, which is how `VGAeTextContext` draws text with no FreeType face anywhere: it poses me, then sends me each verb in turn.

I keep the A8 masks Cairo rasterised for the glyphs drawn through me, in an atlas of my own. It is not the atlas in the font's `atlas`: a mask is only usable by the renderer that made it, and mine live in externally allocated surfaces Cairo composites from. A font answers one and the same adapter every time, through `#aeTextFont`, so the masks a run warms are there for the run after it.

My subject keeps no Alexandrie knowledge of its own: `#aeTextFont` is the one selector of this package the font model answers.
"
Class {
	#name : 'VGAeTextFont',
	#superclass : 'Object',
	#instVars : [
		'scaledFont',
		'cairoMaskAtlas'
	],
	#category : 'VectorGraphics-Bloc-Text',
	#package : 'VectorGraphics-Bloc',
	#tag : 'Text'
}

{ #category : 'instance creation' }
VGAeTextFont class >> on: aScaledFont [
	"The adapter of one scaled font. The font never changes afterwards, and a font builds me
	 once and keeps me, because the masks I rasterise are worth keeping."

	^ self new setScaledFont: aScaledFont
]

{ #category : 'private' }
VGAeTextFont >> appendContour: aContour toAeContext: aContext [
	"One contour, already placed, in whichever space the caller chose: device space for the
	 mask of a glyph, user space for the path of a run. The points are the start point, then a
	 control point and an end point for every quadratic. A glyph contour is always closed."

	| current |
	current := aContour first.
	aContext moveTo: current.
	2 to: aContour size by: 2 do: [ :index |
		| via to |
		via := aContour at: index.
		to := aContour at: index + 1.
		aContext quadraticCurveFromCurrentPoint: current via: via to: to.
		current := to ].
	aContext closePath
]

{ #category : 'private' }
VGAeTextFont >> appendContours: aContourCollection toAeContext: aContext [
	"Every contour of a set, appended in the order they came. The set is a glyph's outline, or
	 the outlines of a whole run already placed; either way each contour closes on its own."

	aContourCollection do: [ :contour |
		self appendContour: contour toAeContext: aContext ]
]

{ #category : 'text sites' }
VGAeTextFont >> appendPathOfGlyphs: aGlyphArray length: aNumberOfGlyphs onAeContext: aContext [
	"The path site: cairo_glyph_path upstream, the font's own outlines here. A glyph is
	 positioned in user space and the contours go on in user space too, so the context's matrix
	 takes part when the path is filled or stroked, as it does for any other path the caller
	 builds. The mask route snaps a glyph to the device grid; this one must not, or a path
	 stroked under a matrix would carry pixels of the matrix in its shape."

	(scaledFont glyphsOf: aGlyphArray size: aNumberOfGlyphs) do: [ :glyph |
		self
			appendContours: (scaledFont
					 userSpaceContoursOfGlyphAt: glyph index
					 at: glyph x @ glyph y)
			toAeContext: aContext ]
]

{ #category : 'masks' }
VGAeTextFont >> cairoMaskAssociations [
	"My masks, as atlas key to mask associations, read through the variable and not through
	 #cairoMaskAtlas: that accessor builds the atlas on first use, and asking what has been
	 drawn must leave me alone. Empty while no glyph has been drawn through me."

	^ cairoMaskAtlas
		  ifNil: [ #(  ) ]
		  ifNotNil: [ :maskAtlas | maskAtlas masks associations asArray ]
]

{ #category : 'masks' }
VGAeTextFont >> cairoMaskAtlas [
	"The glyphs Cairo rasterised for my font, built on the first glyph drawn this way. It is a
	 second atlas and not the one in the font's `atlas`, because a mask is only usable by the
	 renderer that made it: these live in externally allocated A8 surfaces Cairo composites
	 from, those in surfaces of object memory our own rasteriser blits."

	^ cairoMaskAtlas ifNil: [ cairoMaskAtlas := VGGlyphAtlas new ]
]

{ #category : 'masks' }
VGAeTextFont >> cairoMaskForGlyph: aGlyphIndex atPhase: aPhasePoint underMatrix: aLinearMatrix onAeContext: aContext [
	"One glyph rasterised by Cairo itself into an A8 surface of its own, with its origin at the
	 sub-pixel phase the atlas keyed on. The box is whole pixels, so blitting the mask at a
	 whole pixel offset keeps that phase. Nil for a glyph that inks nothing, a space for
	 instance. The contours are placed once and then moved to the box, because transforming the
	 outline is the work of a mask that misses the atlas."

	| contours box |
	contours := scaledFont
		            deviceContoursOfGlyphAt: aGlyphIndex
		            underMatrix: aLinearMatrix
		            at: aPhasePoint.
	contours ifEmpty: [ ^ nil ].
	box := scaledFont wholePixelBoxOfContours: contours.
	^ VGGlyphMask
		  surface: (self
				   cairoMaskSurfaceOfContours: (contours collect: [ :contour |
						    contour collect: [ :point | point - box origin ] ])
				   extent: box extent
				   onAeContext: aContext)
		  offset: box origin
]

{ #category : 'masks' }
VGAeTextFont >> cairoMaskSurfaceOfContours: aContourCollection extent: anExtent onAeContext: aContext [
	"An A8 surface of its own holding the coverage Cairo rasterises for a set of device space
	 contours, which are placed for this surface already.

	 The surface is externally allocated, which is what the mask has to be: Cairo keeps the
	 address of the pixels while it composites them, and the garbage collector may move a
	 ByteArray. Alpha is the coverage and nothing else, so the mask is filled with opaque white,
	 with the winding rule a glyph outline is drawn with and the antialiasing the drawing
	 context asks for."

	| maskSurface maskContext |
	maskSurface := AeCairoImageSurface
		               extent: anExtent
		               format: AeCairoSurfaceFormat a8.
	maskContext := AeCairoContext newFor: maskSurface.
	maskContext
		antialias: aContext antialias;
		useFillRuleWinding;
		sourceColorR: 1.0 g: 1.0 b: 1.0 a: 1.0.
	self appendContours: aContourCollection toAeContext: maskContext.
	maskContext fill.
	maskSurface flush.
	^ maskSurface
]

{ #category : 'inspector' }
VGAeTextFont >> contoursOfTheInspectorSample [
	"The contours the path route puts down for a short run, in user space, placed at the glyph
	 positions the layout chose. The view draws these and its gate counts them, so neither one
	 restates what the route does: both ask it."

	^ (scaledFont glyphArrayForString: 'Hamburg') flatCollect: [ :glyph |
		  scaledFont userSpaceContoursOfGlyphAt: glyph index at: glyph x @ glyph y ]
]

{ #category : 'inspector' }
VGAeTextFont >> extentTextOfCairoMask: anAssociation [
	"The extent of one row of the Cairo masks view, said in words where there is no mask."

	^ anAssociation value
		  ifNil: [ 'inks nothing' ]
		  ifNotNil: [ :mask | mask extent printString ]
]

{ #category : 'text sites' }
VGAeTextFont >> fontExtentsInto: aFontExtents onAeContext: aContext [
	"The font extents site: cairo_font_extents upstream, the font's own hhea numbers here. The
	 numbers are in user space, as Cairo answers them, so the context's matrix takes no part and
	 the argument is unused; it is kept because the five text sites dispatch the same way."

	^ scaledFont fontExtents writeInto: aFontExtents
]

{ #category : 'text sites' }
VGAeTextFont >> glyphExtentsOf: aGlyphArray size: aNumberOfGlyphs into: aTextExtents onAeContext: aContext [
	"The measuring site: cairo_glyph_extents upstream, the font's own metrics here. The numbers
	 are in user space, as Cairo answers them, so the context's matrix takes no part and the
	 argument is unused; it is kept because the five text sites dispatch the same way."

	^ (scaledFont glyphExtentsOf:
		   (scaledFont glyphsOf: aGlyphArray size: aNumberOfGlyphs))
		  writeInto: aTextExtents
]

{ #category : 'inspector' }
VGAeTextFont >> glyphPathFormOfContours: aContourCollection [
	"A picture of a set of contours: Cairo strokes them thinly on white, so that the shape of
	 the outline shows and not the coverage a fill would lay down. The whole pixel box of the
	 contours decides the size of the image and the drawing is moved so that the box starts at
	 its corner. The poser is the one the path route uses, so the picture cannot drift from it."

	| box surface context |
	box := scaledFont wholePixelBoxOfContours: aContourCollection.
	surface := AeCairoImageSurface extent: box extent.
	context := AeCairoContext newFor: surface.
	context
		sourceColorR: 1.0 g: 1.0 b: 1.0 a: 1.0;
		paint;
		translateBy: box origin negated;
		sourceColorR: 0.0 g: 0.0 b: 0.0 a: 1.0;
		strokeSize: 1.
	self appendContours: aContourCollection toAeContext: context.
	context stroke.
	surface flush.
	^ surface asForm
]

{ #category : 'inspector' }
VGAeTextFont >> inspectorCairoMasks: aBuilder [
	<inspectorPresentationOrder: 1 title: 'Cairo masks'>
	"One row per glyph of my atlas, with the A8 mask Cairo rasterised shown as it is: read back
	 as a Form, the coverage reads as grey. The gate of this view hides the tab while no glyph
	 has been drawn through me, and the table is empty for a reader who opens it all the same."

	^ aBuilder newTable
		  items: self cairoMaskAssociations;
		  addColumn: (SpStringTableColumn
				   title: 'Glyph'
				   evaluated: [ :each | each key first printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Phase'
				   evaluated: [ :each | each key second printString ]);
		  addColumn: (SpImageTableColumn
				   title: 'Mask'
				   evaluated: [ :each | self maskFormOfCairoMask: each ]);
		  addColumn: (SpStringTableColumn
				   title: 'Extent'
				   evaluated: [ :each | self extentTextOfCairoMask: each ]);
		  addColumn: (SpStringTableColumn
				   title: 'Offset'
				   evaluated: [ :each | self offsetTextOfCairoMask: each ]);
		  yourself
]

{ #category : 'inspector' }
VGAeTextFont >> inspectorCairoMasksContext: aContext [
	"Nothing to show before a glyph has been drawn through me: my atlas is built on the first
	 such glyph."

	aContext active: cairoMaskAtlas notNil
]

{ #category : 'inspector' }
VGAeTextFont >> inspectorGlyphPath: aBuilder [
	<inspectorPresentationOrder: 2 title: 'Path'>
	"The other route of text, beside the masks: the outlines of a short run as the path site
	 appends them, in user space and with no snapping to the device grid. A stroke and not a
	 fill, because what the route delivers is a shape, and a filled letter would hide where its
	 contours run."

	^ aBuilder newImage image:
		  (self glyphPathFormOfContours: self contoursOfTheInspectorSample)
]

{ #category : 'inspector' }
VGAeTextFont >> inspectorGlyphPathContext: aContext [
	"Nothing to draw for a font whose face maps every letter of the sample to a glyph with no
	 contour: the run would lay down an empty path and the image would have no box."

	aContext active: self contoursOfTheInspectorSample notEmpty
]

{ #category : 'inspector' }
VGAeTextFont >> inspectorLineBox: aBuilder [
	<inspectorPresentationOrder: 3 title: 'Line box'>
	"Ascent, descent and line height are three numbers in the font's Metrics tab; here they are
	 the lines a backend stacks text between, drawn around a word of its glyphs at its size."

	^ aBuilder newImage
		  image: self lineBoxFormOfTheInspectorSample;
		  yourself
]

{ #category : 'inspector' }
VGAeTextFont >> inspectorLineBoxContext: aContext [
	"Nothing to draw for a font whose sample run inks no contour, so the tab stays shut on one."

	aContext active: self contoursOfTheInspectorSample notEmpty
]

{ #category : 'inspector' }
VGAeTextFont >> inspectorLineBoxMargin [
	"The white space the line box picture keeps around the run, in pixels, so that the lines
	 the extents place are visible on every side of it."

	^ 8
]

{ #category : 'inspector' }
VGAeTextFont >> lineBoxExtentOfTheInspectorSample [
	"The size of the line box picture: the sample run plus a margin on each side, and tall
	 enough for everything the extents place — the ascent above the baseline, the descent
	 below it, and the line height where it reaches further than the descent. The width is
	 asked of the real box of the contours rather than measured again here, and never less
	 than one advance, so a run that inks nothing still has a box to draw the lines in."

	| extents margin |
	extents := scaledFont fontExtents.
	margin := self inspectorLineBoxMargin.
	^ ((margin * 2
	    + ((scaledFont wholePixelBoxOfContours: self contoursOfTheInspectorSample) right
		     max: extents maxAdvanceX))
	   @ (margin * 2 + extents ascent
		    + (extents descent max: extents height - extents ascent))) ceiling
]

{ #category : 'inspector' }
VGAeTextFont >> lineBoxFormOfTheInspectorSample [
	"A word of my font's glyphs at its size, with the lines a text backend lays it out with
	 drawn around it. The word is the contours the path site puts down, so the picture cannot
	 drift from the route, and the lines are asked of the font's own extents, which places them."

	| margin baseline surface context form extents |
	extents := scaledFont fontExtents.
	margin := self inspectorLineBoxMargin.
	baseline := (margin @ (margin + extents ascent)) rounded.
	surface := AeCairoImageSurface extent: self lineBoxExtentOfTheInspectorSample.
	context := AeCairoContext newFor: surface.
	context
		sourceColorR: 1.0 g: 1.0 b: 1.0 a: 1.0;
		paint;
		translateBy: baseline;
		sourceColorR: 0.0 g: 0.0 b: 0.0 a: 1.0.
	self appendContours: self contoursOfTheInspectorSample toAeContext: context.
	context fill.
	surface flush.
	form := surface asForm.
	extents drawLinesOn: form placing: [ :point | (point + baseline) rounded ].
	^ form
]

{ #category : 'inspector' }
VGAeTextFont >> maskFormOfCairoMask: anAssociation [
	"The mask of one row of the Cairo masks view, as a Form a table cell can draw. A glyph that
	 inks nothing is held in the atlas as nil, and one transparent pixel is what a row shows for
	 it."

	^ anAssociation value
		  ifNil: [ Form extent: 1 @ 1 depth: 32 ]
		  ifNotNil: [ :mask | mask surface asForm ]
]

{ #category : 'inspector' }
VGAeTextFont >> offsetTextOfCairoMask: anAssociation [
	"The offset of one row of the Cairo masks view, blank where there is no mask."

	^ anAssociation value
		  ifNil: [ '' ]
		  ifNotNil: [ :mask | mask offset printString ]
]

{ #category : 'text sites' }
VGAeTextFont >> poseOnAeContext: aContext [
	"Cairo is told nothing, since it has no handle for my font; the context remembers me and
	 asks me for every text call that follows."

	^ aContext ownTextFont: self
]

{ #category : 'accessing' }
VGAeTextFont >> scaledFont [
	"The font model I answer for."

	^ scaledFont
]

{ #category : 'initialization' }
VGAeTextFont >> setScaledFont: aScaledFont [
	"My subject, set once at build time."

	scaledFont := aScaledFont
]

{ #category : 'text sites' }
VGAeTextFont >> showGlyphs: aGlyphsArray size: aNumberOfGlyphs onAeContext: aContext [
	"One A8 mask a glyph, composited by Cairo with whatever source the context carries, which is
	 how any other mask gets its colour. cairo_mask_surface places a mask in user space, so the
	 matrix is put aside: the device origin of a glyph is already in device pixels."

	| matrix linear |
	matrix := aContext matrix asVGCairoMatrix.
	linear := matrix linearPart.
	aContext saveState.
	aContext setIdentityMatrix.
	(scaledFont glyphsOf: aGlyphsArray size: aNumberOfGlyphs) do: [ :glyph |
		self
			showOneGlyph: glyph
			underMatrix: matrix
			linearPart: linear
			onAeContext: aContext ].
	aContext restoreState
]

{ #category : 'masks' }
VGAeTextFont >> showOneGlyph: aGlyph underMatrix: aMatrix linearPart: aLinearMatrix onAeContext: aContext [
	"One glyph blitted through its mask. The origin is snapped to Cairo's grid first, then split
	 into the whole pixels the blit carries and the phase the mask is rendered at, so the mask of
	 a letter is shared by every place that letter sits on a whole pixel."

	| device whole phase mask |
	device := VGPathBuilder snapped: (aMatrix valueX: aGlyph x y: aGlyph y).
	whole := device floor.
	phase := device - whole.
	mask := self cairoMaskAtlas
		        maskForGlyph: aGlyph index
		        phase: phase
		        matrix: aLinearMatrix
		        ifAbsentPut: [
		        self
			        cairoMaskForGlyph: aGlyph index
			        atPhase: phase
			        underMatrix: aLinearMatrix
			        onAeContext: aContext ].
	mask ifNil: [ ^ self ].
	aContext
		maskSurface: mask surface
		x: (whole + mask offset) x
		y: (whole + mask offset) y
]
