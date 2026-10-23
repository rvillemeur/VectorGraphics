"
I am a paint, the frozen hand-over between the drawing API and the backend, and I am the whole of rule 2 of the plan.

A paint is three things: a tag, a block of thirty-two-bit floats holding my coefficients, and, for a gradient, a list of stops. Nothing above the backend boundary knows whether I will be evaluated by a Pharo method or by a SPIR-V function, and nothing below it knows what a `VGCairoPattern` or a `BlPaint` is.

The block is the same size for every paint, and its first eight fields mean the same thing whatever the tag: fields 1 to 6 are the matrix that maps a device point into my own space, field 7 is the extend mode and field 8 is the sampling filter. The tag says how to read fields 9 onwards. `VGPaint class >> blockLayout` writes the whole table out, and `VGPaintTest` reads the block field by field so a change of layout fails in a test rather than in a picture.

My subclasses answer `colorAtX:y:` for the software backend, which evaluates me exactly, in floating point, because that is what live Cairo does: a quantised two-hundred-and-fifty-six-entry table is off by one at some points of a long ramp. `stopTable` builds that table all the same, because a shader wants it, and a test holds it to the exact evaluation at its own sample points.
"
Class {
	#name : 'VGPaint',
	#superclass : 'Object',
	#instVars : [
		'tag',
		'coefficients',
		'matrix'
	],
	#category : 'VectorGraphics-Cairo-Paint',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Paint'
}

{ #category : 'constants' }
VGPaint class >> blockLayout [
	"The frozen layout of the coefficient block, one entry per field, numbered from one. Fields 1
	 to 8 mean the same thing for every tag; the rest are read according to it. This method is the
	 ABI, and VGPaintTest holds every paint to it."
	^ { 1 -> #matrixSx. 2 -> #matrixShy. 3 -> #matrixShx. 4 -> #matrixSy. 5 -> #matrixX.
	    6 -> #matrixY. 7 -> #extendCode. 8 -> #filterCode.
	    9 -> #redOrLineX0OrInnerXOrPatchCount. 10 -> #greenOrLineY0OrInnerY.
	    11 -> #blueOrLineX1OrInnerRadius. 12 -> #alphaOrLineY1OrOuterX.
	    13 -> #outerY. 14 -> #outerRadius. 15 -> #surfaceWidth. 16 -> #surfaceHeight }
]

{ #category : 'constants' }
VGPaint class >> codeFor: aName in: aTable [
	^ (aTable detect: [ :each | each value = aName ]) key
]

{ #category : 'abi' }
VGPaint class >> coefficientCount [
	"The number of thirty-two-bit floats in every coefficient block, whatever the tag. One shape
	 for every paint is the point of the ABI: a reader takes the first eight fields without
	 asking what the paint is."

	^ 16
]

{ #category : 'constants' }
VGPaint class >> defaultExtend [
	"Pad for a gradient and none for a surface, which is what Cairo documents and what a live
	 pattern answers."

	^ #pad
]

{ #category : 'constants' }
VGPaint class >> defaultFilter [
	^ #good
]

{ #category : 'abi' }
VGPaint class >> extendFieldIndex [
	^ 7
]

{ #category : 'constants' }
VGPaint class >> extendFor: anObject [
	^ self nameIn: self extendNames for: anObject
]

{ #category : 'constants' }
VGPaint class >> extendNames [
	"Cairo's own extend modes, each at its own cairo_extend_t value, which is the code the block
	 carries. Read from the live enumeration: none is 0, repeat 1, reflect 2 and pad 3."

	^ { 0 -> #none. 1 -> #repeat. 2 -> #reflect. 3 -> #pad }
]

{ #category : 'abi' }
VGPaint class >> filterFieldIndex [
	^ 8
]

{ #category : 'constants' }
VGPaint class >> filterFor: anObject [
	^ self nameIn: self filterNames for: anObject
]

{ #category : 'constants' }
VGPaint class >> filterNames [
	"Cairo's own sampling filters at their own cairo_filter_t values, read from the live
	 enumeration. Only nearest and bilinear change how a surface is sampled; fast, good and best
	 are Cairo's three names for a quality it picks itself, and we read them as bilinear."

	^ { 0 -> #fast. 1 -> #good. 2 -> #best. 3 -> #nearest. 4 -> #bilinear. 5 -> #gaussian }
]

{ #category : 'instance creation' }
VGPaint class >> fromBlock: aFloat32Array [
	"A paint of mine carrying those coefficients, which is how a block that has travelled through
	 a buffer becomes a paint again. The block is the ABI of rule 2 and holds every field but the
	 stops, so a gradient rebuilt this way still needs its stops added."

	^ self new
		  setBlock: aFloat32Array;
		  yourself
]

{ #category : 'abi' }
VGPaint class >> matrixFieldIndices [
	^ 1 to: 6
]

{ #category : 'abi' }
VGPaint class >> matrixFieldOrder [
	"The order the six matrix fields are written in, which is Cairo's own field order and the
	 order VGCairoMatrix reads them back in."

	^ #( #sx #shy #shx #sy #x #y )
]

{ #category : 'constants' }
VGPaint class >> nameIn: aTable for: anObject [
	"The name anObject stands for in that code table, whether it is one of our symbols, a code of
	 Cairo's own, or an Alexandrie enumeration member that answers one. The same normalisation
	 VGCairoStrokeStyle does for caps and joins, and for the same reason: a caller may name either
	 vocabulary."

	| code |
	anObject isSymbol ifTrue: [
		^ (aTable anySatisfy: [ :each | each value = anObject ])
			  ifTrue: [ anObject ]
			  ifFalse: [ nil ] ].
	code := anObject isInteger
		        ifTrue: [ anObject ]
		        ifFalse: [ anObject asInteger ].
	^ (aTable detect: [ :each | each key = code ] ifNone: [ nil ]) ifNotNil: [ :each |
		  each value ]
]

{ #category : 'constants' }
VGPaint class >> paintTag [
	"The tag that says how to read the block past field eight. It is cairo_pattern_type_t itself,
	 so a paint and the pattern that built it carry the same number: solid 0, surface 1, linear 2
	 and radial 3."

	^ self subclassResponsibility
]

{ #category : 'converting' }
VGPaint class >> rgbaOf: aColor [
	"The four channels of a colour as floats in zero to one. A Pharo Color stores ten bits a
	 channel, so this is where the quantisation stops: every interpolation past this point is in
	 floating point, which is what live Cairo does. Alexandrie reads the same four accessors off
	 the same Color, so an input colour quantises identically on both sides."

	^ {
		  aColor red asFloat.
		  aColor green asFloat.
		  aColor blue asFloat.
		  aColor alpha asFloat }
]

{ #category : 'constants' }
VGPaint class >> typeNames [
	"The tag of a paint is cairo_pattern_type_t itself, so a paint and the pattern that built it
	 carry the same number, and this is the name each number goes by. Cairo has one more, raster
	 source, which this layer does not implement."
	^ {
		  (0 -> #solid).
		  (1 -> #surface).
		  (2 -> #linear).
		  (3 -> #radial).
		  (4 -> #mesh) }
]

{ #category : 'accessing' }
VGPaint >> coefficients [
	^ coefficients
]

{ #category : 'accessing' }
VGPaint >> extend [
	^ self class extendFor: (coefficients at: self class extendFieldIndex) truncated
]

{ #category : 'accessing' }
VGPaint >> extend: anObject [
	"One of my symbols, a cairo_extend_t code, or an Alexandrie enumeration member."

	| name |
	name := self class extendFor: anObject.
	name ifNil: [ ^ self ].
	coefficients
		at: self class extendFieldIndex
		put: (self class codeFor: name in: self class extendNames) asFloat
]

{ #category : 'accessing' }
VGPaint >> filter [
	^ self class filterFor: (coefficients at: self class filterFieldIndex) truncated
]

{ #category : 'accessing' }
VGPaint >> filter: anObject [
	"One of my symbols, a cairo_filter_t code, or an Alexandrie enumeration member."

	| name |
	name := self class filterFor: anObject.
	name ifNil: [ ^ self ].
	coefficients
		at: self class filterFieldIndex
		put: (self class codeFor: name in: self class filterNames) asFloat
]

{ #category : 'accessing' }
VGPaint >> hasStops [
	"Whether I carry a stop list beside my block. Only a gradient does, and a reader that writes
	 a paint out asks this rather than asking what class I am."

	^ false
]

{ #category : 'initialization' }
VGPaint >> initialize [
	super initialize.
	tag := self class paintTag.
	coefficients := Float32Array new: self class coefficientCount.
	self matrix: VGCairoMatrix newIdentity.
	self extend: self class defaultExtend.
	self filter: self class defaultFilter
]

{ #category : 'inspector' }
VGPaint >> inspectorBlock: aBuilder [

	<inspectorPresentationOrder: 20 title: 'Block'>
	^ aBuilder newTable
		  items: self class blockLayout;
		  addColumn:
			  (SpStringTableColumn title: 'Field' evaluated: [ :each | each key printString ]);
		  addColumn:
			  (SpStringTableColumn title: 'Name' evaluated: [ :each | each value asString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Value'
				   evaluated: [ :each | (coefficients at: each key) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Word'
				   evaluated: [ :each |
					   '16r'
					   ,
						   ((coefficients at: each key) asIEEE32BitWord
							    printPaddedWith: $0
							    to: 8
							    base: 16) ]);
		  yourself
]

{ #category : 'inspector' }
VGPaint >> inspectorBlockContext: aContext [

	aContext active: coefficients notNil
]

{ #category : 'testing' }
VGPaint >> isSolid [
	"Whether this paint is one colour everywhere. Cairo asks the same question before it folds a
	 constant alpha into the paint instead of carrying it as a mask."
	^ false
]

{ #category : 'accessing' }
VGPaint >> matrix [
	"The matrix that maps a device point into my own space, decoded from my block once and kept.
	 Every pixel of every fill asks for it, and building the decode afresh each time was the whole
	 cost of a frame. My block stays the truth: matrix: writes it and drops the decode, and no one
	 else writes the six fields. The matrix I answer is mine, so a caller that wants to change one
	 copies it first."

	^ matrix ifNil: [
		  | named |
		  named := Dictionary new.
		  self class matrixFieldIndices doWithIndex: [ :field :index |
			  named
				  at: (self class matrixFieldOrder at: index)
				  put: (coefficients at: field) ].
		  matrix := VGCairoMatrix
			            newX: (named at: #x)
			            y: (named at: #y)
			            sx: (named at: #sx)
			            sy: (named at: #sy)
			            shx: (named at: #shx)
			            shy: (named at: #shy) ]
]

{ #category : 'accessing' }
VGPaint >> matrix: aMatrix [
	"The matrix that maps a device point into my own space. It is the pattern's own matrix
	 composed with the inverse of the transformation in force when I was made the source, because
	 that is the moment Cairo captures: a later translateBy: does not move a source already set,
	 which is measured. The decoded matrix beside the block goes, so that the block is read again
	 and the argument is never aliased."

	matrix := nil.
	self class matrixFieldIndices doWithIndex: [ :field :index |
		coefficients
			at: field
			put: (aMatrix perform: (self class matrixFieldOrder at: index)) asFloat ]
]

{ #category : 'painting' }
VGPaint >> pixelIn: aFormat atX: x y: y [
	"The premultiplied pixel a surface of that format stores for me at that pixel, at full
	 coverage, or nil where I lay nothing down at all. I am evaluated at the centre of the pixel,
	 which is where live Cairo samples a gradient. The quantisation is mine to choose, because
	 Cairo keeps a solid colour in sixteen-bit shorts and a gradient in bytes."

	| channels |
	channels := self rgbaAtX: x + 0.5 y: y + 0.5.
	channels ifNil: [ ^ nil ].
	^ self quantise: channels in: aFormat
]

{ #category : 'painting' }
VGPaint >> pixelIn: aFormat atX: x y: y coverage: aNumber [
	"The source pixel source-over wants at that coverage: the pixel I store at full coverage,
	 with every channel scaled by the coverage as an eight-bit mask. Cairo quantises the paint
	 once and masks the result, so the coverage is not a factor of my alpha. A plain RGB target
	 cannot be served this way, because its pixel has no alpha byte to carry the mask; there the
	 format mixes source and destination by the mask itself."

	| pixel |
	pixel := self pixelIn: aFormat atX: x y: y.
	pixel ifNil: [ ^ nil ].
	^ aFormat pixel: pixel scaledBy: (aFormat maskByteForCoverage: aNumber)
]

{ #category : 'evaluating' }
VGPaint >> pointInPaintSpaceX: x y: y [
	^ self matrix value: x @ y
]

{ #category : 'copying' }
VGPaint >> postCopy [
	"The block is mutable and a pattern keeps its paint while a display list entry keeps a copy of
	 it, so the two must not share the one block. The decoded matrix goes with it, so that the copy
	 never answers a matrix another paint could be holding."

	super postCopy.
	coefficients := coefficients copy.
	matrix := nil
]

{ #category : 'evaluating' }
VGPaint >> quantise: anArray in: aFormat [
	"The pixel word those four unpremultiplied channels of mine become. Rounding the product of
	 the channel and two hundred and fifty-five is what Cairo does for everything it evaluates
	 pixel by pixel, which is every paint but a solid colour."

	^ aFormat pixelForRgba: anArray
]

{ #category : 'evaluating' }
VGPaint >> quantiseWide: anArray in: aFormat [
	"The wide pixel those four unpremultiplied channels of mine become. Cairo evaluates me pixel
	 by pixel and keeps bytes while it does, so widening the pixel word I quantise to is all the
	 precision there is of me: a solid colour, which Cairo converts once into shorts, is the one
	 paint that answers more."
	^ aFormat widenPixel: (self quantise: anArray in: aFormat)
]

{ #category : 'evaluating' }
VGPaint >> rgbaAtX: x y: y [
	"The four channels this paint lays down at that device point, as floats in zero to one and
	 unpremultiplied, or nil where the paint lays down nothing at all. Floats and not a Color:
	 a Pharo Color keeps ten bits a channel, and rounding an interpolation through ten bits
	 answers one less than live Cairo on a ramp of two hundred and fifty-five steps."

	^ self rgbaInPaintSpace: (self pointInPaintSpaceX: x y: y)
]

{ #category : 'evaluating' }
VGPaint >> rgbaInPaintSpace: aPoint [
	^ self subclassResponsibility
]

{ #category : 'private' }
VGPaint >> setBlock: aFloat32Array [
	"My coefficients, copied rather than held, so that a buffer written again does not move a
	 paint already built from it. The decoded matrix goes with them, because the block is the
	 truth and the decode is read from it afresh."

	coefficients := aFloat32Array copy.
	matrix := nil
]

{ #category : 'accessing' }
VGPaint >> tag [
	^ tag
]

{ #category : 'painting' }
VGPaint >> widePixelIn: aFormat atX: x y: y [
	"The same source pixelIn:atX:y: answers, at the precision an operator that composites in
	 floating point reads it at: four sixteen-bit shorts rather than four bytes. Nil where I lay
	 nothing down at all, as there too."
	| channels |
	channels := self rgbaAtX: x + 0.5 y: y + 0.5.
	channels ifNil: [ ^ nil ].
	^ self quantiseWide: channels in: aFormat
]
