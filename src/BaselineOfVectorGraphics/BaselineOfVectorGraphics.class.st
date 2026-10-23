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
	"Every package names each package it really depends on, and not only the nearest one that
	 would drag the rest in: VGArchitectureTest holds this declaration against the references
	 the code makes. The one edge it cannot state is Cairo-Examples on Cairo-Tests, because the
	 reverse is stated and a cycle has no load order."

	spec for: #common do: [
		spec
			package: 'VectorGraphics';
			package: 'VectorGraphics-Cairo' with: [ spec requires: #( 'VectorGraphics' ) ];
			package: 'VectorGraphics-Cairo-Examples' with: [ spec requires: #( 'VectorGraphics-Cairo' ) ];
			package: 'VectorGraphics-Cairo-Tests'
			with: [ spec requires: #( 'VectorGraphics-Cairo' 'VectorGraphics-Cairo-Examples' ) ];
			package: 'VectorGraphics-Bloc' with: [ spec requires: #( 'VectorGraphics-Cairo' ) ];
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
						   'VectorGraphics-Vulkan' 'VectorGraphics-Vulkan-Examples' ) ].
		spec
			group: 'core' with: #( 'VectorGraphics' );
			group: 'cairo' with: #( 'VectorGraphics-Cairo' );
			group: 'bloc' with: #( 'VectorGraphics-Bloc' );
			group: 'vulkan' with: #( 'VectorGraphics-Vulkan' );
			group: 'examples'
			with: #( 'VectorGraphics-Cairo-Examples' 'VectorGraphics-Bloc-Examples'
			         'VectorGraphics-Vulkan-Examples' );
			group: 'tests'
			with: #( 'VectorGraphics-Cairo-Tests' 'VectorGraphics-Bloc-Tests'
			         'VectorGraphics-Vulkan-Tests' );
			group: 'default' with: #( 'core' 'cairo' 'bloc' ) ]
]
