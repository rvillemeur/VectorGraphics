"
I hold the examples of unit 2.8: the rounding of a box diameter, the kernel that blurs one, the
passes a blur is planned as, and a shadow mask blurred.

Each is one click from the browser and each rebuilds its object. Three of them need no driver at
all: a rounding table, a kernel module and a plan of passes are all built on the host, which is why
the plan is kept on the dispatch rather than computed inside it. `shadowMaskBlurred` falls back to
the host path where there is no device, and its tab says which path ran.

See `VGBlurRounding`, `VGBlurBoxKernel`, `VGBlurDispatch` and `VGVulkanBlurFilter`.
"
Class {
	#name : 'VGVulkanBlurExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Vulkan-Examples-Examples',
	#package : 'VectorGraphics-Vulkan-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGVulkanBlurExamples class >> boxKernel [
	<sampleInstance>
	"The kernel both axes of a blur run. Its Bindings and Module tabs come from VGSpirvKernel and
	 read the module built from this very object, and its Params tab names the words a pass
	 describes itself by. Nothing here touches a driver: a module is bytes."

	^ VGBlurBoxKernel new
]

{ #category : 'examples' }
VGVulkanBlurExamples class >> passesOfAShadowBlur [
	<sampleInstance>
	"The passes a shadow of sigma eight is blurred as, planned for a field of 256 bytes a row and
	 128 rows and never dispatched: six of them, a box radius run along the rows and then down the
	 columns, the three radii those of VGA8GaussianBlurFilter's own three passes. The Passes tab
	 reads the words each one carries and the workgroups it would need, which is the whole of what
	 a device is told. A dispatch plans a blur with no device, so this example runs on a machine
	 with no driver."

	| dispatch |
	dispatch := VGBlurDispatch new.
	dispatch
		planPassesOfRadii: (VGA8GaussianBlurFilter
				 boxRadiiForSigma: 8
				 passes: VGA8GaussianBlurFilter defaultPassCount)
		columns: 256
		rows: 128.
	^ dispatch
]

{ #category : 'examples' }
VGVulkanBlurExamples class >> residentBlurOfThisMachine [
	<sampleInstance>
	"One click: the blur dispatch of this machine, warmed by two blurs of a 64 by 64 field at the
	 radii a shadow of width ten asks for. The Residency tab names every buffer it keeps, the bytes
	 each was grown to and the passes that read it, and the Passes tab the passes of the last blur.
	 The second blur is run because the point of unit 3.1 is what the second blur does not pay: the
	 six kernels, the descriptor sets, the command pool and the buffers of the first are all still
	 there, and the whole of it goes to the device as one submission.
	 The session is a fresh one and not the default, so a click neither releases the device the
	 frames of this image draw on nor shows what another click left behind.
	 Where no driver answers, a dispatch with no device is answered, planned as the same passes and
	 never dispatched: an example may not raise on a machine with no device."
	| session dispatch bytes radii |
	session := VGVulkanDeviceSession new.
	bytes := ByteArray new: 64 * 64.
	radii := VGA8GaussianBlurFilter
		         boxRadiiForSigma: (VGA8GaussianBlurFilter sigmaForRadius: 10)
		         passes: VGA8GaussianBlurFilter defaultPassCount.
	dispatch := session blurDispatch.
	dispatch ifNil: [
		dispatch := VGBlurDispatch new.
		dispatch planPassesOfRadii: radii columns: 64 rows: 64.
		^ dispatch ].
	2 timesRepeat: [
		dispatch blur: bytes columns: 64 rows: 64 boxRadii: radii ].
	^ dispatch
]

{ #category : 'examples' }
VGVulkanBlurExamples class >> roundingOfACorrectedDiameter [
	<sampleInstance>
	"The rounding of one of the twenty diameters where the host filter's Float64 reciprocal loses a
	 unit. The Corrections tab names every quotient the device has to subtract one from, each asked
	 of VGA8GaussianBlurFilter itself, so the table cannot drift from the arithmetic it copies.
	 A diameter of forty-nine is a box radius of twenty-four, which a shadow of sigma about
	 seventeen asks for."

	^ VGBlurRounding ofDiameter: 49
]

{ #category : 'examples' }
VGVulkanBlurExamples class >> shadowMaskBlurred [
	<sampleInstance>
	"The mask of a shadow, blurred. A circle drawn opaque into an alpha-only surface is what a
	 shadow is masked through, and the filter blurs it in place: the Mask tab shows the grey image
	 the blur answers and the Device tab says whether the device computed it, what the recovery was
	 if it did not, and which radii of this field the device would take at all. Where there is no
	 driver the host path runs and the picture is the same bytes."

	| surface filter |
	surface := VGCairoImageSurface
		           extent: 96 @ 96
		           format: VGCairoSurfaceFormat a8.
	surface newContext
		sourceColorR: 0.0 g: 0.0 b: 0.0 a: 1.0;
		circleCenterX: 48 y: 48 radius: 28;
		fill.
	filter := VGVulkanBlurFilter new.
	filter
		surface: surface;
		applyRadius: 10.
	^ filter
]
