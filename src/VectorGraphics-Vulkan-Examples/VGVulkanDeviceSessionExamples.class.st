"
I hold the examples of unit 3.1: the device session a machine keeps, with the context, the kernels
and the buffers it holds between frames.

One click answers a session of its own, warmed by two frames of one tile extent, whose `Residency`
tab names every buffer it keeps and the bytes it was grown to. The session is a fresh one every
call, so clicking never releases the device the frames of this image are drawing on, and it is left
live, because a session that is released is a device opened again by the next frame.

Where no driver answers, the example records the reason and answers the session all the same: an
example may not raise on a machine with no device.

See `VGVulkanDeviceSession`, `VGTiledFillDispatch` and `VGVulkanBackend`.
"
Class {
	#name : 'VGVulkanDeviceSessionExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Vulkan-Examples-Examples',
	#package : 'VectorGraphics-Vulkan-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGVulkanDeviceSessionExamples class >> sessionOfThisMachine [
	<sampleInstance>
	"One click: the session of this machine, warmed by two frames of one tile extent and by two
	 blurs of a 64 by 64 field, with the Residency tab naming every buffer it keeps, the stage it
	 belongs to and the bytes each was grown to. The second frame and the second blur are drawn
	 because the point of the unit is what they do not pay: the context, the kernels, the
	 descriptor sets and the buffers of the first are all still there.
	 The session is a fresh one and not the default, so a click neither releases the device the
	 frames of this image draw on nor shows what another click left behind. It is answered live,
	 because a released session is a device the next frame opens again.
	 Where no driver answers, the reason is recorded on the session and nothing is drawn: an
	 example may not raise on a machine with no device."
	| session encoding target dispatch blur bytes radii |
	session := VGVulkanDeviceSession new.
	encoding := VGTiledFillExamples encodingOfThreeShapes.
	target := ByteArray new:
		          VGTiledFillExamples frameExtent x
		          * VGTiledFillExamples frameExtent y
		          * VGTiledFillEncoding targetFormat bytesPerPixel.
	dispatch := session dispatchForEncoding: encoding.
	dispatch ifNil: [ ^ session ].
	2 timesRepeat: [ dispatch draw: encoding into: target ].
	blur := session blurDispatch.
	bytes := ByteArray new: 64 * 64.
	radii := VGA8GaussianBlurFilter
		         boxRadiiForSigma: (VGA8GaussianBlurFilter sigmaForRadius: 10)
		         passes: VGA8GaussianBlurFilter defaultPassCount.
	2 timesRepeat: [ blur blur: bytes columns: 64 rows: 64 boxRadii: radii ].
	^ session
]
