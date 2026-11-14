Extension { #name : 'VGScaledFont' }

{ #category : '*VectorGraphics-Bloc' }
VGScaledFont >> aeTextFont [
	"My adapter for the Alexandrie route, built on first use and kept: it holds the masks Cairo
	 rasterised for my glyphs, and each context of a frame poses me again. This is the one
	 selector of that package I answer; the five text verbs are the adapter's."

	^ aeTextFont ifNil: [ aeTextFont := VGAeTextFont on: self ]
]

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
