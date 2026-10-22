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

{ #category : 'examples' }
VGBackendExamples class >> selectionOnThisMachine [
	<sampleInstance>
	"The root of the backend hierarchy, with the preference forgotten and probed again, so that
	 its class-side Selection tab shows a verdict this machine really gave: which backends stand
	 for selection, in which order, which one a failure rejected and which one draws. Probing
	 opens a device and destroys it again, which is why the tab itself probes nothing."

	VGBackend clearPreference.
	VGBackend preferredClass.
	^ VGBackend
]
