"
The documentation gates of `VectorGraphics-TrueType`: the package comment is held to the package's real tags, the examples of `VectorGraphics-TrueType-Examples` are run, and `doc/ARCHITECTURE.md` is held to the image.

`viewSubjects` names `TTGlyph` and `TTFontDescription`. The view gates read every inspector view the class declares, whichever package the method sits in, so `TTGlyph >> inspectorGlyph` — an extension method of `VectorGraphics-Text` — is built here too.
"
Class {
	#name : 'VGTrueTypeDocumentationTest',
	#superclass : 'VectorGraphicsDocumentationTest',
	#category : 'VectorGraphics-TrueType-Tests-Tests',
	#package : 'VectorGraphics-TrueType-Tests',
	#tag : 'Tests'
}

{ #category : 'testing' }
VGTrueTypeDocumentationTest class >> isAbstract [
	^ false
]

{ #category : 'accessing' }
VGTrueTypeDocumentationTest class >> packageUnderTest [
	^ PackageOrganizer default packageNamed: 'VectorGraphics-TrueType'
]

{ #category : 'accessing' }
VGTrueTypeDocumentationTest >> viewSubjects [
	^ {
		TTGlyph -> (TrueTypeExamples -> #glyphWithContours) .
		TTFontDescription -> (TrueTypeExamples -> #glyphMap) }
]
