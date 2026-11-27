"
I hold the examples of this project's documentation tabs, one click each from the browser.

`architectureOfTheFontPackage` answers the renderer of the font package's declarations, which is what the *Architecture* tab of `VectorGraphics-Canvas-Fonts` shows. `objectGraphOfAWarmScaledFont` measures one run first, so the graph it answers shows the outlines the face cached while measuring and an atlas still empty, which is the point of that tab: it says what this font holds, not what a font may hold.

Both answer an object whose own inspector draws the picture, so an example here needs no window of its own.
"
Class {
	#name : 'VGDocumentationExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Documentation-Examples',
	#package : 'VectorGraphics-Documentation-Examples'
}

{ #category : 'examples' }
VGDocumentationExamples class >> architectureOfTheFontPackage [
	"The diagram a reader sees in the Architecture tab of the font package: one box per class of
	 VectorGraphics-Canvas-Fonts, a solid line for each holding declared there, a dashed one for
	 each cache and a faint one for each reference the declarations do not mention."

	<sampleInstance>
	^ ArchDocGraphRenderer onPackageNamed: 'VectorGraphics-Canvas-Fonts'
]

{ #category : 'examples' }
VGDocumentationExamples class >> fontRouteMap [
	"The component map of the font route: six parts over the two packages of slice one. Its
	 diagram tab is the picture that answers the heap of class names."

	<sampleInstance>
	^ VGFontRouteMap new
]

{ #category : 'examples' }
VGDocumentationExamples class >> objectGraphOfAWarmScaledFont [
	"The graph a reader sees in the Object graph tab, after one run has been measured: the face now
	 holds an outline per letter of the run, because measuring reads them, while the glyph atlas is
	 still empty, because nothing has been rasterised yet. That is the difference between what a
	 font may hold and what this font holds."

	<sampleInstance>
	| font |
	font := VGScaledFontExamples scaledFontAtAReadableSize.
	font textExtentsOf: VGScaledFontExamples exampleRun.
	^ ArchDocObjectGraph of: font
]

{ #category : 'examples' }
VGDocumentationExamples class >> objectGraphOfTheSharedFontManager [
	"The Bloc side of the route, walked from the manager Bloc asks for a face: the catalogue it
	 answers from, and the one face a draw has made it parse. A face is read here on purpose —
	 a manager nobody has drawn with keeps none, and a graph of such a manager shows the
	 catalogue alone, which is the truth about it and a poor picture of the route."

	<sampleInstance>
	| manager |
	manager := VGFontManager withDefaultFaces.
	manager defaultFaceOfFirstFamilyNamedIn: { manager familyNames first }.
	^ ArchDocObjectGraph of: manager
]

{ #category : 'examples' }
VGDocumentationExamples class >> projectPackageGraph [
	"Where the font packages sit in this project: forty-five packages, the arrows between them,
	 and VectorGraphics-Canvas-Fonts filled apart from the rest."

	<sampleInstance>
	| package |
	package := Smalltalk packageOrganizer packageNamed: 'VectorGraphics-Canvas-Fonts'.
	^ ArchDocPackageRenderer
		onProject: package archDocProject
		focusing: package
]

{ #category : 'examples' }
VGDocumentationExamples class >> readingOrderOfTheFontPackage [
	"Which class of the font package to read first: the thirteen classes weighed by their source
	 and by how much of the package reaches them. Open the Where to start tab."

	<sampleInstance>
	| package |
	package := Smalltalk packageOrganizer packageNamed: 'VectorGraphics-Canvas-Fonts'.
	^ ArchDocReadingOrder on: (ArchDocModel onPackage: package) graph
]
