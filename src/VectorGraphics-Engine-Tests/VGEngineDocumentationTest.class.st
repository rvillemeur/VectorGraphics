"
The documentation gates of `VectorGraphics-Engine`: the package comment is held to the package's real tags, the examples of `VectorGraphics-Engine-Examples` are run, and `doc/ARCHITECTURE.md` is held to the image.

`viewSubjects` names the four engine views and the example that feeds each: both engine views read `VectorCanvasExamples class >> engineDuringAFillPath`, since `VectorEngineAbstract` declares one and `VectorEnginePixel` the other.
"
Class {
	#name : 'VGEngineDocumentationTest',
	#superclass : 'VectorGraphicsDocumentationTest',
	#category : 'VectorGraphics-Engine-Tests-Tests',
	#package : 'VectorGraphics-Engine-Tests',
	#tag : 'Tests'
}

{ #category : 'testing' }
VGEngineDocumentationTest class >> isAbstract [
	^ false
]

{ #category : 'accessing' }
VGEngineDocumentationTest class >> packageUnderTest [
	^ PackageOrganizer default packageNamed: 'VectorGraphics-Engine'
]

{ #category : 'accessing' }
VGEngineDocumentationTest >> viewSubjects [
	^ {
		VectorEnginePixel -> (VectorCanvasExamples -> #engineDuringAFillPath) .
		VectorEngineAbstract -> (VectorCanvasExamples -> #engineDuringAFillPath) .
		VectorEngineBoundsFinder
		-> (VectorCanvasExamples -> #boundsFinderAfterMeasuringATriangle) .
		VectorCanvas -> (VectorCanvasExamples -> #canvasAfterADrawing) }
]
