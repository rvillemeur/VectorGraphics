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

{ #category : 'running' }
VGAeRendererTest >> setUp [
	"`BlHostRenderer class >> preferableClass` caches the renderer the whole image draws through,
	 and these tests change it, so the previous choice is put back afterwards. The font manager is
	 ours for the duration, because a frame on this route has to find one of our faces."

	super setUp.
	previousRendererClass := BlHostRenderer preferableClass.
	previousFontManager := (AeFontManager class slotNamed: #globalInstance) read:
		                       AeFontManager
]

{ #category : 'running' }
VGAeRendererTest >> tearDown [
	"Both globals are put back by hand, because a test that installed either of them would
	 otherwise decide how the rest of the image draws and finds its fonts."

	BlHostRenderer preferableClass: previousRendererClass.
	(AeFontManager class slotNamed: #globalInstance)
		write: previousFontManager
		to: AeFontManager.
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
