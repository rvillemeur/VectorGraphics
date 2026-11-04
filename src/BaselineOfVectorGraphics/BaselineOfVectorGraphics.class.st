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
	"The load declaration of this project, in three parts so that no one method holds a block
	 per package: the external projects a layer needs, the packages and what each requires, and
	 the groups.

	 The default group is the engine and the Cairo backend alone. The Bloc renderer is a group
	 of its own because this project is Alexandrie's replacement inside Bloc, not a part of
	 Bloc: loading the default group must work in an image where no Bloc class exists, and
	 VGRenderer is a subclass of BARenderer. VGArchitectureTest holds both halves of that."

	spec for: #common do: [
		self declareExternalProjectsOn: spec.
		self declarePackagesOn: spec.
		self declareGroupsOn: spec ]
]

{ #category : 'baselines' }
BaselineOfVectorGraphics >> declareExternalProjectsOn: spec [
	"The projects outside this repository that a layer of it needs. Bloc is the only one: the
	 renderer of the bloc group subclasses BARenderer, so that group fetches Bloc rather than
	 assume an image that already holds it. The vulkan group names no project, because
	 PharoVulkan is not published; load it by hand before asking for that group."

	spec baseline: 'Bloc' with: [
		spec repository: 'github://pharo-graphics/Bloc:master' ]
]

{ #category : 'baselines' }
BaselineOfVectorGraphics >> declareGroupsOn: spec [
	"One group per layer, and a default group of the engine and the Cairo backend. A layer
	 above them is opt-in: 'bloc' is the renderer that replaces Alexandrie's canvas inside
	 Bloc, 'vulkan' the device backend.

	 The examples and the tests of each layer are a group of their own, because the
	 project-wide 'examples' and 'tests' groups span all three layers: asking for them fetches
	 Bloc and wants PharoVulkan, which a user of the Cairo backend alone wants neither of. The
	 two project-wide groups are declared as the union of the layer groups, so a layer that
	 gains a package is in both at once."

	spec
		group: 'core' with: #( 'VectorGraphics' );
		group: 'cairo' with: #( 'VectorGraphics-Cairo' );
		group: 'cairo-examples' with: #( 'VectorGraphics-Cairo-Examples' );
		group: 'cairo-tests' with: #( 'VectorGraphics-Cairo-Tests' );
		group: 'bloc' with: #( 'VectorGraphics-Bloc' );
		group: 'bloc-examples' with: #( 'VectorGraphics-Bloc-Examples' );
		group: 'bloc-tests' with: #( 'VectorGraphics-Bloc-Tests' );
		group: 'vulkan' with: #( 'VectorGraphics-Vulkan' );
		group: 'vulkan-examples' with: #( 'VectorGraphics-Vulkan-Examples' );
		group: 'vulkan-tests' with: #( 'VectorGraphics-Vulkan-Tests' );
		group: 'examples' with: #( 'cairo-examples' 'bloc-examples' 'vulkan-examples' );
		group: 'tests' with: #( 'cairo-tests' 'bloc-tests' 'vulkan-tests' );
		group: 'default' with: #( 'core' 'cairo' )
]

{ #category : 'baselines' }
BaselineOfVectorGraphics >> declarePackagesOn: spec [
	"Every package names each package it really depends on, and not only the nearest one that
	 would drag the rest in: VGArchitectureTest holds this declaration against the references
	 the code makes. The one edge it cannot state is Cairo-Examples on Cairo-Tests, because the
	 reverse is stated and a cycle has no load order."

	spec
		package: 'VectorGraphics';
		package: 'VectorGraphics-Cairo' with: [ spec requires: #( 'VectorGraphics' ) ];
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
