"
I hold the export surfaces of unit 1.9: the PDF and SVG pages Bloc's BAPdfExporter and
BASvgExporter ask Alexandrie for with #extent:to:.
I write every page into a memory file system, so a test leaves nothing on disk, and I read the
written document back as bytes and compare what it carries against the pixels of the surface
itself.
Cairo emits vector drawing operators into these two formats and we embed one raster image per
page, so these tests are about the document our writer produces, not about matching Cairo byte
for byte, which no raster page can do.
"
Class {
	#name : 'VGCairoExportSurfaceTest',
	#superclass : 'TestCase',
	#instVars : [
		'fileSystem'
	],
	#category : 'VectorGraphics-Cairo-Tests-Tests',
	#package : 'VectorGraphics-Cairo-Tests',
	#tag : 'Tests'
}

{ #category : 'private' }
VGCairoExportSurfaceTest >> alphaBytesOf: aSurface [
	"The alpha of every pixel, the top row first, which is what a soft mask of the page carries."

	| bytes |
	bytes := ByteArray new: aSurface width * aSurface height.
	0 to: aSurface height - 1 do: [ :y |
		0 to: aSurface width - 1 do: [ :x |
			bytes
				at: y * aSurface width + x + 1
				put: ((aSurface straightAlphaPixelAtX: x y: y) bitShift: -24) ] ].
	^ bytes
]

{ #category : 'private' }
VGCairoExportSurfaceTest >> bytesOf: aFileReference [
	^ aFileReference binaryReadStreamDo: [ :in | in upToEnd ]
]

{ #category : 'private' }
VGCairoExportSurfaceTest >> crossReferenceOffsetOf: anInteger in: aString [
	"An entry of a cross reference table is the twenty bytes the format fixes: ten of offset, five
	 of generation, one of keyword and two of line end. Object zero holds the first entry, which
	 is why the offset of object n is n entries in."

	| tableStart firstLineEnd firstEntry entry |
	tableStart := aString indexOfSubCollection: 'xref'.
	self assert: tableStart > 0 description: 'the document carries no cross reference table'.
	firstLineEnd := aString indexOf: Character lf startingAt: tableStart.
	firstEntry := (aString indexOf: Character lf startingAt: firstLineEnd + 1) + 1.
	entry := firstEntry + (anInteger * 20).
	^ (aString copyFrom: entry to: entry + 9) asInteger
]

{ #category : 'private' }
VGCairoExportSurfaceTest >> dataUriPayloadIn: aString [
	"The base64 payload of the one data URI the document carries."

	| start stop |
	start := (aString indexOfSubCollection: 'base64,') + 'base64,' size.
	self assert: start > 'base64,' size description: 'the document carries no data URI'.
	stop := (aString indexOf: $" startingAt: start) - 1.
	^ aString copyFrom: start to: stop
]

{ #category : 'private' }
VGCairoExportSurfaceTest >> drawTwoPatchesOn: aSurface [
	"Two overlapping fills, the second one translucent, so the written document carries a colour
	 and an alpha that both vary from pixel to pixel."

	| context |
	context := aSurface newContext.
	context
		sourceColorR: 1 g: 0 b: 0 a: 1;
		rectangleX: 1 y: 1 width: 6 height: 4;
		fill.
	context
		sourceColorR: 0 g: 0 b: 1 a: 0.5;
		rectangleX: 4 y: 2 width: 4 height: 5;
		fill.
	^ aSurface
]

{ #category : 'private' }
VGCairoExportSurfaceTest >> numberAfter: aKey in: aString from: anIndex [
	| at |
	at := aString indexOfSubCollection: aKey startingAt: anIndex.
	self
		assert: at > 0
		description: 'the document carries no ' , aKey , ' after ' , anIndex printString.
	^ Number readFrom: (aString readStream skip: at + aKey size - 1; yourself)
]

{ #category : 'private' }
VGCairoExportSurfaceTest >> pdfPageOfExtent: aPointExtent [
	^ VGCairoPDFSurface
		  extent: aPointExtent
		  to: (self targetNamed: VGCairoPDFSurface fileExtension)
]

{ #category : 'private' }
VGCairoExportSurfaceTest >> rgbBytesOf: aSurface [
	"The three colour channels of every pixel, the top row first, with the stored premultiplication
	 divided back out, because a document of either format carries straight alpha."

	| bytes |
	bytes := ByteArray new: aSurface width * aSurface height * 3.
	0 to: aSurface height - 1 do: [ :y |
		0 to: aSurface width - 1 do: [ :x |
			| pixel at |
			pixel := aSurface straightAlphaPixelAtX: x y: y.
			at := (y * aSurface width + x) * 3.
			bytes at: at + 1 put: ((pixel bitShift: -16) bitAnd: 255).
			bytes at: at + 2 put: ((pixel bitShift: -8) bitAnd: 255).
			bytes at: at + 3 put: (pixel bitAnd: 255) ] ].
	^ bytes
]

{ #category : 'running' }
VGCairoExportSurfaceTest >> setUp [
	super setUp.
	fileSystem := FileSystem memory
]

{ #category : 'private' }
VGCairoExportSurfaceTest >> streamOfObjectCarrying: aKey in: aByteArray [
	"The stream bytes of the one indirect object whose dictionary carries the given key, read
	 through the /Length that dictionary declares, which is how a reader of the format finds them.
	 The search runs forward from the key because the writer states /Length last."

	| text at length streamStart |
	text := aByteArray asString.
	at := text indexOfSubCollection: aKey.
	self assert: at > 0 description: 'no object carries ' , aKey.
	length := (self numberAfter: '/Length ' in: text from: at) asInteger.
	streamStart := (text indexOfSubCollection: 'stream' startingAt: at) + 'stream' size + 1.
	^ aByteArray copyFrom: streamStart to: streamStart + length - 1
]

{ #category : 'private' }
VGCairoExportSurfaceTest >> svgPageOfExtent: aPointExtent [
	^ VGCairoSVGSurface
		  extent: aPointExtent
		  to: (self targetNamed: VGCairoSVGSurface fileExtension)
]

{ #category : 'private' }
VGCairoExportSurfaceTest >> targetNamed: anExtension [
	^ fileSystem root / ('page.' , anExtension)
]

{ #category : 'tests' }
VGCairoExportSurfaceTest >> testAFinishedPdfBeginsWithThePdfHeaderAndEndsWithTheEndOfFileMarker [
	| page text |
	page := self pdfPageOfExtent: 12 @ 8.
	self drawTwoPatchesOn: page.
	page finish.
	text := self textOf: page target.
	self assert: (text beginsWith: VGCairoPDFSurface documentPrefix).
	self assert: (text trimRight endsWith: '%%EOF')
]

{ #category : 'tests' }
VGCairoExportSurfaceTest >> testAPageKeepsItsExtentInPointsAndRastersOnePixelPerPoint [
	"The extent a surface answers is the pixels it holds, and the extent of a page is points, so
	 the two agree only because one point of a page gets one pixel. A fractional page rounds its
	 pixels up and keeps its points."

	| page |
	page := self pdfPageOfExtent: 10.5 @ 20.25.
	self assert: page pageExtent equals: 10.5 @ 20.25.
	self assert: page extent equals: 11 @ 21
]

{ #category : 'tests' }
VGCairoExportSurfaceTest >> testAPageOfZeroExtentStillWritesADocument [
	"A degenerate page carries no image at all, because neither format admits an image of no
	 width, and the document around it still has to be well formed. Both formats spell the word
	 image in the one construct that embeds pixels, so its absence says there is no image."

	VGCairoExportSurface allSubclasses do: [ :each |
		| page text |
		page := each extent: 0 @ 0 to: (self targetNamed: each fileExtension).
		page finish.
		text := self textOf: page target.
		self
			assert: (text beginsWith: each documentPrefix)
			description: each name , ' wrote no document for an empty page'.
		self
			deny: (text asLowercase includesSubstring: 'image')
			description: each name , ' embedded an image of no pixels' ]
]

{ #category : 'tests' }
VGCairoExportSurfaceTest >> testAPageRefusesDrawingOnceItIsFinished [
	| page |
	page := self pdfPageOfExtent: 9 @ 7.
	page finish.
	self
		should: [
			page newContext
				rectangleX: 0 y: 0 width: 2 height: 2;
				fill ]
		raise: Error
]

{ #category : 'tests' }
VGCairoExportSurfaceTest >> testAPdfIsNotWrittenUntilThePageIsFinished [
	| page |
	page := self pdfPageOfExtent: 12 @ 8.
	self drawTwoPatchesOn: page.
	page flush.
	self deny: page target exists.
	page finish.
	self assert: page target exists
]

{ #category : 'tests' }
VGCairoExportSurfaceTest >> testAnSvgEmbedsThePixelsAsAPortableNetworkGraphic [
	| page payload bytes form |
	page := self svgPageOfExtent: 12 @ 8.
	self drawTwoPatchesOn: page.
	page finish.
	payload := self dataUriPayloadIn: (self textOf: page target).
	bytes := (Base64MimeConverter mimeDecodeToChars: payload readStream) contents asByteArray.
	form := PNGReadWriter formFromStream: bytes readStream.
	self assert: form extent equals: page extent.
	self assert: form bits equals: page asForm bits
]

{ #category : 'tests' }
VGCairoExportSurfaceTest >> testAnSvgRootCarriesTheExtentInPoints [
	| page text |
	page := self svgPageOfExtent: 40 @ 30.
	page finish.
	text := self textOf: page target.
	self assert: (text includesSubstring: 'width="40pt"').
	self assert: (text includesSubstring: 'height="30pt"').
	self assert: (text includesSubstring: 'viewBox="0 0 40 30"')
]

{ #category : 'tests' }
VGCairoExportSurfaceTest >> testEveryExportSurfaceWritesADocumentThatBeginsWithThePrefixItDeclares [
	"Reflective over the family, so a third container format added later is held to the same two
	 facts without a test of its own."

	VGCairoExportSurface allSubclasses do: [ :each |
		| page text |
		page := each extent: 9 @ 7 to: (self targetNamed: each fileExtension).
		self drawTwoPatchesOn: page.
		page finish.
		text := self textOf: page target.
		self
			assert: (text beginsWith: each documentPrefix)
			description: each name , ' wrote a document of another kind'.
		self
			assert: text size > each documentPrefix size
			description: each name , ' wrote nothing but its prefix' ]
]

{ #category : 'tests' }
VGCairoExportSurfaceTest >> testFinishingThePageTwiceWritesTheDocumentOnce [
	"Bloc's exporters cascade flush and finish and a caller may finish again, and Cairo treats a
	 second finish as nothing to do, so the second one must not write the document over again."

	| page sentinel |
	page := self pdfPageOfExtent: 12 @ 8.
	self drawTwoPatchesOn: page.
	page finish.
	sentinel := 'overwritten by the test' asByteArray.
	page target delete.
	page target binaryWriteStreamDo: [ :out | out nextPutAll: sentinel ].
	page finish.
	self assert: (self bytesOf: page target) equals: sentinel
]

{ #category : 'tests' }
VGCairoExportSurfaceTest >> testThePdfCarriesEveryColourChannelThatWasDrawn [
	| page |
	page := self pdfPageOfExtent: 12 @ 8.
	self drawTwoPatchesOn: page.
	page finish.
	self
		assert: (self
				 streamOfObjectCarrying: '/ColorSpace /DeviceRGB'
				 in: (self bytesOf: page target))
		equals: (self rgbBytesOf: page)
]

{ #category : 'tests' }
VGCairoExportSurfaceTest >> testThePdfCarriesTheAlphaThatWasDrawnAsASoftMask [
	"The format keeps no alpha channel in an image, so the alpha of the page travels as a separate
	 greyscale image the page image names in its /SMask."

	| page |
	page := self pdfPageOfExtent: 12 @ 8.
	self drawTwoPatchesOn: page.
	page finish.
	self
		assert: (self
				 streamOfObjectCarrying: '/ColorSpace /DeviceGray'
				 in: (self bytesOf: page target))
		equals: (self alphaBytesOf: page)
]

{ #category : 'tests' }
VGCairoExportSurfaceTest >> testThePdfCrossReferenceTablePointsAtTheStartOfEveryObject [
	"A reader of the format reaches every object through the table rather than by scanning, so an
	 offset that is one byte out makes the document unreadable while it still looks well formed."

	| page text objectCount |
	page := self pdfPageOfExtent: 12 @ 8.
	self drawTwoPatchesOn: page.
	page finish.
	text := self textOf: page target.
	objectCount := (self
		                numberAfter: '/Size '
		                in: text
		                from: (text indexOfSubCollection: 'trailer')) asInteger - 1.
	self assert: objectCount >= 1.
	1 to: objectCount do: [ :number |
		| offset header |
		offset := self crossReferenceOffsetOf: number in: text.
		header := number printString , ' 0 obj'.
		self
			assert: ((text copyFrom: offset + 1 to: offset + header size) = header)
			description: 'object ' , number printString , ' is not where the table says' ]
]

{ #category : 'tests' }
VGCairoExportSurfaceTest >> testThePdfPageBoxIsTheExtentInPointsTheCallerAskedFor [
	| page |
	page := self pdfPageOfExtent: 40 @ 30.
	page finish.
	self assert: ((self textOf: page target) includesSubstring: '/MediaBox [ 0 0 40 30 ]')
]

{ #category : 'tests' }
VGCairoExportSurfaceTest >> testThePdfPageBoxOfAFractionalExtentKeepsTheFraction [
	"A point is one seventy second of an inch and an extent in points is not whole in general, so
	 the page box has to carry the fraction even though the pixels of the page cannot."

	| page |
	page := self pdfPageOfExtent: 10.5 @ 20.25.
	page finish.
	self assert: ((self textOf: page target) includesSubstring: '/MediaBox [ 0 0 10.5 20.25 ]')
]

{ #category : 'private' }
VGCairoExportSurfaceTest >> textOf: aFileReference [
	"A PDF mixes binary image bytes into an otherwise textual document, so it is read as bytes and
	 looked at one byte to one character, which is what the keywords of the format are written in."

	^ (self bytesOf: aFileReference) asString
]
