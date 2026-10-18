Class {
	#name : 'BaselineOfVectorGraphics',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfVectorGraphics',
	#package : 'BaselineOfVectorGraphics'
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
			with: [ spec requires: #( 'VectorGraphics-Cairo' 'VectorGraphics-Cairo-Examples' ) ].
		spec
			group: 'core' with: #( 'VectorGraphics' );
			group: 'cairo' with: #( 'VectorGraphics-Cairo' );
			group: 'examples' with: #( 'VectorGraphics-Cairo-Examples' );
			group: 'tests' with: #( 'VectorGraphics-Cairo-Tests' );
			group: 'default' with: #( 'core' 'cairo' ) ]
]
