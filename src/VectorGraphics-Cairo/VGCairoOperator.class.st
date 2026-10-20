"
One of Cairo's twenty-nine compositing operators, holding the code Cairo gives it and the name
Alexandrie calls it by, and able to composite a source over a destination pixel.

My instances are the constants: `VGCairoOperator over`, `VGCairoOperator saturate`, and the rest.
`named:`, `code:` and `normalise:` answer the one instance for a name, a code or whatever a
conformance script hands over, and `all` answers the twenty-nine in code order.

The compositing is split in two, because pixman is: twenty-one operators composite in eight-bit
integers through `compose:over:in:`, and the eight whose arithmetic divides composite in floating
point through `composeWideSource:mask:over:in:`, reading their source as four sixteen-bit shorts.
`composesInFloatingPoint` says which, and `sourceFromPaint:in:atX:y:` asks the paint for the
representation the operator wants, so a caller never has to know. `isUnbounded` and
`foldsAnAlphaIntoThePaint` answer the two questions the renderer asks before it draws: whether I
write where no source covers, and whether an alpha on a solid paint belongs in the paint's colour
or in a mask.
"
Class {
	#name : 'VGCairoOperator',
	#superclass : 'Object',
	#instVars : [
		'code',
		'operatorName'
	],
	#category : 'VectorGraphics-Cairo-Compositing',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Compositing'
}

{ #category : 'instance creation' }
VGCairoOperator class >> add [
	^ VGPorterDuffOperator code: 12 name: #add source: #one destination: #one
]

{ #category : 'instance creation' }
VGCairoOperator class >> all [
	"One operator an entry of #operatorNames, built by its own accessor, so the two cannot drift."
	^ self operatorNames collect: [ :each | self perform: each ]
]

{ #category : 'instance creation' }
VGCairoOperator class >> atop [
	^ VGPorterDuffOperator code: 5 name: #atop source: #destinationAlpha destination: #oneMinusSourceAlpha
]

{ #category : 'instance creation' }
VGCairoOperator class >> clear [
	^ VGClearOperator code: 0 name: #clear source: #zero destination: #zero
]

{ #category : 'instance creation' }
VGCairoOperator class >> code: anInteger [
	"The operator cairo_operator_t numbers that way."
	^ self all
		  detect: [ :each | each code = anInteger ]
		  ifNone: [ self error: anInteger printString , ' is no Cairo operator code' ]
]

{ #category : 'instance creation' }
VGCairoOperator class >> colorBurn [
	^ VGDividedBlendOperator code: 20 name: #colorBurn blend: #colorBurnOf:with:
]

{ #category : 'instance creation' }
VGCairoOperator class >> colorDodge [
	^ VGDividedBlendOperator code: 19 name: #colorDodge blend: #colorDodgeOf:with:
]

{ #category : 'instance creation' }
VGCairoOperator class >> darken [
	^ VGSeparableBlendOperator code: 17 name: #darken blend: #darkenTermForDestination:alpha:source:alpha:
]

{ #category : 'instance creation' }
VGCairoOperator class >> dest [
	^ VGPorterDuffOperator code: 6 name: #dest source: #zero destination: #one
]

{ #category : 'instance creation' }
VGCairoOperator class >> destAtop [
	^ VGPorterDuffOperator code: 10 name: #destAtop source: #oneMinusDestinationAlpha destination: #sourceAlpha
]

{ #category : 'instance creation' }
VGCairoOperator class >> destIn [
	^ VGPorterDuffOperator code: 8 name: #destIn source: #zero destination: #sourceAlpha
]

{ #category : 'instance creation' }
VGCairoOperator class >> destOut [
	^ VGPorterDuffOperator code: 9 name: #destOut source: #zero destination: #oneMinusSourceAlpha
]

{ #category : 'instance creation' }
VGCairoOperator class >> destOver [
	^ VGPorterDuffOperator code: 7 name: #destOver source: #oneMinusDestinationAlpha destination: #one
]

{ #category : 'instance creation' }
VGCairoOperator class >> difference [
	^ VGSeparableBlendOperator code: 23 name: #difference blend: #differenceTermForDestination:alpha:source:alpha:
]

{ #category : 'instance creation' }
VGCairoOperator class >> exclusion [
	^ VGSeparableBlendOperator code: 24 name: #exclusion blend: #exclusionTermForDestination:alpha:source:alpha:
]

{ #category : 'instance creation' }
VGCairoOperator class >> hardLight [
	^ VGSeparableBlendOperator code: 21 name: #hardLight blend: #hardLightTermForDestination:alpha:source:alpha:
]

{ #category : 'instance creation' }
VGCairoOperator class >> hslColor [
	^ VGNonSeparableBlendOperator code: 27 name: #hslColor blend: #colorOf:with:
]

{ #category : 'instance creation' }
VGCairoOperator class >> hslHue [
	^ VGNonSeparableBlendOperator code: 25 name: #hslHue blend: #hueOf:with:
]

{ #category : 'instance creation' }
VGCairoOperator class >> hslLuminosity [
	^ VGNonSeparableBlendOperator code: 28 name: #hslLuminosity blend: #luminosityOf:with:
]

{ #category : 'instance creation' }
VGCairoOperator class >> hslSaturation [
	^ VGNonSeparableBlendOperator code: 26 name: #hslSaturation blend: #saturationOf:with:
]

{ #category : 'instance creation' }
VGCairoOperator class >> in [
	^ VGPorterDuffOperator code: 3 name: #in source: #destinationAlpha destination: #zero
]

{ #category : 'inspecting' }
VGCairoOperator class >> inspectorCombiners: aBuilder [
	<inspectorPresentationOrder: 25 title: 'Combiners'>
	"The twenty-nine operators with the arithmetic each one composites through and the two
	 questions the renderer asks before it draws. Every column asks the operator itself, so the
	 tab cannot drift from the split: pixman kept an eight-bit combiner for twenty-one of them and
	 only a floating-point one for the eight whose arithmetic divides."
	^ aBuilder newTable
		  items: self all;
		  addColumn: (SpStringTableColumn
				   title: 'Operator'
				   evaluated: [ :each | each operatorName asString ]);
		  addColumn: (SpStringTableColumn title: 'Code' evaluated: [ :each | each code printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Arithmetic'
				   evaluated: [ :each | each arithmeticDescription ]);
		  addColumn: (SpStringTableColumn
				   title: 'A paint''s alpha'
				   evaluated: [ :each | each paintAlphaDescription ]);
		  addColumn: (SpStringTableColumn
				   title: 'Runs over'
				   evaluated: [ :each | each reachDescription ]);
		  yourself
]

{ #category : 'inspecting' }
VGCairoOperator class >> inspectorCombinersContext: aContext [
	"A rule the whole hierarchy answers belongs on the class that states it, so the tab shows on
	 the root of the hierarchy and not on each of its subclasses."
	aContext active: self superclass = Object
]

{ #category : 'instance creation' }
VGCairoOperator class >> lighten [
	^ VGSeparableBlendOperator code: 18 name: #lighten blend: #lightenTermForDestination:alpha:source:alpha:
]

{ #category : 'instance creation' }
VGCairoOperator class >> multiply [
	^ VGMultiplyBlendOperator
		  code: 14
		  name: #multiply
		  blend: #multiplyTermForDestination:alpha:source:alpha:
]

{ #category : 'instance creation' }
VGCairoOperator class >> named: aSymbol [
	"The operator Cairo calls that, or an error naming what is on offer."
	(self operatorNames includes: aSymbol) ifFalse: [
		^ self error: aSymbol printString , ' is no Cairo operator' ].
	^ self perform: aSymbol
]

{ #category : 'constants' }
VGCairoOperator class >> namesThatCarryAnAlphaAsAMask [
	"The operators under which Cairo refuses to fold a solid paint's alpha into the paint's colour
	 and carries it as a mask instead. Cairo decides this in _cairo_operator_bounded_by_source and
	 names these same six. Four of them write a different pixel through the two routes and match
	 the mask one; in and destIn write the same pixel either way, and are here because Cairo lists
	 them."
	^ #( clear source in out destIn destAtop )
]

{ #category : 'instance creation' }
VGCairoOperator class >> normalise: anObject [
	"One of mine, one of Alexandrie's enumeration values, a plain code or a name. A shared
	 conformance script may hand over any of them, the way unit 1.4 has to normalise a stroke
	 cap, and an unknown object is an error rather than a silent nothing."
	anObject isSymbol ifTrue: [ ^ self named: anObject ].
	anObject isInteger ifTrue: [ ^ self code: anObject ].
	(anObject isKindOf: VGCairoOperator) ifTrue: [ ^ anObject ].
	^ self code: anObject value
]

{ #category : 'constants' }
VGCairoOperator class >> operatorNames [
	"Cairo's whole operator set, in the order of cairo_operator_t: the twelve Porter and Duff
	 operators, add and saturate, the eleven separable blend modes of the PDF specification and
	 the four that work on the colour as a whole. A name missing from here is an operator the
	 inventory test reports, because this is the list #all is built from."
	^ #( #clear #source #over #in #out #atop #dest #destOver #destIn #destOut #destAtop #xor
	     #add #saturate #multiply #screen #overlay #darken #lighten #colorDodge #colorBurn
	     #hardLight #softLight #difference #exclusion #hslHue #hslSaturation #hslColor
	     #hslLuminosity )
]

{ #category : 'instance creation' }
VGCairoOperator class >> out [
	^ VGPorterDuffOperator code: 4 name: #out source: #oneMinusDestinationAlpha destination: #zero
]

{ #category : 'instance creation' }
VGCairoOperator class >> over [
	^ VGPorterDuffOperator code: 2 name: #over source: #one destination: #oneMinusSourceAlpha
]

{ #category : 'instance creation' }
VGCairoOperator class >> overlay [
	^ VGSeparableBlendOperator code: 16 name: #overlay blend: #overlayTermForDestination:alpha:source:alpha:
]

{ #category : 'constants' }
VGCairoOperator class >> probeDestinationPixel [
	"The destination the probe source is composited over: a grey at half alpha, premultiplied, so
	 that an operator which reads the destination's colour has one to read and an operator which
	 clears it leaves something visibly different behind."
	^ 16r80404040
]

{ #category : 'constants' }
VGCairoOperator class >> probeSourcePixel [
	"The source every operator is asked about when the question is what it does rather than what
	 it writes for a caller: a blue at half alpha, premultiplied."
	^ 16r80000080
]

{ #category : 'instance creation' }
VGCairoOperator class >> saturate [
	^ VGSaturateOperator code: 13 name: #saturate source: #saturating destination: #one
]

{ #category : 'instance creation' }
VGCairoOperator class >> screen [
	^ VGSeparableBlendOperator code: 15 name: #screen blend: #screenTermForDestination:alpha:source:alpha:
]

{ #category : 'instance creation' }
VGCairoOperator class >> softLight [
	^ VGDividedBlendOperator code: 22 name: #softLight blend: #softLightOf:with:
]

{ #category : 'instance creation' }
VGCairoOperator class >> source [
	^ VGSourceOperator code: 1 name: #source source: #one destination: #zero
]

{ #category : 'instance creation' }
VGCairoOperator class >> xor [
	^ VGPorterDuffOperator code: 11 name: #xor source: #oneMinusDestinationAlpha destination: #oneMinusSourceAlpha
]

{ #category : 'comparing' }
VGCairoOperator >> = anObject [
	^ self class == anObject class and: [ code = anObject code ]
]

{ #category : 'describing' }
VGCairoOperator >> arithmeticDescription [
	"Which of pixman's two combiners I composite through."
	^ self composesInFloatingPoint
		  ifTrue: [ 'floating point' ]
		  ifFalse: [ 'eight bit' ]
]

{ #category : 'accessing' }
VGCairoOperator >> code [
	"cairo_operator_t itself, so a phase two shader needs no translation table."

	^ code
]

{ #category : 'compositing' }
VGCairoOperator >> compose: aSourcePixel over: aDestinationPixel in: aFormat [
	^ self subclassResponsibility
]

{ #category : 'compositing' }
VGCairoOperator >> composeSource: aSource mask: aMaskByte over: aDestinationPixel in: aFormat [
	"The pixel to store where a source covers that much of a destination pixel. Measured on a
	 live Cairo context: a partial coverage scales the source, alpha and colours alike, and the
	 operator then runs on what is left of it. Clear and source are the two Cairo mixes with the
	 destination instead, and they say so themselves. The source is what sourceFromPaint:in:atX:y:
	 answered for me, so it is a wide pixel when I composite in floating point."
	self composesInFloatingPoint ifTrue: [
		^ self
			  composeWideSource: aSource
			  mask: aMaskByte
			  over: aDestinationPixel
			  in: aFormat ].
	^ self
		  compose: (aFormat pixel: aSource scaledBy: aMaskByte)
		  over: aDestinationPixel
		  in: aFormat
]

{ #category : 'compositing' }
VGCairoOperator >> composeWideSource: aWideSource mask: aMaskByte over: aDestinationPixel in: aFormat [
	"The pixel pixman's floating point combiner writes. Only an operator that answers true to
	 composesInFloatingPoint is composed this way, and the two that do, saturate and the dividing
	 blend modes, share the arithmetic here and differ in the two hooks it asks: what alpha comes
	 out, and what premultiplied channels. The mask scales the whole source, alpha and channels
	 alike, which is what pixman does to it; the store is pixman's own, a truncating multiply by
	 two hundred and fifty-six."
	| coverage sourceAlpha destinationAlpha source destination alpha |
	coverage := aMaskByte / 255.0.
	sourceAlpha := (aFormat alphaOfWidePixel: aWideSource) / 65535.0 * coverage.
	destinationAlpha := (aFormat alphaOfPixel: aDestinationPixel) / 255.0.
	alpha := self floatAlphaForSource: sourceAlpha over: destinationAlpha.
	aFormat isA8 ifTrue: [ ^ aFormat byteForFloat: alpha ].
	source := (aFormat premultipliedChannelsOfWidePixel: aWideSource) collect: [ :each |
		          each / 65535.0 * coverage ].
	destination := (aFormat premultipliedChannelsOfPixel: aDestinationPixel) collect: [ :each |
		               each / 255.0 ].
	^ aFormat
		  pixelForAlpha: (aFormat byteForFloat: alpha)
		  channels: ((self
				    floatChannelsForSource: source
				    alpha: sourceAlpha
				    over: destination
				    alpha: destinationAlpha) collect: [ :each | aFormat byteForFloat: each ])
]

{ #category : 'testing' }
VGCairoOperator >> composesInFloatingPoint [
	"Whether pixman runs me through its floating point combiner rather than its byte one, which
	 decides the precision I need the source at and the arithmetic I compose with. Eight of the
	 twenty-nine answer true, and which eight is measured: over nine colour pairs the byte
	 arithmetic is a step out of live Cairo on saturate and on the seven blend modes that divide,
	 and exact on the other twenty-one."
	^ false
]

{ #category : 'compositing' }
VGCairoOperator >> floatAlphaForSource: aSourceAlpha over: aDestinationAlpha [
	"The alpha, in zero to one, that composeWideSource:mask:over:in: stores. Asked of an operator
	 that composites in floating point and of no other."
	^ self subclassResponsibility
]

{ #category : 'compositing' }
VGCairoOperator >> floatChannelsForSource: aSource alpha: aSourceAlpha over: aDestination alpha: aDestinationAlpha [
	"The three premultiplied channels, in zero to one, that composeWideSource:mask:over:in:
	 stores. Both colours arrive premultiplied and scaled by the mask already. Asked of an
	 operator that composites in floating point and of no other."
	^ self subclassResponsibility
]

{ #category : 'testing' }
VGCairoOperator >> foldsAnAlphaIntoThePaint [
	"Whether an alpha on a solid paint belongs in the paint's colour, which is how Cairo carries
	 it under most operators. The six that answer false take it as a mask instead, and the two
	 routes quantise differently, so the choice is visible in the pixel."
	^ (self class namesThatCarryAnAlphaAsAMask includes: self operatorName) not
]

{ #category : 'comparing' }
VGCairoOperator >> hash [
	^ code hash
]

{ #category : 'inspecting' }
VGCairoOperator >> inspectorCompositing: aBuilder [
	<inspectorPresentationOrder: 20 title: 'Compositing'>
	"What I write over one destination as the coverage grows from nothing to all of it. The rows
	 are my own arithmetic rather than a description of it, and the source goes in through
	 sourceFromPixel:in:, so the eight operators that composite in floating point read it here as
	 four shorts just as they do when a paint feeds them."
	| format destination quarters |
	format := VGCairoSurfaceFormat argb32.
	destination := self class probeDestinationPixel.
	quarters := (0 to: 4) collect: [ :quarter |
		            format maskByteForCoverage: quarter / 4 ].
	^ aBuilder newTable
		  items: quarters;
		  addColumn: (SpStringTableColumn title: 'Mask' evaluated: [ :mask | mask printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Written'
				   evaluated: [ :mask |
					   (self
						    composeSource: (self sourceFromPixel: self class probeSourcePixel in: format)
						    mask: mask
						    over: destination
						    in: format)
						   printPaddedWith: $0
						   to: 8
						   base: 16 ]);
		  addColumn: (SpStringTableColumn
				   title: 'Leaves the destination'
				   evaluated: [ :mask |
					   ((self
						     composeSource: (self sourceFromPixel: self class probeSourcePixel in: format)
						     mask: mask
						     over: destination
						     in: format) = destination
						    ifTrue: [ 'yes' ]
						    ifFalse: [ 'no' ]) ]);
		  yourself
]

{ #category : 'inspecting' }
VGCairoOperator >> inspectorCompositingContext: aContext [
	"Gated on my having been set up, because an operator with no name and no code composites
	 nothing."
	aContext active: operatorName notNil
]

{ #category : 'testing' }
VGCairoOperator >> isBlendMode [
	"Whether I am one of the fifteen modes of the PDF blend set, which Cairo adds after the
	 Porter-Duff operators and the two arithmetic ones."

	^ false
]

{ #category : 'testing' }
VGCairoOperator >> isUnbounded [
	"Whether I write something at a pixel no source covers, which is what makes Cairo run me over
	 the whole clip and not only over the shape being drawn. I am asked rather than told: the
	 answer is my own arithmetic on a probe pixel at a coverage of nothing, so it cannot drift
	 from the compositing. The probe goes through sourceFromPixel:in: because eight of the
	 operators read their source as four shorts rather than as a packed pixel."
	| format probe |
	format := VGCairoSurfaceFormat argb32.
	probe := self class probeDestinationPixel.
	^ (self
		   composeSource: (self sourceFromPixel: self class probeSourcePixel in: format)
		   mask: 0
		   over: probe
		   in: format) ~= probe
]

{ #category : 'accessing' }
VGCairoOperator >> operatorName [
	"Cairo's own name for me, in the spelling Alexandrie's enumeration uses on its class side.
	 Not called name, because a class-side constant named after a reflection selector hides the
	 selector Pharo's own tools send."

	^ operatorName
]

{ #category : 'describing' }
VGCairoOperator >> paintAlphaDescription [
	"Where an alpha on a solid paint goes when I am the operator in force."
	^ self foldsAnAlphaIntoThePaint
		  ifTrue: [ 'in the colour' ]
		  ifFalse: [ 'as a mask' ]
]

{ #category : 'printing' }
VGCairoOperator >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPut: $(;
		nextPutAll: operatorName;
		nextPut: $)
]

{ #category : 'describing' }
VGCairoOperator >> reachDescription [
	"How much of the surface Cairo runs me over for one shape."
	^ self isUnbounded
		  ifTrue: [ 'the whole clip' ]
		  ifFalse: [ 'the shape' ]
]

{ #category : 'initialisation' }
VGCairoOperator >> setCode: anInteger name: aSymbol [
	code := anInteger.
	operatorName := aSymbol
]

{ #category : 'compositing' }
VGCairoOperator >> sourceFromPaint: aPaint in: aFormat atX: x y: y [
	"The source that paint gives me at that pixel, at the precision I compose at: a pixel word
	 for the twenty-one operators pixman composites on bytes, and a wide pixel of four sixteen-bit
	 shorts for the eight it composites in floating point. Nil where the paint lays nothing down,
	 as the paint itself answers."
	^ self composesInFloatingPoint
		  ifTrue: [ aPaint widePixelIn: aFormat atX: x y: y ]
		  ifFalse: [ aPaint pixelIn: aFormat atX: x y: y ]
]

{ #category : 'compositing' }
VGCairoOperator >> sourceFromPixel: aPixel in: aFormat [
	"The same source, when all there is of it is a pixel word: widening it loses nothing, and
	 only a solid colour ever carries more than a pixel word holds."
	^ self composesInFloatingPoint
		  ifTrue: [ aFormat widenPixel: aPixel ]
		  ifFalse: [ aPixel ]
]

{ #category : 'evaluating' }
VGCairoOperator >> value [
	"My code, under the selector Alexandrie's enumeration answers it with, so a script written
	 against that enumeration reads me the same way."

	^ code
]
