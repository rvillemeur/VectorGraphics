"
I hold the tests of `VGVulkanRoundTrip`, the round trip budget of unit 2.1.
"
Class {
	#name : 'VGVulkanRoundTripTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Vulkan-Tests-Tests',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
VGVulkanRoundTripTest >> testAMachineWithNoDeviceSaysSoAndMeasuresNothing [
	"Rule six of section 9: the engine runs where there is no driver. A round trip that cannot be
	 measured answers why, and nothing it did not measure."

	| trip |
	trip := VGNoDeviceRoundTripStub reference run.
	self deny: trip isAvailable.
	self deny: trip hasRun.
	self assert: trip unavailableReason equals: VGNoDeviceRoundTripStub reason.
	self assert: trip verdict equals: VGVulkanRoundTrip unknownVerdict
]

{ #category : 'tests' }
VGVulkanRoundTripTest >> testAnUnmeasuredRoundTripHasNoVerdictAndNoTotal [

	| trip |
	trip := VGVulkanRoundTrip reference.
	self deny: trip hasRun.
	self assert: trip roundTripMilliseconds isNil.
	self assert: trip verdict equals: VGVulkanRoundTrip unknownVerdict
]

{ #category : 'tests' }
VGVulkanRoundTripTest >> testHalvingTheTimeDoublesTheRate [
	"The rates are the frame over the time, so they cannot be read the wrong way round."

	| slow fast |
	slow := VGVulkanRoundTrip reference.
	slow recordUpload: 4 fill: 4 readback: 4.
	fast := VGVulkanRoundTrip reference.
	fast recordUpload: 2 fill: 2 readback: 2.
	self assert: slow uploadMegabytesPerSecond > 0.
	self
		assert: fast uploadMegabytesPerSecond
		closeTo: slow uploadMegabytesPerSecond * 2.
	self
		assert: fast fillMegapixelsPerSecond
		closeTo: slow fillMegapixelsPerSecond * 2.
	self
		assert: fast readbackMegabytesPerSecond
		closeTo: slow readbackMegabytesPerSecond * 2
]

{ #category : 'tests' }
VGVulkanRoundTripTest >> testTheGateHasNoVerdictWithTheSoftwareSideMissing [
	"Half a measurement is not a verdict: the gate of unit 2.1 is a comparison, and a round trip
	 of three milliseconds says nothing until the software frame it is compared with is known."

	| trip |
	trip := VGVulkanRoundTrip reference.
	trip recordUpload: 1 fill: 1 readback: 1.
	self assert: trip verdict equals: VGVulkanRoundTrip unknownVerdict
]

{ #category : 'tests' }
VGVulkanRoundTripTest >> testTheGateIsGoWhenTheRoundTripIsCheaperThanTheSoftwareFrame [

	| trip |
	trip := VGVulkanRoundTrip reference.
	trip recordUpload: 1 fill: 1 readback: 1.
	trip softwareMilliseconds: 100.
	self assert: trip verdict equals: VGVulkanRoundTrip goVerdict.
	self assert: trip isGo
]

{ #category : 'tests' }
VGVulkanRoundTripTest >> testTheGateIsNoGoWhenTheRoundTripCostsMoreThanTheSoftwareFrame [

	| trip |
	trip := VGVulkanRoundTrip reference.
	trip recordUpload: 50 fill: 50 readback: 50.
	trip softwareMilliseconds: 100.
	self assert: trip verdict equals: VGVulkanRoundTrip noGoVerdict.
	self deny: trip isGo
]

{ #category : 'tests' }
VGVulkanRoundTripTest >> testTheMeasurementNamesTheDeviceItWasMadeOn [
	"Three numbers mean nothing without the device that produced them: a software Vulkan driver
	 and a discrete card give the same shape of report and a different verdict's worth of
	 hardware, so the report names what it measured."

	| trip |
	trip := VGVulkanRoundTrip reference.
	self assert: trip deviceName isNil.
	trip run.
	trip isAvailable
		ifTrue: [ self deny: trip deviceName isEmpty ]
		ifFalse: [ self assert: trip deviceName isNil ]
]

{ #category : 'tests' }
VGVulkanRoundTripTest >> testTheReferenceRoundTripIsTheFrameTheProfileMeasured [
	"The gate compares the GPU round trip with the software frame of unit 1.11, so it has to be
	 the same frame. The extent is asked of the profile rather than written down again."

	self
		assert: VGVulkanRoundTrip reference extent
		equals: VGFrameProfile referenceExtent
]

{ #category : 'tests' }
VGVulkanRoundTripTest >> testTheReportOfAMeasuredGateCarriesTheThreeStepsAndTheVerdict [
	"The report is what the view and the printed form both read, so it holds every number the
	 gate was decided on and names the decision."

	| trip labels |
	trip := VGVulkanRoundTrip reference.
	trip recordUpload: 1 fill: 2 readback: 3.
	trip softwareMilliseconds: 100.
	labels := trip reportRows collect: [ :each | each key ].
	self assert: (labels includesAll: #( 'upload' 'fill' 'readback' 'round trip' 'software frame' )).
	self
		assert: (trip reportRows detect: [ :each | each key = 'verdict' ]) value
		equals: VGVulkanRoundTrip goVerdict asString
]

{ #category : 'tests' }
VGVulkanRoundTripTest >> testTheReportOfAnUnmeasurableMachineCarriesTheReasonAndNoNumbers [
	"A machine with no device has a report too, and it says why rather than showing three zeroes."

	| trip rows |
	trip := VGNoDeviceRoundTripStub reference run.
	rows := trip reportRows.
	self
		assert: (rows detect: [ :each | each key = 'reason' ]) value
		equals: VGNoDeviceRoundTripStub reason.
	self assert: (rows noneSatisfy: [ :each | each key = 'round trip' ])
]

{ #category : 'tests' }
VGVulkanRoundTripTest >> testTheRoundTripOnThisMachineIsThreePositiveNumbers [
	"The measurement itself, on whatever device this machine has. A machine with none answers a
	 reason instead, and that is a pass too, because the gate is about the machine and not about
	 the code."

	| trip |
	trip := VGVulkanRoundTrip reference run.
	trip isAvailable ifFalse: [ ^ self assert: trip unavailableReason isNotNil ].
	self assert: trip hasRun.
	self assert: trip uploadMilliseconds > 0.
	self assert: trip fillMilliseconds > 0.
	self assert: trip readbackMilliseconds > 0.
	self assert: trip roundTripMilliseconds > 0
]

{ #category : 'tests' }
VGVulkanRoundTripTest >> testTheTotalIsTheSumOfTheThreeNumbers [

	| trip |
	trip := VGVulkanRoundTrip reference.
	trip recordUpload: 2 fill: 3 readback: 5.
	self assert: trip hasRun.
	self assert: trip roundTripMilliseconds equals: 10
]
