"
I measure what one frame costs to send to a Vulkan device and to get back again, which is the
question unit 2.1 of the plan asks before any pixel is drawn on the GPU.
Three numbers: the milliseconds to upload a frame's worth of coverage into a storage buffer, the
milliseconds for a trivial coverage shader to write every pixel of it, and the milliseconds to read
that buffer back into object memory.
Their sum is the round trip, and the gate compares it with what the software backend spends on the
same frame, which `VGFrameProfile` measures.
`reference` answers the round trip of the frame unit 1.11 profiled, `run` measures it, and
`verdict` answers go, no go, or unknown while either side is still missing.
A machine with no working device is not a failure here: `run` records why in `unavailableReason`
and answers me with nothing measured.
"
Class {
	#name : 'VGVulkanRoundTrip',
	#superclass : 'Object',
	#instVars : [
		'extent',
		'repeats',
		'uploadMilliseconds',
		'fillMilliseconds',
		'readbackMilliseconds',
		'softwareMilliseconds',
		'unavailableReason',
		'deviceName'
	],
	#category : 'VectorGraphics-Vulkan-Budget',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Budget'
}

{ #category : 'constants' }
VGVulkanRoundTrip class >> bytesPerMegabyte [
	"The binary megabyte, because the number describes a memory transfer and not a disc."

	^ 1024 * 1024
]

{ #category : 'constants' }
VGVulkanRoundTrip class >> bytesPerPixel [
	"One 32-bit float of coverage per pixel, which is what the kernel writes and what the host
	 sends and reads back."

	^ 4
]

{ #category : 'kernel' }
VGVulkanRoundTrip class >> coverageKernelMethod [
	"The kernel whose dispatch is the fill rate measurement."

	^ VGVulkanCoverageKernel >> #coverageOf:out:
]

{ #category : 'instance creation' }
VGVulkanRoundTrip class >> extent: anExtent repeats: anInteger [
	^ self new setExtent: anExtent repeats: anInteger
]

{ #category : 'constants' }
VGVulkanRoundTrip class >> goVerdict [
	^ #go
]

{ #category : 'constants' }
VGVulkanRoundTrip class >> microsecondsPerMillisecond [
	^ 1000
]

{ #category : 'constants' }
VGVulkanRoundTrip class >> millisecondDecimalPlaces [
	"Three places, because the steps of one frame are fractions of a millisecond on a device that
	 shares its memory with the host."

	^ 3
]

{ #category : 'constants' }
VGVulkanRoundTrip class >> millisecondsPerSecond [
	^ 1000
]

{ #category : 'constants' }
VGVulkanRoundTrip class >> noGoVerdict [
	^ #noGo
]

{ #category : 'constants' }
VGVulkanRoundTrip class >> pixelsPerMegapixel [
	^ 1000000
]

{ #category : 'constants' }
VGVulkanRoundTrip class >> rateDecimalPlaces [
	^ 0
]

{ #category : 'instance creation' }
VGVulkanRoundTrip class >> reference [
	"The round trip of the reference frame: the frame unit 1.11 profiled, so that the two numbers
	 the gate compares are measurements of the same picture."

	^ self extent: VGFrameProfile referenceExtent repeats: self referenceRepeats
]

{ #category : 'constants' }
VGVulkanRoundTrip class >> referenceRepeats [
	"How many times each of the three steps is measured. The first is thrown away as warm-up, so
	 a single repeat would measure nothing; ten keeps the whole gate under a second of device time
	 while averaging away the scheduling noise of one dispatch."

	^ 10
]

{ #category : 'constants' }
VGVulkanRoundTrip class >> unknownVerdict [
	"No verdict yet: either nothing was measured, or only one of the two sides of the comparison
	 is known. A gate that answered go or noGo from half a measurement would be a formality, and
	 this one is not."

	^ #unknown
]

{ #category : 'kernel' }
VGVulkanRoundTrip class >> workItemsPerGroup [
	"Read from the kernel's own annotation rather than written down here, so the dispatch covers
	 exactly the pixels the kernel's local size says one workgroup covers."

	^ (PVTypeAnnotation fromMethod: self coverageKernelMethod) localSize first
]

{ #category : 'measuring' }
VGVulkanRoundTrip >> coverageBytes [
	"One frame of coverage as the host holds it, every pixel carrying the value the kernel writes,
	 so the upload moves a frame and not an empty block."

	| pixel bytes |
	pixel := ByteArray new: self class bytesPerPixel.
	pixel unsignedLongAt: 1 put: 1.0 asIEEE32BitWord bigEndian: false.
	bytes := ByteArray new: self frameBytes.
	1 to: bytes size by: self class bytesPerPixel do: [ :each |
		bytes
			replaceFrom: each
			to: each + self class bytesPerPixel - 1
			with: pixel
			startingAt: 1 ].
	^ bytes
]

{ #category : 'accessing' }
VGVulkanRoundTrip >> deviceName [
	"The device the three numbers were measured on, or nil where nothing was measured."

	^ deviceName
]

{ #category : 'accessing' }
VGVulkanRoundTrip >> extent [
	^ extent
]

{ #category : 'rates' }
VGVulkanRoundTrip >> fillMegapixelsPerSecond [
	^ (self pixelCount / self class pixelsPerMegapixel)
	  / (fillMilliseconds / self class millisecondsPerSecond) asFloat
]

{ #category : 'accessing' }
VGVulkanRoundTrip >> fillMilliseconds [
	^ fillMilliseconds
]

{ #category : 'accessing' }
VGVulkanRoundTrip >> frameBytes [
	^ self pixelCount * self class bytesPerPixel
]

{ #category : 'testing' }
VGVulkanRoundTrip >> hasRun [
	^ uploadMilliseconds isNotNil
]

{ #category : 'inspector' }
VGVulkanRoundTrip >> inspectorBudget: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Budget'>
	"What one frame costs on the device against what it costs on the software path. Every row is
	 read from the report this object answers, which is computed from the measurement, so the tab
	 cannot say go while the numbers say otherwise. Nothing is measured here: opening the tab
	 opens no device."

	^ aBuilder newTable
		  items: self reportRows;
		  addColumn: (SpStringTableColumn
				   title: 'Measurement'
				   evaluated: [ :each | each key ]);
		  addColumn:
			  (SpStringTableColumn title: 'Value' evaluated: [ :each | each value ]);
		  yourself
]

{ #category : 'inspector' }
VGVulkanRoundTrip >> inspectorBudgetContext: aContext [
	"A round trip with no frame to measure has nothing to report."

	aContext active: extent isNotNil
]

{ #category : 'testing' }
VGVulkanRoundTrip >> isAvailable [
	"Whether this machine could be measured at all. A device that is missing, or a driver that
	 faults, records why instead, and a round trip that has not been asked to run is available
	 until it says otherwise."

	^ unavailableReason isNil
]

{ #category : 'gate' }
VGVulkanRoundTrip >> isGo [
	^ self verdict = self class goVerdict
]

{ #category : 'measuring' }
VGVulkanRoundTrip >> measureOn: aContext [
	"The three steps of one frame, each averaged over the repeats and measured in the order a
	 frame pays them, because arguments are evaluated left to right. The kernel is destroyed
	 before the buffer, since a buffer freed under a live pipeline takes the image with it."

	| kernel buffer sent received groups |
	deviceName := aContext chosenDeviceName.
	sent := self coverageBytes.
	received := ByteArray new: self frameBytes.
	groups := (self pixelCount / self class workItemsPerGroup) ceiling.
	buffer := VkBuffer storageBuffer: self pixelCount on: aContext device.
	kernel := PVComputeKernel
		          fromMethod: self class coverageKernelMethod
		          on: aContext.
	[
	kernel bindBuffer: buffer.
	kernel prepare.
	self
		recordUpload:
		(self millisecondsPerRepeatOf: [ self upload: sent into: buffer ])
		fill:
		(self millisecondsPerRepeatOf: [ kernel dispatch: groups y: 1 z: 1 ])
		readback:
			(self millisecondsPerRepeatOf: [ self readback: buffer into: received ]) ]
		ensure: [
			kernel destroy.
			buffer destroy ]
]

{ #category : 'measuring' }
VGVulkanRoundTrip >> measureSoftwareFrame [
	"The other side of the comparison, measured here and not quoted from unit 1.11, so the gate
	 compares two numbers from the same machine and the same session."

	softwareMilliseconds := VGFrameProfile reference ourMilliseconds
]

{ #category : 'rates' }
VGVulkanRoundTrip >> megabytesPerSecondIn: aMillisecondCount [
	"The frame's bytes over the time one step took, so a faster step reads as a larger number."

	^ (self frameBytes / self class bytesPerMegabyte)
	  / (aMillisecondCount / self class millisecondsPerSecond) asFloat
]

{ #category : 'printing' }
VGVulkanRoundTrip >> millisecondStringFor: aNumber [
	^ (aNumber asFloat printShowingDecimalPlaces: self class millisecondDecimalPlaces) , ' ms'
]

{ #category : 'measuring' }
VGVulkanRoundTrip >> millisecondsPerRepeatOf: aBlock [
	"One pass is run and thrown away before the clock starts: it carries the first touch of the
	 pages and, for a dispatch, the warm-up of the pipeline. The microsecond clock is read rather
	 than millisecondsToRun:, because a memory copy of one frame can finish inside a millisecond
	 and a step measured as zero would read as infinitely fast."

	| start |
	aBlock value.
	start := Time microsecondClockValue.
	repeats timesRepeat: [ aBlock value ].
	^ (Time microsecondClockValue - start / repeats / self class microsecondsPerMillisecond)
		  asFloat
]

{ #category : 'measuring' }
VGVulkanRoundTrip >> newContext [
	"A compute context, or nil with the reason recorded. A machine with no driver, no device or a
	 device that refuses the features this project asks for raises here, and the gate reports the
	 machine rather than failing."

	^ [ VkContext computeContext ]
		  on: Error
		  do: [ :each |
			  unavailableReason := self reasonFrom: each.
			  nil ]
]

{ #category : 'accessing' }
VGVulkanRoundTrip >> pixelCount [
	^ extent x * extent y
]

{ #category : 'printing' }
VGVulkanRoundTrip >> printOn: aStream [
	super printOn: aStream.
	aStream nextPut: $(.
	self isAvailable ifFalse: [
		^ aStream
			  nextPutAll: unavailableReason;
			  nextPut: $) ].
	self hasRun ifFalse: [ ^ aStream nextPutAll: 'not measured)' ].
	aStream
		nextPutAll: (self millisecondStringFor: self roundTripMilliseconds);
		nextPutAll: ', ';
		nextPutAll: self verdict;
		nextPut: $)
]

{ #category : 'measuring' }
VGVulkanRoundTrip >> readback: aBuffer into: aByteArray [
	"The device-to-host step, which section 2.2 makes the known risk of the whole plan: the frame
	 ends in host window memory, so every frame pays this copy."

	| pointer |
	pointer := aBuffer map.
	[ LibC memCopy: pointer to: aByteArray size: aByteArray size ] ensure: [ aBuffer unmap ]
]

{ #category : 'rates' }
VGVulkanRoundTrip >> readbackMegabytesPerSecond [
	^ self megabytesPerSecondIn: readbackMilliseconds
]

{ #category : 'accessing' }
VGVulkanRoundTrip >> readbackMilliseconds [
	^ readbackMilliseconds
]

{ #category : 'private' }
VGVulkanRoundTrip >> reasonFrom: anError [
	"A driver fault arrives as several classes of error and not all of them carry a message, so
	 the class name stands where there is no text."

	^ anError messageText ifNil: [ anError class name ]
]

{ #category : 'measuring' }
VGVulkanRoundTrip >> recordUpload: anUploadMilliseconds fill: aFillMilliseconds readback: aReadbackMilliseconds [
	"The three numbers arrive together, because a round trip with two of them is not a round trip
	 and nothing downstream should have to ask which of the three is missing."

	uploadMilliseconds := anUploadMilliseconds.
	fillMilliseconds := aFillMilliseconds.
	readbackMilliseconds := aReadbackMilliseconds
]

{ #category : 'accessing' }
VGVulkanRoundTrip >> repeats [
	^ repeats
]

{ #category : 'printing' }
VGVulkanRoundTrip >> reportRows [
	"Label and value for every number the gate was decided on, so the view and the printed form
	 read one report and neither restates the arithmetic. A machine with no device carries its
	 reason here and no numbers at all."

	| rows |
	rows := OrderedCollection new.
	rows add: 'frame' -> (extent x printString , ' x ' , extent y printString , ' pixels').
	rows add: 'repeats' -> repeats printString.
	self isAvailable ifFalse: [
		rows add: 'device' -> 'none'.
		rows add: 'reason' -> unavailableReason.
		^ rows asArray ].
	deviceName ifNotNil: [ rows add: 'device' -> deviceName ].
	self hasRun ifFalse: [ ^ rows asArray ].
	rows add: 'upload' -> (self
			 stringFor: uploadMilliseconds
			 rate: self uploadMegabytesPerSecond
			 unit: 'MB/s').
	rows add: 'fill' -> (self
			 stringFor: fillMilliseconds
			 rate: self fillMegapixelsPerSecond
			 unit: 'Mpixel/s').
	rows add: 'readback' -> (self
			 stringFor: readbackMilliseconds
			 rate: self readbackMegabytesPerSecond
			 unit: 'MB/s').
	rows add:
		'round trip' -> (self millisecondStringFor: self roundTripMilliseconds).
	softwareMilliseconds ifNotNil: [
		rows add:
			'software frame' -> (self millisecondStringFor: softwareMilliseconds) ].
	rows add: 'verdict' -> self verdict asString.
	^ rows asArray
]

{ #category : 'accessing' }
VGVulkanRoundTrip >> roundTripMilliseconds [
	"What one frame costs on the device: the bytes out, the fill, and the bytes back. Nil until
	 the three are measured, because a partial total reads like a cheap one."

	self hasRun ifFalse: [ ^ nil ].
	^ uploadMilliseconds + fillMilliseconds + readbackMilliseconds
]

{ #category : 'measuring' }
VGVulkanRoundTrip >> run [
	"Measure the three numbers on this machine, or record why they cannot be measured. Answers
	 self in both cases, because a machine with no device still has a report to give, and that
	 report is a pass of the gate and not a failure of it."

	| context |
	context := self newContext.
	context ifNil: [ ^ self ].
	[
	[ self measureOn: context ]
		on: Error
		do: [ :each | unavailableReason := self reasonFrom: each ] ]
		ensure: [ context destroy ].
	^ self
]

{ #category : 'measuring' }
VGVulkanRoundTrip >> runGate [
	"Both sides of the gate: the device round trip and the software frame it is weighed against."

	self run.
	self isAvailable ifFalse: [ ^ self ].
	self measureSoftwareFrame.
	^ self
]

{ #category : 'initialization' }
VGVulkanRoundTrip >> setExtent: anExtent repeats: anInteger [
	extent := anExtent.
	repeats := anInteger
]

{ #category : 'accessing' }
VGVulkanRoundTrip >> softwareMilliseconds [
	^ softwareMilliseconds
]

{ #category : 'accessing' }
VGVulkanRoundTrip >> softwareMilliseconds: aNumber [
	"The software side of the comparison, given rather than measured, so that a caller who
	 already has the number of unit 1.11 does not pay for it twice."

	softwareMilliseconds := aNumber
]

{ #category : 'printing' }
VGVulkanRoundTrip >> stringFor: aMillisecondCount rate: aRate unit: aUnitString [
	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: (self millisecondStringFor: aMillisecondCount);
			  nextPutAll: ' (';
			  nextPutAll:
				  (aRate printShowingDecimalPlaces: self class rateDecimalPlaces);
			  space;
			  nextPutAll: aUnitString;
			  nextPut: $) ]
]

{ #category : 'accessing' }
VGVulkanRoundTrip >> unavailableReason [
	"Why there is no measurement, or nil where there is one."

	^ unavailableReason
]

{ #category : 'measuring' }
VGVulkanRoundTrip >> upload: aByteArray into: aBuffer [
	"The host-to-device step: one memcpy into the mapped block. VkBuffer's own
	 copyFromByteArray: writes the bytes one at a time from Smalltalk, which measures the
	 interpreter rather than the bus, so the copy is made here through libc instead."

	| pointer |
	pointer := aBuffer map.
	[ LibC memCopy: aByteArray to: pointer size: aByteArray size ] ensure: [ aBuffer unmap ]
]

{ #category : 'rates' }
VGVulkanRoundTrip >> uploadMegabytesPerSecond [
	^ self megabytesPerSecondIn: uploadMilliseconds
]

{ #category : 'accessing' }
VGVulkanRoundTrip >> uploadMilliseconds [
	^ uploadMilliseconds
]

{ #category : 'gate' }
VGVulkanRoundTrip >> verdict [
	"Go where one frame through the device costs less than the same frame on the software path,
	 noGo where it costs more, and unknown while either side of that comparison is missing."

	(self hasRun and: [ softwareMilliseconds isNotNil ]) ifFalse: [
		^ self class unknownVerdict ].
	^ self roundTripMilliseconds < softwareMilliseconds
		  ifTrue: [ self class goVerdict ]
		  ifFalse: [ self class noGoVerdict ]
]
