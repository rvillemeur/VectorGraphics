"
I hold the facts about `VGAeRenderer`, the host renderer of the route where Cairo rasterises
every figure and this project supplies only the fonts.

Two kinds of fact live here. First the wiring: the renderer is one Bloc can choose, it names
itself apart from Alexandrie's, and the canvas and the text measurer it builds are the ones of
this route. Second the gate of unit 5.1: a real headless space holding a text element is opened,
drawn and settled, and the frame that reaches the pixels was drawn through Cairo with scaled
fonts of ours — no FreeType face is built for it, which is the whole point of the route.
"
Class {
	#name : 'VGAeRendererTest',
	#superclass : 'TestCase',
	#instVars : [
		'previousRendererClass',
		'previousFontManager'
	],
	#category : 'VectorGraphics-Bloc-Tests-Text',
	#package : 'VectorGraphics-Bloc-Tests',
	#tag : 'Text'
}

{ #category : 'private' }
VGAeRendererTest >> cachedFacesAndSizesOf: aCanvas [
	"The scaled fonts a canvas built, as face -> size, ordered by size. They are read from the
	 cache because a span resolves its scaled font while it is being measured, and the frame
	 canvas is then handed the font that measuring built."

	^ ((aCanvas instVarNamed: 'scaledFontCache') keys collect: [ :each |
		   each first -> each second ]) asArray sort: [ :a :b | a value < b value ]
]

{ #category : 'private' }
VGAeRendererTest >> exportSelectorsWithNoOverrideYet [
	"The class-side export methods of `BARenderer` this route does not redefine. Their upstream
	 bodies reach Alexandrie's own canvas — `newFormFrom:` through `aeAsForm`, `write:asPngTo:`
	 through `BAExporter png` — and a `VGScaledFont` cannot be drawn through that canvas, so
	 exporting an element that carries text is a stated hole of this route, not an oversight.
	 `VGRenderer` covers both for the all-ours route; unit 5.3 of the font plan decides whether
	 this one needs them. `testTheExportMethodsAreAStatedHoleOfThisRoute` fails as soon as one is
	 covered."

	^ #( #newFormFrom: #write:asPngTo: )
]

{ #category : 'running' }
VGAeRendererTest >> setUp [
	"`BlHostRenderer class >> preferableClass` caches the renderer the whole image draws through,
	 and these tests change it, so the previous choice is put back afterwards. The font manager is
	 ours for the duration, because a frame on this route has to find one of our faces."

	super setUp.
	previousRendererClass := BlHostRenderer preferableClass.
	previousFontManager := VGFontManager managerUpstreamHolds
]

{ #category : 'running' }
VGAeRendererTest >> tearDown [
	"Both globals are put back by hand, because a test that installed either of them would
	 otherwise decide how the rest of the image draws and finds its fonts."

	BlHostRenderer preferableClass: previousRendererClass.
	VGFontManager restoreUpstreamManager: previousFontManager.
	VGAeOffscreen resetInstance.
	super tearDown
]

{ #category : 'tests' }
VGAeRendererTest >> testASpaceWithTextDrawsThroughCairoWithOurScaledFontsAndNoFreeTypeFace [
	"The gate of unit 5.1. A real `BlSpace` holding a text element is opened on a host with no
	 window, with our font manager installed and this renderer chosen, and four facts are stated
	 about the frame it drew: the space chose this renderer, pixels reached the buffer the host
	 lent, the span was measured against a face and a scaled font of ours, and FreeType was asked
	 for no new face. Cairo drew every one of those pixels; only the fonts came from this project.
	 The fonts are read from the offscreen canvas because a span resolves its scaled font while it
	 is measured and the frame canvas is then handed that font to draw with."

	| space element facesBefore facesAfter faces fonts |
	VGFontManager installGlobally.
	BlHostRenderer preferableClass: VGAeRenderer.
	VGAeOffscreen resetInstance.
	element := BlTextElement new
		           text: 'Hi' asRopedText;
		           position: 10 @ 10;
		           yourself.
	space := BlSpace new
		         host: VGPixelBufferHost default;
		         yourself.
	space extent: 100 @ 100.
	space root addChild: element.
	Smalltalk garbageCollect.
	facesBefore := AeFTFace allInstances size.
	[
	space show.
	space settleForDuration: 5 seconds.
	self assert: space hostSpace renderer class equals: VGAeRenderer.
	self deny: (space hostSpace pixels allSatisfy: [ :each | each = 0 ]).
	faces := OrderedCollection new.
	fonts := OrderedCollection new.
	(VGAeOffscreen instance canvas instVarNamed: 'scaledFontCache')
		keysAndValuesDo: [ :key :font |
			faces add: key first.
			fonts add: font ].
	self deny: fonts isEmpty.
	self assert: (faces allSatisfy: [ :each | each isKindOf: VGFontFace ]).
	self assert: (fonts allSatisfy: [ :each | each isKindOf: VGScaledFont ]).
	Smalltalk garbageCollect.
	facesAfter := AeFTFace allInstances size.
	self assert: facesAfter <= facesBefore ] ensure: [
		space close.
		VGPixelBufferHost cleanUp.
		VGFontManager uninstallGlobally ]
]

{ #category : 'tests' }
VGAeRendererTest >> testInitializeForHostSpaceStaysDerivedFromUpstream [
	"My renderer's single instance side override is Alexandrie's own method with the canvas and
	 the offscreen changed. Holding it against the upstream source means a field added there is
	 noticed here, and not in a frame that silently draws with a stale scale factor."

	| ours upstream |
	ours := (VGAeRenderer >> #initializeForHostSpace:) sourceCode
		        copyReplaceAll: 'VGAeOffscreen instance'
		        with: 'BAOffscreen instance'.
	ours := ours
		        copyReplaceAll: 'VGAeCanvas newWithoutSurface'
		        with: 'AeCanvas newWithoutSurface'.
	upstream := (BARenderer >> #initializeForHostSpace:) sourceCode.
	self
		assert: (RBParser parseMethod: ours) body
		equals: (RBParser parseMethod: upstream) body
]

{ #category : 'tests' }
VGAeRendererTest >> testMeasuringAParagraphWithoutAWindowUsesTheOffscreenOfThisRoute [
	"Bloc measures text during layout, which happens before any window exists, through a class
	 side send that reaches a singleton canvas. On this route that singleton is `VGAeOffscreen`."

	| paragraph |
	paragraph := VGTextParagraphStub new.
	VGAeRenderer offscreenMeasureTextParagraph: paragraph.
	self assert: paragraph measurer canvas class equals: VGAeCanvas
]

{ #category : 'tests' }
VGAeRendererTest >> testTheExportMethodsAreAStatedHoleOfThisRoute [
	"Drawing a frame goes through our canvas, but exporting an element to a form or a PNG still
	 goes through Alexandrie's, because this renderer inherits the two class-side export methods.
	 The sister route redefines both. The selectors are listed, so the day one is covered the
	 list has to change with it."

	self exportSelectorsWithNoOverrideYet do: [ :each |
		self assert: (BARenderer class includesSelector: each).
		self assert: (VGRenderer class includesSelector: each).
		self deny: (VGAeRenderer class includesSelector: each) ].
	self
		assertCollection: (VGRenderer class selectors reject: [ :each |
				 VGAeRenderer class includesSelector: each ])
		hasSameElements: self exportSelectorsWithNoOverrideYet
]

{ #category : 'tests' }
VGAeRendererTest >> testTheRendererBuildsTheCanvasOfThisRouteAndMeasuresThroughIt [
	"A renderer holds one canvas for the frame and one text measurer for layout. Alexandrie's own
	 method builds the canvas by naming `AeCanvas` and takes the measurer from `BAOffscreen`;
	 both have to be of this route, or the frame would be drawn with our fonts while the layout
	 that placed it was measured with Cairo's."

	| renderer |
	renderer := VGAeRenderer new.
	renderer initializeForHostSpace: VGHostSpaceStub new.
	self assert: renderer canvas class equals: VGAeCanvas.
	self assert: renderer textMeasurer canvas class equals: VGAeCanvas
]

{ #category : 'tests' }
VGAeRendererTest >> testTheRendererIsOneBlocCanChooseAndNamesItselfApartFromTheOthers [
	"`BlHost >> newHostRenderer` asks `BlHostRenderer preferableClass`, so naming this renderer
	 there is the whole installation seam of the route. The label is what Bloc shows in a window
	 title and in its own tools, and the three renderers have to be told apart there."

	BlHostRenderer preferableClass: VGAeRenderer.
	self assert: BlHeadlessHost default newHostRenderer class equals: VGAeRenderer.
	self assert: (BlHostRenderer availableClasses includes: VGAeRenderer).
	self deny: VGAeRenderer label equals: BARenderer label.
	self deny: VGAeRenderer label equals: VGRenderer label
]

{ #category : 'tests' }
VGAeRendererTest >> testTheWindowSceneDrawsTextOfTwoSizesInACatalogueFamily [
	"The gate of unit 5.3. The scene the window example shows is drawn here on a host with no
	 window, because a real window blocks the image until a reader closes it. Three facts: the
	 frame reached the pixels the host lent, the scene names one family in two sizes, and the
	 scaled fonts the frame resolved are faces of ours carrying that very family at those two
	 sizes — so a reader of the window sees the font the catalogue found on the disk, not a
	 silent fallback on the default face.
	 The manager is posed with its default faces, which are the two Source families Pharo
	 embeds, so the font directory Pharo ships is scanned on top of them: 2 ms, and the only
	 place Cascadia Code is found."

	| space scene drawn |
	VGFontManager installGlobally.
	AeFontManager globalInstance scanDirectory:
		AeFilesystemResources fontsDirectory.
	BlHostRenderer preferableClass: VGAeRenderer.
	VGAeOffscreen resetInstance.
	scene := VGAeRendererExamples textSceneInTwoSizes.
	space := BlSpace new
		         host: VGPixelBufferHost default;
		         yourself.
	space extent: 320 @ 160.
	space root addChild: scene.
	[
	space show.
	space settleForDuration: 5 seconds.
	self deny: (space hostSpace pixels allSatisfy: [ :each | each = 0 ]).
	self
		assert: (self textFamiliesAndSizesIn: scene)
		equals: { ('Cascadia Code' -> 12). ('Cascadia Code' -> 36) }.
	drawn := self cachedFacesAndSizesOf: VGAeOffscreen instance canvas.
	self
		assert: (drawn collect: [ :each | each key class -> each value ])
		equals: { (VGFontFace -> 12). (VGFontFace -> 36) }.
	self
		assert: (drawn collect: [ :each | each key familyName -> each value ])
		equals: { ('Cascadia Code' -> 12). ('Cascadia Code' -> 36) } ] ensure: [
		space close.
		VGPixelBufferHost cleanUp.
		VGFontManager uninstallGlobally ]
]

{ #category : 'private' }
VGAeRendererTest >> textFamiliesAndSizesIn: aScene [
	"Every text element of a scene as family name -> font size, ordered by size, so that a test
	 states what a reader of the window sees rather than the order the children happen to be
	 in."

	^ ((aScene children select: [ :each | each isKindOf: BlTextElement ])
		   collect: [ :each |
			   | attributes |
			   attributes := each text attributesAt: 1.
			   (attributes detect: [ :attribute |
				    attribute isKindOf: BlFontFamilyAttribute ]) name
			   -> (attributes detect: [ :attribute |
					    attribute isKindOf: BlFontSizeAttribute ]) size ]) asArray
		  sort: [ :a :b | a value < b value ]
]
