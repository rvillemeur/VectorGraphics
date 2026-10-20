"
I am a one page SVG document, the replacement for AeCairoSVGSurface.
The root element carries the page size in points and a view box in the same units, and the
pixels of the page travel inside it as one <image> element whose source is a Portable Network
Graphic in a base64 data URI.
The graphic carries its own alpha channel, so unlike the PDF page nothing has to be split out.
"
Class {
	#name : 'VGCairoSVGSurface',
	#superclass : 'VGCairoExportSurface',
	#category : 'VectorGraphics-Cairo-Export',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Export'
}

{ #category : 'constants' }
VGCairoSVGSurface class >> dataUriPrefix [
	^ 'data:image/png;base64,'
]

{ #category : 'constants' }
VGCairoSVGSurface class >> documentPrefix [
	^ '<?xml version="1.0" encoding="UTF-8"?>'
]

{ #category : 'constants' }
VGCairoSVGSurface class >> fileExtension [
	^ 'svg'
]

{ #category : 'constants' }
VGCairoSVGSurface class >> linkNamespace [
	"The pixels travel in an xlink:href, because a reader older than the second version of the
	 format reads the href of no other namespace."

	^ 'http://www.w3.org/1999/xlink'
]

{ #category : 'constants' }
VGCairoSVGSurface class >> namespace [
	^ 'http://www.w3.org/2000/svg'
]

{ #category : 'private' }
VGCairoSVGSurface >> base64PortableNetworkGraphic [
	"The pixels as a Portable Network Graphic, encoded on one line: a line end inside an attribute
	 value is legal but a reader is free to keep it, and nothing is gained by carrying it."

	| bytes |
	bytes := ByteArray new writeStream.
	PNGReadWriter putForm: self asForm onStream: bytes.
	^ (Base64MimeConverter mimeEncode: bytes contents readStream multiLine: false) contents
]

{ #category : 'writing' }
VGCairoSVGSurface >> documentString [
	"The whole document: the declaration, the root element that carries the page size, the one
	 graphic that carries the pixels, and the closing tag. A page with no pixels carries no
	 graphic, because the format admits no image of no width."

	^ String streamContents: [ :out |
		  out
			  nextPutAll: self class documentPrefix;
			  nextPutAll: self newLine;
			  nextPutAll: self rootElementStart;
			  nextPutAll: self newLine.
		  self hasPixels ifTrue: [
			  out
				  nextPutAll: self graphicElement;
				  nextPutAll: self newLine ].
		  out
			  nextPutAll: '</svg>';
			  nextPutAll: self newLine ]
]

{ #category : 'private' }
VGCairoSVGSurface >> graphicElement [
	"The whole page as one graphic over the view box. The aspect ratio is not preserved, because a
	 fractional page rounds its pixels up and is then a hair wider or taller than its box, and a
	 reader that preserved the ratio would letterbox the page over that hair."

	^ String streamContents: [ :out |
		  out
			  nextPutAll: '<image x="0" y="0" width="';
			  nextPutAll: (self numberString: pageExtent x);
			  nextPutAll: '" height="';
			  nextPutAll: (self numberString: pageExtent y);
			  nextPutAll: '" preserveAspectRatio="none" xlink:href="';
			  nextPutAll: self class dataUriPrefix;
			  nextPutAll: self base64PortableNetworkGraphic;
			  nextPutAll: '"/>' ]
]

{ #category : 'private' }
VGCairoSVGSurface >> rootElementStart [
	"The size is stated in points and the view box in the same units, so a reader that honours the
	 size and one that honours the view box lay the page out alike."

	^ String streamContents: [ :out |
		  out
			  nextPutAll: '<svg xmlns="';
			  nextPutAll: self class namespace;
			  nextPutAll: '" xmlns:xlink="';
			  nextPutAll: self class linkNamespace;
			  nextPutAll: '" width="';
			  nextPutAll: (self numberString: pageExtent x);
			  nextPutAll: 'pt" height="';
			  nextPutAll: (self numberString: pageExtent y);
			  nextPutAll: 'pt" viewBox="0 0 ';
			  nextPutAll: (self numberString: pageExtent x);
			  nextPutAll: ' ';
			  nextPutAll: (self numberString: pageExtent y);
			  nextPutAll: '">' ]
]

{ #category : 'writing' }
VGCairoSVGSurface >> writeDocumentOn: aBinaryStream [
	aBinaryStream nextPutAll: self documentString utf8Encoded
]
