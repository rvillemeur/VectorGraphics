Extension { #name : 'TTGlyph' }

{ #category : '*VectorGraphics-Text' }
TTGlyph >> inspectorGlyph: aBuilder [
	<inspectorPresentationOrder: 30 title: 'Glyph'>
	"The glyph as the engine really draws it: a VectorCanvas fills it through
	drawGlyphOn:geometryTransformation: with no transformation, so the picture is in font units.
	TrueType counts y upwards and the form counts it downwards, so the form is flipped afterwards
	rather than the points being moved — this view must not change the glyph it shows.
	Bridges VectorGraphics-TrueType, which defines TTGlyph, and VectorGraphics-Engine, which
	defines VectorCanvas: the view draws the glyph with the engine, so it belongs to neither
	package and lives in VectorGraphics-Text. TTGlyph loaded alone keeps its other tabs."

	| extent form canvas |
	extent := self inspectorPointExtent.
	(extent x > 0 and: [ extent y > 0 ]) ifFalse: [
		^ aBuilder newText
			  text: 'This glyph has no point to draw';
			  beNotEditable;
			  yourself ].
	form := Form extent: extent depth: 32.
	form fillColor: Color white.
	canvas := VectorCanvas onForm: form.
	canvas fillColor: Color black do: [
		self drawGlyphOn: canvas geometryTransformation: nil ].
	^ aBuilder newImage
		  image: ((form flipBy: #vertical centerAt: form center) scaledToSize: 240 @ 240);
		  yourself
]
