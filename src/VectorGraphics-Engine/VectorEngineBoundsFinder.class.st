"
I measure the area a drawing would cover, and paint nothing.

A VectorCanvas holds two engines: one that paints and me. `VectorCanvas >> updatingMorphBoundsDo:` swaps me in, runs the drawing commands, and puts the painting engine back; `VectorCanvas >> measuredMorphBounds` then answers the rectangle the drawing would have covered. Morphic uses this to learn a morph's damage rectangle without touching the display.

I walk every path exactly as my superclass does — the `prim…` methods, the hop counts and the arithmetic of `finishPath:` are inherited — so the bounds I answer are the bounds the painting engine reports for the same commands, not an estimate. What I override is only the writing: `updateAlphasForX:y:` writes no coverage, `updateEdgesAndBoundsForX:y:` keeps the blend box and counts no edge, `blendPath` runs no blend pass, and `pvtAllocateMorphIds` allocates nothing. I therefore own no buffer at all, where a painting engine of the same size owns three arrays of width times height.

The anti-aliasing width and the sub-pixel margin widen the box in `finishPath:`, and they differ between the whole-pixel and the sub-pixel engine. I take both from the engine I stand in for, through `mirror:`, so build me with `onForm:mirroring:` and rebuild me whenever the canvas replaces its painting engine.

I cannot answer `morph:isAtPoint:`: that reads the morph id map, which I never write.
"
Class {
	#name : 'VectorEngineBoundsFinder',
	#superclass : 'VectorEnginePixel',
	#instVars : [
		'horizontalExpansion'
	],
	#category : 'VectorGraphics-Engine-Kernel',
	#package : 'VectorGraphics-Engine',
	#tag : 'Kernel'
}

{ #category : 'instance creation' }
VectorEngineBoundsFinder class >> onForm: aForm mirroring: aVectorEngine [

	| finder |
	finder := self new.
	finder initializeOnForm: aForm.
	finder mirror: aVectorEngine.
	^ finder
]

{ #category : 'private - blend with mask' }
VectorEngineBoundsFinder >> blendHorizontalExpansion [

	^ horizontalExpansion
]

{ #category : 'private' }
VectorEngineBoundsFinder >> blendPath [

	"No blend pass: the morph bounds are already taken in #finishPath: before the blend
	box is clipped, which is all this engine is for."
]

{ #category : 'initialization' }
VectorEngineBoundsFinder >> initialize [

	"Whole-pixel margin, so a finder built without #mirror: still measures. #mirror:
	replaces it with the margin of the engine that paints."

	super initialize.
	horizontalExpansion := 0.0
]

{ #category : 'inspector' }
VectorEngineBoundsFinder >> inspectorAllocatedBufferNames [

	"Ask the slots a painting engine fills, so the view cannot drift from the overrides."

	^ (#( #alphaMask #edgeCounts ) select: [ :each |
		   (self instVarNamed: each) notNil ]) ifEmpty: [ #none ]
]

{ #category : 'inspector' }
VectorEngineBoundsFinder >> inspectorMeasuredBoxEntries [

	"One row per box: what a caller reads, what the walk covered after #finishPath: widened
	and clipped it, and the form that was measured but not painted."

	^ {
		  ('box measured' -> [ self morphBoundsAfterDraw ]) .
		  ('blend box, widened and clipped'
		   -> [ blendLeft @ blendTop corner: blendRight @ blendBottom ]) .
		  ('form measured' -> [ targetForm extent ]) .
		  ('pixels of that form no longer white'
		   -> [ self inspectorPixelsOtherThanWhiteIn: targetForm ]) }
]

{ #category : 'inspector' }
VectorEngineBoundsFinder >> inspectorMeasurement: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Measurement'>
	"What this engine measured and what it mirrored to measure it. Every row asks the live
	state, including the count of painted pixels, which says that measuring paints nothing.
	VectorCanvasExamples class >> boundsFinderAfterMeasuringATriangle answers one
	of these after a measured drawing."

	^ aBuilder newTable
		  addColumn:
			  ((SpStringTableColumn
				    title: 'Measurement'
				    evaluated: [ :each | each key ]) width: 280);
		  addColumn: (SpStringTableColumn
				   title: 'Now'
				   evaluated: [ :each | each value value printString ]);
		  items: self inspectorMeasurementEntries;
		  yourself
]

{ #category : 'inspector' }
VectorEngineBoundsFinder >> inspectorMeasurementEntries [

	^ self inspectorMeasuredBoxEntries
	  , self inspectorMirroredMarginEntries
]

{ #category : 'inspector' }
VectorEngineBoundsFinder >> inspectorMirroredMarginEntries [

	"The numbers taken from the engine that paints, the margin they produce, and the
	buffers this engine owns, asked of the slots rather than stated."

	^ {
		  ('anti-aliasing width mirrored' -> [ antiAliasingWidth ]) .
		  ('horizontal margin mirrored' -> [ self blendHorizontalExpansion ]) .
		  ('stroke width of the last path' -> [ strokeWidth ]) .
		  ('margin added to the box' -> [ auxStrokeWidthDilatedHalf ]) .
		  ('buffers allocated' -> [ self inspectorAllocatedBufferNames ]) }
]

{ #category : 'inspector' }
VectorEngineBoundsFinder >> inspectorPixelsOtherThanWhiteIn: aForm [

	^ aForm bits count: [ :each | each ~= (Color white pixelValueForDepth: 32) ]
]

{ #category : 'initialization' }
VectorEngineBoundsFinder >> mirror: aVectorEngine [

	"Both numbers widen the blend box in #finishPath:, and both differ between the
	whole-pixel and the sub-pixel engine, so take them from the engine that paints
	instead of this class's own defaults."

	self antiAliasingWidth: aVectorEngine antiAliasingWidth.
	horizontalExpansion := aVectorEngine blendHorizontalExpansion
]

{ #category : 'primitive algorithms - aux' }
VectorEngineBoundsFinder >> updateAlphasForX: x y: y [

	"No coverage buffer to write. The path still walks every hop, because the blend box
	the bounds come from is built hop by hop in #updateEdgesAndBoundsForX:y:."
]

{ #category : 'primitive algorithms - aux' }
VectorEngineBoundsFinder >> updateEdgesAndBoundsForX: x y: y [

	"The box only. Edge counts serve the non-zero winding rule of the fill pass, and no
	pass runs here."

	blendLeft := blendLeft min: x.
	blendTop := blendTop min: y.
	blendRight := blendRight max: x.
	blendBottom := blendBottom max: y
]
