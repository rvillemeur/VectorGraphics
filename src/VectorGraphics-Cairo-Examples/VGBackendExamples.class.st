"
I hold the examples of VGBackend: the root of the backend hierarchy, whose class-side Boundary tab names the three messages a backend answers.
"
Class {
	#name : 'VGBackendExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Cairo-Examples-Examples',
	#package : 'VectorGraphics-Cairo-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGBackendExamples class >> backendBoundary [
	<sampleInstance>
	"The root of the backend hierarchy. Its class-side Boundary tab lists the three messages a
	 backend answers and which subclasses answer them, read from the hierarchy itself."

	^ VGBackend
]
