"
I emit the SPIR-V that turns the coverage of one fill into the pixel written: the evaluation of its paint and the composition of that pixel into the destination under its own operator.

I am a vocabulary of the same module as the kernel that owns me, and I share its builder, its GLSL set and its value table, so an identifier I emit and an identifier it emits belong to one function. The kernel keeps the walk over the edges, the buffers and the declarations; it builds me while it emits one entry and sends me emitSource, emitMaskForCoverage: and emitCompositeWithMask:.

A paint reaches me as the coefficient block of rule 2 and a stop list, both read out of buffers the dispatch uploads, and I answer the premultiplied word VGCairoSurfaceFormat >> pixelForRgba: answers for the same channels. Both gradient geometries, all four extend modes and the arithmetic of all three operators of the subset are emitted every time, and a selection picks the one the header names, because a selection costs less than a branch and none of them writes anything.
"
Class {
	#name : 'VGTiledFillPixelEmitter',
	#superclass : 'VGSpirvVocabulary',
	#instVars : [
		'kernel'
	],
	#category : 'VectorGraphics-Vulkan-Tiles',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Tiles'
}

{ #category : 'constants' }
VGTiledFillPixelEmitter class >> compositionSelectorFor: anOperator [
	"Which arithmetic composites under that operator. An operator added to the rasteriser's
	 subset without arithmetic here is refused while the module is built, so no frame is drawn
	 by a branch that composites nothing."

	^ self compositionSelectors
		  at: anOperator operatorName
		  ifAbsent: [
		  self error: anOperator operatorName , ' has no arithmetic in this kernel' ]
]

{ #category : 'constants' }
VGTiledFillPixelEmitter class >> compositionSelectors [
	"The arithmetic of each operator of the subset, by the operator's own name. A reader of
	 VGTiledFillRasteriser class >> supportedOperators finds one entry here for each operator it
	 lists, and each answers the pair of weights the source and the destination are mixed by."

	^ Dictionary newFromPairs: {
			  #over.
			  #emitOverWeightsWithMask:.
			  #source.
			  #emitSourceWeightsWithMask:.
			  #clear.
			  #emitClearWeightsWithMask: }
]

{ #category : 'instance creation' }
VGTiledFillPixelEmitter class >> on: aKernel [
	"The emitter of one kernel, sharing the module it is building."
	^ self new setKernel: aKernel
]

{ #category : 'paint' }
VGTiledFillPixelEmitter >> coefficientOf: aField [
	"One field of the coefficient block of the entry standing, numbered as the paint ABI of
	 rule 2 numbers it."
	^ kernel
		  elementOf: #paints
		  atBase: (self valueNamed: #paintBase)
		  field: aField
]

{ #category : 'inspecting' }
VGTiledFillPixelEmitter >> compositionRows [
	"Each operator of the subset the rasteriser draws, beside the arithmetic I hold for it and
	 whether that arithmetic is a method of mine. The rows read the rasteriser and my own
	 selectors, so an operator added to the subset without arithmetic shows here as it fails
	 while a module is built."
	^ VGTiledFillRasteriser supportedOperators collect: [ :each |
		  | selector |
		  selector := self class compositionSelectors
			              at: each operatorName
			              ifAbsent: [ nil ].
		  {
			  each operatorName.
			  (VGTiledFillEncoding codeForOperator: each).
			  selector.
			  (selector notNil and: [ self class includesSelector: selector ]) } ]
]

{ #category : 'paint' }
VGTiledFillPixelEmitter >> emitAcceptanceOf: aRootId in: aDictionary [
	"Whether the circle that root names has a radius of its own, which is
	 VGRadialGradientPaint >> acceptableRootsAmong:. A circle of negative radius does not exist,
	 so the offset that names it paints nothing."

	^ self
		  float: (self
				   sumOfFloat: (aDictionary at: #innerRadius)
				   and: (self
						    productOfFloat: aRootId
						    and: (aDictionary at: #radiusDelta)))
		  atLeast: (self constantFloat: 0)
]

{ #category : 'composition' }
VGTiledFillPixelEmitter >> emitByteOf: aPixelId atShift: anInteger [
	"The channel of a pixel word that sits at that shift. The full byte doubles as the mask of
	 one channel, because a channel of this format is a byte wide."

	^ self
		  bitsOfWord: (self word: aPixelId shiftedRightBy: anInteger)
		  and: (self constantWord: VGTiledFillEncoding fullAlphaByte)
]

{ #category : 'paint' }
VGTiledFillPixelEmitter >> emitChannelsAt: anOffsetId [
	"The four unpremultiplied channels at that offset, interpolated between the two stops the
	 search found as VGGradientPaint >> interpolate:to:at: interpolates them: in floating point
	 and unpremultiplied, because a transparent blue stop ramping to an opaque red one reads a
	 blue of a hundred and twenty-six half way and a premultiplied interpolation cannot answer
	 that. A stop found on one side only stands for both sides, and two stops at one offset
	 answer the first of them, which is the stop the walk calls after."

	| before after keyBefore keyAfter spanning divisor fraction |
	before := self
		          select: (self
				           word: (kernel load: #beforeFound)
				           equals: (self constantWord: 1))
		          ifTrue: (kernel load: #beforeStop)
		          ifFalse: (kernel load: #afterStop)
		          type: self wordType.
	after := self
		         select: (self
				          word: (kernel load: #afterFound)
				          equals: (self constantWord: 1))
		         ifTrue: (kernel load: #afterStop)
		         ifFalse: (kernel load: #beforeStop)
		         type: self wordType.
	keyBefore := self
		             stopField: VGTiledFillLayout stopPositionField
		             at: before.
	keyAfter := self
		            stopField: VGTiledFillLayout stopPositionField
		            at: after.
	spanning := self float: keyAfter above: keyBefore.
	divisor := self
		           select: spanning
		           ifTrue: (self differenceOfFloat: keyAfter and: keyBefore)
		           ifFalse: (self constantFloat: 1)
		           type: self floatType.
	fraction := self
		            quotientOfFloat:
		            (self differenceOfFloat: anOffsetId and: keyBefore)
		            by: divisor.
	^ VGTiledFillLayout stopChannelFields collect: [ :field |
		  | from to |
		  from := self stopField: field at: before.
		  to := self stopField: field at: after.
		  self
			  select: spanning
			  ifTrue: (self
					   sumOfFloat: from
					   and: (self
							    productOfFloat: (self differenceOfFloat: to and: from)
							    and: fraction))
			  ifFalse: to
			  type: self floatType ]
]

{ #category : 'composition' }
VGTiledFillPixelEmitter >> emitClearWeightsWithMask: aMaskId [
	"Clear reads no source at all: the mask weighs the destination, and clearing a pixel the
	 shape covers by half leaves half of the destination standing, as VGClearOperator was
	 measured to do."

	^ {
		  (self constantWord: 0).
		  (self
			   differenceOfWord:
			   (self constantWord: VGTiledFillEncoding fullAlphaByte)
			   and: aMaskId) }
]

{ #category : 'composition' }
VGTiledFillPixelEmitter >> emitCompositeWithMask: aMaskId [
	"The destination pixel after this fill has been composited into it, which is the one place
	 a pixel of the target changes. The read and the write are of a function variable, because
	 this invocation owns the pixel for the whole of the frame."

	kernel
		store: (self
				 emitPixelOfSource: (kernel load: #source)
				 over: (kernel load: #dest)
				 weights: (self emitWeightsWithMask: aMaskId))
		into: #dest
]

{ #category : 'paint' }
VGTiledFillPixelEmitter >> emitDotOf: aPair and: anotherPair [
	"The dot product of two points, each a pair of floats as x then y."

	^ self
		  sumOfFloat:
		  (self productOfFloat: aPair first and: anotherPair first)
		  and: (self productOfFloat: aPair second and: anotherPair second)
]

{ #category : 'paint' }
VGTiledFillPixelEmitter >> emitExtendedOffset: anOffsetId [
	"The offset the extend mode of the block really reads, and whether it reads one at all,
	 which is VGGradientPaint >> extended: with >> reflected: under it. All four modes are
	 arithmetic, all four are emitted, and field seven of the block picks one; only none paints
	 nothing, and it paints nothing exactly where the offset falls outside its own ramp."

	| code isMode folded modes value |
	code := self wordOfFloat: (self coefficientOf: VGPaint extendFieldIndex).
	isMode := [ :name |
	          self
		          word: code
		          equals:
		          (self constantWord: (VGPaint codeFor: name in: VGPaint extendNames)) ].
	folded := self
		          differenceOfFloat: anOffsetId
		          and: (self
				           productOfFloat: (self constantFloat: 2)
				           and: (self floorOfFloat: (self
							             quotientOfFloat: anOffsetId
							             by: (self constantFloat: 2)))).
	modes := Dictionary newFromPairs: {
			         #none.
			         anOffsetId.
			         #repeat.
			         (self
				          differenceOfFloat: anOffsetId
				          and: (self floorOfFloat: anOffsetId)).
			         #reflect.
			         (self
				          select: (self float: folded notAbove: (self constantFloat: 1))
				          ifTrue: folded
				          ifFalse:
				          (self differenceOfFloat: (self constantFloat: 2) and: folded)
				          type: self floatType).
			         #pad.
			         (self
				          smallerFloatOf: (self
						           largerFloatOf: anOffsetId
						           and: (self constantFloat: 0))
				          and: (self constantFloat: 1)) }.
	value := modes at: #pad.
	#( #reflect #repeat #none ) do: [ :name |
		value := self
			         select: (isMode value: name)
			         ifTrue: (modes at: name)
			         ifFalse: value
			         type: self floatType ].
	^ value -> (self
		   either: (self negation: (isMode value: #none))
		   or: (self
				    both: (self float: anOffsetId atLeast: (self constantFloat: 0))
				    and: (self float: anOffsetId notAbove: (self constantFloat: 1))))
]

{ #category : 'paint' }
VGTiledFillPixelEmitter >> emitLinearOffset [
	"How far along its own line the point projects, which is VGLinearGradientPaint >>
	 offsetInPaintSpace:. A line of no length has no direction to project on and paints nothing
	 at all; the division is emitted all the same, with a divisor of one where the length
	 vanishes, because the value is selected away and a selection costs less than a branch."

	| startX startY deltaX deltaY square divisor |
	startX := self coefficientOf: VGLinearGradientPaint lineStartFields first.
	startY := self coefficientOf: VGLinearGradientPaint lineStartFields second.
	deltaX := self
		          differenceOfFloat:
		          (self coefficientOf: VGLinearGradientPaint lineEndFields first)
		          and: startX.
	deltaY := self
		          differenceOfFloat:
		          (self coefficientOf: VGLinearGradientPaint lineEndFields second)
		          and: startY.
	square := self
		          sumOfFloat: (self productOfFloat: deltaX and: deltaX)
		          and: (self productOfFloat: deltaY and: deltaY).
	divisor := self
		           select: (self float: square equals: (self constantFloat: 0))
		           ifTrue: (self constantFloat: 1)
		           ifFalse: square
		           type: self floatType.
	^ (self
		   quotientOfFloat: (self
				    sumOfFloat: (self
						     productOfFloat:
						     (self differenceOfFloat: (self valueNamed: #paintX) and: startX)
						     and: deltaX)
				    and: (self
						     productOfFloat:
						     (self differenceOfFloat: (self valueNamed: #paintY) and: startY)
						     and: deltaY))
		   by: divisor)
	  -> (self negation: (self float: square equals: (self constantFloat: 0)))
]

{ #category : 'paint' }
VGTiledFillPixelEmitter >> emitLinearRootOf: aDictionary [
	"The one root the quadratic leaves when its leading coefficient vanishes, and whether it is
	 a root at all: a vanishing b with it leaves none. The divisor is one where b vanishes, so
	 the division stands and its value is selected away."

	| vanishes divisor root |
	vanishes := self float: (aDictionary at: #b) equals: (self constantFloat: 0).
	divisor := self
		           select: vanishes
		           ifTrue: (self constantFloat: 1)
		           ifFalse: (self
				            differenceOfFloat: (self constantFloat: 0)
				            and: (aDictionary at: #b))
		           type: self floatType.
	root := self quotientOfFloat: (aDictionary at: #c) by: divisor.
	^ root -> (self
		   both: (self negation: vanishes)
		   and: (self emitAcceptanceOf: root in: aDictionary))
]

{ #category : 'composition' }
VGTiledFillPixelEmitter >> emitMaskForCoverage: aCoverageId [
	"The mask that coverage reaches the composition as: the eight-bit mask
	 VGCairoSurfaceFormat >> maskByteForCoverage: quantises it to, scaled by the alpha byte of
	 the fill. Pharo's rounded adds a half and takes the floor, and the conversion to a word
	 truncates, so the half is added here."

	^ self
		  emitScaleOfByte: (self
				   smallerWordOf: (self wordOfFloat: (self
							    sumOfFloat: (self
									     productOfFloat: aCoverageId
									     and: (self constantFloat: kernel class maskScale))
							    and: (self constantFloat: kernel class halfUnit)))
				   and: (self constantWord: VGTiledFillEncoding fullAlphaByte))
		  by: (self valueNamed: #alphaByte)
]

{ #category : 'composition' }
VGTiledFillPixelEmitter >> emitOverWeightsWithMask: aMaskId [
	"Source over destination: the whole of the source scaled by the mask, and what the alpha of
	 that scaled source leaves of the destination. VGPorterDuffOperator weighs the source by one
	 and the destination by one minus the source alpha, and a scaling by the full byte is the
	 identity, so the mask is the source''s own weight here."

	^ {
		  aMaskId.
		  (self
			   differenceOfWord:
			   (self constantWord: VGTiledFillEncoding fullAlphaByte)
			   and: (self
					    emitScaleOfByte: (self
							     emitByteOf: (kernel load: #source)
							     atShift: VGTiledFillEncoding targetFormat channelShifts last)
					    by: aMaskId)) }
]

{ #category : 'paint' }
VGTiledFillPixelEmitter >> emitPaintSpacePoint [
	"The centre of this pixel mapped into the paint''s own space by fields one to six of its
	 block, which is VGCairoMatrix >> valueX:y: on the matrix a paint decodes from those fields.
	 The centre and not the corner, because that is where live Cairo samples a gradient, and
	 VGPaint >> pixelIn:atX:y: adds the same half."

	| x y named |
	x := self
		     sumOfFloat: (self valueNamed: #pixelLeft)
		     and: (self constantFloat: kernel class halfUnit).
	y := self
		     sumOfFloat: (self valueNamed: #pixelRow)
		     and: (self constantFloat: kernel class halfUnit).
	named := Dictionary new.
	VGPaint matrixFieldIndices doWithIndex: [ :field :index |
		named
			at: (VGPaint matrixFieldOrder at: index)
			put: (self coefficientOf: field) ].
	self
		remember: (self
				 sumOfFloat: (self
						  sumOfFloat: (self productOfFloat: (named at: #sx) and: x)
						  and: (self productOfFloat: (named at: #shx) and: y))
				 and: (named at: #x))
		as: #paintX.
	self
		remember: (self
				 sumOfFloat: (self
						  sumOfFloat: (self productOfFloat: (named at: #shy) and: x)
						  and: (self productOfFloat: (named at: #sy) and: y))
				 and: (named at: #y))
		as: #paintY
]

{ #category : 'paint' }
VGTiledFillPixelEmitter >> emitPixelOfChannels: aCollection [
	"The premultiplied pixel word those four unpremultiplied channels become, which is
	 VGCairoSurfaceFormat >> pixelForRgba: on the one format a frame is encoded for: the alpha
	 is rounded to a byte of its own, and each colour is multiplied by the alpha as a float and
	 rounded after it, which is what live Cairo stores for a gradient."

	| alpha scale |
	scale := self constantFloat: VGTiledFillEncoding fullAlphaByte.
	alpha := aCollection last.
	^ (1 to: aCollection size) inject: (self constantWord: 0) into: [
		  :pixel
		  :index |
		  | channel |
		  channel := index = aCollection size
			             ifTrue: [ self productOfFloat: alpha and: scale ]
			             ifFalse: [
				             self
					             productOfFloat:
					             (self productOfFloat: (aCollection at: index) and: alpha)
					             and: scale ].
		  self
			  sumOfWord: pixel
			  and: (self
					   word: (self emitRoundedWordOf: channel)
					   shiftedLeftBy: (kernel class rgbaChannelShifts at: index)) ]
]

{ #category : 'composition' }
VGTiledFillPixelEmitter >> emitPixelOfSource: aSourceId over: aDestinationId weights: aPair [
	"Two premultiplied pixels, each scaled by a weight of its own and added channel by channel,
	 which is VGCairoSurfaceFormat >> mixPixel:weightedBy:withPixel:weightedBy: on the one
	 format a frame is encoded for. The sum is capped, because a pair of weights can overflow a
	 byte."

	^ VGTiledFillEncoding targetFormat channelShifts
		  inject: (self constantWord: 0)
		  into: [ :pixel :shift |
			  self
				  sumOfWord: pixel
				  and: (self
						   word: (self
								    smallerWordOf: (self
										     sumOfWord: (self
												      emitScaleOfByte: (self emitByteOf: aSourceId atShift: shift)
												      by: aPair first)
										     and: (self
												      emitScaleOfByte:
												      (self emitByteOf: aDestinationId atShift: shift)
												      by: aPair second))
								    and:
								    (self constantWord: VGTiledFillEncoding fullAlphaByte))
						   shiftedLeftBy: shift) ]
]

{ #category : 'paint' }
VGTiledFillPixelEmitter >> emitQuadraticRootsOf: aDictionary [
	"The largest acceptable of the two roots, and whether there is one. A negative discriminant
	 leaves none, and its square root is taken of the discriminant raised to zero so that no NaN
	 is computed at all; the leading coefficient cannot vanish here, because the linear root
	 stands for that, but its divisor is guarded all the same."

	| discriminant positive root divisor roots acceptable |
	discriminant := self
		                differenceOfFloat:
		                (self
			                 productOfFloat: (aDictionary at: #b)
			                 and: (aDictionary at: #b))
		                and: (self
				                 productOfFloat: (self constantFloat: 4)
				                 and: (self
						                  productOfFloat: (aDictionary at: #a)
						                  and: (aDictionary at: #c))).
	positive := self float: discriminant atLeast: (self constantFloat: 0).
	root := self squareRootOfFloat:
		        (self largerFloatOf: discriminant and: (self constantFloat: 0)).
	divisor := self
		           select:
		           (self float: (aDictionary at: #a) equals: (self constantFloat: 0))
		           ifTrue: (self constantFloat: 1)
		           ifFalse: (self
				            productOfFloat: (self constantFloat: 2)
				            and: (aDictionary at: #a))
		           type: self floatType.
	roots := {
		         (self
			          sumOfFloat:
			          (self differenceOfFloat: (self constantFloat: 0) and: (aDictionary at: #b))
			          and: root).
		         (self
			          differenceOfFloat:
			          (self differenceOfFloat: (self constantFloat: 0) and: (aDictionary at: #b))
			          and: root) } collect: [ :each |
		         self quotientOfFloat: each by: divisor ].
	acceptable := roots collect: [ :each |
		              self emitAcceptanceOf: each in: aDictionary ].
	^ (self
		   select: (self both: acceptable first and: acceptable second)
		   ifTrue: (self largerFloatOf: roots first and: roots second)
		   ifFalse: (self
				    select: acceptable first
				    ifTrue: roots first
				    ifFalse: roots second
				    type: self floatType)
		   type: self floatType)
	  -> (self
			   both: positive
			   and: (self either: acceptable first or: acceptable second))
]

{ #category : 'paint' }
VGTiledFillPixelEmitter >> emitRadialCoefficients [
	"The three coefficients of the quadratic VGRadialGradientPaint >> offsetInPaintSpace: writes,
	 in the order a, b, c, together with the inner radius and the difference of the radii, which
	 deciding whether a root is acceptable needs after it."

	| field innerCenter innerRadius centreDelta radiusDelta pointDelta |
	field := [ :name |
	          self coefficientOf: (VGRadialGradientPaint fieldNamed: name) ].
	innerCenter := {
			               (field value: #innerCenterX).
			               (field value: #innerCenterY) }.
	innerRadius := field value: #innerRadius.
	centreDelta := {
			               (self
				                differenceOfFloat: (field value: #outerCenterX)
				                and: innerCenter first).
			               (self
				                differenceOfFloat: (field value: #outerCenterY)
				                and: innerCenter second) }.
	radiusDelta := self
		               differenceOfFloat: (field value: #outerRadius)
		               and: innerRadius.
	pointDelta := {
			              (self
				               differenceOfFloat: (self valueNamed: #paintX)
				               and: innerCenter first).
			              (self
				               differenceOfFloat: (self valueNamed: #paintY)
				               and: innerCenter second) }.
	^ Dictionary newFromPairs: {
			  #a.
			  (self
				   differenceOfFloat: (self emitDotOf: centreDelta and: centreDelta)
				   and: (self productOfFloat: radiusDelta and: radiusDelta)).
			  #b.
			  (self
				   productOfFloat: (self constantFloat: -2)
				   and: (self
						    sumOfFloat: (self emitDotOf: pointDelta and: centreDelta)
						    and: (self productOfFloat: innerRadius and: radiusDelta))).
			  #c.
			  (self
				   differenceOfFloat: (self emitDotOf: pointDelta and: pointDelta)
				   and: (self productOfFloat: innerRadius and: innerRadius)).
			  #innerRadius.
			  innerRadius.
			  #radiusDelta.
			  radiusDelta }
]

{ #category : 'paint' }
VGTiledFillPixelEmitter >> emitRadialOffset [
	"The offset of the point on a radial gradient: the largest root of the quadratic whose
	 interpolated circle passes through it and has a radius of its own. A vanishing leading
	 coefficient leaves the linear root instead, and both are emitted, because a selection costs
	 less than a branch and neither writes anything."

	| terms vanishes linear quadratic |
	terms := self emitRadialCoefficients.
	vanishes := self float: (terms at: #a) equals: (self constantFloat: 0).
	linear := self emitLinearRootOf: terms.
	quadratic := self emitQuadraticRootsOf: terms.
	^ (self
		   select: vanishes
		   ifTrue: linear key
		   ifFalse: quadratic key
		   type: self floatType)
	  -> (self
			   either: (self both: vanishes and: linear value)
			   or: (self
					    both: (self negation: vanishes)
					    and: quadratic value))
]

{ #category : 'paint' }
VGTiledFillPixelEmitter >> emitRoundedWordOf: aFloatId [
	"A float of zero or more rounded to a word the way Pharo''s rounded rounds it: a half added
	 and the floor taken, and the conversion to a word takes the floor for us, because it
	 truncates and the value is never negative."

	^ self wordOfFloat:
		  (self
			   sumOfFloat: aFloatId
			   and: (self constantFloat: kernel class halfUnit))
]

{ #category : 'composition' }
VGTiledFillPixelEmitter >> emitScaleOfByte: aByteId by: aWeightId [
	"One byte scaled by another, divided by the full byte with rounding, which is
	 VGCairoSurfaceFormat >> scaleByte:by: and so Cairo's own integer blend."

	^ self
		  word: (self
				   sumOfWord: (self productOfWord: aByteId and: aWeightId)
				   and: (self constantWord: kernel class roundingAddend))
		  dividedBy: (self constantWord: VGTiledFillEncoding fullAlphaByte)
]

{ #category : 'paint' }
VGTiledFillPixelEmitter >> emitSource [
	"The pixel this fill lays down at this pixel of the target and whether it lays one down at
	 all. A solid paint is the one word the header carries, because a solid answers the same
	 pixel everywhere; a gradient is evaluated here out of its own block and its own stops, and
	 lays nothing down where its geometry gives no offset, where its extend mode paints outside
	 its ramp, or where it has no stop to read. Both geometries are emitted and the tag selects
	 one, which is what the weights of the operators do a few instructions later."

	| isLinear linear radial offset reaches extended isSolid channels found |
	self
		remember: (self
				 productOfWord: (self valueNamed: #paintBlockOffset)
				 and: (self constantWord: VGTiledFillLayout paintBlockFloats))
		as: #paintBase.
	self emitPaintSpacePoint.
	isLinear := self
		            word: (self valueNamed: #paintTag)
		            equals: (self constantWord: VGLinearGradientPaint paintTag).
	linear := self emitLinearOffset.
	radial := self emitRadialOffset.
	offset := self
		          select: isLinear
		          ifTrue: linear key
		          ifFalse: radial key
		          type: self floatType.
	reaches := self
		           either: (self both: isLinear and: linear value)
		           or: (self
				            both: (self negation: isLinear)
				            and: radial value).
	extended := self emitExtendedOffset: offset.
	self emitStopSearchAt: extended key.
	channels := self emitChannelsAt: extended key.
	isSolid := self
		           word: (self valueNamed: #paintTag)
		           equals: (self constantWord: VGPixelPaint paintTag).
	found := self
		         both: (self both: reaches and: extended value)
		         and: (self
				          either: (self
						           word: (kernel load: #beforeFound)
						           equals: (self constantWord: 1))
				          or: (self
						           word: (kernel load: #afterFound)
						           equals: (self constantWord: 1))).
	kernel
		store: (self
				 select: isSolid
				 ifTrue: (self valueNamed: #sourcePixel)
				 ifFalse: (self emitPixelOfChannels: channels)
				 type: self wordType)
		into: #source.
	kernel
		store: (self
				 select: (self either: isSolid or: found)
				 ifTrue: (self constantWord: 1)
				 ifFalse: (self constantWord: 0)
				 type: self wordType)
		into: #hasSource
]

{ #category : 'composition' }
VGTiledFillPixelEmitter >> emitSourceWeightsWithMask: aMaskId [
	"The source operator mixes the two pixels by the mask alone, which is what a live Cairo
	 context was measured to do: at half coverage it writes half of each pixel and not a source
	 scaled to half its alpha. VGSourceOperator says the same with a lerp."

	^ {
		  aMaskId.
		  (self
			   differenceOfWord:
			   (self constantWord: VGTiledFillEncoding fullAlphaByte)
			   and: aMaskId) }
]

{ #category : 'paint' }
VGTiledFillPixelEmitter >> emitStopSearchAt: anOffsetId [
	"The two stops the offset falls between, found by the walk VGGradientPaint >> rgbaAtOffset:
	 makes over the stop list in the order the stops were added: the one before is the last stop
	 at or below the offset and the one after is the first stop at or above it. A paint with no
	 stop leaves neither found, which is where it lays nothing down."
	#( #stop #beforeStop #afterStop #beforeFound #afterFound ) do: [ :each |
		kernel store: (self constantWord: 0) into: each ].
	builder
		emitWhile: [
		self word: (kernel load: #stop) below: (self valueNamed: #stopCount) ]
		do: [
			| key |
			key := self
				       stopField: VGTiledFillLayout stopPositionField
				       at: (kernel load: #stop).
			builder emitIf: (self float: key notAbove: anOffsetId) then: [
				kernel store: (kernel load: #stop) into: #beforeStop.
				kernel store: (self constantWord: 1) into: #beforeFound ].
			builder
				emitIf: (self
						 both: (self
								  word: (kernel load: #afterFound)
								  equals: (self constantWord: 0))
						 and: (self float: key atLeast: anOffsetId))
				then: [
					kernel store: (kernel load: #stop) into: #afterStop.
					kernel store: (self constantWord: 1) into: #afterFound ].
			kernel
				store: (self sumOfWord: (kernel load: #stop) and: (self constantWord: 1))
				into: #stop ]
]

{ #category : 'composition' }
VGTiledFillPixelEmitter >> emitWeightsWithMask: aMaskId [
	"The weights the source and the destination are mixed by under the entry's own operator.
	 The arithmetic of all three operators of the subset is emitted and a chain of selections
	 picks the one the header names: each is a handful of instructions and none of them writes
	 anything, so a selection costs less than a branch and keeps the walk straight."

	| weights chosen |
	weights := VGTiledFillRasteriser supportedOperators collect: [ :each |
		           {
			           (VGTiledFillEncoding codeForOperator: each).
			           (self
				            perform: (self class compositionSelectorFor: each)
				            with: aMaskId) } ].
	chosen := weights first second.
	weights allButFirst do: [ :each |
		| isThisOne |
		isThisOne := self
			             word: (self valueNamed: #operator)
			             equals: (self constantWord: each first).
		chosen := chosen with: each second collect: [ :standing :mine |
			          self
				          select: isThisOne
				          ifTrue: mine
				          ifFalse: standing
				          type: self wordType ] ].
	^ chosen
]

{ #category : 'inspecting' }
VGTiledFillPixelEmitter >> inspectorComposition: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Composition'>
	"The operators I composite under: the name each one answers, the code the header carries for
	 it, the arithmetic I hold and whether I really implement it."
	^ aBuilder newTable
		  addColumn: (SpStringTableColumn
				   title: 'Operator'
				   evaluated: [ :each | (each at: 1) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Code'
				   evaluated: [ :each | (each at: 2) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Arithmetic'
				   evaluated: [ :each | (each at: 3) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Implemented'
				   evaluated: [ :each | (each at: 4) printString ]);
		  items: self compositionRows;
		  yourself
]

{ #category : 'inspecting' }
VGTiledFillPixelEmitter >> inspectorCompositionContext: aContext [
	aContext active: kernel isNotNil
]

{ #category : 'accessing' }
VGTiledFillPixelEmitter >> kernel [
	"The kernel whose module I emit into. I read its buffers and its function variables through
	 it, because the declarations are its own."
	^ kernel
]

{ #category : 'printing' }
VGTiledFillPixelEmitter >> printOn: aStream [
	super printOn: aStream.
	aStream nextPutAll: ' of '.
	kernel printOn: aStream
]

{ #category : 'initialization' }
VGTiledFillPixelEmitter >> setKernel: aKernel [
	kernel := aKernel.
	self shareStateWith: aKernel
]

{ #category : 'paint' }
VGTiledFillPixelEmitter >> stopField: aField at: aStopId [
	"One field of one stop of the entry standing, the stop counted from the first stop of this
	 entry and the field numbered as VGTiledFillEncoding writes it."
	^ kernel
		  elementOf: #stops
		  atBase: (self
				   productOfWord:
				   (self sumOfWord: (self valueNamed: #stopOffset) and: aStopId)
				   and: (self constantWord: VGTiledFillLayout stopFloats))
		  field: aField
]
