"
I am an `AeCanvas` whose fonts are this project's, and I decide nothing else.

Bloc asks a canvas for a scaled font before it measures or draws any text, and the answer decides which code reads the outlines. A canvas of mine answers a `VGScaledFont`, under a font matrix and a rendering options record of ours, and keeps one per face and size — the inherited method returns from inside its own `ifAbsentPut:` block, so its cache is written and never read.

My two subclasses part on what draws the pixels, not on what reads the fonts: `VGCanvas` draws them with this project's rasteriser, `VGAeCanvas` leaves them to Cairo.

I am abstract. The face Bloc hands over is already one of ours, because the font manager posed for the image is ours, so I hand it to the scaled font untouched. Until unit 5.2 of the font plan a subclass could be handed a FreeType face instead, and `fontFaceFor:` was mine to ask and theirs to answer; that was the last thing my subclasses parted on in the font path.
"
Class {
	#name : 'VGFontCanvas',
	#superclass : 'AeCanvas',
	#category : 'VectorGraphics-Bloc-Backend',
	#package : 'VectorGraphics-Bloc',
	#tag : 'Backend'
}

{ #category : 'accessing - quality' }
VGFontCanvas class >> highQualityFontOptions [
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
VGFontCanvas class >> highQualityTolerance [
	"The flattening tolerance Alexandrie sets for a window drawn at scale one, in device pixels."

	^ 0.2
]

{ #category : 'inspector' }
VGFontCanvas class >> inspectorSeams: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Seams'>
	"The whole seam between Bloc's canvas and a backend, asked of the code rather than listed
	 here; `seamRows` reads it and `overridesUpstreamSelector:` answers the last column. Every
	 canvas of ours offers the tab, and each one answers it for itself: `VGFontCanvas` replaces
	 the font methods alone, its subclasses the surface and pattern ones too."

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
					   (self overridesUpstreamSelector: each key) printString ]);
		  yourself
]

{ #category : 'accessing - quality' }
VGFontCanvas class >> lowQualityFontOptions [
	"Hinting off, the four values `AeCanvas class >> initializeFontOptions` puts in its own low
	 quality record."

	^ VGFontOptions new
		  antialias: #fast;
		  hintMetrics: #off;
		  hintStyle: #none;
		  yourself
]

{ #category : 'accessing - quality' }
VGFontCanvas class >> lowQualityTolerance [
	"The flattening tolerance Alexandrie sets for a window drawn at a scale above one."

	^ 0.5
]

{ #category : 'seam' }
VGFontCanvas class >> ourClassesBelowAlexandrie [
	"My class and the ones above it, up to Alexandrie's canvas, that one excluded: the stretch of
	 the hierarchy that holds our own overrides. Since unit 5.1 of the font plan it is two classes
	 under `VGCanvas` and under `VGAeCanvas`, and one under `VGFontCanvas` itself."

	^ self withAllSuperclasses copyUpTo: AeCanvas
]

{ #category : 'seam' }
VGFontCanvas class >> ourOverriddenUpstreamSelectors [
	"Every selector `AeCanvas` implements, on either side, that a canvas of ours on the stretch
	 below it replaces."

	| selectors |
	selectors := Set new.
	self ourClassesBelowAlexandrie do: [ :ourClass |
		(ourClass methods , ourClass class methods) do: [ :each |
			((AeCanvas includesSelector: each selector) or: [
				 AeCanvas class includesSelector: each selector ]) ifTrue: [
				selectors add: each selector ] ] ].
	^ selectors
]

{ #category : 'seam' }
VGFontCanvas class >> overridesUpstreamSelector: aSelector [
	"Whether a canvas of ours replaces the upstream method named by the selector, on either side.
	 The question is asked of the whole stretch from this class up to Alexandrie's canvas, that
	 one excluded, because the font methods sit on `VGFontCanvas` and the surface and pattern ones
	 on its subclasses. A selector nothing of ours implements reaches Cairo's own FreeType."

	^ self ourClassesBelowAlexandrie anySatisfy: [ :each |
		  (each includesSelector: aSelector) or: [
			  each class includesSelector: aSelector ] ]
]

{ #category : 'seam' }
VGFontCanvas class >> seamRows [
	"Every method of `AeCanvas` that names a class of the Cairo package, and every method of it
	 that a canvas of ours between this class and `AeCanvas` overrides, as selector to
	 named-classes associations sorted by selector. A creation method added upstream appears with
	 nothing named against it, which is what a hole in the failover looks like."

	| rows |
	rows := self upstreamCairoRows.
	self ourOverriddenUpstreamSelectors do: [ :selector |
		rows at: selector ifAbsentPut: [ #(  ) ] ].
	^ (rows associations asSortedCollection: [ :a :b | a key <= b key ])
		  asOrderedCollection
]

{ #category : 'seam' }
VGFontCanvas class >> upstreamCairoRows [
	"Every method of `AeCanvas`, on either side, that names a class of the Cairo package, as a
	 dictionary from selector to the classes that method names."

	| scanner rows |
	scanner := VGCairoReferenceScanner new.
	rows := Dictionary new.
	(AeCanvas methods , AeCanvas class methods) do: [ :each |
		(scanner cairoClassesNamedBy: each) ifNotEmpty: [ :named |
			rows at: each selector put: named ] ].
	^ rows
]

{ #category : 'accessing' }
VGFontCanvas >> fontOptions [
	"`AeCanvas` holds its font options in an instance variable with no reader, and the failover
	 has to be able to state that ours are never Cairo's record."

	^ fontOptions
]

{ #category : 'initialization' }
VGFontCanvas >> initialize [
	"The inherited method leaves the font options nil until the canvas is prepared for a surface,
	 and a scaled font can be asked for before that, when text is measured without a window."

	super initialize.
	fontOptions := self class highQualityFontOptions
]

{ #category : 'inspector' }
VGFontCanvas >> inspectorBackend: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Backend'>
	"What this canvas is drawing on and with, all of it ours: the surface, the device scale it
	 carries, our own font options, and the caches `inspectorBackendProperties` lists. The caches
	 are asked for their size, so a bridge that stopped caching shows here as a growing or an
	 empty table."

	^ aBuilder newTable
		  items: self inspectorBackendProperties;
		  addColumn: (SpStringTableColumn
				   title: 'Property'
				   evaluated: [ :each | each key ]);
		  addColumn: (SpStringTableColumn
				   title: 'Value'
				   evaluated: [ :each | each value printString ]);
		  yourself
]

{ #category : 'inspector' }
VGFontCanvas >> inspectorBackendContext: aContext [
	"A canvas built without a surface holds no caches yet, and the device scale is read from the
	 surface."

	aContext active: cairoSurface notNil
]

{ #category : 'inspector' }
VGFontCanvas >> inspectorBackendProperties [
	"The rows of the Backend tab: what every canvas of ours draws on and with. A subclass that
	 keeps a cache of its own appends a row for it."

	^ {
		  ('Surface' -> cairoSurface class).
		  ('Surface extent' -> (cairoSurface
			   ifNil: [ nil ]
			   ifNotNil: [ :surface | surface extent ])).
		  ('Device scale' -> self deviceScale).
		  ('Font options' -> fontOptions).
		  ('Scaled fonts cached' -> scaledFontCache size) }
]

{ #category : 'API - text' }
VGFontCanvas >> scaledFontForFace: aFace size: size [
	"Answer a `VGScaledFont` for the face and size Bloc asked for. The inherited method sends
	 `newCairoFontFace` to the face, which is the one place where the backend is reached without
	 a Cairo class being named anywhere in the source.

	 The inherited method also returns from inside the `ifAbsentPut:` block, so its cache never
	 fills and every text run rebuilds its scaled font; the cache works here.

	 The face is used as it arrives. Until unit 5.2 of the font plan a subclass could be handed a
	 FreeType face instead, and `fontFaceFor:` was where it said how it recovered the bytes
	 behind one; the manager posed for the image is ours now, so what arrives is already one of
	 our faces."

	^ scaledFontCache
		  at: {
				  aFace.
				  size }
		  ifAbsentPut: [
			  VGScaledFont
				  fontFace: aFace
				  fontMatrix: (VGCairoMatrix newScalingByX: size y: size)
				  userToDeviceMatrix: deviceScaleMatrix
				  options: fontOptions ]
]

{ #category : 'initialization' }
VGFontCanvas >> setHighQualityOptions [
	"The inherited method assigns a shared `AeCairoFontOptions`, which is a Cairo object: reading
	 any of its four fields is a foreign call into the library this project replaces. Our own
	 record holds the same four values."

	cairoContext
		tolerance: self class highQualityTolerance;
		antialias: #fast.
	fontOptions := self class highQualityFontOptions
]

{ #category : 'initialization' }
VGFontCanvas >> setLowQualityOptions [
	"Set when the host window draws at a scale factor above one, where the extra samples would be
	 thrown away by the downscale. The inherited method assigns a shared Cairo record; see
	 `setHighQualityOptions`."

	cairoContext
		tolerance: self class lowQualityTolerance;
		antialias: #fast.
	fontOptions := self class lowQualityFontOptions
]
