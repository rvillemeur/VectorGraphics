"
I hold the unit 1.9 export examples: a finished PDF page and a finished SVG page.
Each page is written into a memory file system rather than onto disk, because an example is run
by a click in the browser and by the example tests, and neither should leave a file behind.
One click opens an inspector whose Document tab shows the document that was written and whose
Picture tab shows the pixels it carries.
"
Class {
	#name : 'VGCairoExportSurfaceExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Cairo-Examples-Examples',
	#package : 'VectorGraphics-Cairo-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGCairoExportSurfaceExamples class >> pageOfTwoPatchesOn: aSurfaceClass [
	"The page both examples draw, written into a memory file system so nothing reaches disk."

	| page context |
	page := aSurfaceClass
		        extent: 80 @ 60
		        to: FileSystem memory root / ('page.' , aSurfaceClass fileExtension).
	context := page newContext.
	context sourceColorR: 0.9 g: 0.2 b: 0.1 a: 1.0.
	context
		rectangleX: 8 y: 8 width: 40 height: 24;
		fill.
	context sourceColorR: 0.1 g: 0.3 b: 0.9 a: 0.5.
	context
		circleCenterX: 52 y: 38 radius: 18;
		fill.
	page finish.
	^ page
]

{ #category : 'examples' }
VGCairoExportSurfaceExamples class >> pdfPageOfTwoPatches [
	<sampleInstance>
	"A finished PDF page of an opaque patch and a translucent one, so the document carries both a
	 colour image and the soft mask that holds the alpha."

	^ self pageOfTwoPatchesOn: VGCairoPDFSurface
]

{ #category : 'examples' }
VGCairoExportSurfaceExamples class >> svgPageOfTwoPatches [
	<sampleInstance>
	"A finished SVG page of the same two patches. The alpha travels inside the embedded graphic
	 here, because that format carries an alpha channel of its own."

	^ self pageOfTwoPatchesOn: VGCairoSVGSurface
]
