"
The documentation gates of `VectorGraphics-Paths`: the package comment is held to the package's real tags, the examples of `VectorGraphics-Paths-Examples` are run, and `doc/ARCHITECTURE.md` is held to the image.

The path command and SVG classes carry no inspector view, so `viewSubjects` stays empty and the view gates pass without a subject. Give the classes a view and name it here, and the gates start holding it.
"
Class {
	#name : 'VGPathsDocumentationTest',
	#superclass : 'VectorGraphicsDocumentationTest',
	#category : 'VectorGraphics-Paths-Tests-Tests',
	#package : 'VectorGraphics-Paths-Tests',
	#tag : 'Tests'
}

{ #category : 'testing' }
VGPathsDocumentationTest class >> isAbstract [
	^ false
]

{ #category : 'accessing' }
VGPathsDocumentationTest class >> packageUnderTest [
	^ PackageOrganizer default packageNamed: 'VectorGraphics-Paths'
]
