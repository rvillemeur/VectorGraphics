"
I declare the packages of this project and how they load, for Metacello.
Each code package is named in `baseline:` with the packages it requires, and the groups are
`core`, `cairo`, `bloc`, `examples`, `tests` and `default`, which loads the three code layers.
Metacello finds me by name, so nothing in the image references me.
"
Class {
	#name : 'BaselineOfVectorGraphics',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfVectorGraphics-Baseline',
	#package : 'BaselineOfVectorGraphics',
	#tag : 'Baseline'
}

{ #category : 'baselines' }
BaselineOfVectorGraphics >> baseline: spec [
	<baseline>
	"The load declaration of this project, in six parts so that no one method holds a block
	 per package: the external projects a layer needs, the rasteriser's own twelve packages,
	 the three backends above it, the font engine above the Bloc renderer, the corpus and the
	 benchmarks beside them, and the groups.
	 The default group is the rasteriser and the canvas, which is three packages since the
	 split of 2026-11. The Bloc renderer is a group of its own because this project is
	 Alexandrie's replacement inside Bloc, not a part of Bloc: loading the default group must
	 work in an image where no Bloc class exists, and VGRenderer is a subclass of BARenderer.
	 VGArchitectureTest holds both halves of that.
	 The font engine is a group apart again: it writes the slots that decide what every space
	 of the image draws with, which loading a renderer must not do on its own."

	spec for: #common do: [
		self declareExternalProjectsOn: spec.
		self declareRasteriserPackagesOn: spec.
		self declareBackendPackagesOn: spec.
		self declareFontEnginePackagesOn: spec.
		self declareSupportPackagesOn: spec.
		self declareGroupsOn: spec ]
]

{ #category : 'baselines' }
BaselineOfVectorGraphics >> declareBackendPackagesOn: spec [
	"The backends above the rasteriser: the canvas, which is three packages of its own since the
	 split of 2026-11, the Bloc renderer that replaces Alexandrie's canvas, and the Vulkan device
	 path. Each names every package it really depends on, and not only the nearest one that would
	 drag the rest in: VGArchitectureTest holds this declaration against the references the code
	 makes.
	 The canvas trio is nearly a chain. The font layer is a leaf, so it names the font reader and
	 nothing else of this project. The canvas names the renderer and the font layer. The
	 renderer names the canvas back, four times, which is the one cycle of the trio and the one
	 edge left out here: VGArchitectureTest class >> edgesTheBaselineCannotDeclare holds it,
	 since a pair declared both ways has no load order. The second such edge is the canvas
	 examples on the canvas tests, which is the cycle the mirror packages make: the tests build
	 their subject from an example and an example of the architecture table reads the test class
	 that holds it.
	 Each of the three has its own examples and tests package, declared from the references each
	 one makes. The tests of the canvas require the tests of the renderer, which is an edge
	 between two test packages this project already allows elsewhere: the canvas tests draw a
	 frame through the backend fixture.
	 The Bloc renderer names the font reader as well as the canvas. The Bloc examples and the
	 Bloc tests name the reader as well since unit 3.7, where a catalogue entry is what a run of
	 text is shaped from. The Bloc tests also require the canvas tests, which the dependency
	 table cannot state: VGBlocExamplesTest subclasses VGCairoExamplesTest and names it nowhere
	 in a method.
	 The Vulkan packages are declared from a scan of their Tonel files, because they are not
	 loaded in any image this project is developed in: they name the canvas and the renderer, the
	 Vulkan tests name both test packages of those two, and no class of the font layer.
	 The corpus and the benchmark harness are declared by declareSupportPackagesOn:."

	spec
		package: 'VectorGraphics-Canvas-Fonts'
		with: [ spec requires: #( 'VectorGraphics-TrueType' ) ];
		package: 'VectorGraphics-Canvas-Raster';
		package: 'VectorGraphics-Canvas'
		with: [
			spec requires:
					#( 'VectorGraphics-Canvas-Fonts' 'VectorGraphics-Canvas-Raster' ) ];
		package: 'VectorGraphics-Canvas-Fonts-Examples'
		with: [
			spec requires:
					#( 'VectorGraphics-Canvas' 'VectorGraphics-Canvas-Fonts'
					   'VectorGraphics-Conformance' ) ];
		package: 'VectorGraphics-Canvas-Fonts-Tests'
		with: [
			spec requires:
					#( 'VectorGraphics-Canvas' 'VectorGraphics-Canvas-Fonts'
					   'VectorGraphics-Canvas-Fonts-Examples' 'VectorGraphics-Conformance'
					   'VectorGraphics-TrueType' 'VectorGraphics-TrueType-Tests' ) ];
		package: 'VectorGraphics-Canvas-Raster-Tests'
		with: [
			spec requires:
					#( 'VectorGraphics-Canvas' 'VectorGraphics-Canvas-Raster'
					   'VectorGraphics-Conformance' ) ];
		package: 'VectorGraphics-Canvas-Examples'
		with: [
			spec requires:
					#( 'VectorGraphics-Canvas' 'VectorGraphics-Canvas-Raster'
					   'VectorGraphics-Conformance' ) ];
		package: 'VectorGraphics-Canvas-Raster-Examples'
		with: [
			spec requires:
					#( 'VectorGraphics-Canvas' 'VectorGraphics-Canvas-Examples'
					   'VectorGraphics-Canvas-Raster' ) ];
		package: 'VectorGraphics-Canvas-Tests'
		with: [
			spec requires:
					#( 'VectorGraphics-Canvas' 'VectorGraphics-Canvas-Examples'
					   'VectorGraphics-Canvas-Fonts-Examples' 'VectorGraphics-Canvas-Raster'
					   'VectorGraphics-Canvas-Raster-Examples'
					   'VectorGraphics-Canvas-Raster-Tests' 'VectorGraphics-Conformance' ) ];
		package: 'VectorGraphics-Bloc'
		with: [
			spec requires:
					#( 'Bloc' 'VectorGraphics-Canvas' 'VectorGraphics-Canvas-Fonts'
					   'VectorGraphics-Canvas-Raster' 'VectorGraphics-TrueType' ) ];
		package: 'VectorGraphics-Bloc-Examples'
		with: [
			spec requires:
					#( 'VectorGraphics-Bloc' 'VectorGraphics-Canvas'
					   'VectorGraphics-Canvas-Fonts' 'VectorGraphics-TrueType' ) ];
		package: 'VectorGraphics-Bloc-Tests'
		with: [
			spec requires:
					#( 'VectorGraphics-Bloc' 'VectorGraphics-Bloc-Examples'
					   'VectorGraphics-Canvas' 'VectorGraphics-Canvas-Fonts'
					   'VectorGraphics-Canvas-Raster' 'VectorGraphics-Canvas-Tests'
					   'VectorGraphics-TrueType' ) ];
		package: 'VectorGraphics-Vulkan'
		with: [
			spec requires:
					#( 'VectorGraphics-Bloc' 'VectorGraphics-Canvas'
					   'VectorGraphics-Canvas-Raster' ) ];
		package: 'VectorGraphics-Vulkan-Examples'
		with: [
			spec requires:
					#( 'VectorGraphics-Benchmarks' 'VectorGraphics-Bloc' 'VectorGraphics-Canvas'
					   'VectorGraphics-Canvas-Raster' 'VectorGraphics-Vulkan' ) ];
		package: 'VectorGraphics-Vulkan-Tests'
		with: [
			spec requires:
					#( 'VectorGraphics-Benchmarks' 'VectorGraphics-Bloc'
					   'VectorGraphics-Canvas' 'VectorGraphics-Canvas-Raster'
					   'VectorGraphics-Canvas-Raster-Tests' 'VectorGraphics-Canvas-Tests'
					   'VectorGraphics-Conformance' 'VectorGraphics-Vulkan'
					   'VectorGraphics-Vulkan-Examples' ) ]
]

{ #category : 'baselines' }
BaselineOfVectorGraphics >> declareExternalProjectsOn: spec [
	"The projects outside this repository that a layer or a group of it needs. Bloc: the
	 renderer of the bloc group subclasses BARenderer, so that group fetches Bloc rather than
	 assume an image that already holds it. MuTalk: the mutation tester the dev group brings,
	 pinned to a tag because it rewrites production methods in the image and the version doing
	 the rewriting is part of this project's setup — Bloc is pinned to master only because it
	 publishes no release tags. The vulkan group names no project, because PharoVulkan is not
	 published; load it by hand before asking for that group."

	spec
		baseline: 'Bloc'
		with: [ spec repository: 'github://pharo-graphics/Bloc:master' ];
		baseline: 'MuTalk'
		with: [
		spec repository: 'github://pharo-contributions/mutalk:v3.0.8/src' ]
]

{ #category : 'baselines' }
BaselineOfVectorGraphics >> declareFontEnginePackagesOn: spec [
	"The font engine, in three packages of its own above the Bloc renderer. It is apart from
	 VectorGraphics-Bloc because it does one thing that package must not do on its own: write
	 Bloc's renderer slot and upstream's font manager slot, which changes what every space of
	 the image draws with. A reader who wants the renderer and no such change loads 'bloc'; one
	 who wants the change loads 'fonts'.
	 The postLoadDoIt: is what makes that group transparent: Metacello sends it to me once the
	 engine's package is in, and the route is posed before the load returns. It is attached to
	 the package rather than to the group, so it runs once however the package arrives.
	 The tests name the font layer of the canvas, and require the canvas test package, which the
	 dependency table cannot state: VGFontEngineExamplesTest subclasses VGCairoExamplesTest and
	 names it nowhere in a method."

	spec
		package: 'VectorGraphics-Bloc-FontEngine'
		with: [
			spec
				requires: #( 'VectorGraphics-Bloc' );
				postLoadDoIt: #installTheFontEngine ];
		package: 'VectorGraphics-Bloc-FontEngine-Examples'
		with: [
			spec requires:
					#( 'VectorGraphics-Bloc-FontEngine' 'VectorGraphics-TrueType' ) ];
		package: 'VectorGraphics-Bloc-FontEngine-Tests'
		with: [
			spec requires:
					#( 'VectorGraphics-Bloc' 'VectorGraphics-Bloc-FontEngine'
					   'VectorGraphics-Bloc-FontEngine-Examples' 'VectorGraphics-Canvas-Fonts'
					   'VectorGraphics-Canvas-Tests' 'VectorGraphics-TrueType' ) ]
]

{ #category : 'baselines' }
BaselineOfVectorGraphics >> declareGroupsOn: spec [
	"One group per layer, and a default group of the rasteriser and the canvas. A layer above
	 them is opt-in: 'bloc' is the renderer that replaces Alexandrie's canvas inside Bloc,
	 'vulkan' the device backend.
	 The rasteriser is four groups of its own since the split, so a user can take the font
	 reader with no scan-line rasteriser, or the rasteriser with no font code: 'paths',
	 'engine', 'truetype' and 'text', with 'core' their union plus the front page. 'core' keeps
	 the name every existing loader uses, so loading it still brings the whole rasteriser.
	 The canvas is three groups of its own since the split of 2026-11, for the same reason:
	 'canvas' is the canvas API and, through its requires, the renderer and the font layer below
	 it; 'canvas-raster' is the scan-line renderer of a display list, which needs no device, no
	 library and no window; 'canvas-fonts' is the font and glyph layer, a leaf above the font
	 reader. 'default' names the three one by one rather than 'canvas' alone, so what it loads
	 is read from the group list and not from a chain of requires.
	 The examples and the tests of each layer are a group of their own, because the
	 project-wide 'examples' and 'tests' groups span every layer: asking for them fetches
	 Bloc and wants PharoVulkan, which a user of the canvas alone wants neither of. The
	 two project-wide groups are declared as the union of the layer groups, so a layer that
	 gains a package is in both at once. VectorGraphics-Tests needs no group of its own: every
	 layer's test package requires it, so it arrives with whichever tests are asked for.
	 'bloc' and 'vulkan' name 'core' as well as their own package, because before the split the
	 whole rasteriser arrived through the canvas's requires and loading a backend must keep
	 bringing it: the backend itself names only the font reader.
	 'dev' is the group to work on this project from: the default stack, the tests of those
	 same layers, and MuTalk. It names the test groups one by one rather than the
	 project-wide 'tests' group, so that it still loads in a plain Pharo image.
	 'conformance' is the corpus the backends are compared against and 'benchmarks' the
	 harness that measures them. Neither holds a TestCase, and each is a group of its own so
	 that it loads with no test package at all."

	spec
		group: 'paths' with: #( 'VectorGraphics-Paths' );
		group: 'paths-examples' with: #( 'VectorGraphics-Paths-Examples' );
		group: 'paths-tests' with: #( 'VectorGraphics-Paths-Tests' );
		group: 'engine' with: #( 'VectorGraphics-Engine' );
		group: 'engine-examples' with: #( 'VectorGraphics-Engine-Examples' );
		group: 'engine-tests' with: #( 'VectorGraphics-Engine-Tests' );
		group: 'truetype' with: #( 'VectorGraphics-TrueType' );
		group: 'truetype-examples' with: #( 'VectorGraphics-TrueType-Examples' );
		group: 'truetype-tests' with: #( 'VectorGraphics-TrueType-Tests' );
		group: 'text' with: #( 'VectorGraphics-Text' );
		group: 'text-examples' with: #( 'VectorGraphics-Text-Examples' );
		group: 'text-tests' with: #( 'VectorGraphics-Text-Tests' );
		group: 'core' with: #( 'VectorGraphics' 'paths' 'engine' 'truetype' 'text' );
		group: 'canvas' with: #( 'VectorGraphics-Canvas' );
		group: 'canvas-examples' with: #( 'VectorGraphics-Canvas-Examples' );
		group: 'canvas-tests' with: #( 'VectorGraphics-Canvas-Tests' );
		group: 'canvas-raster' with: #( 'VectorGraphics-Canvas-Raster' );
		group: 'canvas-raster-examples'
			with: #( 'VectorGraphics-Canvas-Raster-Examples' );
		group: 'canvas-raster-tests' with: #( 'VectorGraphics-Canvas-Raster-Tests' );
		group: 'canvas-fonts' with: #( 'VectorGraphics-Canvas-Fonts' );
		group: 'canvas-fonts-examples'
			with: #( 'VectorGraphics-Canvas-Fonts-Examples' );
		group: 'canvas-fonts-tests' with: #( 'VectorGraphics-Canvas-Fonts-Tests' );
		group: 'bloc' with: #( 'core' 'VectorGraphics-Bloc' );
		group: 'bloc-examples' with: #( 'VectorGraphics-Bloc-Examples' );
		group: 'bloc-tests' with: #( 'VectorGraphics-Bloc-Tests' );
		group: 'fonts'
			with: #( 'truetype' 'canvas' 'VectorGraphics-Bloc'
			   'VectorGraphics-Bloc-FontEngine' );
		group: 'fonts-examples' with: #( 'VectorGraphics-Bloc-FontEngine-Examples' );
		group: 'fonts-tests' with: #( 'VectorGraphics-Bloc-FontEngine-Tests' );
		group: 'vulkan' with: #( 'core' 'VectorGraphics-Vulkan' );
		group: 'vulkan-examples' with: #( 'VectorGraphics-Vulkan-Examples' );
		group: 'vulkan-tests' with: #( 'VectorGraphics-Vulkan-Tests' );
		group: 'conformance' with: #( 'VectorGraphics-Conformance' );
		group: 'benchmarks' with: #( 'VectorGraphics-Benchmarks' );
		group: 'examples'
		with: #( 'paths-examples' 'engine-examples' 'truetype-examples' 'text-examples'
			   'canvas-examples' 'canvas-raster-examples' 'canvas-fonts-examples'
			   'bloc-examples' 'fonts-examples' 'vulkan-examples' );
		group: 'tests'
		with: #( 'paths-tests' 'engine-tests' 'truetype-tests' 'text-tests' 'canvas-tests'
			   'canvas-raster-tests' 'canvas-fonts-tests' 'bloc-tests' 'fonts-tests'
			   'vulkan-tests' );
		group: 'default' with: #( 'core' 'canvas' 'canvas-raster' 'canvas-fonts' );
		group: 'dev'
		with: #( 'default' 'paths-tests' 'engine-tests' 'truetype-tests' 'text-tests'
			   'canvas-tests' 'canvas-raster-tests' 'canvas-fonts-tests' 'MuTalk' )
]

{ #category : 'baselines' }
BaselineOfVectorGraphics >> declareRasteriserPackagesOn: spec [
	"The pure-Pharo rasteriser, in four packages since the split, with the front page that holds
	 no code and the abstract documentation gate the four test packages subclass.
	 A few edges here are not references and so cannot appear in VGArchitectureTest class >>
	 allowedDependencies, which reads what a method names: the four documentation gates subclass
	 VectorGraphicsDocumentationTest in VectorGraphics-Tests, and the text tests and examples
	 exercise the glue of VectorGraphics-Text, which is extension methods on classes of other
	 packages and therefore names nothing. Without those requires the group loads and the suite
	 then fails on a missing superclass or a missing method."

	spec
		package: 'VectorGraphics';
		package: 'VectorGraphics-Tests';
		package: 'VectorGraphics-Paths';
		package: 'VectorGraphics-Paths-Examples'
		with: [ spec requires: #( 'VectorGraphics-Engine' 'VectorGraphics-Paths' ) ];
		package: 'VectorGraphics-Paths-Tests'
		with: [
			spec requires:
					#( 'VectorGraphics-Paths' 'VectorGraphics-Paths-Examples'
					   'VectorGraphics-Tests' ) ];
		package: 'VectorGraphics-Engine';
		package: 'VectorGraphics-Engine-Examples'
		with: [ spec requires: #( 'VectorGraphics-Engine' ) ];
		package: 'VectorGraphics-Engine-Tests'
		with: [
			spec requires:
					#( 'VectorGraphics-Engine' 'VectorGraphics-Engine-Examples'
					   'VectorGraphics-Paths' 'VectorGraphics-Tests' ) ];
		package: 'VectorGraphics-TrueType'
		with: [ spec requires: #( 'VectorGraphics-Paths' ) ];
		package: 'VectorGraphics-TrueType-Examples'
		with: [ spec requires: #( 'VectorGraphics-TrueType' ) ];
		package: 'VectorGraphics-TrueType-Tests'
		with: [
			spec requires:
					#( 'VectorGraphics-Paths' 'VectorGraphics-TrueType'
					   'VectorGraphics-TrueType-Examples' 'VectorGraphics-Tests' ) ];
		package: 'VectorGraphics-Text'
		with: [ spec requires: #( 'VectorGraphics-Engine' 'VectorGraphics-TrueType' ) ];
		package: 'VectorGraphics-Text-Examples'
		with: [
			spec requires:
					#( 'VectorGraphics-Engine' 'VectorGraphics-Text' 'VectorGraphics-TrueType' ) ];
		package: 'VectorGraphics-Text-Tests'
		with: [
			spec requires:
					#( 'VectorGraphics-Engine' 'VectorGraphics-Tests' 'VectorGraphics-Text'
					   'VectorGraphics-Text-Examples' 'VectorGraphics-TrueType' ) ]
]

{ #category : 'baselines' }
BaselineOfVectorGraphics >> declareSupportPackagesOn: spec [
	"The two packages that hold neither a layer nor a suite: the corpus every backend is
	 compared against, and the harness that measures a frame through each of them. Both lived
	 in a -Tests package until the review of 2026-11, which made an examples package depend
	 on a test package; neither holds a TestCase, and each is a group of its own so that it
	 loads with no suite in the image.
	 The corpus names VectorGraphics-TrueType since unit 5.2 of the font plan: the experiments
	 ported from Alexandrie read their font out of this project's own catalogue, where they
	 read it out of the global FreeType font manager before.
	 The corpus draws text, so it names the font layer of the canvas as well as the canvas and
	 its renderer. The harness names no font class: it measures a frame of the corpus through a
	 backend."

	spec
		package: 'VectorGraphics-Conformance'
		with: [
			spec requires:
					#( 'VectorGraphics-Canvas' 'VectorGraphics-Canvas-Fonts'
					   'VectorGraphics-Canvas-Raster' 'VectorGraphics-TrueType' ) ];
		package: 'VectorGraphics-Benchmarks'
		with: [
			spec requires:
					#( 'VectorGraphics-Bloc' 'VectorGraphics-Canvas'
					   'VectorGraphics-Canvas-Raster' 'VectorGraphics-Conformance'
					   'VectorGraphics-Vulkan' ) ]
]

{ #category : 'baselines' }
BaselineOfVectorGraphics >> installTheFontEngine [
	"The hook the engine's package carries, sent by Metacello once that package is loaded: it
	 poses the font manager and the renderer that make Bloc draw text with this project's
	 glyphs. A machine holding none of the families VGFontManager class >>
	 preferredTextFamilyNames names raises VGFontManagerHasNoUsableFamily here, and the load
	 fails — which is the decision taken for this group: an image that cannot draw with our
	 fonts must say so, not keep FreeType and look as though it had switched.
	 The class is named through the environment, because the hook is compiled into a baseline
	 that must still load in an image where this project is absent."

	^ (self class environment at: #VGFontEngine) install
]
