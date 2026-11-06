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
	"The load declaration of this project, in four parts so that no one method holds a block
	 per package: the external projects a layer needs, the rasteriser's own twelve packages,
	 the three backends above it, and the groups.
	 The default group is the rasteriser and the Cairo backend. The Bloc renderer is a group of
	 its own because this project is Alexandrie's replacement inside Bloc, not a part of Bloc:
	 loading the default group must work in an image where no Bloc class exists, and VGRenderer
	 is a subclass of BARenderer. VGArchitectureTest holds both halves of that."

	spec for: #common do: [
		self declareExternalProjectsOn: spec.
		self declareRasteriserPackagesOn: spec.
		self declareBackendPackagesOn: spec.
		self declareGroupsOn: spec ]
]

{ #category : 'baselines' }
BaselineOfVectorGraphics >> declareBackendPackagesOn: spec [
	"The three backends above the rasteriser: the Cairo one, the Bloc renderer that replaces
	 Alexandrie's canvas, and the Vulkan device path. Each names every package it really
	 depends on, and not only the nearest one that would drag the rest in: VGArchitectureTest
	 holds this declaration against the references the code makes. The one edge it cannot state
	 is Cairo-Examples on Cairo-Tests, because the reverse is stated and a cycle has no load
	 order. The Cairo backend names the font reader alone out of the four rasteriser packages,
	 which is why loading 'cairo' brings neither the scan-line engine nor the front page."

	spec
		package: 'VectorGraphics-Cairo'
		with: [ spec requires: #( 'VectorGraphics-TrueType' ) ];
		package: 'VectorGraphics-Cairo-Examples' with: [ spec requires: #( 'VectorGraphics-Cairo' ) ];
		package: 'VectorGraphics-Cairo-Tests'
		with: [ spec requires: #( 'VectorGraphics-Cairo' 'VectorGraphics-Cairo-Examples' ) ];
		package: 'VectorGraphics-Bloc' with: [ spec requires: #( 'Bloc' 'VectorGraphics-Cairo' ) ];
		package: 'VectorGraphics-Bloc-Examples'
		with: [ spec requires: #( 'VectorGraphics-Bloc' 'VectorGraphics-Cairo' ) ];
		package: 'VectorGraphics-Bloc-Tests'
		with: [
			spec requires:
					#( 'VectorGraphics-Bloc' 'VectorGraphics-Bloc-Examples' 'VectorGraphics-Cairo'
					   'VectorGraphics-Cairo-Tests' ) ];
		package: 'VectorGraphics-Vulkan'
		with: [ spec requires: #( 'VectorGraphics-Bloc' 'VectorGraphics-Cairo' ) ];
		package: 'VectorGraphics-Vulkan-Examples'
		with: [
			spec requires:
					#( 'VectorGraphics-Bloc' 'VectorGraphics-Cairo' 'VectorGraphics-Vulkan' ) ];
		package: 'VectorGraphics-Vulkan-Tests'
		with: [
			spec requires:
					#( 'VectorGraphics-Bloc' 'VectorGraphics-Cairo' 'VectorGraphics-Cairo-Tests'
					   'VectorGraphics-Vulkan' 'VectorGraphics-Vulkan-Examples' ) ]
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
BaselineOfVectorGraphics >> declareGroupsOn: spec [
	"One group per layer, and a default group of the rasteriser and the Cairo backend. A layer
	 above them is opt-in: 'bloc' is the renderer that replaces Alexandrie's canvas inside
	 Bloc, 'vulkan' the device backend.
	 The rasteriser is four groups of its own since the split, so a user can take the font
	 reader with no scan-line rasteriser, or the rasteriser with no font code: 'paths',
	 'engine', 'truetype' and 'text', with 'core' their union plus the front page. 'core' keeps
	 the name every existing loader uses, so loading it still brings the whole rasteriser.
	 The examples and the tests of each layer are a group of their own, because the
	 project-wide 'examples' and 'tests' groups span every layer: asking for them fetches
	 Bloc and wants PharoVulkan, which a user of the Cairo backend alone wants neither of. The
	 two project-wide groups are declared as the union of the layer groups, so a layer that
	 gains a package is in both at once. VectorGraphics-Tests needs no group of its own: every
	 layer's test package requires it, so it arrives with whichever tests are asked for.
	 'bloc' and 'vulkan' name 'core' as well as their own package, because before the split the
	 whole rasteriser arrived through the Cairo backend's requires and loading a backend must
	 keep bringing it: the backend itself names only the font reader.
	 'dev' is the group to work on this project from: the default stack, the tests of those
	 same layers, and MuTalk. It names the five test groups one by one rather than the
	 project-wide 'tests' group, so that it still loads in a plain Pharo image."

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
		group: 'cairo' with: #( 'VectorGraphics-Cairo' );
		group: 'cairo-examples' with: #( 'VectorGraphics-Cairo-Examples' );
		group: 'cairo-tests' with: #( 'VectorGraphics-Cairo-Tests' );
		group: 'bloc' with: #( 'core' 'VectorGraphics-Bloc' );
		group: 'bloc-examples' with: #( 'VectorGraphics-Bloc-Examples' );
		group: 'bloc-tests' with: #( 'VectorGraphics-Bloc-Tests' );
		group: 'vulkan' with: #( 'core' 'VectorGraphics-Vulkan' );
		group: 'vulkan-examples' with: #( 'VectorGraphics-Vulkan-Examples' );
		group: 'vulkan-tests' with: #( 'VectorGraphics-Vulkan-Tests' );
		group: 'examples'
		with: #( 'paths-examples' 'engine-examples' 'truetype-examples' 'text-examples'
			   'cairo-examples' 'bloc-examples' 'vulkan-examples' );
		group: 'tests'
		with: #( 'paths-tests' 'engine-tests' 'truetype-tests' 'text-tests' 'cairo-tests'
			   'bloc-tests' 'vulkan-tests' );
		group: 'default' with: #( 'core' 'cairo' );
		group: 'dev'
		with: #( 'default' 'paths-tests' 'engine-tests' 'truetype-tests' 'text-tests'
			   'cairo-tests' 'MuTalk' )
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
