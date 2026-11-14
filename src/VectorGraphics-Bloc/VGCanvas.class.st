"
I am an `AeCanvas` that builds this project's objects instead of Cairo's.

Bloc draws through an `AeCanvas`, and almost every method of that class is backend independent: it
records a path, a paint or a clip and sends it on to whatever context it holds. Only six methods
reach the backend by building one of its objects, and I override exactly those six: the two that
build a surface, the two that build a gradient pattern, the one that builds the blurred alpha
surface of a shadow, and the one that builds a scaled font.

The sixth is the awkward one. It names no Cairo class at all; it sends `newCairoFontFace` to the
face Bloc hands over, so the Cairo call hides inside the face, and a face of ours answers itself.
Unit 5.1 of the font plan moved that override up into `VGFontCanvas`, which I share with
`VGAeCanvas`, and unit 5.2 took the bridge behind it away: the font manager posed for the image is
ours, so the face arrives carrying its own bytes and there is nothing to match against a foreign
font registry any more.

My instance side holds no state of its own: everything I override reads the inherited instance
variables, which is the point — the canvas stays Alexandrie's and only the objects change.
"
Class {
	#name : 'VGCanvas',
	#superclass : 'VGFontCanvas',
	#category : 'VectorGraphics-Bloc-Backend',
	#package : 'VectorGraphics-Bloc',
	#tag : 'Backend'
}

{ #category : 'instance creation' }
VGCanvas class >> extent: aPoint [
	"`AeCanvas class >> extent:` names `AeCairoImageSurface`, which is the one line that decides
	 the backend of every canvas built by extent, including the one each exporter builds."

	^ self newFor: (VGCairoImageSurface extent: aPoint)
]

{ #category : 'form' }
VGCanvas class >> formOfElement: aBlElement [
	"The `Form` of an element, drawn through this project. This is `BlElement >> aeAsForm` with the
	 canvas class changed and the receiver passed in as an argument: the method walks the parents to
	 collect their transformations, which is behaviour of the renderer's form API and not something
	 to reinvent, and `VGRendererTest` holds this method against the upstream source so the two
	 cannot drift apart."

	| topMostBounds transformedGeometryBounds aCanvas matrix |
	aBlElement isLayoutRequested ifTrue: [
		aBlElement isAttachedToSceneGraph
			ifTrue: [ aBlElement space settle ]
			ifFalse: [ aBlElement forceLayout ] ].
	topMostBounds := aBlElement topMostParent bounds asRectangle.
	matrix := BlMatrix2D new.
	aBlElement allParentsReverseDo: [ :e |
		matrix := e transformation matrix copy multiplyBy: matrix ].
	aBlElement transformation asElementTransformation class
	= BlElementAbsoluteTransformation ifFalse: [
		matrix := aBlElement transformation matrix copy multiplyBy: matrix ].
	transformedGeometryBounds := aBlElement geometryBounds copy.
	matrix transformBounds: transformedGeometryBounds.
	aBlElement withAllParentsReverseDo: [ :e |
		transformedGeometryBounds translateBy: e position ].
	aCanvas := self extent: transformedGeometryBounds extent.
	aCanvas privateAeCairoSurface deviceOffset:
		transformedGeometryBounds origin negated.
	aCanvas clippingRectangle: topMostBounds.
	aCanvas restoreContextAfter: [
		aBlElement allParentsReverseDo: [ :e |
			aCanvas pathTranslate: e position.
			e transformation aeApplyTo: aCanvas ].
		aBlElement aeFullDrawOn: aCanvas ].
	^ aCanvas asForm
]

{ #category : 'inspector' }
VGCanvas >> inspectionOfSurface: aBuilder [
	<inspectorPresentationOrder: 0 title: 'Surface'>
	"Alexandrie's own view of this tab answers the surface's Form itself. The inspector then sends
	 asInspection to what the view answered, which a Form does not understand, and that send is
	 outside the handler newInspectionPresenterOnApplication: wraps the build in: the tab raises
	 for any AeCanvas, ours included. The Form goes through the builder here instead.

	 The override lives on our canvas because Alexandrie's classes are never edited in this
	 project. #asForm answers a fresh Form every call, so showing the surface cannot change it."

	^ aBuilder newImage
		  image: cairoSurface asForm;
		  yourself
]

{ #category : 'inspector' }
VGCanvas >> inspectionOfSurfaceContext: aContext [
	"Nothing to show before a surface is posed: asForm would be asked of nil."

	aContext active: cairoSurface notNil
]

{ #category : 'API - other' }
VGCanvas >> newCairoSurfaceExtent: aLogicalExtent [
	"The logical extent is in points and the surface is in device pixels, so the surface carries
	 the device scale and the canvas keeps drawing in points."

	| aScale aSurface |
	aScale := self deviceScale.
	aSurface := VGCairoImageSurface extent: aLogicalExtent * aScale.
	aSurface deviceScale: aScale.
	^ aSurface
]

{ #category : 'API - other' }
VGCanvas >> newSurfaceWithGaussianShadow: extent width: width canvasDo: aBlock [
	"The shadow of an element is drawn once into an alpha surface, blurred, and then used as a
	 mask. `AeCanvas` builds that intermediate canvas by naming its own class, so a subclass has to
	 send `self class newFor:` here or the shadow would be drawn through Cairo. The filter is the
	 one the selected backend owns, so a window on a machine with a device blurs on the device
	 without this method naming a Vulkan class."

	| alphaSurface alphaCanvas |
	alphaSurface := cairoSurface
		                newSimilarImageFormat: VGCairoSurfaceFormat a8
		                width: extent x
		                height: extent y.
	alphaSurface status ensureIsSuccess.
	alphaCanvas := self class newFor: alphaSurface.
	aBlock value: alphaCanvas.
	VGBackend preferredClass blurFilterClass new
		surface: alphaSurface;
		applyRadius: width.
	^ alphaSurface
]

{ #category : 'API - source' }
VGCanvas >> setSourceLinearPatternStops: aCollection start: startPoint end: endPoint [

	cairoContext sourcePattern: (VGCairoLinearGradientPattern
			 from: startPoint
			 to: endPoint
			 addStopsFrom: aCollection)
]

{ #category : 'API - source' }
VGCanvas >> setSourceRadialPatternStops: aCollection innerCenter: anInnerCenter innerRadius: anInnerRadius outerCenter: anOuterCenter outerRadius: anOuterRadius [

	cairoContext sourcePattern: (VGCairoRadialGradientPattern
			 innerCenter: anInnerCenter
			 innerRadius: anInnerRadius
			 outerCenter: anOuterCenter
			 outerRadius: anOuterRadius
			 addStopsFrom: aCollection)
]
