"
I run the box passes of a Gaussian blur on the Vulkan device.

I am handed the bytes of an alpha field, its stride and its height, and the radius of each box pass, and I answer those bytes blurred. The field goes out to the device once and comes back once, however many passes there are: two buffers of the size of the field are kept and the passes alternate between them, a pass along the rows writing the second and a pass down the columns writing the first, which is how VGA8GaussianBlurFilter alternates its two host buffers. The answer is therefore in the first buffer whatever the count of passes is.

One module serves every pass. Two VGBlurBoxKernel instances are built over the same bytes, one binding the pair of field buffers in each order, so a pass chooses its direction by choosing its kernel. The two small buffers, the words that describe the pass and the rounding table of its diameter, are written again before each dispatch, which is safe because a dispatch waits for the device before it answers.

See VGBlurBoxKernel class >> paramNames for the words a pass is described by, and VGVulkanBlurFilter for the filter that decides whether a blur is mine at all.
"
Class {
	#name : 'VGBlurDispatch',
	#superclass : 'Object',
	#instVars : [
		'context',
		'passes'
	],
	#category : 'VectorGraphics-Vulkan-Blur',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Blur'
}

{ #category : 'constants' }
VGBlurDispatch class >> columnsAxis [
	"The name of a pass that runs down the columns."

	^ #columns
]

{ #category : 'constants' }
VGBlurDispatch class >> layersPerDispatch [
	"A field is flat, so a dispatch is one layer deep."

	^ 1
]

{ #category : 'instance creation' }
VGBlurDispatch class >> on: aContext [
	"A dispatch that blurs on that context. The device belongs to the caller and not to me: it
	 outlives one blur, and the buffers of a blur do not."

	^ self new setContext: aContext
]

{ #category : 'constants' }
VGBlurDispatch class >> rowsAxis [
	"The name of a pass that runs along the rows."

	^ #rows
]

{ #category : 'blurring' }
VGBlurDispatch >> blur: aByteArray columns: aColumnCount rows: aRowCount boxRadii: aCollection [
	"Those bytes blurred by every box radius in turn, answered in the array they came in. The field
	 goes out to the device once and comes back once, however many passes there are."

	| buffers |
	self
		planPassesOfRadii: aCollection
		columns: aColumnCount
		rows: aRowCount.
	buffers := self buffersForWords:
		           aByteArray size / VGBlurBoxKernel bytesPerWord.
	[ self runPassesOn: buffers bytes: aByteArray ] ensure: [
		buffers valuesDo: [ :each | each destroy ] ].
	^ aByteArray
]

{ #category : 'blurring' }
VGBlurDispatch >> buffersForWords: aWordCount [
	"The buffers a blur needs, answered by name: two of the size of the field, which the passes
	 alternate between, and the two small ones every pass is described by. They are named and not
	 positional because the direction of a pass is which of the two fields it reads."

	^ Dictionary new
		  at: #fieldA put: (VkBuffer storageBuffer: aWordCount on: context device);
		  at: #fieldB put: (VkBuffer storageBuffer: aWordCount on: context device);
		  at: #params
		  put: (VkBuffer
				   storageBuffer: VGBlurBoxKernel paramWords
				   on: context device);
		  at: #corrections
		  put: (VkBuffer
				   storageBuffer: VGBlurRounding correctionWordCount
				   on: context device);
		  yourself
]

{ #category : 'blurring' }
VGBlurDispatch >> bytesOfCorrectionsOfDiameter: anInteger [
	"The rounding table of that diameter as the device reads it: a bit for every quotient the host
	 filter writes one less than the whole quotient at. VGBlurRounding builds it by asking the
	 filter, so the table cannot drift from the arithmetic it stands for."

	| stride words answer |
	stride := VGBlurBoxKernel elementStride.
	words := (VGBlurRounding ofDiameter: anInteger) correctionWords.
	answer := ByteArray new: words size * stride.
	words withIndexDo: [ :each :index |
		answer uint32AtOffset: index - 1 * stride put: each ].
	^ answer
]

{ #category : 'blurring' }
VGBlurDispatch >> bytesOfParams: aDictionary [
	"The words of a pass as the device reads them, in the order the kernel names them, so the two
	 cannot disagree about which field is which."

	| stride names answer |
	stride := VGBlurBoxKernel elementStride.
	names := VGBlurBoxKernel paramNames.
	answer := ByteArray new: names size * stride.
	names withIndexDo: [ :each :index |
		answer uint32AtOffset: index - 1 * stride put: (aDictionary at: each) ].
	^ answer
]

{ #category : 'accessing' }
VGBlurDispatch >> context [
	^ context
]

{ #category : 'blurring' }
VGBlurDispatch >> groupsAcrossWordsOf: aDictionary [
	"The workgroups a pass needs across a row. An invocation owns one whole word of four bytes, and
	 the stride of an alpha surface is always a whole number of words, so the words of a row divide
	 exactly; the workgroups they fall in need not, and the kernel refuses the invocations past the
	 end."

	^ ((aDictionary at: #columnCount) / VGBlurBoxKernel bytesPerWord
	   / VGBlurBoxKernel workgroupWidth) ceiling
]

{ #category : 'blurring' }
VGBlurDispatch >> groupsDownRowsOf: aDictionary [
	^ ((aDictionary at: #rowCount) / VGBlurBoxKernel workgroupHeight) ceiling
]

{ #category : 'inspector' }
VGBlurDispatch >> inspectorPasses: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Passes'>
	"The passes I was planned as: the axis each runs along, every word it carries, and the
	 workgroups it dispatches. The columns are built from VGBlurBoxKernel paramNames and the counts
	 are asked of my own arithmetic, so a word added to the contract shows here without this
	 method being edited."

	| table |
	table := aBuilder newTable.
	table addColumn: (SpStringTableColumn
			 title: 'Axis'
			 evaluated: [ :each | each key ]).
	VGBlurBoxKernel paramNames do: [ :name |
		table addColumn: (SpStringTableColumn
				 title: name asString
				 evaluated: [ :each | (each value at: name) printString ]) ].
	table addColumn: (SpStringTableColumn
			 title: 'Groups across'
			 evaluated: [ :each | (self groupsAcrossWordsOf: each value) printString ]).
	table addColumn: (SpStringTableColumn
			 title: 'Groups down'
			 evaluated: [ :each | (self groupsDownRowsOf: each value) printString ]).
	table items: passes.
	^ table
]

{ #category : 'inspector' }
VGBlurDispatch >> inspectorPassesContext: aContext [
	aContext active: passes notNil
]

{ #category : 'blurring' }
VGBlurDispatch >> kernelFrom: aSourceBuffer to: aTargetBuffer params: aParamsBuffer corrections: aCorrectionsBuffer [
	"A kernel over the shared module that reads that buffer and writes that one. The direction of a
	 pass is the order the pair of field buffers is bound in and nothing else, which is why the two
	 directions are two kernels over one set of bytes. The buffers are bound in the order the kernel
	 names its bindings in, so the contract is read and never restated here."

	| answer buffers |
	answer := PVComputeKernel on: context spirv: VGBlurBoxKernel spirv.
	buffers := Dictionary new
		           at: #source put: aSourceBuffer;
		           at: #target put: aTargetBuffer;
		           at: #params put: aParamsBuffer;
		           at: #corrections put: aCorrectionsBuffer;
		           yourself.
	VGBlurBoxKernel bindingNames do: [ :each |
		answer bindBuffer: (buffers at: each) ].
	answer prepare.
	^ answer
]

{ #category : 'blurring' }
VGBlurDispatch >> kernelsOver: aDictionary [
	"One kernel for each axis, over the same module: the pass along the rows binds the first field
	 as its source and the second as its target, and the pass down the columns binds them the other
	 way about, so a pass chooses its direction by choosing its kernel."

	| params corrections |
	params := aDictionary at: #params.
	corrections := aDictionary at: #corrections.
	^ Dictionary new
		  at: self class rowsAxis
		  put: (self
				   kernelFrom: (aDictionary at: #fieldA)
				   to: (aDictionary at: #fieldB)
				   params: params
				   corrections: corrections);
		  at: self class columnsAxis
		  put: (self
				   kernelFrom: (aDictionary at: #fieldB)
				   to: (aDictionary at: #fieldA)
				   params: params
				   corrections: corrections);
		  yourself
]

{ #category : 'accessing' }
VGBlurDispatch >> passes [
	"The words of every pass of the last blur, in the order they were dispatched, kept so that
	 what the device was told can be read after the device is gone."

	^ passes
]

{ #category : 'blurring' }
VGBlurDispatch >> planPassesOfRadii: aCollection columns: aColumnCount rows: aRowCount [
	"The passes of a blur, each the axis it runs along and the words that describe it, kept so that
	 what the device was told can be read after the device is gone. Every radius is one pass along
	 the rows followed by one down the columns, which is what makes a separable approximation of a
	 two-dimensional Gaussian and is the order VGA8GaussianBlurFilter runs them in. A blur is planned
	 on its own where there is no device, which is what an example on a machine with no driver can
	 still show."

	passes := OrderedCollection new.
	aCollection do: [ :boxRadius |
		passes add: self class rowsAxis -> (self
				 wordsAlongRowsOfRadius: boxRadius
				 columns: aColumnCount
				 rows: aRowCount).
		passes add: self class columnsAxis -> (self
				 wordsDownColumnsOfRadius: boxRadius
				 columns: aColumnCount
				 rows: aRowCount) ].
	^ passes
]

{ #category : 'blurring' }
VGBlurDispatch >> run: aKernel words: aDictionary params: aParamsBuffer corrections: aCorrectionsBuffer [
	"One box pass: the words that describe it and the rounding table of its diameter written, then
	 one invocation for every word of every row of the field. The two small buffers are written
	 again before every pass, which is safe because a dispatch waits for the device before it
	 answers, so no pass reads what the next one wrote."

	aParamsBuffer uploadBytes: (self bytesOfParams: aDictionary).
	aCorrectionsBuffer uploadBytes:
		(self bytesOfCorrectionsOfDiameter: (aDictionary at: #diameter)).
	aKernel
		dispatch: (self groupsAcrossWordsOf: aDictionary)
		y: (self groupsDownRowsOf: aDictionary)
		z: self class layersPerDispatch
]

{ #category : 'blurring' }
VGBlurDispatch >> runPassesOn: aDictionary bytes: aByteArray [
	"Every planned pass run over those buffers, the field uploaded before the first and read back
	 after the last. A pass along the rows reads the first field and writes the second, a pass down
	 the columns reads the second and writes the first, so the answer is in the first field whatever
	 the count of passes. The kernels are destroyed before the buffers, because a buffer freed under
	 a live pipeline takes the image with it."

	| kernels |
	kernels := self kernelsOver: aDictionary.
	[
	(aDictionary at: #fieldA) uploadBytes: aByteArray.
	passes do: [ :each |
		self
			run: (kernels at: each key)
			words: each value
			params: (aDictionary at: #params)
			corrections: (aDictionary at: #corrections) ].
	(aDictionary at: #fieldA) readbackInto: aByteArray ] ensure: [
		kernels valuesDo: [ :each | each destroy ] ]
]

{ #category : 'initialization' }
VGBlurDispatch >> setContext: aContext [
	context := aContext
]

{ #category : 'blurring' }
VGBlurDispatch >> wordsAlongRowsOfRadius: aRadius columns: aColumnCount rows: aRowCount [
	"A pass along the rows: one byte to the next tap, and a tap clamped to the ends of the row. The
	 column count is the stride of the surface and not its width, so the padding bytes of a row
	 blur, which is what VGA8GaussianBlurFilter does and what Cairo lets happen."

	^ (self
		   wordsOfRadius: aRadius
		   columns: aColumnCount
		   rows: aRowCount)
		  at: #step put: 1;
		  at: #axisLimit put: aColumnCount;
		  at: #columnWeight put: 1;
		  at: #rowWeight put: 0;
		  yourself
]

{ #category : 'blurring' }
VGBlurDispatch >> wordsDownColumnsOfRadius: aRadius columns: aColumnCount rows: aRowCount [
	"A pass down the columns: a whole row to the next tap, and a tap clamped to the first and the
	 last row."

	^ (self
		   wordsOfRadius: aRadius
		   columns: aColumnCount
		   rows: aRowCount)
		  at: #step put: aColumnCount;
		  at: #axisLimit put: aRowCount;
		  at: #columnWeight put: 0;
		  at: #rowWeight put: 1;
		  yourself
]

{ #category : 'blurring' }
VGBlurDispatch >> wordsOfRadius: aRadius columns: aColumnCount rows: aRowCount [
	"The words every pass carries whichever axis it runs along: the diameter and the radius of the
	 box and the shape of the field. The three words that name the axis are added by the caller."

	^ Dictionary new
		  at: #diameter put: aRadius + aRadius + 1;
		  at: #radius put: aRadius;
		  at: #columnCount put: aColumnCount;
		  at: #rowCount put: aRowCount;
		  yourself
]
