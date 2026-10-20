"
I draw a Bloc space through this project instead of through Cairo.

Bloc picks a renderer with `BlHostRenderer class >> preferableClass`, so installing me is one send:
`BlHostRenderer preferableClass: VGRenderer`. Note that merely loading this package makes that
choice ambiguous — `preferableClass` answers `allSubclasses anyOne` when nobody chose — so an image
that wants Cairo must say so, and a failover image must name me.

Everything that composes, clips, caches and walks the scene graph is inherited from `BARenderer`.
Four things are not, and they are what I override: the canvas and the text measurer built when a
host space is attached, the surface built over the pixels the host window lends on every frame, and,
on the class side, the label, the offscreen measurer, the form of an element and the PNG of an
element.

What I cannot reach: three methods of `Bloc-Alexandrie` build a Cairo surface without asking a
canvas for it — a composition layer, the surface of a gradient shadow effect, and the shared matrix
of a cached transformation. `VGRendererTest` lists them, so a fourth one fails a test rather than a
failover image.
"
Class {
	#name : 'VGRenderer',
	#superclass : 'BARenderer',
	#category : 'VectorGraphics-Bloc-Backend',
	#package : 'VectorGraphics-Bloc',
	#tag : 'Backend'
}

{ #category : 'accessing' }
VGRenderer class >> label [
	"What Bloc calls this engine in a window title and in its own tools."

	^ 'VectorGraphics'
]

{ #category : 'host - api' }
VGRenderer class >> newFormFrom: aBlElement [
	"The inherited method sends `aeAsForm`, which names `AeCanvas` in its own source and cannot be
	 reached through any seam, so the walk it performs lives in `VGCanvas class >> formOfElement:`
	 instead, held against the upstream source by a test."

	^ VGCanvas formOfElement: aBlElement
]

{ #category : 'host - api' }
VGRenderer class >> offscreenMeasureTextParagraph: aBlTextParagraph [
	"Text is measured during layout, before any window exists, so the measurement goes through a
	 singleton canvas. The inherited method uses Alexandrie's singleton; this one uses ours."

	VGOffscreen instance measureTextParagraph: aBlTextParagraph
]

{ #category : 'form' }
VGRenderer class >> write: aBlElement asPngTo: aFileReference [
	"Draw the element into a PNG at the given location. The exporter is Alexandrie's, because only
	 the canvas it builds decides the backend."

	^ VGPngExporter new
		  target: aFileReference;
		  element: aBlElement;
		  export
]

{ #category : 'accessing' }
VGRenderer >> canvas [
	"The canvas of the current frame. A renderer builds one canvas and reuses it, giving it the
	 surface of each damaged rectangle in turn."

	^ aeCanvas
]

{ #category : 'initialization' }
VGRenderer >> initializeForHostSpace: aBlHostSpace [
	"The inherited method builds the frame canvas by naming `AeCanvas` and takes its text measurer
	 from `BAOffscreen`, whose canvas is one as well. Both come from this project here. A renderer
	 can be initialised more than once, which is why the inherited method starts with `initialize`."

	self initialize.
	physicalSize := aBlHostSpace physicalSize.
	scaleFactor := aBlHostSpace scaleFactor.
	session := Smalltalk session.
	textMeasurer := VGOffscreen instance textMeasurer.
	aeCanvas := VGCanvas newWithoutSurface
]

{ #category : 'inspector' }
VGRenderer >> inspectorRenderer: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Renderer'>
	"What Bloc holds when this project is the backend: our canvas for the frame, our text
	 measurer for layout, and the class the image would pick for the next space it opens, which
	 is asked of Bloc rather than assumed."

	^ aBuilder newTable
		  items: {
				  ('Label' -> self class label).
				  ('Canvas' -> self canvas class).
				  ('Canvas is valid' -> self isValid).
				  ('Text measurer canvas' -> (self textMeasurer
					    ifNil: [ nil ]
					    ifNotNil: [ :measurer | measurer canvas class ])).
				  ('Scale factor' -> scaleFactor).
				  ('Bloc would pick' -> BlHostRenderer preferableClass) };
		  addColumn: (SpStringTableColumn
				   title: 'Property'
				   evaluated: [ :each | each key ]);
		  addColumn: (SpStringTableColumn
				   title: 'Value'
				   evaluated: [ :each | each value printString ]);
		  yourself
]

{ #category : 'inspector' }
VGRenderer >> inspectorRendererContext: aContext [
	"A renderer holds nothing until a host space has initialised it."

	aContext active: aeCanvas notNil
]

{ #category : 'rendering' }
VGRenderer >> renderWith: aBlock pixels: address stride: stride physicalRectangle: physicalRectangle logicalRectangle: logicalRectangle [
	"The host window lends the pixels of one damaged rectangle and the pitch of its own rows. The
	 surface over them is this project's, and it carries the rectangle's origin as a device offset
	 and the window's scale factor as a device scale, so that the canvas keeps drawing in space
	 coordinates. On a high resolution screen the quality options drop, as upstream does, because
	 the area painted is four times larger and the difference is not visible."

	| aSurface |
	aSurface := VGCairoImageSurface
		            unownedNewForData: address
		            format: VGCairoSurfaceFormat argb32
		            width: physicalRectangle width
		            height: physicalRectangle height
		            stride: stride.
	aSurface
		deviceOffset: physicalRectangle origin negated;
		deviceScaleX: scaleFactor y: scaleFactor.
	aeCanvas prepareForSurface: aSurface.
	aeCanvas clippingRectangle: logicalRectangle.
	scaleFactor > 1.0 ifTrue: [ aeCanvas setLowQualityOptions ].
	aBlock value: aeCanvas.
	aSurface flush.
	aeCanvas removeSurface.
	aSurface externallyFree
]
