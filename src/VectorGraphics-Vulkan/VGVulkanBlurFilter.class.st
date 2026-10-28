"
I am the Gaussian blur of VGA8GaussianBlurFilter with its box passes run on the Vulkan device.

I am the filter VGVulkanBackend owns, and the backend the engine selects is what the Bloc canvas and the conformance corpus ask for a blur, so a machine with a device blurs every shadow it draws through me without any caller naming me.

I decide one thing and compute nothing: whether the passes of a blur are ones the device path reproduces exactly. Two shapes are not. An invocation writes one whole word of four alpha bytes, so the stride of the surface has to be a whole number of words; and a box wider than the axis it walks is left to the host, because VGA8GaussianBlurFilter's three-phase walk runs off the end of a row there and blurs the next row's bytes into it, which is a defect of that walk and not the blur I am to reproduce. Where either holds I run the host walk instead, and ranOnTheDevice says which of the two ran.

A device that fails part way through leaves my buffers half blurred, so the recovery starts again from the surface and runs the whole host walk; the failure it recovered from is kept in deviceFailure rather than dropped. See VGBlurDispatch for the passes and VGBlurBoxKernel for the arithmetic of one of them.
"
Class {
	#name : 'VGVulkanBlurFilter',
	#superclass : 'VGA8GaussianBlurFilter',
	#instVars : [
		'ranOnTheDevice',
		'deviceFailure'
	],
	#category : 'VectorGraphics-Vulkan-Blur',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Blur'
}

{ #category : 'blurring' }
VGVulkanBlurFilter >> applyBoxRadii: aCollection [
	"Every pass of the blur on the device where the device path reproduces the host walk exactly,
	 and the host walk itself where it does not or where the device fails. A failed device leaves my
	 buffers half blurred, so the recovery starts again from the surface, which is what the
	 inherited method does."

	ranOnTheDevice := false.
	deviceFailure := nil.
	(self supportsBoxRadii: aCollection) ifFalse: [
		^ super applyBoxRadii: aCollection ].
	^ [ self blurOnTheDeviceWithBoxRadii: aCollection ]
		  on: Error
		  do: [ :failure |
			  deviceFailure := failure.
			  super applyBoxRadii: aCollection ]
]

{ #category : 'blurring' }
VGVulkanBlurFilter >> blurOnTheDeviceWithBoxRadii: aCollection [
	"The passes on the device: the field read out of the surface as the host path reads it, blurred
	 in the buffers the device owns, and written back once at the end. The dispatch is the
	 session's and is neither built nor released here, which is what makes a small shadow cheaper
	 on the device than on the host: unit 2.8 paid 37 to 52 ms to open a context a blur, and unit
	 3.0 still paid two kernels prepared and four buffers created and destroyed a blur. A machine
	 with no device raises here, naming the fault, and my caller takes the host walk."
	| dispatch |
	dispatch := VGVulkanDeviceSession default blurDispatch ifNil: [
		            VkError signal:
			            VGVulkanDeviceSession noDeviceErrorMessage
			            , VGVulkanDeviceSession default unavailableReason ].
	self prepareBuffers.
	dispatch
		blur: bufferA
		columns: columnCount
		rows: rowCount
		boxRadii: aCollection.
	self writeBufferBackToTheSurface.
	ranOnTheDevice := true
]

{ #category : 'accessing' }
VGVulkanBlurFilter >> deviceFailure [
	"The error the device path answered, where the host walk ran because the device failed rather
	 than because it was never asked. It is nil otherwise."

	^ deviceFailure
]

{ #category : 'inspector' }
VGVulkanBlurFilter >> deviceRows [
	"What the Device tab shows. The radii are the ones VGA8GaussianBlurFilter's own Box radii tab
	 shows, each turned into the box passes a shadow of that radius really runs and asked of the
	 predicate."

	| answer |
	answer := OrderedCollection new.
	answer add: { 'Ran on the device'. self ranOnTheDevice printString }.
	answer add: { 'Recovered failure'.
		(deviceFailure
			 ifNil: [ 'none' ]
			 ifNotNil: [ :failure |
			 failure class name , ': ' , failure messageText printString ]) }.
	answer add: { 'Field'.
		columnCount printString , ' by ' , rowCount printString }.
	answer add: { 'Words a row'.
		(columnCount / VGBlurBoxKernel bytesPerWord) printString }.
	self class inspectorRadiiShown do: [ :radius |
		| radii |
		radii := self class
			         boxRadiiForSigma: (self class sigmaForRadius: radius)
			         passes: self class defaultPassCount.
		answer add: { 'Shadow radius ' , radius printString.
			(self supportsBoxRadii: radii) printString } ].
	^ answer
]

{ #category : 'inspector' }
VGVulkanBlurFilter >> inspectorDevice: aBuilder [
	<inspectorPresentationOrder: 12 title: 'Device'>
	"Which path blurred these bytes, what the recovery was if the device failed, and which shadow
	 radii of this field the device would take at all. The last rows sample my own predicate rather
	 than restate it, so a field whose stride is not a whole number of words, or whose rows are
	 fewer than a box diameter, shows false against every radius it refuses."

	^ aBuilder newTable
		  addColumn: (SpStringTableColumn
				   title: 'Question'
				   evaluated: [ :each | each first ]);
		  addColumn: (SpStringTableColumn
				   title: 'Answer'
				   evaluated: [ :each | each second ]);
		  items: self deviceRows;
		  yourself
]

{ #category : 'inspector' }
VGVulkanBlurFilter >> inspectorDeviceContext: aContext [
	aContext active: self surface notNil
]

{ #category : 'accessing' }
VGVulkanBlurFilter >> ranOnTheDevice [
	"Whether the last blur ran its passes on the device. It is false before a blur, and false after
	 one the device path refused or failed at."

	^ ranOnTheDevice == true
]

{ #category : 'testing' }
VGVulkanBlurFilter >> supportsBoxRadii: aCollection [
	"Whether the device path reproduces those passes exactly. An invocation writes one whole word of
	 four alpha bytes, so the stride has to be a whole number of words — every Cairo alpha stride
	 is, and the test holds it. A box no wider than the axis it walks is one the host walks in three
	 phases that cover the axis exactly; a wider one overruns into the next row, so it is left to
	 the host walk that defines it."

	(columnCount \\ VGBlurBoxKernel bytesPerWord) isZero ifFalse: [ ^ false ].
	^ aCollection allSatisfy: [ :each |
		  | diameter |
		  diameter := each + each + 1.
		  diameter <= columnCount and: [ diameter <= rowCount ] ]
]
