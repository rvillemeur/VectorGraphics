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
		'passes',
		'buffers',
		'kernels',
		'commandPool',
		'submissions'
	],
	#category : 'VectorGraphics-Vulkan-Blur',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Blur'
}

{ #category : 'constants' }
VGBlurDispatch class >> axisOfPass: anIndex [
	"The axis the pass at that index runs along. The passes of a blur always alternate, the first
	 along the rows, so the axis is the parity of the index; a kernel kept from a longer blur than
	 the one being planned is still the kernel of its own axis, which is what lets every kernel I
	 hold be rebound when a field buffer grows."
	^ anIndex odd
		  ifTrue: [ self rowsAxis ]
		  ifFalse: [ self columnsAxis ]
]

{ #category : 'constants' }
VGBlurDispatch class >> columnsAxis [
	"The name of a pass that runs down the columns."

	^ #columns
]

{ #category : 'constants' }
VGBlurDispatch class >> correctionsNameAt: anIndex [
	"The name of the rounding table of the pass at that index. One a pass for the reason
	 paramsNameAt: gives."
	^ ('corrections' , anIndex printString) asSymbol
]

{ #category : 'constants' }
VGBlurDispatch class >> fieldBufferNames [
	"The two buffers of the size of the field, which the passes alternate between. They are named
	 and not positional because the direction of a pass is which of the two a kernel reads."
	^ #( #fieldA #fieldB )
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
VGBlurDispatch class >> paramsNameAt: anIndex [
	"The name of the buffer that describes the pass at that index. Every pass of a blur has its
	 own, because a descriptor set is read when the device runs the command buffer and not when it
	 is recorded, so two passes of one submission cannot share one description."
	^ ('params' , anIndex printString) asSymbol
]

{ #category : 'constants' }
VGBlurDispatch class >> rowsAxis [
	"The name of a pass that runs along the rows."

	^ #rows
]

{ #category : 'blurring' }
VGBlurDispatch >> blur: aByteArray columns: aColumnCount rows: aRowCount boxRadii: aCollection [
	"Those bytes blurred by every box radius in turn, answered in the array they came in. The field
	 goes out to the device once and comes back once, and every pass runs in one submission,
	 however many passes there are. Neither the kernels nor the buffers are built here if an
	 earlier blur already built them: they belong to me and are let go of only when whoever holds
	 me releases the device."
	submissions := 0.
	self
		planPassesOfRadii: aCollection
		columns: aColumnCount
		rows: aRowCount.
	self growBuffersForWords: aByteArray size / VGBlurBoxKernel bytesPerWord.
	self prepareKernelsForPasses.
	self runPassesOnBytes: aByteArray.
	^ aByteArray
]

{ #category : 'accessing' }
VGBlurDispatch >> bufferNamesHeld [
	"Every buffer I hold, in the order a reading of my residency shows them: the two of the size of
	 the field first, then the pair every pass I have ever been planned as is described by. The
	 names are read off what I hold rather than written down, because the count of passes grows
	 with the largest blur the session has seen."
	| answer |
	answer := self class fieldBufferNames select: [ :each |
		          buffers includesKey: each ].
	^ answer
	  , ((1 to: buffers size) inject: OrderedCollection new into: [ :acc :index |
			   (buffers includesKey: (self class paramsNameAt: index)) ifTrue: [
				   acc
					   add: (self class paramsNameAt: index);
					   add: (self class correctionsNameAt: index) ].
			   acc ]) asArray
]

{ #category : 'device' }
VGBlurDispatch >> buffersOfPass: anIndex [
	"My buffers named as the kernel of that pass names its bindings. The pass along the rows reads
	 the first field and writes the second, the pass down the columns reads the second and writes
	 the first, so an axis is a pair of names swapped; the pair of small buffers is the pass's own.
	 The axis is the parity of the index and not what the plan I hold says, so a kernel kept from a
	 longer blur can be rebound too."
	| source target |
	(self class axisOfPass: anIndex) = self class rowsAxis
		ifTrue: [
			source := #fieldA.
			target := #fieldB ]
		ifFalse: [
			source := #fieldB.
			target := #fieldA ].
	^ Dictionary new
		  at: #source put: (buffers at: source);
		  at: #target put: (buffers at: target);
		  at: #params put: (buffers at: (self class paramsNameAt: anIndex));
		  at: #corrections
		  put: (buffers at: (self class correctionsNameAt: anIndex));
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

{ #category : 'device' }
VGBlurDispatch >> commandPoolOnce [
	"The pool every submission of mine cuts its command buffer from, created on the first blur and
	 kept afterwards. It is mine and not a kernel's, because the command buffer carries the passes
	 of several kernels."
	^ commandPool ifNil: [
		  commandPool := VkCommandPool
			                 on: context device
			                 queueFamilyIndex: context computeQueueFamily ]
]

{ #category : 'accessing' }
VGBlurDispatch >> context [
	^ context
]

{ #category : 'accessing' }
VGBlurDispatch >> deviceBuffers [
	"The buffers I hold, by name, so that a test and an inspection can read what is resident
	 without opening anything."
	^ buffers
]

{ #category : 'accessing' }
VGBlurDispatch >> deviceKernels [
	"The prepared kernels I hold, by axis, so that a test and an inspection can read what is
	 resident without opening anything."
	^ kernels
]

{ #category : 'residency' }
VGBlurDispatch >> ensureBuffersOfEveryPass [
	1 to: passes size do: [ :index |
		buffers at: (self class paramsNameAt: index) ifAbsentPut: [
			VkBuffer storageBuffer: VGBlurBoxKernel paramWords on: context device ].
		buffers at: (self class correctionsNameAt: index) ifAbsentPut: [
			VkBuffer storageBuffer: VGBlurRounding correctionWordCount on: context device ] ].
	^ buffers
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

{ #category : 'residency' }
VGBlurDispatch >> growBuffersForWords: aWordCount [
	"The buffers of one blur, held for the session: a params and a corrections buffer for every
	 pass, which never change size, and the two fields, which grow with the field of the largest
	 blur asked for and never shrink."

	self ensureBuffersOfEveryPass.
	^ self growFieldBuffersToWords: aWordCount
]

{ #category : 'residency' }
VGBlurDispatch >> growFieldBuffersToWords: aWordCount [
	"A grown field is rebound into every kernel that reads it before the buffer it replaces is
	 destroyed, because a descriptor set that still names a destroyed buffer is read by the device
	 on the next submission."

	| replaced bytes |
	bytes := aWordCount * VGBlurBoxKernel bytesPerWord.
	replaced := OrderedCollection new.
	self class fieldBufferNames do: [ :name |
		| held |
		held := buffers at: name ifAbsent: [ nil ].
		(held isNil or: [ held size < bytes ]) ifTrue: [
			buffers at: name put: (VkBuffer storageBuffer: aWordCount on: context device).
			held ifNotNil: [ replaced add: held ] ] ].
	replaced ifEmpty: [ ^ buffers ].
	self rebindKernels.
	replaced do: [ :each | each destroy ].
	^ buffers
]

{ #category : 'initialization' }
VGBlurDispatch >> initialize [
	"The buffers and the kernels I hold for as long as whoever holds me holds me, both empty until
	 a first blur asks the device for them."
	super initialize.
	buffers := Dictionary new.
	kernels := Dictionary new.
	submissions := 0
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

{ #category : 'inspecting' }
VGBlurDispatch >> inspectorResidency: aBuilder [
	<inspectorPresentationOrder: 20 title: 'Residency'>
	"Every buffer I hold, the bytes it has been grown to and the passes that read or write it. The
	 passes are asked of buffersOfPass: itself rather than restated here, so the view cannot
	 disagree with what is really bound, and the names come from what I hold rather than from a
	 list, because the count of passes grows with the largest blur the session has seen."
	^ aBuilder newTable
		  addColumn: (SpStringTableColumn
				   title: 'Buffer'
				   evaluated: [ :each | each asString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Bytes'
				   evaluated: [ :each | (buffers at: each) size printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Passes'
				   evaluated: [ :each |
					   (kernels keys asSortedCollection select: [ :index |
							    (self buffersOfPass: index) values includes:
								    (buffers at: each) ]) asArray printString ]);
		  items: self bufferNamesHeld;
		  yourself
]

{ #category : 'inspector' }
VGBlurDispatch >> inspectorResidencyContext: aContext [

	"The rows read buffers and kernels, so a dispatch that has planned no pass yet holds neither
	 and would show a tab of nothing."

	aContext active: buffers notEmpty
]

{ #category : 'device' }
VGBlurDispatch >> kernelOfPass: anIndex [
	"A prepared kernel that runs the pass at that index. The buffers are bound in the order the
	 kernel names its bindings in, so the contract is read and never restated here."
	| answer held |
	answer := PVComputeKernel on: context spirv: VGBlurBoxKernel spirv.
	held := self buffersOfPass: anIndex.
	VGBlurBoxKernel bindingNames do: [ :each |
		answer bindBuffer: (held at: each) ].
	answer prepare.
	^ answer
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

{ #category : 'device' }
VGBlurDispatch >> prepareKernelsForPasses [
	"One prepared kernel a pass, built as a blur first needs it and kept for every blur after it.
	 Preparing a kernel compiles its module and builds its pipeline, which unit 3.1 pays once a
	 session rather than once a blur. A blur of fewer passes than an earlier one runs the first of
	 the kernels and keeps the rest: the passes of a blur always alternate, the first along the
	 rows, so the kernel at an index always reads the field that index's axis reads."
	1 to: passes size do: [ :index |
		kernels at: index ifAbsentPut: [ self kernelOfPass: index ] ].
	^ kernels
]

{ #category : 'printing' }
VGBlurDispatch >> printOn: aStream [
	super printOn: aStream.
	kernels ifEmpty: [
		aStream nextPutAll: ' (no device asked for yet)'.
		^ self ].
	aStream
		nextPutAll: ' (';
		print: kernels size;
		nextPutAll: (kernels size = 1
				 ifTrue: [ ' pass resident, ' ]
				 ifFalse: [ ' passes resident, ' ]);
		print: submissions;
		nextPutAll: (submissions = 1
				 ifTrue: [ ' submission in the last blur)' ]
				 ifFalse: [ ' submissions in the last blur)' ])
]

{ #category : 'device' }
VGBlurDispatch >> rebindKernels [
	"Every kernel I hold made to point at the buffers I hold now, which is what a grown field
	 buffer needs: the descriptor set is written again and the pipeline is not built again. The
	 binding index is the position of the name in the kernel's own contract, so the two cannot
	 disagree."
	kernels keysAndValuesDo: [ :index :kernel |
		| held |
		held := self buffersOfPass: index.
		VGBlurBoxKernel bindingNames doWithIndex: [ :name :binding |
			kernel rebindBuffer: (held at: name) atBinding: binding - 1 ] ]
]

{ #category : 'device' }
VGBlurDispatch >> releaseDevice [
	"Everything of the device I hold let go of, the kernels before the buffers, because a buffer
	 freed under a live pipeline takes the image with it. The context is not mine and is not
	 destroyed here: whoever opened it closes it."
	kernels valuesDo: [ :each | each destroy ].
	kernels := Dictionary new.
	commandPool ifNotNil: [ commandPool destroy ].
	commandPool := nil.
	buffers valuesDo: [ :each | each destroy ].
	buffers := Dictionary new
]

{ #category : 'blurring' }
VGBlurDispatch >> runPassesOnBytes: aByteArray [
	"Every planned pass run over my buffers in one submission, the field uploaded before it and
	 read back after it. A pass along the rows reads the first field and writes the second, a pass
	 down the columns reads the second and writes the first, so the answer is in the first field
	 whatever the count of passes. Every pass is described before anything is submitted, which is
	 what one submission needs: the device reads a description when it runs the dispatch that reads
	 it, and the passes of one submission run one after another."
	(buffers at: #fieldA) uploadBytes: aByteArray.
	passes doWithIndex: [ :each :index |
		(buffers at: (self class paramsNameAt: index)) uploadBytes:
			(self bytesOfParams: each value).
		(buffers at: (self class correctionsNameAt: index)) uploadBytes:
			(self bytesOfCorrectionsOfDiameter: (each value at: #diameter)) ].
	self submitPasses.
	(buffers at: #fieldA) readbackInto: aByteArray
]

{ #category : 'initialization' }
VGBlurDispatch >> setContext: aContext [
	context := aContext
]

{ #category : 'accessing' }
VGBlurDispatch >> submissionsOfLastBlur [
	"How many times the last blur submitted work to the device. It is one, whatever the count of
	 passes, and a test holds that: a submission costs about 0.43 ms of the host, so the count is
	 what makes the device path of a small shadow cheaper than the host walk rather than dearer."
	^ submissions
]

{ #category : 'device' }
VGBlurDispatch >> submitPasses [
	"Every pass of the blur recorded into one command buffer and submitted once, with a barrier
	 between neighbours because dispatches of one command buffer are not ordered against each other
	 on their own and every pass reads the field the pass before it wrote. One submission and not
	 one a pass: a submission costs about 0.43 ms of host time whatever it carries, which is most
	 of what the device path of a small shadow costs at all. The pool is reset first, so the one
	 command buffer a blur cuts from it is the same memory every time."
	| cmd pool |
	pool := self commandPoolOnce.
	pool reset.
	cmd := pool allocateBuffer.
	cmd do: [ :recording |
		passes doWithIndex: [ :each :index |
			(kernels at: index)
				recordComputeInto: recording
				groupsAcross: (self groupsAcrossWordsOf: each value)
				down: (self groupsDownRowsOf: each value)
				layers: self class layersPerDispatch.
			index < passes size ifTrue: [
				recording recordComputeToComputeBarrier ] ] ].
	submissions := submissions + 1.
	context computeQueue submit: cmd andWait: true
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
