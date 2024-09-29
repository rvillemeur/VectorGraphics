Class {
	#name : #BaselineOfVectorGraphics,
	#superclass : #BaselineOf,
	#category : #BaselineOfVectorGraphics
}

{ #category : #baseline }
BaselineOfVectorGraphics >> baseline: spec [
	<baseline>
	spec for: #common do: [ spec

		package: 'VectorGraphics'.
]
]
