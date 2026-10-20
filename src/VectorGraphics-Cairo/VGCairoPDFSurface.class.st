"
I am a one page PDF document, the replacement for AeCairoPDFSurface.
I write the pixels of the page as one image object in device RGB, the alpha of the page as a
second image object in device grey that the first one names in its /SMask, a content stream that
draws the image over the whole page box, and the cross reference table a reader of the format
needs to reach each object.
The format keeps no alpha channel inside an image, which is why the alpha travels as a soft mask
rather than as a fourth channel.
"
Class {
	#name : 'VGCairoPDFSurface',
	#superclass : 'VGCairoExportSurface',
	#category : 'VectorGraphics-Cairo-Export',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Export'
}

{ #category : 'constants' }
VGCairoPDFSurface class >> bitsPerComponent [
	^ 8
]

{ #category : 'constants' }
VGCairoPDFSurface class >> catalogueObjectNumber [
	"The document is six indirect objects in a fixed order - catalogue, pages, page, content
	 stream, colour image, soft mask - and an object refers to another by its number, so the
	 numbering is stated here once rather than written into the dictionaries."

	^ 1
]

{ #category : 'constants' }
VGCairoPDFSurface class >> colourImageObjectNumber [
	^ 5
]

{ #category : 'constants' }
VGCairoPDFSurface class >> contentObjectNumber [
	^ 4
]

{ #category : 'constants' }
VGCairoPDFSurface class >> documentPrefix [
	^ '%PDF-1.4'
]

{ #category : 'constants' }
VGCairoPDFSurface class >> fileExtension [
	^ 'pdf'
]

{ #category : 'constants' }
VGCairoPDFSurface class >> imageName [
	"The name the page resources give the image of the page, which the content stream draws."

	^ 'Im0'
]

{ #category : 'constants' }
VGCairoPDFSurface class >> pageObjectNumber [
	^ 3
]

{ #category : 'constants' }
VGCairoPDFSurface class >> pagesObjectNumber [
	^ 2
]

{ #category : 'constants' }
VGCairoPDFSurface class >> softMaskObjectNumber [
	^ 6
]

{ #category : 'private - dictionaries' }
VGCairoPDFSurface >> catalogueDictionary [
	^ '<< /Type /Catalog /Pages ' , (self referenceTo: self class pagesObjectNumber) , ' >>'
]

{ #category : 'private - dictionaries' }
VGCairoPDFSurface >> colourImageDictionaryOfLength: anInteger [
	^ self
		  imageDictionaryOfColourSpace: 'DeviceRGB'
		  softMask: (self referenceTo: self class softMaskObjectNumber)
		  length: anInteger
]

{ #category : 'private' }
VGCairoPDFSurface >> contentBytes [
	"The content stream of the page: the image of the page drawn over the whole page box. The
	 matrix scales the unit square an image occupies to the page in points, and the page box
	 starts at the origin, so nothing is translated."

	self hasPixels ifFalse: [ ^ #[  ] ].
	^ (String streamContents: [ :out |
		   out
			   nextPutAll: 'q ';
			   nextPutAll: (self numberString: pageExtent x);
			   nextPutAll: ' 0 0 ';
			   nextPutAll: (self numberString: pageExtent y);
			   nextPutAll: ' 0 0 cm /';
			   nextPutAll: self class imageName;
			   nextPutAll: ' Do Q' ]) utf8Encoded
]

{ #category : 'private - dictionaries' }
VGCairoPDFSurface >> contentDictionaryOfLength: anInteger [
	^ '<< /Length ' , anInteger printString , ' >>'
]

{ #category : 'private' }
VGCairoPDFSurface >> crossReferenceEntryForOffset: anInteger [
	"An entry is exactly the twenty bytes the format fixes - ten of offset, five of generation, one
	 of keyword and a two byte line end - because a reader seeks straight to the entry of an
	 object instead of scanning the table."

	^ (anInteger printPaddedWith: $0 to: 10) , ' 00000 n' , String cr , String lf
]

{ #category : 'private' }
VGCairoPDFSurface >> freeCrossReferenceEntry [
	"The entry of object zero, which no document uses and every table begins with."

	^ '0000000000 65535 f' , String cr , String lf
]

{ #category : 'private - dictionaries' }
VGCairoPDFSurface >> imageDictionaryOfColourSpace: aName softMask: aReferenceOrNil length: anInteger [
	"The /Length is stated last in every stream dictionary written here, so a reader searching
	 forward from any other key of the dictionary reaches it."

	^ String streamContents: [ :out |
		  out
			  nextPutAll: '<< /Type /XObject /Subtype /Image /Width ';
			  print: width;
			  nextPutAll: ' /Height ';
			  print: height;
			  nextPutAll: ' /ColorSpace /';
			  nextPutAll: aName;
			  nextPutAll: ' /BitsPerComponent ';
			  print: self class bitsPerComponent.
		  aReferenceOrNil ifNotNil: [ :reference |
			  out
				  nextPutAll: ' /SMask ';
				  nextPutAll: reference ].
		  out
			  nextPutAll: ' /Length ';
			  print: anInteger;
			  nextPutAll: ' >>' ]
]

{ #category : 'writing' }
VGCairoPDFSurface >> objects [
	"Each object as its dictionary and the stream bytes it carries, or nil for a dictionary alone.
	 The order is the numbering of VGCairoPDFSurface class, and a page with no pixels stops after
	 the content stream, which is then empty."

	| list content |
	list := OrderedCollection new.
	list add: self catalogueDictionary -> nil.
	list add: self pagesDictionary -> nil.
	list add: self pageDictionary -> nil.
	content := self contentBytes.
	list add: (self contentDictionaryOfLength: content size) -> content.
	self hasPixels ifTrue: [
		| colours alphas |
		colours := self rgbBytes.
		alphas := self alphaBytes.
		list add: (self colourImageDictionaryOfLength: colours size) -> colours.
		list add: (self softMaskDictionaryOfLength: alphas size) -> alphas ].
	^ list asArray
]

{ #category : 'private - dictionaries' }
VGCairoPDFSurface >> pageDictionary [
	^ String streamContents: [ :out |
		  out
			  nextPutAll: '<< /Type /Page /Parent ';
			  nextPutAll: (self referenceTo: self class pagesObjectNumber);
			  nextPutAll: ' /MediaBox [ 0 0 ';
			  nextPutAll: (self numberString: pageExtent x);
			  nextPutAll: ' ';
			  nextPutAll: (self numberString: pageExtent y);
			  nextPutAll: ' ] /Resources ';
			  nextPutAll: self resourcesDictionary;
			  nextPutAll: ' /Contents ';
			  nextPutAll: (self referenceTo: self class contentObjectNumber);
			  nextPutAll: ' >>' ]
]

{ #category : 'private - dictionaries' }
VGCairoPDFSurface >> pagesDictionary [
	^ '<< /Type /Pages /Kids [ ' , (self referenceTo: self class pageObjectNumber)
	  , ' ] /Count 1 >>'
]

{ #category : 'private' }
VGCairoPDFSurface >> referenceTo: anInteger [
	"How one object names another. Every object written here is of the first generation."

	^ anInteger printString , ' 0 R'
]

{ #category : 'private - dictionaries' }
VGCairoPDFSurface >> resourcesDictionary [
	^ self hasPixels
		  ifTrue: [
			  '<< /XObject << /' , self class imageName , ' '
			  , (self referenceTo: self class colourImageObjectNumber) , ' >> >>' ]
		  ifFalse: [ '<< >>' ]
]

{ #category : 'private - dictionaries' }
VGCairoPDFSurface >> softMaskDictionaryOfLength: anInteger [
	"The alpha of the page as a greyscale image, which the colour image names in its /SMask,
	 because the format keeps no alpha channel inside an image."

	^ self
		  imageDictionaryOfColourSpace: 'DeviceGray'
		  softMask: nil
		  length: anInteger
]

{ #category : 'writing' }
VGCairoPDFSurface >> writeCrossReferenceTableFor: aCollectionOfOffsets on: aBinaryStream [
	"The table a reader reaches every object through: the entry of the free object zero, one entry
	 for each object written in number order, the trailer that names the catalogue, and the offset
	 of the table itself."

	| tableStart size |
	tableStart := aBinaryStream position.
	size := aCollectionOfOffsets size + 1.
	self writeLine: 'xref' on: aBinaryStream.
	self writeLine: '0 ' , size printString on: aBinaryStream.
	aBinaryStream nextPutAll: self freeCrossReferenceEntry utf8Encoded.
	aCollectionOfOffsets do: [ :each |
		aBinaryStream nextPutAll: (self crossReferenceEntryForOffset: each) utf8Encoded ].
	self writeLine: 'trailer' on: aBinaryStream.
	self
		writeLine:
			'<< /Size ' , size printString , ' /Root '
			, (self referenceTo: self class catalogueObjectNumber) , ' >>'
		on: aBinaryStream.
	self writeLine: 'startxref' on: aBinaryStream.
	self writeLine: tableStart printString on: aBinaryStream.
	self writeLine: '%%EOF' on: aBinaryStream
]

{ #category : 'writing' }
VGCairoPDFSurface >> writeDocumentOn: aBinaryStream [
	"The header, then the objects in the order the numbering fixes, then the cross reference table
	 that says where each object starts and the trailer that names the catalogue."

	| offsets |
	offsets := OrderedCollection new.
	self writeLine: self class documentPrefix on: aBinaryStream.
	self objects doWithIndex: [ :object :number |
		offsets add: aBinaryStream position.
		self writeObject: object number: number on: aBinaryStream ].
	self writeCrossReferenceTableFor: offsets on: aBinaryStream
]

{ #category : 'writing' }
VGCairoPDFSurface >> writeObject: anAssociation number: anInteger on: aBinaryStream [
	"An object is its number, its dictionary, and - when it carries one - its bytes between the
	 stream and endstream keywords."

	self writeLine: anInteger printString , ' 0 obj' on: aBinaryStream.
	self writeLine: anAssociation key on: aBinaryStream.
	anAssociation value ifNotNil: [ :bytes |
		self writeLine: 'stream' on: aBinaryStream.
		aBinaryStream nextPutAll: bytes.
		self writeNewLineOn: aBinaryStream.
		self writeLine: 'endstream' on: aBinaryStream ].
	self writeLine: 'endobj' on: aBinaryStream
]
