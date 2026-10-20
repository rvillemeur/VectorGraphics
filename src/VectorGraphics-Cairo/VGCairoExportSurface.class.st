"
I am a page of a container format: the surface Bloc's BAPdfExporter and BASvgExporter ask for
with #extent:to:, and the Alexandrie class I stand in for is AeCairoExportSurface.
My extent is given in points, one point being one seventy second of an inch, and I write my
document into my target file when I am finished.

Cairo records the drawing operators sent to one of these surfaces and emits them as vector
drawing in the container format, so a Cairo page is resolution independent. I cannot: by the
time a drawing reaches me it is a display list of flattened polygons, and the curves, the text
and the gradients it came from are gone, so a faithful vector page is not derivable from what I
hold. I therefore rasterise the page and embed the pixels, which is what a reader of the
document sees, and what the exporters that write a file for a human to look at need.

The page is rasterised at one device pixel to the point. That is not a quality setting with a
better value: the surface protocol I inherit answers my pixels to #extent, Cairo's export
surface answers its points to the same selector, and the callers inventoried in VGCairoInventory
send it, so the two readings have to agree.

A subclass names the container format: #fileExtension and #documentPrefix say what the document
is, and #writeDocumentOn: writes it. VGCairoExportSurfaceTest holds both subclasses to their own
prefix, and reads the written document back to compare what it carries against my pixels.
"
Class {
	#name : 'VGCairoExportSurface',
	#superclass : 'VGCairoImageSurface',
	#instVars : [
		'pageExtent',
		'target'
	],
	#category : 'VectorGraphics-Cairo-Export',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Export'
}

{ #category : 'constants' }
VGCairoExportSurface class >> documentPrefix [
	"The bytes a document of this container format begins with. The writer writes them and
	 VGCairoExportSurfaceTest reads them back, so the two cannot drift apart."

	^ self subclassResponsibility
]

{ #category : 'instance creation' }
VGCairoExportSurface class >> extent: aPoint to: aFileReference [
	"A page of the given size in points, written to the given file when the page is finished. One
	 point is one seventy second of an inch, which is what it is in Cairo. The pixels are rounded
	 up, because a fractional page still has to own whole pixels."

	^ (self newFormat: VGCairoSurfaceFormat argb32 extent: aPoint ceiling)
		  setPageExtent: aPoint target: aFileReference;
		  yourself
]

{ #category : 'instance creation' }
VGCairoExportSurface class >> extent: aPoint toPathString: aString [
	"Cairo needs a C string for its own constructor, so Alexandrie offers this entry as well as
	 the one that takes a file reference. Ours takes the reference, and this is here for a caller
	 written against Alexandrie."

	^ self extent: aPoint to: aString asFileReference
]

{ #category : 'constants' }
VGCairoExportSurface class >> fileExtension [
	"The extension of the file this container format is written to, without a dot."

	^ self subclassResponsibility
]

{ #category : 'private' }
VGCairoExportSurface >> alphaBytes [
	"The alpha of every pixel, the top row first."

	| bytes |
	bytes := ByteArray new: width * height.
	0 to: height - 1 do: [ :y |
		0 to: width - 1 do: [ :x |
			bytes
				at: y * width + x + 1
				put: ((self straightAlphaPixelAtX: x y: y) bitShift: -24) ] ].
	^ bytes
]

{ #category : 'writing' }
VGCairoExportSurface >> documentBytes [
	"The whole document as bytes, which is what #finish writes to my target. Building it reads my
	 pixels, so it draws what I still owe, as every other reader of my pixels does."

	^ ByteArray streamContents: [ :out | self writeDocumentOn: out ]
]

{ #category : 'lifecycle' }
VGCairoExportSurface >> finish [
	"Write my document, which is where Cairo emits its own: a page is a file once it is finished.
	 Finishing twice writes nothing, because Cairo treats a second finish as nothing to do and
	 Bloc's exporters cascade flush and finish over a page a caller may have finished already."

	| bytes |
	self isFinished ifTrue: [ ^ self ].
	self flush.
	bytes := self documentBytes.
	target ensureDelete.
	target binaryWriteStreamDo: [ :out | out nextPutAll: bytes ].
	^ super finish
]

{ #category : 'private' }
VGCairoExportSurface >> hasPixels [
	"Neither container format admits an image of no width or no height, so a degenerate page
	 carries no image at all and is still a well formed document."

	^ width > 0 and: [ height > 0 ]
]

{ #category : 'inspector' }
VGCairoExportSurface >> inspectorDocument: aBuilder [
	<inspectorPresentationOrder: 12 title: 'Document'>
	"The document I would write, built in memory, so looking at a page does not write its file."

	^ aBuilder newText
		  text: self printableDocument;
		  beNotEditable;
		  yourself
]

{ #category : 'inspector' }
VGCairoExportSurface >> inspectorDocumentContext: aContext [
	aContext active: pageExtent notNil
]

{ #category : 'private' }
VGCairoExportSurface >> newLine [
	"The line end of a written document. Both formats take a single line feed, and it is built
	 rather than written as a literal because a line feed inside Pharo source is forbidden."

	^ String lf
]

{ #category : 'private' }
VGCairoExportSurface >> numberString: aNumber [
	"A whole number of points is written without a fraction, which is what a page box of whole
	 points reads like in either format, and anything else as a float."

	^ aNumber isInteger
		  ifTrue: [ aNumber printString ]
		  ifFalse: [ aNumber asFloat printString ]
]

{ #category : 'accessing' }
VGCairoExportSurface >> pageExtent [
	"My size in points, which is what Cairo's export surface answers to #extent. My own #extent
	 answers pixels, and the two agree because one point of a page gets one pixel."

	^ pageExtent
]

{ #category : 'private' }
VGCairoExportSurface >> printableDocument [
	"My document as text, with every byte that is not printable shown as a full stop, because a
	 page carries its pixels as binary inside an otherwise textual document."

	^ String streamContents: [ :out |
		  self documentBytes do: [ :each |
			  out nextPut: (((each between: 32 and: 126) or: [ each = Character lf value ])
					   ifTrue: [ Character value: each ]
					   ifFalse: [ $. ]) ] ]
]

{ #category : 'private' }
VGCairoExportSurface >> rgbBytes [
	"The three colour channels of every pixel, the top row first, with the stored premultiplication
	 divided back out, because both container formats carry straight alpha."

	| bytes |
	bytes := ByteArray new: width * height * 3.
	0 to: height - 1 do: [ :y |
		0 to: width - 1 do: [ :x |
			| pixel at |
			pixel := self straightAlphaPixelAtX: x y: y.
			at := (y * width + x) * 3.
			bytes at: at + 1 put: ((pixel bitShift: -16) bitAnd: 255).
			bytes at: at + 2 put: ((pixel bitShift: -8) bitAnd: 255).
			bytes at: at + 3 put: (pixel bitAnd: 255) ] ].
	^ bytes
]

{ #category : 'initialization' }
VGCairoExportSurface >> setPageExtent: aPoint target: aFileReference [
	pageExtent := aPoint.
	target := aFileReference
]

{ #category : 'accessing' }
VGCairoExportSurface >> target [
	"The file my document is written to when I am finished."

	^ target
]

{ #category : 'writing' }
VGCairoExportSurface >> writeDocumentOn: aBinaryStream [
	^ self subclassResponsibility
]

{ #category : 'private' }
VGCairoExportSurface >> writeLine: aString on: aBinaryStream [
	aBinaryStream nextPutAll: aString utf8Encoded.
	self writeNewLineOn: aBinaryStream
]

{ #category : 'private' }
VGCairoExportSurface >> writeNewLineOn: aBinaryStream [
	aBinaryStream nextPutAll: self newLine utf8Encoded
]
