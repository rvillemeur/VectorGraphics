"
I am an `AeCanvas` that builds this project's objects instead of Cairo's.

Bloc draws through an `AeCanvas`, and almost every method of that class is backend independent: it
records a path, a paint or a clip and sends it on to whatever context it holds. Only six methods
reach the backend by building one of its objects, and I override exactly those six: the two that
build a surface, the two that build a gradient pattern, the one that builds the blurred alpha
surface of a shadow, and the one that builds a scaled font.

The sixth is the awkward one. It names no Cairo class at all; it sends `newCairoFontFace` to the
FreeType face Bloc hands over, so the Cairo call hides inside the face. That face carries a family
name and a style name but no bytes, so `faceForFreeTypeFace:` matches it against the font manager's
own entries to find the file or the memory it came from, and keeps one `VGFontFace` per family and
style so that two scaled fonts of one family share a glyph cache.

My instance side holds no state of its own: everything I override reads the inherited instance
variables, which is the point — the canvas stays Alexandrie's and only the objects change.
"
Class {
	#name : 'VGCanvas',
	#superclass : 'AeCanvas',
	#classInstVars : [
		'faceCache'
	],
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

{ #category : 'accessing' }
VGCanvas class >> faceCache [
	"One font face per family and style, so that two scaled fonts of one family share a glyph
	 cache. The font manager has a cache of its own, but it is three entries deep and it holds
	 FreeType faces, which are the thing we are replacing."

	^ faceCache ifNil: [ faceCache := Dictionary new ]
]

{ #category : 'font bridge' }
VGCanvas class >> faceForFreeTypeFace: anAeFTFace [
	"Bloc hands the canvas a FreeType face, which carries a family name and a style name and no
	 bytes. The face answers the resolution; the canvas adds the cache, so a family and style
	 pair is read from the font manager once however many frames ask for it."

	^ self faceCache
		  at: {
				  anAeFTFace familyName.
				  anAeFTFace styleName }
		  ifAbsentPut: [ VGFontFace newForFace: anAeFTFace ]
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

{ #category : 'accessing - quality' }
VGCanvas class >> highQualityFontOptions [
	"Hinted metrics and slight hinting, the four values `AeCanvas class >> initializeFontOptions`
	 puts in its own high quality record. One record is shared, because the options are read and
	 never changed."

	^ VGFontOptions new
		  antialias: #fast;
		  hintMetrics: #on;
		  hintStyle: #slight;
		  yourself
]

{ #category : 'accessing - quality' }
VGCanvas class >> highQualityTolerance [
	"The flattening tolerance Alexandrie sets for a window drawn at scale one, in device pixels."

	^ 0.2
]

{ #category : 'inspector' }
VGCanvas class >> inspectorSeams: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Seams'>
	"The whole seam between Bloc''s canvas and a backend, asked of the code rather than listed
	 here; `seamRows` reads it."

	^ aBuilder newTable
		  items: self seamRows;
		  addColumn: (SpStringTableColumn
				   title: 'Selector'
				   evaluated: [ :each | each key ]);
		  addColumn: (SpStringTableColumn
				   title: 'Cairo classes named upstream'
				   evaluated: [ :each |
					   ((each value collect: [ :class | class name ]) asSortedCollection: [
						    :a :b | a <= b ]) asArray printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Overridden here'
				   evaluated: [ :each |
					   ((self includesSelector: each key) or: [
						    self class includesSelector: each key ]) printString ]);
		  yourself
]

{ #category : 'inspector' }
VGCanvas class >> inspectorSeamsContext: aContext [
	"The seam is a fact about this class and its superclass, so the tab belongs to the class that
	 subclasses Bloc's own canvas and not to anything below it."

	aContext active: self superclass = AeCanvas
]

{ #category : 'accessing - quality' }
VGCanvas class >> lowQualityFontOptions [
	"Hinting off, the four values `AeCanvas class >> initializeFontOptions` puts in its own low
	 quality record."

	^ VGFontOptions new
		  antialias: #fast;
		  hintMetrics: #off;
		  hintStyle: #none;
		  yourself
]

{ #category : 'accessing - quality' }
VGCanvas class >> lowQualityTolerance [
	"The flattening tolerance Alexandrie sets for a window drawn at a scale above one."

	^ 0.5
]

{ #category : 'caching' }
VGCanvas class >> resetFaceCache [
	<script>
	faceCache := nil
]

{ #category : 'reflection' }
VGCanvas class >> seamRows [
	"Every method of `AeCanvas` that names a class of the Cairo package, and every method of it
	 this class overrides, as selector to named-classes associations sorted by selector. A creation
	 method added upstream appears with nothing named against it, which is what a hole in the
	 failover looks like."

	| scanner rows |
	scanner := VGCairoReferenceScanner new.
	rows := Dictionary new.
	(AeCanvas methods , AeCanvas class methods) do: [ :each |
		(scanner cairoClassesNamedBy: each) ifNotEmpty: [ :named |
			rows at: each selector put: named ] ].
	((self methods , self class methods) select: [ :each |
		 (AeCanvas includesSelector: each selector) or: [
			 AeCanvas class includesSelector: each selector ] ]) do: [ :each |
		rows at: each selector ifAbsentPut: [ #(  ) ] ].
	^ (rows associations asSortedCollection: [ :a :b | a key <= b key ])
		  asOrderedCollection
]

{ #category : 'accessing' }
VGCanvas >> fontOptions [
	"`AeCanvas` holds its font options in an instance variable with no reader, and the failover
	 has to be able to state that ours are never Cairo's record."

	^ fontOptions
]

{ #category : 'initialization' }
VGCanvas >> initialize [
	"The inherited method leaves the font options nil until the canvas is prepared for a surface,
	 and a scaled font can be asked for before that, when text is measured without a window."

	super initialize.
	fontOptions := self class highQualityFontOptions
]

{ #category : 'inspector' }
VGCanvas >> inspectorBackend: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Backend'>
	"What this canvas is drawing on and with, all of it ours: the surface, the device scale it
	 carries, our own font options, and the two caches the font bridge fills. The caches are
	 asked for their size, so a bridge that stopped caching shows here as a growing or an empty
	 table."

	^ aBuilder newTable
		  items: {
				  ('Surface' -> cairoSurface class).
				  ('Surface extent' -> (cairoSurface
					    ifNil: [ nil ]
					    ifNotNil: [ :surface | surface extent ])).
				  ('Device scale' -> self deviceScale).
				  ('Font options' -> fontOptions).
				  ('Scaled fonts cached' -> scaledFontCache size).
				  ('Faces cached' -> self class faceCache size) };
		  addColumn: (SpStringTableColumn
				   title: 'Property'
				   evaluated: [ :each | each key ]);
		  addColumn: (SpStringTableColumn
				   title: 'Value'
				   evaluated: [ :each | each value printString ]);
		  yourself
]

{ #category : 'inspector' }
VGCanvas >> inspectorBackendContext: aContext [
	"A canvas built without a surface holds no caches yet, and the device scale is read from the
	 surface."

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

{ #category : 'API - text' }
VGCanvas >> scaledFontForFace: aFace size: size [
	"Answer a `VGScaledFont` for the FreeType face and size Bloc asked for. The inherited method
	 sends `newCairoFontFace` to the face, which is the one place where the backend is reached
	 without a Cairo class being named anywhere in the source.
	 The inherited method also returns from inside the `ifAbsentPut:` block, so its cache never
	 fills and every text run rebuilds its scaled font; the cache works here."

	^ scaledFontCache
		  at: {
				  aFace.
				  size }
		  ifAbsentPut: [
			  VGScaledFont
				  fontFace: (self class faceForFreeTypeFace: aFace)
				  fontMatrix: (VGCairoMatrix newScalingByX: size y: size)
				  userToDeviceMatrix: deviceScaleMatrix
				  options: fontOptions ]
]

{ #category : 'initialization' }
VGCanvas >> setHighQualityOptions [
	"The inherited method assigns a shared `AeCairoFontOptions`, which is a Cairo object: reading
	 any of its four fields is a foreign call into the library this project replaces. Our own
	 record holds the same four values."

	cairoContext
		tolerance: self class highQualityTolerance;
		antialias: #fast.
	fontOptions := self class highQualityFontOptions
]

{ #category : 'initialization' }
VGCanvas >> setLowQualityOptions [
	"Set when the host window draws at a scale factor above one, where the extra samples would be
	 thrown away by the downscale. The inherited method assigns a shared Cairo record; see
	 `setHighQualityOptions`."

	cairoContext
		tolerance: self class lowQualityTolerance;
		antialias: #fast.
	fontOptions := self class lowQualityFontOptions
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
