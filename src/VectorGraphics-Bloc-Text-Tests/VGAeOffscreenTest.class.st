"
I hold the facts about `VGAeOffscreen`, the one by one canvas that measures text on the route
where Cairo draws and this project supplies only the fonts.

Bloc measures a paragraph during layout, before any window exists, so the measurement goes
through a singleton canvas. The facts are that the canvas is a `VGAeCanvas`, so a measurement
reads our own scaled fonts, and that this singleton is its own: neither Alexandrie's nor the one
of the all-ours route.
"
Class {
	#name : 'VGAeOffscreenTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Bloc-Text-Tests-Text',
	#package : 'VectorGraphics-Bloc-Text-Tests',
	#tag : 'Text'
}

{ #category : 'running' }
VGAeOffscreenTest >> tearDown [
	"The singletons are built by the tests, so they do not outlive them holding a surface. Both
	 of ours are reset, because the Measuring tab is read on each of them."

	VGAeOffscreen resetInstance.
	VGOffscreen resetInstance.
	super tearDown
]

{ #category : 'tests' }
VGAeOffscreenTest >> testEnsureReadyStaysDerivedFromUpstream [
	"My single override is Alexandrie's own method with the canvas class changed. Holding it
	 against the upstream source means an upstream change to how the measurer is built is noticed
	 here, and not in a layout that silently measures through the wrong fonts. The guard that
	 reinstalls our font manager is dropped before the comparison: it is a statement upstream has
	 no reason to hold, and the pin is about the rest of the method."

	| ours upstream |
	ours := ((VGAeOffscreen >> #ensureReady) sourceCode
		         copyReplaceAll: 'VGFontManager ensureUpstreamHoldsMine.'
		         with: '')
		        copyReplaceAll: 'VGAeCanvas extent:'
		        with: 'AeCanvas extent:'.
	upstream := (BAOffscreen >> #ensureReady) sourceCode.
	self
		assert: (RBParser parseMethod: ours) body
		equals: (RBParser parseMethod: upstream) body
]

{ #category : 'tests' }
VGAeOffscreenTest >> testMeasuringAParagraphGoesThroughThatCanvas [
	"Bloc measures a paragraph by sending `measureOn:` to it with the measurer, so the canvas the
	 measurer holds is the canvas the measurement would have read its fonts from."

	| paragraph |
	paragraph := VGTextParagraphStub new.
	VGAeOffscreen instance measureTextParagraph: paragraph.
	self assert: paragraph measurer canvas class equals: VGAeCanvas
]

{ #category : 'tests' }
VGAeOffscreenTest >> testTheMeasuringCanvasIsTheOneCairoDrawsWithOurFonts [
	"The canvas that measures has to be ours, or a paragraph would be laid out against fonts
	 read by Cairo's own FreeType while the frame it belongs to is drawn against ours."

	| offscreen |
	offscreen := VGAeOffscreen instance.
	self assert: offscreen canvas class equals: VGAeCanvas.
	self
		assert: (offscreen canvas instVarNamed: 'cairoContext') class
		equals: VGAeTextContext
]

{ #category : 'tests' }
VGAeOffscreenTest >> testTheMeasuringTabNamesTheCanvasOfEachRoute [
	"One Measuring tab serves every offscreen, ours and Alexandrie's, because it asks the object
	 which canvas it measures through rather than restating it. A reader opening either of ours
	 has to be told a different canvas."

	| builder |
	builder := SpPresenterBuilder newApplication: SpApplication new.
	{
		(VGAeOffscreen instance -> VGAeCanvas).
		(VGOffscreen instance -> VGCanvas) } do: [ :each |
		| presenter |
		each key canvas.
		presenter := (StInspectionContext new
			              inspectedObject: each key;
			              methodSelector: #inspectorMeasuring:;
			              yourself) basicNewInspectionPresenter: builder.
		self assert: presenter notNil.
		presenter columns do: [ :column |
			presenter items do: [ :item | column evaluation value: item ] ].
		self
			assert: (presenter items detect: [ :item | item key = 'Canvas' ]) value
			equals: each value ]
]

{ #category : 'tests' }
VGAeOffscreenTest >> testTheSingletonIsItsOwnAndNotTheOneOfTheOtherRoutes [
	"Each offscreen keeps its own singleton in a class instance variable, so the three routes
	 measure through three canvases. A shared one would make the route that ran first decide how
	 every other one measures."

	| offscreen |
	offscreen := VGAeOffscreen instance.
	self assert: offscreen identicalTo: VGAeOffscreen instance.
	self deny: offscreen identicalTo: VGOffscreen instance.
	self deny: offscreen identicalTo: BAOffscreen instance
]
