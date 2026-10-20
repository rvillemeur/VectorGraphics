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
	spec for: #common do: [
		spec
			package: 'VectorGraphics';
			package: 'VectorGraphics-Cairo' with: [ spec requires: #( 'VectorGraphics' ) ];
			package: 'VectorGraphics-Cairo-Examples' with: [ spec requires: #( 'VectorGraphics-Cairo' ) ];
			package: 'VectorGraphics-Cairo-Tests'
			with: [ spec requires: #( 'VectorGraphics-Cairo' 'VectorGraphics-Cairo-Examples' ) ];
			package: 'VectorGraphics-Bloc' with: [ spec requires: #( 'VectorGraphics-Cairo' ) ];
			package: 'VectorGraphics-Bloc-Examples' with: [ spec requires: #( 'VectorGraphics-Bloc' ) ];
			package: 'VectorGraphics-Bloc-Tests'
			with: [
				spec requires:
						#( 'VectorGraphics-Bloc' 'VectorGraphics-Bloc-Examples'
						   'VectorGraphics-Cairo-Tests' ) ].
		spec
			group: 'core' with: #( 'VectorGraphics' );
			group: 'cairo' with: #( 'VectorGraphics-Cairo' );
			group: 'bloc' with: #( 'VectorGraphics-Bloc' );
			group: 'examples'
			with: #( 'VectorGraphics-Cairo-Examples' 'VectorGraphics-Bloc-Examples' );
			group: 'tests' with: #( 'VectorGraphics-Cairo-Tests' 'VectorGraphics-Bloc-Tests' );
			group: 'default' with: #( 'core' 'cairo' 'bloc' ) ]
]
