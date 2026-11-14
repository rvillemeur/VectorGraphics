Extension { #name : 'VGScaledFont' }

{ #category : '*VectorGraphics-Bloc' }
VGScaledFont >> appendContour: aContour toAeContext: aContext [
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

{ #category : '*VectorGraphics-Bloc' }
VGScaledFont >> appendPathOfGlyphs: aGlyphArray length: aNumberOfGlyphs onAeContext: aContext [
	"The path site: cairo_glyph_path upstream, my own outlines here. A glyph is positioned in
	 user space and the contours go on in user space too, so the context's matrix takes part
	 when the path is filled or stroked, as it does for any other path the caller builds. The
	 mask route snaps a glyph to the device grid; this one must not, or a path stroked under a
	 matrix would carry pixels of the matrix in its shape."

	(self glyphsOf: aGlyphArray size: aNumberOfGlyphs) do: [ :glyph |
		(self userSpaceContoursOfGlyphAt: glyph index at: glyph x @ glyph y)
			do: [ :contour | self appendContour: contour toAeContext: aContext ] ]
]

{ #category : '*VectorGraphics-Bloc' }
VGScaledFont >> cairoMaskAssociations [
	"The masks of the route through real Cairo, as atlas key to mask associations, read through
	 the variable and not through #cairoMaskAtlas: that accessor builds the atlas on first use,
	 and asking what has been drawn must leave the font alone. Empty for a font no glyph has
	 been drawn through on this route."

	^ cairoMaskAtlas
		  ifNil: [ #(  ) ]
		  ifNotNil: [ :maskAtlas | maskAtlas masks associations asArray ]
]

{ #category : '*VectorGraphics-Bloc' }
VGScaledFont >> cairoMaskAtlas [
	"My rasterised glyphs for the route through real Cairo, built on the first glyph drawn that
	 way. It is a second atlas and not the one in `atlas`, because a mask is only usable by the
	 renderer that made it: these live in externally allocated A8 surfaces Cairo composites
	 from, those in surfaces of object memory our own rasteriser blits."

	^ cairoMaskAtlas ifNil: [ cairoMaskAtlas := VGGlyphAtlas new ]
]

{ #category : '*VectorGraphics-Bloc' }
VGScaledFont >> cairoMaskForGlyph: aGlyphIndex atPhase: aPhasePoint underMatrix: aLinearMatrix onAeContext: aContext [
	"One glyph rasterised by Cairo itself into an A8 surface of its own, with its origin at the
	 sub-pixel phase the atlas keyed on. The box is whole pixels, so blitting the mask at a
	 whole pixel offset keeps that phase. Nil for a glyph that inks nothing, a space for
	 instance. The contours are placed once and then moved to the box, because transforming the
	 outline is the work of a mask that misses the atlas."

	| contours box |
	contours := self
		            deviceContoursOfGlyphAt: aGlyphIndex
		            underMatrix: aLinearMatrix
		            at: aPhasePoint.
	contours ifEmpty: [ ^ nil ].
	box := self wholePixelBoxOfContours: contours.
	^ VGGlyphMask
		  surface: (self
				   cairoMaskSurfaceOfContours: (contours collect: [ :contour |
						    contour collect: [ :point | point - box origin ] ])
				   extent: box extent
				   onAeContext: aContext)
		  offset: box origin
]

{ #category : '*VectorGraphics-Bloc' }
VGScaledFont >> cairoMaskSurfaceOfContours: aContourCollection extent: anExtent onAeContext: aContext [
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
	aContourCollection do: [ :contour |
		self appendContour: contour toAeContext: maskContext ].
	maskContext fill.
	maskSurface flush.
	^ maskSurface
]

{ #category : '*VectorGraphics-Bloc' }
VGScaledFont >> contoursOfTheInspectorSample [
	"The contours the path route puts down for a short run, in user space, placed at the glyph
	 positions the layout chose. The view draws these and its gate counts them, so neither one
	 restates what the route does: both ask it."

	^ (self glyphArrayForString: 'Hamburg') flatCollect: [ :glyph |
		  self userSpaceContoursOfGlyphAt: glyph index at: glyph x @ glyph y ]
]

{ #category : '*VectorGraphics-Bloc' }
VGScaledFont >> extentTextOfCairoMask: anAssociation [
	"The extent of one row of the Cairo masks view, said in words where there is no mask."

	^ anAssociation value
		  ifNil: [ 'inks nothing' ]
		  ifNotNil: [ :mask | mask extent printString ]
]

{ #category : '*VectorGraphics-Bloc' }
VGScaledFont >> fontExtentsInto: aFontExtents onAeContext: aContext [
	"The font extents site: cairo_font_extents upstream, my own hhea numbers here. The numbers
	 are in user space, as Cairo answers them, so the context's matrix takes no part and the
	 argument is unused; it is kept because the five text sites dispatch the same way."

	^ self fontExtents writeInto: aFontExtents
]

{ #category : '*VectorGraphics-Bloc' }
VGScaledFont >> glyphExtentsOf: aGlyphArray size: aNumberOfGlyphs into: aTextExtents onAeContext: aContext [
	"The measuring site: cairo_glyph_extents upstream, my own metrics here. The numbers are in
	 user space, as Cairo answers them, so the context's matrix takes no part and the argument is
	 unused; it is kept because the five text sites dispatch the same way."

	^ (self glyphExtentsOf: (self glyphsOf: aGlyphArray size: aNumberOfGlyphs))
		  writeInto: aTextExtents
]

{ #category : '*VectorGraphics-Bloc' }
VGScaledFont >> glyphPathFormOfContours: aContourCollection [
	"A picture of a set of contours: Cairo strokes them thinly on white, so that the shape of
	 the outline shows and not the coverage a fill would lay down. The whole pixel box of the
	 contours decides the size of the image and the drawing is moved so that the box starts at
	 its corner. The poser is the one the path route uses, so the picture cannot drift from it."

	| box surface context |
	box := self wholePixelBoxOfContours: aContourCollection.
	surface := AeCairoImageSurface extent: box extent.
	context := AeCairoContext newFor: surface.
	context
		sourceColorR: 1.0 g: 1.0 b: 1.0 a: 1.0;
		paint;
		translateBy: box origin negated;
		sourceColorR: 0.0 g: 0.0 b: 0.0 a: 1.0;
		strokeSize: 1.
	aContourCollection do: [ :contour |
		self appendContour: contour toAeContext: context ].
	context stroke.
	surface flush.
	^ surface asForm
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

{ #category : '*VectorGraphics-Bloc' }
VGScaledFont >> inspectorCairoMasks: aBuilder [

	<inspectorPresentationOrder: 12 title: 'Cairo masks'>
	"One row per glyph of the atlas of the route through real Cairo, with the A8 mask Cairo
	 rasterised shown as it is: read back as a Form, the coverage reads as grey. The gate of
	 this view hides the tab for a font with no atlas, and the table is empty for a reader who
	 opens it all the same."

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

{ #category : '*VectorGraphics-Bloc' }
VGScaledFont >> inspectorCairoMasksContext: aContext [
	"Nothing to show before a glyph has been drawn through real Cairo: the atlas of that route is
	 built on the first such glyph."

	aContext active: cairoMaskAtlas notNil
]

{ #category : '*VectorGraphics-Bloc' }
VGScaledFont >> inspectorGlyphPath: aBuilder [
	<inspectorPresentationOrder: 13 title: 'Path'>
	"The other route of text, beside the masks: the outlines of a short run as the path site
	 appends them, in user space and with no snapping to the device grid. A stroke and not a
	 fill, because what the route delivers is a shape, and a filled letter would hide where its
	 contours run."

	^ aBuilder newImage image:
		  (self glyphPathFormOfContours: self contoursOfTheInspectorSample)
]

{ #category : '*VectorGraphics-Bloc' }
VGScaledFont >> inspectorGlyphPathContext: aContext [
	"Nothing to draw for a font whose face maps every letter of the sample to a glyph with no
	 contour: the run would lay down an empty path and the image would have no box."

	aContext active: self contoursOfTheInspectorSample notEmpty
]

{ #category : '*VectorGraphics-Bloc' }
VGScaledFont >> inspectorLineBox: aBuilder [
	<inspectorPresentationOrder: 14 title: 'Line box'>
	"Ascent, descent and line height are three numbers in the Metrics tab; here they are the
	 lines a backend stacks text between, drawn around a word of my own glyphs at my own size."

	^ aBuilder newImage
		  image: self lineBoxFormOfTheInspectorSample;
		  yourself
]

{ #category : '*VectorGraphics-Bloc' }
VGScaledFont >> inspectorLineBoxContext: aContext [
	"Nothing to draw for a font whose sample run inks no contour, so the tab stays shut on one."

	aContext active: self contoursOfTheInspectorSample notEmpty
]

{ #category : '*VectorGraphics-Bloc' }
VGScaledFont >> lineBoxFormOfTheInspectorSample [
	"A word of my own glyphs at my own size, with the lines a text backend lays it out with
	 drawn around it. The word is the contours the path site puts down, so the picture cannot
	 drift from the route, and the lines are asked of my own font extents, which places them."

	| extents contours margin baseline right surface context form |
	extents := self fontExtents.
	contours := self contoursOfTheInspectorSample.
	margin := 8.
	baseline := (margin @ (margin + extents ascent)) rounded.
	right := (contours inject: extents maxAdvanceX into: [ :widest :contour |
		          contour inject: widest into: [ :each :point | each max: point x ] ]).
	surface := AeCairoImageSurface extent:
		           ((margin * 2 + right)
			            @ (margin * 2 + extents ascent
				              + (extents descent max: extents height - extents ascent)))
			           ceiling.
	context := AeCairoContext newFor: surface.
	context
		sourceColorR: 1.0 g: 1.0 b: 1.0 a: 1.0;
		paint;
		translateBy: baseline;
		sourceColorR: 0.0 g: 0.0 b: 0.0 a: 1.0.
	contours do: [ :contour | self appendContour: contour toAeContext: context ].
	context fill.
	surface flush.
	form := surface asForm.
	extents drawLinesOn: form placing: [ :point | (point + baseline) rounded ].
	^ form
]

{ #category : '*VectorGraphics-Bloc' }
VGScaledFont >> maskFormOfCairoMask: anAssociation [
	"The mask of one row of the Cairo masks view, as a Form a table cell can draw. A glyph that
	 inks nothing is held in the atlas as nil, and one transparent pixel is what a row shows for
	 it."

	^ anAssociation value
		  ifNil: [ Form extent: 1 @ 1 depth: 32 ]
		  ifNotNil: [ :mask | mask surface asForm ]
]

{ #category : '*VectorGraphics-Bloc' }
VGScaledFont >> offsetTextOfCairoMask: anAssociation [
	"The offset of one row of the Cairo masks view, blank where there is no mask."

	^ anAssociation value
		  ifNil: [ '' ]
		  ifNotNil: [ :mask | mask offset printString ]
]

{ #category : '*VectorGraphics-Bloc' }
VGScaledFont >> poseOnAeContext: aContext [
	"Extensions in this project's Bloc package, because the engine's own package must name no
	 Alexandrie class: an A8 mask surface is one. Cairo is told nothing, since it has no handle
	 for me; the context remembers me and asks me for every text call that follows."

	^ aContext ownScaledFont: self
]

{ #category : '*VectorGraphics-Bloc' }
VGScaledFont >> showGlyphs: aGlyphsArray size: aNumberOfGlyphs onAeContext: aContext [
	"One A8 mask a glyph, composited by Cairo with whatever source the context carries, which is
	 how any other mask gets its colour. cairo_mask_surface places a mask in user space, so the
	 matrix is put aside: the device origin of a glyph is already in device pixels."

	| matrix linear |
	matrix := aContext matrix asVGCairoMatrix.
	linear := matrix copy
		          x: 0;
		          y: 0;
		          yourself.
	aContext saveState.
	aContext setIdentityMatrix.
	(self glyphsOf: aGlyphsArray size: aNumberOfGlyphs) do: [ :glyph |
		self
			showOneGlyph: glyph
			underMatrix: matrix
			linearPart: linear
			onAeContext: aContext ].
	aContext restoreState
]

{ #category : '*VectorGraphics-Bloc' }
VGScaledFont >> showOneGlyph: aGlyph underMatrix: aMatrix linearPart: aLinearMatrix onAeContext: aContext [
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
