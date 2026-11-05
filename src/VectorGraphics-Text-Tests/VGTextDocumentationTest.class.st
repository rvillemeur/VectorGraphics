"
The documentation gates of `VectorGraphics-Text`: the package comment is held to the package's real tags, the examples of `VectorGraphics-Text-Examples` are run, and `doc/ARCHITECTURE.md` is held to the image.

The package defines no class — it is the glue between the engine and the TrueType reader, six extension methods on classes of the two — so `viewSubjects` stays empty. Its one view, `TTGlyph >> inspectorGlyph`, is built by `VGTrueTypeDocumentationTest`, which names the class that declares it.
"
Class {
	#name : 'VGTextDocumentationTest',
	#superclass : 'VectorGraphicsDocumentationTest',
	#category : 'VectorGraphics-Text-Tests-Tests',
	#package : 'VectorGraphics-Text-Tests',
	#tag : 'Tests'
}

{ #category : 'testing' }
VGTextDocumentationTest class >> isAbstract [
	^ false
]

{ #category : 'accessing' }
VGTextDocumentationTest class >> packageUnderTest [
	^ PackageOrganizer default packageNamed: 'VectorGraphics-Text'
]
