Extension { #name : 'VGScaledFont' }

{ #category : '*VectorGraphics-Bloc' }
VGScaledFont >> appendContour: aContour toAeContext: aContext [
	"One contour, already in device space: the start point, then a control point and an end point
	 for every quadratic. A glyph contour is always closed."

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
	 rasterised shown as it is: read back as a Form, the coverage reads as grey.
	 The atlas is read through the variable and not through #cairoMaskAtlas, because that
	 accessor builds the atlas on first use and a view must leave the object it shows alone. A
	 font no glyph has been drawn through on this route has no atlas at all: the gate of this
	 view hides the tab, and the table is empty for a reader who opens it all the same."

	^ aBuilder newTable
		  items: (cairoMaskAtlas
				   ifNil: [ #(  ) ]
				   ifNotNil: [ :atlas | atlas masks associations asArray ]);
		  addColumn: (SpStringTableColumn
				   title: 'Glyph'
				   evaluated: [ :each | each key first printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Phase'
				   evaluated: [ :each | each key second printString ]);
		  addColumn: (SpImageTableColumn
				   title: 'Mask'
				   evaluated: [ :each |
					   each value
						   ifNil: [ Form extent: 1 @ 1 depth: 32 ]
						   ifNotNil: [ :mask | mask surface asForm ] ]);
		  addColumn: (SpStringTableColumn
				   title: 'Extent'
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

{ #category : '*VectorGraphics-Bloc' }
VGScaledFont >> inspectorCairoMasksContext: aContext [
	"Nothing to show before a glyph has been drawn through real Cairo: the atlas of that route is
	 built on the first such glyph."

	aContext active: cairoMaskAtlas notNil
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
	device := VGPathBuilder new snapped:
		          (aMatrix valueX: aGlyph x y: aGlyph y).
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
