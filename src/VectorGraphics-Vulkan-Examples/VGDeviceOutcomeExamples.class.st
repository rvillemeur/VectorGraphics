"
I hold the examples of `VGDeviceOutcome`: what the device half of a benchmarked frame answered on this machine.

One click shows the device that drew a frame of the corpus, the picture it drew and the verdict on its pixels — or, on a machine with no driver, the reason none drew, which is an outcome and not a failure.
"
Class {
	#name : 'VGDeviceOutcomeExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Vulkan-Examples-Examples',
	#package : 'VectorGraphics-Vulkan-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGDeviceOutcomeExamples class >> outcomeOfTheReferenceFrameOnThisMachine [
	<sampleInstance>
	"The device half of one benchmarked frame, as this machine answers it: the device that drew
	 the frame, the picture, and whether those pixels are the ones software draws — or the
	 reason no device drew, on a machine with no driver.
	 This opens a device of its own and dispatches a frame, so it takes a second or two."

	^ VGFrameDeviceBenchmark onTheReferenceFrame run measureSoftwareFrame outcome
]
