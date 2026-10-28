"
I am one pass of a box blur over an eight-bit alpha field, emitted as a SPIR-V compute kernel.

I reproduce VGA8GaussianBlurFilter's box pass exactly, and that is the whole of my contract. The host pass carries a running sum along the axis it walks; I sum the window of every output byte on its own, which is the same integer and lets every byte be computed at once. I write a whole thirty-two bit word a time, the four adjacent bytes of one row, so no two invocations write the same word and no read-modify-write can race: the stride of an alpha surface is always a whole number of words, so every row starts on a word.

One module serves both axes. The params buffer names the step between two taps, the limit the axis clamps against and which of the column and the row is the axis, so a pass along the rows and a pass down the columns differ in the words uploaded and in which buffer is bound as the source, never in the bytes of the module. The walk is over the stride of the surface and not over its width, as the host filter walks, so the padding bytes of a row blur and a row bleeds into the next exactly as Cairo lets it.

The arithmetic of the average is not a division. VGA8GaussianBlurFilter multiplies by a Float64 reciprocal and floors, which loses one at some exact multiples of some diameters, so VGBlurRounding hands me a bit per quotient that needs the correction and I subtract it. See VGBlurBoxKernel class >> bindingNames for the buffers and VGBlurDispatch for the two passes.
"
Class {
	#name : 'VGBlurBoxKernel',
	#superclass : 'VGSpirvKernel',
	#classInstVars : [
		'cachedSpirv'
	],
	#category : 'VectorGraphics-Vulkan-Blur',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Blur'
}

{ #category : 'constants' }
VGBlurBoxKernel class >> bindingNames [
	"The four buffers I read, in the order they are bound: the field this pass reads, the field it
	 writes, the words that describe the pass and the rounding table. A binding number is the
	 position of the name here, counted from zero, so this one list states the whole contract."

	^ #( #source #target #params #corrections )
]

{ #category : 'constants' }
VGBlurBoxKernel class >> bitsPerByte [
	^ 8
]

{ #category : 'constants' }
VGBlurBoxKernel class >> builtInNumbers [
	"The one built-in I read: an invocation finds its word and its row in the whole grid, there
	 being no tile here to find them inside."

	^ { SpvBuiltIn globalInvocationId }
]

{ #category : 'constants' }
VGBlurBoxKernel class >> byteMask [
	"The low byte of a word, which is what an alpha sample is."

	^ 255
]

{ #category : 'constants' }
VGBlurBoxKernel class >> bytesPerWord [
	"A word of this module is thirty-two bits, so it holds four alpha bytes."

	^ 4
]

{ #category : 'module cache' }
VGBlurBoxKernel class >> clearSpirvCache [
	"Forget the module built so far. The cache is a saving and never a decision, so what is built
	 next is byte for byte what was forgotten."

	cachedSpirv := nil
]

{ #category : 'inspector' }
VGBlurBoxKernel class >> inspectorSampleField [
	"The field the Params tab describes a pass of: a box radius, a stride in bytes and a count of
	 rows. Any field would do; this one is narrow enough to read and several workgroups wide."

	^ Dictionary new
		  at: #radius put: 2;
		  at: #columnCount put: 64;
		  at: #rowCount put: 32;
		  yourself
]

{ #category : 'constants' }
VGBlurBoxKernel class >> paramNames [
	"The words of the params buffer, in the order the buffer holds them: the diameter and the radius
	 of the box, the stride and the height of the field, then the three words that name the axis of
	 this pass — the step between two taps, the limit the axis clamps against, and the weight of the
	 column and of the row in the axis coordinate, which is one and nought along the rows and nought
	 and one down the columns."

	^ #( #diameter #radius #columnCount #rowCount #step #axisLimit #columnWeight
	     #rowWeight )
]

{ #category : 'constants' }
VGBlurBoxKernel class >> paramWords [
	^ self paramNames size
]

{ #category : 'module cache' }
VGBlurBoxKernel class >> spirv [
	"The bytes of the kernel, built once a session. The module depends on nothing a pass carries —
	 the diameter, the axis and the size of the field all ride in the params buffer — so a blur that
	 built one would pay the build for every pass of every blur."

	^ cachedSpirv ifNil: [ cachedSpirv := self new spirv ]
]

{ #category : 'constants' }
VGBlurBoxKernel class >> wordBitCount [
	"The bits of a word of the rounding table, asked of the class that builds the table so that the
	 two cannot disagree about where a quotient is found in it."

	^ VGBlurRounding wordBitCount
]

{ #category : 'constants' }
VGBlurBoxKernel class >> wordVariableNames [
	"The function variables: the tap the window loop stands on, the sum of the window so far, and
	 the word the four bytes are packed into before it is written."

	^ #( #tap #sum #packed )
]

{ #category : 'constants' }
VGBlurBoxKernel class >> workgroupHeight [
	"Rows to a workgroup."

	^ 16
]

{ #category : 'constants' }
VGBlurBoxKernel class >> workgroupWidth [
	"Words of a row to a workgroup."

	^ 16
]

{ #category : 'emitting' }
VGBlurBoxKernel >> emitAverageAtColumnOffset: anInteger [
	"The byte the pass writes at the column that many bytes into this invocation's word: the window
	 of that output byte summed tap by tap, then averaged. The axis of the pass is named by the two
	 weights, so a pass along the rows and a pass down the columns are the same instructions; the
	 base is the index of the output byte with its own axis coordinate taken out of it, which is
	 what the clamped tap is added back onto."

	| column byteIndex axisCoord base |
	column := self
		          sumOfWord: (self
				           productOfWord: (self valueNamed: #wordColumn)
				           and: (self constantWord: self class bytesPerWord))
		          and: (self constantWord: anInteger).
	byteIndex := self
		             sumOfWord: (self
				              productOfWord: (self valueNamed: #row)
				              and: (self valueNamed: #columnCount))
		             and: column.
	axisCoord := self
		             sumOfWord: (self
				              productOfWord: column
				              and: (self valueNamed: #columnWeight))
		             and: (self
				              productOfWord: (self valueNamed: #row)
				              and: (self valueNamed: #rowWeight)).
	base := self
		        differenceOfWord: byteIndex
		        and: (self productOfWord: axisCoord and: (self valueNamed: #step)).
	self store: (self constantWord: 0) into: #sum.
	self store: (self constantWord: 0) into: #tap.
	builder
		emitWhile: [
		self word: (self load: #tap) below: (self valueNamed: #diameter) ]
		do: [
			self
				store: (self
						 sumOfWord: (self load: #sum)
						 and: (self emitByteAtBase: base axisCoord: axisCoord))
				into: #sum.
			self
				store: (self sumOfWord: (self load: #tap) and: (self constantWord: 1))
				into: #tap ].
	^ self emitAverageOfSum: (self load: #sum)
]

{ #category : 'emitting' }
VGBlurBoxKernel >> emitAverageOfSum: aSumId [
	"VGA8GaussianBlurFilter class >> averageOfSum:overDiameter: on the device. It is the quotient of
	 the sum by the diameter, less one where the host's Float64 reciprocal falls just under the
	 integer: that happens at an exact multiple of the diameter and nowhere else, and VGBlurRounding
	 carries a bit for every quotient it happens at. A sample is a byte and a window holds one
	 sample a tap, so the quotient cannot reach past the last bit of that table."

	| quotient remainder flagged isMultiple |
	quotient := self word: aSumId dividedBy: (self valueNamed: #diameter).
	remainder := self
		             differenceOfWord: aSumId
		             and: (self
				              productOfWord: quotient
				              and: (self valueNamed: #diameter)).
	flagged := self emitCorrectionBitOfQuotient: quotient.
	isMultiple := self
		              select: (self word: remainder equals: (self constantWord: 0))
		              ifTrue: (self constantWord: 1)
		              ifFalse: (self constantWord: 0)
		              type: self wordType.
	^ self
		  differenceOfWord: quotient
		  and: (self productOfWord: flagged and: isMultiple)
]

{ #category : 'emitting' }
VGBlurBoxKernel >> emitBody [
	"The word of four bytes this invocation owns, and whether it owns one at all: the dispatch is
	 rounded up to whole workgroups, so the invocations past the last word of the last row have
	 nothing to write."

	| inside |
	self rememberParams.
	self
		remember: (self
				 componentOfBuiltIn: SpvBuiltIn globalInvocationId
				 at: self class columnComponent)
		as: #wordColumn.
	self
		remember: (self
				 componentOfBuiltIn: SpvBuiltIn globalInvocationId
				 at: self class rowComponent)
		as: #row.
	inside := self
		          both: (self
				           word: (self valueNamed: #wordColumn)
				           below: (self valueNamed: #wordColumnCount))
		          and: (self
				           word: (self valueNamed: #row)
				           below: (self valueNamed: #rowCount)).
	builder emitIf: inside then: [ self emitWord ]
]

{ #category : 'emitting' }
VGBlurBoxKernel >> emitByteAtBase: aBaseId axisCoord: anAxisCoordId [
	"The source byte of the tap the loop stands on, clamped to the ends of the axis as the host
	 filter clamps it: a tap before the first byte of the axis repeats that byte, and a tap past the
	 last repeats the last. The radius is taken off by a select and not by a subtraction, because an
	 index is unsigned here, so a tap left of the field would wrap round instead of going negative."

	| wanted lowered clamped index word shift |
	wanted := self sumOfWord: anAxisCoordId and: (self load: #tap).
	lowered := self
		           select: (self word: wanted below: (self valueNamed: #radius))
		           ifTrue: (self constantWord: 0)
		           ifFalse:
		           (self differenceOfWord: wanted and: (self valueNamed: #radius))
		           type: self wordType.
	clamped := self
		           smallerWordOf: lowered
		           and: (self
				            differenceOfWord: (self valueNamed: #axisLimit)
				            and: (self constantWord: 1)).
	index := self
		         sumOfWord: aBaseId
		         and: (self productOfWord: clamped and: (self valueNamed: #step)).
	word := self word: index dividedBy: (self constantWord: self class bytesPerWord).
	shift := self
		         productOfWord: (self
				          differenceOfWord: index
				          and: (self
						           productOfWord: word
						           and: (self constantWord: self class bytesPerWord)))
		         and: (self constantWord: self class bitsPerByte).
	^ self
		  bitsOfWord:
		  (self word: (self elementOf: #source at: word) shiftedRightByWord: shift)
		  and: (self constantWord: self class byteMask)
]

{ #category : 'emitting' }
VGBlurBoxKernel >> emitCorrectionBitOfQuotient: aQuotientId [
	"One where that quotient is one the host's arithmetic writes one less than, nought otherwise.
	 The table holds a bit a quotient, thirty-two bits to a word, in the order VGBlurRounding writes
	 them."

	| word shift |
	word := self
		        word: aQuotientId
		        dividedBy: (self constantWord: self class wordBitCount).
	shift := self
		         differenceOfWord: aQuotientId
		         and: (self
				          productOfWord: word
				          and: (self constantWord: self class wordBitCount)).
	^ self
		  bitsOfWord:
		  (self
			   word: (self elementOf: #corrections at: word)
			   shiftedRightByWord: shift)
		  and: (self constantWord: 1)
]

{ #category : 'emitting' }
VGBlurBoxKernel >> emitWord [
	"The four bytes of this invocation's word, each averaged over its own window, packed into one
	 word and written once. The shift of a byte inside the word is a literal, which is why the four
	 bytes are unrolled here while the taps of a window are a loop on the device: a word holds four
	 bytes whatever the blur is, and a window holds as many taps as the diameter says."

	| index |
	self store: (self constantWord: 0) into: #packed.
	0 to: self class bytesPerWord - 1 do: [ :offset |
		self
			store: (self
					 sumOfWord: (self load: #packed)
					 and: (self
							  word: (self emitAverageAtColumnOffset: offset)
							  shiftedLeftBy: offset * self class bitsPerByte))
			into: #packed ].
	index := self
		         sumOfWord: (self
				          productOfWord: (self valueNamed: #row)
				          and: (self valueNamed: #wordColumnCount))
		         and: (self valueNamed: #wordColumn).
	self storeWord: (self load: #packed) into: #target at: index
]

{ #category : 'building' }
VGBlurBoxKernel >> freshKernel [
	^ self class new
]

{ #category : 'inspector' }
VGBlurBoxKernel >> inspectorParams: aBuilder [
	<inspectorPresentationOrder: 12 title: 'Params'>
	"The words a pass describes itself by, each at the position the kernel reads it from, with what
	 a pass along the rows and a pass down the columns put there for one sample field. The two
	 columns are asked of VGBlurDispatch itself, so the tab shows what a device is really told: the
	 step of one byte against a whole row, the limit of the stride against the rows, and the
	 weights that pick which invocation coordinate runs along the axis."

	| field rows columns |
	field := self class inspectorSampleField.
	rows := VGBlurDispatch new
		        wordsAlongRowsOfRadius: (field at: #radius)
		        columns: (field at: #columnCount)
		        rows: (field at: #rowCount).
	columns := VGBlurDispatch new
		           wordsDownColumnsOfRadius: (field at: #radius)
		           columns: (field at: #columnCount)
		           rows: (field at: #rowCount).
	^ aBuilder newTable
		  addColumn: (SpStringTableColumn
				   title: 'Word'
				   evaluated: [ :each | each value printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Name'
				   evaluated: [ :each | each key ]);
		  addColumn: (SpStringTableColumn
				   title: 'Along rows'
				   evaluated: [ :each | (rows at: each key) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Down columns'
				   evaluated: [ :each | (columns at: each key) printString ]);
		  items: (self class paramNames withIndexCollect: [ :each :index |
					   each -> (index - 1) ]);
		  yourself
]

{ #category : 'inspector' }
VGBlurBoxKernel >> inspectorParamsContext: aContext [
	aContext active: true
]

{ #category : 'accessing' }
VGBlurBoxKernel >> localSize [
	"A workgroup of words and of rows. An invocation owns one word of one row and reads nothing
	 another invocation writes, so the shape of the workgroup is a dispatch size and carries no
	 meaning of its own."

	^ {
		  self class workgroupWidth.
		  self class workgroupHeight.
		  self class layerCount }
]

{ #category : 'emitting' }
VGBlurBoxKernel >> rememberParams [
	"Every word of the params buffer under its own name, and the one word computed from them. The
	 position of a name in the list is the field, counted from one, exactly as the position of a
	 binding name is its binding number, so the kernel and the dispatch that fills the buffer read
	 one list and cannot disagree about the order."

	self class paramNames withIndexDo: [ :each :index |
		self
			remember: (self
					 elementOf: #params
					 atBase: (self constantWord: 0)
					 field: index)
			as: each ].
	self
		remember: (self
				 word: (self valueNamed: #columnCount)
				 dividedBy: (self constantWord: self class bytesPerWord))
		as: #wordColumnCount
]
