"
I hold the facts about `VGRenderer`, the host renderer that draws a Bloc space through
this project.

Three kinds of fact live here. First, the wiring: the renderer is a host renderer Bloc can choose,
and the canvas, the text measurer, the form and the PNG path it builds are all ours. Second, the
handover: the host window lends a raw pixel address and a row pitch, and the renderer has to draw
into that memory with the right device offset and device scale. Third, and most important for a
failover image, the proof that no Cairo code runs: one test reads every method this package owns and
finds no reference into `Alexandrie-Cairo`, and another installs a metalink on every method of that
package, draws a frame, and fails if any of them was entered.

The last test opens a real headless space, draws it and dispatches a mouse event through it, which
is the gate of this unit. Note what it does not prove: this image has Cairo loaded, because the
conformance tests need live Cairo as their oracle, so the gate's own words — ""with no `libcairo`
present"" — can only be satisfied in a separate failover image. The static scan and the metalink
test are what stand in for it here.
"
Class {
	#name : 'VGRendererTest',
	#superclass : 'TestCase',
	#instVars : [
		'previousRendererClass'
	],
	#category : 'VectorGraphics-Bloc-Tests',
	#package : 'VectorGraphics-Bloc-Tests'
}

{ #category : 'private' }
VGRendererTest >> cairoForeignCallMethods [
	"Every foreign function of the Cairo package, resolved from its own class so that the compiled
	 method is the live one. `package methods` can answer a method that has since been replaced,
	 and a link installed on a replaced method never fires, which would let this proof pass by
	 accident."

	^ (PackageOrganizer default packageNamed:
		   VGCairoReferenceScanner cairoPackageName) methods
		  select: [ :each | each sendsSelector: #ffiCall: ]
		  thenCollect: [ :each | each methodClass >> each selector ]
]

{ #category : 'private' }
VGRendererTest >> drawEverythingOn: aCanvas [
	"One frame that uses all five creation seams and the font bridge, so a proof about this draw
	 says something about a real frame and not only about a plain fill."

	aCanvas scaledFontForFace: AeFontManager globalInstance defaultFace size: 12.
	aCanvas
		pathFactory: [ :context |
			context rectangleX: 0 y: 0 width: 20 height: 20 ];
		setBackgroundWith: [
			aCanvas
				setSourceLinearPatternStops: {
						(0 -> Color red).
						(1 -> Color blue) }
				start: 0 @ 0
				end: 20 @ 0 ];
		setBorderOff;
		drawFigureAndPrepareToClip: false.
	aCanvas
		pathFactory: [ :context | context circleCenterX: 10 y: 10 radius: 6 ];
		setBackgroundWith: [
			aCanvas
				setSourceRadialPatternStops: {
						(0 -> Color white).
						(1 -> Color black) }
				innerCenter: 10 @ 10
				innerRadius: 0
				outerCenter: 10 @ 10
				outerRadius: 6 ];
		setBorderOff;
		drawFigureAndPrepareToClip: false.
	aCanvas
		newSurfaceWithGaussianShadow: 20 @ 20
		width: 3
		canvasDo: [ :alphaCanvas |
			alphaCanvas
				pathFactory: [ :context |
					context rectangleX: 4 y: 4 width: 12 height: 12 ];
				setBackgroundWith: [ alphaCanvas setSourceColor: Color black ];
				setBorderOff;
				drawFigureAndPrepareToClip: false ]
]

{ #category : 'private' }
VGRendererTest >> exportersWithNoOverrideYet [
	"The exporters of `Bloc-Alexandrie` that still build Alexandrie's canvas because this project
	 has no subclass for them. JPEG needs nothing but the canvas, and PDF and SVG need our export
	 surfaces, which unit 1.9 built; the three are a stated hole in the failover, not an oversight,
	 and `testEveryExporterThatNamesTheCanvasIsOverridden` fails as soon as one is covered."

	^ #( #BAJpgExporter #BAPdfExporter #BASvgExporter )
]

{ #category : 'private' }
VGRendererTest >> foreignPackagePrefixes [
	"The packages this project subclasses and must not touch: Bloc, its Alexandrie backend, and
	 Alexandrie itself."

	^ #( 'Bloc' 'Alexandrie' )
]

{ #category : 'running' }
VGRendererTest >> setUp [
	"`BlHostRenderer class >> preferableClass` caches the renderer the whole image draws through,
	 and these tests change it, so the previous choice is put back afterwards."

	super setUp.
	previousRendererClass := BlHostRenderer preferableClass
]

{ #category : 'running' }
VGRendererTest >> tearDown [
	BlHostRenderer preferableClass: previousRendererClass.
	super tearDown
]

{ #category : 'tests' }
VGRendererTest >> testAFrameDrawnThroughOurRendererEntersNoCairoFunction [
	"The static scan proves that no method of this project names a Cairo class. This proves the
	 other half, at run time: a frame drawn through our renderer enters none of the foreign
	 functions of the Cairo package. Every method of that package that sends `ffiCall:` carries a
	 metalink for the length of the draw, and one link per method is needed, because a single link
	 shared between method nodes fires for the first only. A link fires in whichever process makes
	 the call, so only the calls of the process drawing the frame are counted: the finalisation
	 process frees the Cairo objects of other tests through AeCairoContext class >> externallyFree:
	 whenever a collection falls in this window, and a free of another test's object is not part
	 of our frame. Our frame is drawn in this process from end to end, so nothing of it is lost by
	 the filter. The deliberate Cairo call at the end is the positive control: without it,
	 instrumentation that silently failed to install would make this test pass."

	| entered links renderer stride pixels drawingProcess |
	entered := OrderedCollection new.
	drawingProcess := Processor activeProcess.
	links := self cairoForeignCallMethods collect: [ :each |
		         | link |
		         link := MetaLink new.
		         link metaObject: [ :context |
			         Processor activeProcess == drawingProcess ifTrue: [
				         entered add: context method ] ].
		         link selector: #value:.
		         link arguments: #( #context ).
		         each ast link: link.
		         link ].
	[
	renderer := VGRenderer new.
	renderer initializeForHostSpace: VGHostSpaceStub new.
	stride := VGCairoSurfaceFormat argb32 strideForWidth: 20.
	pixels := ByteArray new: stride * 20.
	renderer
		renderWith: [ :canvas | self drawEverythingOn: canvas ]
		pixels: pixels
		stride: stride
		physicalRectangle: (0 @ 0 extent: 20 @ 20)
		logicalRectangle: (0 @ 0 extent: 20 @ 20).
	self
		assert: entered isEmpty
		description: 'these Cairo functions ran: '
			, (entered collect: [ :each | each printString ]) asArray printString.
	entered removeAll.
	(AeCairoImageSurface extent: 4 @ 4) newContext rotateByRadians: 0.5.
	self
		deny: entered isEmpty
		description: 'the instrumentation never fired, so the proof above says nothing' ]
		ensure: [ links do: [ :each | each uninstall ] ]
]

{ #category : 'tests' }
VGRendererTest >> testASpaceOpensDrawsAndRespondsToAClickThroughOurRenderer [
	"The gate of this unit. A real `BlSpace` is opened on a host whose space draws, with our
	 renderer as the one the image has chosen, and three facts are stated about it: the space
	 chose our renderer, a frame reached the pixels the host lent, and a click on an element
	 reached its handler. Nothing here knows about this project except the renderer class, which
	 is what a failover has to be."

	| space element clicked |
	BlHostRenderer preferableClass: VGRenderer.
	clicked := false.
	element := BlElement new.
	element
		extent: 40 @ 30;
		background: Color red;
		addEventHandlerOn: BlClickEvent do: [ :event | clicked := true ].
	space := BlSpace new
		         host: VGPixelBufferHost default;
		         yourself.
	space extent: 100 @ 100.
	space root addChild: element.
	[
		space show.
		space settleForDuration: 5 seconds.
		self assert: space hostSpace renderer class equals: VGRenderer.
		self assert: space hostSpace class equals: VGPixelBufferHostSpace.
		self deny: (space hostSpace pixels allSatisfy: [ :each | each = 0 ]).
		element eventSimulator click.
		space settleForDuration: 5 seconds.
		self assert: clicked ] ensure: [
			space close.
			VGPixelBufferHost cleanUp ]
]

{ #category : 'tests' }
VGRendererTest >> testEveryExporterThatNamesTheCanvasIsOverridden [
	"`newCanvas:` is the one method of the exporter hierarchy that names a backend, so an exporter
	 that names `AeCanvas` and has no subclass here exports through Cairo. The two we cover are
	 `VGFormExporter` and `VGPngExporter`; the rest are listed by `exportersWithNoOverrideYet`."

	| naming covered |
	naming := BAExporter withAllSubclasses select: [ :each |
		          (each includesSelector: #newCanvas:) and: [
			          (each >> #newCanvas:) allLiterals anySatisfy: [ :literal |
				          literal isVariableBinding and: [ literal value == AeCanvas ] ] ] ].
	covered := naming select: [ :each |
		           each subclasses anySatisfy: [ :subclass |
			           subclass includesSelector: #newCanvas: ] ].
	self
		assertCollection: (covered collect: [ :each | each name ]) asSet
		hasSameElements: #( #BAFormExporter #BAPngExporter ).
	self
		assertCollection:
		((naming \ covered) collect: [ :each | each name ]) asSet
		hasSameElements: self exportersWithNoOverrideYet.
	self
		assert: (BAFormExporter subclasses collect: [ :each | each name ]) asArray
		equals: (Array with: VGFormExporter name).
	self
		assert: (BAPngExporter subclasses collect: [ :each | each name ]) asArray
		equals: (Array with: VGPngExporter name)
]

{ #category : 'tests - text' }
VGRendererTest >> testMeasuringAParagraphWithoutAWindowUsesOurCanvas [
	"Bloc measures text during layout, which happens before any window exists, through a class
	 side send that reaches a singleton canvas. That canvas has to be ours, or a failover image
	 would call Cairo while laying out, long before it drew anything."

	| paragraph |
	paragraph := VGTextParagraphStub new.
	VGRenderer offscreenMeasureTextParagraph: paragraph.
	self assert: paragraph measurer canvas class equals: VGCanvas
]

{ #category : 'tests' }
VGRendererTest >> testNoMethodOfThisProjectNamesACairoClass [
	"The failover is only real if nothing in this project reaches for a Cairo class, because a
	 named class would be looked up and its library loaded as soon as the method ran. The scanner
	 reads the literal frame of every method of every package of the project, blocks included."

	| offenders |
	offenders := VGCairoReferenceScanner default offenders.
	self
		assert: offenders isEmpty
		description: 'these methods name a Cairo class: '
			, (offenders collect: [ :each | each key printString ]) asArray printString
]

{ #category : 'tests' }
VGRendererTest >> testTheBlocBackendMethodsThatBypassTheCanvasAreKnown [
	"Four methods of the Bloc backend build a Cairo object themselves instead of asking the canvas
	 for it. One is the renderer's own frame handover, which this project overrides. The other
	 three cannot be reached by subclassing the canvas and are the stated gap of this unit: the
	 surface a composition layer paints on, the surface a gradient shadow is drawn into, and a
	 shared matrix, whose class only allocates a structure in object memory and calls nothing.
	 A fifth one would be a hole in the failover, so the list is asserted rather than only
	 described."

	| named |
	named := (VGCairoReferenceScanner default bypassingBlocMethods collect: [
		          :each | each methodClass name , '>>' , each selector ]) asSet.
	self
		assertCollection: named
		hasSameElements:
			#( 'BARenderer>>renderWith:pixels:stride:physicalRectangle:logicalRectangle:'
			   'BAAxisAlignedCompositionLayer>>createSurfaceToBePaintedOn:'
			   'BlGradientShadowEffect>>setUpShadowSurfaceFor:extent:'
			   'BASharedCairoMatrix>>default' ) asSet.
	self assert: (VGRenderer includesSelector:
			 #renderWith:pixels:stride:physicalRectangle:logicalRectangle:)
]

{ #category : 'tests - form and png' }
VGRendererTest >> testTheFormOfAnElementIsDrawnByOurCanvas [
	"`newFormFrom:` is how Bloc turns an element into a Pharo `Form`, which is what an inspector
	 preview and a test of a widget both use. Drawing it has to go through our canvas, and the form
	 has to carry the ink: the extent alone would pass on an empty surface."

	| element form |
	element := BlElement new
		           extent: 20 @ 10;
		           background: Color red;
		           yourself.
	form := VGRenderer newFormFrom: element.
	self assert: form extent equals: 20 @ 10.
	self assert: (form colorAt: 10 @ 5) equals: Color red
]

{ #category : 'tests' }
VGRendererTest >> testTheFormOfAnElementStaysDerivedFromUpstream [
	"`VGCanvas class >> formOfElement:` is `BlElement >> aeAsForm` with the canvas class changed
	 and the element passed as an argument, because the method walks the parent chain to collect
	 transformations and that walk is not ours to reinvent. The two are held together here: parse
	 both, substitute the names back, and compare the trees, so a change upstream fails a test
	 instead of quietly leaving our form unrotated. Our canvas is built with `self extent:`, which
	 is what the class side of a canvas class says instead of naming itself, so that send is put
	 back first — before `aBlElement` becomes `self` and makes the two indistinguishable."

	| ours upstream |
	ours := (VGCanvas class >> #formOfElement:) sourceCode.
	ours := (ours copyReplaceAll: 'self extent:' with: 'AeCanvas extent:')
		        copyReplaceAll: 'aBlElement'
		        with: 'self'.
	upstream := (BlElement >> #aeAsForm) sourceCode.
	self
		assert: (RBParser parseMethod: ours) body
		equals: (RBParser parseMethod: upstream) body
]

{ #category : 'tests - form and png' }
VGRendererTest >> testThePngOfAnElementIsWrittenThroughOurCanvas [
	"The PNG export of an element goes through the exporter hierarchy of `Bloc-Alexandrie`, which
	 is backend independent but for the canvas it builds. The file written here is read back, so
	 the test covers our PNG writer as well as our canvas."

	| element file written |
	element := BlElement new
		           extent: 16 @ 8;
		           background: Color blue;
		           yourself.
	file := FileSystem memory root / 'element.png'.
	VGRenderer write: element asPngTo: file.
	self assert: file exists.
	written := file binaryReadStreamDo: [ :stream |
		           PNGReadWriter formFromStream: stream ].
	self assert: written extent equals: 16 @ 8.
	self assert: (written colorAt: 8 @ 4) equals: Color blue
]

{ #category : 'tests - wiring' }
VGRendererTest >> testTheRendererBuildsOurCanvasAndMeasuresTextWithIt [
	"A renderer holds one canvas for the frame and one text measurer for layout, and the inherited
	 method builds both through Alexandrie: the canvas by naming `AeCanvas`, the measurer by asking
	 `BAOffscreen` for its own. Both have to be ours, and the measurer's canvas as well, because
	 text is measured before anything is drawn."

	| renderer |
	renderer := VGRenderer new.
	renderer initializeForHostSpace: VGHostSpaceStub new.
	self assert: renderer canvas class equals: VGCanvas.
	self assert: renderer textMeasurer canvas class equals: VGCanvas
]

{ #category : 'tests - wiring' }
VGRendererTest >> testTheRendererDrawsIntoThePixelsTheHostLent [
	"This is the handover the host window performs on every frame: it lends a raw pixel buffer and
	 the row pitch of its own rows, and the renderer draws straight into it in premultiplied
	 ARGB32, with the damaged rectangle's origin as a device offset so that drawing in space
	 coordinates lands in the right place. The surface built over those pixels has to be ours, and
	 the pixels themselves have to change."

	| renderer stride pixels surface |
	renderer := VGRenderer new.
	renderer initializeForHostSpace: VGHostSpaceStub new.
	stride := VGCairoSurfaceFormat argb32 strideForWidth: 20.
	pixels := ByteArray new: stride * 20.
	surface := nil.
	renderer
		renderWith: [ :canvas |
			surface := canvas privateAeCairoSurface.
			canvas
				pathFactory: [ :context | context rectangleX: 0 y: 0 width: 20 height: 20 ];
				setBackgroundWith: [ canvas setSourceColor: Color red ];
				setBorderOff;
				drawFigureAndPrepareToClip: false ]
		pixels: pixels
		stride: stride
		physicalRectangle: (0 @ 0 extent: 20 @ 20)
		logicalRectangle: (0 @ 0 extent: 20 @ 20).
	self assert: surface class equals: VGCairoImageSurface.
	self deny: (pixels allSatisfy: [ :each | each = 0 ])
]

{ #category : 'tests - wiring' }
VGRendererTest >> testTheRendererIsAHostRendererBlocCanChoose [
	"`BlHost >> newHostRenderer` asks `BlHostRenderer preferableClass`, which answers the one
	 subclass that was named, or any available one when nobody named it. That send is the whole
	 installation seam: naming this renderer there is what makes every space draw through this
	 project."

	BlHostRenderer preferableClass: VGRenderer.
	self assert: BlHeadlessHost default newHostRenderer class equals: VGRenderer.
	self assert: (BlHostRenderer availableClasses includes: VGRenderer)
]

{ #category : 'tests - wiring' }
VGRendererTest >> testTheRendererNamesItself [
	"The label is what Bloc shows for the renderer in a window title and in its own tools, so a
	 failover image says which engine drew the frame."

	self assert: VGRenderer label equals: 'VectorGraphics'.
	self deny: VGRenderer label equals: BARenderer label
]

{ #category : 'tests' }
VGRendererTest >> testThisProjectDefinesNoMethodOnABlocOrAlexandrieClass [
	"The failover is a set of subclasses and nothing else: no method of this project is installed
	 on a class of Bloc or of Alexandrie. An extension method there would change the behaviour of
	 the image that loads this project, which is the opposite of a failover that can be chosen."

	| offenders |
	offenders := VGCairoReferenceScanner projectPackageNames flatCollect: [
		             :packageName |
		             (PackageOrganizer default packageNamed: packageName) methods
			             select: [ :each |
				             | owner |
				             owner := each methodClass instanceSide package.
				             owner notNil and: [
					             self foreignPackagePrefixes anySatisfy: [ :prefix |
						             owner name beginsWith: prefix ] ] ] ].
	self
		assert: offenders isEmpty
		description: 'these methods are installed on a foreign class: '
			, (offenders collect: [ :each | each printString ]) asArray printString
]
