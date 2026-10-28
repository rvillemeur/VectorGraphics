"
I gate unit 2.8: the Gaussian blur of a shadow, run on the device.

I am a subclass of VGBlurTest and answer the device filter for its blur, so every fact that class states about the software filter — a flat field left flat, a dot spread symmetrically, the clamped window average of every byte, and Alexandrie byte for byte with and without stride padding — is stated again about the device. Nothing here loosens a tolerance: the kernel divides in integers and corrects the one rounding Float64 gives the software filter, so the two write the same bytes or the unit has failed.

The filter falls back to the software path where the device is missing or where the shape of the surface is one the walk would overrun, so the inherited tests hold on a machine with no driver as well. The tests of my own are the ones that say the device really ran.
"
Class {
	#name : 'VGVulkanBlurTest',
	#superclass : 'VGBlurTest',
	#category : 'VectorGraphics-Vulkan-Tests-Tests',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Tests'
}

{ #category : 'testing' }
VGVulkanBlurTest class >> shouldInheritSelectors [
	"SUnit hands a concrete subclass the tests of its superclass only where the subclass has none of
	 its own. Mine are an addition and not a replacement: the whole of VGBlurTest, the Alexandrie
	 comparisons and all, is to run against the device filter, which is what the filterClass hook
	 exists for."

	^ true
]

{ #category : 'fixtures' }
VGVulkanBlurTest >> filterClass [
	^ VGVulkanBlurFilter
]

{ #category : 'fixtures' }
VGVulkanBlurTest >> maskOfGeometry: aBlock blurRadius: aRadius blurredWith: aFilterClass [
	"The alpha surface a shadow is masked through, blurred by the filter named: the geometry drawn
	 opaque into an alpha-only surface of the conformance case size, which is what
	 VGConformanceCorpus builds for its four shadow cases and what AeCanvas builds for a Bloc
	 shadow."

	| surface context filter |
	surface := VGCairoImageSurface
		           extent: VGConformanceCorpus caseExtent
		           format: VGCairoSurfaceFormat a8.
	context := surface newContext.
	context sourceColorR: 0.0 g: 0.0 b: 0.0 a: 1.0.
	aBlock value: context.
	context fill.
	filter := aFilterClass new.
	filter
		surface: surface;
		applyRadius: aRadius.
	^ filter -> (self bytesOf: surface) asArray
]

{ #category : 'tests' }
VGVulkanBlurTest >> testABoxWiderThanTheFieldItWalksIsLeftToTheHostPath [
	"The host filter walks a row in three parts and those parts overrun into the next row where the
	 box is wider than the row itself, which reads bytes no window of that pixel holds and, past the
	 last row, reads off the end of the buffer altogether. That is what the host filter really does,
	 and the device kernel reads a clamped window instead, so a field that narrow is refused and the
	 host walk keeps it — overrun and all, which the last assertion states. A shadow never asks for
	 one, a sixty-four point radius being a box of forty-seven, but a caller may."

	| narrow |
	narrow := self filterClass new.
	narrow surface: (self
			 ourSurfaceOfExtent: 64 @ 3
			 seededWith: (self seedBytesOfSize: 64 * 3)).
	self deny: (narrow supportsBoxRadii: #( 7 )).
	self assert: (narrow supportsBoxRadii: #( 1 )).
	self should: [ narrow applyBoxRadii: #( 7 ) ] raise: Error.
	self deny: narrow ranOnTheDevice
]

{ #category : 'tests' }
VGVulkanBlurTest >> testADeviceBlurIsOneSubmissionWhateverTheCountOfPasses [
	"Every pass of a blur is recorded into one command buffer and submitted once. It matters
	 because a submission costs about 0.43 ms of the host whatever it carries, so six of them cost
	 more than the host walk the device path is meant to beat. The kernels are one a pass and are
	 kept for the largest blur the session has seen, which is what lets a shorter blur reuse the
	 first of them."

	| session dispatch bytes |
	session := VGVulkanDeviceSession new.
	session contextOrNil ifNil: [ ^ self ].
	bytes := ByteArray new: 64 * 64.
	dispatch := session blurDispatch.
	[
	dispatch blur: bytes columns: 64 rows: 64 boxRadii: #( 2 2 2 ).
	self assert: dispatch passes size equals: 6.
	self assert: dispatch submissionsOfLastBlur equals: 1.
	self assert: dispatch deviceKernels size equals: dispatch passes size.
	dispatch blur: bytes columns: 64 rows: 64 boxRadii: #( 2 ).
	self assert: dispatch passes size equals: 2.
	self assert: dispatch submissionsOfLastBlur equals: 1.
	self assert: dispatch deviceKernels size equals: 6 ] ensure: [
		session releaseDevice ]
]

{ #category : 'tests' }
VGVulkanBlurTest >> testADeviceBlurKeepsItsKernelsAndItsBuffersBetweenBlurs [
	"The kernels and the buffers of a blur last as long as the session, a field buffer grows for a
	 larger blur and never shrinks for a smaller one, and the pair of buffers a pass is described
	 by is the same size for every blur and so is never replaced. Releasing the session lets go of
	 all of it."

	| session dispatch small large held kernels grown paramsName |
	session := VGVulkanDeviceSession new.
	session contextOrNil ifNil: [ ^ self ].
	small := ByteArray new: 64 * 64.
	large := ByteArray new: 256 * 256.
	paramsName := VGBlurDispatch paramsNameAt: 1.
	dispatch := session blurDispatch.
	[
	self assert: session blurDispatch == dispatch.
	dispatch blur: small columns: 64 rows: 64 boxRadii: #( 2 2 ).
	held := dispatch deviceBuffers copy.
	kernels := dispatch deviceKernels copy.
	dispatch blur: small columns: 64 rows: 64 boxRadii: #( 2 2 ).
	held keysAndValuesDo: [ :name :buffer |
		self assert: (dispatch deviceBuffers at: name) == buffer ].
	kernels keysAndValuesDo: [ :index :kernel |
		self assert: (dispatch deviceKernels at: index) == kernel ].
	dispatch blur: large columns: 256 rows: 256 boxRadii: #( 2 2 ).
	self deny: (dispatch deviceBuffers at: #fieldA) == (held at: #fieldA).
	self deny: (dispatch deviceBuffers at: #fieldB) == (held at: #fieldB).
	self assert:
		(dispatch deviceBuffers at: paramsName) == (held at: paramsName).
	grown := dispatch deviceBuffers at: #fieldA.
	dispatch blur: small columns: 64 rows: 64 boxRadii: #( 2 2 ).
	self assert: (dispatch deviceBuffers at: #fieldA) == grown ] ensure: [
		session releaseDevice ].
	self assert: dispatch deviceBuffers isEmpty.
	self assert: dispatch deviceKernels isEmpty
]

{ #category : 'tests' }
VGVulkanBlurTest >> testADeviceBlurReallyRunsOnTheDeviceWhenThereIsOne [
	"Every other test of mine passes on a machine with no driver, because the filter falls back to
	 the host path. This one says what the unit is for: where a device computes, the bytes above
	 came from it. The session is asked whether there is a device at all, and the filter draws on
	 the one it holds."

	| filter surface |
	VGVulkanDeviceSession default contextOrNil ifNil: [ ^ self ].
	surface := self
		           ourSurfaceOfExtent: 16 @ 16
		           seededWith: (self seedBytesOfSize: 16 * 16).
	filter := self filterClass new.
	filter
		surface: surface;
		applySigma: 4.
	self assert: filter ranOnTheDevice
]

{ #category : 'tests' }
VGVulkanBlurTest >> testTheFourShadowMasksOfTheCorpusAreTheSameBytesOnTheDevice [
	"The gate of the unit. The four shadow cases of unit 1.9 are what the blur exists for, and their
	 masks are blurred twice here, once on the host and once on the device, and compared byte for
	 byte rather than within the shadow tolerance the corpus allows against Alexandrie: that
	 tolerance covers the rasterisation of the geometry underneath, which is the same picture on both
	 sides of this comparison, so the blur itself owes exactness.
	 The masks are compared on a machine with no device too, where both sides are the host path.
	 What a device adds is the last assertion: either every mask with a radius to blur by was
	 blurred on the device or none was, and never some of them."

	| geometries radii blurring ranOnTheDevice |
	geometries := VGConformanceCorpus shadowCaseGeometries.
	radii := VGConformanceCorpus shadowCaseBlurRadii.
	self assert: geometries size equals: radii size.
	blurring := 0.
	ranOnTheDevice := 0.
	geometries withIndexDo: [ :each :index |
		| host device |
		host := self
			        maskOfGeometry: each value
			        blurRadius: (radii at: index)
			        blurredWith: VGA8GaussianBlurFilter.
		device := self
			          maskOfGeometry: each value
			          blurRadius: (radii at: index)
			          blurredWith: self filterClass.
		self
			assert: device value = host value
			description: 'the device and the host blurred ' , each key
				, ' into different bytes'.
		(radii at: index) isZero ifFalse: [
			blurring := blurring + 1.
			device key ranOnTheDevice ifTrue: [
				ranOnTheDevice := ranOnTheDevice + 1 ] ] ].
	self assert: blurring > 0.
	self
		assert: (ranOnTheDevice isZero or: [ ranOnTheDevice = blurring ])
		description: 'the device blurred some of the shadow masks and not the others'
]

{ #category : 'tests' }
VGVulkanBlurTest >> testTheKernelBindsOneBufferForEveryBufferItReadsAndNamesThemAllInItsInterface [
	"The four buffers of the binding contract: the field read, the field written, the parameters
	 of the pass and the table of corrections. They stand at one descriptor set, numbered from
	 zero in the order bindingNames holds them, and under SPIR-V 1.5 the entry point names every
	 one of them and every built-in it reads."

	| validator |
	PVSpirvValidator isAvailable ifFalse: [ ^ self skip ].
	validator := PVSpirvValidator on: VGBlurBoxKernel spirv.
	self
		assert:
		(validator variableIdsInStorageClass: SpvStorageClass storageBuffer) size
		equals: VGBlurBoxKernel bindingNames size.
	self
		assert: validator entryPointInterfaceIds size
		equals: VGBlurBoxKernel bindingNames size
			+ VGBlurBoxKernel builtInNumbers size
]

{ #category : 'tests' }
VGVulkanBlurTest >> testTheKernelModuleIsValidSpirv [
	"The box kernel, assembled by hand: the tap loop, the four pixels of the word it writes and
	 the correction it looks up. spirv-val reads all of it, and a driver refuses what it refuses."

	| validator |
	PVSpirvValidator isAvailable ifFalse: [ ^ self skip ].
	validator := PVSpirvValidator on: VGBlurBoxKernel spirv.
	self
		assert: validator isValid
		description: 'the blur box kernel produced invalid SPIR-V: '
			, validator validationOutput
]

{ #category : 'tests' }
VGVulkanBlurTest >> testTheSelectedBackendNamesTheFilterAShadowIsBlurredWith [
	"A shadow is blurred by the filter the selected backend owns, which is how the device blur
	 reaches a Bloc window and the conformance corpus without either of them naming a Vulkan
	 class. The base answer is the host filter, because a backend that says nothing about blurring
	 blurs on the host."

	self assert: VGBackend blurFilterClass equals: VGA8GaussianBlurFilter.
	self assert: VGVulkanBackend blurFilterClass equals: self filterClass.
	self
		assert: (VGBackend withAllSubclasses allSatisfy: [ :each |
				 each blurFilterClass includesBehavior: VGA8GaussianBlurFilter ])
		description: 'a backend answers a blur filter that is not a blur filter'
]

{ #category : 'tests' }
VGVulkanBlurTest >> testTheStrideOfAnAlphaSurfaceIsAlwaysAWholeNumberOfWords [
	"The kernel writes a whole word at a time, four pixels of one row, which is sound only because
	 a row of an alpha surface is a whole number of words and so every row starts word-aligned.
	 Cairo aligns the stride of an a8 surface to four bytes, and the filter refuses a surface it
	 does not; this is why that refusal never fires in practice."

	| stride |
	1 to: 40 do: [ :width |
		stride := (VGCairoImageSurface
			           extent: width @ 2
			           format: VGCairoSurfaceFormat a8) stride.
		self assert: stride \\ VGBlurBoxKernel bytesPerWord equals: 0.
		self assert: stride >= width ]
]
