"
I hold VGPresentPathBenchmark to the shape of its report and to what separates the two paths it compares, and to nothing about which of them is faster: a timing that asserts a speed goes red on a busy machine and says nothing about the code. I ask for a short run — one round of a few timed draws — because the shape of a run does not depend on how many draws it holds, and the verdict run of three rounds of forty belongs to the plan document and not to a gate. My tests answer early on a machine with no device, which is not a failure.
"
Class {
	#name : 'VGPresentPathBenchmarkTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Vulkan-Tests-Tests',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Tests'
}

{ #category : 'testing' }
VGPresentPathBenchmarkTest >> hasDevice [
	"Whether a device on this machine computes, asked of the session that holds it. A test of
	 mine that needs one answers early where there is none: a machine with no driver has nothing
	 to measure and that is not a failure."
	^ VGVulkanDeviceSession default contextOrNil isNotNil
]

{ #category : 'tests' }
VGPresentPathBenchmarkTest >> testAMachineAnswersEitherRowsOrAReason [
	"A run of mine is not a failure on a machine with no device: it answers no rows and says
	 why, and on a machine with one it answers rows and says nothing. This test is the one of
	 mine that needs no device, so it runs everywhere."
	| benchmark |
	benchmark := VGPresentPathBenchmark rounds: 1 timedDraws: 1.
	benchmark run.
	self assert: benchmark hasRun equals: benchmark isAvailable.
	benchmark isAvailable ifFalse: [
		self assert: benchmark unavailableReason isString.
		self assert: benchmark comparisonRows isEmpty ]
]

{ #category : 'tests' }
VGPresentPathBenchmarkTest >> testARunReportsEveryFrameOnBothPathsAtBothExtents [
	"The shape of a run. Every frame of the device benchmark is measured at both extents and on
	 both paths, so a run holds one comparison a frame an extent a path, and each of them names
	 which frame, which extent and which path it timed."
	| benchmark rows |
	self hasDevice ifFalse: [ ^ self ].
	benchmark := VGPresentPathBenchmark rounds: 1 timedDraws: 2.
	benchmark run.
	rows := benchmark comparisonRows.
	self
		assert: rows size
		equals: VGFrameDeviceBenchmark frameNames size
			* VGPresentPathBenchmark extents size
			* VGPresentPathBenchmark pathNames size.
	self
		assert: (rows collect: [ :each | each frameName ]) asSet
		equals: VGFrameDeviceBenchmark frameNames asSet.
	self
		assert: (rows collect: [ :each | each extent ]) asSet
		equals: VGPresentPathBenchmark extents asSet.
	self
		assert: (rows collect: [ :each | each pathName ]) asSet
		equals: VGPresentPathBenchmark pathNames asSet
]

{ #category : 'tests' }
VGPresentPathBenchmarkTest >> testEachPathIsMeasuredOnTheStagesThatPathPays [
	"What the two paths are, read off the stages they were measured on rather than off their
	 names. The presented path clears its target on the device and copies it into an image; it
	 reads nothing back and it copies nothing in the host. The readback path reads the target
	 into the host's own pixels and pays a copy on each side of that, and it clears nothing,
	 because the destination it uploads is the clearing."
	| benchmark presented readBack hostCopyStages |
	self hasDevice ifFalse: [ ^ self ].
	benchmark := VGPresentPathBenchmark rounds: 1 timedDraws: 2.
	benchmark run.
	presented := benchmark comparisonRows detect: [ :each |
		             each pathName = VGPresentPathBenchmark presentedPathName ].
	readBack := benchmark comparisonRows detect: [ :each |
		            each pathName = VGPresentPathBenchmark readBackPathName ].
	hostCopyStages := {
		                  VGPresentPathBenchmark pixelsOfStageName.
		                  VGPresentPathBenchmark writeIntoStageName }.
	self assert: (presented stageNames includesAll: #( #clear #copy )).
	self deny: (presented stageNames includesAny: hostCopyStages).
	self deny: (presented stageNames includes: #readback).
	self assert: (readBack stageNames includesAll: hostCopyStages).
	self assert: (readBack stageNames includes: #readback).
	self deny: (readBack stageNames includes: #clear)
]

{ #category : 'tests' }
VGPresentPathBenchmarkTest >> testEveryComparisonHoldsTheDrawsItWasAskedFor [
	"The counts of a run. Every comparison holds one round of timed draws a round asked for, the
	 discarded draws are in none of them, and the verdict figure is no slower than the middle
	 one, because a minimum of a set is never above its median."
	| benchmark |
	self hasDevice ifFalse: [ ^ self ].
	benchmark := VGPresentPathBenchmark rounds: 2 timedDraws: 3.
	benchmark run.
	benchmark comparisonRows do: [ :row |
		self assert: row roundCount equals: 2.
		self assert: row allDraws size equals: 2 * 3.
		self assert: row minimumMicroseconds <= row medianMicroseconds ]
]
