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
