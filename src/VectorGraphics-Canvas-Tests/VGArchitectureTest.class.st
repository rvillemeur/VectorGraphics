"
I hold the agreed layering of this project: which package may name a class of which other package, and which packages each group of the baseline loads.

The table is VGArchitectureTest class >> allowedDependencies, one entry per package, and my tests fail both when a package makes an edge the table does not grant and when the table grants an edge the code no longer makes, so the table cannot drift into a description of the project history.

I also hold the table against the organiser, against BaselineOfVectorGraphics and against a fixture that plants a reference three blocks deep, because a scan that reads only a method own literals misses every reference inside a block.

The second fact is mine since the renderer left the default group: no package the default group loads may name a class of Bloc or of Alexandrie and no class of those packages may inherit from one, so this project rasterises in an image where neither is present. The bloc group loads everything the default group loads plus the renderer, so using it as Alexandrie's replacement inside Bloc stays one Metacello load, and the cairo-examples and cairo-tests groups load without Bloc as well — of Alexandrie they are allowed, because the conformance gate compares this rasteriser with live Cairo and a comparison needs that positive control. Each test asks the same question of a group that must answer yes, so an empty answer cannot come from a walk that finds nothing at all. My class-side Groups tab shows every group live, and VGArchitectureTest class >> replacedStackPackageNames and >> blocPackageNames read the stack from the organiser by prefix.

Two project-wide rules are not mine and stay where they were written: VGBackendSelectionTest holds that only the Vulkan family names a PharoVulkan class, through VGCairoReferenceScanner, and that every package of this project is named in the baseline.

I live in VectorGraphics-Cairo-Tests rather than in a package of my own, since this project has no aggregate test package and a new package would owe the baseline and the profiling stage table an entry for one class.
"
Class {
	#name : 'VGArchitectureTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Canvas-Tests-Tests',
	#package : 'VectorGraphics-Canvas-Tests',
	#tag : 'Tests'
}

{ #category : 'layering' }
VGArchitectureTest class >> allowedDependencies [
	"The outgoing package references each package of this project may make, keyed by package
	 name. This table is the agreement: a package missing from it is one nobody has placed in
	 the layering, and an edge missing from a set is a dependency nobody has agreed to. My tests
	 fail on either, so adding a dependency means stating it here and in the baseline first.
	 The rule that only the Vulkan family may name a PharoVulkan class is held elsewhere, by
	 VGBackendSelectionTest through VGCairoReferenceScanner, so no edge out of this project
	 appears here.
	 An edge is a reference one package's methods make to another's classes, which is not the
	 same as what a package needs in order to load: the four documentation gates subclass
	 VectorGraphicsDocumentationTest without naming it in a method, so the baseline declares
	 that edge and this table cannot."
	^ Dictionary newFrom: {
			  "The front page holds no code since the split, only the package comment that says
			   which package holds what, so it names nothing and nothing names it."
			  'VectorGraphics' -> #(  ).
			  "The rasteriser, in four packages. Paths is the command language, Engine the
			   scan-line rasteriser, TrueType the font reader, Text the glue that lets the one
			   draw the other: no edge runs from Engine to TrueType or back, which is what the
			   split was for."
			  'VectorGraphics-Paths' -> #(  ).
			  'VectorGraphics-Paths-Examples'
			  -> #( 'VectorGraphics-Engine' 'VectorGraphics-Paths' ).
			  'VectorGraphics-Paths-Tests'
			  -> #( 'VectorGraphics-Paths' 'VectorGraphics-Paths-Examples' ).
			  'VectorGraphics-Engine' -> #(  ).
			  'VectorGraphics-Engine-Examples' -> #( 'VectorGraphics-Engine' ).
			  "The engine tests run paths through the engine, which is what the engine is for,
			   and the paths examples draw into a canvas, so both name the other layer. Neither
			   edge is one the code itself makes."
			  'VectorGraphics-Engine-Tests'
			  -> #( 'VectorGraphics-Engine' 'VectorGraphics-Engine-Examples' 'VectorGraphics-Paths' ).
			  'VectorGraphics-TrueType' -> #( 'VectorGraphics-Paths' ).
			  'VectorGraphics-TrueType-Examples' -> #( 'VectorGraphics-TrueType' ).
			  "The font tests read a glyph as path commands and name no engine class: a font can
			   be parsed and measured with no rasteriser in the image."
			  'VectorGraphics-TrueType-Tests'
			  -> #( 'VectorGraphics-Paths' 'VectorGraphics-TrueType'
				    'VectorGraphics-TrueType-Examples' ).
			  "Text is six extension methods on classes of the two packages it joins, so it
			   holds no class of its own and nothing can name it."
			  'VectorGraphics-Text' -> #( 'VectorGraphics-Engine' 'VectorGraphics-TrueType' ).
			  'VectorGraphics-Text-Examples'
			  -> #( 'VectorGraphics-Engine' 'VectorGraphics-TrueType' ).
			  'VectorGraphics-Text-Tests'
			  -> #( 'VectorGraphics-Engine' 'VectorGraphics-Text-Examples'
				    'VectorGraphics-TrueType' ).
			  "The abstract documentation gate the four concrete ones subclass. It reads its
			   package from the subclass hook and the organiser, so it names no package of ours."
			  'VectorGraphics-Tests' -> #(  ).
			  "The canvas, in four packages: three since the split of 2026-11 and the geometry
			   leaf since unit 3 of FONTS-LOAD-PLAN. VectorGraphics-Canvas is the API a drawing
			   is written against and the display list it records; VectorGraphics-Canvas-Raster
			   is the renderer that turns that list into pixels, which needs no device, no
			   library and no window; VectorGraphics-Canvas-Fonts is the font and glyph layer, a
			   leaf above the font reader that names nothing else of this project;
			   VectorGraphics-Canvas-Geometry holds the path and the matrix both routes measure
			   and map with.
			   The renderer names no package of this project. The four references it made to
			   the canvas were the deferred review point of the split, and unit 8 removed
			   them: the default antialias is a constant of the renderer itself and the colour
			   conversion is a Color extension the renderer owns."
			  'VectorGraphics-Canvas'
			  -> #( 'VectorGraphics-Canvas-Fonts' 'VectorGraphics-Canvas-Geometry'
				    'VectorGraphics-Canvas-Raster' ).
			  'VectorGraphics-Canvas-Raster' -> #( ).
			  'VectorGraphics-Canvas-Fonts' -> #( 'VectorGraphics-TrueType' ).
			  "The geometry, a leaf of its own since unit 1 of FONTS-LOAD-PLAN and named for what
			   it holds since unit 3: a path, its subpaths, the builder that records one, and the
			   matrix a point is mapped by. It names nothing. The two methods that read the
			   segments of a rasterised path are extensions the rasteriser owns, and #invert and
			   #inverted are extensions the canvas owns, because the status they answer is a
			   class of VectorGraphics-Canvas. The cairo route loads this package without the
			   canvas, which is what the plan was for."
			  'VectorGraphics-Canvas-Geometry' -> #(  ).
			  'VectorGraphics-Canvas-Geometry-Examples'
			  -> #( 'VectorGraphics-Canvas' 'VectorGraphics-Canvas-Geometry' ).
			  'VectorGraphics-Canvas-Geometry-Tests'
			  -> #( 'VectorGraphics-Canvas' 'VectorGraphics-Canvas-Geometry'
				    'VectorGraphics-Canvas-Raster' ).
			  "Each of the three has its examples and its tests package, as of unit 6.6 of the
			   split: a test or an examples class belongs to the package of its subject, so the
			   layering the trio has is the layering its mirrors have.
			   An examples class names its subject. These examples open the conformance corpora,
			   the Form comparison and the font lifetime, which live in VectorGraphics-Conformance
			   since the review of 2026-11. The one edge left from the examples to the test
			   package is VGArchitectureExamples, whose subject is the architecture gate itself,
			   and it is the half of that cycle the baseline leaves out."
			  'VectorGraphics-Canvas-Examples'
			  -> #( 'VectorGraphics-Canvas' 'VectorGraphics-Canvas-Geometry'
				    'VectorGraphics-Canvas-Geometry-Examples'
				    'VectorGraphics-Canvas-Raster'
				    'VectorGraphics-Canvas-Tests'
				    'VectorGraphics-Conformance' ).
			  "The canvas tests name every mirror below them, and the tests of the renderer as
			   well: the frame fixture and the backend stubs are the renderer's, and a canvas
			   test that draws a frame builds it through them rather than keeping a second copy."
			  'VectorGraphics-Canvas-Tests'
			  -> #( 'VectorGraphics-Canvas' 'VectorGraphics-Canvas-Examples'
				    'VectorGraphics-Canvas-Fonts-Examples'
				    'VectorGraphics-Canvas-Geometry'
				    'VectorGraphics-Canvas-Geometry-Examples'
				    'VectorGraphics-Canvas-Raster'
				    'VectorGraphics-Canvas-Raster-Examples'
				    'VectorGraphics-Canvas-Raster-Tests'
				    'VectorGraphics-Conformance' 'VectorGraphics-Reflection'
				    'VectorGraphics-Reflection-Examples' ).
			  'VectorGraphics-Canvas-Raster-Examples'
			  -> #( 'VectorGraphics-Canvas' 'VectorGraphics-Canvas-Geometry'
				    'VectorGraphics-Canvas-Geometry-Examples' 'VectorGraphics-Canvas-Raster' ).
			  'VectorGraphics-Canvas-Raster-Tests'
			  -> #( 'VectorGraphics-Canvas' 'VectorGraphics-Canvas-Geometry'
				    'VectorGraphics-Canvas-Raster' 'VectorGraphics-Conformance'
				    'VectorGraphics-Reflection' ).
			  "The font examples of the canvas name the font catalogue of the reader, which is where
			   this project states where a platform keeps its fonts. Scanning a directory list of
			   their own made these examples examples of one machine: a single Linux font directory
			   exists on that platform alone, so the face, the scaled font and the atlas showed
			   nothing on macOS and on Windows."
			  'VectorGraphics-Canvas-Fonts-Examples'
			  -> #( 'VectorGraphics-Canvas' 'VectorGraphics-Canvas-Fonts'
				    'VectorGraphics-Canvas-Geometry'
				    'VectorGraphics-Conformance' 'VectorGraphics-TrueType' ).
			  "The font tests of the canvas name the font reader and its fixtures since the
			   glyph source of review point 4: the flags of a composite glyph record are
			   TTGlyfGlyphSource's constants now, and VGFontBytesFixture, which builds a font
			   byte by byte, moved to VectorGraphics-TrueType-Tests so the tests of a source can
			   read it too."
			  'VectorGraphics-Canvas-Fonts-Tests'
			  -> #( 'VectorGraphics-Canvas' 'VectorGraphics-Canvas-Fonts'
				    'VectorGraphics-Canvas-Fonts-Examples'
				    'VectorGraphics-Canvas-Geometry'
				    'VectorGraphics-Conformance' 'VectorGraphics-Reflection'
				    'VectorGraphics-TrueType' 'VectorGraphics-TrueType-Tests' ).
			  "The reference scan, a leaf of its own since unit 2 of FONTS-LOAD-PLAN. It reads the
			   compiled methods of a package and answers the classes of another project they
			   name, so it is a tool every layer may ask and it names nothing itself. It left the
			   canvas because the cairo route reads it through VGFontCanvas, and the canvas is
			   not on that route."
			  'VectorGraphics-Reflection' -> #(  ).
			  'VectorGraphics-Reflection-Examples' -> #( 'VectorGraphics-Reflection' ).
			  "The Bloc renderer of the software canvas: it names the canvas, the rasteriser and
			   the reference scan, and since unit 3 of FONTS-LOAD-PLAN nothing of the cairo
			   route. VGCanvas has its superclass in VectorGraphics-Bloc-Text, so the baseline
			   declares that edge and this table cannot: a superclass is not a reference a method
			   makes. The examples and the tests name that route, because a canvas example
			   installs a font manager before it draws text, and they name no renderer class:
			   they build a canvas and let it name the renderer."
			  'VectorGraphics-Bloc'
			  -> #( 'VectorGraphics-Canvas' 'VectorGraphics-Canvas-Raster'
				    'VectorGraphics-Reflection' ).
			  'VectorGraphics-Bloc-Examples'
			  -> #( 'VectorGraphics-Bloc' 'VectorGraphics-Bloc-Text'
				    'VectorGraphics-Canvas-Fonts' 'VectorGraphics-TrueType' ).
			  'VectorGraphics-Bloc-Tests'
			  -> #( 'VectorGraphics-Bloc' 'VectorGraphics-Bloc-Examples'
				    'VectorGraphics-Bloc-Text' 'VectorGraphics-Bloc-Text-Examples'
				    'VectorGraphics-Bloc-Text-Tests' 'VectorGraphics-Canvas'
				    'VectorGraphics-Canvas-Fonts' 'VectorGraphics-Canvas-Geometry'
				    'VectorGraphics-Canvas-Raster' 'VectorGraphics-Reflection'
				    'VectorGraphics-TrueType' ).
			  "The cairo text route, eight classes and ten extension methods on the classes of
			   Alexandrie, which both canvases of this project share: the canvas that answers a
			   scaled font of ours, the font manager posed in the slot every face is resolved
			   through, and the cairo canvas, offscreen, renderer, context and font that draw text
			   with it. It names the font layer, the geometry, the font reader and the reference
			   scan, and no canvas, no rasteriser and no other Bloc package of this project, which
			   is what the fonts group loads it for. Its mirrors name VectorGraphics-Bloc, where
			   the headless host a measuring run poses lives.
			   It is a package of its own since unit 3 of FONTS-LOAD-PLAN, where the eight classes
			   left VectorGraphics-Bloc and the install hook stayed behind in
			   VectorGraphics-Bloc-FontEngine: VectorGraphics-Bloc needs this route for the
			   superclass of VGCanvas, and loading the software canvas must pose nothing."
			  'VectorGraphics-Bloc-Text'
			  -> #( 'VectorGraphics-Canvas-Fonts' 'VectorGraphics-Canvas-Geometry'
				    'VectorGraphics-Reflection' 'VectorGraphics-TrueType' ).
			  'VectorGraphics-Bloc-Text-Examples'
			  -> #( 'VectorGraphics-Bloc' 'VectorGraphics-Bloc-Text'
				    'VectorGraphics-Canvas-Fonts' 'VectorGraphics-Canvas-Geometry' ).
			  'VectorGraphics-Bloc-Text-Tests'
			  -> #( 'VectorGraphics-Bloc' 'VectorGraphics-Bloc-Text'
				    'VectorGraphics-Bloc-Text-Examples' 'VectorGraphics-Canvas-Fonts'
				    'VectorGraphics-Canvas-Geometry' 'VectorGraphics-TrueType' ).
			  "The font engine is one class and the hook that sends install to it: the fonts group
			   poses the route as it loads, and the bloc group, which loads that route for the
			   superclass of VGCanvas, poses nothing. So the engine names the route and nothing
			   else, its examples name it and the font reader they draw a word of text with, and
			   its tests name the route as well, because what install writes is read back from the
			   slots of that package."
			  'VectorGraphics-Bloc-FontEngine' -> #( 'VectorGraphics-Bloc-Text' ).
			  'VectorGraphics-Bloc-FontEngine-Examples'
			  -> #( 'VectorGraphics-Bloc-FontEngine' 'VectorGraphics-TrueType' ).
			  'VectorGraphics-Bloc-FontEngine-Tests'
			  -> #( 'VectorGraphics-Bloc-FontEngine' 'VectorGraphics-Bloc-FontEngine-Examples'
				    'VectorGraphics-Bloc-Text' 'VectorGraphics-Canvas-Fonts'
				    'VectorGraphics-TrueType' ).
			  "The device path reads the frame unit 1.11 profiles, which is drawn through the Bloc
			   renderer, so binning and the budget name that package as well as the display list.
			   The three Vulkan sets are read from their Tonel files, since no image this project
			   is developed in loads them: none of the three names a class of the font layer."
			  'VectorGraphics-Vulkan'
			  -> #( 'VectorGraphics-Bloc' 'VectorGraphics-Canvas'
				    'VectorGraphics-Canvas-Raster' ).
			  "The budget — the two benchmarks and the drawing kit — lives in
			   VectorGraphics-Benchmarks, a package of its own since the review of 2026-11, so the
			   examples that open a benchmark name no test package."
			  'VectorGraphics-Vulkan-Examples'
			  -> #( 'VectorGraphics-Benchmarks' 'VectorGraphics-Bloc' 'VectorGraphics-Canvas'
				    'VectorGraphics-Canvas-Raster' 'VectorGraphics-Vulkan' ).
			  "One edge to a canvas test package: the backend tests draw the frame fixture of the
			   renderer's tests rather than keeping a second copy of it. VGVulkanExamplesTest
			   subclasses VGCairoExamplesTest, which is the canvas's, but a superclass is not a
			   reference a method makes, so that edge is the baseline's to declare and not this
			   table's. The geometry leaf is named because VGGradientFrameFixture maps a pattern
			   through VGCairoMatrix, which moved there with unit 3 of FONTS-LOAD-PLAN."
			  'VectorGraphics-Vulkan-Tests'
			  -> #( 'VectorGraphics-Benchmarks' 'VectorGraphics-Bloc'
				    'VectorGraphics-Canvas' 'VectorGraphics-Canvas-Geometry'
				    'VectorGraphics-Canvas-Raster'
				    'VectorGraphics-Canvas-Raster-Tests'
				    'VectorGraphics-Conformance' 'VectorGraphics-Vulkan'
				    'VectorGraphics-Vulkan-Examples' ).
			  "Neither of these two holds a TestCase, and both were filed in a -Tests package until
			   the review of 2026-11, which made an examples package depend on a test package. The
			   corpus names the canvas it is compared against; the benchmarks name the corpus they
			   measure and the backends they drive."
			  "The corpus names the font reader since unit 5.2 of the font plan: the experiments
			   ported from Alexandrie read their font out of a TTFontCatalogue, where they read it
			   out of the global FreeType font manager before. It names no Bloc class, because the
			   canvas groups load it and bring no Bloc package. The benchmarks name no font class:
			   they measure a frame of the corpus through a backend."
			  'VectorGraphics-Conformance'
			  -> #( 'VectorGraphics-Canvas' 'VectorGraphics-Canvas-Fonts'
				    'VectorGraphics-Canvas-Geometry'
				    'VectorGraphics-Canvas-Raster' 'VectorGraphics-TrueType' ).
			  'VectorGraphics-Benchmarks'
			  -> #( 'VectorGraphics-Bloc' 'VectorGraphics-Canvas'
				    'VectorGraphics-Canvas-Raster' 'VectorGraphics-Conformance'
				    'VectorGraphics-Vulkan' ).

			"The documentation package, which draws the architecture rather than taking part in it:
			  two inspector tabs, installed as extension methods on Pharo's Package and on
			  VGScaledFont, so no font class is edited for the sake of a picture. It names the font
			  packages it draws and nothing of this project names it, which is what keeps the
			  rasteriser loadable with no documentation and no Roassal in the image. Its edges out of
			  this project, to ArchDoc and Roassal, are the baseline's business and are named there."
			"The tabs are extension methods on a Package and on VGScaledFont, which the organiser
			  records and no method of this package names, so the documentation package makes no
			  reference edge at all. What it must load is another matter, and the baseline says it.
			  The examples do make one: the object graph of the Bloc side is walked from a real
			  VGFontManager, which is a class of VectorGraphics-Bloc-Text, so that edge is granted
			  here and required in the baseline. A documentation package that draws the font route
			  without the half where FreeType disappears would draw the lesser half."
			'VectorGraphics-Documentation' -> #(  ).
			'VectorGraphics-Documentation-Examples'
			-> #( 'VectorGraphics-Bloc-Text' 'VectorGraphics-Canvas-Fonts-Examples'
			      'VectorGraphics-Documentation' ).
			'VectorGraphics-Documentation-Tests'
			-> #( 'VectorGraphics-Canvas-Fonts' 'VectorGraphics-Canvas-Fonts-Examples'
			      'VectorGraphics-Documentation' 'VectorGraphics-Documentation-Examples' ) }
]

{ #category : 'layering' }
VGArchitectureTest class >> blocPackageNames [
	"Every package of Bloc present in this image, read from the organiser by prefix. Alexandrie
	 is left out, unlike replacedStackPackageNames: the Cairo test package names Alexandrie's
	 Cairo bindings on purpose, because the conformance gate proves this rasteriser matches
	 live Cairo and a comparison needs that positive control."

	^ (PackageOrganizer default packages select: [ :each |
		   each name beginsWith: 'Bloc' ]) collect: [ :each | each name asString ]
]

{ #category : 'layering' }
VGArchitectureTest class >> dependencyReport [
	"One row per package of this project: its name, the edges allowedDependencies grants it, the
	 edges it really makes, and the edges BaselineOfVectorGraphics declares for it. All four are
	 computed here, so a reader of the report and my tests cannot be looking at different
	 numbers."

	| declared |
	declared := Dictionary new.
	BaselineOfVectorGraphics project version packages do: [ :each |
		declared at: each name put: each requires asSet ].
	^ self projectPackageNames asSortedCollection asArray collect: [ :each |
		  {
			  each.
			  (self packageNameSeparator join:
					   (self allowedDependencies at: each ifAbsent: [ #(  ) ])
						   asSortedCollection).
			  (self packageNameSeparator join: (self edgesOf: each) asSortedCollection).
			  (self packageNameSeparator join:
					   (declared at: each ifAbsent: [ Set new ]) asSortedCollection) } ]
]

{ #category : 'layering' }
VGArchitectureTest class >> edgesOf: aPackageName [
	"The packages aPackageName own methods name, itself excluded. Asking the package for its
	 methods reads its extension methods on base classes too.
	 A package this image does not hold names nothing, and answers no edges rather than raising:
	 the walk is a reading of the image, and whether an absent package is a finding or a skip
	 belongs to the test that reads it."

	| package found |
	package := PackageOrganizer default
		           packageNamed: aPackageName
		           ifAbsent: [ ^ Set new ].
	found := Set new.
	package methods do: [ :method | found addAll: (self packagesNamedBy: method) ].
	^ found copyWithout: aPackageName
]

{ #category : 'accessing' }
VGArchitectureTest class >> edgesTheBaselineCannotDeclare [
	"The edges allowedDependencies grants and the baseline leaves out. Each is one half of a
	 cycle: the reverse edge is declared, so declaring this one as well would leave Metacello
	 with no load order. testEveryEdgeTheBaselineCannotDeclareIsOneHalfOfACycle reads the
	 reverse out of the baseline, so an edge nobody declared cannot hide here.
	 The canvas examples name the architecture test their own example opens, which is the
	 one edge left of the two the split had: the renderer's four references to the canvas
	 went in unit 8."

	^ {
		  ('VectorGraphics-Canvas-Examples' -> 'VectorGraphics-Canvas-Tests') }
]

{ #category : 'layering' }
VGArchitectureTest class >> groupReport [
	"One row per group of BaselineOfVectorGraphics: its name, the packages loading that group
	 brings in, and the classes of Bloc or Alexandrie those packages name. The packages come
	 from the spec and the classes from a live scan, so a reader of the report and
	 testNoPackageOfTheDefaultGroupNamesAClassOfTheStackItReplaces cannot be looking at
	 different numbers."

	| scanner |
	scanner := VGCairoReferenceScanner new.
	^ ((BaselineOfVectorGraphics project version groups collect: [ :each |
		    each name asString ]) asSortedCollection asArray) collect: [ :groupName |
		  | loaded named |
		  loaded := (self packagesLoadedByGroupNamed: groupName) asSortedCollection asArray.
		  named := Set new.
		  loaded do: [ :package |
			  (scanner
				   offendersIn: package
				   naming: self replacedStackPackageNames) do: [ :each |
				  each value do: [ :one | named add: one name asString ] ] ].
		  {
			  groupName.
			  (self packageNameSeparator join: loaded).
			  (self packageNameSeparator join: named asSortedCollection) } ]
]

{ #category : 'layering' }
VGArchitectureTest class >> inheritanceOfGroupNamed: aGroupName into: aCollectionOfPackageNames [
	"The links from a class of that group to a superclass or trait in one of those packages,
	 as 'Subject -> Behaviour' strings. A superclass and a trait are named by the class
	 definition, not by any method, so the literal scan of VGCairoReferenceScanner cannot see
	 them, and this is the link Metacello fails on first.
	 The group names what it loads, so a package of it this image does not hold is passed over:
	 the answer is the links of the classes that are there."

	| found |
	found := OrderedCollection new.
	(self loadedPackagesNamed: (self packagesLoadedByGroupNamed: aGroupName)) do: [
		:package |
		package definedClasses do: [ :each |
			| behaviours |
			behaviours := each allSuperclasses asOrderedCollection
				              addAll: each traits;
				              addAll: each class traits;
				              yourself.
			behaviours do: [ :one |
				(one package notNil and: [
					 aCollectionOfPackageNames includes: one package name asString ]) ifTrue: [
					found add: each name , ' -> ' , one name ] ] ] ].
	^ found asSortedCollection asArray
]

{ #category : 'inspecting' }
VGArchitectureTest class >> inspectorDependencies: aBuilder [
	"The granted, the real and the declared outgoing edges side by side, for every package of
	 this project. Reads dependencyReport, so the tab states what the table, a live scan and the
	 baseline say rather than a stored summary, and it mutates nothing it shows."

	<inspectorPresentationOrder: 10 title: 'Dependencies'>
	^ aBuilder newTable
		  addColumn: (SpStringTableColumn title: 'Package' evaluated: [ :each | each first ]);
		  addColumn: (SpStringTableColumn title: 'Granted' evaluated: [ :each | each second ]);
		  addColumn: (SpStringTableColumn title: 'Real' evaluated: [ :each | each third ]);
		  addColumn: (SpStringTableColumn title: 'Baseline' evaluated: [ :each | each fourth ]);
		  items: self dependencyReport;
		  yourself
]

{ #category : 'inspecting' }
VGArchitectureTest class >> inspectorDependenciesContext: aContext [
	"The tab belongs to whichever class in this hierarchy holds the table, which today is this
	 one and only one. Asking the table rather than naming the class keeps the gate true if a
	 second project ever subclasses me for its own layering."

	^ aContext active: self allowedDependencies notEmpty
]

{ #category : 'layering' }
VGArchitectureTest class >> inspectorGroups: aBuilder [
	"What each group of the baseline loads, and which classes of the stack this project
	 replaces those packages name. Reads groupReport, so the tab is a live scan of the image
	 the moment it opens: the default group's third cell is empty exactly while the project
	 loads in an image with no Bloc. It mutates nothing it shows."

	<inspectorPresentationOrder: 20 title: 'Groups'>
	^ aBuilder newTable
		  addColumn: (SpStringTableColumn title: 'Group' evaluated: [ :each | each first ]);
		  addColumn:
			  (SpStringTableColumn title: 'Loads' evaluated: [ :each | each second ]);
		  addColumn: (SpStringTableColumn
				   title: 'Names of Bloc or Alexandrie'
				   evaluated: [ :each | each third ]);
		  items: self groupReport;
		  yourself
]

{ #category : 'layering' }
VGArchitectureTest class >> inspectorGroupsContext: aContext [
	"The tab belongs to whichever class in this hierarchy reads the baseline's groups, which
	 today is this one and only one. Asking the baseline rather than naming the class keeps the
	 gate true if a second project ever subclasses me for its own layering."

	^ aContext active: BaselineOfVectorGraphics project version groups notEmpty
]

{ #category : 'inspecting' }
VGArchitectureTest class >> inspectorLoadedPackages: aBuilder [
	"Which packages of the dependency table this image holds, and which gate of mine reads each
	 one. A group loading part of the project - canvas-tests loads fifteen of the forty-five
	 packages the table names - leaves the rest absent, and the gates of those packages skip
	 rather than raise. This tab is where that is read: it names every row the table has, so a
	 run reporting forty-five tests of which twenty-one skipped is accounted for here. Reads
	 loadedPackageReport, a live scan, and mutates nothing it shows."

	<inspectorPresentationOrder: 30 title: 'Loaded'>
	^ aBuilder newTable
		  addColumn:
			  (SpStringTableColumn title: 'Package' evaluated: [ :each | each first ]);
		  addColumn: (SpStringTableColumn
				   title: 'In this image'
				   evaluated: [ :each | each second ]);
		  addColumn:
			  (SpStringTableColumn title: 'Its gate' evaluated: [ :each | each third ]);
		  items: self loadedPackageReport;
		  yourself
]

{ #category : 'inspecting' }
VGArchitectureTest class >> inspectorLoadedPackagesContext: aContext [
	"The tab belongs to whichever class in this hierarchy holds the dependency table, which
	 today is this one and only one. Asking the table rather than naming the class keeps the
	 gate true if a second project ever subclasses me for its own layering."

	^ aContext active: self allowedDependencies notEmpty
]

{ #category : 'layering' }
VGArchitectureTest class >> isPlatformPathOfAFont: aString [
	"Whether this string is an absolute path, of this platform or of another, naming a font or a
	 directory of fonts. The question is asked of a string literal rather than of source, so a
	 path inside a comment is no offence and a path the code really holds is."

	| absolute lowercase |
	absolute := (aString beginsWith: '/') or: [
		            aString size > 2 and: [ (aString at: 2) = $: ] ].
	absolute ifFalse: [ ^ false ].
	lowercase := aString asLowercase.
	^ (lowercase includesSubstring: 'font') or: [
		  #( '.ttf' '.otf' '.ttc' ) anySatisfy: [ :each |
			  lowercase endsWith: each ] ]
]

{ #category : 'accessing' }
VGArchitectureTest class >> isProductionPackageNamed: aPackageName [
	"Whether a package of this project is one a consumer loads to draw, as against one that
	 only this project runs. Tests and examples are out by their name; the conformance corpus
	 and the benchmarks are out because they are harnesses too, each holding fixtures of its
	 own."
	^ ((aPackageName endsWith: '-Tests') or: [
		   aPackageName endsWith: '-Examples' ]) not and: [
		  ((aPackageName endsWith: '-Conformance') or: [
			   aPackageName endsWith: '-Benchmarks' ]) not ]
]

{ #category : 'reporting' }
VGArchitectureTest class >> loadedPackageReport [
	"One row per package the dependency table names: the package, whether this image holds it,
	 and the gate of mine that reads it. The gate is found by reflecting over my own test
	 selectors for the one naming that package as a literal, so a gate renamed or deleted shows
	 as none rather than as a name that no longer answers. Nothing is cached: the row says what
	 the image holds the moment the tab opens."

	| gates |
	gates := Dictionary new.
	(self selectors select: [ :each | each beginsWith: 'test' ]) do: [ :selector |
		self allowedDependencies keysDo: [ :packageName |
			((self >> selector) sourceCode includesSubstring: '''' , packageName , '''')
				ifTrue: [ (gates at: packageName ifAbsentPut: [ OrderedCollection new ])
						add: selector ] ] ].
	^ self allowedDependencies keys asSortedCollection asArray collect: [ :packageName |
		  {
			  packageName.
			  ((PackageOrganizer default packageNamed: packageName ifAbsent: [ nil ])
				   ifNil: [ 'absent, its gate skips' ]
				   ifNotNil: [ :package |
					   package methods size printString , ' methods read' ]).
			  (', ' join: (gates at: packageName ifAbsent: [ #( 'none' ) ]) asSortedCollection) }  ]
]

{ #category : 'layering' }
VGArchitectureTest class >> loadedPackagesNamed: aCollectionOfPackageNames [
	"The packages of those names this image holds, in the order given, the ones it lacks passed
	 over. A sweep over a group of the baseline reads the names the group loads, not the names
	 this image has: a group loading part of the project - canvas-tests loads fifteen of the
	 forty-five packages the table names - leaves the rest absent, and an absent package names
	 nothing a sweep could find."

	^ aCollectionOfPackageNames
		  collect: [ :each |
			  PackageOrganizer default packageNamed: each ifAbsent: [ nil ] ]
		  thenReject: [ :each | each isNil ]
]

{ #category : 'layering' }
VGArchitectureTest class >> packageNameSeparator [
	"What dependencyReport puts between two package names inside one table cell."

	^ ', '
]

{ #category : 'layering' }
VGArchitectureTest class >> packagesLoadedByGroupNamed: aGroupName [
	"The packages of this project that Metacello loads for one group of
	 BaselineOfVectorGraphics: the names that group includes, every group among them expanded in
	 turn, and everything those packages require. Read from the spec rather than listed here, so
	 a group edited in the baseline moves this answer with it. An external project the baseline
	 names, such as Bloc, is left out: it is a name in another repository's baseline, and the
	 image happens to hold a package of the same name."

	| groups found todo |
	groups := Dictionary new.
	BaselineOfVectorGraphics project version groups do: [ :each |
		groups at: each name put: each includes ].
	found := Set new.
	todo := OrderedCollection with: aGroupName.
	[ todo isEmpty ] whileFalse: [
		| next |
		next := todo removeFirst.
		(groups includesKey: next)
			ifTrue: [ todo addAll: (groups at: next) ]
			ifFalse: [
				((found includes: next) or: [
					 (next beginsWith: self projectPackageNamePrefix) not ]) ifFalse: [
					found add: next.
					todo addAll: (self requiresOfPackageNamed: next) ] ] ].
	^ found
]

{ #category : 'layering' }
VGArchitectureTest class >> packagesNamedBy: aCompiledMethod [
	"The packages of this project whose classes aCompiledMethod names, reading the literals of
	 every block inside it as well as its own, to any depth. A block reaches the literals
	 either as a CompiledBlock or, when the compiler finds it clean, as a closure of its own,
	 and both answer #isBlock."

	| found scan |
	found := Set new.
	scan := nil.
	scan := [ :compiled |
	        compiled literals do: [ :literal |
		        literal isVariableBinding
			        ifTrue: [
				        literal value isBehavior ifTrue: [
					        literal value instanceSide package ifNotNil: [ :package |
						        (package name beginsWith: self projectPackageNamePrefix)
							        ifTrue: [ found add: package name asString ] ] ] ]
			        ifFalse: [
				        literal isBlock ifTrue: [ scan value: literal ] ] ] ].
	scan value: aCompiledMethod.
	^ found
]

{ #category : 'layering' }
VGArchitectureTest class >> projectPackageNamePrefix [
	"Every package of this project begins with this. BaselineOfVectorGraphics does not, which is
	 why the baseline is read through its own class and not found by this prefix."

	^ 'VectorGraphics'
]

{ #category : 'layering' }
VGArchitectureTest class >> projectPackageNames [
	"Every package of this project, asked of the organiser so that a package added tomorrow is
	 covered by the coverage test rather than by a list written out by hand.
	 Asking the organiser answers the packages this image holds, which is the whole project only
	 in an image that loaded it whole. The sweeps read it and so answer for the packages that are
	 there, which is what a sweep can say; a test comparing the whole dependency table against
	 the image first sends skipUnlessEveryPackageIsLoaded:, because a package the table names and
	 the image lacks would read there as a stray or as a dependency that stopped being real."

	^ ((PackageOrganizer default packages select: [ :each |
		    each name beginsWith: self projectPackageNamePrefix ]) collect: [ :each |
		   each name asString ]) asSet
]

{ #category : 'layering' }
VGArchitectureTest class >> replacedStackPackageNamePrefixes [
	"Bloc and the Alexandrie packages Bloc is built on. This project exists to replace
	 Alexandrie's canvas inside Bloc, so the Bloc layer of this project may name both and no
	 other layer may name either."

	^ #( 'Bloc' 'Alexandrie' )
]

{ #category : 'layering' }
VGArchitectureTest class >> replacedStackPackageNames [
	"Every package of Bloc and of Alexandrie present in this image, read from the organiser by
	 prefix so that a package a Bloc update adds is covered without this method being edited."

	^ (PackageOrganizer default packages select: [ :each |
		   self replacedStackPackageNamePrefixes anySatisfy: [ :prefix |
			   each name beginsWith: prefix ] ]) collect: [ :each | each name asString ]
]

{ #category : 'layering' }
VGArchitectureTest class >> requiresOfPackageNamed: aPackageName [
	"What BaselineOfVectorGraphics says one package needs. A name the baseline declares as a
	 group or as an external project is not a package of ours and needs nothing here."

	^ (BaselineOfVectorGraphics project version packages
		   detect: [ :each | each name = aPackageName ]
		   ifNone: [ ^ #(  ) ]) requires
]

{ #category : 'layering' }
VGArchitectureTest class >> stringLiteralsOf: aCompiledMethod [
	"Every string literal of this method, reading the literals of every block inside it as well
	 as its own, to any depth. A path hidden in a block is a path the method holds."

	| found scan |
	found := OrderedCollection new.
	scan := nil.
	scan := [ :compiled |
	        compiled literals do: [ :literal |
		        literal isString
			        ifTrue: [ found add: literal asString ]
			        ifFalse: [ literal isBlock ifTrue: [ scan value: literal ] ] ] ].
	scan value: aCompiledMethod.
	^ found
]

{ #category : 'running' }
VGArchitectureTest >> assertEdgesOfPackageNamed: aPackageName [
	"Fail naming every method that makes a reference allowedDependencies does not grant. A bare
	 package name would say that the layering broke without saying where to look for it. The
	 class name is asked for as a string, because a symbol would carry its quoting into the
	 failure message.
	 The package is asked for through my own packageNamed:, so a gate whose package this image
	 does not hold skips instead of raising."

	| allowed strays |
	allowed := (self class allowedDependencies at: aPackageName ifAbsent: [ #(  ) ]) asSet.
	strays := Set new.
	(self packageNamed: aPackageName) methods do: [ :method |
		((self class packagesNamedBy: method) copyWithout: aPackageName) do: [ :each |
			(allowed includes: each) ifFalse: [
				strays add: method methodClass name asString , ' >> '
					, method selector asString , ' -> ' , each ] ] ].
	self assert: strays asSortedCollection asArray equals: #(  )
]

{ #category : 'running' }
VGArchitectureTest >> packageNamed: aPackageName [
	"The package of this project a gate reads, or a skip when this image does not hold it. A
	 gate names its package as a literal so that it has a name of its own in a report, and a
	 group that loads part of the project - canvas-tests loads fifteen of the forty-five
	 packages the table names - reaches gates whose package is absent. Such a gate has nothing
	 to look at, so it says so and the gates of the packages that are loaded still run."

	^ PackageOrganizer default
		  packageNamed: aPackageName
		  ifAbsent: [ self skip: aPackageName , ' is not loaded in this image' ]
]

{ #category : 'running' }
VGArchitectureTest >> skipUnlessEveryPackageIsLoaded: aCollectionOfPackageNames [
	"Skip the test unless this image holds every one of these packages, naming the ones it
	 lacks. A test that compares a whole-project statement - the dependency table, a group of
	 the baseline - against the image can only report falsely when part of the project is
	 absent: every row of a missing package reads as stale, or as a stray, or as an edge nobody
	 declared."

	| absent |
	absent := aCollectionOfPackageNames reject: [ :each |
		          (PackageOrganizer default packageNamed: each ifAbsent: [ nil ]) notNil ].
	absent ifNotEmpty: [
		self skip: 'these packages are not loaded in this image: '
			, (', ' join: absent asSortedCollection) ]
]

{ #category : 'tests - partial loads' }
VGArchitectureTest >> testAGateSkipsRatherThanRaisesWhenItsPackageIsNotLoaded [
	"My gates name their package as a literal, because each one is a test of its own with its
	 own name in a report. A group that loads less than the whole project - canvas-tests loads
	 fifteen packages of the forty-five the table names - therefore reaches a gate whose package
	 is absent, and asking the organiser for it raised KeyNotFound. A gate that cannot look at
	 its package has nothing to say about it, which is a skip and not an error."

	self
		should: [ self packageNamed: 'VectorGraphics-NotLoadedInAnyImage' ]
		raise: TestSkipped
]

{ #category : 'tests - partial loads' }
VGArchitectureTest >> testAGroupSweepReadsOnlyThePackagesOfThatGroupThisImageHolds [
	"The tests that sweep a group of the baseline - the default group names no method and no
	 superclass of the stack it replaces - take their package names from the baseline, which
	 lists what the group loads and not what this image holds. A package of the group that was
	 never loaded names nothing, so it is passed over and the sweep answers for the packages
	 that are there."

	| loaded |
	loaded := self class loadedPackagesNamed:
		          #( 'VectorGraphics-Canvas-Tests' 'VectorGraphics-NotLoadedInAnyImage' ).
	self assert: (loaded collect: [ :each | each name asString ]) asArray
		equals: #( 'VectorGraphics-Canvas-Tests' )
]

{ #category : 'tests - partial loads' }
VGArchitectureTest >> testAWholeProjectTestSkipsWhenAPackageOfTheTableIsAbsent [
	"Two of my tests compare the whole dependency table against the whole image: one asks
	 whether every granted edge is real, the other whether every name in the table is a package
	 of this project. Both read the image through the organiser, which holds only what was
	 loaded, so in a partial image every row of an absent package reads as stale or as a stray.
	 That is a false report rather than a finding, so the comparison is skipped unless the
	 project is whole."

	self
		should: [
			self skipUnlessEveryPackageIsLoaded: #( 'VectorGraphics-NotLoadedInAnyImage' ) ]
		raise: TestSkipped
]

{ #category : 'tests' }
VGArchitectureTest >> testBenchmarksStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Benchmarks'
]

{ #category : 'tests' }
VGArchitectureTest >> testBlocExamplesStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Bloc-Examples'
]

{ #category : 'tests' }
VGArchitectureTest >> testBlocStaysInsideItsAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Bloc'
]

{ #category : 'tests' }
VGArchitectureTest >> testBlocTestsStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Bloc-Tests'
]

{ #category : 'tests' }
VGArchitectureTest >> testBlocTextExamplesStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Bloc-Text-Examples'
]

{ #category : 'tests' }
VGArchitectureTest >> testBlocTextStaysInsideItsAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Bloc-Text'
]

{ #category : 'tests' }
VGArchitectureTest >> testBlocTextTestsStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Bloc-Text-Tests'
]

{ #category : 'tests' }
VGArchitectureTest >> testCanvasExamplesStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Canvas-Examples'
]

{ #category : 'tests' }
VGArchitectureTest >> testCanvasFontsExamplesStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Canvas-Fonts-Examples'
]

{ #category : 'tests' }
VGArchitectureTest >> testCanvasFontsStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Canvas-Fonts'
]

{ #category : 'tests' }
VGArchitectureTest >> testCanvasFontsTestsStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Canvas-Fonts-Tests'
]

{ #category : 'tests' }
VGArchitectureTest >> testCanvasGeometryExamplesStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Canvas-Geometry-Examples'
]

{ #category : 'tests' }
VGArchitectureTest >> testCanvasGeometryStaysInsideItsAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Canvas-Geometry'
]

{ #category : 'tests' }
VGArchitectureTest >> testCanvasGeometryTestsStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Canvas-Geometry-Tests'
]

{ #category : 'tests' }
VGArchitectureTest >> testCanvasRasterExamplesStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Canvas-Raster-Examples'
]

{ #category : 'tests' }
VGArchitectureTest >> testCanvasRasterStaysInsideItsAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Canvas-Raster'
]

{ #category : 'tests' }
VGArchitectureTest >> testCanvasRasterTestsStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Canvas-Raster-Tests'
]

{ #category : 'tests' }
VGArchitectureTest >> testCanvasStaysInsideItsAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Canvas'
]

{ #category : 'tests' }
VGArchitectureTest >> testCanvasTestsStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Canvas-Tests'
]

{ #category : 'tests' }
VGArchitectureTest >> testConformanceStaysInsideItsAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Conformance'
]

{ #category : 'tests' }
VGArchitectureTest >> testDocumentationExamplesStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Documentation-Examples'
]

{ #category : 'tests' }
VGArchitectureTest >> testDocumentationStaysInsideItsAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Documentation'
]

{ #category : 'tests' }
VGArchitectureTest >> testDocumentationTestsStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Documentation-Tests'
]

{ #category : 'tests - dependencies' }
VGArchitectureTest >> testEngineExamplesStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Engine-Examples'
]

{ #category : 'tests - dependencies' }
VGArchitectureTest >> testEngineStaysInsideItsAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Engine'
]

{ #category : 'tests - dependencies' }
VGArchitectureTest >> testEngineTestsStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Engine-Tests'
]

{ #category : 'tests' }
VGArchitectureTest >> testEveryAllowedDependencyIsDeclaredInTheBaseline [
	"A package can load only what the baseline says it needs. An edge the table grants but the
	 baseline leaves out works in this image, where every package is present already, and fails
	 for whoever loads the project one group at a time. The edges of
	 edgesTheBaselineCannotDeclare are left out here and held by their own test."

	| declared missing |
	declared := Dictionary new.
	BaselineOfVectorGraphics project version packages do: [ :each |
		declared at: each name put: each requires asSet ].
	missing := Set new.
	self class allowedDependencies keysAndValuesDo: [ :package :allowed |
		allowed do: [ :each |
			((self class edgesTheBaselineCannotDeclare includes: package -> each) or: [
				 (declared at: package ifAbsent: [ Set new ]) includes: each ]) ifFalse: [
				missing add: package , ' -> ' , each ] ] ].
	self assert: missing asSortedCollection asArray equals: #(  )
]

{ #category : 'tests' }
VGArchitectureTest >> testEveryAllowedDependencyIsOneThePackageReallyMakes [
	"A dependency that stopped being real has to come out of the table, or the table stops
	 describing the code and starts describing its history.
	 The whole table is read against the whole image, so the image has to hold the whole
	 project: a package that was never loaded names nothing, and every edge granted to it would
	 read as one that stopped being real."

	| stale |
	self skipUnlessEveryPackageIsLoaded: self class allowedDependencies keys.
	stale := Set new.
	self class allowedDependencies keysAndValuesDo: [ :package :allowed |
		| actual |
		actual := self class edgesOf: package.
		allowed do: [ :each |
			(actual includes: each) ifFalse: [ stale add: package , ' -> ' , each ] ] ].
	self assert: stale asSortedCollection asArray equals: #(  )
]

{ #category : 'tests' }
VGArchitectureTest >> testEveryAllowedDependencyNamesAPackageOfThisProject [
	"A renamed package leaves its old name behind in the table, where it would silently grant
	 nothing and hide the edge that replaced it.
	 projectPackageNames is read from the organiser, so it answers the packages this image
	 holds and not the packages the project has. The image therefore has to hold the whole
	 project, or every name in the table whose package was not loaded would read as a name no
	 package of this project answers to."

	| strays |
	self skipUnlessEveryPackageIsLoaded: self class allowedDependencies keys.
	strays := Set new.
	self class allowedDependencies keysAndValuesDo: [ :package :allowed |
		allowed do: [ :each |
			(self class projectPackageNames includes: each) ifFalse: [
				strays add: package , ' -> ' , each ] ] ].
	self assert: strays asSortedCollection asArray equals: #(  )
]

{ #category : 'tests' }
VGArchitectureTest >> testEveryClassCommentOfThisProjectIsCrOnly [
	"CLAUDE.md forbids LF in Pharo source, and a class comment is source. An LF in one is
	 invisible in the browser and shows up as a working copy Iceberg reports modified for ever,
	 because the comment on disk is CR and the comment in the image is not. The check is
	 therefore in the image and nowhere else."

	| commented offenders |
	commented := OrderedCollection new.
	offenders := OrderedCollection new.
	self class projectPackageNames do: [ :each |
		(PackageOrganizer default packageNamed: each) definedClasses do: [ :cls |
			cls comment ifNotNil: [ :text |
				commented add: cls name.
				(text includes: Character lf) ifTrue: [ offenders add: cls name asString ] ] ] ].
	"A mistyped query would leave nothing to scan and pass in silence."
	self deny: commented isEmpty.
	self assertEmpty: offenders asSortedCollection asArray
]

{ #category : 'tests' }
VGArchitectureTest >> testEveryEdgeTheBaselineCannotDeclareIsOneHalfOfACycle [
	"The exemption is not a place for an edge somebody forgot to declare. An edge belongs there
	 only because its reverse is declared, which is what makes the pair a cycle no baseline can
	 state, and the reverse is read from the baseline rather than asserted here."

	| declared wrong |
	declared := Dictionary new.
	BaselineOfVectorGraphics project version packages do: [ :each |
		declared at: each name put: each requires asSet ].
	wrong := Set new.
	self class edgesTheBaselineCannotDeclare do: [ :edge |
		((declared at: edge value ifAbsent: [ Set new ]) includes: edge key) ifFalse: [
			wrong add: edge key , ' -> ' , edge value ] ].
	self assert: wrong asSortedCollection asArray equals: #(  )
]

{ #category : 'tests' }
VGArchitectureTest >> testEveryExternalProjectIsPinnedWhereThisProjectMeansIt [
	"Every project outside this repository, with the repository this project pins it to and the
	 reason that pin is a tag or a branch. MuTalk is a tag: it rewrites production methods in the
	 image, so the version doing the rewriting is part of this project's own setup. Bloc is a
	 branch because it publishes no release tag. PharoVulkan is a branch because it is this
	 project's own Vulkan binding, written alongside it, so a tag cut today is stale a week later.
	 ArchDoc is a branch for the same reason: it is this project's own documentation library, and
	 it is where Roassal is pinned, so no group here names Roassal.
	 The pins are read through `repositorySpecs`: the MuTalk-only test this one replaces sent
	 `map`, which MetacelloRepositoriesSpec no longer understands."

	| pins |
	pins := Dictionary new.
	BaselineOfVectorGraphics project version projects do: [ :each |
		pins
			at: each name
			put: (each repositories repositorySpecs collect: [ :one | one description ])
					asArray ].
	self assert: pins equals: (Dictionary newFrom: {
			 ('ArchDoc' -> #( 'github://rvillemeur/ArchDoc:main/src' )).
			 ('Bloc' -> #( 'github://pharo-graphics/Bloc:master' )).
			 ('MuTalk' -> #( 'github://pharo-contributions/mutalk:v3.0.8/src' )).
			 ('PharoVulkan' -> #( 'github://rvillemeur/PharoVulkan:main/src' )) })
]

{ #category : 'tests' }
VGArchitectureTest >> testEveryPackageOfThisProjectHasADeclaredAllowedSet [
	"A package added tomorrow goes unscanned until it appears in the table, so the table is
	 checked against the organiser rather than against a list written out by hand."

	self
		assert: self class allowedDependencies keys asSortedCollection asArray
		equals: self class projectPackageNames asSortedCollection asArray
]

{ #category : 'tests - dependencies' }
VGArchitectureTest >> testEveryPackageOfThisProjectIsScannedByOneOfMyTests [
	"The table covering a package is not the same as a test scanning it: a package can appear in
	 allowedDependencies with an empty set and never be read, in which case every reference it
	 makes is allowed by nobody. One test per package names it, so the failure says which
	 package broke; this reads the package name out of each of those tests rather than listing
	 them, so the twenty-three stay in step with the organiser."

	| scanned |
	scanned := Set new.
	(self class selectors select: [ :each | each beginsWith: 'test' ]) do: [ :selector |
		| method |
		method := self class >> selector.
		(method sendsSelector: #assertEdgesOfPackageNamed:) ifTrue: [
			method literals do: [ :literal |
				(literal isString and: [
					 self class projectPackageNames includes: literal asString ]) ifTrue: [
					scanned add: literal asString ] ] ] ].
	self
		assert: scanned asSortedCollection asArray
		equals: self class projectPackageNames asSortedCollection asArray
]

{ #category : 'tests - hierarchy' }
VGArchitectureTest >> testNoBackendOutsideAProductionPackageIsACandidateForSelection [
	"VGBackend class >> candidateClasses finds candidates by reflection over the subclasses, so
	 a fixture that subclasses a real backend and forgets to refuse is ranked with the real
	 ones and chosen for every surface of the image — which happened during unit 7.4 of
	 VECTORCANVAS-PRESENT-PLAN.md, where a cleared rejection set left VGFailingDispatchBackendStub
	 preferred, a stub that fails every frame. Every backend a test or an example package
	 defines answers false to isCandidate, and this holds the next one to it."

	| offenders |
	offenders := OrderedCollection new.
	VGBackend allSubclasses do: [ :each |
		((self class isProductionPackageNamed: each package name) not and: [
			 each isCandidate ]) ifTrue: [
			offenders add: each package name , ': ' , each name ] ].
	self assert: offenders asSortedCollection asArray equals: #(  )
]

{ #category : 'tests - groups' }
VGArchitectureTest >> testNoClassOfTheCanvasExampleAndTestGroupsInheritsFromBloc [
	"The six canvas example and test groups install in an image with no Bloc, which the literal
	 scan of testTheCanvasExampleAndTestGroupsNameNoBlocClass cannot prove on its own:
	 a superclass is named by the class definition. Alexandrie is not asked about here —
	 blocPackageNames says why."

	#( 'canvas-examples' 'canvas-tests' 'canvas-raster-examples' 'canvas-raster-tests'
	   'canvas-fonts-examples' 'canvas-fonts-tests' ) do: [ :group |
		self
			assert: (self class inheritanceOfGroupNamed: group into: self class blocPackageNames)
			equals: #(  ) ].
	self
		assert: (self class inheritanceOfGroupNamed: 'bloc' into: self class blocPackageNames)
				notEmpty
		description: 'the walk finds nothing at all, so the empty answers above prove nothing'
]

{ #category : 'tests' }
VGArchitectureTest >> testNoClassOfTheDefaultGroupInheritsFromTheStackItReplaces [
	"This is the link that fails the load first: VGRenderer is a subclass of BARenderer, and
	 Metacello cannot install the class at all without Bloc in the image. The same question is
	 asked of the Cairo examples and tests by
	 testNoClassOfTheCairoExampleAndTestGroupsInheritsFromBloc."

	self
		assert: (self class
				 inheritanceOfGroupNamed: 'default'
				 into: self class replacedStackPackageNames)
		equals: #(  ).
	self
		assert:
			(self class inheritanceOfGroupNamed: 'bloc' into: self class replacedStackPackageNames)
				notEmpty
		description: 'the walk finds nothing at all, so the empty answer above proves nothing'
]

{ #category : 'tests - hierarchy' }
VGArchitectureTest >> testNoClassOfThisProjectInheritsFromAnObsoleteClass [
	"A class whose superclass is obsolete looks right in the browser and answers right in the
	 tests, because the obsolete copy still holds the methods the live class holds. It is still
	 broken: the live class is no longer in its own hierarchy, so a method added to it never
	 reaches the subclass, and the package the obsolete copy was filed under holds a class
	 nothing can find. Reparenting a class moved between packages, and reloading one from its
	 Tonel file after a crash, are the two ways this project has made one.
	 This is asked of every package of the project rather than of a list, so a package added
	 tomorrow is covered."

	| strays |
	strays := Set new.
	self class projectPackageNames do: [ :name |
		(PackageOrganizer default packageNamed: name) definedClasses do: [ :cls |
			cls allSuperclasses do: [ :each |
				each isObsolete ifTrue: [
					strays add: cls name asString , ' < ' , each name asString ] ] ] ].
	self assert: strays asSortedCollection asArray equals: #(  )
]

{ #category : 'tests - hierarchy' }
VGArchitectureTest >> testNoMethodOfThisProjectExtendsANumberClass [
	"Pixels live in a `Bitmap` and in a `WordArray`, and this project extends those two because it
	 reads and writes them. A number is not a thing this project owns any part of, and a method
	 added to one is visible to every package in the image under a selector this project does not
	 control: the `SmallInteger >> digitAt:` that made this test fail was Pharo's own method kept
	 under the name Pharo renamed away, so the project was the only thing in the image answering an
	 obsolete selector. Ask Pharo for `byteAt:`, which every integer class implements."
	| offenders |
	offenders := OrderedCollection new.
	self class projectPackageNames do: [ :packageName |
		(PackageOrganizer default packageNamed: packageName) methods do: [ :each |
			(each methodClass instanceSide includesBehavior: Number) ifTrue: [
				offenders add: each methodClass name , ' >> ' , each selector ] ] ].
	self assertEmpty: offenders
]

{ #category : 'tests' }
VGArchitectureTest >> testNoMethodOfThisProjectRedefinesAMethodOfAnotherProject [
	"An extension may add a selector to a class another project owns; it may not replace one a
	 class already has. A class holds one method object per selector, so a redefinition takes
	 that method away from the upstream package: the upstream checkout then reports the method
	 as gone, and the next load of that package puts its own version back and takes ours away
	 without a word. The upstream source on disk is the referee - a selector one of our packages
	 owns must not appear as a method header in the Tonel file of the package defining the class."

	| strays |
	strays := Set new.
	self class projectPackageNames do: [ :name |
		(PackageOrganizer default packageNamed: name ifAbsent: [ nil ])
			ifNotNil: [ :package |
				package extensionMethods do: [ :method |
					(self tonelFileDefiningTheClassOf: method) ifNotNil: [ :file |
						(file contents includesSubstring:
							 method methodClass name , ' >> ' , method selector , ' [')
							ifTrue: [
							strays add:
								method methodClass name asString , ' >> '
								, method selector asString ] ] ] ] ].
	self assert: strays asSortedCollection asArray equals: #(  )
]

{ #category : 'tests' }
VGArchitectureTest >> testNoPackageOfTheDefaultGroupDefinesAMethodOnTheStackItReplaces [
	"Loading this project with no group named must not need Bloc or Alexandrie, so a package of
	 the default group installs no method on a class of either: the extension would have no
	 class to go on. The Bloc packages extend both by design since phases 3 and 4 of the font
	 plan — a scaled font of ours answers an Alexandrie context, and a Cairo surface answers a
	 context of ours — and what they may name is stated by #allowedDependencies. This rule spoke
	 for the whole project, as a gate of VGRendererTest, until that design landed.
	 The group names what it loads, so a package of it this image does not hold is passed over:
	 it defines no method at all here."

	| stack offenders |
	stack := self class replacedStackPackageNames asSet.
	offenders := (self class loadedPackagesNamed:
		              (self class packagesLoadedByGroupNamed: 'default')
			              asSortedCollection asArray) flatCollect: [ :package |
		             (package methods select: [ :each |
			              | owner |
			              owner := each methodClass instanceSide package.
			              owner notNil and: [ stack includes: owner name asString ] ])
			             collect: [ :each |
			             package name asString , ': ' , each printString ] ].
	self assert: offenders asSortedCollection asArray equals: #(  )
]

{ #category : 'tests' }
VGArchitectureTest >> testNoPackageOfTheDefaultGroupNamesAClassOfTheStackItReplaces [
	"Loading this project with no group named must not reach Bloc or Alexandrie. The engine and
	 the Cairo backend are what a user loads to rasterise; the Bloc renderer is the opt-in layer
	 that replaces Alexandrie's canvas inside Bloc. A package of the default group that names a
	 class of either fails to load in an image where neither is present, and VGRenderer, a
	 subclass of BARenderer, is how that was found."

	| scanner offenders |
	scanner := VGCairoReferenceScanner new.
	offenders := (self class packagesLoadedByGroupNamed: 'default') asSortedCollection asArray
		             flatCollect: [ :package |
			             (scanner
				              offendersIn: package
				              naming: self class replacedStackPackageNames) collect: [ :each |
				             package , ': ' , each key methodClass name , '>>'
				             , each key selector , ' names '
				             , (each value collect: [ :one | one name ]) asArray printString ] ].
	self assert: offenders asSortedCollection asArray equals: #(  )
]

{ #category : 'tests' }
VGArchitectureTest >> testNoProductionMethodOfThisProjectReadsTheFontBytesAlexandrieEmbeds [
	"The font a consumer draws with by default is a file of the machine, read by this project.
	 Alexandrie-FreeType carries six fonts of its own as byte arrays in classes, and a
	 production method that names one of them, or that sends scanEmbeddedFonts to register all
	 six, cannot run in an image loaded without that package — which is the image unit 6 of
	 FONT-PLAN.md drew in.
	 Tests, examples, the conformance corpus and the benchmarks are left out on purpose: they
	 want the same bytes every run, and a font of the machine is not the same on two machines.
	 The suite therefore still needs Alexandrie-FreeType, and a consumer of the project does
	 not."
	| embedded offenders |
	embedded := AeEmbeddedFontFile withAllSubclasses asArray.
	offenders := OrderedCollection new.
	self class projectPackageNames do: [ :packageName |
		(self class isProductionPackageNamed: packageName) ifTrue: [
			(PackageOrganizer default packageNamed: packageName) methods do: [
				:each |
				((each literals anySatisfy: [ :literal |
					  literal isVariableBinding and: [
							  embedded includes: literal value ] ]) or: [
					 each sendsSelector: #scanEmbeddedFonts ]) ifTrue: [
					offenders add:
						packageName , ': ' , each methodClass name , '>>' , each selector ] ] ] ].
	self assert: offenders asSortedCollection asArray equals: #(  )
]

{ #category : 'tests - layering' }
VGArchitectureTest >> testOnlyTheFontCatalogueNamesAPlatformFontDirectory [
	"Where a platform keeps its fonts is one fact, and TTFontCatalogue class >>
	 defaultFontDirectories is where this project states it. A path written anywhere else is the
	 path of one machine: a path under one developer's home directory broke the examples of the
	 text glue for everybody else, and a single Linux font directory breaks the examples of the
	 scaled-font layer on macOS and on Windows, where it does not exist."

	| offenders |
	offenders := OrderedCollection new.
	self class projectPackageNames do: [ :packageName |
		packageName asPackage methods do: [ :method |
			((self class stringLiteralsOf: method) anySatisfy: [ :literal |
				 self class isPlatformPathOfAFont: literal ]) ifTrue: [
				offenders add: method methodClass name , ' >> ' , method selector ] ] ].
	self
		assert:
		(offenders reject: [ :each |
			 each = 'TTFontCatalogue class >> defaultFontDirectories' ])
			asSortedCollection asArray
		equals: #( )
]

{ #category : 'tests - dependencies' }
VGArchitectureTest >> testPathsExamplesStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Paths-Examples'
]

{ #category : 'tests - dependencies' }
VGArchitectureTest >> testPathsStaysInsideItsAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Paths'
]

{ #category : 'tests - dependencies' }
VGArchitectureTest >> testPathsTestsStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Paths-Tests'
]

{ #category : 'tests' }
VGArchitectureTest >> testReflectionExamplesStayInsideTheirAllowedDependencies [

	self assertEdgesOfPackageNamed: 'VectorGraphics-Reflection-Examples'
]

{ #category : 'tests' }
VGArchitectureTest >> testReflectionStaysInsideItsAllowedDependencies [

	self assertEdgesOfPackageNamed: 'VectorGraphics-Reflection'
]

{ #category : 'tests - dependencies' }
VGArchitectureTest >> testTextExamplesStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Text-Examples'
]

{ #category : 'tests - dependencies' }
VGArchitectureTest >> testTextStaysInsideItsAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Text'
]

{ #category : 'tests - dependencies' }
VGArchitectureTest >> testTextTestsStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Text-Tests'
]

{ #category : 'tests' }
VGArchitectureTest >> testTheBaselineNamesOnlyArchDocBlocMuTalkAndPharoVulkanAsExternalProjects [
	"Every project outside this repository that a load can reach, named here so one cannot be
	 added without saying which group needs it: ArchDoc for the documentation group, which reads
	 the declarations the font classes carry and draws them, Bloc for the renderer group, MuTalk
	 for the dev group, PharoVulkan for the vulkan group, whose three packages name its bindings,
	 its compiler and its driver. Roassal draws the diagram and is not named here: ArchDoc's own
	 baseline pins the Roassal it was written against, and two pins of one project in one load is
	 how a Metacello conflict is built. What each one is pinned to, and why, is the test above."

	self
		assert: (BaselineOfVectorGraphics project version projects collect: [ :each |
				 each name ]) asSortedCollection asArray
		equals: #( 'ArchDoc' 'Bloc' 'MuTalk' 'PharoVulkan' )
]

{ #category : 'tests' }
VGArchitectureTest >> testTheBlocGroupLoadsEverythingTheDefaultGroupLoadsAndTheRenderer [
	"Using this project as Alexandrie's replacement stays one load: the bloc group brings the
	 renderer and everything the default group brings. Dropping the renderer out of the default
	 group must not make it harder to reach."

	| loaded |
	loaded := self class packagesLoadedByGroupNamed: 'bloc'.
	self assert: (loaded includes: 'VectorGraphics-Bloc').
	self assert: ((self class packagesLoadedByGroupNamed: 'default') allSatisfy: [ :each |
			 loaded includes: each ])
]

{ #category : 'tests' }
VGArchitectureTest >> testTheBlocLayerRequiresTheExternalBlocProject [
	"The renderer subclasses BARenderer, so the group that loads it must fetch Bloc rather than
	 assume an image that already holds it. No package of the default stack requires Bloc,
	 which is the other half of the same fact."

	| requires |
	requires := Dictionary new.
	BaselineOfVectorGraphics project version packages do: [ :each |
		requires at: each name put: each requires asSet ].
	self assert: ((requires at: 'VectorGraphics-Bloc') includes: 'Bloc').
	(self class packagesLoadedByGroupNamed: 'default') do: [ :each |
		self deny: ((requires at: each) includes: 'Bloc') ]
]

{ #category : 'tests' }
VGArchitectureTest >> testTheCanvasExampleAndTestGroupsNameNoBlocClass [
	"The examples and the tests of the canvas load without Bloc too, eight groups of them: six
	 since unit 6.6 of the split and two since unit 1 of FONTS-LOAD-PLAN, where the path
	 geometry became a package of its own. The project-wide examples and tests groups span every
	 layer, so asking for them fetches Bloc and wants PharoVulkan, which a user of the canvas
	 wants neither of. Most of these groups bring the font reader, because the canvas's font
	 layer names it, and the conformance corpus, because the examples open it and the gate reads
	 it. The font tests group also brings the font reader's own test and examples packages, and
	 through them the rasteriser tests, since VGFontBytesFixture moved to
	 VectorGraphics-TrueType-Tests with the glyph source: the face tests that reject a font
	 missing a table read that fixture. The geometry tests group brings the font reader through
	 the canvas, whose live-cairo gate the matrix tests ask before they compare a matrix of
	 ours with one of Cairo. It brings no corpus. The three test groups bring the reference scan as well, which the
	 gate and the backend selection read to answer what a package names.
	 None of it is Bloc. Alexandrie is not asked about here — blocPackageNames says why. A group
	 that does not exist would pass on an empty scan, so the packages each one must bring in are
	 named first."

	| scanner expected offenders |
	scanner := VGCairoReferenceScanner new.
	expected := Dictionary newFrom: {
			            'canvas-examples'
			            -> #( 'VectorGraphics-Canvas' 'VectorGraphics-Canvas-Examples'
				               'VectorGraphics-Canvas-Fonts' 'VectorGraphics-Canvas-Geometry'
				               'VectorGraphics-Canvas-Geometry-Examples'
				               'VectorGraphics-Canvas-Raster' 'VectorGraphics-Conformance'
				               'VectorGraphics-Paths' 'VectorGraphics-TrueType' ).
			            'canvas-tests'
			            -> #( 'VectorGraphics-Canvas' 'VectorGraphics-Canvas-Examples'
				               'VectorGraphics-Canvas-Fonts'
				               'VectorGraphics-Canvas-Fonts-Examples'
				               'VectorGraphics-Canvas-Geometry'
				               'VectorGraphics-Canvas-Geometry-Examples'
				               'VectorGraphics-Canvas-Raster'
				               'VectorGraphics-Canvas-Raster-Examples'
				               'VectorGraphics-Canvas-Raster-Tests'
				               'VectorGraphics-Canvas-Tests' 'VectorGraphics-Conformance'
				               'VectorGraphics-Paths' 'VectorGraphics-Reflection'
				               'VectorGraphics-Reflection-Examples' 'VectorGraphics-TrueType' ).
			            'canvas-raster-examples'
			            -> #( 'VectorGraphics-Canvas' 'VectorGraphics-Canvas-Fonts'
				               'VectorGraphics-Canvas-Geometry'
				               'VectorGraphics-Canvas-Geometry-Examples'
				               'VectorGraphics-Canvas-Raster'
				               'VectorGraphics-Canvas-Raster-Examples' 'VectorGraphics-Paths'
				               'VectorGraphics-TrueType' ).
			            'canvas-raster-tests'
			            -> #( 'VectorGraphics-Canvas' 'VectorGraphics-Canvas-Fonts'
				               'VectorGraphics-Canvas-Geometry' 'VectorGraphics-Canvas-Raster'
				               'VectorGraphics-Canvas-Raster-Tests'
				               'VectorGraphics-Conformance' 'VectorGraphics-Paths'
				               'VectorGraphics-Reflection' 'VectorGraphics-TrueType' ).
			            'canvas-fonts-examples'
			            -> #( 'VectorGraphics-Canvas' 'VectorGraphics-Canvas-Fonts'
				               'VectorGraphics-Canvas-Fonts-Examples'
				               'VectorGraphics-Canvas-Geometry' 'VectorGraphics-Canvas-Raster'
				               'VectorGraphics-Conformance' 'VectorGraphics-Paths'
				               'VectorGraphics-TrueType' ).
			            'canvas-fonts-tests'
			            -> #( 'VectorGraphics-Canvas' 'VectorGraphics-Canvas-Fonts'
				               'VectorGraphics-Canvas-Fonts-Examples'
				               'VectorGraphics-Canvas-Fonts-Tests'
				               'VectorGraphics-Canvas-Geometry' 'VectorGraphics-Canvas-Raster'
				               'VectorGraphics-Conformance' 'VectorGraphics-Paths'
				               'VectorGraphics-Reflection' 'VectorGraphics-Tests'
				               'VectorGraphics-TrueType'
				               'VectorGraphics-TrueType-Examples'
				               'VectorGraphics-TrueType-Tests' ).
			            'canvas-geometry-examples'
			            -> #( 'VectorGraphics-Canvas' 'VectorGraphics-Canvas-Fonts'
				               'VectorGraphics-Canvas-Geometry'
				               'VectorGraphics-Canvas-Geometry-Examples'
				               'VectorGraphics-Canvas-Raster' 'VectorGraphics-Paths'
				               'VectorGraphics-TrueType' ).
			            'canvas-geometry-tests'
			            -> #( 'VectorGraphics-Canvas' 'VectorGraphics-Canvas-Fonts'
				               'VectorGraphics-Canvas-Geometry'
				               'VectorGraphics-Canvas-Geometry-Tests'
				               'VectorGraphics-Canvas-Raster' 'VectorGraphics-Paths'
				               'VectorGraphics-TrueType' ) }.
	expected keysAndValuesDo: [ :group :packages |
		self
			assert: (self class packagesLoadedByGroupNamed: group)
			equals: packages asSet ].
	offenders := expected keys asSortedCollection asArray flatCollect: [ :group |
		             (self class packagesLoadedByGroupNamed: group) asSortedCollection asArray
			             flatCollect: [ :package |
				             (scanner
					              offendersIn: package
					              naming: self class blocPackageNames) collect: [ :each |
					             group , ' ' , package , ': ' , each key methodClass name , '>>'
					             , each key selector ] ] ].
	self assert: offenders asSortedCollection asArray equals: #(  )
]

{ #category : 'tests' }
VGArchitectureTest >> testTheDefaultGroupLoadsTheRasteriserAndTheCanvasAlone [
	"What `Metacello load: 'VectorGraphics'` brings in, named here so the group cannot grow a
	 layer back by accident. The rasteriser is four packages since the split and the default
	 group brings all four, because that is what the one package it replaced held. The canvas
	 is four packages, three since the split of 2026-11 and the path geometry since unit 1 of
	 FONTS-LOAD-PLAN, and the group brings all four, for the same reason. Every layer above
	 them is a group of its own."

	self
		assert: (self class packagesLoadedByGroupNamed: 'default') asSortedCollection asArray
		equals: #( 'VectorGraphics' 'VectorGraphics-Canvas' 'VectorGraphics-Canvas-Fonts'
			   'VectorGraphics-Canvas-Geometry' 'VectorGraphics-Canvas-Raster'
			   'VectorGraphics-Engine' 'VectorGraphics-Paths' 'VectorGraphics-Text'
			   'VectorGraphics-TrueType' )
]

{ #category : 'tests - groups' }
VGArchitectureTest >> testTheDevGroupBringsNoBlocAndNoVulkanPackage [
	"The dev group must load in a plain Pharo image. The renderer layers are the two that need
	 something outside this repository — Bloc from its own repository, PharoVulkan by hand — so
	 a dev group that reached them would make a mutation run depend on a machine with a Vulkan
	 driver."

	| loaded |
	loaded := self class packagesLoadedByGroupNamed: 'dev'.
	self assert: (loaded reject: [ :each |
			 (each includesSubstring: 'Bloc') or: [
				 each includesSubstring: 'Vulkan' ] ]) equals: loaded.
	#( 'VectorGraphics-Canvas-Tests' 'VectorGraphics-Canvas-Raster-Tests'
	   'VectorGraphics-Canvas-Fonts-Tests' ) do: [ :each |
		self assert: (loaded includes: each) ].
	#( 'Paths' 'Engine' 'TrueType' 'Text' ) do: [ :layer |
		self assert: (loaded includes: 'VectorGraphics-' , layer , '-Tests') ]
]

{ #category : 'tests' }
VGArchitectureTest >> testTheDevGroupLoadsTheDefaultStackItsTestsAndMuTalk [
	"The group a developer of this project loads: what `default` loads, the tests of those same
	 layers, and MuTalk. MuTalk mutates production methods and asks whether a test notices, so a
	 dev group without the tests of the code under test would report everything as survived.
	 The four layer test groups and the four of the canvas are named one by one rather than
	 through the project-wide `tests` group, because that one spans every layer: it fetches Bloc
	 and wants PharoVulkan, neither of which a mutation run of the canvas needs."

	| groups |
	groups := Dictionary new.
	BaselineOfVectorGraphics project version groups do: [ :each |
		groups at: each name put: each includes ].
	self assert: (groups includesKey: 'dev').
	self
		assert: (groups at: 'dev') asSortedCollection asArray
		equals: #( 'MuTalk' 'canvas-fonts-tests' 'canvas-geometry-tests' 'canvas-raster-tests'
			   'canvas-tests' 'default' 'engine-tests' 'paths-tests' 'text-tests'
			   'truetype-tests' )
]

{ #category : 'tests - dependencies' }
VGArchitectureTest >> testTheDocumentationGatePackageStaysInsideItsAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Tests'
]

{ #category : 'tests - partial loads' }
VGArchitectureTest >> testTheEdgesOfAPackageThisImageDoesNotHoldAreNoneRatherThanAnError [
	"The walk answers what a package's own methods name. A package that is not loaded names
	 nothing in this image, which is an empty answer: the walk is a reading of the image and not
	 a judgement, so the test that reads it is where the absence is decided."

	self assert: (self class edgesOf: 'VectorGraphics-NotLoadedInAnyImage') isEmpty
]

{ #category : 'tests' }
VGArchitectureTest >> testTheExamplesAndTestsGroupsAreTheUnionOfTheirLayerGroups [
	"One group per layer for examples and for tests, and the project-wide group is their union.
	 Stating the union as the layer group names rather than as package names is what keeps the
	 two from drifting apart when a layer gains a package. Thirteen layers: the four packages of
	 the rasteriser, then the canvas, its renderer, its font layer and its geometry, then
	 Bloc, the cairo text route, the font engine, Vulkan and the documentation that draws them."

	| groups |
	groups := Dictionary new.
	BaselineOfVectorGraphics project version groups do: [ :each |
		groups at: each name put: each includes asArray ].
	self assert: (groups at: 'examples') equals: #( 'paths-examples' 'engine-examples'
			 'truetype-examples' 'text-examples' 'canvas-examples'
			 'canvas-raster-examples' 'canvas-fonts-examples' 'canvas-geometry-examples'
			 'bloc-examples' 'bloc-text-examples' 'fonts-examples'
			 'reflection-examples' 'vulkan-examples' 'documentation-examples' ).
	self assert: (groups at: 'tests') equals: #( 'paths-tests' 'engine-tests' 'truetype-tests'
			 'text-tests' 'canvas-tests' 'canvas-raster-tests' 'canvas-fonts-tests'
			 'canvas-geometry-tests' 'bloc-tests' 'bloc-text-tests' 'fonts-tests'
			 'vulkan-tests' 'documentation-tests' ).
	#( 'examples' 'tests' ) do: [ :name |
		self
			assert: (self class packagesLoadedByGroupNamed: name)
			equals: ((groups at: name) inject: Set new into: [ :all :layer |
					 all
						 addAll: (self class packagesLoadedByGroupNamed: layer);
						 yourself ]) ]
]

{ #category : 'tests' }
VGArchitectureTest >> testTheFontEngineExamplesStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Bloc-FontEngine-Examples'
]

{ #category : 'tests' }
VGArchitectureTest >> testTheFontEngineStaysInsideItsAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Bloc-FontEngine'
]

{ #category : 'tests' }
VGArchitectureTest >> testTheFontEngineTestsStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Bloc-FontEngine-Tests'
]

{ #category : 'tests' }
VGArchitectureTest >> testTheFontsGroupLoadsTheCairoRouteAndNoCanvas [
	"The point of FONTS-LOAD-PLAN, held here: someone who wants the TrueType engine on cairo
	 loads `fonts` and gets the reader, the font layer, the geometry, the reference scan, the
	 cairo route and the engine that poses it. No canvas, no rasteriser, no software renderer
	 and no Vulkan package, none of which is on that route. The set is named one by one rather
	 than asserted package by package, so the group cannot grow a layer back unnoticed; this
	 replaces the looser test of unit 3.7, which named the canvas as part of the route."

	self
		assert: (self class packagesLoadedByGroupNamed: 'fonts') asSortedCollection asArray
		equals: #( 'VectorGraphics-Bloc-FontEngine' 'VectorGraphics-Bloc-Text'
			   'VectorGraphics-Canvas-Fonts' 'VectorGraphics-Canvas-Geometry'
			   'VectorGraphics-Paths' 'VectorGraphics-Reflection'
			   'VectorGraphics-TrueType' )
]

{ #category : 'tests - groups' }
VGArchitectureTest >> testTheFontsGroupPosesTheRouteAsItLoads [
	"What makes the switch transparent: the engine's package carries a postLoadDoIt:, so
	 Metacello poses the route itself and a reader of the group has nothing to evaluate
	 afterwards. The hook is read from the spec, not named here, so moving it breaks this."

	| spec |
	spec := BaselineOfVectorGraphics project version packages detect: [ :each |
		        each name = 'VectorGraphics-Bloc-FontEngine' ].

	self assert: spec postLoadDoIt notNil
]

{ #category : 'tests - dependencies' }
VGArchitectureTest >> testTheFrontPagePackageStaysInsideItsAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics'
]

{ #category : 'tests' }
VGArchitectureTest >> testTheScanReadsAReferencePlantedInsideANestedBlock [
	"The scan must read the literals of every block inside a method, at any depth. Most of this
	 project draws inside a block — a display list entry is replayed from one, a conformance case
	 is a draw block — so a scan of a method own literals alone would pass exactly the code it is
	 meant to watch. VGNestedBlockReferenceFixture names VGCairoMatrix three blocks deep and
	 nowhere else."

	self
		assert: (self class packagesNamedBy:
				 VGNestedBlockReferenceFixture >> #reachThroughThreeBlocks)
		equals: (Set with: VGCairoMatrix package name asString)
]

{ #category : 'tests' }
VGArchitectureTest >> testTheVulkanLayerRequiresTheExternalPharoVulkanProject [
	"The three Vulkan packages name PharoVulkan's bindings, its compiler and its driver, so the
	 group that loads them must fetch that project rather than assume an image that already
	 holds it. No package of the default stack requires it, which is the other half of the same
	 fact: the canvas and the rasteriser draw with no GPU and no Vulkan driver present."

	| requires |
	requires := Dictionary new.
	BaselineOfVectorGraphics project version packages do: [ :each |
		requires at: each name put: each requires asSet ].
	#( 'VectorGraphics-Vulkan' 'VectorGraphics-Vulkan-Examples'
	   'VectorGraphics-Vulkan-Tests' ) do: [ :each |
		self assert: ((requires at: each) includes: 'PharoVulkan') ].
	(self class packagesLoadedByGroupNamed: 'default') do: [ :each |
		self deny: ((requires at: each) includes: 'PharoVulkan') ]
]

{ #category : 'tests - dependencies' }
VGArchitectureTest >> testTrueTypeExamplesStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-TrueType-Examples'
]

{ #category : 'tests - dependencies' }
VGArchitectureTest >> testTrueTypeStaysInsideItsAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-TrueType'
]

{ #category : 'tests - dependencies' }
VGArchitectureTest >> testTrueTypeTestsStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-TrueType-Tests'
]

{ #category : 'tests' }
VGArchitectureTest >> testVulkanExamplesStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Vulkan-Examples'
]

{ #category : 'tests' }
VGArchitectureTest >> testVulkanStaysInsideItsAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Vulkan'
]

{ #category : 'tests' }
VGArchitectureTest >> testVulkanTestsStayInsideTheirAllowedDependencies [
	self assertEdgesOfPackageNamed: 'VectorGraphics-Vulkan-Tests'
]

{ #category : 'private' }
VGArchitectureTest >> tonelFileDefiningTheClassOf: aMethod [
	"The Tonel file of the package that owns the class a method of ours extends, or nil when the
	 class belongs to this project, or to a package no registered repository has on disk, as the
	 image's own packages do."

	| home repository |
	home := aMethod methodClass instanceSide package name.
	(self class projectPackageNames includes: home) ifTrue: [ ^ nil ].
	repository := IceRepository registry
		              detect: [ :each |
			              each workingCopy packages anySatisfy: [ :package |
				              package name = home ] ]
		              ifNone: [ ^ nil ].
	repository location ifNil: [ ^ nil ].
	^ (repository location / 'src' / home
	   / (aMethod methodClass instanceSide name , '.class.st')) ifNotNil: [ :file |
		  file exists ifTrue: [ file ] ifFalse: [ nil ] ]
]
